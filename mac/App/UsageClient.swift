import Foundation
import UsageCore

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

    static func readToken() throws -> String {
        let out = try Shell.run("/usr/bin/security", ["find-generic-password", "-s", keychainService, "-w"])
        guard let data = out.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = obj["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String, !token.isEmpty
        else { throw FetchError.message("No Claude Code login found. Run `claude` once.") }
        if let exp = (oauth["expiresAt"] as? NSNumber)?.doubleValue, exp / 1000 < Date().timeIntervalSince1970 {
            throw FetchError.message("Claude Code login expired. Open Claude Code to refresh it.")
        }
        return token
    }

    /// `claude --version`, cached for a day (it's slow and memory-heavy).
    static func claudeVersion() -> String {
        let d = UserDefaults.standard
        if let v = d.string(forKey: "claudeVersion"),
           Date().timeIntervalSince1970 - d.double(forKey: "claudeVersionAt") < 86400 { return v }
        let v = (try? Shell.run(claudeBin, ["--version"]))?.split(separator: " ").first.map(String.init) ?? "2.0.0"
        d.set(v, forKey: "claudeVersion")
        d.set(Date().timeIntervalSince1970, forKey: "claudeVersionAt")
        return v
    }

    static func fetch() async throws -> [String: Any] {
        let token = try readToken()
        var req = URLRequest(url: usageURL, timeoutInterval: 20)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("claude-code/\(claudeVersion())", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        switch code {
        case 200: break
        case 429:
            let ra = TimeInterval((resp as? HTTPURLResponse)?.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 120
            throw FetchError.rateLimited(retryAfter: max(60, ra))
        case 401, 403:
            throw FetchError.message("Login refused (HTTP \(code)). Open Claude Code to refresh it.")
        default:
            throw FetchError.message("Usage endpoint returned HTTP \(code)")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw FetchError.message("Unexpected response")
        }
        return obj
    }
}

enum Shell {
    /// Runs a program and returns its trimmed stdout; throws on a non-zero exit or timeout.
    static func run(_ path: String, _ args: [String], timeout: TimeInterval = 15) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe(), err = Pipe()
        p.standardOutput = pipe
        p.standardError = err
        try p.run()
        let deadline = DispatchTime.now() + timeout
        DispatchQueue.global().asyncAfter(deadline: deadline) { if p.isRunning { p.terminate() } }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0 else {
            let msg = String(decoding: errData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            throw ShellError(status: p.terminationStatus, stderr: msg)
        }
        return String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    struct ShellError: LocalizedError {
        let status: Int32
        let stderr: String
        var errorDescription: String? { stderr.isEmpty ? "exit \(status)" : stderr }
    }
}
