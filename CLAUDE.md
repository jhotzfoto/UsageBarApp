# UsageBarApp

## Current state / Next step
- 0.11.1 installed and on GitHub (private, main): renews Claude Code's login automatically via `claude -p /usage`, in its last 4 min or once expired. Verified: renewed on its own 2026-11-15 22:53, 2026-11-16 06:51 and 14:49 ET (Claude Code ignores renewal until ~5 min left).
- 2026-11-16/17: tests now fail with a plain message instead of crashing in the sandbox (1440a57). Git's index was lost (likely iCloud) and restored from index.lock. The app is unchanged.
- Next: glance at `~/Library/Application Support/UsageBarApp/login_renewals.log` over the next few days; it should show only "renewed" lines.
- Latest handoff: handoffs/handoff_2026-11-17_usagebarapp-test-crash-and-git-index.md. The 0.11.1 one still holds the app rules and how to build.
