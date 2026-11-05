import Foundation

/// Text for Claude Code's status line. The app writes it to a file once a minute; the status line
/// command only prints that file, so it costs nothing per prompt.
public enum Statusline {
    static func ansi(_ p: Double) -> String { p >= 90 ? "\u{1B}[31m" : (p >= 70 ? "\u{1B}[33m" : "\u{1B}[32m") }
    static let dim = "\u{1B}[2m", reset = "\u{1B}[0m"

    /// "S 64% 2h14m · W 33% · pace: 100% at 9:40 PM" (colored), or a dimmed stale note.
    public static func text(_ snap: Snapshot?, sessionPace: Forecast.Pace?, staleAfter: TimeInterval, now: Date = Date(), color: Bool = true) -> String {
        guard let snap, !snap.limits.isEmpty else { return "Claude usage: no reading yet" }
        func c(_ s: String, _ p: Double) -> String { color ? ansi(p) + s + reset : s }
        var parts: [String] = []
        if let s = snap.session {
            let p = s.effectivePercent(at: now)
            var t = "S \(Int(p))%"
            if let r = s.resetsAt, r > now, s.percent > 0 { t += " " + UsageStyle.shortCountdown(r.timeIntervalSince(now)) }
            parts.append(c(t, p))
        }
        if let w = snap.weekly { parts.append(c("W \(Int(w.effectivePercent(at: now)))%", w.effectivePercent(at: now))) }
        if let ex = snap.extra, ex.used > 0 || ex.reached { parts.append(c("E \(Int(ex.percent))%", ex.percent)) }
        if let p = sessionPace, let h = p.hitsLimitAt, let s = snap.session, s.percent < 100 {
            parts.append("pace: 100% at \(h.formatted(date: .omitted, time: .shortened))")
        }
        var line = parts.joined(separator: " · ")
        if snap.staleReason(staleAfter: staleAfter, now: now) != nil {
            let t = "(as of \(snap.fetchedAt.formatted(date: .omitted, time: .shortened)))"
            line += " " + (color ? dim + t + reset : t)
        }
        return line
    }
}
