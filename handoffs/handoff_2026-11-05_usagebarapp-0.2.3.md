# HANDOFF: UsageBarApp native Mac app + iPhone widgets (saved 2026-11-05 19:30 ET)
Status: OPEN
Next move: Josh does the iPhone session-key steps (below); read the result's "From:" line and act on it

Native $0 macOS menu bar app + Mac widgets + iPhone (Scriptable) widgets for live Claude usage, built in Claude Code alongside the older SwiftBar tool **UsageBar** (`../UsageBar`, v1.5.0, still running, untouched, must stay that way). UsageBarApp is at **0.2.3**: installed in `~/Applications`, running, menu bar item visible, 21/21 core tests pass, everything committed. Remaining: iPhone test (waiting on Josh), wiring the already-written About/Privacy window + app icon, and a few minor pre-mortem items. Nothing deleted; no secrets on disk except Josh's own sessionKey once he pastes it into the iPhone Keychain.

## Where the files are
Project root: `~/Library/Mobile Documents/com~apple~CloudDocs/01_ClaudeCoWork/Workspace/03_Projects/UsageBarApp/` (git repo, branch main, author set repo-locally to Josh Hotz <josh@joshhotz.com>)
- PLAN.md                         decisions, rules, architecture, phases (progress note at top)
- README.md / CHANGELOG.md        usage, install, uninstall / release notes for every version (keep updating both)
- mac/project.yml                 XcodeGen spec (team KFT88Q5XQ9, manual signing "Apple Development", no provisioning profile, MARKETING_VERSION 0.2.0)
- mac/App/                        UsageBarApp.swift (MenuBarExtra + History window + Settings), UsageModel.swift (polling, log, backoff, Chrome fallback, publish), UsageClient.swift (Keychain read via /usr/bin/security, fetch, fetchViaChrome, hang-proof Shell.run), ChatTracker.swift, AlertManager.swift, MenuView.swift, HistoryView.swift (Swift Charts), SettingsView.swift (General/Alerts/Status line tabs), AboutView.swift (WRITTEN, NOT WIRED)
- mac/Widget/UsageWidget.swift    "Claude session" (small) + "Claude usage" (medium/large)
- mac/UsageCore/                  Swift package with all logic + Tests (Models, UsageParser incl. fastISO, ReadingsLog, History, Forecast, Alerts, ServiceStatus, ChatTracking, Statusline)
- iphone/UsageBarApp.js           = Scriptable "Claude Usage" (pasted sessionKey route, Mac fallback)
- iphone/login-test.js            = Scriptable "Claude Login Test" (OBSOLETE WebView test; can be deleted from Scriptable)
- scripts/install-mac.sh          build + safe in-place install (rsync), first-run import of UsageBar history
- scripts/uninstall-mac.sh        removes app, data, group container, defaults, DerivedData
- docs/market-research_2026-11-04.md   top 5 competitors, gaps, ideas
- handoffs/                       this file
Runtime data: `~/Library/Application Support/UsageBarApp/` (usage_log.csv, usage_daily.csv, chats.json, statusline.txt), `~/Library/Group Containers/KFT88Q5XQ9.com.joshhotz.usagebarapp/snapshot.json` (widgets), `~/Library/Mobile Documents/iCloud~dk~simonbs~Scriptable/Documents/` (Claude Usage.js, Claude Login Test.js, UsageBarApp/snapshot.json + login-test.log). Defaults domain: com.joshhotz.UsageBarApp.
Build output (not in iCloud): `~/Library/Developer/Xcode/DerivedData/UsageBarApp`, `.../UsageCore-spm`, `.../report-spm` (scratch report tool).
This session: Claude Code, https://claude.ai/code/session_01YWh6FhK47gDCgL52QqAAAT (Remote Control was turned on so Josh follows from his phone).
Older UsageBar handoffs: `../UsageBar/handoffs/handoff_2026-11-01_usagebar-v1.4.2.md` (UsageBar mechanics, API details, dead ends).

