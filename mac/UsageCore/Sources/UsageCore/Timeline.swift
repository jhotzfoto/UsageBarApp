import Foundation

/// One day split into 30- or 60-minute slots: how much session % was used in each, and whether a
/// 5-hour session was running (active), none was (idle: capacity you could have used), or the Mac
/// wasn't recording (no data, e.g. asleep).
extension History {
    public enum SlotState: String { case active, idle, noData, future }

    public struct Slot: Identifiable, Hashable {
        public var id: Date { start }
        public let start: Date
        public let end: Date
        public let used: Double        // session % gained in this slot
        public let state: SlotState
    }

    public struct DayTimeline {
        public let day: Date
        public let slots: [Slot]
        public let windows: [Window]       // 5-hour windows overlapping the day
        public let used: Double            // session % gained during the day
        public let unusedAtReset: Double   // sum of what was left when this day's windows reset
        public let idleHours: Double       // recorded time with no session running
        public let noDataHours: Double
        /// Idle time expressed as full 5-hour sessions that could have run.
        public var idleSessions: Double { idleHours / 5 }
    }

    public static func timeline(day: Date, slotMinutes: Int, readings: [Reading], windows: [Window],
                                now: Date = Date(), calendar: Calendar = .current) -> DayTimeline {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let slotLen = TimeInterval(slotMinutes * 60)
        let sorted = readings.sorted { $0.ts < $1.ts }
        let inDay = sorted.filter { $0.ts >= start && $0.ts < end }

        // Session % gained between consecutive readings, credited to the later reading's slot.
        var gain: [Int: Double] = [:]
        var prev = sorted.last { $0.key == "session" && $0.resetsAt != nil && $0.ts < start }
        for r in inDay where r.key == "session" {
            guard let reset = r.resetsAt else { continue }
            let g: Double
            if let p = prev, let pr = p.resetsAt, minute(pr) == minute(reset) {
                g = max(0, r.percent - p.percent)
            } else {
                g = r.percent   // first reading of a new window: everything since it started
            }
            if g > 0 { gain[Int(r.ts.timeIntervalSince(start) / slotLen), default: 0] += g }
            prev = r
        }

        let wins = windows.filter { $0.start < end && $0.reset > start }
        // Which slots had any reading at all (the Mac was awake and recording).
        var seen = Set<Int>()
        for r in inDay { seen.insert(Int(r.ts.timeIntervalSince(start) / slotLen)) }

        var slots: [Slot] = []
        var idle: TimeInterval = 0, noData: TimeInterval = 0
        var s = start, i = 0
        while s < end {
            let e = min(end, s.addingTimeInterval(slotLen))
            let state: SlotState
            if s >= now { state = .future }
            else if wins.contains(where: { $0.start < e && $0.reset > s }) { state = .active }
            else if seen.contains(i) { state = .idle }
            else { state = .noData }
            let len = max(0, min(e, now).timeIntervalSince(s))
            if state == .idle { idle += len } else if state == .noData { noData += len }
            slots.append(Slot(start: s, end: e, used: gain[i] ?? 0, state: state))
            s = e; i += 1
        }
        let unused = windows.filter { $0.done && $0.reset > start && $0.reset <= end }.compactMap(\.unused).reduce(0, +)
        return DayTimeline(day: start, slots: slots, windows: wins, used: slots.reduce(0) { $0 + $1.used },
                           unusedAtReset: unused, idleHours: idle / 3600, noDataHours: noData / 3600)
    }
}
