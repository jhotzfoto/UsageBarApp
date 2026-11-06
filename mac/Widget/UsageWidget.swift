import SwiftUI
import UsageCore
import WidgetKit

/// Desktop / Notification Center widgets. They only read the snapshot the app shares through the
/// App Group; the app reloads them after every reading. Countdowns are live timers, so they tick
/// without widget refreshes.
struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry { UsageEntry(date: Date(), snapshot: .sample) }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(UsageEntry(date: Date(), snapshot: context.isPreview ? (SnapshotStore.load() ?? .sample) : SnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let snap = SnapshotStore.load()
        let now = Date()
        var entries = [UsageEntry(date: now, snapshot: snap)]
        // An extra entry right at each upcoming reset, so the widget drops to 0% on time.
        for r in Set((snap?.limits ?? []).compactMap(\.resetsAt)).sorted() where r > now && r < now.addingTimeInterval(6 * 3600) {
            entries.append(UsageEntry(date: r, snapshot: snap))
        }
        // And one when the reading turns 20 min old, so the "as of" line turns amber on time.
        if let f = snap?.fetchedAt, f.addingTimeInterval(20 * 60 + 5) > now { entries.append(UsageEntry(date: f.addingTimeInterval(20 * 60 + 5), snapshot: snap)) }
        entries.sort { $0.date < $1.date }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60))))
    }
}

struct SessionSmallView: View {
    let entry: UsageEntry

    var body: some View {
        let now = entry.date
        VStack(alignment: .leading, spacing: 4) {
            Text("Claude session").font(.caption).foregroundStyle(.secondary)
            if let s = entry.snapshot?.session {
                let pct = s.effectivePercent(at: now)
                Text("\(Int(pct))%")
                    .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(UsageStyle.color(for: pct))
                Bar(percent: pct, color: UsageStyle.color(for: pct))
                if let r = s.resetsAt, r > now {
                    HStack(spacing: 3) {
                        Text("resets in").foregroundStyle(.secondary)
                        Text(timerInterval: now...r, countsDown: true).monospacedDigit()
                    }
                    .font(.caption)
                } else {
                    Text("new session available").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let w = entry.snapshot?.weekly {
                    Text("Weekly \(Int(w.effectivePercent(at: now)))%").font(.caption2).foregroundStyle(.secondary)
                }
                AgeLine(snapshot: entry.snapshot, now: now)
            } else {
                NoData(snapshot: entry.snapshot)
            }
        }
    }
}

struct OverviewMediumView: View {
    let entry: UsageEntry

    var body: some View {
        let now = entry.date
        VStack(alignment: .leading, spacing: 6) {
            if let snap = entry.snapshot, !snap.limits.isEmpty {
                ForEach(snap.limits.prefix(3)) { l in
                    let pct = l.effectivePercent(at: now)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(l.label).font(.caption)
                            Spacer()
                            if l.group == "session", let r = l.resetsAt, r > now {
                                Text(timerInterval: now...r, countsDown: true).font(.caption2).monospacedDigit()
                                    .foregroundStyle(.secondary).frame(maxWidth: 70, alignment: .trailing)
                            }
                            Text("\(Int(pct))%").font(.caption.weight(.semibold)).monospacedDigit()
                                .foregroundStyle(UsageStyle.color(for: pct))
                        }
                        Bar(percent: pct, color: UsageStyle.color(for: pct))
                    }
                }
                if let ex = snap.extra {
                    HStack {
                        Text("Extra usage").font(.caption)
                        Spacer()
                        Text(String(format: "$%.2f / $%.2f", ex.used, ex.limit)).font(.caption2).foregroundStyle(.secondary)
                        Text("\(Int(ex.percent))%").font(.caption.weight(.semibold)).monospacedDigit()
                            .foregroundStyle(UsageStyle.color(for: ex.percent))
                    }
                }
                Spacer(minLength: 0)
                AgeLine(snapshot: snap, now: now)
            } else {
                NoData(snapshot: entry.snapshot)
            }
        }
    }
}

struct AgeLine: View {
    let snapshot: Snapshot?
    let now: Date
    var body: some View {
        if let s = snapshot, s.fetchedAt != .distantPast {
            let stale = s.staleReason(staleAfter: 20 * 60, now: now) != nil
            Text((stale ? "⚠︎ as of " : "as of ") + s.fetchedAt.formatted(date: .omitted, time: .shortened))
                .font(.caption2).foregroundStyle(stale ? UsageStyle.amber : .secondary)
        }
    }
}

struct NoData: View {
    let snapshot: Snapshot?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No reading yet").font(.callout)
            Text(snapshot?.error ?? "Open UsageBarApp from the menu bar.").font(.caption).foregroundStyle(.secondary)
        }
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
        .frame(height: 5)
    }
}

struct SessionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SessionWidget", provider: Provider()) { entry in
            SessionSmallView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Claude session")
        .description("Session % and time until it resets.")
        .supportedFamilies([.systemSmall])
    }
}

struct OverviewWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OverviewWidget", provider: Provider()) { entry in
            OverviewMediumView(entry: entry).containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Claude usage")
        .description("Session, weekly and extra usage.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct UsageWidgets: WidgetBundle {
    var body: some Widget {
        SessionWidget()
        OverviewWidget()
    }
}

extension Snapshot {
    static var sample: Snapshot {
        Snapshot(fetchedAt: Date(), limits: [
            UsageLimit(key: "session", label: "Session (5h)", group: "session", percent: 42, resetsAt: Date().addingTimeInterval(8000)),
            UsageLimit(key: "weekly_all", label: "Weekly · all models", group: "weekly", percent: 31, resetsAt: Date().addingTimeInterval(400000)),
        ], extra: nil, breakdown: [])
    }
}
