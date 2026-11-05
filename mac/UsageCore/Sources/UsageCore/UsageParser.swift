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
        guard var s = v as? String else { return nil }
        if let r = s.range(of: #"\.\d+"#, options: .regularExpression) { s.removeSubrange(r) }
        return ISO8601DateFormatter().date(from: s.replacingOccurrences(of: "Z", with: "+00:00"))
    }

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
