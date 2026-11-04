import AppKit
import Foundation
import WidgetKit

/// Owns the current reading: polls on the chosen interval, shares the snapshot with the widgets and
/// the iPhone, and runs alerts. A one-minute tick keeps countdowns current without API calls.
@MainActor
final class UsageModel: ObservableObject {
    static let refreshChoices = [2, 5, 10, 15, 30, 60]
    static let clickFetchGap: TimeInterval = 30
    static let minFetchGap: TimeInterval = 115   // the endpoint answers 429 after a handful of quick calls

    @Published private(set) var snapshot: Snapshot?
    @Published private(set) var isFetching = false
    @Published private(set) var now = Date()

    @Published var refreshMinutes: Int {
        didSet { UserDefaults.standard.set(refreshMinutes, forKey: "refreshMinutes") }
    }

    let alerts = AlertManager()
    private var timer: Timer?
    private var backoffUntil = Date.distantPast

    /// Scriptable's iCloud Documents folder; the iPhone widget reads the snapshot from here.
    static let iphoneMirror = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Mobile Documents/iCloud~dk~simonbs~Scriptable/Documents")

    init() {
        let saved = UserDefaults.standard.integer(forKey: "refreshMinutes")
        refreshMinutes = Self.refreshChoices.contains(saved) ? saved : 5
        snapshot = SnapshotStore.load()
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
        Task { await refresh(minGap: Self.minFetchGap) }
    }

    var staleAfter: TimeInterval { max(600, Double(refreshMinutes) * 60 + 300) }
    var staleReason: String? { snapshot?.staleReason(staleAfter: staleAfter, now: now) }

    private func tick() {
        now = Date()
        alerts.check(snapshot, staleAfter: staleAfter, now: now)
        Task { await refresh(minGap: max(Self.minFetchGap, Double(refreshMinutes) * 60 - 30)) }
    }

    /// Fetches if the reading is at least `minGap` seconds old (and we're not backing off after a 429).
    func refresh(minGap: TimeInterval) async {
        let age = snapshot.map { Date().timeIntervalSince($0.fetchedAt) } ?? .infinity
        guard !isFetching, age >= minGap, Date() >= backoffUntil else { return }
        isFetching = true
        defer { isFetching = false }
        do {
            let raw = try await UsageClient.fetch()
            snapshot = try UsageClient.snapshot(from: raw)
        } catch UsageClient.FetchError.rateLimited(let ra) {
            backoffUntil = Date().addingTimeInterval(ra)
            return
        } catch {
            guard var s = snapshot else {
                snapshot = Snapshot(fetchedAt: .distantPast, limits: [], extra: nil, breakdown: [],
                                    error: error.localizedDescription, errorAt: Date())
                return publish()
            }
            s.error = error.localizedDescription
            s.errorAt = Date()
            snapshot = s
        }
        now = Date()
        publish()
        alerts.check(snapshot, staleAfter: staleAfter, now: now)
    }

    /// Shares the reading with the widgets (App Group) and the iPhone (Scriptable iCloud folder).
    private func publish() {
        guard let s = snapshot else { return }
        if let url = SnapshotStore.url { try? SnapshotStore.save(s, to: url) }
        if FileManager.default.fileExists(atPath: Self.iphoneMirror.path) {
            try? SnapshotStore.save(s, to: Self.iphoneMirror.appendingPathComponent("UsageBarApp/snapshot.json"))
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
