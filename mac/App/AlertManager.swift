import AppKit
import Foundation
import UserNotifications

/// Same alerts as UsageBar, each once per window. Off by default while UsageBar is still in use,
/// so nothing is sent twice. When several thresholds are crossed at once, only the highest is sent.
@MainActor
final class AlertManager: ObservableObject {
    static let sounds = ["Default", "None", "Glass", "Hero", "Ping", "Purr", "Submarine", "Funk", "Blow", "Sosumi"]

    @Published var enabled: Bool { didSet { save("alertsEnabled", enabled); if enabled { requestPermission() } } }
    @Published var sound: String { didSet { save("alertSound", sound) } }
    @Published private(set) var permissionDenied = false

    var sessionThresholds: [Double] = [80, 95]
    var weeklyThresholds: [Double] = [75, 90]
    var extraThresholds: [Double] = [80, 95, 100]

    private var sent: [String: Date]
    private var activeSessionReset: Date?

    init() {
        let d = UserDefaults.standard
        enabled = d.bool(forKey: "alertsEnabled")
        sound = d.string(forKey: "alertSound") ?? "Default"
        sent = (d.dictionary(forKey: "alertsSent") as? [String: Date]) ?? [:]
        activeSessionReset = d.object(forKey: "activeSessionReset") as? Date
    }

    private func save(_ key: String, _ value: Any) { UserDefaults.standard.set(value, forKey: key) }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in self.permissionDenied = !granted }
        }
    }

    func check(_ snap: Snapshot?, staleAfter: TimeInterval, now: Date) {
        guard let snap else { return }
        sent = sent.filter { now.timeIntervalSince($0.value) < 8 * 86400 }
        defer {
            save("alertsSent", sent)
            if let r = activeSessionReset { save("activeSessionReset", r) }
            else { UserDefaults.standard.removeObject(forKey: "activeSessionReset") }
        }

        if let s = snap.session, let reset = s.resetsAt {
            if !s.hasReset(at: now) {
                crossed("sp|\(key(reset))", s.percent, sessionThresholds,
                        title: "Claude session at \(Int(s.percent))%",
                        body: { "Session passed \(Int($0))%. Resets \(UsageStyle.resetText(reset, now: now))." })
                if s.percent > 0 { activeSessionReset = reset }
            }
        }
        if let prev = activeSessionReset, prev <= now {
            once("ns|\(key(prev))", title: "New Claude session available",
                 body: "Your 5-hour limit reset at \(prev.formatted(date: .omitted, time: .shortened)).")
            activeSessionReset = nil
        }
        for w in snap.limits where w.group == "weekly" && !w.hasReset(at: now) {
            guard let reset = w.resetsAt else { continue }
            crossed("wp|\(w.label)|\(key(reset))", w.percent, weeklyThresholds,
                    title: "\(w.label) at \(Int(w.percent))%",
                    body: { "Passed \(Int($0))%. Resets \(UsageStyle.resetText(reset, now: now))." })
        }
        if let ex = snap.extra {
            let month = now.formatted(.dateTime.year().month(.twoDigits))
            crossed("ex|\(month)|\(ex.limit)", ex.percent, extraThresholds,
                    title: "Extra usage at \(Int(ex.percent))% of monthly budget",
                    body: { "Passed \(Int($0))%: \(String(format: "$%.2f of $%.2f", ex.used, ex.limit)) \(ex.currency) used." })
        }
        if snap.staleReason(staleAfter: 1800, now: now) != nil {
            once("st|\(Int(snap.fetchedAt.timeIntervalSince1970))", title: "Claude usage not updating",
                 body: snap.error ?? "No successful update for 30 minutes.")
        }
    }

    private func key(_ d: Date) -> String { String(Int(d.timeIntervalSince1970 / 60)) }

    private func once(_ k: String, title: String, body: String) {
        guard sent[k] == nil else { return }
        sent[k] = Date()
        notify(title, body)
    }

    private func crossed(_ prefix: String, _ value: Double, _ thresholds: [Double], title: String, body: (Double) -> String) {
        let hit = thresholds.filter { value >= $0 }
        let fresh = hit.filter { sent["\(prefix)|\($0)"] == nil }
        guard let top = fresh.max() else { return }
        notify(title, body(top))
        for t in hit where sent["\(prefix)|\(t)"] == nil { sent["\(prefix)|\(t)"] = Date() }
    }

    /// Bookkeeping always runs, so turning alerts on later doesn't replay old ones.
    func notify(_ title: String, _ body: String, force: Bool = false) {
        guard enabled || force else { return }
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        c.sound = sound == "Default" ? .default : nil
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
        if sound != "Default" && sound != "None" { NSSound(named: NSSound.Name(sound))?.play() }
    }

    func sendTest() {
        requestPermission()
        notify("UsageBarApp test", "Notifications are working.", force: true)
    }
}
