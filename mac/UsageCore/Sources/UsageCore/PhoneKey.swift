import Foundation

/// The iPhone's session-key lifetime record (UsageBarApp/key-status.json in Scriptable's iCloud
/// folder, written by the iPhone script on every run). Times only; the key never leaves the iPhone.
/// A key is known to have worked from savedAt to lastOkAt, and to be dead by firstFailAt, so its
/// lifetime is a range: checks run about every 15 minutes, and not at all while the phone is off.
public enum PhoneKey {
    public struct Key: Equatable {
        public var savedAt: Date?
        public var lastOkAt: Date?
        public var firstFailAt: Date?
        public var expiresAt: Date?
        public var endedBy: String?
        public init(savedAt: Date? = nil, lastOkAt: Date? = nil, firstFailAt: Date? = nil, expiresAt: Date? = nil, endedBy: String? = nil) {
            self.savedAt = savedAt; self.lastOkAt = lastOkAt; self.firstFailAt = firstFailAt
            self.expiresAt = expiresAt; self.endedBy = endedBy
        }
    }

    public struct Status: Equatable {
        public var current: Key?
        public var past: [Key]
        public var updatedAt: Date?
    }

    public static func parse(_ data: Data) -> Status? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        func key(_ any: Any?) -> Key? {
            guard let d = any as? [String: Any] else { return nil }
            return Key(savedAt: UsageParser.date(d["savedAt"]), lastOkAt: UsageParser.date(d["lastOkAt"]),
                       firstFailAt: UsageParser.date(d["firstFailAt"]), expiresAt: UsageParser.date(d["expiresAt"]),
                       endedBy: d["endedBy"] as? String)
        }
        return Status(current: key(obj["current"]), past: (obj["past"] as? [Any] ?? []).compactMap(key),
                      updatedAt: UsageParser.date(obj["updatedAt"]))
    }

    /// "2 h", "30 h", "5 days".
    public static func duration(_ t: TimeInterval) -> String {
        let h = t / 3600
        return h < 48 ? "\(Int(h.rounded(.down))) h" : "\(Int((h / 24).rounded(.down))) days"
    }

    /// How long a key lasted (or has lasted so far).
    public static func lifetimeText(_ k: Key, now: Date) -> String {
        guard let saved = k.savedAt else {
            return k.lastOkAt.map { "saved before tracking began; last worked \(short($0))" } ?? "saved before tracking began"
        }
        if let fail = k.firstFailAt {
            guard let ok = k.lastOkAt else { return "never worked" }
            let lo = duration(ok.timeIntervalSince(saved)), hi = duration(fail.timeIntervalSince(saved))
            return lo == hi ? "lasted about \(lo)" : "lasted between \(lo) and \(hi)"
        }
        if k.endedBy == "replaced" {
            return "replaced while still working, after \(duration((k.lastOkAt ?? saved).timeIntervalSince(saved)))"
        }
        guard let ok = k.lastOkAt else { return "not checked yet" }
        return "working for \(duration(ok.timeIntervalSince(saved))) so far"
    }

    /// Lines for Settings > iPhone.
    public static func summary(_ s: Status, now: Date) -> [String] {
        var out: [String] = []
        if let c = s.current {
            if let fail = c.firstFailAt {
                out.append("Session key stopped working \(short(fail)) (\(lifetimeText(c, now: now))). Paste a new one on the iPhone.")
            } else {
                out.append("Session key " + (c.savedAt.map { "saved \(short($0)), " } ?? "") + lifetimeText(c, now: now)
                           + (c.lastOkAt.map { "; last worked \(short($0))" } ?? "") + ".")
            }
            if let e = c.expiresAt { out.append("claude.ai says it expires \(short(e)).") }
        } else {
            out.append("No session key on the iPhone yet.")
        }
        let ended = s.past.filter { $0.savedAt != nil }
        if !ended.isEmpty {
            out.append("Earlier keys: " + ended.prefix(5).map { lifetimeText($0, now: now) }.joined(separator: "; ") + ".")
        }
        return out
    }

    /// Identifies the current key's failure, so the Mac alerts once per failure (nil while working).
    public static func failureID(_ s: Status?) -> String? {
        s?.current?.firstFailAt.map { CSV.iso($0) }
    }

    static func short(_ d: Date) -> String {
        d.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
