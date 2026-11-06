import Charts
import SwiftUI
import UsageCore

/// How History draws its charts (one switch for all of them, remembered).
enum ChartStyle: String { case line, bars }

/// One colour language for all of History: blue = your usage, green = a session was running,
/// amber = capacity you didn't use (idle or left at reset), grey = not recorded.
enum HistoryPalette {
    static let usage = Color.accentColor
    static let running = UsageStyle.green
    static let missed = UsageStyle.amber
    static let none = Color.secondary
    static let cardFill = Color(nsColor: .controlBackgroundColor)
}

/// History window, ordered by what matters: summary tiles first, then today, sessions, days,
/// weeks and chats, each in its own card with a one-line "what to look for".
struct HistoryView: View {
    var body: some View {
        ScrollView {
            HistoryContent()
                .frame(maxWidth: 1040)
                .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 780, minHeight: 620)
    }
}

struct HistoryContent: View {
    @EnvironmentObject var model: UsageModel
    @AppStorage("historyRange") private var range = 14
    @AppStorage("historyChartStyle") private var styleRaw = ChartStyle.line.rawValue
    var styleOverride: ChartStyle? = nil   // design check renders only
    private var style: ChartStyle { styleOverride ?? ChartStyle(rawValue: styleRaw) ?? .line }

    var body: some View {
        let now = model.now
        let cutoff = now.addingTimeInterval(-Double(range) * 86400)
        let wins = model.windows.filter { $0.reset > cutoff }
        let days = History.days(readings: model.readings, daily: model.daily, now: now).filter { $0.date > cutoff }
        let weeks = History.weeks(readings: model.readings, daily: model.daily, now: now)
        let start = History.historyStart(readings: model.readings, daily: model.daily)

        VStack(alignment: .leading, spacing: 16) {
            header(start: start)
            OverviewTiles(wins: wins, days: days, range: range)
            DayTimelineCard(style: style)
            SessionsCard(wins: wins, style: style)
            DaysCard(days: days, style: style)
            ModelsCard(range: range, style: style)
            WeeksCard(weeks: weeks, style: style)
            ChatHistory(range: range)
        }
        .padding(24)
    }

    private func header(start: Date?) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Usage history").font(.largeTitle.weight(.bold))
                Text("Since \(start?.formatted(.dateTime.month(.wide).day()) ?? "–") · times when the Mac was asleep aren't recorded")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("", selection: $range) {
                Text("7 days").tag(7); Text("14 days").tag(14); Text("30 days").tag(30)
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 210)
            Picker("", selection: $styleRaw) {
                Image(systemName: "chart.xyaxis.line").help("Line charts").tag(ChartStyle.line.rawValue)
                Image(systemName: "chart.bar.fill").help("Bar charts").tag(ChartStyle.bars.rawValue)
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 84)
        }
    }
}

/// Design check: `UsageBarApp --render-history <path>` renders History with the real data to
/// <path>-light.png and <path>-dark.png and quits. Read only: it never fetches or writes data.
@MainActor
enum RenderHistory {
    static var active = false   // the app then skips polling, so nothing is fetched or written

    static func run(path: String, style: ChartStyle?) {
        let model = UsageModel()
        Task { @MainActor in
            for _ in 0..<150 where model.readings.isEmpty { try? await Task.sleep(nanoseconds: 100_000_000) }
            for (name, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
                NSApp.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
                let view = HistoryContent(styleOverride: style).environmentObject(model)
                    .frame(width: 1040)
                    .background(Color(nsColor: .windowBackgroundColor))
                    .environment(\.colorScheme, scheme)
                let r = ImageRenderer(content: view)
                r.scale = 1.5
                if let tiff = r.nsImage?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: URL(fileURLWithPath: "\(path)-\(name).png"))
                }
            }
            exit(0)
        }
    }
}

// MARK: hover

/// Tracks the pointer over a chart as a date on the x axis (nil when the pointer leaves).
struct HoverX: ViewModifier {
    @Binding var date: Date?
    func body(content: Content) -> some View {
        content.chartOverlay { proxy in
            GeometryReader { g in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let p):
                            guard let frame = proxy.plotFrame else { return }
                            date = proxy.value(atX: p.x - g[frame].origin.x, as: Date.self)
                        case .ended:
                            date = nil
                        }
                    }
            }
        }
    }
}

extension View {
    func hoverX(_ date: Binding<Date?>) -> some View { modifier(HoverX(date: date)) }
}

/// The small card that follows the pointer.
struct Tooltip: View {
    let title: String
    let lines: [(String, Color)]
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption.weight(.semibold))
            ForEach(Array(lines.enumerated()), id: \.offset) { _, l in
                HStack(spacing: 6) {
                    Circle().fill(l.1).frame(width: 7, height: 7)
                    Text(l.0).font(.caption).monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.primary.opacity(0.1)))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
    }
}

/// A vertical guide at the hovered point with the tooltip on top.
@ChartContentBuilder
func hoverMark(_ x: Date?, title: String, lines: [(String, Color)]) -> some ChartContent {
    if let x {
        RuleMark(x: .value("Hover", x))
            .foregroundStyle(Color.primary.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1))
            .annotation(position: .top, alignment: .center, spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                Tooltip(title: title, lines: lines)
            }
    }
}

