import AppKit
import SwiftUI

/// About window: identity, version, privacy policy, terms, acknowledgements and release notes.
struct AboutView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case about = "About", privacy = "Privacy", terms = "Terms", credits = "Acknowledgements", notes = "Release notes"
        var id: String { rawValue }
    }
    @State private var tab: Tab = .about

    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    static let contact = "josh@joshhotz.com"

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) { ForEach(Tab.allCases) { Text($0.rawValue).tag($0) } }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding([.horizontal, .top], 16)
            Divider().padding(.top, 12)
            switch tab {
            case .about: about
            case .privacy: DocText(AboutText.privacy)
            case .terms: DocText(AboutText.terms)
            case .credits: DocText(AboutText.credits)
            case .notes: DocText(AboutText.releaseNotes)
            }
        }
        .frame(width: 560, height: 520)
    }

    private var about: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 8)
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 96, height: 96)
            Text("UsageBarApp").font(.title.bold())
            Text("Version \(Self.version) (\(Self.build))").foregroundStyle(.secondary)
            Text("Live Claude usage in your menu bar, on your desktop and on your iPhone: session and weekly limits, extra usage, pace, history and estimated usage per chat.")
                .multilineTextAlignment(.center).frame(maxWidth: 420).padding(.top, 4)
            Text("An independent personal project. Not made by, endorsed by or affiliated with Anthropic. Claude is a trademark of Anthropic, PBC.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 420)
            HStack(spacing: 14) {
                Button("Privacy policy") { tab = .privacy }
                Button("Release notes") { tab = .notes }
                Button("Contact") { NSWorkspace.shared.open(URL(string: "mailto:\(Self.contact)?subject=UsageBarApp%20\(Self.version)")!) }
            }
            .padding(.top, 6)
            Spacer()
            Text("© 2026 Josh Hotz. All rights reserved.").font(.caption).foregroundStyle(.secondary)
                .padding(.bottom, 14)
        }
        .padding(.horizontal, 24)
    }
}

/// Scrollable, selectable document text with simple Markdown (headings and inline styles).
struct DocText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(text.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                    if line.hasPrefix("## ") {
                        Text(line.dropFirst(3)).font(.headline).padding(.top, 8)
                    } else if line.hasPrefix("# ") {
                        Text(line.dropFirst(2)).font(.title3.bold())
                    } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                        Spacer().frame(height: 2)
                    } else {
                        Text((try? AttributedString(markdown: line)) ?? AttributedString(line))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}

enum AboutText {
    static let privacy = """
    # Privacy policy
    Effective November 5, 2026 · UsageBarApp \(AboutView.version)

    **In short:** UsageBarApp has no servers, accounts, analytics, ads or tracking. It talks only to Anthropic (for your usage numbers) and to Anthropic's public status page. Everything it keeps stays on your Mac, plus one optional copy in your own iCloud for your iPhone.

    ## What it reads
    • **Your Claude Code login** (Keychain item "Claude Code-credentials"). It reads only the access token and its expiry date. The token is sent only to Anthropic, to ask for your usage. It is never saved by UsageBarApp, never refreshed, and the Keychain item is never changed.
    • **Your usage numbers** from api.anthropic.com: session, weekly and per-model limits, reset times, extra usage spending and Anthropic's split by product.
    • **claude.ai chats, if chat tracking is on.** A small script runs inside your open claude.ai tab in Chrome. It reads your recent chats there and returns only titles, message times and token estimates. Message text never leaves the page. It never opens, focuses or changes anything in Chrome.
    • **Claude Code sessions** in ~/.claude/projects. It reads only token counts, times, session titles and project folder paths.
    • **Claude's public status** from status.anthropic.com (no personal data).

    ## Where data goes
    • To Anthropic: the usage request (with your Claude Code token), and the chat requests made by your own browser tab.
    • To your iCloud, only if the Scriptable app is set up: a copy of the latest usage numbers (no chat titles) in Scriptable's iCloud folder, so your iPhone widgets can show it. Apple's iCloud terms apply.
    • Nowhere else. Nothing is sent to the developer or to any third party.

    ## What's stored, and for how long
    All of this is in ~/Library/Application Support/UsageBarApp and the app's shared container on your Mac:
    • Usage readings: 30 days in detail, then one summary per day.
    • Chat tracking: titles, times and token estimates for 8 days.
    • The latest reading, for the widgets and the status line.
    • Your settings.

    ## Permissions it may ask for
    • **Notifications:** only if you turn alerts on.
    • **Control Google Chrome (Automation):** only for chat tracking. You can turn it off in Settings > General or in System Settings > Privacy & Security > Automation.
    • **Open at login:** only if you turn it on.

    ## Deleting your data
    Run scripts/uninstall-mac.sh, or quit the app and delete ~/Library/Application Support/UsageBarApp and ~/Library/Group Containers/KFT88Q5XQ9.com.joshhotz.usagebarapp. Your Claude account and Claude Code are not affected.

    ## Children
    UsageBarApp is not directed at children and collects nothing from anyone.

    ## Changes
    Changes to this policy are listed in the release notes, with a new effective date.

    ## Contact
    \(AboutView.contact)
    """

    static let terms = """
    # Terms of use
    UsageBarApp is a personal project, provided free and "as is", without warranty of any kind. You use it at your own risk.

    ## Accuracy
    UsageBarApp shows numbers from Anthropic endpoints that are not publicly documented and can change without notice. Figures marked "est." (per-chat shares, token estimates, pace) are estimates. For your actual limits, claude.ai Settings > Usage is authoritative.

    ## Your Anthropic account
    Your use of Claude remains subject to Anthropic's own terms. UsageBarApp only reads your usage; it doesn't use your allowance or change anything in your account.

    ## Trademarks
    Claude and Anthropic are trademarks of Anthropic, PBC. UsageBarApp is not affiliated with or endorsed by Anthropic.

    ## License
    © 2026 Josh Hotz. All rights reserved. For personal use.
    """

    static let credits = """
    # Acknowledgements
    ## Built with
    • Swift, SwiftUI, Swift Charts and WidgetKit (Apple).
    • **XcodeGen** (MIT License, © Yonas Kolb) generates the Xcode project. It's a build tool and isn't part of the app.

    ## Inspiration
    Ideas such as a pace forecast and a status line were inspired by open-source Claude usage trackers, including **Claude Tracker** and **CodexBar** (both MIT). No code from them is included.

    ## Data
    Usage data comes from Anthropic. Service status comes from status.anthropic.com.
    """

    static var releaseNotes: String {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let s = try? String(contentsOf: url, encoding: .utf8) else { return "# Release notes\nNot included in this build." }
        return s.replacingOccurrences(of: "# Changelog", with: "# Release notes")
    }
}
