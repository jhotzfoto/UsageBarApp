import AppKit
import Foundation
import UsageCore
import WidgetKit

/// Owns the current reading: polls on the chosen interval, logs readings, tracks chats, checks Claude's
/// status page, shares the snapshot (widgets, iPhone, Claude Code status line) and runs alerts.
/// A one-minute tick keeps countdowns current without API calls.
@MainActor
final class UsageModel: ObservableObject {
    static let refreshChoices = [2, 5, 10, 15, 30, 60]
    static let clickFetchGap: TimeInterval = 30
    static let minFetchGap: TimeInterval = 115   // the endpoint answers 429 after a handful of quick calls

    @Published private(set) var snapshot: Snapshot?
    @Published private(set) var isFetching = false
    @Published private(set) var now = Date()
    @Published private(set) var readings: [Reading] = []
    @Published private(set) var daily: [DailyRow] = []
    @Published private(set) var windows: [History.Window] = []
    @Published private(set) var chats: ChatTracker.Result?
    @Published private(set) var status: ServiceStatus?
    /// When the iPhone copy (Scriptable's iCloud folder) was last written; nil if not this run.
    @Published private(set) var iphoneCopyAt: Date?
    /// The iPhone's session-key lifetime record (written by the iPhone script).
    @Published private(set) var phoneKey: PhoneKey.Status?
    @Published var phoneKeyAlert: Bool { didSet { UserDefaults.standard.set(phoneKeyAlert, forKey: "phoneKeyAlert") } }

    @Published var refreshMinutes: Int { didSet { UserDefaults.standard.set(refreshMinutes, forKey: "refreshMinutes") } }
    @Published var menuBarIcon: Bool { didSet { UserDefaults.standard.set(menuBarIcon, forKey: "menuBarIcon") } }
    @Published var chromeTracking: Bool { didSet { UserDefaults.standard.set(chromeTracking, forKey: "chromeTracking") } }
    @Published var topChats: Int { didSet { UserDefaults.standard.set(topChats, forKey: "topChats") } }

    let alerts = AlertManager()
    private var timer: Timer?
    private var backoffUntil = Date.distantPast
    private var lastStatusCheck = Date.distantPast
    private var lastRollup = Date.distantPast
    private var fetchStartedAt = Date.distantPast
    private var lastAttemptAt = Date.distantPast
    private var errorStreak = 0
    private var lastWidgetKey = ""
    private var lastChatPass = Date.distantPast

    static let dataDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/UsageBarApp")
    /// Scriptable's iCloud Documents folder; the iPhone widget reads the snapshot from here.
    static let iphoneMirror = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Mobile Documents/iCloud~dk~simonbs~Scriptable/Documents")
    static var statuslineURL: URL { dataDir.appendingPathComponent("statusline.txt") }

    let log = ReadingsLog(directory: UsageModel.dataDir)
    let tracker = ChatTracker(directory: UsageModel.dataDir)

