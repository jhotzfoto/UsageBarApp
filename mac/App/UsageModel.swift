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

    @Published var refreshMinutes: Int { didSet { UserDefaults.standard.set(refreshMinutes, forKey: "refreshMinutes") } }
    @Published var chromeTracking: Bool { didSet { UserDefaults.standard.set(chromeTracking, forKey: "chromeTracking") } }
    @Published var topChats: Int { didSet { UserDefaults.standard.set(topChats, forKey: "topChats") } }

    let alerts = AlertManager()
    private var timer: Timer?
    private var backoffUntil = Date.distantPast
    private var lastStatusCheck = Date.distantPast
    private var lastRollup = Date.distantPast

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
        let tc = d.integer(forKey: "topChats")
        topChats = (1...25).contains(tc) ? tc : 5
        snapshot = SnapshotStore.load()
        reloadLog()
        chats = tracker.cached(readings: readings)
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification,
                                                          object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in await self?.refresh(minGap: Self.clickFetchGap) }
        }
        writeStatusline()
        Task { await refresh(minGap: Self.minFetchGap) }
        Task { await checkStatus() }
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
    }

    /// Fetches if the reading is at least `minGap` seconds old (and we're not backing off after a 429).
    func refresh(minGap: TimeInterval) async {
        let age = snapshot.map { Date().timeIntervalSince($0.fetchedAt) } ?? .infinity
        guard !isFetching, age >= minGap, Date() >= backoffUntil else { return }
        isFetching = true
        defer { isFetching = false }
        do {
            let raw = try await UsageClient.fetch()
            let s = try UsageParser.snapshot(from: raw)
            snapshot = s
            try? log.append(s)
            if Date().timeIntervalSince(lastRollup) > 86400 { log.rollup(); lastRollup = Date() }
            reloadLog()
            trackChats()
        } catch UsageClient.FetchError.rateLimited(let ra) {
            backoffUntil = Date().addingTimeInterval(ra)
            return
        } catch {
            var s = snapshot ?? Snapshot(fetchedAt: .distantPast, limits: [], extra: nil, breakdown: [])
            s.error = error.localizedDescription
            s.errorAt = Date()
            snapshot = s
        }
        now = Date()
        publish()
        alerts.check(snapshot, now: now)
    }

    private func reloadLog() {
        readings = log.load(since: Date().addingTimeInterval(-Double(ReadingsLog.keepDays + 1) * 86400))
        daily = log.loadDaily()
        windows = History.windows(readings: readings, daily: daily, now: Date())
    }

    private func trackChats() {
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
            if FileManager.default.fileExists(atPath: Self.iphoneMirror.path) {
                try? SnapshotStore.save(s, to: Self.iphoneMirror.appendingPathComponent("UsageBarApp/snapshot.json"))
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
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