// MARK: building blocks

/// A titled card: title, one-line "what to look for", optional controls on the right.
struct Card<Content: View, Accessory: View>: View {
    let title: String
    let subtitle: String?
    let accessory: Accessory
    let content: Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder accessory: () -> Accessory, @ViewBuilder content: () -> Content) {
        self.title = title; self.subtitle = subtitle; self.accessory = accessory(); self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.title3.weight(.semibold))
                    if let s = subtitle { Text(s).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                }
                Spacer(minLength: 12)
                accessory
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(HistoryPalette.cardFill))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.primary.opacity(0.07)))
    }
}

extension Card where Accessory == EmptyView {
    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title, subtitle: subtitle, accessory: { EmptyView() }, content: content)
    }
}

/// A number with a small label under it (used for each card's takeaway row).
struct Stat: View {
    let value: String
    let label: String
    var color: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value).font(.system(.title3, design: .rounded).weight(.semibold)).monospacedDigit().foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct StatRow: View {
    let stats: [Stat]
    var body: some View {
        HStack(alignment: .top, spacing: 28) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, s in s }
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }
}

struct Legend: View {
    let items: [(String, Color)]
    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, it in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2.5).fill(it.1).frame(width: 11, height: 11)
                    Text(it.0).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// A small horizontal fill bar (0–100%).
struct MiniBar: View {
    let percent: Double
    var color: Color = HistoryPalette.usage
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.18))
                Capsule().fill(color).frame(width: g.size.width * min(1, max(0, percent / 100)))
            }
        }
        .frame(height: 6)
    }
}

private func average(_ xs: [Double]) -> Double? { xs.isEmpty ? nil : xs.reduce(0, +) / Double(xs.count) }
private func pct(_ v: Double?) -> String { v.map { "\(Int($0.rounded()))%" } ?? "–" }
private func hrs(_ v: Double?) -> String { v.map { String(format: $0 < 10 ? "%.1f h" : "%.0f h", $0) } ?? "–" }

// MARK: overview

/// Four tiles that answer "how am I doing?" before any chart.
struct OverviewTiles: View {
    @EnvironmentObject var model: UsageModel
    let wins: [History.Window]
    let days: [History.Day]
    let range: Int

    var body: some View {
        let now = model.now
        let done = wins.filter(\.done)
        let full = days.filter { $0.trackedHours >= 12 }   // partial days would understate idle time
        let idle = average(full.map(\.idleHours))
        let weekly = model.snapshot?.weekly
        HStack(spacing: 12) {
            Tile(label: "Weekly limit used",
                 value: weekly.map { pct($0.effectivePercent(at: now)) } ?? "–",
                 color: weekly.map { UsageStyle.color(for: $0.effectivePercent(at: now)) } ?? .primary,
                 caption: weekly.map { "Resets " + UsageStyle.resetText($0.resetsAt, now: now) } ?? "No reading yet")
            Tile(label: "Average session peak", value: pct(average(done.map(\.peak))), color: HistoryPalette.usage,
                 caption: "\(done.count) sessions in the last \(range) days")
            Tile(label: "Left unused per session", value: pct(average(done.compactMap(\.unused))), color: HistoryPalette.missed,
                 caption: String(format: "≈ %.1f full sessions' worth in all", done.compactMap(\.unused).reduce(0, +) / 100))
            Tile(label: "Idle per day", value: hrs(idle), color: HistoryPalette.missed,
                 caption: idle.map { String(format: "Room for ~%.1f more sessions a day", $0 / 5) } ?? "Not enough full days yet")
        }
    }

    struct Tile: View {
        let label: String
        let value: String
        let color: Color
        let caption: String
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(label.uppercased()).font(.caption2.weight(.semibold)).tracking(0.6).foregroundStyle(.secondary)
                Text(value).font(.system(size: 34, weight: .semibold, design: .rounded)).monospacedDigit().foregroundStyle(color)
                Text(caption).font(.caption).foregroundStyle(.secondary).lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(HistoryPalette.cardFill))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.primary.opacity(0.07)))
        }
    }
}

// MARK: your day

/// One day: the session % as a line (or 30-minute usage bars) over shading for when a session was
/// running, idle and not recorded, with what was left unused at each reset.
struct DayTimelineCard: View {
    @EnvironmentObject var model: UsageModel
    let style: ChartStyle
    @State private var dayOffset = 0
    @State private var picking = false
    @State private var hover: Date?

