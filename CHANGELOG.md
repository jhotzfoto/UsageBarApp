# Changelog

All changes to UsageBarApp, newest first, release-note style. Every change gets an entry.

## 0.1.0 — 2026-11-04
**New: Mac app** (`mac/`, SwiftUI, built with XcodeGen, signed with the free personal team)
- Menu bar text with exact colors (rendered as an image), stale state in grey.
- Dropdown: every limit with bar, reset time and countdown; extra usage budget; Anthropic's weekly split
  by product (`seven_day_breakdown`); Refresh, claude.ai link, Settings, Quit.
- Fetching: Claude Code login read-only via `/usr/bin/security`; every 5 min (2–60 in Settings), on
  menu open after 30 s, and on wake. 429 backoff. One-minute tick for countdowns and alerts.
- Alerts with the same rules as UsageBar plus extra usage 80/95/100%. Off by default; sound picker,
  preview, test notification.
- Open at login toggle (off by default).
- Shares each reading with the widgets (App Group) and the iPhone (Scriptable's iCloud folder, once it
  exists).

**New: Mac widgets**
- "Claude session" (small) and "Claude usage" (medium/large). Live countdowns; an extra timeline entry
  at each reset.

**New: iPhone**
- `iphone/UsageBarApp.js`: Home Screen (small, medium) and Lock Screen (circular, rectangular, inline)
  widgets.
- Uses the phone's own claude.ai login first, then the Mac reading, and shows the source and age.
- Not tested on a phone yet.

**New: scripts**
- `scripts/install-mac.sh`, `scripts/uninstall-mac.sh`.

**Verified**
- Clean Release build with no warnings. Parser checked against live data: session 12%, weekly 65%,
  Fable 28%, breakdown Cowork 79 / Chats 18 / Claude Code 2 / Other 1, matching UsageBar's reading of the
  same minute.
- The installed app fetched live with no Keychain prompt and wrote the snapshot. macOS registered the
  widget extension.
- Ice placed the new menu bar item in its hidden section.

## 0.0.2 — 2026-11-04
**New**
- `docs/market-research_2026-11-04.md`: top 5 competing apps, how UsageBar differs, feature ideas.

## 0.0.1 — 2026-11-04
**New**
- Project folder, git history, `PLAN.md` with the agreed decisions, architecture and phases.
- `iphone/login-test.js`: phase 0 test of whether Scriptable can read Claude usage through its own
  claude.ai login, in the app and from a widget.
