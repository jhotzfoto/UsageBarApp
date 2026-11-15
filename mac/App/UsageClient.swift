import AppKit
import Foundation
import UsageCore

/// Reads usage from api.anthropic.com/api/oauth/usage with Claude Code's OAuth access token.
/// The token comes from the Keychain item "Claude Code-credentials", read with /usr/bin/security.
/// Only accessToken and expiresAt are read; the app never writes the item and never uses the refresh
/// token. When the login is about to run out, `renewLogin()` runs Claude Code's own status check so
/// Claude Code renews it (see `LoginRenewal`).
enum UsageClient {
    static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    static let keychainService = "Claude Code-credentials"

    enum FetchError: LocalizedError {
        case message(String)
        case rateLimited(retryAfter: TimeInterval)
        case expired
        case refused(Int)
        case signInNeeded
        var errorDescription: String? {
            switch self {
            case .message(let m): return m
            case .rateLimited: return "Rate limited by usage endpoint"
            case .expired: return "Claude Code login expired; renewing it automatically."
            case .refused(let c): return "Login refused (HTTP \(c)); renewing it automatically."
            case .signInNeeded: return "Claude Code was signed out. Click Sign in below (one time)."
            }
        }
        /// The login itself is the problem (as opposed to the network or the endpoint).
        var isLogin: Bool {
            switch self { case .expired, .refused: return true; default: return false }
        }
    }

    /// The Claude Code command line tool, wherever it's installed.
    static var claudePath: String? {
        LoginRenewal.candidatePaths(home: NSHomeDirectory()).first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func readLogin() throws -> LoginRenewal.Login {
        // Long timeout: if macOS ever shows a Keychain prompt, you need time to click Always Allow.
        let out: String
        do {
            out = try Shell.run("/usr/bin/security", ["find-generic-password", "-s", keychainService, "-w"], timeout: 120)
        } catch Shell.ShellError.timedOut {
            throw FetchError.message("Waiting for Keychain access: click Always Allow if macOS asks.")
        } catch {
            throw FetchError.signInNeeded
        }
        guard let login = LoginRenewal.parse(out) else { throw FetchError.signInNeeded }
        return login
    }

    static func readToken() throws -> String {
        let login = try readLogin()
        if login.isExpired(now: Date()) { throw FetchError.expired }
        return login.accessToken
    }

    /// Runs Claude Code's own `/usage` command (no model request, nothing saved). Claude Code renews its
    /// own login while doing so (`claude auth status` does NOT renew; tested 2026-11-15). Returns the login's new expiry as read back from the Keychain.
    static func renewLogin() throws -> Date? {
        guard let bin = claudePath else {
            throw FetchError.message("Claude Code's command line tool wasn't found, so the login can't renew itself.")
        }
        do {
            _ = try Shell.run(bin, ["-p", "/usage", "--no-session-persistence"], timeout: 60, cwd: NSHomeDirectory())
        } catch Shell.ShellError.timedOut {
            throw FetchError.message("Claude Code didn't answer the login renewal in time.")
        } catch {
            // A non-zero exit can still have renewed the login; the read-back below decides.
        }
        return try readLogin().expiresAt
    }

    /// Opens Terminal on `claude auth login` (only needed if Claude Code was fully signed out).
    static func openSignIn() {
        guard let bin = claudePath else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("UsageBarApp-sign-in.command")
        let script = "#!/bin/zsh\ncd ~\necho 'Signing Claude Code back in for UsageBarApp...'\n'\(bin)' auth login\n"
        try? script.write(to: url, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        NSWorkspace.shared.open(url)
    }

    /// `claude --version`, cached for a day (it's slow and memory-heavy).
    static func claudeVersion() -> String {
        let d = UserDefaults.standard
        if let v = d.string(forKey: "claudeVersion"),
           Date().timeIntervalSince1970 - d.double(forKey: "claudeVersionAt") < 86400 { return v }
        let v = claudePath.flatMap { try? Shell.run($0, ["--version"]) }?.split(separator: " ").first.map(String.init) ?? "2.0.0"
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
            throw FetchError.refused(code)
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
        guard running else { throw FetchError.message("Chrome isn't open") }
        let orgJS = org.flatMap { o in o.allSatisfy { $0.isHexDigit || $0 == "-" } ? "\"\(o)\"" : nil } ?? "null"
        let body = chromeUsageScript.replacingOccurrences(of: "__ORG__", with: orgJS)
        let out = try await Task.detached(priority: .utility) {
            try Shell.run("/usr/bin/osascript", ChatTracking.osascriptArguments(body), timeout: 25)
        }.value
        guard let obj = try? JSONSerialization.jsonObject(with: Data(out.utf8)) as? [String: Any],
              (obj["ok"] as? Bool) == true, let raw = obj["raw"] as? [String: Any] else {
            throw FetchError.message("Chrome didn't answer")
        }
        return raw
    }
}

enum Shell {
    /// Runs a program and returns its trimmed stdout. Never hangs: output is collected as it arrives
    /// and the process is killed after `timeout` (a child holding the pipe open can't block us).
    static func run(_ path: String, _ args: [String], timeout: TimeInterval = 15, cwd: String? = nil) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        if let cwd { p.currentDirectoryURL = URL(fileURLWithPath: cwd) }
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