    var body: some View {
        let cal = Calendar.current
        let now = model.now
        let day = cal.date(byAdding: .day, value: -dayOffset, to: cal.startOfDay(for: now))!
        let tl = History.timeline(day: day, slotMinutes: 30, readings: model.readings, windows: model.windows, now: now)
        let line = History.sessionLine(day: day, readings: model.readings, now: now)
        let barTop = max(10, (tl.slots.map(\.used).max() ?? 0) * 1.15)
        let top: Double = style == .line ? 100 : barTop
        let first = History.historyStart(readings: model.readings, daily: model.daily).map { cal.startOfDay(for: $0) }
        let isToday = dayOffset == 0

        Card(isToday ? "Your day" : "Your day: \(day.formatted(.dateTime.weekday(.wide)))",
             subtitle: style == .line
                ? "Your session % through the day. It climbs as you use Claude and drops at each reset."
                : "Session % used in each half hour.") {
            HStack(spacing: 6) {
                Button { dayOffset += 1 } label: { Image(systemName: "chevron.left") }
                    .disabled(first.map { day <= $0 } ?? true)
                Button { picking = true } label: {
                    Label(isToday ? "Today" : day.formatted(.dateTime.month(.abbreviated).day()), systemImage: "calendar")
                        .monospacedDigit().frame(minWidth: 86)
                }
                .popover(isPresented: $picking, arrowEdge: .bottom) {
                    let today = cal.startOfDay(for: now)
                    DatePicker("", selection: Binding(
                        get: { day },
                        set: { d in
                            dayOffset = max(0, cal.dateComponents([.day], from: cal.startOfDay(for: d), to: today).day ?? 0)
                            picking = false
                        }), in: (first ?? today)...today, displayedComponents: .date)
                        .datePickerStyle(.graphical).labelsHidden().padding(12)
                }
                Button { dayOffset -= 1 } label: { Image(systemName: "chevron.right") }
                    .disabled(isToday)
                if !isToday { Button("Today") { dayOffset = 0 } }
            }
            .controlSize(.regular)
        } content: {
            dayChart(tl: tl, line: line, top: top, isToday: isToday, now: now)
            Legend(items: [(style == .line ? "Session %" : "Used per half hour", HistoryPalette.usage),
                           ("Session running", Self.shade(.active)), ("Idle (missed)", Self.shade(.idle)),
                           ("Not recorded", Self.shade(.noData))])
            Divider().padding(.vertical, 2)
            StatRow(stats: [
                Stat(value: pct(tl.used), label: isToday ? "used so far" : "used", color: HistoryPalette.usage),
                Stat(value: pct(tl.unusedAtReset), label: "left at resets", color: HistoryPalette.missed),
                Stat(value: hrs(tl.idleHours), label: "idle", color: HistoryPalette.missed),
                Stat(value: String(format: "%.1f", tl.idleSessions), label: "more sessions would fit"),
                Stat(value: hrs(tl.noDataHours), label: "not recorded", color: .secondary),
            ])
        }
    }

