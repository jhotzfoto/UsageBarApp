# Market research: Claude usage trackers (2026-11-04)

Quick scan of web listings, GitHub pages and App Store pages. Most feature claims come from the
developers' own pages and weren't tested.

## Top 5 competitors
| # | App | Platforms | Price | How it gets data | Stand-out features |
|---|---|---|---|---|---|
| 1 | **Usage for Claude + ChatGPT** (App Store) | iPhone, iPad, Mac, Apple Watch | Free; Pro via in-app purchase | Signs in on each device with the official login | Home + Lock Screen widgets, Watch complications, reset alerts, status alerts, 90-day history, CSV export, multiple accounts, ChatGPT too |
| 2 | **Claude Tracker** (formerly Claude Usage Tracker), open source | Mac | Free (MIT, donations) | Browser sign-in, session key, or Claude Code login | Per-model usage, alerts with sound picker, extra-usage and API costs, multiple profiles with auto-switch, Claude Code statusline, notch HUD, auto-start session on reset |
| 3 | **CodexBar** (steipete), open source | Mac | Free | Claude Code login, browser cookies, or CLI | Two-bar menu bar meter, credits bar when weekly is used up, 30-day local cost scan, WidgetKit widget, incident badges, CLI, many AI providers |
| 4 | **Limits** (getlimits.app) | iPhone | Free; Pro for predictive warnings | Connects your Claude account | Home + Lock Screen widgets, live reset countdowns, refill alerts, per-model weekly caps |
| 5 | **Usagebar** (usagebar.com) | Mac | $9 one-time | Claude Code login | Simple menu bar 5-hour + weekly, matches `/usage` |

Also seen:
- **ClaudeMeter** and **ClaudeUsageBar**: free Mac apps.
- **ClaUse Bar** and **CUStats Go**: App Store; CUStats Go costs $8.99.
- Two Scriptable widgets on GitHub:
  - **hendrilee/claude-usage-widget** uses your claude.ai session cookie and adds pace labels and a 24h trend.
  - **intelQong/claude-usage-iOS-widget** is fed by Claude Code's `/usage`.

## What this means for us
- **App Store apps exist.** Apple does approve these apps (#1, ClaUse Bar, CUStats Go). Their developers
  pay for the developer program, which you've ruled out.
- **The iPhone can sign in by itself.** #1 and the hendrilee widget read usage on the phone with the
  user's own claude.ai login, which supports our phase 0 approach.
- **Basic tracking is crowded.** The 5-hour and weekly view, widgets and alerts are covered by free apps.

## Where UsageBar is already different
| UsageBar has | Competitors |
|---|---|
| Estimated **usage per chat** (claude.ai + Claude Code), with an independent token check | None found |
| History: unused % at each reset, idle hours, windows per day/week | #1 has history charts, but not "unused" or idle time |
| Extra usage budget in $ alongside the % | #2 has extra-usage costs; most don't |
| Fully local, no account, open to you | The open-source ones are similar |

## Ideas worth adding (none built)
1. **Anthropic's own split by product.** The usage endpoint now returns `seven_day_breakdown` (on
   2026-11-01: Claude Code 3%, Chats 16%, Cowork 81% of the weekly window). Showing it is free and exact,
   and it can check the per-chat estimates by product. **Top pick:** small, accurate, unique.
2. **Pace forecast.** For example "At this pace you'll hit 100% at 9:40 PM" or "on track to use 60% this
   week". Several competitors have a pace marker. Easy, using the log we already keep.
3. **Cost per chat while on extra usage.** Convert the per-chat estimate into dollars once the session is
   full and the budget is in use ("Uber Eats agent: ~$1.20 tonight"). Nobody has this.
4. **Claude status alerts.** Notify when status.anthropic.com reports an incident, so a "stuck" chat isn't
   mistaken for a limit (#1 and #3 do this).
5. **"Use it or lose it" planning.** Show how much session time and % will go unused, and suggest when to
   start the next session based on your usual hours (the history page already tracks unused %).
6. **Claude Code statusline.** Session %, countdown and pace in the terminal (#2 has this).
7. **Live Activity / Watch.** #1 has a Watch app. A free account makes native iOS and Watch apps expire
   every 7 days, so these are only realistic if you ever pay for the developer program.

## Sources
- https://github.com/hamed-elfayome/Claude-Usage-Tracker
- https://claudetracker.com/
- https://apps.apple.com/us/app/usage-for-claude/id6755173244
- https://hayek.github.io/ClaudeUsagePage/
- https://github.com/steipete/CodexBar/releases/tag/v0.40.0
- https://getlimits.app/claude-usage-tracker
- https://usagebar.com/
- https://eddmann.com/ClaudeMeter/
- https://www.claudeusagebar.com/
- https://apps.apple.com/app/id6759294136
- https://apps.apple.com/us/app/id6757679404
- https://github.com/hendrilee/claude-usage-widget
- https://github.com/intelQong/claude-usage-iOS-widget
- https://tokn.watch/blog/mac-menu-bar-ai-usage/
