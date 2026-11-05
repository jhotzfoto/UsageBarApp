import AppKit
import Foundation
import UsageCore

/// Runs one chat-tracking pass after each usage reading, off the main thread:
/// claude.ai (Chrome tab, via osascript) + Claude Code transcripts, then attribution.
/// Never opens, focuses or navigates Chrome; only runs when Chrome is already open.
final class ChatTracker {
    struct Result {
        let rows: [ChatTracking.Row]
        let events: [ChatTracking.Event]
        let status: String?
        let projects: [String: String]
        let checkedAt: Date
    }

    private let storeURL: URL
    private let codeRoot = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude/projects")
    private let queue = DispatchQueue(label: "chattracker", qos: .utility)
    private var running = false

    init(directory: URL) { storeURL = directory.appendingPathComponent("chats.json") }

    func load() -> ChatTracking.Store {
        guard let d = try? Data(contentsOf: storeURL) else { return ChatTracking.Store() }
        return (try? SnapshotStore.decoder.decode(ChatTracking.Store.self, from: d)) ?? ChatTracking.Store()
    }

    private func save(_ st: ChatTracking.Store) {
        try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? SnapshotStore.encoder.encode(st).write(to: storeURL, options: .atomic)
    }

    /// Recomputes from what's stored, without reading Chrome or transcripts (used at launch).
    func cached(readings: [Reading]) -> Result {
        let st = load()
        let ev = ChatTracking.events(st)
        return Result(rows: ChatTracking.attribute(readings: readings, events: ev), events: ev, status: st.status,
                      projects: st.code.compactMapValues(\.project), checkedAt: st.checkedAt ?? .distantPast)
    }

    func pass(readings: [Reading], includeChrome: Bool, completion: @escaping (Result) -> Void) {
        guard !running else { return }
        running = true
        queue.async {
            let now = Date()
            var st = self.load()
            var status: String? = nil
            if includeChrome {
                status = self.readChrome(&st, now: now)
            } else {
                status = "Chat tracking for claude.ai is off (Settings)"
            }
            ChatTracking.updateCode(&st, root: self.codeRoot, now: now)
            ChatTracking.prune(&st, now: now)
            st.status = status
            st.checkedAt = now
            self.save(st)
            let ev = ChatTracking.events(st)
            let rows = ChatTracking.attribute(readings: readings, events: ev)
            let result = Result(rows: rows, events: ev, status: status, projects: st.code.compactMapValues(\.project), checkedAt: now)
            DispatchQueue.main.async {
                self.running = false
                completion(result)
            }
        }
    }

    private func readChrome(_ st: inout ChatTracking.Store, now: Date) -> String? {
        let chromeRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.google.Chrome" }
        guard chromeRunning else { return ChatTracking.pausedNoTab }
        do {
            let out = try Shell.run("/usr/bin/osascript", ["-e", ChatTracking.appleScript, ChatTracking.pageArguments(st, now: now)], timeout: 20)
            return ChatTracking.apply(pageOutput: out, to: &st, now: now)
        } catch let e as Shell.ShellError {
            if e.stderr.contains("JavaScript") && e.stderr.contains("Apple Events") { return ChatTracking.pausedJSOff }
            if e.stderr.contains("-1743") || e.stderr.lowercased().contains("not allowed") {
                return "Chat tracking paused: allow UsageBarApp to control Chrome (System Settings > Privacy & Security > Automation)"
            }
            return "Chat tracking paused: Chrome didn't answer (\(e.stderr.suffix(80)))"
        } catch {
            return "Chat tracking paused: \(error.localizedDescription)"
        }
    }
}
