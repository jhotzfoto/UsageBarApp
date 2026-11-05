import Charts
import SwiftUI
import UsageCore

/// History window: 5-hour windows (peak and unused), days (windows used, idle hours), weekly windows
/// (trend), and estimated top chats per week and per window.
struct HistoryView: View {
    @EnvironmentObject var model: UsageModel
    @State private var range = 14

    var body: some View {
        let now = model.now
        let wins = model.windows.filter { $0.reset > now.addingTimeInterval(-Double(range) * 86400) }
        let days = History.days(readings: model.readings, daily: model.daily, now: now)
            .filter { $0.date > now.addingTimeInterval(-Double(range) * 86400) }
        let weeks = History.weeks(readings: model.readings, daily: model.daily, now: now)
        let start = History.historyStart(readings: model.readings, daily: model.daily)

        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude usage history").font(.title2.bold())
                        Text("History starts \(start?.formatted(date: .abbreviated, time: .omitted) ?? "–"). Gaps while the Mac was asleep aren't filled in. Older than 30 days: daily summaries.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("", selection: $range) {
                        Text("7 days").tag(7); Text("14 days").tag(14); Text("30 days").tag(30)
                    }
                    .pickerStyle(.segmented).frame(width: 220)
                }

                section("5-hour windows: peak and unused at reset") {
                    if wins.isEmpty { empty } else {
                        Chart(wins) { w in
                            BarMark(x: .value("Reset", w.reset), y: .value("Used", w.peak))
                                .foregroundStyle(UsageStyle.color(for: w.peak))
                            if let u = w.unused {
                                BarMark(x: .value("Reset", w.reset), y: .value("Unused", u))
                                    .foregroundStyle(Color.secondary.opacity(0.25))
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis { AxisMarks(values: [0, 50, 100]) { v in AxisGridLine(); AxisValueLabel { Text("\(v.as(Int.self) ?? 0)%") } } }
                        .frame(height: 160)
                        let done = wins.filter(\.done)
                        if !done.isEmpty {
                            Text(String(format: "%d windows · average peak %.0f%% · average unused %.0f%%", done.count,
                                        done.map(\.peak).reduce(0, +) / Double(done.count),
                                        done.compactMap(\.unused).reduce(0, +) / Double(done.count)))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                section("Days: idle hours (no active session)") {
                    if days.isEmpty { empty } else {
                        Chart(days) { d in
                            BarMark(x: .value("Day", d.date, unit: .day), y: .value("Idle h", d.idleHours))
                                .foregroundStyle(Color.secondary.opacity(0.5))
                            BarMark(x: .value("Day", d.date, unit: .day), y: .value("Active h", max(0, d.trackedHours - d.idleHours)))
                                .foregroundStyle(UsageStyle.green)
                        }
                        .frame(height: 140)
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                            GridRow { head("Day"); head("Windows"); head("Avg peak"); head("Idle"); head("Weekly at end") }
                            ForEach(days.reversed()) { d in
                                GridRow {
                                    Text(d.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                    Text("\(d.windows)").monospacedDigit()
                                    Text(d.avgPeak.map { "\(Int($0.rounded()))%" } ?? "–").monospacedDigit()
                                    Text(String(format: "%.1f h of %.0f", d.idleHours, d.trackedHours)).monospacedDigit()
                                    Text(d.weeklyEnd.map { "\(Int($0))%" } ?? "–").monospacedDigit()
                                }
                                .font(.callout)
                            }
                        }
                    }
                }

                section("Weekly windows") {
                    if weeks.isEmpty { empty } else {
                        Chart {
                            ForEach(weeks) { w in
                                ForEach(Array(w.trend.enumerated()), id: \.offset) { _, p in
                                    LineMark(x: .value("Day", p.0), y: .value("Weekly %", p.1), series: .value("Week", w.reset))
                                    PointMark(x: .value("Day", p.0), y: .value("Weekly %", p.1)).symbolSize(16)
                                }
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .frame(height: 140)
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                            GridRow { head("Week"); head("Windows"); head("Avg peak"); head("Idle"); head("Weekly peak") }
                            ForEach(weeks.reversed()) { w in
                                GridRow {
                                    Text("From " + w.start.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                                    Text("\(w.windows)").monospacedDigit()
                                    Text(w.avgPeak.map { "\(Int($0.rounded()))%" } ?? "–").monospacedDigit()
                                    Text(String(format: "%.0f h", w.idleHours)).monospacedDigit()
                                    Text("\(Int(w.weeklyPeak))%").monospacedDigit()
                                }
                                .font(.callout)
                            }
                        }
                    }
                }

                ChatHistory(range: range)
            }
            .padding(24)
        }
        .frame(minWidth: 720, minHeight: 600)
    }

    private var empty: some View { Text("No data yet").foregroundStyle(.secondary) }
    private func head(_ s: String) -> some View { Text(s).font(.caption).foregroundStyle(.secondary) }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
    }
}

struct ChatHistory: View {
    @EnvironmentObject var model: UsageModel
    let range: Int

    var body: some View {
        let rows = model.chats?.rows ?? []
        let weekStart = model.snapshot?.weekly?.resetsAt.map { $0.addingTimeInterval(-7 * 86400) }
            ?? model.now.addingTimeInterval(-7 * 86400)
        let week = ChatTracking.totals(rows, since: weekStart)
        let windows = Set(rows.map(\.window)).sorted(by: >)
        VStack(alignment: .leading, spacing: 8) {
            Text("Top chats this week (estimated)").font(.headline)
            Text("Each rise in session % is split among the chats with new activity since the previous rise, by estimated tokens (claude.ai: ~4 characters per token of context per model call; Claude Code: exact token counts). Rough estimates.")
                .font(.caption).foregroundStyle(.secondary)
            if week.isEmpty { Text("No tracked chats yet").foregroundStyle(.secondary) }
            ChatTable(totals: Array(week.prefix(15)))
            Text("Chats by 5-hour window (estimated)").font(.headline).padding(.top, 8)
            ForEach(windows.prefix(range * 3), id: \.self) { w in
                let tot = ChatTracking.totals(rows, window: w)
                DisclosureGroup {
                    ChatTable(totals: tot)
                } label: {
                    Text("\(w.addingTimeInterval(-History.sessionLength).formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())) – \(w.formatted(date: .omitted, time: .shortened))")
                    + Text(String(format: "  (%.0f%% attributed)", tot.reduce(0) { $0 + $1.percent })).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ChatTable: View {
    let totals: [ChatTracking.Total]
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
            GridRow {
                Text("Chat").font(.caption).foregroundStyle(.secondary)
                Text("Source").font(.caption).foregroundStyle(.secondary)
                Text("Est. tokens").font(.caption).foregroundStyle(.secondary)
                Text("Est. session %").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(totals) { t in
                GridRow {
                    if t.source == "chat", let u = URL(string: "https://claude.ai/chat/\(t.id)") {
                        Link(t.title, destination: u).lineLimit(1)
                    } else {
                        Text(t.title + (t.source == "code" ? " (code)" : "")).lineLimit(1)
                    }
                    Text(t.source == "chat" ? "Chat" : (t.source == "code" ? "Claude Code" : "–"))
                    Text(Int(t.tokens).formatted()).monospacedDigit()
                    Text(String(format: "%.1f%%", t.percent)).monospacedDigit()
                }
                .font(.callout)
            }
        }
    }
}