    private func dayChart(tl: History.DayTimeline, line: [History.LinePoint], top: Double, isToday: Bool, now: Date) -> some View {
        let resets = tl.windows.filter { $0.done && $0.reset > tl.day && $0.reset <= tl.day.addingTimeInterval(86400) }
        let yTicks: AxisMarkValues = style == .line ? .automatic(desiredCount: 5) : .automatic(desiredCount: 4)
        return Chart {
            shading(tl.slots, top: top)
            if style == .line { lineMarks(line, isToday: isToday) } else { barMarks(tl.slots) }
            resetMarks(resets)
            if isToday { RuleMark(x: .value("Now", now)).foregroundStyle(UsageStyle.red.opacity(0.6)) }
            dayHover(tl: tl, line: line, now: now)
        }
        .hoverX($hover)
        .chartXScale(domain: tl.day...tl.day.addingTimeInterval(86400))
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { _ in
                AxisGridLine(); AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYScale(domain: 0...top)
        .chartYAxis {
            AxisMarks(values: yTicks) { v in
                AxisGridLine(); AxisValueLabel { Text("\(v.as(Double.self).map { Int($0) } ?? 0)%") }
            }
        }
        .padding(.top, 14)
        .frame(height: 230)
    }

    /// What was going on at the hovered time: session %, whether a session was running, its reset.
    private func dayHover(tl: History.DayTimeline, line: [History.LinePoint], now: Date) -> some ChartContent {
        let h = hover.flatMap { $0 >= tl.day && $0 <= min(now, tl.day.addingTimeInterval(86400)) ? $0 : nil }
        let slot = h.flatMap { t in tl.slots.first { $0.start <= t && t < $0.end } }
        let win = h.flatMap { t in tl.windows.first { $0.start <= t && t < $0.reset } }
        var lines: [(String, Color)] = []
        if let slot {
            if slot.state == .noData {
                lines.append(("Not recorded (Mac asleep)", HistoryPalette.none))
            } else {
                if style == .line, let t = h, let p = line.last(where: { $0.ts <= t }), slot.state != .idle {
                    lines.append(("Session \(Int(p.percent))%", HistoryPalette.usage))
                }
                if slot.used > 0 { lines.append((String(format: "%.0f%% used this half hour", slot.used), HistoryPalette.usage)) }
                lines.append(slot.state == .active ? ("Session running", HistoryPalette.running) : ("Idle: no session", HistoryPalette.missed))
                if let w = win { lines.append(("Session resets \(w.reset.formatted(date: .omitted, time: .shortened))", .secondary)) }
            }
        }
        return hoverMark(h, title: h?.formatted(date: .omitted, time: .shortened) ?? "", lines: lines)
    }

    @ChartContentBuilder
    private func shading(_ slots: [History.Slot], top: Double) -> some ChartContent {
        ForEach(slots.filter { $0.state != .future }) { s in
            RectangleMark(xStart: .value("From", s.start), xEnd: .value("To", s.end),
                          yStart: .value("Base", 0), yEnd: .value("Top", top))
                .foregroundStyle(Self.shade(s.state))
        }
    }

    @ChartContentBuilder
    private func lineMarks(_ line: [History.LinePoint], isToday: Bool) -> some ChartContent {
        ForEach(line) { p in
            LineMark(x: .value("Time", p.ts), y: .value("Session %", p.percent), series: .value("Segment", p.segment))
                .foregroundStyle(HistoryPalette.usage)
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
        }
        if isToday, let last = line.last {
            PointMark(x: .value("Time", last.ts), y: .value("Session %", last.percent))
                .foregroundStyle(HistoryPalette.usage).symbolSize(36)
                .annotation(position: .top, spacing: 4) { Text("\(Int(last.percent))%").font(.caption.bold()) }
        }
    }

    @ChartContentBuilder
    private func barMarks(_ slots: [History.Slot]) -> some ChartContent {
        ForEach(slots.filter { $0.used > 0 }) { s in
            RectangleMark(xStart: .value("From", s.start.addingTimeInterval(90)), xEnd: .value("To", s.end.addingTimeInterval(-90)),
                          yStart: .value("Base", 0), yEnd: .value("Used", s.used))
                .foregroundStyle(HistoryPalette.usage)
                .cornerRadius(2)
        }
    }

    @ChartContentBuilder
    private func resetMarks(_ resets: [History.Window]) -> some ChartContent {
        ForEach(resets) { w in
            RuleMark(x: .value("Reset", w.reset))
                .foregroundStyle(Color.secondary.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .annotation(position: .top, spacing: 2, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                    Text("\(Int(w.unused ?? 0))% unused").font(.caption2.weight(.medium))
                        .foregroundStyle((w.unused ?? 0) >= 20 ? HistoryPalette.missed : .secondary)
                }
        }
    }

    static func shade(_ s: History.SlotState) -> Color {
        switch s {
        case .active: return HistoryPalette.running.opacity(0.14)
        case .idle: return HistoryPalette.missed.opacity(0.24)
        case .noData: return HistoryPalette.none.opacity(0.09)
        case .future: return .clear
        }
    }
}

// MARK: sessions

struct SessionsCard: View {
    let wins: [History.Window]
    let style: ChartStyle
    @State private var hover: Date?

    /// The session nearest the pointer: when it ran, its peak and what was left.
    private func sessionHover() -> some ChartContent {
        let w = hover.flatMap { t in wins.min { abs($0.reset.timeIntervalSince(t)) < abs($1.reset.timeIntervalSince(t)) } }
        var lines: [(String, Color)] = []
        if let w {
            lines.append(("Peak \(Int(w.peak))%", HistoryPalette.usage))
            if let u = w.unused { lines.append(("\(Int(u))% left unused", HistoryPalette.missed)) }
            else { lines.append(("Still running", HistoryPalette.running)) }
        }
        let title = w.map {
            "\($0.start.formatted(.dateTime.weekday(.abbreviated).hour().minute())) – \($0.reset.formatted(date: .omitted, time: .shortened))"
        } ?? ""
        return hoverMark(w?.reset, title: title, lines: lines)
    }

    var body: some View {
        let done = wins.filter(\.done)
        let avgPeak = average(done.map(\.peak))
        Card("5-hour sessions",
             subtitle: "How full each session got before it reset. The amber gap above the line is capacity you didn't use.") {
            if wins.isEmpty { Text("No sessions yet").foregroundStyle(.secondary) } else {
                Chart {
                    if style == .line {
                        ForEach(done) { w in
                            AreaMark(x: .value("Reset", w.reset), yStart: .value("Peak", w.peak), yEnd: .value("Full", 100))
                                .foregroundStyle(HistoryPalette.missed.opacity(0.10))
                        }
                        ForEach(wins) { w in
                            LineMark(x: .value("Reset", w.reset), y: .value("Peak", w.peak))
                                .foregroundStyle(HistoryPalette.usage)
                                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            PointMark(x: .value("Reset", w.reset), y: .value("Peak", w.peak))
                                .foregroundStyle(w.done ? HistoryPalette.usage : HistoryPalette.usage.opacity(0.4))
                                .symbolSize(28)
                        }
                    } else {
                        ForEach(wins) { w in
                            BarMark(x: .value("Reset", w.reset), y: .value("Peak", w.peak), width: .fixed(9))
                                .foregroundStyle(HistoryPalette.usage).cornerRadius(2)
                            if let u = w.unused {
                                BarMark(x: .value("Reset", w.reset), y: .value("Unused", u), width: .fixed(9))
                                    .foregroundStyle(HistoryPalette.missed.opacity(0.35)).cornerRadius(2)
                            }
                        }
                    }
                    if let a = avgPeak {
                        RuleMark(y: .value("Average", a))
                            .foregroundStyle(Color.secondary.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .leading, spacing: 2) {
                                Text("average \(Int(a.rounded()))%").font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                            }
                    }
                    sessionHover()
                }
                .hoverX($hover)
                .chartYScale(domain: 0...100)
                .chartYAxis { AxisMarks(values: [0, 50, 100]) { v in AxisGridLine(); AxisValueLabel { Text("\(v.as(Int.self) ?? 0)%") } } }
                .frame(height: 190)
                Legend(items: [("Session peak", HistoryPalette.usage), ("Left unused", HistoryPalette.missed.opacity(0.35))])
                Divider().padding(.vertical, 2)
                StatRow(stats: [
                    Stat(value: "\(done.count)", label: "sessions"),
                    Stat(value: pct(avgPeak), label: "average peak", color: HistoryPalette.usage),
                    Stat(value: pct(done.map(\.peak).max()), label: "fullest"),
                    Stat(value: pct(average(done.compactMap(\.unused))), label: "left unused, average", color: HistoryPalette.missed),
                ])
            }
        }
    }
}

// MARK: days

struct DaysCard: View {
    @EnvironmentObject var model: UsageModel
    let days: [History.Day]
    let style: ChartStyle
    @State private var hover: Date?

    /// The day under the pointer: hours running, idle, sessions and average peak.
    private func dayHover() -> some ChartContent {
        let d = hover.flatMap { t in days.min { abs($0.date.addingTimeInterval(43200).timeIntervalSince(t)) < abs($1.date.addingTimeInterval(43200).timeIntervalSince(t)) } }
        var lines: [(String, Color)] = []
        if let d {
            lines.append((hrs(max(0, d.trackedHours - d.idleHours)) + " session running", HistoryPalette.running))
            lines.append((hrs(d.idleHours) + " idle", HistoryPalette.missed))
            lines.append(("\(d.windows) sessions, average peak \(pct(d.avgPeak))", HistoryPalette.usage))
            if d.trackedHours < 23.5 { lines.append((hrs(24 - d.trackedHours) + " not recorded", HistoryPalette.none)) }
        }
        return hoverMark(d.map { $0.date.addingTimeInterval(43200) },
                         title: d?.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) ?? "", lines: lines)
    }

    var body: some View {
        Card("Days", subtitle: "Hours with a session running versus idle hours you could have used. Each row shows the day hour by hour.") {
            if days.isEmpty { Text("No days yet").foregroundStyle(.secondary) } else {
                Chart {
                    ForEach(days) { d in
                        let active = max(0, d.trackedHours - d.idleHours)
                        if style == .line {
                            LineMark(x: .value("Day", d.date, unit: .day), y: .value("Hours", active), series: .value("Kind", "running"))
                                .foregroundStyle(HistoryPalette.running)
                                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            PointMark(x: .value("Day", d.date, unit: .day), y: .value("Hours", active))
                                .foregroundStyle(HistoryPalette.running).symbolSize(24)
                            LineMark(x: .value("Day", d.date, unit: .day), y: .value("Hours", d.idleHours), series: .value("Kind", "idle"))
                                .foregroundStyle(HistoryPalette.missed)
                                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            PointMark(x: .value("Day", d.date, unit: .day), y: .value("Hours", d.idleHours))
                                .foregroundStyle(HistoryPalette.missed).symbolSize(24)
                        } else {
                            BarMark(x: .value("Day", d.date, unit: .day), y: .value("Hours", active))
                                .foregroundStyle(HistoryPalette.running).cornerRadius(2)
                            BarMark(x: .value("Day", d.date, unit: .day), y: .value("Hours", d.idleHours))
                                .foregroundStyle(HistoryPalette.missed.opacity(0.6)).cornerRadius(2)
                        }
                    }
                    dayHover()
                }
                .hoverX($hover)
                .chartYAxis { AxisMarks(values: [0, 6, 12, 18, 24]) { v in AxisGridLine(); AxisValueLabel { Text("\(v.as(Int.self) ?? 0) h") } } }
                .chartYScale(domain: 0...24)
                .frame(height: 170)
                Legend(items: [("Session running", HistoryPalette.running), ("Idle (missed)", HistoryPalette.missed)])
                Divider().padding(.vertical, 4)
                DayList(days: Array(days.reversed()))
            }
        }
    }
}

/// One row per day: date, a 24-hour strip (blue = used, green = session running, amber = idle,
/// grey = not recorded) and the day's numbers in aligned columns.
struct DayList: View {
    @EnvironmentObject var model: UsageModel
    let days: [History.Day]

