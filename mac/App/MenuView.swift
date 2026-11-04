import SwiftUI

/// The dropdown: every limit with %, bar, reset time and countdown; extra usage budget;
/// Anthropic's weekly split by product; status and actions.
struct MenuView: View {
    @EnvironmentObject var model: UsageModel
    @Environment(\.openSettings) private var openSettings

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

            if let snap = model.snapshot, !snap.limits.isEmpty {
                ForEach(snap.limits) { LimitRow(limit: $0, now: model.now, dimmed: model.staleReason != nil) }
                if let ex = snap.extra { ExtraRow(extra: ex, sessionFull: (snap.session?.effectivePercent(at: model.now) ?? 0) >= 100) }
                if !snap.breakdown.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 3) {
                        Text("This week by product (from Anthropic)").font(.caption).foregroundStyle(.secondary)
                        Text(snap.breakdown.map { "\($0.name) \(Int($0.percent))%" }.joined(separator: " · "))
                            .font(.callout.monospacedDigit())
                    }
                }
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
                Button("claude.ai usage") { NSWorkspace.shared.open(URL(string: "https://claude.ai/settings/usage")!) }
                Spacer()
                Button("Settings…") { NSApp.activate(ignoringOtherApps: true); openSettings() }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(14)
        .frame(width: 340)
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
