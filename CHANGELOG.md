# Changelog

All changes to UsageBarApp, newest first, release-note style. Every change gets an entry.

## Project housekeeping — 2026-11-26 (git out of iCloud sync)
**Fixed**
- **Git no longer shows every file as "deleted" after a commit.** It happened twice (Nov 17 and Nov 26):
  iCloud seems to undo git's last rename of its file list, leaving only the temporary copy. Git's folder
  is now `.git.nosync` (iCloud skips anything ending in `.nosync`), with a one-line `.git` file pointing
  to it. Same fix applied to PingPlace. Nothing about the app changes, and GitHub stays the backup.
- Moved a stray Finder file (`.DS_Store`) out of git's refs folder; `git fsck` is now clean.
- **Phone-script tests no longer fail depending on the time of day.** Three History widget checks (G, H, I)
  passed only within 30 minutes of the saved test data; after that the widget rightly adds ⚠︎ and the
  checks didn't expect it. The tests now give the script a fake clock pinned 2 minutes after the saved
  phone reading, and a new check (J) confirms the ⚠︎ appears when the same data is 45 minutes old.
  14 widget checks and 7 accuracy checks pass. The widget itself is unchanged.

## iPhone Claude History widget — 2026-11-26 (right now comes from the phone)
**Added**
- **The History widget now uses the phone's own live reading for "right now".** On the phone, the
  first fix showed the Mac's history was 34 minutes old: the Mac uploads every 10 minutes, but iCloud
  was slow to bring those updates down to the phone. The Claude Usage script already reads claude.ai
  itself and saves that reading on the phone, so the History widget now uses it when it's newer than
  the Mac's history. Today's line and dot, the day's total and the 7-day total are brought up to that
  reading, counting the same way the Mac does. The header says "Phone · 4m ago" when that happens.
- Checked against real data: with the Mac's history cut off 5 to 60 minutes early, the phone reading
  brought today's total back to exactly the Mac's real number. If a session reset in between, only the
  new session can be counted (2 to 3% short in the test) until the Mac's update arrives.
- Only works while the Claude Usage script can read claude.ai on the phone. Otherwise it shows the
  Mac's history as before. Just after midnight it keeps showing yesterday until the Mac's new day arrives.

## iPhone Claude History widget — 2026-11-25 (no more blank widget, clearer numbers)
**Fixed**
- **The widget no longer sits blank or says "no info" until you tap it.** In the background iOS gives a
  widget only a few seconds, and iCloud often hadn't handed over the Mac's newest file in time, so the
  widget had nothing to show. It now keeps its own copy of the last good history on the phone and shows
  that when iCloud is slow. It gives up waiting on iCloud after 5 seconds instead of hanging. The age text
  ("Mac · 14m ago") gets a ⚠︎ when what it shows is over 30 minutes old.
- **Asks iOS to refresh every 10 minutes** (was 30), to match how often the Mac shares. iOS still decides
  the real timing and often waits longer.

**Changed**
- **"144%" is now "1.4 sessions used".** The number was always right: it adds up how much of each 5-hour
  session you used today, so it passes 100% once you've used more than one session's worth. Shown as
  sessions it reads plainly. "Unused at reset" is in sessions too. The live session line in the chart
  stays in % (0 to 100% of the current session).
- The Mac app is unchanged (still 0.11.1). The updated script was copied into Scriptable's iCloud folder,
  so the phone picks it up on its own.

## Tests only — 2026-11-16 (no more test crash reports)
**Fixed**
- **The tests no longer crash when they can't write their temp folder** (as happens inside Claude
  Code's sandbox). On 2026-11-15 a sandboxed run crashed the test runner and left a macOS crash report
  for `xctest`. Now every test fails with a plain message saying the temp folder can't be written and to
  run the tests outside the sandbox. The app itself is unchanged (still 0.11.1); nothing to reinstall.

## 0.11.1 — 2026-11-15 (quieter, better-timed login renewal)
**Changed**
- **The app now renews Claude Code's login only in its last few minutes (or once it has run out),
  instead of 30 minutes early.** Tonight's first real run showed Claude Code ignores renewal requests
  until about 5 minutes are left: the tries at 29 and 17 minutes left did nothing and were logged as
  "failed"; the one at under 5 minutes renewed it (good for another 8 hours). Asking at the right time
  means no wasted runs and no misleading "failed" lines in the renewal log. If a check misses that short
  window, the app renews right before its next reading, so the menu bar still doesn't go stale.

## 0.11.0 — 2026-11-15 (no more "Claude Code login expired")
**Fixed**
- **The menu bar no longer goes stale when Claude Code's login runs out.** That login lasts a few hours
  and only renewed when you ran Claude Code in Terminal (the Code tab in the Claude app keeps its own login,
  so using it never helped). Now, when the login has under 30 minutes left, the app runs Claude Code's own
  `/usage` command (`claude -p /usage`) in the background and Claude Code renews itself. No model
  request, no usage cost, at most once every 10 minutes. The app still never touches the login itself.