    private let dateW: CGFloat = 64, colW: CGFloat = 74, peakW: CGFloat = 110

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Spacer().frame(width: dateW)
                GeometryReader { g in
                    ForEach([0, 6, 12, 18], id: \.self) { h in
                        Text(h == 0 ? "12a" : h == 12 ? "12p" : "\(h % 12)\(h < 12 ? "a" : "p")")
                            .font(.caption2).foregroundStyle(.secondary)
                            .position(x: g.size.width * CGFloat(h) / 24 + 9, y: 6)
                    }
                }
                .frame(height: 12)
                head("Sessions", colW); head("Avg peak", peakW); head("Idle", colW); head("Weekly", colW)
            }
            .padding(.bottom, 6)
            ForEach(Array(days.enumerated()), id: \.element.id) { i, d in
                row(d)
                    .padding(.vertical, 7)
                    .background(i % 2 == 1 ? Color.primary.opacity(0.03) : .clear, in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private func head(_ s: String, _ w: CGFloat) -> some View {
        Text(s).font(.caption).foregroundStyle(.secondary).frame(width: w, alignment: .leading)
    }

    private func row(_ d: History.Day) -> some View {
        let cal = Calendar.current
        // Only that day's readings (plus a little before, for the first rise of the day).
        let from = d.date.addingTimeInterval(-6 * 3600), to = d.date.addingTimeInterval(86400)
        let rs = model.readings.filter { $0.ts >= from && $0.ts < to }
        let tl = History.timeline(day: d.date, slotMinutes: 60, readings: rs, windows: model.windows, now: model.now)
        let isToday = cal.isDateInToday(d.date)
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(isToday ? "Today" : d.date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.callout.weight(.semibold))
                Text(d.date.formatted(.dateTime.month(.abbreviated).day())).font(.caption).foregroundStyle(.secondary)
            }
            .frame(width: dateW, alignment: .leading)
            DayStrip(slots: tl.slots).frame(height: 18)
            Text("\(d.windows)").monospacedDigit().frame(width: colW, alignment: .leading)
            HStack(spacing: 6) {
                MiniBar(percent: d.avgPeak ?? 0).frame(width: 52)
                Text(pct(d.avgPeak)).monospacedDigit()
            }
            .frame(width: peakW, alignment: .leading)
            Text(hrs(d.idleHours)).monospacedDigit()
                .foregroundStyle(d.idleHours >= 5 ? HistoryPalette.missed : .primary)
                .frame(width: colW, alignment: .leading)
            Text(pct(d.weeklyEnd)).monospacedDigit().foregroundStyle(.secondary).frame(width: colW, alignment: .leading)
        }
        .font(.callout)
    }
}

