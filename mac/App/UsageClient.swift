import AppKit
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
        case expired
        var errorDescription: String? {
            switch self {
            case .message(let m): return m
            case .rateLimited: return "Rate limited by usage endpoint"
            case .expired: return "Claude Code login expired. Open Claude Code to refresh it."
            }
        }
    }

    static func readToken() throws -> String {
        // Long timeout: if macOS ever shows a Keychain prompt, you need time to click Always Allow.
        let out: String
        do {
            out = try Shell.run("/usr/bin/security", ["find-generic-password", "-s", keychainService, "-w"], timeout: 120)
        } catch Shell.ShellError.timedOut {
            throw FetchError.message("Waiting for Keychain access: click Always Allow if macOS asks.")
        }
        guard let data = out.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = obj["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String, !token.isEmpty
        else { throw FetchError.message("No Claude Code login found. Run `claude` once.") }
        if let exp = (oauth["expiresAt"] as? NSNumber)?.doubleValue, exp / 1000 < Date().timeIntervalSince1970 {
            throw FetchError.expired
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

extension UsageClient {
    /// Same usage numbers, read through the open claude.ai tab in Chrome (used only when the Claude Code
    /// login has expired). Only when Chrome is already running; never opens or focuses anything.
    /// Async function body for `ChatTracking.pageJob` (async fetch, so the tab never freezes).
    /// `__ORG__` is the org chat tracking already found, or null to pick the first chat org.
    static let chromeUsageScript = #"""
    async function get(u){var r=await fetch(u,{credentials:"same-origin"});
      if(r.status!==200) throw new Error("HTTP "+r.status); return await r.json();}
    try{
      var org=__ORG__;
      if(!org){var orgs=await get("/api/organizations");
        for(var i=0;i<orgs.length;i++){if((orgs[i].capabilities||[]).indexOf("chat")>=0){org=orgs[i].uuid;break;}}}
      return JSON.stringify({ok:true,raw:await get("/api/organizations/"+org+"/usage")});
    }catch(e){return JSON.stringify({ok:false,error:String(e.message||e)});}
    """#

    static func fetchViaChrome(org: String?) async throws -> [String: Any] {
        let running = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.google.Chrome" }
        guard running else { throw FetchError.expired }
        let orgJS = org.flatMap { o in o.allSatisfy { $0.isHexDigit || $0 == "-" } ? "\"\(o)\"" : nil } ?? "null"
        let body = chromeUsageScript.replacingOccurrences(of: "__ORG__", with: orgJS)
        let out = try await Task.detached(priority: .utility) {
            try Shell.run("/usr/bin/osascript", ChatTracking.osascriptArguments(body), timeout: 25)
        }.value
        guard let obj = try? JSONSerialization.jsonObject(with: Data(out.utf8)) as? [String: Any],
              (obj["ok"] as? Bool) == true, let raw = obj["raw"] as? [String: Any] else { throw FetchError.expired }
        return raw
    }
}

enum Shell {
    /// Runs a program and returns its trimmed stdout. Never hangs: output is collected as it arrives
    /// and the process is killed after `timeout` (a child holding the pipe open can't block us).
    static func run(_ path: String, _ args: [String], timeout: TimeInterval = 15) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let outPipe = Pipe(), errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        let lock = NSLock()
        var out = Data(), err = Data()
        outPipe.fileHandleForReading.readabilityHandler = { h in let d = h.availableData; lock.withLock { out.append(d) } }
        errPipe.fileHandleForReading.readabilityHandler = { h in let d = h.availableData; lock.withLock { err.append(d) } }
        let done = DispatchSemaphore(value: 0)
        p.terminationHandler = { _ in done.signal() }
        try p.run()
        let timedOut = done.wait(timeout: .now() + timeout) == .timedOut
        if timedOut {
            p.terminate()
            _ = done.wait(timeout: .now() + 2)
        }
        Thread.sleep(forTimeInterval: 0.05)   // let the last output arrive
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil
        try? outPipe.fileHandleForReading.close()
        try? errPipe.fileHandleForReading.close()
        if timedOut { throw ShellError.timedOut }
        let (o, e) = lock.withLock { (out, err) }
        guard p.terminationStatus == 0 else {
            throw ShellError.failed(status: p.terminationStatus, stderr: String(decoding: e, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return String(decoding: o, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum ShellError: LocalizedError {
        case failed(status: Int32, stderr: String)
        case timedOut
        var stderr: String { if case .failed(_, let e) = self { return e }; return "" }
        var errorDescription: String? {
            switch self {
            case .failed(let st, let e): return e.isEmpty ? "exit \(st)" : e
            case .timedOut: return "timed out"
            }
        }
    }
}
