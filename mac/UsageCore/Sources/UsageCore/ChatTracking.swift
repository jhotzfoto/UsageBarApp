import Foundation

/// Estimated per-chat share of the session (port of UsageBar 1.4's chattrack.py).
///
/// Anthropic reports one combined session %. Every time it rises, the rise is credited to the chats
/// with new activity since the previous rise, split by estimated tokens. All results are estimates.
/// - claude.ai chats and tasks: read in an open claude.ai tab in Chrome (`PageScript`); the page returns
///   only titles, message times and token estimates. Message text never leaves the page.
/// - Claude Code: local transcripts in ~/.claude/projects (exact usage fields).
public enum ChatTracking {
    public static let keepDays: Double = 8
    public static let maxDetailsPerPass = 8
    public static let unattributed = "unattributed"

    public struct Event: Hashable {
        public let ts: Date
        public let id: String
        public let title: String
        public let source: String      // "chat" or "code"
        public let tokens: Double
    }

    public struct ChatInfo: Codable, Equatable {
        public var title = ""
        public var platform = ""
        public var updatedAt = ""
        public var stale = false
        public var events: [[Double]] = []        // [unix ts, tokens]
    }

    public struct CodeSession: Codable, Equatable {
        public var title: String?
        public var project: String?
        public var events: [String: [Double]] = [:]   // message id -> [unix ts, tokens]
        public var created: Double?                    // earliest transcript file creation time
    }

    /// Everything the tracker remembers between passes (titles, times and token counts only).
    public struct Store: Codable, Equatable {
        public var org: String?
        public var chats: [String: ChatInfo] = [:]
        public var code: [String: CodeSession] = [:]
        public var offsets: [String: UInt64] = [:]
        public var status: String?
        public var checkedAt: Date?
        public init() {}
    }

    // MARK: claude.ai page

