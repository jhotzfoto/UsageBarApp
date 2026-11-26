# HANDOFF: UsageBarApp iPhone Claude History widget fixed (saved 2026-11-26 00:02 ET)
Status: DONE
Next move: over the next day, glance at the History widget: header should say "Phone · Xm ago" with a small number

The iPhone "Claude History" widget (Scriptable) was blank until tapped, showed stale data, and showed confusing totals over 100%. Three fixes are now live on the phone and pushed to GitHub. (1) The widget keeps its own copy on the phone and stops waiting on iCloud after 5 seconds, so it's never blank. (2) Totals read as sessions ("1.6 sessions used") instead of "156%". (3) The phone's own live Claude Usage reading fills in "right now" when iCloud is slow to bring the Mac's update. Josh confirmed on the phone that the header shows "Phone · 2m ago". The Mac app is unchanged (still 0.11.1), with nothing to rebuild or reinstall.

## Next steps
1. Nothing is pending. Optional: over the next day, check the History widget refreshes on its own (header "Phone · Xm ago", small number) and its total matches the Mac menu's.
2. If it shows "⚠︎ Mac · …" for a long time, the Claude Usage widget has probably stopped reading claude.ai on the phone (key expired or bot check). Run Claude Usage on the phone first. Details: Decisions, item 6.
3. Optional ideas, not asked for yet (Open questions): build a "today" from the phone alone just after midnight, and clip the top dot on the 7-day chart.
- Do not: edit the installed Scriptable copy by hand without also updating `iphone/ClaudeHistory.js`. Keep them identical apart from Scriptable's 3-line header.

## How to resume
- Read this file, then `CLAUDE.md`. The app rules and build steps are in `handoffs/handoff_2026-11-16_usagebarapp-0.11.1.md` (still valid).
- Phone script tests (no Scriptable needed, Node on the Mac):
  `node iphone/tests/history-widget.test.mjs iphone/ClaudeHistory.js iphone/tests/fixtures/history-2026-11-25-2350.json iphone/tests/fixtures/phone-reading-2026-11-25-2354.json` (13 PASS)
  `node iphone/tests/history-phone-merge.test.mjs iphone/ClaudeHistory.js iphone/tests/fixtures/history-2026-11-25-2350.json iphone/tests/fixtures/phone-reading-2026-11-25-2354.json` (7 PASS)
- To ship a phone-script change: write Scriptable's 3-line header plus `iphone/ClaudeHistory.js` to `~/Library/Mobile Documents/iCloud~dk~simonbs~Scriptable/Documents/Claude History.js` (iCloud syncs it to the phone). This needs an unsandboxed run.
- Skills: none needed. handoff-session at the end.
- Needs: Bash outside the sandbox for the Scriptable folder and for git push.

---
# REFERENCE

## Original ask and standing rules (verbatim)
Josh's opening message pasted a resume prompt, then added his own words and a screenshot of the small History widget (showing "144% used · 2.0 h idle · 272% unused at reset", "Mac · 14m ago"):
> Continue my UsageBarApp project. Read CLAUDE.md, then the newest file in handoffs/ (currently handoff_2026-11-17_usagebarapp-test-crash-and-git-index.md), and the 0.11.1 handoff for the app rules and build steps.
>
> Where it stands as of 2026-11-25: version 0.11.1 is installed and on GitHub, git is clean, and nothing is half-done. The login renewal log at ~/Library/Application Support/UsageBarApp/login_renewals.log shows 31 renewals in a row since Nov 15 with no failures, so the "watch the log" item is closed.
>
> Give me a short snapshot, then ask me with multiple-choice buttons what I want to do next: add a feature, fix something, or run a health check.

> This is my current view of the Claude History Widget built with Scriptable on my Phone. It never displays anything until I click on it, when it says there is no info, it updates from Mac every 10 minutes. THat part is broken too.
>
> I"m not sure if these usage %ages are even accurate - showing over 100%?

