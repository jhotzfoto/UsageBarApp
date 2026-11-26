# UsageBarApp

Native Mac menu bar app + Mac widgets + iPhone (Scriptable) widgets for live Claude usage.
Personal, $0, built alongside UsageBar (`../UsageBar`), which stays as it is. See `PLAN.md`.

**Status (0.2.0, 2026-11-05)**
- **Mac:** feature-complete and tested (18 unit tests plus a live check).
- **iPhone scripts:** written but not tested yet.

## Mac app
Menu bar: `S 12% 2h25m · W 65%` (plus `E x%` once extra usage is being spent), colored green under 70,
amber 70–89, red 90+, grey when stale.

The dropdown shows:
- every limit with %, bar, reset time and countdown
- extra usage budget ($ used of limit)
- pace under Session and Weekly ("At this pace: 100% at 9:40 PM" / "~37% at reset (62% unused)")
- **Planning**: next session, your usual start hour, weekly % per remaining day, and Anthropic's split
  by product
- **Top chats this session (est.)**, as in UsageBar 1.4.2: tracked vs logged vs token estimate, top 5,
  total, others, unattributed
- a Claude incident banner when status.anthropic.com reports one
- last updated, Refresh, **History** (opens as a panel in the dropdown; "Open in window" for a
  separate window), claude.ai usage page, **About**, Settings…, Quit

**History window:** summary tiles (weekly limit, average session peak, left unused, idle per day), then
cards: your day (session % line with session/idle/not-recorded shading, any day via the calendar),
5-hour sessions (peak and unused), days (running vs idle hours plus an hour-by-hour strip per day),
weekly limit, and estimated top chats. One switch at the top turns every chart into lines or bars.
History starts 2026-11-01 (imported from UsageBar).

**Chat tracking:**
- Reads your open claude.ai tab in Chrome: titles, message times and token estimates only.
- The first time, macOS asks to let UsageBarApp control Chrome. Click **OK**, or turn it on later in
  System Settings > Privacy & Security > Automation.
- Chrome needs View > Developer > Allow JavaScript from Apple Events (already on).
- You can turn it off in Settings > General.

**Claude Code status line:**
- Settings > Status line > Copy snippet, then paste it into `~/.claude/settings.json`.
- It prints `S 13% 2h46m · W 69%` (plus pace when you're on track to hit 100%), updated every minute.

**How it works**
- Reads Claude Code's login from the Keychain item "Claude Code-credentials" via `/usr/bin/security`.
- Keeps that login alive by itself: shortly before it runs out, it runs Claude Code's own `/usage`
  command (`claude -p /usage`), which makes Claude Code renew its own login. Each renewal is listed in
  `~/Library/Application Support/UsageBarApp/login_renewals.log` (times only, no secrets).
  It reads the access token and expiry only, and never writes or refreshes the item.
- Calls `api.anthropic.com/api/oauth/usage` every 5 min (Settings: 2–60), and when you open the menu
  if the reading is over 30 s old. Backs off on HTTP 429. Countdowns tick every minute without API calls.
- **Settings:**
  - check interval, chat tracking, number of top chats, menu bar icon, open at login, when the
    iPhone copy was last written
  - **iPhone session key**: how long each pasted key has lasted (from the iPhone's record in
    Scriptable's iCloud folder, `UsageBarApp/key-status.json`, times only) and a notification when it
    stops working
  - **Alerts** (on by default), each with its own toggle and editable thresholds:
    - session 80/95%
    - weekly 75/90%
    - extra usage 80/95/100%
    - session time left 60/15 min (only while under 70%)
    - new session available
    - weekly reset within 24 h
    - not updating for 30 min
    - Claude incidents
  - sound picker, preview, test notification
  - status line snippet
- **Data:** `~/Library/Application Support/UsageBarApp/`
  - `usage_log.csv` (30 days) and `usage_daily.csv`
  - `chats.json` (titles, times and token counts only)
  - `statusline.txt`

**Install / update:** `scripts/install-mac.sh`. It builds, signs with the free personal team and copies
to `~/Applications`.

**If the menu bar item doesn't show:** Ice hides new menu bar items. Open Ice > Settings > Menu Bar
Layout and drag "UsageBarApp" into the visible section.

## Mac widgets
Right-click the desktop > Edit Widgets > search "UsageBarApp":
- **Claude session** (small): %, bar, live countdown, weekly %.
- **Claude usage** (medium/large): session, weekly and Fable bars, extra usage, age of the reading.

They read the app's shared snapshot (App Group `KFT88Q5XQ9.com.joshhotz.usagebarapp`) and update after
every reading.

## iPhone (Scriptable)
1. Install **Scriptable** (free) on the iPhone and open it once. This creates its iCloud folder; after
   that, the Mac app also copies its reading there (`UsageBarApp/snapshot.json`) as a fallback.
2. Copy `iphone/UsageBarApp.js` into Scriptable (iCloud Drive > Scriptable) as **Claude Usage**.
3. On the Mac, copy the `sessionKey` cookie from Chrome (claude.ai tab > ⌘⌥I > Application > Cookies >
   https://claude.ai). On the iPhone, run Claude Usage; the key is pre-filled from Universal Clipboard.
   Tap Save. It stays in the iPhone Keychain. To replace it later: run Claude Usage > Change session key.
4. Add Claude Usage as widgets:
   - Home Screen: small, medium
   - Lock Screen: circular, rectangular, inline

The widget uses the phone's own reading when it can and the Mac's otherwise, and shows which one and how
old it is.

**Claude History** (separate widget, `iphone/ClaudeHistory.js`, in Scriptable as **Claude History**):
today in half-hour slots (used, session running, idle, not recorded) and the last 7 days (used and idle
hours). Large shows both, medium today, small today's numbers; Lock Screen a summary. It draws the Mac's
history (`UsageBarApp/history.json`, written every 10 minutes while the Mac is awake) and keeps the last
good copy on the phone, so it still shows something when iCloud is slow. When Claude Usage's own phone
reading is newer, "right now" (today's line, dot and total) comes from that instead ("Phone · 4m ago"). "Sessions used" adds up how much
of each 5-hour session was used (1.0 = one full session). Charts are lines;
type `bars` in the widget's Parameter field (Edit Widget) for bar charts.

## Folders
| Path | What |
|---|---|
| `PLAN.md` | Decisions, rules, architecture, phases |
| `mac/` | Xcode project (`project.yml` → XcodeGen), `App/`, `Widget/`, and `UsageCore/` (tested logic, `swift test`) |
| `iphone/` | Scriptable scripts |
| `scripts/` | `install-mac.sh`, `uninstall-mac.sh` |
| `docs/` | Market research |
| `CHANGELOG.md` | Every change, release-note style |

## Uninstall
1. Mac: `scripts/uninstall-mac.sh`. It removes the app and widgets, the data folder, the shared data,
   the settings and the build folders. If you added the status line, remove the `statusLine` entry from
   `~/.claude/settings.json`. If you turned on "Open at login", also remove it in System Settings > General >
   Login Items.
2. iPhone: remove the widgets, then delete Claude Usage in Scriptable (and Scriptable itself if wanted).
3. The Claude Code Keychain item is not affected.
