import Foundation

/// Usage per model per day.
/// - Tokens per model: Claude Code transcripts name the exact model of every reply; claude.ai chats
///   carry the chat's model setting (estimated tokens). Kept as one small daily summary per model
///   (model_daily.csv), so it outlives the chat tracker's 8-day detail.
/// - Official: how much of each weekly limit Anthropic tracks (all models, and per-model limits such
///   as Fable) was used each day, from the readings.
public enum ModelUsage {
    public struct Row: Hashable {
        public let date: String     // local yyyy-MM-dd
        public let model: String    // model id, or "unknown"
        public let source: String   // "chat" or "code"
        public let tokens: Double
        public init(date: String, model: String, source: String, tokens: Double) {
            self.date = date; self.model = model; self.source = source; self.tokens = tokens
        }
    }

    public struct Day: Identifiable, Hashable {
        public var id: Date { date }
        public let date: Date
        public let models: [Share]       // largest first
        public var total: Double { models.reduce(0) { $0 + $1.tokens } }
    }

    public struct Share: Hashable {
        public let name: String          // display name, e.g. "Opus 5.5"
        public let tokens: Double
    }

    static func dayString(_ d: Date, _ cal: Calendar) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    static func dayDate(_ s: String, _ cal: Calendar) -> Date? {
        let p = s.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return cal.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }

    /// "claude-opus-5-5" → "Opus 5.5", "claude-sonnet-4-5-20250929" → "Sonnet 4.5",
    /// "claude-3-5-haiku-20241022" → "Haiku 3.5"; nil or empty → "Unknown".
    public static func displayName(_ id: String?) -> String {
        guard var s = id?.lowercased(), !s.isEmpty, s != "unknown" else { return "Unknown" }
        if s.hasPrefix("claude-") { s.removeFirst(7) }
        let parts = s.split(separator: "-").map(String.init).filter { !($0.count >= 8 && Int($0) != nil) }   // drop dates
        guard let fi = parts.firstIndex(where: { Int($0) == nil }) else { return id! }
        let family = parts[fi].prefix(1).uppercased() + parts[fi].dropFirst()
        var version = parts[(fi + 1)...].filter { Int($0) != nil }
        if version.isEmpty { version = Array(parts[..<fi]) }
        return version.isEmpty ? family : family + " " + version.joined(separator: ".")
    }

    /// Tokens per local day, model and source.
    public static func rows(events: [ChatTracking.Event], calendar: Calendar = .current) -> [Row] {
        var sums: [String: Double] = [:]
        for e in events {
            let k = [dayString(e.ts, calendar), e.model ?? "unknown", e.source].joined(separator: "|")
            sums[k, default: 0] += e.tokens
        }
        return sums.map { k, v in
            let p = k.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            return Row(date: p[0], model: p[1], source: p[2], tokens: v)
        }.sorted { ($0.date, $0.model, $0.source) < ($1.date, $1.model, $1.source) }
    }

    /// Keeps stored days before `coveredFrom` and takes fresh rows from then on (days the tracker
    /// still holds in full).
    public static func merge(stored: [Row], fresh: [Row], coveredFrom: String) -> [Row] {
        (stored.filter { $0.date < coveredFrom } + fresh.filter { $0.date >= coveredFrom })
            .sorted { ($0.date, $0.model, $0.source) < ($1.date, $1.model, $1.source) }
    }

    /// The first day the chat tracker still holds completely.
    public static func coveredFrom(now: Date, calendar: Calendar = .current) -> String {
        let edge = now.addingTimeInterval(-ChatTracking.keepDays * 86400)
        return dayString(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: edge))!, calendar)
    }

    public static func days(_ rows: [Row], calendar: Calendar = .current) -> [Day] {
        var byDay: [String: [String: Double]] = [:]
        for r in rows { byDay[r.date, default: [:]][displayName(r.model), default: 0] += r.tokens }
        return byDay.compactMap { d, m in
            dayDate(d, calendar).map { Day(date: $0, models: m.map { Share(name: $0.key, tokens: $0.value) }.sorted { $0.tokens > $1.tokens }) }
        }.sorted { $0.date < $1.date }
    }

    // MARK: file

    public static func load(_ url: URL) -> [Row] {
        guard let s = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return s.split(separator: "\n").dropFirst().compactMap { line in
            let p = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard p.count == 4, let t = Double(p[3]) else { return nil }
            return Row(date: p[0], model: p[1], source: p[2], tokens: t)
        }
    }

    public static func save(_ rows: [Row], to url: URL) throws {
        let body = rows.map { "\($0.date),\($0.model.replacingOccurrences(of: ",", with: " ")),\($0.source),\(Int($0.tokens))" }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try (["date,model,source,tokens"] + body).joined(separator: "\n").appending("\n")
            .write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: official limits

    /// Weekly limit % used per local day, per limit ("All models", "Fable", ...): the sum of rises
    /// between readings of the same weekly window (a new window counts from 0).
    public static func limitGains(readings: [Reading], calendar: Calendar = .current) -> [Date: [String: Double]] {
        var out: [Date: [String: Double]] = [:]
        var prev: [String: Reading] = [:]
        for r in readings.sorted(by: { $0.ts < $1.ts }) where r.key.hasPrefix("weekly") {
            let name = r.key == "weekly_all" ? "All models"
                : (r.label.components(separatedBy: "· ").last ?? r.label).trimmingCharacters(in: .whitespaces)
            var g = 0.0
            if let p = prev[name], let a = p.resetsAt, let b = r.resetsAt, History.minute(a) == History.minute(b) {
                g = max(0, r.percent - p.percent)
            } else if prev[name] != nil {
                g = r.percent   // a new weekly window started
            }
            if g > 0 { out[calendar.startOfDay(for: r.ts), default: [:]][name, default: 0] += g }
            prev[name] = r
        }
        return out
    }
}
