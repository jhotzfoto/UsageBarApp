import Foundation
import SwiftUI

/// One usage limit as shown everywhere (menu bar, dropdown, widgets).
public struct UsageLimit: Codable, Hashable, Identifiable {
    public var id: String { key }
    public let key: String          // "session", "weekly_all", "weekly_fable", ...
    public let label: String        // "Session (5h)", "Weekly · all models", ...
    public let group: String        // "session" or "weekly"
    public let percent: Double
    public let resetsAt: Date?

    public init(key: String, label: String, group: String, percent: Double, resetsAt: Date?) {
        self.key = key; self.label = label; self.group = group; self.percent = percent; self.resetsAt = resetsAt
    }

    /// A limit whose reset time has passed counts as 0% until the next reading.
    public func effectivePercent(at now: Date = Date()) -> Double {
        if let r = resetsAt, r <= now { return 0 }
        return percent
    }
    public func hasReset(at now: Date = Date()) -> Bool {
        if let r = resetsAt { return r <= now }
        return false
    }
    /// Length of this limit's window (5 h for the session, 7 days for weekly limits).
    public var windowLength: TimeInterval { group == "session" ? 5 * 3600 : 7 * 86400 }
}

public struct ExtraUsage: Codable, Hashable {
    public let used: Double
    public let limit: Double
    public let currency: String
    public let percent: Double
    public let reached: Bool
    public init(used: Double, limit: Double, currency: String, percent: Double, reached: Bool) {
        self.used = used; self.limit = limit; self.currency = currency; self.percent = percent; self.reached = reached
    }
}

/// Anthropic's own split of the weekly window by product (Claude Code / Chats / Cowork).
public struct BreakdownRow: Codable, Hashable {
    public let name: String
    public let percent: Double
    public init(name: String, percent: Double) { self.name = name; self.percent = percent }
}

/// What the app shares with its widgets (App Group) and the iPhone (Scriptable's iCloud folder).
public struct Snapshot: Codable {
    public var version = 1
    public var fetchedAt: Date
    public var limits: [UsageLimit]
    public var extra: ExtraUsage?
    public var breakdown: [BreakdownRow]
    public var error: String?
    public var errorAt: Date?
    public var source = "mac"

    public init(fetchedAt: Date, limits: [UsageLimit], extra: ExtraUsage?, breakdown: [BreakdownRow],
                error: String? = nil, errorAt: Date? = nil) {
        self.fetchedAt = fetchedAt; self.limits = limits; self.extra = extra; self.breakdown = breakdown
        self.error = error; self.errorAt = errorAt
    }

    public var session: UsageLimit? { limits.first { $0.group == "session" } }
    public var weekly: UsageLimit? { limits.first { $0.key == "weekly_all" } ?? limits.first { $0.group == "weekly" } }

    /// Error newer than the reading, or a reading older than `staleAfter`.
    public func staleReason(staleAfter: TimeInterval, now: Date = Date()) -> String? {
        if let e = error, let at = errorAt, at > fetchedAt { return e }
        let age = now.timeIntervalSince(fetchedAt)
        if age > staleAfter { return "No successful update for \(Int(age / 60)) min" }
        return nil
    }
}

public enum SnapshotStore {
    public static let groupID = "KFT88Q5XQ9.com.joshhotz.usagebarapp"

    public static var url: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("snapshot.json")
    }

    public static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    public static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    public static func load(from url: URL? = SnapshotStore.url) -> Snapshot? {
        guard let url, let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(Snapshot.self, from: data)
    }

    public static func save(_ snapshot: Snapshot, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }
}

public enum UsageStyle {
    public static let green = Color(red: 0x34 / 255.0, green: 0xC7 / 255.0, blue: 0x59 / 255.0)
    public static let amber = Color(red: 0xFF / 255.0, green: 0x9F / 255.0, blue: 0x0A / 255.0)
    public static let red = Color(red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x30 / 255.0)
    public static let dim = Color(red: 0x8E / 255.0, green: 0x8E / 255.0, blue: 0x93 / 255.0)

    /// Same bands as UsageBar: green under 70, amber 70–89, red 90+.
    public static func color(for percent: Double) -> Color {
        percent >= 90 ? red : (percent >= 70 ? amber : green)
    }

    /// "2h14m" / "45m" for the menu bar.
    public static func shortCountdown(_ seconds: TimeInterval) -> String {
        let m = max(0, Int(seconds / 60))
        return m >= 60 ? "\(m / 60)h\(String(format: "%02d", m % 60))m" : "\(m)m"
    }

    /// "today 11:00 PM (in 2h 14m)" / "Sun, Nov 8 4:00 AM (in 6d 7h)".
    public static func resetText(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "reset time unknown" }
        return "\(dayTime(date)) (in \(duration(date.timeIntervalSince(now))))"
    }

    /// "today 11:00 PM", "tomorrow 9:00 AM", "Sun, Nov 8 4:00 AM".
    public static func dayTime(_ date: Date) -> String {
        let cal = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if cal.isDateInToday(date) { return "today \(time)" }
        if cal.isDateInTomorrow(date) { return "tomorrow \(time)" }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + " \(time)"
    }

    /// "6d 7h", "2h 14m", "45m".
    public static func duration(_ seconds: TimeInterval) -> String {
        let s = Int(max(0, seconds))
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
        return d > 0 ? "\(d)d \(h)h" : (h > 0 ? "\(h)h \(m)m" : "\(m)m")
    }
}