- **"Login refused" errors now heal themselves too:** the app renews and retries once before giving up.
- **Chrome backup:** if Chrome doesn't answer, the error says so plainly instead of claiming the login expired.

**New**
- **One-click Sign in**, shown only if Claude Code was fully signed out (password change, "log out of all
  devices"), plus one notification. Opens Terminal on `claude auth login`.
- **Renewal log** at `~/Library/Application Support/UsageBarApp/login_renewals.log`: when, why, and the
  result of each renewal (times only, no secrets), so it's easy to check it's working.

## 0.10.0 — 2026-11-06
**New**
- **Models by day** in History: tokens per model each day (a line per model, or stacked bars), a row
  per day with a coloured split ("Opus 5.5 82% · Sonnet 4.5 18%") and total tokens, and the official
  numbers Anthropic tracks: how much of the all-models and per-model (Fable) weekly limits you used
  that day. Hover for each model's tokens and share.
- Claude Code: the exact model of every reply is now recorded (past 8 days filled in once from your
  transcripts). claude.ai chats: each chat's model is recorded from now on; older chat use shows as
  "Unknown".
- A small long-term summary (model_daily.csv: date, model, source, tokens) keeps this beyond the chat
  tracker's 8 days.

## 0.9.0 — 2026-11-06
**New**
- **History opens right from the menu bar.** Clicking History turns the dropdown into a large History
  panel under the menu bar, no separate window. **Back** returns to the usual menu; **Open in
  window** keeps it open as its own window. Clicking anywhere else closes it, and the menu opens on
  the usual summary next time.

## 0.8.1 — 2026-11-06
**New**
- **Hover over any History chart for details.** A guide line follows the pointer with a small card:
  - Your day: the time, session %, whether a session was running (or idle, or not recorded), usage
    in that half hour and when the session resets.
  - 5-hour sessions: when the nearest session ran, its peak and how much was left unused.
  - Days: hours with a session running, idle hours, sessions and average peak for that day.
  - Weekly limit: the weekly % at that point and which week it belongs to.

## 0.8.0 — 2026-11-06 (History redesign)
**New**
- **Redesigned History window.** Four summary tiles at the top answer "how am I doing?" first: weekly
  limit used, average session peak, capacity left unused per session, and idle hours per day. Below,
  each chart sits in its own card with a plain-English title and a one-line "what to look for".
- **Line charts everywhere**, with one switch (top right) to turn every chart back into bars. Your
  choice is remembered.
- **Days as a visual list**: each day gets a 24-hour strip (blue = usage, green = session running,
  amber = idle, grey = not recorded) next to sessions, an average-peak bar, idle hours and weekly %.
- One colour language throughout: blue = your usage, green = session running, amber = missed
  capacity, grey = not recorded.
- **iPhone Claude History widget uses lines too**; type `bars` in the widget's Parameter field to
  switch back.

**Changed**
- Top chats leaves out "no tracked activity" (now a footnote) and shows a bar per chat.
- Chats by session shows the latest 8, with "Show all".

## 0.7.2 — 2026-11-06
**Changed**
- **Day timeline is now a line graph** of your session % through the day: it climbs as you use
  Claude and drops to 0 at each reset, with today's current % marked. The shading behind it (session
  running, idle, not recorded) and the reset labels stay. The line breaks where the Mac wasn't
  recording instead of drawing across the gap. The 30 min / 1 hour switch is gone (no longer needed).

## 0.7.1 — 2026-11-06
**New**
- **Pick any day in the Day timeline.** Click the date in History > Day timeline to open a calendar
  (from the first tracked day to today). A **Today** button jumps back. The arrows still step day by day.

## 0.7.0 — 2026-11-06
**New**
- **Claude History widget for iPhone**, separate from Claude Usage (Scriptable > Claude History).
  Large: today in half-hour slots (session % used, session running, idle = missed capacity, not
  recorded, resets and now) plus the last 7 days (used and idle hours) with a 7-day total. Medium:
  today's timeline. Small: today's numbers with a mini timeline. Lock Screen: a one-line summary.
- The Mac shares that history with the iPhone every 10 minutes (UsageBarApp/history.json in
  Scriptable's iCloud folder: usage numbers and times only, no chat titles).

## 0.6.0 — 2026-11-06
**New**
- **Day timeline** at the top of History: one day in 30-minute (or 1-hour) slots, with arrows to step
  back through earlier days. Bars show how much session % you used in each slot. The background shows
  when a 5-hour session was running, when none was (idle: capacity you could have used, in amber) and
  when the Mac wasn't recording. Each reset is marked with how much was left unused, plus a line
  summing up the day: used, unused at resets, idle hours and how many more sessions would have fit.

**Changed**
- Missed capacity is amber throughout History: unused-at-reset in the 5-hour chart and idle hours in
  the days chart, each with a legend.

## 0.5.1 — 2026-11-06
**Changed**
- In the menu, **Top chats** now comes right after your limits and **Planning** moves to the bottom.

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