Later instructions, in order:
> Fix it + relabel %

> I don't need to do anything - this fix is now live?

(with a screenshot of the large widget showing "1.4 sessions used · 2.7 unused · 2.0 h idle", "⚠︎ Mac · 34m ago")
> this is the result, i cant tell if your fix worked.

> Yes, add it as long as it results in a more accurate widget

> it says Phone · 2m ago now, write a handoff and update github

Rules carried over from earlier handoffs (still in force):
- Never write the "Claude Code-credentials" Keychain item or use the refresh token.
- Never get past claude.ai's Cloudflare check.
- Never ask Josh to paste keys into chat.
- Tests never touch real data files.
- Confirm before deleting, sending, publishing or spending.
- Never edit an old handoff.
- Plain, short language with no code in chat, and every decision as a multiple-choice question.

## Decisions
1. **Diagnosis: the Mac side was fine and the phone side was the gap.** The Mac wrote `history.json` every 10 minutes (seen at 23:40, 23:50), and it was uploaded to iCloud with no errors (checked with a Swift `ubiquitousItemIsUploaded` probe). The History script had no fallback: in a background widget run, if iCloud hadn't handed over the file, it showed "No Claude history yet" or blank. The Claude Usage script already had a saved copy for this case. (Claude)
2. **The over-100% numbers were correct, and only the label was confusing.** "Used" adds up every 5-hour session's gain today (4+10+18+96+28 = 156%). "Unused at reset" adds up the leftover in each session at its reset (96+90+82+4 = 272%). Josh chose to relabel ("Fix it + relabel %"). It now shows sessions: pct/100, one decimal under 10 ("1.6 sessions used", "2.7 unused at resets"). The live line in the chart stays in % because it's the current session going 0 to 100%. (Josh)
3. **Fix 1 (commit 92bc39f):** a saved copy on the phone, at `FileManager.local()` documents/`claude-history-cache.json`, outside iCloud. The widget uses the newer of the iCloud copy and the saved copy. The iCloud download is raced against `Timer.schedule` (5 s in a widget, 20 s in the app). The widget asks for a refresh every 10 minutes (was 30). The age text gets ⚠︎ past 30 minutes and shows days past 48 hours. The empty message now says to open the script once. (Claude, within Josh's "fix it")
4. **Fix 1 alone wasn't enough.** On the phone the widget showed data, but it was 34 minutes old ("⚠︎ Mac · 34m ago", 1.4 sessions, which was the ~23:20 version). The Mac had uploaded 23:30, 23:40 and 23:50 versions fine, and the phone's own `phone-reading.json` reached the Mac within minutes. So iCloud was slow in the Mac-to-phone direction only, which nothing on our side can force. (Claude)
5. **Fix 2 (commit d3cd86c): use the phone's own live reading for "right now".** Josh: "Yes, add it as long as it results in a more accurate widget". `withPhone(h, ph)` takes Claude Usage's `phone-reading.json` (source 'phone', session percent and resetsAt) when it's newer than the Mac's `generatedAt` and on the same day. It counts exactly like the Mac's `History.timeline` in Timeline.swift: in the same session, it adds the % gained since the Mac's last line point; in a new session, it adds all of its %. Same session means the window start (resetsAt minus 5 h) is no later than the Mac's last point plus 1 minute. The gain goes to the slot holding the phone reading. Slots from the session start to now become "active". The line gets the phone point, starting a new piece after a gap of over 20 minutes (the Mac's rule) or after a reset in between (its exact time isn't known). today.used and the last day of days[] go up by the gain, and the header says "Phone · Xm ago". The cached copy stays the Mac's unmerged data, and merging happens at render time. (Josh approved, Claude designed)
   - Rejected: adding the current session's resetsAt to history.json from the Mac. It would need a Mac rebuild, and inferring from the window start gave exact results in tests.
   - Rejected: guessing the old session's reset time and unused amount when a reset happened in between. It isn't knowable from the phone, so the line just starts a new piece and resets/unused are left alone.
6. **Known limits (accepted):** if a session reset in between, the phone can't see the old session's last minutes (127% vs the Mac's real 130% in the test) until the Mac's update arrives. If Claude Usage can't read claude.ai on the phone, the widget falls back to the Mac data. Just after midnight, the Mac's history is still yesterday's, so the widget shows yesterday (dated header) until the new day arrives. (Claude, stated to Josh)
7. **Shipping path:** the installed `Claude History.js` in Scriptable's iCloud folder is the repo file plus Scriptable's 3-line header. Writing it there syncs it to the phone, with no copy and paste needed. Josh asked "I don't need to do anything - this fix is now live?" The answer was: mostly, but opening Scriptable once forces the sync and seeds the saved copy. (Claude)
8. **The test scripts were saved into the repo** (`iphone/tests/`) with frozen fixtures, because the live data reset at midnight and broke three data-dependent checks. The fixtures hold usage numbers and times only. (Claude)

## Where everything is
Project root: `~/Library/Mobile Documents/com~apple~CloudDocs/01_ClaudeCoWork/Workspace/03_Projects/UsageBarApp`
- `iphone/ClaudeHistory.js`: the History widget source of truth. 14829 bytes, md5 85a4e5496913297a8751db9534a272fc (2026-11-25 23:58)
- `~/Library/Mobile Documents/iCloud~dk~simonbs~Scriptable/Documents/Claude History.js`: the installed copy (header + repo file). 14962 bytes, md5 611b990cfd2ee3f39d1133a51229df6c. Matches the repo below its first 3 lines (checked with diff).
- `iphone/tests/history-widget.test.mjs`: 13 fake-Scriptable checks (loading, saved copy, 5 s limit, broken files, all widget sizes, phone merge).
- `iphone/tests/history-phone-merge.test.mjs`: 7 accuracy checks for `withPhone` against the Mac's real totals.
- `iphone/tests/fixtures/history-2026-11-25-2350.json`, `phone-reading-2026-11-25-2354.json`: frozen real data (numbers and times only).
- `CHANGELOG.md`: two new top entries, "iPhone Claude History widget — 2026-11-26" and "— 2026-11-25".
- `README.md`: Claude History paragraph updated (saved copy, sessions meaning, phone reading).
- `CLAUDE.md`: Current state / Next step updated.
- Live data the widget reads, in `.../iCloud~dk~simonbs~Scriptable/Documents/UsageBarApp/`: `history.json` (Mac, every 10 min), `snapshot.json` (Mac), `phone-reading.json` and `key-status.json` (written by the phone's Claude Usage).
- On the phone only: Scriptable local documents/`claude-history-cache.json` (the saved copy).
- Mac side that writes history: `mac/App/UsageModel.swift` `publishHistory()` (about line 286), `mac/UsageCore/Sources/UsageCore/PhoneHistory.swift`, counting rules in `Timeline.swift` (`timeline`, `sessionLine`).
- Commits: 92bc39f (fix 1), d3cd86c (fix 2), plus this handoff's commit. Branch main, pushed to origin.
- Session: claude://claude.ai/epitaxy/local_6b894623-53a3-404a-83a4-e0faf3c74d43, id local_6b894623-53a3-404a-83a4-e0faf3c74d43. Remote Control is on, so it's also listed at claude.ai/code.
- Transcript: `~/.claude/projects/-Users-hotz-personal-Library-Mobile-Documents-com-apple-CloudDocs-01-ClaudeCoWork-Workspace-03-Projects-UsageBarApp/39d114c4-deee-41ca-a227-d75ddc8f0c1f.jsonl`
- Carries forward: handoff_2026-11-17_usagebarapp-test-crash-and-git-index.md (and the 0.11.1 handoff for app rules and builds).

## Verified vs not verified
Verified:
- On the phone, by Josh: the new script runs (screenshot showed "sessions used" and ⚠︎), and after fix 2 the header showed "Phone · 2m ago".
- The Mac uploads `history.json` and `snapshot.json` to iCloud with no errors (Swift resource-values probe, 23:55).
- The phone's `phone-reading.json` reached the Mac within minutes (modified 23:54, read at 23:55).
- 13/13 widget checks and 7/7 merge checks pass on the frozen fixtures (Node, run at 00:01).
- The merge equals the Mac's real total (158%) when the Mac is 5, 40 or 60 minutes behind in the same session.
- The installed Scriptable copy equals the repo file below the header (diff).
Not verified:
- That `Timer` fires inside a real Scriptable widget run (the 5 s limit was only tested in the fake). If it didn't fire, the race would still end when iCloud finishes.
- That the saved phone copy exists on the phone yet. It's created on the first successful run, and is likely there given the phone screenshots.
- How often iOS actually refreshes the widget. It asks for 10 minutes, and iOS decides.
- The midnight behaviour on the real phone.

## Chat-only content (verbatim)
Numbers given to Josh about today (2026-11-25), from the Mac's history.json at 23:40:
```
used 156% = 4 + 10 + 18 + 96 + 28 (current session)  -> about 1.6 sessions
unused at reset 272% = 96 + 90 + 82 + 4  (resets at 6:20 am, 12:30 pm, 5:30 pm, 10:30 pm ET)
7 days: 4.7 sessions used · 24 unused at resets · 9.0 h idle (room for ~1.8 more sessions)
```
By 23:50 today's total was 158%. Everything else (code, tests, changelog text) is saved in the repo.

## Methods
- Sessions label: `sessions(pct) = pct/100`, 1 decimal under 10, whole number at 10 or above.
- Merge accuracy test: the Mac's history is cut at minute X. The removed gain is the sum of rises between consecutive line points after X. Then a phone reading equal to the Mac's real later value is added, and the result is compared with the Mac's real today.used.
- Staleness: the age text is measured from `phoneAt` if merged, else `generatedAt`. ⚠︎ shows over 30 min.

## Open questions
- None from Josh are unanswered.
- Not raised with Josh (optional ideas): (a) just after midnight, start "today" from the phone reading alone instead of showing yesterday. (b) The top dot on the 7-day chart gets clipped when a day is the week's highest (seen on Wed in Josh's screenshot).

## Dead ends and do-not-do
- Don't expect the Mac to speed up iCloud delivery to the phone. Uploads were already done, and the delay is iOS pulling the file down.
- In Claude Code's sandbox, `$TMPDIR` changes when a command runs unsandboxed. Use the absolute scratchpad path for unsandboxed copies (first install attempt failed on this).
- Tests that read the live `history.json` break after midnight (it resets to 0). Use the fixtures.

## Loose ends and exposure
- `$TMPDIR/hist-test/` and the session scratchpad hold copies of the test scripts and data (usage numbers only). Temp folders clear themselves, and the durable copies are in `iphone/tests/`.
- The repo is private on GitHub. The fixtures show Josh's Claude usage percentages and times, nothing else.
- No secrets were pasted in this chat.

## Changed since the previous handoff
- Old: "Next: glance at login_renewals.log." New: closed by Josh (31 renewals with no failures).
- Old: the History widget was assumed fine. New: fixed as above.

## Provenance
- Transcript read with handoff-session `read_transcript.py`: 23 user/assistant messages, 2026-11-26 04:41 to 05:00 UTC, 5 tool blocks clipped at 4000, 0 unreadable lines. The whole chat was also in context.
- Step 0 skipped: Josh finished the task and asked for the handoff.
- Cold read: 9 of 9. Asked: why over 100%, what label is used now, where the saved copy lives, how the merge counts, why not add resetsAt on the Mac, what's not verified, how to run the tests, how the script gets to the phone, and what Josh said to approve fix 2. All are answered above.
