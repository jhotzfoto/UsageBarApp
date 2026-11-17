# HANDOFF: UsageBarApp test crash hardened, git index repaired (saved 2026-11-17 12:49 ET)
Status: DONE (watching only)
Next move: glance at login_renewals.log every few days; expect only "renewed" lines

Follow-up to the 0.11.1 handoff. Josh got an xctest crash report (2026-11-15 23:16 ET). It was a sandboxed test run during 0.11.1 work, not the app. The app was never affected. The test is now hardened so it fails with a clear message instead of crashing, committed and pushed (1440a57). Afterwards git's index went missing (likely iCloud). It was restored from the leftover index.lock with Josh's OK, and git is clean. The app is still 0.11.1, with no rebuild or reinstall needed.

## Where the files are
Project root: `~/Library/Mobile Documents/com~apple~CloudDocs/01_ClaudeCoWork/Workspace/03_Projects/UsageBarApp`
- mac/UsageCore/Tests/UsageCoreTests/UsageCoreTests.swift   hardened test setUp (changed this session)
- CHANGELOG.md                                              new top entry "Tests only — 2026-11-16 (no more test crash reports)"
- handoffs/handoff_2026-11-16_usagebarapp-0.11.1.md         previous handoff: app rules, build and install steps (still valid)
- ~/Library/Application Support/UsageBarApp/login_renewals.log   the app's real renewal log (read only, never touched by tests)
- Session: claude://claude.ai/epitaxy/local_757c8975-f3f1-4c0d-8e05-255899157aa5 (Remote Control on, so it's also listed at claude.ai/code)
- Transcript: ~/.claude/projects/-Users-hotz-personal-Library-Mobile-Documents-com-apple-CloudDocs-01-ClaudeCoWork-Workspace-03-Projects-UsageBarApp/dee39ecf-3e40-40e0-baee-cda5b3d71ed8.jsonl

## What the crash was (settled, don't re-investigate)
- The process was `xctest` (Apple's test runner), whose parent was swift-test, launched by `claude`. It was EXC_BREAKPOINT in `swift_unexpectedError`, which is a `try!` failing.
- The test was `testRenewalLogIsShortAndSecretFree` (then UsageCoreTests.swift:498). It writes a practice log to a temp folder and reads it back with `try!`.
- Cause: the run was inside Claude Code's sandbox, which blocks the system temp folder, so the file was never written. That session then re-ran the tests unsandboxed (30/30 passed) and shipped 0.11.1 one minute later.
- Effect on the app: none. The app never runs test code. The app's own log write (LoginRenewal.swift appendLog) uses `try?` and skips quietly on failure.

## What changed (commit 1440a57, pushed to origin/main)
- `setUpWithError() throws` now creates the temp folder and writes a `.probe` file. On failure it throws `TempFolderNotWritable`, so every test fails with: "Can't write the test temp folder (...). If this is Claude Code's sandbox, run the tests outside it."
- In `testRenewalLogIsShortAndSecretFree() throws`, the read uses `try` instead of `try!`.
- The app code is unchanged and still at 0.11.1.

## Verified
- A normal unsandboxed run passes 30/30.
- Simulated sandbox (setUp temporarily pointed at a read-only folder, then restored from backup): all 30 tests failed cleanly with the message, and no crash report appeared. Not verified inside the real sandbox, because `swift build` can't run there at all (sandbox_apply: Operation not permitted). Overriding TMPDIR didn't work either: FileManager ignores it, and SwiftPM breaks with a read-only TMPDIR.
- The renewal log shows only "renewed" lines since 0.11.1: 11-15 22:53, 11-16 06:51, 14:49, 22:47 and 11-17 06:44. The two older "failed" lines came from the old 30-minute timing that 0.11.1 replaced.

## Git index repair (2026-11-17)
- Symptom: right after the commit and push, `git status` showed all 59 files as deleted, though every file was on disk and the commit was complete.
- Cause: `.git/index` was gone, and a complete `.git/index.lock` (6811 bytes, 59 entries, from 16:12) was left behind, so git's rename never finished. Likely iCloud syncing the folder at 16:13. This is plausible but not proven.
- Fix (Josh approved): checked that no git process was running, backed up the lock, then `mv .git/index.lock .git/index`. Now `git status` is clean, 59 files are tracked, and HEAD = origin/main = 1440a57.
- If git ever shows everything as "deleted" while the files are still there, check for `.git/index.lock`. If index is missing and the lock is complete, the same rename fixes it. Ask Josh first.

## Loose ends
- The backup of the old lock is at `/private/tmp/claude-501/-Users-hotz-personal-Library-Mobile-Documents-com-apple-CloudDocs-01-ClaudeCoWork-Workspace-03-Projects-UsageBarApp/dee39ecf-3e40-40e0-baee-cda5b3d71ed8/scratchpad/index.backup`. It's a temp folder that clears itself, it holds no private data, and nothing needs to be done.

## Open / next steps
1. Over the next few days, glance at login_renewals.log. It should show only "renewed" lines, about every 8 hours.
2. Nothing else is pending.

## How to resume
- Tests: `cd mac/UsageCore && swift test --scratch-path ~/Library/Developer/Xcode/DerivedData/UsageCore-spm`. Run it outside the sandbox. In the sandbox the tests now fail with the temp-folder message, which is expected.
- Build and install: `zsh scripts/install-mac.sh`. git push needs an unsandboxed run.
- Rules carried over:
  - Never write the "Claude Code-credentials" Keychain item or use the refresh token.
  - Never get past claude.ai's Cloudflare check.
  - Never ask Josh to paste keys into chat.
  - Tests never touch real data files.
  - Confirm before deleting, sending, publishing or spending.
  - Never edit an old handoff.
  - Plain, short language with no code in chat, and every decision as a multiple-choice question.
