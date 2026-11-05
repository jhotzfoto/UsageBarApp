import Foundation

/// History built from the readings log (+ daily rollups): 5-hour windows, days and weekly windows.
public enum History {
    public static let sessionLength: TimeInterval = 5 * 3600

    public struct Window: Hashable, Identifiable {
        public var id: Date { reset }
        public let reset: Date
        public var start: Date { reset.addingTimeInterval(-History.sessionLength) }
        public let peak: Double
        public let done: Bool
        /// Unused % at reset (nil while the window is still running).
        public var unused: Double? { done ? max(0, 100 - peak) : nil }
    }

    public struct Day: Hashable, Identifiable {
        public var id: Date { date }
        public let date: Date              // local midnight
        public let windows: Int
        public let avgPeak: Double?
        public let idleHours: Double
        public let trackedHours: Double
        public let weeklyEnd: Double?      // weekly (all models) % at the end of the day
    }

    public struct Week: Hashable, Identifiable {
        public var id: Date { reset }
        public let reset: Date
        public var start: Date { reset.addingTimeInterval(-7 * 86400) }
        public let windows: Int
        public let avgPeak: Double?
        public let idleHours: Double
        public let weeklyPeak: Double
        public let trend: [(Date, Double)]
        public static func == (a: Week, b: Week) -> Bool { a.reset == b.reset && a.weeklyPeak == b.weeklyPeak && a.windows == b.windows }
        public func hash(into h: inout Hasher) { h.combine(reset) }
    }

    public static func minute(_ d: Date) -> Date { Date(timeIntervalSince1970: (d.timeIntervalSince1970 / 60).rounded() * 60) }

    /// Session windows with a non-zero peak, newest last.
    public static func windows(readings: [Reading], daily: [DailyRow], now: Date = Date()) -> [Window] {
        var peaks: [Date: Double] = [:]
        for d in daily where d.key == "session" {
            for (r, p) in d.sessionWindows { peaks[minute(r)] = max(peaks[minute(r)] ?? 0, p) }
        }
        for r in readings where r.key == "session" {
            guard let reset = r.resetsAt else { continue }
            peaks[minute(reset)] = max(peaks[minute(reset)] ?? 0, r.percent)
        }
        return peaks.filter { $0.value > 0 }.keys.sorted().map { Window(reset: $0, peak: peaks[$0]!, done: $0 <= now) }
    }

    public static func historyStart(readings: [Reading], daily: [DailyRow]) -> Date? {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let fromDaily = daily.compactMap { df.date(from: $0.date) }.min()
        let fromRaw = readings.map(\.ts).min()
        return [fromDaily, fromRaw].compactMap { $0 }.min()
    }

    /// Per local day: windows used, average peak, idle hours (no active session) and weekly % at end.
    public static func days(readings: [Reading], daily: [DailyRow], now: Date = Date(), calendar: Calendar = .current) -> [Day] {
        guard let first = historyStart(readings: readings, daily: daily) else { return [] }
        let wins = windows(readings: readings, daily: daily, now: now)
        var weeklyByDay: [Date: Double] = [:]
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        for d in daily where d.key == "weekly_all" {
            if let day = df.date(from: d.date) { weeklyByDay[calendar.startOfDay(for: day)] = d.lastPercent }
        }
        for r in readings.sorted(by: { $0.ts < $1.ts }) where r.key == "weekly_all" {
            weeklyByDay[calendar.startOfDay(for: r.ts)] = r.percent
        }
        var out: [Day] = []
        var day = calendar.startOfDay(for: first)
        while day <= now {
            let next = calendar.date(byAdding: .day, value: 1, to: day)!
            let from = max(day, first), to = min(next, now)
            let tracked = max(0, to.timeIntervalSince(from))
            let todays = wins.filter { calendar.isDate($0.reset.addingTimeInterval(-1), inSameDayAs: day) }
            // Active time = union of window intervals overlapping the day.
            var spans: [(Date, Date)] = wins.compactMap { w in
                let s = max(w.start, from), e = min(w.reset, to)
                return s < e ? (s, e) : nil
            }.sorted { $0.0 < $1.0 }
            var active: TimeInterval = 0
            var cur: (Date, Date)? = nil
            for sp in spans {
                if let c = cur, sp.0 <= c.1 { cur = (c.0, max(c.1, sp.1)) }
                else { if let c = cur { active += c.1.timeIntervalSince(c.0) }; cur = sp }
            }
            if let c = cur { active += c.1.timeIntervalSince(c.0) }
            spans.removeAll()
            let peaks = todays.map(\.peak)
            out.append(Day(date: day, windows: todays.count, avgPeak: peaks.isEmpty ? nil : peaks.reduce(0, +) / Double(peaks.count),
                           idleHours: max(0, tracked - active) / 3600, trackedHours: tracked / 3600,
                           weeklyEnd: weeklyByDay[day]))
            day = next
        }
        return out
    }

    /// One row per weekly window (from the weekly reset times in the log).
    public static func weeks(readings: [Reading], daily: [DailyRow], now: Date = Date()) -> [Week] {
        let weekly = readings.filter { $0.key == "weekly_all" && $0.resetsAt != nil }
        let resets = Set(weekly.map { minute($0.resetsAt!) }).sorted()
        let wins = windows(readings: readings, daily: daily, now: now)
        let ds = days(readings: readings, daily: daily, now: now)
        return resets.map { reset in
            let start = reset.addingTimeInterval(-7 * 86400)
            let inWeek = wins.filter { $0.reset > start && $0.reset <= reset }
            let rs = weekly.filter { minute($0.resetsAt!) == reset }.sorted { $0.ts < $1.ts }
            let dsIn = ds.filter { $0.date >= Calendar.current.startOfDay(for: start) && $0.date < reset }
            // Last reading of each day.
            var byDay: [Date: (Date, Double)] = [:]
            for r in rs { byDay[Calendar.current.startOfDay(for: r.ts)] = (r.ts, r.percent) }
            let trend = byDay.values.sorted { $0.0 < $1.0 }
            let peaks = inWeek.map(\.peak)
            return Week(reset: reset, windows: inWeek.count, avgPeak: peaks.isEmpty ? nil : peaks.reduce(0, +) / Double(peaks.count),
                        idleHours: dsIn.reduce(0) { $0 + $1.idleHours }, weeklyPeak: rs.map(\.percent).max() ?? 0, trend: trend)
        }
    }
}
