# HANDOFF: UsageBarApp 0.11.1, login renewal timing fixed and verified (saved 2026-11-16 15:38 ET)
Status: DONE (watching only)
Next move: nothing required; optionally glance at `login_renewals.log` in a few days for any "failed" lines

UsageBarApp (native $0 macOS menu bar app + Mac widgets + iPhone Scriptable widgets for live Claude usage) is at **0.11.1**, installed and on GitHub. It keeps Claude Code's login alive by itself, so the "Stale since … login expired" banner should not come back. This supersedes handoff_2026-11-15_usagebarapp-0.11.0.md, which was saved before the renewal was verified and still describes the old 30-minute timing. Read that older file only for deep background (root cause, rejected options); everything that changed is here.

## Where the files are
Project root: `~/Library/Mobile Documents/com~apple~CloudDocs/01_ClaudeCoWork/Workspace/03_Projects/UsageBarApp/` (git, branch `main`, 0.11.1 = commit f41dbb8, plus this handoff commit)
- GitHub: https://github.com/jhotzfoto/UsageBarApp (PRIVATE, only branch `main`; gh CLI logged in as jhotzfoto)
- mac/UsageCore/Sources/UsageCore/LoginRenewal.swift   `renewWithin` = 4 min (was 30); comment records the evidence
- mac/App/UsageModel.swift       fetchUsage(): renew if due (≤4 min left or expired) → fetch → on 401/403 renew+retry once → Chrome backup → sign-in state
- mac/App/UsageClient.swift      renewLogin() runs `claude -p /usage --no-session-persistence` (60 s timeout, cwd ~)
- mac/UsageCore/Tests/UsageCoreTests/UsageCoreTests.swift   testRenewalTiming now asserts no renewal at 20 and 10 min left, renewal at 3 min (30 tests total)
- CHANGELOG.md (0.11.1 entry), PLAN.md (rule note says 4 min), CLAUDE.md (Current state), mac/project.yml (0.11.1 / build 16)
- handoffs/handoff_2026-11-15_usagebarapp-0.11.0.md   previous checkpoint (root cause, rules, rejected options)
Runtime: `~/Library/Application Support/UsageBarApp/login_renewals.log` (times and outcomes only, no secrets). Installed app: `~/Applications/UsageBarApp.app` (0.11.1, running since 2026-11-15 23:17).
This session: Claude Code desktop, `local_4e68506b-1dfd-4d00-ba51-87271aeb410c`, link claude://claude.ai/epitaxy/local_4e68506b-1dfd-4d00-ba51-87271aeb410c (Remote Control on; title already starts with "✋🏻🛑 HANDED OFF").

## What we learned since the 0.11.0 handoff
- **Claude Code only renews its login in roughly its last 5 minutes.** Evidence from the log on 2026-11-15: `/usage` at 29 min and 17 min left did nothing ("failed: still expiring after the check"); at 4 min 44 s left it renewed (good for 8 more hours). The afternoon manual test worked only because the login was already expired.
- So 0.11.0's 30-minute window caused harmless but misleading "failed" lines. 0.11.1 asks only in the last 4 minutes, or once expired. If the app's ~12-minute fetch cycle misses that window, the "expired" path renews right before the next fetch, so readings don't go stale.

## Verified / done
- 0.11.0 renewed on its own at 2026-11-15 22:53 ET (good until 06:53).
- 0.11.1: 30/30 tests pass, BUILD SUCCEEDED, installed, running. Committed f41dbb8 and pushed.
- 0.11.1 renewed on its own twice with no failures: 2026-11-16 06:51 (good until 14:51) and 14:49 (good until 22:49). Both caught the 4-minute window.

## Open / next steps (all optional)
1. In a few days, check `login_renewals.log` for any "failed" lines. Expect "expiring soon … renewed" (or "expired … renewed" when the window is missed). If "failed" repeats: suspects are the CLI path, the 60 s timeout, or a Keychain prompt for `claude` launched by the app.
2. Menu text still says "Stale since" for Chrome-only failures; fine for now.
3. Old optional items from the 0.10.0 handoff (iPhone history screen, other-day widget, models on iPhone widget, visual checks) remain unanswered.
4. Not this project: a one-time scheduled task `plugin-cleanup-reminder` (due 2026-11-16 14:17 ET; whether it ran was not checked) reminds Josh to turn off unused Claude plugins. About 80 plugin connector errors came from synced claude.ai plugins (about 60 need sign-in, about 22 "No URL configured", plus the broken Definite server in the Data plugin). His own connectors are all fine. Suggested off: Bio Research, Legal, Sales, Customer Support, Data, Finance, Operations, Daloopa, Nimble, Design, Brand Voice. Done in the Claude app's plugin settings, not from a Code session (the only local Claude Code plugin is Shortcuts Playground). Exact menu name not verified.
5. Skills housekeeping (from the last handoff): `/handoff-session` (~/.claude/skills) is newer than the claude.ai copy; re-upload only if Josh asks.

## How to work on it
- Tests: `cd mac/UsageCore && swift test --scratch-path ~/Library/Developer/Xcode/DerivedData/UsageCore-spm`. Must run unsandboxed (the sandbox blocks the system temp folder the tests write to).
- Build + install: `zsh scripts/install-mac.sh` (unsandboxed; xcodegen regenerates the project). Version check: `plutil -extract CFBundleShortVersionString raw ~/Applications/UsageBarApp.app/Contents/Info.plist`.
- Login expiry without printing secrets: `security find-generic-password -s "Claude Code-credentials" -w | python3 -c "import sys,json,datetime;print(datetime.datetime.fromtimestamp(json.load(sys.stdin)['claudeAiOauth']['expiresAt']/1000))"`
- `git push` needs an unsandboxed run. Commit and push after each working milestone; every change gets a plain-language CHANGELOG entry.

## Rules (carry over)
- Never write the "Claude Code-credentials" Keychain item or use the refresh token; only Claude Code renews itself (via `claude -p /usage`). `claude auth status` does NOT renew.
- Never get past claude.ai's Cloudflare check. Never ask Josh to paste keys into chat. Tests never touch real data files.
- Josh: terse, plain language, no code in chat, multiple-choice decisions, confirm before publishing or deleting. Never edit an old handoff; write a new one.

## Loose ends / privacy
- Nothing new on disk besides this file. login_renewals.log holds times and outcomes only. The repo is private and its handoffs contain Josh's email and team id.

## How to resume
New Claude Code session in `03_Projects/UsageBarApp`, run /resume-session and pick this file. First command: `tail -5 ~/Library/Application\ Support/UsageBarApp/login_renewals.log`.