/// 24 (or 48) small cells for one day. Hours where usage rose are blue, deeper the more was used.
struct DayStrip: View {
    let slots: [History.Slot]
    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(slots) { s in
                RoundedRectangle(cornerRadius: 2.5).fill(color(s))
            }
        }
    }

    private func color(_ s: History.Slot) -> Color {
        switch s.state {
        case .active: return s.used > 0 ? HistoryPalette.usage.opacity(0.45 + min(1, s.used / 25) * 0.55) : HistoryPalette.running.opacity(0.45)
        case .idle: return HistoryPalette.missed.opacity(0.55)
        case .noData: return HistoryPalette.none.opacity(0.14)
        case .future: return HistoryPalette.none.opacity(0.05)
        }
    }
}

// MARK: models

private func tokens(_ n: Double) -> String {
    n >= 1e9 ? String(format: "%.1fB", n / 1e9) : n >= 1e6 ? String(format: "%.1fM", n / 1e6)
        : n >= 1e3 ? String(format: "%.0fK", n / 1e3) : String(Int(n))
}

/// Tokens per model per day (line per model, or stacked bars), a row per day with the model split,
/// and the official weekly limit % used that day (all models, and per-model limits such as Fable).
struct ModelsCard: View {
    @EnvironmentObject var model: UsageModel
    let range: Int
    let style: ChartStyle
    @State private var hover: Date?

    static let palette: [Color] = [HistoryPalette.usage, .purple, .teal, .pink, .indigo, .brown, .mint]

