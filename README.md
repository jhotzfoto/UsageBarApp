# UsageBarApp

Native Mac menu bar app + Mac widgets + iPhone (Scriptable) widgets for live Claude usage.
Personal, $0, built alongside UsageBar (`../UsageBar`), which stays as it is. See `PLAN.md`.

**Status (0.1.0, 2026-11-04)**
- **Mac app and Mac widgets:** built, installed and fetching live.
- **iPhone scripts:** written but not tested yet; they need Scriptable on the phone.

## Mac app
Menu bar: `S 12% 2h25m · W 65%` (plus `E x%` once extra usage is being spent), colored green under 70,
amber 70–89, red 90+, grey when stale.

The dropdown shows:
- every limit with %, bar, reset time and countdown
- extra usage budget ($ used of limit)
- **This week by product**: Anthropic's own split (Cowork / Chats / Claude Code)
- last updated, Refresh, claude.ai usage page, Settings…, Quit

**How it works**
- Reads Claude Code's login from the Keychain item "Claude Code-credentials" via `/usr/bin/security`.
  It reads the access token and expiry only, and never writes or refreshes the item.
- Calls `api.anthropic.com/api/oauth/usage` every 5 min (Settings: 2–60), and when you open the menu
  if the reading is over 30 s old. Backs off on HTTP 429. Countdowns tick every minute without API calls.
- **Settings:** check interval, alerts (off by default while UsageBar runs), alert sound with preview and
  test notification, open at login.
- **Alerts, once per window:** session 80/95%, weekly 75/90%, extra usage 80/95/100%, new session
  available, not updating for 30 min.

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

## iPhone (Scriptable), not tested yet
1. Install **Scriptable** (free) on the iPhone and open it once. This creates its iCloud folder; after
   that, the Mac app also copies its reading there (`UsageBarApp/snapshot.json`) as a fallback.
2. Copy `iphone/login-test.js` and `iphone/UsageBarApp.js` into Scriptable (iCloud Drive > Scriptable).
3. Run `login-test.js` in Scriptable and sign into claude.ai when asked. Then add it as a widget to
   check it works from a widget.
4. Add `UsageBarApp.js` as widgets:
   - Home Screen: small, medium
   - Lock Screen: circular, rectangular, inline

The widget uses the phone's own reading when it can and the Mac's otherwise, and shows which one and how
old it is.

## Folders
| Path | What |
|---|---|
| `PLAN.md` | Decisions, rules, architecture, phases |
| `mac/` | Xcode project (`project.yml` → XcodeGen), `App/`, `Widget/`, `Shared/` |
| `iphone/` | Scriptable scripts |
| `scripts/` | `install-mac.sh`, `uninstall-mac.sh` |
| `docs/` | Market research |
| `CHANGELOG.md` | Every change, release-note style |

## Uninstall
1. Mac: `scripts/uninstall-mac.sh`. It removes the app and widgets, the shared data, the settings and
   the build folder. If you turned on "Open at login", also remove it in System Settings > General >
   Login Items.
2. iPhone: remove the widgets, then delete the two scripts in Scriptable (and Scriptable itself if wanted).
3. UsageBar (SwiftBar) and the Claude Code Keychain item are not affected.