## Decisions and why (don't reopen)
- **$0, no App Store.** App Store needs the $99/yr developer program; Josh refuses paid routes. Competing App Store apps exist (they pay).
- **iPhone = Scriptable, not a native iOS app.** Free-signed iOS apps expire every 7 days. (Mac app signed without a provisioning profile has no 7-day expiry; cert valid to 2027-09-23.)
- **Build our own, don't fork** Claude Tracker / CodexBar (both MIT): core was already built; Josh's differentiators (per-chat estimates, unused %/idle history, by-product split, iPhone without Mac) aren't in them; CodexBar is huge (7.7k commits). Borrow ideas only, credited.
- **UsageBar (SwiftBar) runs alongside**, long-term comparison, "quality over speed". New app's alerts were meant to stay OFF until switch-over to avoid duplicates.
- **iPhone must update without the Mac** (Josh's choice). Route history:
  1. Scriptable WebView sign-in: FAILED. Google blocks "Sign in with Google" in embedded browsers ("There was an error logging you in"); email login email never arrived; WebView /api/organizations returned 403/needLogin (login-test.log). Also first hit "evaluateJavaScript returned unsupported type" (async IIFE returned a Promise; fixed by ending on a string).
  2. CURRENT: Josh pastes his claude.ai `sessionKey` cookie once; stored in iOS Keychain; plain Scriptable Request with `Cookie: sessionKey=…`, NO faked browser User-Agent. Same as hendrilee/claude-usage-widget (research agent). Unknown: whether Cloudflare blocks the iPhone request. If it does, the route is out (rule) and the widget uses the Mac reading.
- **Remote watching of Claude Code from the phone:** options given (Remote Control /remote-control, notification hooks, SSH+tmux, show Code activity in widget). Josh ran /remote-control. No hooks or settings changes made.

## Verified / done (0.2.3)
- Menu bar `S x% 2h14m · W y%` (+ `E x%` when spending extra usage), colored; dropdown with bars, reset times, pace ("At this pace: 100% at …" / "~37% at reset"), Planning (next session, usual start ~9 AM, weekly %/day, Anthropic by-product split), Top chats (est.) like UsageBar 1.4.2, outage banner, History/Settings/Quit.
- History window (5-h windows peak+unused, days idle/active, weekly trend, chats per week/window); imported UsageBar history from 2026-11-01 (7,798 rows). Real-data check: Nov 1 = 25 tracked h (DST), 2 windows avg 93%; weekly trend 44→69%.
- Alerts engine with editable thresholds per alert (session 80/95, weekly 75/90, extra 80/95/100, time-left 60/15 under 70%, new session, weekly reset 24 h, stale 30 min, incidents). Sound picker/preview/test.
- Claude Code status line text written every minute to statusline.txt; snippet in Settings > Status line (NOT installed into ~/.claude/settings.json; ask Josh first).
- Pre-mortem (independent agent) fixes done: 7× faster log load (2.2 s → 0.31 s for 30k rows, off main thread), staleness only after staleAfter, error backoff 2/4/8/15 min, 10 s wake delay, hang-proof Shell.run + 3-min fetch watchdog, Keychain read 120 s timeout, install script fails safely + in-place rsync, widget reload only on change + amber entry at 20 min, Chrome fallback when Claude Code token expired, chat pass ≤ every 5 min, iPhone refresh at reset.
- Bugs found by tests: Code session dedupe (copied messages keep original timestamps → order by transcript creation date); CRLF split; slow ISO parsing.
- Install-time freeze fixed: app copying from iCloud Drive on main thread at launch (likely TCC prompt) → import moved to install-mac.sh, iCloud writes off main thread.

## Open / next steps
1. **iPhone (Josh):** Mac Chrome claude.ai tab → ⌘⌥I → Application → Cookies → https://claude.ai → `sessionKey` → copy value. iPhone Scriptable → run **Claude Usage** → value pre-filled via Universal Clipboard → Save → read "From:" line.
   - "this iPhone ✓" → add widgets (Home small/medium, Lock Screen rectangular/circular, script = Claude Usage).
   - "the Mac" + "bot check blocked" → route out; keep Mac fallback; tell Josh plainly.
   - "expired or wrong" → recopy key. Never ask Josh to paste the key into chat.
2. **Settings mismatch:** live defaults show refreshMinutes=2 and alertsEnabled=1 (plan: 5 and off → duplicate alerts with UsageBar). Ask Josh if he set them; don't change silently.
3. **Chrome Automation permission:** chat tracking showed "Chrome didn't answer" (likely the "UsageBarApp wants to control Google Chrome" prompt). Confirm Josh clicked OK (System Settings > Privacy & Security > Automation). Check `chats.json` status.
4. **Wire the About window** (Josh asked; standard-app items explained): add `Window("About UsageBarApp", id: "about") { AboutView() }` in UsageBarApp.swift, an "About" button in MenuView footer + Settings > General; bundle ../CHANGELOG.md as a resource (project.yml `resources`/copy phase) for Release notes tab; generate an **AppIcon** asset (none exists; render PNGs 16–1024 via a Swift script into mac/App/Assets.xcassets/AppIcon.appiconset, set ASSETCATALOG_COMPILER_APPICON_NAME). Contact shown: josh@joshhotz.com (tell Josh he can change it). Bump to 0.3.0, CHANGELOG, install, commit.
5. **Offered, not answered:** small icon prefix in the new app's menu bar text to tell it apart from UsageBar; investigate Ice re-hiding (after in-place install it stayed visible).
6. **Remaining minor pre-mortem items:** Chrome page script uses synchronous XHR (can freeze the claude.ai tab; switch to async + window stash); notify() doesn't check notification permission; SMAppService errors swallowed; claude.ai org choice is first org with "chat"; long label vs notch; show "iPhone copy last written" in Settings.
7. **UsageBar (old) overnight login test:** `../UsageBar/data/refresh_test.log` does NOT exist and the refresh-test launch agent is gone; result unknown (a 9 AM trigger in old chat 825a09de… was to read it). UsageBarApp now covers expiry via the Chrome fallback.
8. Remove obsolete "Claude Login Test" from Scriptable when convenient.

## Rules (carry over)
- Never refresh or write the "Claude Code-credentials" Keychain item; read accessToken/expiresAt only; never read the refresh token.
- Never get past claude.ai's Cloudflare check (no UA spoofing, no cloudscraper/curl_cffi). If challenged, stop.
- Ask before installing anything; say so before deviating; don't ship untested work with confident framing; verify against claude.ai Settings > Usage.
- Tests must never touch real data files (UsageBar 1.2.1 incident: fake 2027 clock ran the real rollup; morning readings lost).
- Log every change in CHANGELOG.md, release-note style (memory: changelog-release-notes, usagebar-test-safety).
- UsageBar (SwiftBar) stays as is. Commit messages end with Co-Authored-By + Claude-Session lines.
- Josh dislikes avoidable hard stops: vet routes first (agents/research) before sending him to do manual steps; keep his steps minimal.

## Loose ends / privacy
- Scratch in `$TMPDIR` (/private/tmp/claude-501/…): report package, parse tests, backups usagebar.v1.2.0/v1.2.2/v1.3.1/v1.4.2.py, chattrack.v1.3.1.py. Disposable, nothing private. Deleting needs Josh's OK.
- chats.json holds claude.ai chat titles + Claude Code session titles/project paths (local only). iCloud Scriptable snapshot holds usage numbers only (no titles).
- sessionKey (once pasted) = full claude.ai account access; lives only in iPhone Keychain; signing out of claude.ai in Chrome revokes it.

## How to resume
New Claude Code session in `03_Projects/UsageBarApp` (or /resume-session and pick this file). Check: `git log --oneline | head -5`, CHANGELOG top entry, `pgrep -x UsageBarApp`, `cat ~/Library/Application\ Support/UsageBarApp/statusline.txt`, `python3 -c "import json;print(json.load(open('$HOME/Library/Application Support/UsageBarApp/chats.json'))['status'])"`, Scriptable `UsageBarApp/login-test.log`. Run tests: `cd mac/UsageCore && swift test --scratch-path ~/Library/Developer/Xcode/DerivedData/UsageCore-spm`. Build+install: `zsh scripts/install-mac.sh` (unsandboxed). Then ask Josh for the iPhone "From:" result and continue with step 2.
