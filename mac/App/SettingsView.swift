import SwiftUI
import UsageCore

struct SettingsView: View {
    @EnvironmentObject var model: UsageModel
    @EnvironmentObject var alerts: AlertManager
    @State private var launchAtLogin = LaunchAtLogin.isOn

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            alertsTab.tabItem { Label("Alerts", systemImage: "bell") }
            statusLine.tabItem { Label("Status line", systemImage: "terminal") }
        }
        .frame(width: 520)
        .padding(.vertical, 8)
    }

    private var general: some View {
        Form {
            Section("Updates") {
                Picker("Check usage every", selection: $model.refreshMinutes) {
                    ForEach(UsageModel.refreshChoices, id: \.self) { Text("\($0) min").tag($0) }
                }
                Text("Countdowns, pace and alerts update every minute without calling the API.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Chat tracking (estimated)") {
                Toggle("Read claude.ai chats from Chrome", isOn: $model.chromeTracking)
                Text("Uses your open claude.ai tab in Chrome (titles, message times and token estimates only; message text never leaves the page). Claude Code sessions are always read from ~/.claude/projects.")
                    .font(.caption).foregroundStyle(.secondary)
                Stepper("Top chats shown: \(model.topChats)", value: $model.topChats, in: 1...25)
            }
            Section("General") {
                Toggle("Open at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in LaunchAtLogin.set(on); launchAtLogin = LaunchAtLogin.isOn }
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var alertsTab: some View {
        Form {
            Section {
                Toggle("Send alerts", isOn: $alerts.enabled)
                Text("Off while UsageBar (SwiftBar) is still running, so you don't get every alert twice. Alerts are still tracked while off, so turning them on doesn't replay old ones.")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Sound", selection: $alerts.sound) { ForEach(AlertManager.sounds, id: \.self) { Text($0).tag($0) } }
                HStack {
                    Button("Send test notification") { alerts.sendTest() }
                    Button("Preview sound") { alerts.previewSound() }
                }
                if alerts.permissionDenied {
                    Text("Notifications are off for UsageBarApp in System Settings > Notifications.").font(.caption).foregroundStyle(UsageStyle.amber)
                }
            }
            Section("Which alerts (each fires once per window; highest crossed threshold only)") {
                ThresholdRow(title: "Session used (%)", on: $alerts.config.sessionOn, values: $alerts.config.sessionThresholds)
                ThresholdRow(title: "Weekly limits used (%)", on: $alerts.config.weeklyOn, values: $alerts.config.weeklyThresholds)
                ThresholdRow(title: "Extra usage budget (%)", on: $alerts.config.extraOn, values: $alerts.config.extraThresholds)
                ThresholdRow(title: "Session time left (min)", on: $alerts.config.timeLeftOn, values: $alerts.config.timeLeftMinutes, max: 300)
                Stepper("…only while session is under \(Int(alerts.config.timeLeftOnlyBelow))%", value: $alerts.config.timeLeftOnlyBelow, in: 10...100, step: 5)
                    .disabled(!alerts.config.timeLeftOn)
                Toggle("New session available", isOn: $alerts.config.newSessionOn)
                HStack {
                    Toggle("Weekly reset soon", isOn: $alerts.config.weeklyResetSoonOn)
                    Spacer()
                    Stepper("\(Int(alerts.config.weeklyResetSoonHours)) h before", value: $alerts.config.weeklyResetSoonHours, in: 1...72)
                        .disabled(!alerts.config.weeklyResetSoonOn)
                }
                HStack {
                    Toggle("Not updating", isOn: $alerts.config.staleOn)
                    Spacer()
                    Stepper("for \(Int(alerts.config.staleMinutes)) min", value: $alerts.config.staleMinutes, in: 10...240, step: 5)
                        .disabled(!alerts.config.staleOn)
                }
                Toggle("Claude incidents (status.anthropic.com)", isOn: $alerts.config.outageOn)
                Button("Restore defaults") { alerts.config = AlertConfig() }
            }
        }
        .formStyle(.grouped)
    }

    private var statusLine: some View {
        Form {
            Section("Claude Code status line") {
                Text("Shows session %, countdown, weekly % and pace at the bottom of Claude Code. UsageBarApp writes the text once a minute; the status line just prints it, so it adds no API calls.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Current text:").font(.caption)
                Text(Statusline.text(model.snapshot, sessionPace: model.sessionPace, staleAfter: model.staleAfter, now: model.now, color: false))
                    .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                Text("Add this to ~/.claude/settings.json:").font(.caption)
                Text(StatuslineSetup.snippet).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                HStack {
                    Button("Copy snippet") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(StatuslineSetup.snippet, forType: .string)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

enum StatuslineSetup {
    static var snippet: String {
        #"""
        "statusLine": {
          "type": "command",
          "command": "cat \"$HOME/Library/Application Support/UsageBarApp/statusline.txt\" 2>/dev/null"
        }
        """#
    }
}

/// Toggle + editable comma-separated thresholds ("80, 95"); invalid input keeps the last valid list.
struct ThresholdRow: View {
    let title: String
    @Binding var on: Bool
    @Binding var values: [Double]
    var max: Double = 100
    @State private var text = ""

    var body: some View {
        HStack {
            Toggle(title, isOn: $on)
            Spacer()
            TextField("", text: $text)
                .frame(width: 110)
                .multilineTextAlignment(.trailing)
                .disabled(!on)
                .onSubmit(commit)
                .onChange(of: text) { _, _ in if AlertConfig.parseList(text, max: max) != nil { commit() } }
        }
        .onAppear { text = AlertConfig.listText(values) }
    }

    private func commit() {
        if let v = AlertConfig.parseList(text, max: max) { values = v } else { text = AlertConfig.listText(values) }
    }
}
