import SwiftUI
import UsageCore

/// The dropdown: limits (with pace), extra usage, planning, Anthropic's split by product, top chats
/// (estimated), Claude status, and actions.
struct MenuView: View {
    @EnvironmentObject var model: UsageModel
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let reason = model.staleReason {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Stale since \(model.snapshot.map { $0.fetchedAt == .distantPast ? "never" : $0.fetchedAt.formatted(date: .omitted, time: .shortened) } ?? "never")",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(UsageStyle.red).font(.callout.weight(.semibold))
                    Text(reason).font(.caption).foregroundStyle(.secondary)
                }
                Divider()
            }
            if let st = model.status, !st.isOperational {
                Button { NSWorkspace.shared.open(URL(string: "https://status.anthropic.com")!) } label: {
                    Label(st.incidents.first?.name ?? st.description, systemImage: "bolt.horizontal.circle.fill")
                        .foregroundStyle(UsageStyle.amber).font(.callout)
                }
                .buttonStyle(.plain)
                Divider()
            }

            if let snap = model.snapshot, !snap.limits.isEmpty {
                ForEach(snap.limits) { l in
                    LimitRow(limit: l, now: model.now, dimmed: model.staleReason != nil, pace: model.pace(for: l))
                }
                if let ex = snap.extra { ExtraRow(extra: ex, sessionFull: (snap.session?.effectivePercent(at: model.now) ?? 0) >= 100) }
                Divider()
                VStack(alignment: .leading, spacing: 3) {
                    Text("Planning").font(.caption).foregroundStyle(.secondary)
                    Text(Forecast.nextSessionText(session: snap.session, windows: model.windows, now: model.now)).font(.callout)
                    if let w = snap.weekly, let plan = Forecast.weeklyPlan(w, now: model.now) { Text("Weekly: " + plan).font(.callout) }
                    if !snap.breakdown.isEmpty {
                        Text("This week by product: " + snap.breakdown.map { "\($0.name) \(Int($0.percent))%" }.joined(separator: " · "))
                            .font(.callout)
                    }
                }
                if let c = model.chatSummary { TopChats(summary: c) }
            } else if !model.isFetching {
                Text("No reading yet").foregroundStyle(.secondary)
            }

            Divider()
            HStack {
                if let s = model.snapshot, s.fetchedAt != .distantPast {
                    Text("Updated \(s.fetchedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if model.isFetching { ProgressView().controlSize(.small) }
                Spacer()
                Button("Refresh") { Task { await model.refresh(minGap: 0) } }
                    .disabled(model.isFetching)
            }
            HStack {
                Button("History") { NSApp.activate(ignoringOtherApps: true); openWindow(id: "history") }
                Button("claude.ai usage") { NSWorkspace.shared.open(URL(string: "https://claude.ai/settings/usage")!) }
                Spacer()
                Button("About") { NSApp.activate(ignoringOtherApps: true); openWindow(id: "about") }
                Button("Settings…") { NSApp.activate(ignoringOtherApps: true); openSettings() }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(14)
        .frame(width: 380)
        .task { await model.refresh(minGap: UsageModel.clickFetchGap) }
    }
}

struct Bar: View {
    let percent: Double
    let color: Color
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.2))
                Capsule().fill(color).frame(width: g.size.width * min(1, max(0, percent / 100)))
            }
        }
        .frame(height: 6)
    }
}

struct LimitRow: View {
    let limit: UsageLimit
    let now: Date
    let dimmed: Bool
    let pace: Forecast.Pace?

    var body: some View {
        let pct = limit.effectivePercent(at: now)
        let color = dimmed ? UsageStyle.dim : UsageStyle.color(for: pct)
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(limit.label)
                Spacer()
                Text("\(Int(pct))%").monospacedDigit().foregroundStyle(color).fontWeight(.semibold)
            }
            Bar(percent: pct, color: color)
            Text(limit.hasReset(at: now) ? "Reset; waiting for next update" : "Resets \(UsageStyle.resetText(limit.resetsAt, now: now))")
                .font(.caption).foregroundStyle(.secondary)
            if let p = pace, limit.key == "session" || limit.key == "weekly_all" {
                Text(Forecast.paceText(p, limit: limit, now: now))
                    .font(.caption).foregroundStyle(p.hitsLimitAt != nil && limit.percent < 100 ? UsageStyle.amber : .secondary)
            }
        }
    }
}

struct ExtraRow: View {
    let extra: ExtraUsage
    let sessionFull: Bool

    var body: some View {
        let color = UsageStyle.color(for: extra.percent)
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("Extra usage · monthly")
                Spacer()
                Text("\(Int(extra.percent))%").monospacedDigit().foregroundStyle(color).fontWeight(.semibold)
            }
            Bar(percent: extra.percent, color: color)
            Text(String(format: "$%.2f of $%.2f %@ used", extra.used, extra.limit, extra.currency)
                 + (extra.reached ? " · limit reached" : (sessionFull ? " · session full, using budget" : "")))
                .font(.caption).foregroundStyle(extra.reached ? UsageStyle.red : .secondary)
        }
    }
}

/// Same layout as UsageBar 1.4.2: tracked vs logged with the token check, top chats, top-N total,
/// others and unattributed.
struct TopChats: View {
    let summary: UsageModel.ChatSummary

    var body: some View {
        Divider()
        VStack(alignment: .leading, spacing: 3) {
            Text("Top chats this session (est.)").font(.caption).foregroundStyle(.secondary)
            if let st = summary.status { Text(st).font(.caption).foregroundStyle(UsageStyle.amber) }
            Text(String(format: "Chats: %.2f%% tracked vs %d%% logged · token estimate: ", summary.tracked, Int(summary.logged))
                 + (summary.tokenEstimate.map { "\(Int($0.rounded()))%" } ?? "n/a"))
                .font(.caption.monospacedDigit())
                .foregroundStyle(summary.drift ? UsageStyle.amber : .secondary)
            if summary.top.isEmpty { Text("No tracked activity yet").font(.caption).foregroundStyle(.secondary) }
            ForEach(summary.top) { t in
                Button { open(t) } label: {
                    HStack(spacing: 6) {
                        Text(String(format: "%5.1f%%", t.percent)).monospacedDigit().frame(width: 52, alignment: .trailing)
                        Text(t.title + (t.source == "code" ? " (code)" : "")).lineLimit(1).truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .font(.callout)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if !summary.top.isEmpty {
                Text(String(format: "Top %d total: %.1f%%", summary.top.count, summary.top.reduce(0) { $0 + $1.percent }))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            if summary.othersCount > 0 {
                Text(String(format: "%d others: %.1f%%", summary.othersCount, summary.othersPercent))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            if summary.unattributed > 0 {
                Text(String(format: "Unattributed: %.1f%%", summary.unattributed)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
    }

    private func open(_ t: ChatTracking.Total) {
        if t.source == "code" {
            if let p = summary.projects[t.id] { NSWorkspace.shared.open(URL(fileURLWithPath: p)) }
        } else {
            NSWorkspace.shared.open(URL(string: "https://claude.ai/chat/\(t.id)")!)
        }
    }
}
