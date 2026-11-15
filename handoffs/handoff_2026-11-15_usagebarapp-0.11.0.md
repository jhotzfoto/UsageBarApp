# HANDOFF: UsageBarApp 0.11.0, automatic Claude Code login renewal (saved 2026-11-15 15:14 ET)
Status: OPEN
Next move: check `~/Library/Application Support/UsageBarApp/login_renewals.log` for a "renewed, good until" line from tonight (~22:28–22:58 ET)

UsageBarApp (native $0 macOS menu bar app + Mac widgets + iPhone Scriptable widgets for live Claude usage) went from 0.10.0 to **0.11.0** to stop the recurring "Stale since … Claude Code login expired" banner. Josh wants zero maintenance: never resync or log in manually. 0.11.0 is built, installed, running (started 2026-11-15 14:59), tests pass (30), merged to `main` and pushed to a new **private GitHub repo**. The only thing NOT yet verified is the app renewing the login on its own in the wild: first natural chance is tonight when the current login nears its 22:58 ET expiry. Nothing was deleted except one test transcript I created (see Loose ends).

## Where the files are
Project root: `~/Library/Mobile Documents/com~apple~CloudDocs/01_ClaudeCoWork/Workspace/03_Projects/UsageBarApp/` (git, branch `main`, HEAD 6541244 + this handoff commit)
- GitHub: https://github.com/jhotzfoto/UsageBarApp  (PRIVATE, remote `origin`, only branch `main`; gh CLI logged in as jhotzfoto)
- mac/UsageCore/Sources/UsageCore/LoginRenewal.swift   NEW: parse login JSON (token + expiry only), when-to-renew rules, renewal log, CLI path candidates
- mac/App/UsageClient.swift      readLogin / renewLogin (`claude -p /usage --no-session-persistence`, 60 s timeout, cwd ~) / openSignIn (.command file → `claude auth login`); new errors refused(code), signInNeeded; Shell.run gained `cwd:`
- mac/App/UsageModel.swift       fetchUsage(): renew if due → fetch → on login error renew+retry once → Chrome backup → sign-in state; renewLoginIfNeeded(), markSignInNeeded() (one forced notification)
- mac/App/MenuView.swift         "Sign in" button under the stale banner, only when needsSignIn
- mac/UsageCore/Tests/UsageCoreTests/UsageCoreTests.swift   4 new tests (30 total)
- CHANGELOG.md (0.11.0 entry), README.md, PLAN.md (rule change recorded), mac/project.yml (0.11.0 / build 15)
- handoffs/handoff_2026-11-06_usagebarapp-0.10.0.md, handoff_2026-11-05_usagebarapp-0.2.3.md   earlier checkpoints (API details, dead ends, gotchas)
Runtime: `~/Library/Application Support/UsageBarApp/` usage_log.csv, chats.json, model_daily.csv, statusline.txt, **login_renewals.log (new)**. Installed app: `~/Applications/UsageBarApp.app`.
This session: Claude Code desktop, `local_4e68506b-1dfd-4d00-ba51-87271aeb410c`, link claude://claude.ai/epitaxy/local_4e68506b-1dfd-4d00-ba51-87271aeb410c (Remote Control on). Transcript under `~/.claude/projects/` for the scratch folder this session started in, then moved to the project folder.
Most recent earlier UsageBarApp work: Nov 6 session `11177533…` (cwd ../UsageBar) → 0.10.0. The Nov 9 home-folder session was PingPlace, unrelated.

## Root cause (why it kept going stale)
- The app reads usage with Claude Code's OAuth token from Keychain item "Claude Code-credentials". It expires every few hours (~8 h) and only renews when the **Homebrew CLI** Claude Code makes a real request.
- The desktop app's Code tab does NOT refresh that item (it uses its own login; the ~87 "Claude Code-credentials-<hash>" items are stale, newest Nov 6). So using Claude all day never helped, and the old banner text "Open Claude Code" was misleading.
- Chrome backup (claude.ai tab via AppleScript) was unreliable: on Nov 11 Chrome answered nothing ("AppleEvent timed out -1712"), which also froze chat tracking at 11:45 that day. On Nov 15 it was working again (it kept readings alive though the login had expired Nov 13 23:16).

