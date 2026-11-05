import Foundation

/// Editable alert settings (same defaults as UsageBar, plus extra usage and outages).
public struct AlertConfig: Codable, Equatable {
    public var sessionOn = true
    public var sessionThresholds: [Double] = [80, 95]
    public var weeklyOn = true
    public var weeklyThresholds: [Double] = [75, 90]
    public var extraOn = true
    public var extraThresholds: [Double] = [80, 95, 100]
    public var timeLeftOn = true
    public var timeLeftMinutes: [Double] = [60, 15]
    public var timeLeftOnlyBelow: Double = 70
    public var newSessionOn = true
    public var weeklyResetSoonOn = true
    public var weeklyResetSoonHours: Double = 24
    public var staleOn = true
    public var staleMinutes: Double = 30
    public var outageOn = true

    public init() {}

    /// "80, 95" -> [80, 95]; ignores junk, keeps 1–100 (minutes: 1–300), sorted, no duplicates.
    public static func parseList(_ s: String, max: Double = 100) -> [Double]? {
        let v = s.split(whereSeparator: { $0 == "," || $0 == " " || $0 == ";" }).compactMap { Double($0) }
            .filter { $0 > 0 && $0 <= max }
        let out = Array(Set(v)).sorted()
        return out.isEmpty ? nil : out
    }
    public static func listText(_ v: [Double]) -> String { v.map { $0 == $0.rounded() ? String(Int($0)) : String($0) }.joined(separator: ", ") }
}

public struct AlertState: Codable, Equatable {
    public var sent: [String: Date] = [:]
    public var activeSessionReset: Date?
    public init() {}
}

public struct PendingAlert: Equatable {
    public let title: String
    public let body: String
}

/// Decides which alerts to send. Pure: the caller delivers them and stores the state. Each alert fires
/// once per window; when several thresholds are crossed at once only the highest is sent.
public enum AlertEngine {
    public static func evaluate(_ snap: Snapshot?, config c: AlertConfig, state: inout AlertState, now: Date = Date()) -> [PendingAlert] {
        guard let snap, !snap.limits.isEmpty else { return [] }
        var out: [PendingAlert] = []
        state.sent = state.sent.filter { now.timeIntervalSince($0.value) < 8 * 86400 }

        func once(_ k: String, _ t: String, _ b: String) {
            guard state.sent[k] == nil else { return }
            state.sent[k] = now
            out.append(PendingAlert(title: t, body: b))
        }
        func crossed(_ prefix: String, _ value: Double, _ th: [Double], _ title: (Double) -> String, _ body: (Double) -> String) {
            let hit = th.filter { value >= $0 }
            let fresh = hit.filter { state.sent["\(prefix)|\($0)"] == nil }
            guard let top = fresh.max() else { return }
            out.append(PendingAlert(title: title(top), body: body(top)))
            for t in hit where state.sent["\(prefix)|\(t)"] == nil { state.sent["\(prefix)|\(t)"] = now }
        }
        func key(_ d: Date) -> String { String(Int((d.timeIntervalSince1970 / 60).rounded())) }

        if let s = snap.session, let reset = s.resetsAt, !s.hasReset(at: now) {
            if c.sessionOn {
                crossed("sp|\(key(reset))", s.percent, c.sessionThresholds,
                        { _ in "Claude session at \(Int(s.percent))%" },
                        { "Session passed \(Int($0))%. Resets \(UsageStyle.resetText(reset, now: now))." })
            }
            if c.timeLeftOn, s.percent < c.timeLeftOnlyBelow, s.percent > 0 {
                let mins = reset.timeIntervalSince(now) / 60
                let due = c.timeLeftMinutes.filter { mins <= $0 }
                if let m = due.min(), state.sent["stl|\(key(reset))|\(m)"] == nil {
                    out.append(PendingAlert(title: "Claude session: \(Int(mins.rounded())) min left",
                                            body: "\(Int(s.percent))% used. Use it or lose it: resets \(UsageStyle.dayTime(reset))."))
                    for d in due { state.sent["stl|\(key(reset))|\(d)"] = now }
                }
            }
            if s.percent > 0 { state.activeSessionReset = reset }
        }
        if let prev = state.activeSessionReset, prev <= now {
            if c.newSessionOn {
                once("ns|\(key(prev))", "New Claude session available",
                     "Your 5-hour limit reset at \(prev.formatted(date: .omitted, time: .shortened)).")
            }
            state.activeSessionReset = nil
        }
        for w in snap.limits where w.group == "weekly" && !w.hasReset(at: now) {
            guard let reset = w.resetsAt else { continue }
            if c.weeklyOn {
                crossed("wp|\(w.label)|\(key(reset))", w.percent, c.weeklyThresholds,
                        { _ in "\(w.label) at \(Int(w.percent))%" },
                        { "Passed \(Int($0))%. Resets \(UsageStyle.resetText(reset, now: now))." })
            }
            if c.weeklyResetSoonOn, w.key == "weekly_all", reset.timeIntervalSince(now) <= c.weeklyResetSoonHours * 3600 {
                once("wr|\(key(reset))", "Weekly limit resets \(UsageStyle.dayTime(reset))",
                     "\(Int(w.percent))% used, \(Int(max(0, 100 - w.percent)))% left before the reset.")
            }
        }
        if c.extraOn, let ex = snap.extra {
            let month = now.formatted(.dateTime.year().month(.twoDigits))
            crossed("ex|\(month)|\(ex.limit)", ex.percent, c.extraThresholds,
                    { _ in "Extra usage at \(Int(ex.percent))% of monthly budget" },
                    { "Passed \(Int($0))%: \(String(format: "$%.2f of $%.2f", ex.used, ex.limit)) \(ex.currency) used." })
        }
        if c.staleOn, snap.staleReason(staleAfter: c.staleMinutes * 60, now: now) != nil {
            once("st|\(Int(snap.fetchedAt.timeIntervalSince1970))", "Claude usage not updating",
                 snap.error ?? "No successful update for \(Int(c.staleMinutes)) minutes.")
        }
        return out
    }

    /// Outage alerts: once per incident.
    public static func evaluate(status: ServiceStatus?, config c: AlertConfig, state: inout AlertState, now: Date = Date()) -> [PendingAlert] {
        guard c.outageOn, let status else { return [] }
        var out: [PendingAlert] = []
        for i in status.incidents where state.sent["inc|\(i.id)"] == nil {
            state.sent["inc|\(i.id)"] = now
            out.append(PendingAlert(title: "Claude incident: \(i.name)",
                                    body: "\(i.status.capitalized) · impact \(i.impact). status.anthropic.com"))
        }
        return out
    }
}
