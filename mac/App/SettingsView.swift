import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: UsageModel
    @EnvironmentObject var alerts: AlertManager
    @State private var launchAtLogin = LaunchAtLogin.isOn

    var body: some View {
        Form {
            Section("Updates") {
                Picker("Check usage every", selection: $model.refreshMinutes) {
                    ForEach(UsageModel.refreshChoices, id: \.self) { Text("\($0) min").tag($0) }
                }
                Text("Countdowns update every minute without calling the API.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Alerts") {
                Toggle("Send alerts", isOn: $alerts.enabled)
                Text("Off while UsageBar (SwiftBar) is still running, so you don't get every alert twice.")
                    .font(.caption).foregroundStyle(.secondary)
                Picker("Sound", selection: $alerts.sound) {
                    ForEach(AlertManager.sounds, id: \.self) { Text($0).tag($0) }
                }
                HStack {
                    Button("Send test notification") { alerts.sendTest() }
                    Button("Preview sound") {
                        if alerts.sound != "Default" && alerts.sound != "None" { NSSound(named: NSSound.Name(alerts.sound))?.play() }
                        else if alerts.sound == "Default" { NSSound.beep() }
                    }
                }
                if alerts.permissionDenied {
                    Text("Notifications are turned off for UsageBarApp in System Settings > Notifications.")
                        .font(.caption).foregroundStyle(UsageStyle.amber)
                }
                Text("Session 80/95% · weekly 75/90% · extra usage 80/95/100% · new session available · not updating for 30 min.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("General") {
                Toggle("Open at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in LaunchAtLogin.set(on); launchAtLogin = LaunchAtLogin.isOn }
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .padding(.vertical, 8)
    }
}
