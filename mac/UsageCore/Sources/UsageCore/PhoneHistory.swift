import Foundation

/// The history the iPhone's "Claude History" widget draws (UsageBarApp/history.json in Scriptable's
/// iCloud folder): today's half-hour timeline and a summary of the last 7 days. Usage numbers and
/// times only, no chat titles.
public struct PhoneHistory: Codable, Equatable {
    public struct Slot: Codable, Equatable {
        public let used: Double
        public let state: String      // active, idle, noData, future
    }
    /// A point on today's session % line: minutes since midnight, %, and segment (breaks at gaps).
    public struct Point: Codable, Equatable {
        public let m: Double
        public let p: Double
        public let s: Int
    }
    public struct Reset: Codable, Equatable {
        public let at: Date
        public let unused: Double
    }
    public struct Day: Codable, Equatable {
        public let date: Date         // local midnight
        public let used: Double       // session % gained
        public let unusedAtReset: Double
        public let idleHours: Double
        public let noDataHours: Double
        public let windows: Int
    }

    public let generatedAt: Date
    public let day: Date
    public let slotMinutes: Int
    public let slots: [Slot]
    public let line: [Point]
    public let resets: [Reset]
    public let today: Day
    public let days: [Day]            // oldest first, today last

    public static func build(readings: [Reading], windows: [History.Window], now: Date = Date(),
                             calendar: Calendar = .current, pastDays: Int = 7) -> PhoneHistory {
        func summary(_ tl: History.DayTimeline) -> Day {
            Day(date: tl.day, used: tl.used, unusedAtReset: tl.unusedAtReset, idleHours: tl.idleHours,
                noDataHours: tl.noDataHours, windows: tl.windows.filter { $0.reset > tl.day && $0.reset <= tl.day.addingTimeInterval(86400) }.count)
        }
        let start = calendar.startOfDay(for: now)
        // One sort for all days (timeline() sorts what it's given).
        let sorted = readings.sorted { $0.ts < $1.ts }
        let from = calendar.date(byAdding: .day, value: -(pastDays - 1), to: start)!.addingTimeInterval(-86400)
        let recent = sorted.filter { $0.ts >= from }
        let today = History.timeline(day: start, slotMinutes: 30, readings: recent, windows: windows, now: now, calendar: calendar)
        var days: [Day] = []
        for back in stride(from: pastDays - 1, to: 0, by: -1) {
            let d = calendar.date(byAdding: .day, value: -back, to: start)!
            days.append(summary(History.timeline(day: d, slotMinutes: 60, readings: recent, windows: windows, now: now, calendar: calendar)))
        }
        days.append(summary(today))
        let resets = today.windows.filter { $0.done && $0.reset > today.day && $0.reset <= today.day.addingTimeInterval(86400) }
            .map { Reset(at: $0.reset, unused: $0.unused ?? 0) }
        let line = History.sessionLine(day: start, readings: recent, now: now, calendar: calendar)
            .map { Point(m: ($0.ts.timeIntervalSince(start) / 60).rounded(), p: $0.percent, s: $0.segment) }
        return PhoneHistory(generatedAt: now, day: start, slotMinutes: 30,
                            slots: today.slots.map { Slot(used: ($0.used * 10).rounded() / 10, state: $0.state.rawValue) },
                            line: line, resets: resets, today: summary(today), days: days)
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try SnapshotStore.encoder.encode(self).write(to: url, options: .atomic)
    }
}
