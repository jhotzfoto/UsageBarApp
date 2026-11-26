# UsageBarApp

## Current state / Next step
- 0.11.1 installed and on GitHub (private, main): renews Claude Code's login automatically via `claude -p /usage`, in its last 4 min or once expired. Verified: renewed on its own 2026-11-15 22:53, 2026-11-16 06:51 and 14:49 ET (Claude Code ignores renewal until ~5 min left).
- Login renewal: 31 in a row with no failures by 2026-11-25, so the log watch is closed.
- 2026-11-25: iPhone Claude History widget fixed (keeps a copy on the phone so it isn't blank, 10-min refresh asks, "1.6 sessions used" instead of "156%"). Copied into Scriptable's iCloud folder. Tested with a fake Scriptable on the Mac only.
- 2026-11-26: iCloud was slow to bring the Mac's history to the phone (34 min), so History now uses the phone's own Claude Usage reading for "right now" when newer (header "Phone · …").
- Josh confirmed on the phone: header shows "Phone · 2m ago". Phone-script tests: `iphone/tests/` (see handoff).
- 2026-11-26 (later): git's folder is now `.git.nosync` (a one-line `.git` file points to it), so iCloud stops undoing git's saves. Renaming `.git` needs an unsandboxed run. Health check that night: all fine. Phone tests now use a pinned fake clock, so they pass any time (14 widget + 7 accuracy checks).
- Next: nothing pending. Optionally glance that the History widget keeps refreshing on its own, and that git stays clean after the next few commits.
- Latest handoff: handoffs/handoff_2026-11-26_usagebarapp-iphone-history-widget.md. The 0.11.1 one still holds the app rules and how to build.
