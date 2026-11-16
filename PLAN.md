# UsageBarApp: plan (agreed 2026-11-04)

> **Progress (0.2.0):**
> - Phases 1, 2 and 4 are built and tested on the Mac: history, pace, planning, chat tracking, outage
>   alerts, editable thresholds and status line.
> - Phase 3 (iPhone) scripts are written; the test is waiting on the phone.

A native Mac app + Mac widgets + iPhone widgets showing live Claude usage, built for $0 for personal
use. Quality over speed. It replaced UsageBar (SwiftBar), which was uninstalled on 2026-11-05 at Josh's
request (its project folder in ../UsageBar is kept as history).

## Decisions
| Topic | Decision |
|---|---|
| Cost | $0. Free Apple ID ("Apple Development: josh.hotz@gmail.com"). No App Store (that needs the $99/yr program). |
| Mac | Native SwiftUI menu bar app + WidgetKit widgets (desktop and Notification Center). |
| iPhone | Scriptable (free) widgets: Home Screen and Lock Screen. Free-signed native iOS apps expire every 7 days, so not used. |
| iPhone data | The iPhone signs into claude.ai itself in Scriptable's built-in browser and reads usage on its own (works with the Mac off). **Feasibility test first.** Backup: the Mac's shared snapshot via iCloud. |
| UsageBar | Untouched. Compared side by side over the long term; switch-over only when you decide. |
| Alerts | Off in the new app until you switch over (no duplicates). |
| Code | This folder, own git history, CHANGELOG (release-note style) and README. |

## Rules carried over
- Never refresh or write the "Claude Code-credentials" Keychain item; read only. Never read the refresh token.
  Since 0.11.0 (Josh approved 2026-11-11): when the login has under 4 min left (or ran out), the app runs Claude Code's
  own `/usage` command (`claude -p /usage --no-session-persistence`; no model call, at most every 10 min) so Claude Code renews its own login.
- Never get past claude.ai's Cloudflare check. A real browser with your own login is fine; if Cloudflare
  challenges it, stop.
- Ask before installing anything; say so before deviating from the plan.
- Don't ship untested work with confident framing: verify against claude.ai Settings > Usage.
- Tests never touch real data files (see the UsageBar 1.2.1 incident).
- Log every change in CHANGELOG.md.

## Architecture
```
Mac app (menu bar)                         iPhone (Scriptable)
  reads Claude Code login (read-only)        own claude.ai login in Scriptable's WebView
  -> api.anthropic.com/api/oauth/usage       -> claude.ai/api/organizations/{org}/usage
  -> menu bar + dropdown                     -> Home + Lock Screen widgets
  -> App Group file -> Mac widgets           fallback: reads the Mac snapshot from iCloud
  -> snapshot.json in Scriptable's iCloud folder
```
- **Polling while both run:** the new app fetches every 5 min (UsageBar every 2 min), well under the
  ~7-quick-calls rate limit.
- **Countdowns** in widgets use a live timer to the reset time, so they tick without widget refreshes.
  (iOS allows a widget roughly 40–70 updates a day.)
- **Keychain:** the first read shows a macOS prompt ("UsageBarApp wants to use … Claude Code-credentials").
  Choose "Always Allow". Reading only.

## Phases (each ends with a check you can see)
0. **Setup + feasibility** (now)
   - Folder, git, plan.
   - iPhone login test (`iphone/login-test.js`): can Scriptable sign into claude.ai, read usage, and do it
     from inside a widget?
   - Mac check: build and run a minimal menu bar app + widget with the free signing identity. App Groups
     and widgets with free signing are expected to work but must be confirmed.
1. **Mac app core:** fetch, menu bar text and colors, dropdown (limits, reset times, countdown, extra
   usage budget, Refresh, refresh interval), stale display, snapshot writer. Verified against claude.ai.
2. **Mac widgets:** small (session % + countdown) and medium (session, weekly, Fable, budget).
3. **iPhone widgets:** Lock Screen (session % + countdown) and Home Screen small/medium, using the phase 0
   result; Mac snapshot as fallback, with its age shown.
4. **Parity and extras:** alerts (off by default) with a chosen sound, history, per-chat tracking
   (Chrome tab and Claude Code transcripts, as in UsageBar 1.4), settings window.
5. **Long-term side-by-side test**, then a switch-over checklist (only if you decide to switch).

## Open items
- Install **Scriptable** (free, App Store) on the iPhone and open it once. That creates its iCloud
  folder.
- Exact claude.ai usage response on iPhone: confirmed in phase 0.
