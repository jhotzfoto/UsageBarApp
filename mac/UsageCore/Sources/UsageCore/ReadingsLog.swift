import Foundation

/// One logged limit value, in UsageBar's CSV format (fetched_at,key,label,percent,resets_at).
public struct Reading: Hashable {
    public let ts: Date
    public let key: String
    public let label: String
    public let percent: Double
    public let resetsAt: Date?
    public init(ts: Date, key: String, label: String, percent: Double, resetsAt: Date?) {
        self.ts = ts; self.key = key; self.label = label; self.percent = percent; self.resetsAt = resetsAt
    }
}

/// One rolled-up day per limit (UsageBar's usage_daily.csv format). `sessionWindows` maps each
/// session window's reset (minute) to its peak %.
public struct DailyRow: Hashable {
    public let date: String          // yyyy-MM-dd, local
    public let key: String
    public let label: String
    public let maxPercent: Double
    public let lastPercent: Double
    public let samples: Int
    public let sessionWindows: [Date: Double]
}

/// Append-only CSV of readings with a 30-day raw window; older rows roll into daily summaries.
public final class ReadingsLog {
    public let url: URL
    public let dailyURL: URL
    public static let keepDays = 30

    public init(directory: URL) {
        url = directory.appendingPathComponent("usage_log.csv")
        dailyURL = directory.appendingPathComponent("usage_daily.csv")
    }

    static let header = "fetched_at,key,label,percent,resets_at"
    static let dailyHeader = "date,key,label,max_percent,last_percent,samples,session_windows"

    public func append(_ s: Snapshot) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var text = FileManager.default.fileExists(atPath: url.path) ? "" : Self.header + "\n"
        for l in s.limits {
            text += [CSV.iso(s.fetchedAt), l.key, CSV.quote(l.label), CSV.num(l.percent), l.resetsAt.map(CSV.iso) ?? ""]
                .joined(separator: ",") + "\n"
        }
        if let h = FileHandle(forWritingAtPath: url.path) {
            defer { try? h.close() }
            try h.seekToEnd()
            try h.write(contentsOf: Data(text.utf8))
        } else {
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    public func load(since: Date = .distantPast) -> [Reading] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return CSV.rows(text).dropFirst().compactMap { r in
            guard r.count >= 5, let ts = CSV.date(r[0]), ts >= since, let p = Double(r[3]) else { return nil }
            return Reading(ts: ts, key: r[1], label: r[2], percent: p, resetsAt: CSV.date(r[4]))
        }
    }

    public func loadDaily() -> [DailyRow] {
        guard let text = try? String(contentsOf: dailyURL, encoding: .utf8) else { return [] }
        return CSV.rows(text).dropFirst().compactMap { r in
            guard r.count >= 7, let mx = Double(r[3]), let last = Double(r[4]), let n = Int(r[5]) else { return nil }
            var wins: [Date: Double] = [:]
            for item in r[6].split(separator: ";") {
                let kv = item.split(separator: "=")
                if kv.count == 2, let d = CSV.date(String(kv[0]) + ":00+00:00"), let v = Double(kv[1]) { wins[d] = v }
            }
            return DailyRow(date: r[0], key: r[1], label: r[2], maxPercent: mx, lastPercent: last, samples: n, sessionWindows: wins)
        }
    }

    /// First-run import: copies UsageBar's history (read only), so history starts 2026-11-01.
    public func importIfEmpty(fromLog other: URL, daily otherDaily: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: url.path), fm.fileExists(atPath: other.path) else { return }
        try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? fm.copyItem(at: other, to: url)
        if !fm.fileExists(atPath: dailyURL.path), fm.fileExists(atPath: otherDaily.path) {
            try? fm.copyItem(at: otherDaily, to: dailyURL)
        }
    }

    /// Moves raw rows older than `keepDays` into one summary row per local day per limit.
    @discardableResult
    public func rollup(now: Date = Date()) -> Int {
        let cutoff = now.addingTimeInterval(-Double(Self.keepDays) * 86400)
        let all = load()
        let old = all.filter { $0.ts < cutoff }
        guard !old.isEmpty else { return 0 }
        struct Acc { var label = ""; var mx = 0.0; var last = 0.0; var n = 0; var wins: [Date: Double] = [:] }
        var days: [String: Acc] = [:]
        var order: [String] = []
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for r in old {
            let k = df.string(from: r.ts) + "\u{1}" + r.key
            if days[k] == nil { order.append(k) }
            var a = days[k] ?? Acc()
            a.label = r.label; a.mx = max(a.mx, r.percent); a.last = r.percent; a.n += 1
            if r.key == "session", let reset = r.resetsAt {
                let m = Date(timeIntervalSince1970: (reset.timeIntervalSince1970 / 60).rounded(.down) * 60)
                a.wins[m] = max(a.wins[m] ?? 0, r.percent)
            }
            days[k] = a
        }
        var dailyText = FileManager.default.fileExists(atPath: dailyURL.path) ? "" : Self.dailyHeader + "\n"
        let wf = ISO8601DateFormatter()
        for k in order {
            let parts = k.split(separator: "\u{1}").map(String.init)
            let a = days[k]!
            let wins = a.wins.keys.sorted().map { String(wf.string(from: $0).prefix(16)) + "=" + CSV.num(a.wins[$0]!) }
            dailyText += [parts[0], parts[1], CSV.quote(a.label), CSV.num(a.mx), CSV.num(a.last), String(a.n),
                          wins.joined(separator: ";")].joined(separator: ",") + "\n"
        }
        if let h = FileHandle(forWritingAtPath: dailyURL.path) {
            _ = try? h.seekToEnd(); try? h.write(contentsOf: Data(dailyText.utf8)); try? h.close()
        } else {
            try? dailyText.write(to: dailyURL, atomically: true, encoding: .utf8)
        }
        var keep = Self.header + "\n"
        for r in all where r.ts >= cutoff {
            keep += [CSV.iso(r.ts), r.key, CSV.quote(r.label), CSV.num(r.percent), r.resetsAt.map(CSV.iso) ?? ""]
                .joined(separator: ",") + "\n"
        }
        try? keep.write(to: url, atomically: true, encoding: .utf8)
        return old.count
    }
}

/// Minimal CSV helpers (quotes, commas, ISO dates).
public enum CSV {
    public static func iso(_ d: Date) -> String {
        let f = ISO8601DateFormatter()
        return f.string(from: d).replacingOccurrences(of: "Z", with: "+00:00")
    }
    public static func date(_ s: String) -> Date? { s.isEmpty ? nil : UsageParser.date(s) }
    public static func num(_ v: Double) -> String { v == v.rounded() ? String(format: "%.1f", v) : String(format: "%.2f", v) }
    public static func quote(_ s: String) -> String {
        s.contains(",") || s.contains("\"") || s.contains("\n") ? "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : s
    }

    public static func rows(_ text: String) -> [[String]] {
        var rows: [[String]] = [], row: [String] = [], field = ""
        var inQuotes = false
        var it = Array(text.unicodeScalars)[...]
        while let c = it.popFirst() {
            if inQuotes {
                if c == "\"" {
                    if it.first == "\"" { field.unicodeScalars.append("\""); it.removeFirst() } else { inQuotes = false }
                } else { field.unicodeScalars.append(c) }
            } else if c == "\"" { inQuotes = true }
            else if c == "," { row.append(field); field = "" }
            else if c == "\n" { row.append(field); rows.append(row); row = []; field = "" }
            else if c != "\r" { field.unicodeScalars.append(c) }
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}
