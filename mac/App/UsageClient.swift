import Foundation

/// Reads usage from api.anthropic.com/api/oauth/usage with Claude Code's OAuth access token.
/// The token comes from the Keychain item "Claude Code-credentials", read with /usr/bin/security
/// (the same way UsageBar does). Only accessToken and expiresAt are read; the item is never
/// written or refreshed, and the refresh token is never used.
enum UsageClient {
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let keychainService = "Claude Code-credentials"
    static let claudeBin = "/opt/homebrew/bin/claude"

    enum FetchError: LocalizedError {
        case message(String)
        case rateLimited(retryAfter: TimeInterval)
        var errorDescription: String? {
            switch self {
            case .message(let m): return m
            case .rateLimited: return "Rate limited by usage endpoint"
            }
        }
    }

    // MARK: token

    static func readToken() throws -> String {
        let out = try run("/usr/bin/security", ["find-generic-password", "-s", keychainService, "-w"])
        guard let data = out.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = obj["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String, !token.isEmpty
        else { throw FetchError.message("No Claude Code login found. Run `claude` once.") }
        if let exp = oauth["expiresAt"] as? Double, exp / 1000 < Date().timeIntervalSince1970 {
            throw FetchError.message("Claude Code login expired. Open Claude Code to refresh it.")
        }
        return token
    }

    /// `claude --version`, cached for a day (it's slow and memory-heavy).
    static func claudeVersion() -> String {
        let d = UserDefaults.standard
        if let v = d.string(forKey: "claudeVersion"),
           Date().timeIntervalSince1970 - d.double(forKey: "claudeVersionAt") < 86400 { return v }
        let v = (try? run(claudeBin, ["--version"]))?.split(separator: " ").first.map(String.init) ?? "2.0.0"
        d.set(v, forKey: "claudeVersion")
        d.set(Date().timeIntervalSince1970, forKey: "claudeVersionAt")
        return v
    }

    // MARK: fetch

    static func fetch() async throws -> [String: Any] {
        let token = try readToken()
        var req = URLRequest(url: usageURL, timeoutInterval: 20)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("claude-code/\(claudeVersion())", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let http = resp as? HTTPURLResponse
        switch http?.statusCode ?? 0 {
        case 200: break
        case 429:
            let ra = TimeInterval(http?.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 120
            throw FetchError.rateLimited(retryAfter: max(60, ra))
        case 401, 403:
            throw FetchError.message("Login refused (HTTP \(http!.statusCode)). Open Claude Code to refresh it.")
        case let code:
            throw FetchError.message("Usage endpoint returned HTTP \(code)")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FetchError.message("Unexpected response")
        }
        return obj
    }

    // MARK: parse

    static func snapshot(from raw: [String: Any], at now: Date = Date()) throws -> Snapshot {
        let limits = parseLimits(raw)
        guard !limits.isEmpty else { throw FetchError.message("Response had no limits") }
        return Snapshot(fetchedAt: now, limits: limits, extra: parseExtra(raw), breakdown: parseBreakdown(raw))
    }

    static func date(_ v: Any?) -> Date? {
        guard var s = v as? String else { return nil }
        // Fractions of 1–6 digits; seconds precision is enough.
        if let r = s.range(of: #"\.\d+"#, options: .regularExpression) { s.removeSubrange(r) }
        return ISO8601DateFormatter().date(from: s.replacingOccurrences(of: "Z", with: "+00:00"))
    }

    static func parseLimits(_ raw: [String: Any]) -> [UsageLimit] {
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
                    let model = ((scope?["model"] as? [String: Any])?["display_name"] as? String)
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

    static func parseExtra(_ raw: [String: Any]) -> ExtraUsage? {
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

    static func parseBreakdown(_ raw: [String: Any]) -> [BreakdownRow] {
        guard let b = raw["seven_day_breakdown"] as? [String: Any], let rows = b["rows"] as? [[String: Any]] else { return [] }
        return rows.compactMap { r in
            guard let n = r["display_name"] as? String, let p = (r["percent"] as? NSNumber)?.doubleValue else { return nil }
            return BreakdownRow(name: n, percent: p)
        }.sorted { $0.percent > $1.percent }
    }

    // MARK: helpers

    static func run(_ path: String, _ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = FileHandle.nullDevice
        try p.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw FetchError.message("\(URL(fileURLWithPath: path).lastPathComponent) failed") }
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
