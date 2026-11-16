import Foundation

/// Keeps the borrowed Claude Code login fresh without anyone opening Claude Code.
///
/// The app never refreshes the login itself (it never touches the refresh token or writes the Keychain
/// item). Instead, when the login is close to running out, it runs Claude Code's own `/usage` command
/// (`claude -p /usage --no-session-persistence`), and Claude Code renews its own login. No model request.
public enum LoginRenewal {
    /// Renew when less than this is left (or already expired). Claude Code only renews in roughly the
    /// last 5 minutes (seen 2026-11-15: no renewal at 29 and 17 min left, renewed at 4 min 44 s left),
    /// so asking earlier just wastes a run. If a check misses this window, the "expired" case renews
    /// right before the next fetch, so readings don't go stale.
    public static let renewWithin: TimeInterval = 4 * 60
    /// Never run the check more often than this.
    public static let minGap: TimeInterval = 10 * 60
    /// Keep the renewal log short.
    public static let maxLogLines = 300

    /// Fields the app reads from the Keychain item's JSON. Only these two; the refresh token is ignored.
    public struct Login: Equatable {
        public let accessToken: String
        public let expiresAt: Date?
        public init(accessToken: String, expiresAt: Date?) {
            self.accessToken = accessToken; self.expiresAt = expiresAt
        }
        public func isExpired(now: Date) -> Bool { expiresAt.map { $0 <= now } ?? false }
    }

    /// Parses the "Claude Code-credentials" JSON. Returns nil if there is no usable access token.
    public static func parse(_ json: String) -> Login? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = obj["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String, !token.isEmpty else { return nil }
        let exp = (oauth["expiresAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        return Login(accessToken: token, expiresAt: exp)
    }

    public enum Reason: String {
        case expired = "expired"
        case expiringSoon = "expiring soon"
        case refused = "login refused"
    }

    /// Whether to run the renewal check now, and why. `refused` = the usage endpoint just said 401/403.
    public static func reason(login: Login?, refused: Bool = false, now: Date, lastAttempt: Date?) -> Reason? {
        if let last = lastAttempt, now.timeIntervalSince(last) < minGap { return nil }
        if refused { return .refused }
        guard let login, let exp = login.expiresAt else { return nil }
        if exp <= now { return .expired }
        if exp.timeIntervalSince(now) < renewWithin { return .expiringSoon }
        return nil
    }

    /// One log line, no secrets: when, why, and the outcome.
    public static func logLine(at: Date, reason: Reason, newExpiry: Date?, error: String?) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        f.timeZone = .current
        let outcome: String
        if let e = error { outcome = "failed: " + e.replacingOccurrences(of: "\n", with: " ") }
        else if let n = newExpiry { outcome = "renewed, good until " + f.string(from: n) }
        else { outcome = "renewed" }
        return "\(f.string(from: at))  \(reason.rawValue)  \(outcome)"
    }

    /// Appends a line to `login_renewals.log` in `directory`, keeping the last `maxLogLines`.
    public static func appendLog(_ line: String, directory: URL) {
        let url = directory.appendingPathComponent("login_renewals.log")
        var lines = ((try? String(contentsOf: url, encoding: .utf8)) ?? "")
            .split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        lines.append(line)
        if lines.count > maxLogLines { lines.removeFirst(lines.count - maxLogLines) }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? (lines.joined(separator: "\n") + "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    /// Where the Claude Code command line tool usually lives (first one that exists wins).
    public static func candidatePaths(home: String) -> [String] {
        ["/opt/homebrew/bin/claude", "/usr/local/bin/claude",
         home + "/.local/bin/claude", home + "/.claude/local/claude", home + "/.npm-global/bin/claude"]
    }
}
