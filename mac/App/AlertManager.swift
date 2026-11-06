import AppKit
import Foundation
import UsageCore
import UserNotifications

/// Delivers what AlertEngine decides. Sending is off by default while UsageBar is still in use (no
/// duplicates); the bookkeeping always runs, so turning alerts on later doesn't replay old ones.
@MainActor
final class AlertManager: ObservableObject {
    static let sounds = ["Default", "None", "Glass", "Hero", "Ping", "Purr", "Submarine", "Funk", "Blow", "Sosumi"]

    @Published var enabled: Bool { didSet { defaults.set(enabled, forKey: "alertsEnabled"); if enabled { requestPermission() } } }
    @Published var sound: String { didSet { defaults.set(sound, forKey: "alertSound") } }
    @Published var config: AlertConfig { didSet { saveJSON(config, "alertConfig") } }
    @Published private(set) var permissionDenied = false

    private var state: AlertState { didSet { saveJSON(state, "alertState") } }
    private let defaults = UserDefaults.standard

    init() {
        enabled = defaults.bool(forKey: "alertsEnabled")
        sound = defaults.string(forKey: "alertSound") ?? "Default"
        config = Self.loadJSON("alertConfig") ?? AlertConfig()
        state = Self.loadJSON("alertState") ?? AlertState()
    }

    private static func loadJSON<T: Decodable>(_ key: String) -> T? {
        guard let d = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? SnapshotStore.decoder.decode(T.self, from: d)
    }
    private func saveJSON<T: Encodable>(_ v: T, _ key: String) {
        if let d = try? SnapshotStore.encoder.encode(v) { defaults.set(d, forKey: key) }
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            Task { @MainActor in self.permissionDenied = !granted }
        }
    }

    func check(_ snap: Snapshot?, now: Date) {
        var st = state
        let alerts = AlertEngine.evaluate(snap, config: config, state: &st, now: now)
        state = st
        alerts.forEach { notify($0.title, $0.body) }
    }

    func check(status: ServiceStatus?, now: Date) {
        var st = state
        let alerts = AlertEngine.evaluate(status: status, config: config, state: &st, now: now)
        state = st
        alerts.forEach { notify($0.title, $0.body) }
    }

    func notify(_ title: String, _ body: String, force: Bool = false) {
        guard enabled || force else { return }
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        c.sound = sound == "Default" ? .default : nil
        let sound = self.sound
        // Check permission first: if notifications are off, say so in Settings instead of failing silently.
        UNUserNotificationCenter.current().getNotificationSettings { s in
            let allowed = s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
            Task { @MainActor in
                self.permissionDenied = s.authorizationStatus == .denied
                if s.authorizationStatus == .notDetermined { self.requestPermission() }
                guard allowed else { return }
                UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
                if sound != "Default" && sound != "None" { NSSound(named: NSSound.Name(sound))?.play() }
            }
        }
    }

    func sendTest() {
        requestPermission()
        notify("UsageBarApp test", "Notifications are working.", force: true)
    }

    func previewSound() {
        if sound == "Default" { NSSound.beep() }
        else if sound != "None" { NSSound(named: NSSound.Name(sound))?.play() }
    }
}
