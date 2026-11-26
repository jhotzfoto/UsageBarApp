# UsageBarApp

## Current state / Next step
- 0.11.1 installed and on GitHub (private, main): renews Claude Code's login automatically via `claude -p /usage`, in its last 4 min or once expired. Verified: renewed on its own 2026-11-15 22:53, 2026-11-16 06:51 and 14:49 ET (Claude Code ignores renewal until ~5 min left).
- Login renewal: 31 in a row with no failures by 2026-11-25, so the log watch is closed.
- 2026-11-25: iPhone Claude History widget fixed (keeps a copy on the phone so it isn't blank, 10-min refresh asks, "1.6 sessions used" instead of "156%"). Copied into Scriptable's iCloud folder. Tested with a fake Scriptable on the Mac only.
- 2026-11-26: iCloud was slow to bring the Mac's history to the phone (34 min), so History now uses the phone's own Claude Usage reading for "right now" when newer (header "Phone · …").
- Next: on the phone, check the History header says "Phone · Xm ago" with a small number and the total matches the Mac's menu.
- Latest handoff: handoffs/handoff_2026-11-17_usagebarapp-test-crash-and-git-index.md. The 0.11.1 one still holds the app rules and how to build.