    /// Runs inside the claude.ai tab via AppleScript "execute javascript" (synchronous XHR so the call
    /// returns the result). Weight per reply: context size at each model call (~4 chars/token, tool
    /// results included) + output + ~10k tokens per call for claude.ai's system prompt.
    public static let pageScript = #"""
    (function(){
    var ARGS = __ARGS__;
    var CALL_OVERHEAD = 10000, FILE_CHARS = 6000;
    function get(u){var x=new XMLHttpRequest();x.open("GET",u,false);x.send();
      if(x.status!==200) throw new Error("HTTP "+x.status+" "+u.split("?")[0].split("/").slice(-1)[0]);
      return JSON.parse(x.responseText);}
    function len(v){if(v==null)return 0;if(typeof v==="string")return v.length;return JSON.stringify(v).length;}
    try{
      var org=ARGS.org;
      if(!org){var orgs=get("/api/organizations");
        for(var i=0;i<orgs.length;i++){if((orgs[i].capabilities||[]).indexOf("chat")>=0){org=orgs[i].uuid;break;}}}
      var list=get("/api/organizations/"+org+"/chat_conversations_v2?limit=30&offset=0&archived=false&consistency=strong");
      var items=(list.data||list).map(function(c){return {uuid:c.uuid,title:c.name||"",updated_at:c.updated_at,platform:c.platform||""};});
      var want=(ARGS.want||[]).slice();
      items.forEach(function(c){
        if(ARGS.known[c.uuid]!==c.updated_at && c.updated_at>=ARGS.cutoff && want.indexOf(c.uuid)<0) want.push(c.uuid);
      });
      want=want.slice(0,ARGS.max);
      var details={};
      want.forEach(function(uuid){
        var d=get("/api/organizations/"+org+"/chat_conversations/"+uuid+"?tree=False&rendering_mode=messages&render_all_tools=true");
        var ctx=0, ev=[];
        (d.chat_messages||[]).forEach(function(m){
          var blocks=m.content||[];
          if(m.sender!=="assistant"){
            var c=0; blocks.forEach(function(b){c+=len(b.text)+len(b.content)+len(b.input);});
            if(!blocks.length) c+=len(m.text);
            (m.attachments||[]).forEach(function(a){c+=len(a.extracted_content);});
            c+=FILE_CHARS*((m.files||[]).length);
            ctx+=c; return;
          }
          var tok=CALL_OVERHEAD+ctx/4, out=0;
          blocks.forEach(function(b){
            if(b.type==="tool_result"){var r=len(b.content);ctx+=r;tok+=CALL_OVERHEAD+ctx/4;}
            else if(b.type==="thinking"){out+=len(b.thinking);}
            else {var o=len(b.text)+len(b.input);out+=o;ctx+=o;}
          });
          tok+=out/4;
          ev.push([m.created_at, Math.round(tok)]);
        });
        details[uuid]=ev;
      });
      return JSON.stringify({ok:true,org:org,items:items,details:details});
    }catch(e){return JSON.stringify({ok:false,error:String(e.message||e)});}
    })()
    """#

    /// Finds a claude.ai tab (artifact pages last) and runs the script in it. Never opens, focuses or
    /// navigates anything. Only run after checking Chrome is running ("tell application" would launch it).
    public static let appleScript = #"""
    on run argv
    set js to item 1 of argv
    tell application "Google Chrome"
      set best to missing value
      repeat with w in windows
        repeat with t in tabs of w
          set u to URL of t
          if u starts with "https://claude.ai/" then
            if u does not contain "/artifact/" then return (execute t javascript js)
            if best is missing value then set best to t
          end if
        end repeat
      end repeat
      if best is not missing value then return (execute best javascript js)
    end tell
    return "NO_TAB"
    end run
    """#

    public static let pausedNoTab = "Chat tracking paused: open claude.ai in Chrome"
    public static let pausedJSOff = "Chat tracking paused: turn on Chrome > View > Developer > Allow JavaScript from Apple Events"

    /// Arguments for one pass: known chats (unchanged ones are skipped) and chats still pending.
    public static func pageArguments(_ st: Store, now: Date) -> String {
        let cutoff = ISO8601DateFormatter().string(from: now.addingTimeInterval(-keepDays * 86400)).replacingOccurrences(of: "Z", with: "")
        let known = st.chats.filter { !$0.value.stale }.mapValues { $0.updatedAt }
        let want = st.chats.filter { $0.value.stale }.map(\.key)
        var args: [String: Any] = ["known": known, "want": want, "cutoff": cutoff, "max": maxDetailsPerPass]
        if let o = st.org { args["org"] = o }
        let data = (try? JSONSerialization.data(withJSONObject: args)) ?? Data("{}".utf8)
        return pageScript.replacingOccurrences(of: "__ARGS__", with: String(decoding: data, as: UTF8.self))
    }

    /// Applies the page's answer; returns a status message when tracking should show as paused.
    @discardableResult
    public static func apply(pageOutput out: String, to st: inout Store, now: Date) -> String? {
        if out == "NO_TAB" || out.isEmpty { return pausedNoTab }
        guard let obj = try? JSONSerialization.jsonObject(with: Data(out.utf8)) as? [String: Any] else {
            return "Chat tracking paused: unreadable answer from claude.ai"
        }
        guard (obj["ok"] as? Bool) == true else {
            return "Chat tracking paused: claude.ai \((obj["error"] as? String ?? "error").prefix(80))"
        }
        if let o = obj["org"] as? String { st.org = o }
        let cutoff = ISO8601DateFormatter().string(from: now.addingTimeInterval(-keepDays * 86400)).replacingOccurrences(of: "Z", with: "")
        for it in obj["items"] as? [[String: Any]] ?? [] {
            guard let uuid = it["uuid"] as? String else { continue }
            var c = st.chats[uuid] ?? ChatInfo()
            let upd = it["updated_at"] as? String ?? ""
            // updated_at only decides what to re-read (renames bump it too); activity times always
            // come from each message's created_at.
            if c.updatedAt != upd && upd >= cutoff { c.stale = true }
            c.title = it["title"] as? String ?? ""
            c.platform = it["platform"] as? String ?? ""
            c.updatedAt = upd
            st.chats[uuid] = c
        }
        for (uuid, evAny) in obj["details"] as? [String: Any] ?? [:] {
            var c = st.chats[uuid] ?? ChatInfo()
            c.events = (evAny as? [[Any]] ?? []).compactMap { e in
                guard e.count == 2, let t = UsageParser.date(e[0]), let n = (e[1] as? NSNumber)?.doubleValue else { return nil }
                return [t.timeIntervalSince1970, n]
            }
            c.stale = false
            st.chats[uuid] = c
        }
        return nil
    }

    // MARK: Claude Code transcripts

    static func usageTokens(_ u: [String: Any]) -> Double {
        let its = (u["iterations"] as? [[String: Any]]).flatMap { $0.isEmpty ? nil : $0 } ?? [u]
        return its.reduce(0) { acc, i in
            acc + ["input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens"]
                .reduce(0) { $0 + ((i[$1] as? NSNumber)?.doubleValue ?? 0) }
        }
    }

    /// Reads only what's new in each transcript since the last pass.
    public static func updateCode(_ st: inout Store, root: URL, now: Date) {
        let fm = FileManager.default
        let cutoff = now.addingTimeInterval(-keepDays * 86400)
        var paths: [URL] = []
        for proj in (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [] {
            for f in (try? fm.contentsOfDirectory(at: proj, includingPropertiesForKeys: nil)) ?? [] {
                if f.pathExtension == "jsonl" { paths.append(f) }
                let sub = f.appendingPathComponent("subagents")
                for s in (try? fm.contentsOfDirectory(at: sub, includingPropertiesForKeys: nil)) ?? [] where s.pathExtension == "jsonl" {
                    paths.append(s)
                }
            }
        }
        for path in paths {
            guard let attrs = try? fm.attributesOfItem(atPath: path.path),
                  let size = (attrs[.size] as? NSNumber)?.uint64Value,
                  let mtime = attrs[.modificationDate] as? Date, mtime >= cutoff else { continue }
            let born = ((attrs[.creationDate] as? Date) ?? mtime).timeIntervalSince1970
            var offset = st.offsets[path.path] ?? 0
            if size < offset { offset = 0 }
            guard size > offset, let h = FileHandle(forReadingAtPath: path.path) else { continue }
            defer { try? h.close() }
            try? h.seek(toOffset: offset)
            guard let data = try? h.readToEnd(), let end = data.lastIndex(of: 0x0A) else { continue }
            let chunk = data[data.startIndex...end]   // leave a half-written last line for next time
            for line in chunk.split(separator: 0x0A) {
                guard line.count > 10 else { continue }
                let s = String(decoding: line, as: UTF8.self)
                guard s.contains("\"assistant\"") || s.contains("\"ai-title\"") || s.contains("\"cwd\"") else { continue }
                guard let d = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any],
                      let sid = d["sessionId"] as? String else { continue }
                var cs = st.code[sid] ?? CodeSession()
                if path.deletingLastPathComponent().lastPathComponent != "subagents" { cs.created = min(cs.created ?? born, born) }
                if cs.project == nil, let cwd = d["cwd"] as? String { cs.project = cwd }
                if d["type"] as? String == "ai-title", let t = d["aiTitle"] as? String, !t.isEmpty { cs.title = t }
                if d["type"] as? String == "assistant", let m = d["message"] as? [String: Any], let u = m["usage"] as? [String: Any],
                   let ts = UsageParser.date(d["timestamp"]), ts >= cutoff {
                    let key = (m["id"] as? String) ?? (d["uuid"] as? String) ?? UUID().uuidString
                    let n = usageTokens(u)
                    // Streamed messages repeat on several lines; keep the largest count.
                    if n > (cs.events[key]?[1] ?? 0) { cs.events[key] = [ts.timeIntervalSince1970, n] }
                }
                st.code[sid] = cs
            }
            st.offsets[path.path] = offset + UInt64(chunk.count)
        }
    }

    public static func prune(_ st: inout Store, now: Date) {
        let cutoff = now.addingTimeInterval(-keepDays * 86400).timeIntervalSince1970
        for k in st.chats.keys { st.chats[k]!.events.removeAll { $0[0] < cutoff } }
        for k in Array(st.code.keys) {
            st.code[k]!.events = st.code[k]!.events.filter { $0.value[0] >= cutoff }
            if st.code[k]!.events.isEmpty { st.code[k] = nil }
        }
        st.offsets = st.offsets.filter { FileManager.default.fileExists(atPath: $0.key) }
    }

    /// Every chat and Claude Code event. A continued Claude Code session copies earlier messages (with
    /// their original times) into its new transcript; each message counts once, for the session whose
    /// transcript was created first.
    public static func events(_ st: Store) -> [Event] {
        var out: [Event] = []
        for (uuid, c) in st.chats {
            for e in c.events { out.append(Event(ts: Date(timeIntervalSince1970: e[0]), id: uuid, title: c.title.isEmpty ? "Untitled" : c.title, source: "chat", tokens: e[1])) }
        }
        func first(_ s: CodeSession) -> Double { s.created ?? s.events.values.map { $0[0] }.min() ?? 0 }
        let sessions = st.code.sorted { first($0.value) < first($1.value) }
        var seen = Set<String>()
        for (sid, s) in sessions {
            let title = s.title ?? s.project.map { URL(fileURLWithPath: $0).lastPathComponent } ?? String(sid.prefix(8))
            for (k, v) in s.events where !seen.contains(k) {
                seen.insert(k)
                out.append(Event(ts: Date(timeIntervalSince1970: v[0]), id: sid, title: title, source: "code", tokens: v[1]))
            }
        }
        return out.sorted { $0.ts < $1.ts }
    }

    // MARK: attribution

    public struct Row: Hashable {
        public let window: Date          // session reset (minute)
        public let from: Date
        public let to: Date
        public let id: String
        public let title: String
        public let source: String
        public let tokens: Double
        public let percent: Double
    }

    public struct Total: Hashable, Identifiable {
        public let id: String
        public let title: String
        public let source: String
        public let tokens: Double
        public let percent: Double
    }

    /// Session readings -> attribution rows. A rise is split among the activity since the previous rise
    /// (integer % often hides small activity until the next tick); a rise with no activity is unattributed.
    public static func attribute(readings: [Reading], events: [Event]) -> [Row] {
        var byWindow: [Date: [(Date, Double)]] = [:]
        for r in readings where r.key == "session" {
            guard let reset = r.resetsAt else { continue }
            byWindow[History.minute(reset), default: []].append((r.ts, r.percent))
        }
        var rows: [Row] = []
        for (reset, rs) in byWindow.sorted(by: { $0.key < $1.key }) {
            var prev = 0.0, since = reset.addingTimeInterval(-History.sessionLength)
            for (ts, pct) in rs.sorted(by: { $0.0 < $1.0 }) {
                if pct > prev {
                    var pend: [String: (String, String, Double)] = [:]
                    for e in events where e.ts > since && e.ts <= ts {
                        let cur = pend[e.id]
                        pend[e.id] = (e.title, e.source, (cur?.2 ?? 0) + e.tokens)
                    }
                    let total = pend.values.reduce(0) { $0 + $1.2 }
                    let rise = pct - prev
                    if total > 0 {
                        for (id, v) in pend { rows.append(Row(window: reset, from: since, to: ts, id: id, title: v.0, source: v.1, tokens: v.2, percent: rise * v.2 / total)) }
                    } else {
                        rows.append(Row(window: reset, from: since, to: ts, id: unattributed, title: "Unattributed (no tracked activity)", source: "-", tokens: 0, percent: rise))
                    }
                    since = ts; prev = pct
                } else if pct < prev {   // shouldn't happen inside a window; restart the count
                    prev = pct; since = ts
                }
            }
        }
        return rows
    }

    /// Per chat, merged by id (latest title), largest share first.
    public static func totals(_ rows: [Row], window: Date? = nil, since: Date? = nil) -> [Total] {
        var agg: [String: (String, String, Double, Double, Date)] = [:]
        for r in rows {
            if let w = window, r.window != History.minute(w) { continue }
            if let s = since, r.to < s { continue }
            let cur = agg[r.id]
            let newer = cur.map { r.to >= $0.4 } ?? true
            agg[r.id] = (newer ? r.title : cur!.0, r.source, (cur?.2 ?? 0) + r.tokens, (cur?.3 ?? 0) + r.percent, max(cur?.4 ?? r.to, r.to))
        }
        return agg.map { Total(id: $0.key, title: $0.value.0, source: $0.value.1, tokens: $0.value.2, percent: $0.value.3) }
            .sorted { $0.percent > $1.percent }
    }

    public static func windowTokens(_ events: [Event], reset: Date) -> Double {
        let start = reset.addingTimeInterval(-History.sessionLength)
        return events.filter { $0.ts > start && $0.ts <= reset }.reduce(0) { $0 + $1.tokens }
    }

    /// Independent check: tokens per 1% measured over completed windows (all tracked tokens ÷ peak %),
    /// using only windows fully inside the tracked event history and peaking at 5% or more.
    public static func tokensPerPercent(windows: [History.Window], events: [Event], now: Date) -> (rate: Double, windows: Int)? {
        let since = now.addingTimeInterval(-keepDays * 86400 + History.sessionLength)
        var tok = 0.0, pct = 0.0, n = 0
        for w in windows where w.done && w.start >= since && w.peak >= 5 {
            let t = windowTokens(events, reset: w.reset)
            if t > 0 { tok += t; pct += w.peak; n += 1 }
        }
        return n > 0 && pct > 0 ? (tok / pct, n) : nil
    }
}
