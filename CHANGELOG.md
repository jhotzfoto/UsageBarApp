# Changelog

All changes to UsageBarApp, newest first, release-note style. Every change gets an entry.

## 0.5.0 — 2026-11-05 (UsageBarApp replaces UsageBar)
**New**
- **Stays visible in the menu bar.** The app backs up where you put its menu bar item and, at every
  launch and after updates, puts back a lost position and turns the item back on if it was removed,
  so a menu bar manager such as Ice is less likely to tuck it into its hidden section.

**Changed**
- **The old UsageBar (SwiftBar) is retired** and uninstalled, together with SwiftBar, which only ran
  it. This app is now the only Claude usage item, so alerts are on by default again.
- Removed the "Claude Login Test" iPhone script (the in-app sign-in experiment). Replacing the session
  key lives in Claude Usage: run it and tap Change session key.

## 0.4.0 — 2026-11-05
**New**
- **iPhone session key tracker.** The iPhone script now records when you saved the key, when it last
  worked and when it first stopped working (times only, never the key), on every run and widget
  refresh. Settings > iPhone session key shows how long each key has lasted, plus the expiry date
  claude.ai gives, when it sends one. Over time this tells you how long a claude.ai sign-in really lasts.
- **"iPhone session key stopped working" notification** on the Mac, once per key, with how long it
  lasted. Its own switch, on by default, and it works even while the other alerts are off.

**Changed**
- Update the iPhone script (Scriptable > Claude Usage) to this version to start tracking.

## 0.3.0 — 2026-11-05
**New**
- **About window** (menu > About, or Settings > General): version, privacy policy, terms,
  acknowledgements and these release notes.
- **App icon**: a gauge on a terracotta tile, in Finder, Settings and the About window.
- **Optional menu bar icon** (Settings > General > Show icon in the menu bar), to tell this item
  apart from UsageBar while both run. Off by default.
- **iPhone copy status** in Settings: when the copy your iPhone widget falls back to was last written.

**Changed**
- **claude.ai tab no longer freezes during chat tracking.** The page script used to wait on each
  request (synchronous XHR), which could lock the tab for a few seconds. It now runs in the background
  and the app checks back for the answer.
- The Chrome fallback for usage uses the same claude.ai organization that chat tracking found, instead
  of picking the first one.

**Fixed**
- Alerts now check notification permission first. If notifications are off, Settings > Alerts says
  so instead of alerts silently going nowhere.
- "Open at login" shows why it didn't work (or asks you to approve it in Login Items) instead of
  quietly switching back off.

## 0.2.3 — 2026-11-05 (fixes from an independent pre-mortem review)
**Fixed**
- **Freezes as history grows.** Loading 30,000 log rows took 2.2 s on the main thread. A faster date
  parser and CSV fast path brought it to 0.31 s, and loading now runs off the main thread. New readings are
  added in memory instead of re-reading the file.
- **False "not updating" alerts.** One failed fetch (e.g. right after wake) no longer counts as stale; only
  a reading older than the stale limit does. After wake the app waits 10 s before fetching.
- **Hammering the API while failing.** Repeated errors now back off 2 → 4 → 8 → 15 min instead of
  retrying every minute.
- **Possible permanent hang.** Child processes (Keychain read, osascript) can no longer block forever,
  and a fetch stuck for over 3 min no longer blocks the next one. The Keychain read waits up to 2 min, so
  you have time to click Always Allow if macOS ever asks.
- **Install script could reinstall the old build** when a build failed. It now deletes the old product
  first and checks the build result.
- **Menu bar item moving after updates.** The app is now updated in place, keeping the same path and
  bundle. Checked after this update: the item stayed visible.
- **Mac widgets:** reloaded only when what they show changes (to save their refresh budget), and they turn
  amber on time when the reading is 20 min old.
- **iPhone widget:** refreshes right after the session resets, so 0% shows on time.

**New**
- When the Claude Code login has expired (e.g. overnight), usage is read through the open claude.ai tab in
  Chrome instead, so the menu bar doesn't go grey until you use Claude Code.
