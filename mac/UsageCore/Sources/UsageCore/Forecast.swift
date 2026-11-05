import Foundation

/// Pace forecast and planning, from the readings log.
public enum Forecast {
    public struct Pace: Hashable {
        public let percentPerHour: Double
        public let projectedAtReset: Double     // may exceed 100 (the limit would stop you first)
        public let hitsLimitAt: Date?           // nil if it won't reach 100% before the reset
        public let basis: String                // "last 60 min", "since the window started"
        /// Unused % at reset if this pace continues.
        public var projectedUnused: Double { max(0, 100 - projectedAtReset) }
    }

    /// Recent pace for a limit: the rate over the recent period (60 min for the session, 24 h for weekly
    /// limits) when there's enough data in it, else the average since the window started.
    public static func pace(for limit: UsageLimit, readings: [Reading], now: Date = Date()) -> Pace? {
        guard let reset = limit.resetsAt, reset > now else { return nil }
        let start = reset.addingTimeInterval(-limit.windowLength)
        let recent: TimeInterval = limit.group == "session" ? 3600 : 86400
        let same = readings.filter { $0.key == limit.key && $0.resetsAt.map { abs($0.timeIntervalSince(reset)) < 120 } == true }
            .sorted { $0.ts < $1.ts }
        let pct = limit.percent
        var rate: Double     // % per second
        var basis: String
        let windowStartInRecent = start > now.addingTimeInterval(-recent)
        if !windowStartInRecent, let base = same.last(where: { $0.ts <= now.addingTimeInterval(-recent) }) ?? same.first,
           now.timeIntervalSince(base.ts) >= recent / 4, base.ts > start {
            rate = (pct - base.percent) / now.timeIntervalSince(base.ts)
            basis = limit.group == "session" ? "last \(Int(now.timeIntervalSince(base.ts) / 60)) min"
                                             : "last \(Int(now.timeIntervalSince(base.ts) / 3600)) h"
        } else {
            let elapsed = now.timeIntervalSince(start)
            guard elapsed > 300 else { return nil }
            rate = pct / elapsed
            basis = "since the window started"
        }
        rate = max(0, rate)
        let left = reset.timeIntervalSince(now)
        let projected = pct + rate * left
        var hits: Date? = nil
        if rate > 0, pct < 100 {
            let t = (100 - pct) / rate
            if t < left { hits = now.addingTimeInterval(t) }
        } else if pct >= 100 { hits = now }
        return Pace(percentPerHour: rate * 3600, projectedAtReset: projected, hitsLimitAt: hits, basis: basis)
    }

    /// One-line pace text: "At this pace: 100% at 9:40 PM" / "At this pace: ~62% at reset (38% unused)".
    public static func paceText(_ p: Pace, limit: UsageLimit, now: Date = Date()) -> String {
        if let h = p.hitsLimitAt, limit.percent < 100 {
            return "At this pace: 100% \(UsageStyle.dayTime(h)) (in \(UsageStyle.duration(h.timeIntervalSince(now))))"
        }
        if limit.percent >= 100 { return "Limit reached" }
        if p.percentPerHour < 0.05 { return "No recent use · \(Int(limit.percent))% at reset if idle" }
        return "At this pace: ~\(Int(p.projectedAtReset))% at reset (\(Int(p.projectedUnused))% unused)"
    }

    /// Weekly budget: what's left per remaining day.
    public static func weeklyPlan(_ w: UsageLimit, now: Date = Date()) -> String? {
        guard let reset = w.resetsAt, reset > now else { return nil }
        let days = reset.timeIntervalSince(now) / 86400
        let left = max(0, 100 - w.percent)
        if days < 1 { return "\(Int(left))% left until the weekly reset" }
        return "\(Int(left))% left · about \(Int((left / days).rounded()))% per day for \(Int(days.rounded(.up))) days"
    }

    /// Usual session start hour from recent windows (needs at least 3); nil if there's no pattern.
    public static func usualStartHour(windows: [History.Window], now: Date = Date(), calendar: Calendar = .current) -> Int? {
        let recent = windows.filter { $0.reset > now.addingTimeInterval(-14 * 86400) }
        guard recent.count >= 3 else { return nil }
        var counts: [Int: Int] = [:]
        for w in recent { counts[calendar.component(.hour, from: w.start), default: 0] += 1 }
        guard let best = counts.max(by: { $0.value < $1.value }), best.value >= 2 else { return nil }
        return best.key
    }

    /// Planning line for when the session will reset or has reset.
    public static func nextSessionText(session: UsageLimit?, windows: [History.Window], now: Date = Date()) -> String {
        var t: String
        if let s = session, let r = s.resetsAt, r > now, s.percent > 0 {
            t = "Next session can start \(UsageStyle.dayTime(r))"
        } else {
            t = "A new session starts with your next message"
        }
        if let h = usualStartHour(windows: windows, now: now) {
            var c = DateComponents(); c.hour = h
            let d = Calendar.current.date(from: c).map { $0.formatted(date: .omitted, time: .shortened) } ?? "\(h):00"
            t += " · you usually start around \(d)"
        }
        return t
    }
}