    init() {
        let d = UserDefaults.standard
        let saved = d.integer(forKey: "refreshMinutes")
        refreshMinutes = Self.refreshChoices.contains(saved) ? saved : 5
        chromeTracking = d.object(forKey: "chromeTracking") as? Bool ?? true
        menuBarIcon = d.bool(forKey: "menuBarIcon")
        phoneKeyAlert = d.object(forKey: "phoneKeyAlert") as? Bool ?? true
        let tc = d.integer(forKey: "topChats")
        topChats = (1...25).contains(tc) ? tc : 5
        snapshot = SnapshotStore.load()
        Task { await reloadLog() }   // off the main thread: the log grows to tens of thousands of rows
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
                                                          object: nil, queue: .main) { [weak self] _ in
            // Give the network a moment after wake, so the first fetch doesn't just fail.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                await self?.refresh(minGap: Self.clickFetchGap)
            }
        }
        writeStatusline()
        Task { await refresh(minGap: Self.minFetchGap) }
        Task { await checkStatus() }
        loadPhoneKey()
    }

    /// Reads the iPhone's key record from iCloud (off the main thread) and alerts once when the key
    /// stops working. This alert has its own switch: UsageBar has nothing like it, so no duplicates.
    private func loadPhoneKey() {
        let url = Self.iphoneMirror.appendingPathComponent("UsageBarApp/key-status.json")
        DispatchQueue.global(qos: .utility).async {
            try? FileManager.default.startDownloadingUbiquitousItem(at: url)
            let s = (try? Data(contentsOf: url)).flatMap(PhoneKey.parse)
            DispatchQueue.main.async {
                self.phoneKey = s
                let d = UserDefaults.standard
                guard let id = PhoneKey.failureID(s), id != d.string(forKey: "phoneKeyAlerted") else { return }
                d.set(id, forKey: "phoneKeyAlerted")
                if self.phoneKeyAlert, let c = s?.current {
                    self.alerts.notify("iPhone session key stopped working",
                                       "It " + PhoneKey.lifetimeText(c, now: Date()) + ". Paste a new key in Scriptable > Claude Usage.",
                                       force: true)
                }
            }
        }
    }

    var staleAfter: TimeInterval { max(600, Double(refreshMinutes) * 60 + 300) }
    var staleReason: String? { snapshot?.staleReason(staleAfter: staleAfter, now: now) }

    private func tick() {
        now = Date()
        if windows.contains(where: { !$0.done && $0.reset <= now }) { windows = History.windows(readings: readings, daily: daily, now: now) }
        alerts.check(snapshot, now: now)
        writeStatusline()
        Task { await refresh(minGap: max(Self.minFetchGap, Double(refreshMinutes) * 60 - 30)) }
        if now.timeIntervalSince(lastStatusCheck) >= 5 * 60 { Task { await checkStatus() } }
        loadPhoneKey()
    }

    /// Fetches if the reading is at least `minGap` seconds old, we're not backing off (429 or repeated
    /// errors), and no fetch is running (a fetch stuck for over 3 min is treated as gone).
    func refresh(minGap: TimeInterval) async {
        let age = snapshot.map { Date().timeIntervalSince($0.fetchedAt) } ?? .infinity
        let stuck = isFetching && Date().timeIntervalSince(fetchStartedAt) > 180
        guard !isFetching || stuck, age >= minGap, Date() >= backoffUntil else { return }
        isFetching = true
        fetchStartedAt = Date()
        lastAttemptAt = Date()
        defer { isFetching = false }
        do {
            let raw: [String: Any]
            do {
                raw = try await UsageClient.fetch()
            } catch UsageClient.FetchError.expired where chromeTracking {
                // Claude Code's login expired (e.g. overnight). Read the same numbers through the open
                // claude.ai tab instead, so the menu bar doesn't go grey until Claude Code is used again.
                let tracker = self.tracker
                let org = await Task.detached(priority: .utility) { tracker.load().org }.value
                raw = try await UsageClient.fetchViaChrome(org: org)
            }
            let s = try UsageParser.snapshot(from: raw)
            snapshot = s
            errorStreak = 0
            try? log.append(s)
            appendReadings(s)
            if Date().timeIntervalSince(lastRollup) > 86400 {
                lastRollup = Date()
                if log.rollup() > 0 { await reloadLog() }
            }
            trackChats()
        } catch UsageClient.FetchError.rateLimited(let ra) {
            backoffUntil = Date().addingTimeInterval(ra)
            return
        } catch {
            var s = snapshot ?? Snapshot(fetchedAt: .distantPast, limits: [], extra: nil, breakdown: [])
            s.error = error.localizedDescription
            s.errorAt = Date()
            snapshot = s
            // Back off on repeated errors: 2, 4, 8, then 15 min, instead of retrying every minute.
            errorStreak += 1
            backoffUntil = Date().addingTimeInterval(min(900, 120 * pow(2, Double(errorStreak - 1))))
        }
        now = Date()
        publish()
        alerts.check(snapshot, now: now)
    }

    private func reloadLog() async {
        let log = self.log
        let since = Date().addingTimeInterval(-Double(ReadingsLog.keepDays + 1) * 86400)
        let (r, d) = await Task.detached(priority: .utility) { (log.load(since: since), log.loadDaily()) }.value
        readings = r
        daily = d
        windows = History.windows(readings: r, daily: d, now: Date())
        if chats == nil {
            let tracker = self.tracker
            chats = await Task.detached(priority: .utility) { tracker.cached(readings: r) }.value
        }
    }

    /// Adds a new reading in memory (the log file is only re-read after a rollup).
    private func appendReadings(_ s: Snapshot) {
        readings.append(contentsOf: s.limits.map { Reading(ts: s.fetchedAt, key: $0.key, label: $0.label, percent: $0.percent, resetsAt: $0.resetsAt) })
        windows = History.windows(readings: readings, daily: daily, now: Date())
    }

    /// At most every 5 min, whatever the check interval: each pass reads the claude.ai tab.
    private func trackChats() {
        guard Date().timeIntervalSince(lastChatPass) >= 290 else { return }
        lastChatPass = Date()
        let since = Date().addingTimeInterval(-ChatTracking.keepDays * 86400 - History.sessionLength)
        tracker.pass(readings: readings.filter { $0.ts >= since }, includeChrome: chromeTracking) { [weak self] r in
            self?.chats = r
        }
    }

    private func checkStatus() async {
        lastStatusCheck = Date()
        var req = URLRequest(url: ServiceStatus.url, timeoutInterval: 15)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200, let s = ServiceStatus.parse(data) else { return }
        status = s
        alerts.check(status: s, now: Date())
    }

    /// Shares the reading with the widgets (App Group) and the iPhone (Scriptable iCloud folder).
    private func publish() {
        guard let s = snapshot else { return }
        if let url = SnapshotStore.url { try? SnapshotStore.save(s, to: url) }
        // iCloud folders can block (eviction, the first-use privacy prompt), so never on the main thread.
        DispatchQueue.global(qos: .utility).async {
            guard FileManager.default.fileExists(atPath: Self.iphoneMirror.path),
                  (try? SnapshotStore.save(s, to: Self.iphoneMirror.appendingPathComponent("UsageBarApp/snapshot.json"))) != nil
            else { return }
            DispatchQueue.main.async { self.iphoneCopyAt = Date() }
        }
        // Widgets have a daily refresh budget: reload only when what they show changes.
        let key = s.limits.map { "\($0.key)\(Int($0.percent))" }.joined() + (s.extra.map { "e\(Int($0.percent))" } ?? "")
            + (s.lastError == nil ? "" : "err")
        if key != lastWidgetKey { lastWidgetKey = key; WidgetCenter.shared.reloadAllTimelines() }
        writeStatusline()
    }

    /// Claude Code's status line prints this file (see README); written every minute.
    private func writeStatusline() {
        let text = Statusline.text(snapshot, sessionPace: sessionPace, staleAfter: staleAfter, now: Date())
        try? FileManager.default.createDirectory(at: Self.dataDir, withIntermediateDirectories: true)
        try? (text + "\n").write(to: Self.statuslineURL, atomically: true, encoding: .utf8)
    }

    // MARK: derived

    var sessionPace: Forecast.Pace? {
        guard let s = snapshot?.session, !s.hasReset(at: now) else { return nil }
        return Forecast.pace(for: s, readings: readings, now: now)
    }

    func pace(for l: UsageLimit) -> Forecast.Pace? {
        guard !l.hasReset(at: now) else { return nil }
        return Forecast.pace(for: l, readings: readings, now: now)
    }


    struct ChatSummary {
        let tracked: Double
        let logged: Double
        let tokenEstimate: Double?
        let calibrationWindows: Int
        let top: [ChatTracking.Total]
        let othersCount: Int
        let othersPercent: Double
        let unattributed: Double
        let status: String?
        let projects: [String: String]
        var drift: Bool { tokenEstimate.map { abs($0 - logged) > 5 } ?? false }
    }

    /// The current session's per-chat totals vs the logged %, with the independent token check.
    var chatSummary: ChatSummary? {
        guard let s = snapshot?.session, let reset = s.resetsAt, reset > now, let c = chats else { return nil }
        let tot = ChatTracking.totals(c.rows, window: reset)
        let list = tot.filter { $0.id != ChatTracking.unattributed }
        let cal = ChatTracking.tokensPerPercent(windows: windows, events: c.events, now: now)
        let est = cal.map { ChatTracking.windowTokens(c.events, reset: History.minute(reset)) / $0.rate }
        let top = Array(list.prefix(topChats)), rest = list.dropFirst(topChats)
        return ChatSummary(tracked: list.reduce(0) { $0 + $1.percent }, logged: s.percent, tokenEstimate: est,
                           calibrationWindows: cal?.windows ?? 0, top: top, othersCount: rest.count,
                           othersPercent: rest.reduce(0) { $0 + $1.percent },
                           unattributed: tot.filter { $0.id == ChatTracking.unattributed }.reduce(0) { $0 + $1.percent },
                           status: c.status, projects: c.projects)
    }
}