## Decisions and why (don't reopen)
- **Renewal trigger = `claude -p /usage --no-session-persistence`.** Tested 2026-11-15: login went from expired (Nov 13) to good until 22:58 ET. No model request (handled locally + usage endpoint), no transcript saved with the flag, works in a bare env (`env -i HOME USER`).
- **CORRECTION:** `claude auth status` does NOT renew (tested Nov 15: exit 0, expiry unchanged). On Nov 11 I claimed it did; that was a coincidence. The first 0.11.0 build used it and the log shows `expired  failed: still expiring after the check`; fixed in the final build.
- Rule change approved by Josh ("Yes, build it", 2026-11-11): the app may cause Claude Code to renew itself. Still never reads the refresh token, never writes the Keychain item, never refreshes OAuth itself (could rotate/invalidate Claude Code's refresh token and log it out).
- Timing: renew when < 30 min left, expired, or 401/403; at most once per 10 min.
- Rejected: `claude setup-token` 1-year token (docs: "can only make model requests"; community reports say usage endpoint 403s without user:profile scope; not verified by us). Reading the desktop app's hashed items (stale). App doing its own OAuth refresh (risk above).
- Sign-in only needed if Claude Code is fully signed out (password change, "log out all devices"): one forced notification + Sign in button.
- Merge to main and private repo: Josh asked for both explicitly.

## Verified / done
- 30/30 tests pass (`swift test`), BUILD SUCCEEDED, installed 0.11.0, running process started 14:59:21 = install time.
- Manual `/usage` renewal worked; app then logged fresh readings.
- Full git history scanned for keys/tokens before publishing: none.
- Branch `auto-login-renewal` fast-forwarded into main, pushed, deleted locally and on GitHub.

## Open / next steps
1. **Verify tonight's automatic renewal.** After ~22:30 ET: `cat ~/Library/Application\ Support/UsageBarApp/login_renewals.log` should show `expiring soon  renewed, good until …`. If it shows `failed`, read the message; likely suspects: CLI path, timeout, Keychain prompt for `claude` launched by the app. A background watcher in this session was waiting for it (dies with the session).
2. Then watch a few days; the log shows each renewal. If any `failed` lines repeat, investigate before Josh notices.
3. Optional: menu text still says "Stale since" for Chrome-only failures; fine for now.
4. Old open items from the 0.10.0 handoff (iPhone history screen, other-day widget, models on iPhone widget, visual checks) remain unanswered, all optional.
5. Skills housekeeping (not this project): `/handoff-session` (~/.claude/skills, Nov 11, cross-app) is newer than `/anthropic-skills:handoff-session` (claude.ai account copy, Nov 1, Cowork-only). Re-upload the new one to claude.ai only if Josh asks. A stale July copy sits in `04_Claude-Skills/Chat-Session-Mgmt/Session-Handoff/handoff-session` (unused; archive someday, untouched).

## How to work on it
- Tests: `cd mac/UsageCore && swift test --scratch-path ~/Library/Developer/Xcode/DerivedData/UsageCore-spm`
- Build + install: `zsh scripts/install-mac.sh` (needs unsandboxed run; xcodegen regenerates the project). Check `plutil -extract CFBundleShortVersionString raw ~/Applications/UsageBarApp.app/Contents/Info.plist`.
- Login expiry without printing secrets: `security find-generic-password -s "Claude Code-credentials" -w | python3 -c "import sys,json,datetime;print(datetime.datetime.fromtimestamp(json.load(sys.stdin)['claudeAiOauth']['expiresAt']/1000))"`
- `pgrep`/`ps` and `osascript` are blocked in the sandbox; run unsandboxed. zsh has no `timeout`; use background + kill.
- Push: `git push` (origin = GitHub private repo). Global rule: commit and push after each working milestone.

## Rules (carry over)
- Never write the "Claude Code-credentials" item or use the refresh token; only Claude Code renews itself. Never get past claude.ai's Cloudflare check. Never ask Josh to paste keys into chat.
- Tests never touch real data files. Every change gets a plain-language CHANGELOG entry.
- Josh: terse, no code in chat, multiple-choice decisions, minimal manual steps, confirm before publishing/deleting.

## Loose ends / privacy
- Deleted (my own test artifact): `~/.claude/projects/-Users-hotz-personal/1612c116-….jsonl` created by the first `/usage` test before adding `--no-session-persistence`.
- `$TMPDIR` scratch (as.err, u.out with /usage output) is disposable, usage numbers only.
- `$TMPDIR/UsageBarApp-sign-in.command` is created only if Sign in is clicked; contains just the CLI path + `auth login`.
- login_renewals.log holds times and outcomes only, no secrets. Repo is private; contains handoffs with Josh's email and team id.

## How to resume
New Claude Code session in `03_Projects/UsageBarApp`, run /resume-session (shows as `/anthropic-skills:resume-session` when synced from claude.ai) and pick this file. First command: `cat ~/Library/Application\ Support/UsageBarApp/login_renewals.log`.