- Chat tracking reads Chrome at most every 5 minutes, whatever the check interval.

**Verified**
- 21/21 tests, including new ones for staleness, date and CSV parsing, and 30k-row load speed. Two of
  them found real bugs (CRLF line endings; the 2.2 s load).
- Live after the update: fetching, logging, status line written, memory 68 MB (was 97 MB), menu bar item
  visible.

## 0.2.2 — 2026-11-05
**Changed**
- iPhone `Claude Usage` no longer signs in through Scriptable's built-in browser. Google blocks it, and the
  email login never arrived. You now paste your claude.ai session key once; it's stored in the iOS
  Keychain and sent only to claude.ai in a plain request (no faked browser identity). If claude.ai's bot
  check blocks the request, the widget says so and shows the Mac's reading. Route chosen after a research
  agent reviewed existing Scriptable widgets that work the same way.

## 0.2.1 — 2026-11-05
**Fixed**
- iPhone scripts failed with "JavaScript execution returned a result of an unsupported type". The page
  script's last value was a Promise; it now ends on a plain string, and the result still arrives through
  `completion()`. Found in the first test on the phone.
- "Sign in with Google" fails in Scriptable's built-in browser (Google blocks embedded browsers). Both
  scripts now offer email sign-in, with a "Paste login link" option that opens the emailed link inside
  Scriptable. Only claude.ai links are accepted.

## 0.2.0 — 2026-11-05
**New**
- **History window** (dropdown > History), with Swift Charts:
  - 5-hour windows: peak and unused at reset
  - days: idle vs active hours, windows used, average peak, weekly % at end of day
  - weekly windows: trend chart and table
  - estimated top chats this week, and a breakdown by chat for each window
  - 7 / 14 / 30 day range
- **Pace forecast** under Session and Weekly: "At this pace: 100% at 9:40 PM" (amber) or "~37% at reset
  (62% unused)". Uses the last 60 min (session) or 24 h (weekly), else the average since the window
  started.
- **Planning**: when the next session can start, your usual start hour (from the last 14 days), weekly %
  left per remaining day, and Anthropic's split by product.
- **Per-chat tracking** (port of UsageBar 1.4.2): claude.ai via the open Chrome tab, Claude Code
  transcripts, "Chats: X% tracked vs Y% logged · token estimate: W%" (amber when more than 5 points
  off), top chats (1–25, default 5), top-N total, others, unattributed.
- **Claude outage alerts and banner** from status.anthropic.com (checked every 5 min), once per incident.
- **Editable alerts** (Settings > Alerts): toggle and thresholds for each alert, plus session time left
  60/15 min while under 70% and weekly reset within 24 h (both from UsageBar), restore defaults.
- **Claude Code status line**: the app writes `statusline.txt` every minute; Settings > Status line shows
  the snippet for `~/.claude/settings.json`.
- **Readings log** with 30-day rollup (UsageBar's CSV format). The first install imports UsageBar's history
  (read only), so history starts 2026-11-01.

**Changed**
- Logic moved into a tested Swift package, `mac/UsageCore` (18 tests, run on temporary data only).
- Claude Code sessions that continue another session are ordered by transcript creation time, so copied
  messages count once, for the original session. Found by a test: copied messages keep their original
  timestamps.

**Fixed (found during install)**
- The app froze at first launch while copying UsageBar's history from iCloud Drive on the main thread
  (most likely waiting on macOS's iCloud Drive privacy prompt). The import now runs in `install-mac.sh`,
  and the iPhone copy is written off the main thread.

**Verified**
- `swift test`: 18/18 passed. Release build with no warnings.
- Live: readings logged (7,798 rows including the import), status line written ("S 13% 2h46m · W 69%"),
  2 Claude Code sessions read.
- History on real data:
  - Nov 1 has 25 tracked hours (clocks went back) and 2 windows averaging 93%
  - weekly trend 44 → 69%
  - session pace ~37% at reset; weekly 31% left, ~12%/day
- Not yet verified:
  - claude.ai chat tracking, waiting for you to allow "control Google Chrome"
  - the History window and dropdown layout, by eye
  - iPhone

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
