import Foundation
import SwiftUI

/// One usage limit as shown everywhere (menu bar, dropdown, widgets).
struct UsageLimit: Codable, Hashable, Identifiable {
    var id: String { key }
    let key: String          // "session", "weekly_all", "weekly_fable", ...
    let label: String        // "Session (5h)", "Weekly · all models", ...
    let group: String        // "session" or "weekly"
    let percent: Double
    let resetsAt: Date?

    /// A limit whose reset time has passed counts as 0% until the next reading.
    func effectivePercent(at now: Date = Date()) -> Double {
        if let r = resetsAt, r <= now { return 0 }
        return percent
    }
    func hasReset(at now: Date = Date()) -> Bool {
        if let r = resetsAt { return r <= now }
        return false
    }
}

struct ExtraUsage: Codable, Hashable {
    let used: Double
    let limit: Double
    let currency: String
    let percent: Double
    let reached: Bool
}

/// Anthropic's own split of the weekly window by product (Claude Code / Chats / Cowork).
struct BreakdownRow: Codable, Hashable {
    let name: String
    let percent: Double
}

/// What the app shares with its widgets (App Group) and the iPhone (Scriptable's iCloud folder).
struct Snapshot: Codable {
    var version = 1
    var fetchedAt: Date
    var limits: [UsageLimit]
    var extra: ExtraUsage?
    var breakdown: [BreakdownRow]
    var error: String?
    var errorAt: Date?
    var source = "mac"

    var session: UsageLimit? { limits.first { $0.group == "session" } }
    var weekly: UsageLimit? { limits.first { $0.key == "weekly_all" } ?? limits.first { $0.group == "weekly" } }

    /// Error newer than the reading, or a reading older than `staleAfter`.
    func staleReason(staleAfter: TimeInterval, now: Date = Date()) -> String? {
        if let e = error, let at = errorAt, at > fetchedAt { return e }
        let age = now.timeIntervalSince(fetchedAt)
        if age > staleAfter { return "No successful update for \(Int(age / 60)) min" }
        return nil
    }
}

enum SnapshotStore {
    static let groupID = "KFT88Q5XQ9.com.joshhotz.usagebarapp"

    static var url: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("snapshot.json")
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func load() -> Snapshot? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(Snapshot.self, from: data)
    }

    static func save(_ snapshot: Snapshot, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }
}

enum UsageStyle {
    static let green = Color(red: 0x34 / 255.0, green: 0xC7 / 255.0, blue: 0x59 / 255.0)
    static let amber = Color(red: 0xFF / 255.0, green: 0x9F / 255.0, blue: 0x0A / 255.0)
    static let red = Color(red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x30 / 255.0)
    static let dim = Color(red: 0x8E / 255.0, green: 0x8E / 255.0, blue: 0x93 / 255.0)

    /// Same bands as UsageBar: green under 70, amber 70–89, red 90+.
    static func color(for percent: Double) -> Color {
        percent >= 90 ? red : (percent >= 70 ? amber : green)
    }

    /// "2h14m" / "45m" for the menu bar.
    static func shortCountdown(_ seconds: TimeInterval) -> String {
        let m = max(0, Int(seconds / 60))
        return m >= 60 ? "\(m / 60)h\(String(format: "%02d", m % 60))m" : "\(m)m"
    }

    /// "today 11:00 PM (in 2h 14m)" / "Sun Nov 8 4:00 AM (in 6d 7h)".
    static func resetText(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "reset time unknown" }
        let cal = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        let day: String
        if cal.isDateInToday(date) { day = "today " }
        else if cal.isDateInTomorrow(date) { day = "tomorrow " }
        else { day = date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " " }
        let s = Int(max(0, date.timeIntervalSince(now)))
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
        let left = d > 0 ? "\(d)d \(h)h" : (h > 0 ? "\(h)h \(m)m" : "\(m)m")
        return "\(day)\(time) (in \(left))"
    }
}
