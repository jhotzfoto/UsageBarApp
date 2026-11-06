import Foundation

/// Turns the usage endpoint's JSON into a Snapshot. Renders every limit the API returns.
public enum UsageParser {
    public enum ParseError: LocalizedError {
        case noLimits
        public var errorDescription: String? { "Response had no limits" }
    }

    public static func snapshot(from raw: [String: Any], at now: Date = Date()) throws -> Snapshot {
        let limits = parseLimits(raw)
        guard !limits.isEmpty else { throw ParseError.noLimits }
        return Snapshot(fetchedAt: now, limits: limits, extra: parseExtra(raw), breakdown: parseBreakdown(raw))
    }

    /// ISO 8601 with or without fractions (1–6 digits); seconds precision is enough.
    public static func date(_ v: Any?) -> Date? {
        guard let str = v as? String, !str.isEmpty else { return nil }
        if let d = fastISO(str) { return d }
        // Drop a fractional part without a regex (this runs for every row of the log).
        var s = Substring(str)
        if let dot = s.firstIndex(of: ".") {
            var end = s.index(after: dot)
            while end < s.endIndex, s[end].isNumber { end = s.index(after: end) }
            s = s[..<dot] + s[end...]
        }
        return isoLock.withLock { iso.date(from: String(s)) }
    }
    /// Fast path for "YYYY-MM-DDTHH:MM:SS[.fff][Z|±HH:MM]" (every row of the log); nil if it doesn't fit.
    static func fastISO(_ s: String) -> Date? {
        let u = Array(s.utf8)
        guard u.count >= 19, u[4] == 45, u[7] == 45, u[10] == 84 || u[10] == 32, u[13] == 58, u[16] == 58 else { return nil }
        func num(_ a: Int, _ n: Int) -> Int? {
            var v = 0
            for i in a..<(a + n) { let c = Int(u[i]) - 48; guard c >= 0 && c <= 9 else { return nil }; v = v * 10 + c }
            return v
        }
        guard let y = num(0, 4), let mo = num(5, 2), let d = num(8, 2), let h = num(11, 2), let mi = num(14, 2), let sec = num(17, 2),
              (1...12).contains(mo), (1...31).contains(d) else { return nil }
        var i = 19
        if i < u.count, u[i] == 46 { i += 1; while i < u.count, u[i] >= 48, u[i] <= 57 { i += 1 } }
        var offset = 0
        if i == u.count || u[i] == 90 { offset = 0 }
        else if u[i] == 43 || u[i] == 45, u.count >= i + 6, u[i + 3] == 58, let oh = num(i + 1, 2), let om = num(i + 4, 2) {
            offset = (oh * 3600 + om * 60) * (u[i] == 45 ? -1 : 1)
        } else { return nil }
        // Days from civil (Howard Hinnant's algorithm).
        let yy = mo <= 2 ? y - 1 : y
        let era = (yy >= 0 ? yy : yy - 399) / 400
        let yoe = yy - era * 400
        let doy = (153 * (mo + (mo > 2 ? -3 : 9)) + 2) / 5 + d - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        let days = era * 146097 + doe - 719468
        return Date(timeIntervalSince1970: TimeInterval(days * 86400 + h * 3600 + mi * 60 + sec - offset))
    }

    private static let iso = ISO8601DateFormatter()
    private static let isoLock = NSLock()

    public static func parseLimits(_ raw: [String: Any]) -> [UsageLimit] {
        var out: [UsageLimit] = []
        if let list = raw["limits"] as? [[String: Any]] {
            for l in list {
                guard let kind = l["kind"] as? String, let pct = (l["percent"] as? NSNumber)?.doubleValue else { continue }
                let reset = date(l["resets_at"])
                switch kind {
                case "session":
                    out.append(UsageLimit(key: "session", label: "Session (5h)", group: "session", percent: pct, resetsAt: reset))
                case "weekly_all":
                    out.append(UsageLimit(key: "weekly_all", label: "Weekly · all models", group: "weekly", percent: pct, resetsAt: reset))
                default:
                    let scope = l["scope"] as? [String: Any]
                    let model = (scope?["model"] as? [String: Any])?["display_name"] as? String
                    let name = model ?? ((scope?["surface"] as? [String: Any])?["display_name"] as? String) ?? kind
                    out.append(UsageLimit(key: "weekly_" + name.lowercased(), label: "Weekly · \(name)",
                                          group: (l["group"] as? String) ?? "weekly", percent: pct, resetsAt: reset))
                }
            }
        }
        if out.isEmpty {   // legacy top-level windows
            let legacy: [(String, String, String)] = [("five_hour", "Session (5h)", "session"),
                                                      ("seven_day", "Weekly · all models", "weekly"),
                                                      ("seven_day_opus", "Weekly · Opus", "weekly"),
                                                      ("seven_day_sonnet", "Weekly · Sonnet", "weekly")]
            for (k, label, group) in legacy {
                guard let w = raw[k] as? [String: Any], let u = (w["utilization"] as? NSNumber)?.doubleValue else { continue }
                let key = k == "five_hour" ? "session" : (k == "seven_day" ? "weekly_all" : k)
                out.append(UsageLimit(key: key, label: label, group: group, percent: u, resetsAt: date(w["resets_at"])))
            }
        }
        return out
    }

    public static func parseExtra(_ raw: [String: Any]) -> ExtraUsage? {
        let reached = ((raw["extra_usage"] as? [String: Any])?["spend_limit_reached"] as? Bool) ?? false
        if let sp = raw["spend"] as? [String: Any], (sp["enabled"] as? Bool) == true,
           let lim = sp["limit"] as? [String: Any] {
            func money(_ m: [String: Any]?) -> Double {
                let minor = (m?["amount_minor"] as? NSNumber)?.doubleValue ?? 0
                let exp = (m?["exponent"] as? NSNumber)?.intValue ?? 2
                return minor / pow(10, Double(exp))
            }
            let limit = money(lim), used = money(sp["used"] as? [String: Any])
            guard limit > 0 else { return nil }
            let pct = (sp["percent"] as? NSNumber)?.doubleValue ?? used / limit * 100
            return ExtraUsage(used: used, limit: limit, currency: lim["currency"] as? String ?? "", percent: pct, reached: reached)
        }
        if let ex = raw["extra_usage"] as? [String: Any], (ex["is_enabled"] as? Bool) == true,
           let ml = (ex["monthly_limit"] as? NSNumber)?.doubleValue, ml > 0 {
            let d = pow(10, (ex["decimal_places"] as? NSNumber)?.doubleValue ?? 2)
            let used = ((ex["used_credits"] as? NSNumber)?.doubleValue ?? 0) / d
            return ExtraUsage(used: used, limit: ml / d, currency: ex["currency"] as? String ?? "",
                              percent: used / (ml / d) * 100, reached: reached)
        }
        return nil
    }

    public static func parseBreakdown(_ raw: [String: Any]) -> [BreakdownRow] {
        guard let b = raw["seven_day_breakdown"] as? [String: Any], let rows = b["rows"] as? [[String: Any]] else { return [] }
        return rows.compactMap { r in
            guard let n = r["display_name"] as? String, let p = (r["percent"] as? NSNumber)?.doubleValue else { return nil }
            return BreakdownRow(name: n, percent: p)
        }.sorted { $0.percent > $1.percent }
    }
}
