import AppKit
import ServiceManagement
import SwiftUI
import UsageCore

@main
struct UsageBarAppMain: App {
    @StateObject private var model = UsageModel()

    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(model)
                .environmentObject(model.alerts)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)

        Window("Claude usage history", id: "history") {
            HistoryView()
                .environmentObject(model)
        }
        .defaultSize(width: 820, height: 760)

        Window("About UsageBarApp", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(model)
                .environmentObject(model.alerts)
        }
    }
}

/// Colored menu bar text ("S 64% 2h14m · W 33% · E 94%"). Menu bar text is normally drawn as a
/// monochrome template, so it's rendered to a non-template image to keep the exact colors.
struct MenuBarLabel: View {
    @ObservedObject var model: UsageModel

    var body: some View {
        Image(nsImage: render())
            .onAppear { model.start() }
    }

    private func render() -> NSImage {
        let now = model.now
        var parts: [(String, Double)] = []
        if let s = model.snapshot?.session {
            var t = "S \(Int(s.effectivePercent(at: now)))%"
            if let r = s.resetsAt, r > now, s.percent > 0 { t += " " + UsageStyle.shortCountdown(r.timeIntervalSince(now)) }
            parts.append((t, s.effectivePercent(at: now)))
        }
        if let w = model.snapshot?.weekly { parts.append(("W \(Int(w.effectivePercent(at: now)))%", w.effectivePercent(at: now))) }
        if let ex = model.snapshot?.extra, ex.used > 0 || ex.reached { parts.append(("E \(Int(ex.percent))%", ex.percent)) }
        let text = parts.isEmpty ? "Claude ?" : parts.map(\.0).joined(separator: " · ")
        let color: Color = (model.staleReason != nil || parts.isEmpty) ? UsageStyle.dim
            : UsageStyle.color(for: parts.map(\.1).max() ?? 0)
        // Optional icon in front, to tell this item apart from UsageBar (SwiftBar) while both run.
        let renderer = ImageRenderer(content:
            HStack(spacing: 3) {
                if model.menuBarIcon { Image(systemName: "gauge.with.dots.needle.67percent") }
                Text(text)
            }
            .font(.system(size: 13, weight: .medium).monospacedDigit()).foregroundStyle(color)
            .padding(.horizontal, 1))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let img = renderer.nsImage ?? NSImage()
        img.isTemplate = false
        return img
    }
}

/// Launch at login through the system's Login Items (user-controlled toggle, off by default).
enum LaunchAtLogin {
    static var isOn: Bool { SMAppService.mainApp.status == .enabled }
    /// Returns why it didn't work, if it didn't (shown in Settings instead of failing silently).
    static func set(_ on: Bool) -> String? {
        do {
            try on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        } catch {
            return error.localizedDescription
        }
        if on && SMAppService.mainApp.status == .requiresApproval {
            return "Allow UsageBarApp in System Settings > General > Login Items."
        }
        return nil
    }
}