    var body: some View {
        let cal = Calendar.current
        let cutoff = cal.startOfDay(for: model.now.addingTimeInterval(-Double(range - 1) * 86400))
        let days = ModelUsage.days(model.chats?.modelRows ?? []).filter { $0.date >= cutoff }
        let gains = ModelUsage.limitGains(readings: model.readings)
        let names = Self.order(days)
        Card("Models by day",
             subtitle: "Which models you used each day, by tokens (Claude Code exact; claude.ai chats estimated, by each chat's model). Right: how much of each weekly limit Anthropic tracks you used that day.") {
            if days.isEmpty {
                Text("No model data yet. It fills in as chat tracking runs.").foregroundStyle(.secondary)
            } else {
                chart(days, names: names, gains: gains)
                Divider().padding(.vertical, 4)
                VStack(spacing: 0) {
                    ForEach(Array(days.reversed().enumerated()), id: \.element.id) { i, d in
                        row(d, names: names, gains: gains[d.date] ?? [:])
                            .padding(.vertical, 7)
                            .background(i % 2 == 1 ? Color.primary.opacity(0.03) : .clear, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    /// Models by total use in the range (so colours stay put), "Unknown" last.
    static func order(_ days: [ModelUsage.Day]) -> [String] {
        var totals: [String: Double] = [:]
        for d in days { for m in d.models { totals[m.name, default: 0] += m.tokens } }
        return totals.sorted { ($0.key == "Unknown" ? 0 : 1, $0.value) > ($1.key == "Unknown" ? 0 : 1, $1.value) }.map(\.key)
    }

    static func color(_ name: String, in names: [String]) -> Color {
        if name == "Unknown" { return .gray }
        return palette[(names.firstIndex(of: name) ?? 0) % palette.count]
    }

    private func chart(_ days: [ModelUsage.Day], names: [String], gains: [Date: [String: Double]]) -> some View {
        Chart {
            ForEach(days) { d in
                ForEach(names, id: \.self) { n in
                    let t = (d.models.first { $0.name == n }?.tokens ?? 0) / 1e6
                    if style == .line {
                        LineMark(x: .value("Day", d.date, unit: .day), y: .value("Tokens (M)", t), series: .value("Model", n))
                            .foregroundStyle(by: .value("Model", n))
                            .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        PointMark(x: .value("Day", d.date, unit: .day), y: .value("Tokens (M)", t))
                            .foregroundStyle(by: .value("Model", n)).symbolSize(22)
                    } else if t > 0 {
                        BarMark(x: .value("Day", d.date, unit: .day), y: .value("Tokens (M)", t))
                            .foregroundStyle(by: .value("Model", n)).cornerRadius(2)
                    }
                }
            }
            modelHover(days, names: names, gains: gains)
        }
        .chartForegroundStyleScale(domain: names, range: names.map { Self.color($0, in: names) })
        .chartYAxis { AxisMarks { v in AxisGridLine(); AxisValueLabel { Text("\(v.as(Double.self).map { String(format: "%g", $0) } ?? "")M") } } }
        .chartLegend(position: .bottom, alignment: .leading)
        .hoverX($hover)
        .frame(height: 200)
    }

    private func modelHover(_ days: [ModelUsage.Day], names: [String], gains: [Date: [String: Double]]) -> some ChartContent {
        let d = hover.flatMap { t in days.min { abs($0.date.addingTimeInterval(43200).timeIntervalSince(t)) < abs($1.date.addingTimeInterval(43200).timeIntervalSince(t)) } }
        var lines: [(String, Color)] = []
        if let d {
            for m in d.models {
                lines.append(("\(m.name): \(tokens(m.tokens)) (\(Int((m.tokens / max(1, d.total) * 100).rounded()))%)", Self.color(m.name, in: names)))
            }
            for (k, v) in (gains[d.date] ?? [:]).sorted(by: { $0.key < $1.key }) {
                lines.append(("\(k) weekly limit +\(Int(v.rounded()))%", .secondary))
            }
        }
        return hoverMark(d.map { $0.date.addingTimeInterval(43200) },
                         title: d?.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()) ?? "", lines: lines)
    }

    private func row(_ d: ModelUsage.Day, names: [String], gains: [String: Double]) -> some View {
        let isToday = Calendar.current.isDateInToday(d.date)
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(isToday ? "Today" : d.date.formatted(.dateTime.weekday(.abbreviated))).font(.callout.weight(.semibold))
                Text(d.date.formatted(.dateTime.month(.abbreviated).day())).font(.caption).foregroundStyle(.secondary)
            }
            .frame(width: 64, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { g in
                    HStack(spacing: 1.5) {
                        ForEach(d.models, id: \.name) { m in
                            RoundedRectangle(cornerRadius: 2.5).fill(Self.color(m.name, in: names))
                                .frame(width: max(2, g.size.width * m.tokens / max(1, d.total) - 1.5))
                        }
                    }
                }
                .frame(height: 10)
                Text(d.models.prefix(3).map { "\($0.name) \(Int(($0.tokens / max(1, d.total) * 100).rounded()))%" }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Text(tokens(d.total) + " tokens").monospacedDigit().frame(width: 100, alignment: .leading)
            Text(gains.isEmpty ? "–" : gains.sorted { $0.key < $1.key }.map { "\($0.key) +\(Int($0.value.rounded()))%" }.joined(separator: " · "))
                .font(.caption).foregroundStyle(.secondary).frame(width: 190, alignment: .leading)
        }
        .font(.callout)
    }
}

// MARK: weeks

struct WeeksCard: View {
    let weeks: [History.Week]
    let style: ChartStyle
    @State private var hover: Date?

    /// The reading nearest the pointer: the weekly % on that day and which week it belongs to.
    private func weekHover() -> some ChartContent {
        let points = weeks.flatMap { w in w.trend.map { (week: w, ts: $0.0, value: $0.1) } }
        let p = hover.flatMap { t in points.min { abs($0.ts.timeIntervalSince(t)) < abs($1.ts.timeIntervalSince(t)) } }
        var lines: [(String, Color)] = []
        if let p {
            lines.append(("Weekly limit \(Int(p.value))% used", UsageStyle.color(for: p.value)))
            lines.append(("Week of \(p.week.start.formatted(.dateTime.month(.abbreviated).day())), resets \(p.week.reset.formatted(.dateTime.weekday(.abbreviated).hour()))", .secondary))
        }
        return hoverMark(p?.ts, title: p?.ts.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()) ?? "", lines: lines)
    }

    var body: some View {
        Card("Weekly limit", subtitle: "How your weekly limit filled up, one line per week. Steeper means a heavier week.") {
            if weeks.isEmpty { Text("No weeks yet").foregroundStyle(.secondary) } else {
                Chart {
                    ForEach(weeks) { w in
                        ForEach(Array(w.trend.enumerated()), id: \.offset) { _, p in
                            if style == .line {
                                LineMark(x: .value("Day", p.0), y: .value("Weekly %", p.1), series: .value("Week", w.reset))
                                    .foregroundStyle(by: .value("Week", w.start.formatted(.dateTime.month(.abbreviated).day())))
                                    .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                                PointMark(x: .value("Day", p.0), y: .value("Weekly %", p.1))
                                    .foregroundStyle(by: .value("Week", w.start.formatted(.dateTime.month(.abbreviated).day())))
                                    .symbolSize(22)
                            } else {
                                BarMark(x: .value("Day", p.0, unit: .day), y: .value("Weekly %", p.1))
                                    .foregroundStyle(by: .value("Week", w.start.formatted(.dateTime.month(.abbreviated).day())))
                                    .cornerRadius(2)
                            }
                        }
                    }
                    weekHover()
                }
                .hoverX($hover)
                .chartYScale(domain: 0...100)
                .chartYAxis { AxisMarks(values: [0, 50, 100]) { v in AxisGridLine(); AxisValueLabel { Text("\(v.as(Int.self) ?? 0)%") } } }
                .chartLegend(position: .bottom, alignment: .leading)
                .chartXScale(range: .plotDimension(startPadding: 4, endPadding: 24))
                .frame(height: 170)
                Divider().padding(.vertical, 4)
                VStack(spacing: 10) {
                    ForEach(weeks.reversed()) { w in
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Week of \(w.start.formatted(.dateTime.month(.abbreviated).day()))").font(.callout.weight(.semibold))
                                Text("resets \(w.reset.formatted(.dateTime.weekday(.abbreviated).hour()))").font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(width: 130, alignment: .leading)
                            MiniBar(percent: w.weeklyPeak, color: UsageStyle.color(for: w.weeklyPeak))
                            Text(pct(w.weeklyPeak)).monospacedDigit().frame(width: 44, alignment: .trailing)
                            Text("\(w.windows) sessions").foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
                            Text("avg peak \(pct(w.avgPeak))").foregroundStyle(.secondary).frame(width: 110, alignment: .leading)
                            Text("\(hrs(w.idleHours)) idle").foregroundStyle(HistoryPalette.missed).frame(width: 80, alignment: .leading)
                        }
                        .font(.callout)
                    }
                }
            }
        }
    }
}

// MARK: chats

struct ChatHistory: View {
    @EnvironmentObject var model: UsageModel
    let range: Int
    @State private var showAll = false

    var body: some View {
        let rows = model.chats?.rows ?? []
        let weekStart = model.snapshot?.weekly?.resetsAt.map { $0.addingTimeInterval(-7 * 86400) }
            ?? model.now.addingTimeInterval(-7 * 86400)
        let all = ChatTracking.totals(rows, since: weekStart)
        let week = all.filter { $0.id != ChatTracking.unattributed }
        let unattributed = all.filter { $0.id == ChatTracking.unattributed }.reduce(0) { $0 + $1.percent }
        let windows = Set(rows.map(\.window)).sorted(by: >)
        let shown = showAll ? Array(windows.prefix(range * 3)) : Array(windows.prefix(8))
        Card("Top chats this week",
             subtitle: "Estimated share of your session use per chat. Each rise in session % is split among the chats active at the time, by estimated tokens.") {
            if week.isEmpty { Text("No tracked chats yet").foregroundStyle(.secondary) }
            ChatTable(totals: Array(week.prefix(15)))
            if unattributed > 0 {
                Text(String(format: "Plus about %.1f sessions' worth of use with no tracked chat activity (other devices, or while the Mac was asleep).", unattributed / 100))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        Card("Chats by session", subtitle: "Open a session to see which chats used it.") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(shown, id: \.self) { w in
                    let tot = ChatTracking.totals(rows, window: w)
                    DisclosureGroup {
                        ChatTable(totals: tot).padding(.top, 6)
                    } label: {
                        HStack {
                            Text("\(w.addingTimeInterval(-History.sessionLength).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())) – \(w.formatted(date: .omitted, time: .shortened))")
                            Spacer()
                            Text(String(format: "%.0f%% attributed", tot.reduce(0) { $0 + $1.percent }))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                if windows.count > 8 {
                    Button(showAll ? "Show fewer" : "Show all \(min(windows.count, range * 3)) sessions") { showAll.toggle() }
                        .buttonStyle(.link).padding(.top, 4)
                }
            }
        }
    }
}

struct ChatTable: View {
    let totals: [ChatTracking.Total]
    var body: some View {
        let top = max(1, totals.map(\.percent).max() ?? 1)
        VStack(spacing: 0) {
            ForEach(Array(totals.enumerated()), id: \.element.id) { i, t in
                HStack(spacing: 12) {
                    Group {
                        if t.source == "chat", let u = URL(string: "https://claude.ai/chat/\(t.id)") {
                            Link(t.title, destination: u)
                        } else {
                            Text(t.title)
                        }
                    }
                    .lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(t.source == "chat" ? "Chat" : (t.source == "code" ? "Code" : "–"))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(Color.secondary.opacity(0.14)))
                        .frame(width: 56)
                    Text(Int(t.tokens).formatted() + " tok").font(.caption).monospacedDigit().foregroundStyle(.secondary)
                        .frame(width: 96, alignment: .trailing)
                    MiniBar(percent: t.percent / top * 100).frame(width: 80)
                    Text(String(format: "%.1f%%", t.percent)).monospacedDigit().frame(width: 52, alignment: .trailing)
                }
                .font(.callout)
                .padding(.vertical, 5).padding(.horizontal, 6)
                .background(i % 2 == 1 ? Color.primary.opacity(0.03) : .clear, in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
