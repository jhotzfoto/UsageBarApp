# Community reports on Claude weekly limits (Reddit, GitHub, HN, blogs), 2026

**Read this first (method and caveats):**
- **Reddit could not be read directly.** Both web search and fetch refuse reddit.com for this research tool ("domains are not accessible to our user agent"). So the Reddit material below is second-hand: GitHub issues and press articles that quote or summarise r/ClaudeAI, r/ClaudeCode and r/claude, plus blogs that say they draw on Reddit. Where a blog says "Reddit users" but gives no link, it is marked **[unlinked Reddit claim]**.
- Everything here is **user reports or third-party estimates, not official Anthropic figures**, unless it is labelled as an Anthropic or staff statement.
- Plan names changed: several sources say on **2026-10-30 Max 5x was renamed "Max" and Max 20x was renamed "Ultra"** at the same prices ([Wokey](https://wokey.ai/claude-usage-limits); [ai-toolbox](https://www.ai-toolbox.co/claude-management-and-productivity/claude-usage-limits-2026)). Below, "Max 5x" also covers "Max ($100)" and "Max 20x" also covers "Ultra".
- Primary GitHub threads used: [#41930](https://github.com/anthropics/claude-code/issues/41930) (Apr 2026 drain, cites the r/ClaudeAI thread with 330+ comments) and [#105240](https://github.com/anthropics/claude-code/issues/105240) (Oct–Nov 2026 Max 5x drain).

## 1. How many full 5-hour sessions fit in a week? (5-hour vs weekly relationship)

### Takeaway
The spread is wide, but the best measured figure (Wokey, Nov 2026) is about **12 full 5-hour windows per week on Max 5x (about 8% of weekly per full window)**, about 13 on Pro, and only about **5.7 on Ultra/Max 20x (about 17–18% per window)**. Individual user reports range from roughly 7–14% of weekly per full session on Max 5x in normal times to 25–30% for a single heavy Opus task, and much higher during the drain bugs of April and October–November 2026.

### Cited Findings
**Measured / aggregated (third party, not official):**
- Wokey gateway measurement, week 2026-11-16 to 11-23: Pro ≈ 13 five-hour windows per week (one window ≈ $13 of API value), **Max 5x ≈ 12 windows** (≈ $70 each, weekly ≈ $844 / 100M non-cached tokens, 14 accounts), Team Premium ≈ 9.1, **Ultra (Max 20x) ≈ 5.7 windows** (≈ $275 each, weekly ≈ $1,570, 56 accounts). Ultra is ≈ 9.6× Pro weekly but ≈ 21× Pro per 5-hour window. Method: weekly-meter jumps of 10+ points on real subscription accounts, medians per account — [Wokey](https://wokey.ai/claude-usage-limits)
- Wokey also notes Anthropic's "20× Pro" for Max 20x applied to the 5-hour window, and says the pricing page "now says 10× Pro a week"; SemiAnalysis found one of three identical accounts about 20% lower, so A/B differences between accounts are possible — [Wokey](https://wokey.ai/claude-usage-limits)
- whizi.io (updated Oct 2026) says Anthropic defines the Max multipliers per session, with no published weekly multiple; its July 2025 estimates put Max 5x at ≈ 3.5× Pro weekly and Max 20x at ≈ 6× Pro weekly (Sonnet 4 hours) — [whizi.io](https://whizi.io/resources/claude-weekly-limit/). Note: this predates current models and the 2026 changes; it conflicts with blogs that list weekly as a flat 5×/20× ([ai-toolbox](https://www.ai-toolbox.co/claude-management-and-productivity/claude-usage-limits-2026)).

**Individual user reports (labelled by plan and date):**
- Max (tier not stated), 2026-04-01: "Weekly 31% from 3 sessions" (≈ 10% per session) — BODYPRINT in [GitHub #41930](https://github.com/anthropics/claude-code/issues/41930)
- **[unlinked Reddit claim]**, May 2026: a full 5-hour limit used to cost ≈ 11% of the weekly limit; now a single heavy task (long chat or Opus) takes 25–30% of weekly — [ROROSUKE LABO, note.com, 2026-05-17](https://note.com/rorosuke/n/n13bb93206897?hl=en)
- Max ($100), 2026-11-04: 5-hour at 100% while weekly at 14% (one full session ≈ 14%) — factomachines-afk in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max 5x, after a reset, late Oct 2026: same task used 17% of a 5-hour window (previously two windows), and 2 days used 8% of weekly — lucthesloth in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Not stated, 2026-10-28: 5-hour ~90% in about 1 hour, weekly 17% — survivaler049 in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max 5x, 2026-10-26 (support-confirmed): weekly 94% with 5-hour at 73%, in under 48 hours — Eth66 in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max 20x, 2026-10-28: weekly 61% with 5-hour 24% — Eth66 in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max 20x, (date unclear, 2026): 4% of weekly used 12% of the way into one session (implies one full session ≈ 33% of weekly) — reported second-hand, no link, via search summary of Cowork blogs ([fast.io](https://fast.io/resources/claude-rate-limits-guide/), [clickforest](https://www.clickforest.com/en/blog/claude-cowork-explained)); original post not found
- Ultra (ex-Max 20x), 2026-10-31: weekly lasting ≈ 4 days instead of 6–7 — sascha-schaath in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max 5x, 2026-10-28: weekly 97% by day 4, same workload as before — sllnnx in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max (tier not stated), 2026-11-03: weekly over 50% in 1.5–2 working days with no 5-hour limit hits — hpark122331 in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Max 20x, 2026-04-02: 2 sessions drained the 7-day limit in about 2 days (v2.1.88–89) — kryvel in [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Pro, 2026 (Cowork): one 5-hour Cowork session ≈ 15% of weekly — second-hand, no link ([fast.io](https://fast.io/resources/claude-rate-limits-guide/) / [clickforest](https://www.clickforest.com/en/blog/claude-cowork-explained) via search summary)

### Inferences
- On Max 5x, "one full 5-hour session ≈ 7–14% of weekly" is the most common range in normal periods (Wokey ≈ 8%, BODYPRINT ≈ 10%, factomachines-afk ≈ 14%), so roughly 7–12 full sessions a week. On Ultra/Max 20x, the 5-hour window is much bigger relative to the week (≈ 5–6 full windows a week).
- Two 2026 increases to the **5-hour** limits with no matching weekly increase (May 6 for Claude Code, Sept 22 for all paid plans, per [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached) and [Wokey](https://wokey.ai/claude-usage-limits)) would make each full session a bigger slice of the week. That fits users saying "it used to be ~11%, now one heavy task is 25–30%". This is an inference, not confirmed by Anthropic.
- Ratios from the drain-bug periods (April and Oct–Nov 2026) should not be treated as the normal ratio.

### Gaps
- No direct Reddit thread could be read, so the exact r/ClaudeAI posts with "one session = X% of weekly" for Max 5x could not be quoted or dated.
- No Pro-specific session-to-weekly user ratio was found other than Wokey's ≈ 13 windows and the second-hand Cowork 15% claim.
- Anthropic publishes no weekly token count or session-to-weekly ratio.

## 2. Cowork's usage versus chat and Claude Code

### Takeaway
Anthropic itself says Cowork uses limits faster than chat, and users and bloggers agree it is the heaviest surface after agentic Claude Code, because each step (sub-agents, tool calls, file reads/writes) costs tokens. Hard user-measured Cowork ratios are scarce and mostly second-hand.

### Cited Findings
- Anthropic help text (quoted): "Working on tasks with Cowork consumes more of your usage allocation than chatting with Claude" — quoted in [BetterClaw (pub. 2026-03-26, updated 2026-11-18)](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached); help center wording "consumes limits faster than Chat ... each step Claude takes uses tokens" quoted in [tokenrip (docs checked 2026-11-06)](https://tokenrip.com/blog/claude-cowork)
- Cowork shares the same plan usage as chat and Claude Code — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached); Anthropic: limits apply across Claude and Claude Code — [Anthropic Pro plan help](https://support.anthropic.com/en/articles/8324991-about-claude-s-pro-plan-usage)
- Blogger estimate (not measured): the "225+ messages" of a Max 5x window ≈ 10–20 substantial Cowork operations — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- One user's sum for a single Cowork presentation-building task ≈ $45 of underlying cost, about a fifth of a month of Max — second-hand via search summary of [fast.io](https://fast.io/resources/claude-rate-limits-guide/) / [clickforest](https://www.clickforest.com/en/blog/claude-cowork-explained); original not found
- Substack commenters (Pro): hit the limit after ~10 minutes and started hitting limits once they began using Cowork; "a single Cowork session burns usage fast" — [ruben.substack.com comments](https://ruben.substack.com/p/claude-computer/comments) (via search summary)
- Settings → Usage shows a per-surface breakdown (Claude Code / Chats / Cowork / Other / Fable), which users used to show which surface drained the week — Eth66 and Sarwarkhan6 in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- "Ghost" rate limit reports in Cowork: a Max user rate-limited on every Cowork action for four days with no recent use; another blocked at 16% quota, fixed by switching accounts (unlinked) — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- Cowork promotion: 5-hour limit for Cowork doubled from 2026-06-05, **weekly unchanged**; end date conflicts (July 5 vs Aug 5) — [mer.vin](https://mer.vin/2026/06/anthropic-doubles-claude-cowork-5-hour-limits-through-july-2026/), search summary of [fast.io](https://fast.io/resources/claude-rate-limits-guide/)
- tokenrip says Anthropic merged Cowork into chat in a 2026-09-16 announcement — [tokenrip](https://tokenrip.com/blog/claude-cowork) (single source, not verified)

### Inferences
- Because Cowork promotions raised only the 5-hour limit, heavy Cowork users would run into the weekly cap sooner relative to sessions.
- Cowork's cost per hour likely resembles agentic Claude Code more than chat (multi-step, tool-heavy), but no measured comparison was found.

### Gaps
- No measured, linked user report gives "one Cowork session = X% of weekly" on Max 5x.
- No Reddit thread specifically on Cowork weekly burn could be read.

## 3. Which workflows burn weekly usage fastest, and which tips work (agreed vs disputed)

### Takeaway
Most agreement: keep context short (fresh chats, /clear between tasks, /compact in long sessions), use Sonnet/Haiku for routine work and save Opus/Fable for hard work, turn off unneeded thinking and connectors, and keep sub-agents few. Disputed or weak: shifting work off-peak, upgrading plans or buying extra usage to "fix" fast drain, and rolling back versions. Fable models and silent model switches are reported as major hidden weekly drains.

### Cited Findings
**Workflows reported as heaviest:**
- Heavy Opus tasks and long conversations: 25–30% of weekly per task **[unlinked Reddit claim]** — [note.com, 2026-05-17](https://note.com/rorosuke/n/n13bb93206897?hl=en)
- Fable: Max includes Fable up to 50% of weekly usage; Pro uses credits — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached). User analysis found Fable weighted ≈ 5× Opus against limits (unconfirmed) — lucthesloth in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Silent model switches: Max 20x weekly went 0% → 88% in ~22 hours after "fable" sessions moved from Fable 5 to Fable 5.1 (output tokens per turn ≈ 783 → ≈ 1,596), GitHub issue #91623 — as reported by [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached); desktop sessions switched from Opus 5.5 to Fable 5.2 mid-turn on 2026-11-20, Fable weekly 99% with zero Fable requests in logs — Sarwarkhan6 in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Adaptive/extended thinking: **[unlinked Reddit quote]** a simple question with Thinking on used 65% then errored — [note.com](https://note.com/rorosuke/n/n13bb93206897?hl=en)
- Sub-agents and parallel terminals; hidden background calls from `/dream` and `/insights`; `--resume`/`--continue` breaking the prompt cache — user analysis (ArkNill and others) in [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Idle drain: usage debited while the PC was off (factomachines-afk), quota rising with no active work (#37436) — [#105240](https://github.com/anthropics/claude-code/issues/105240), [#41930](https://github.com/anthropics/claude-code/issues/41930)

**Tips with broad agreement:**
- Start new chats when changing topic; carry a short summary forward ("conversation reincarnation") — [note.com](https://note.com/rorosuke/n/n13bb93206897?hl=en), [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached), [tokenrip](https://tokenrip.com/blog/claude-cowork)
- `/clear` between tasks, `/compact` in long sessions, `/model opusplan` (Opus plans, Sonnet executes) — [ai-toolbox](https://www.ai-toolbox.co/claude-management-and-productivity/claude-usage-limits-2026); fresh sessions and `/clear` instead of `--resume` — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Use Sonnet/Haiku for routine work; reserve Opus for hard reasoning; turn off extended thinking where it doesn't help; disable unused tools and MCP connectors (each adds to the system prompt); attach files only when needed; batch corrections into one prompt — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached), [note.com](https://note.com/rorosuke/n/n13bb93206897?hl=en)
- Few sub-agents, one terminal, set effort explicitly per agent (default effort was reportedly changed to "high" in v2.1.117) — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Start heavy Cowork sessions right after a reset — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- Check Settings → Usage to see which meter (5-hour, weekly, Fable, per surface) is actually at 100% — [#105240](https://github.com/anthropics/claude-code/issues/105240)
- BetterClaw's claim that these tips stretch a 5-hour window by 30–60% is its own unverified estimate — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)

**Disputed or don't hold up:**
- "Switch to Haiku/Sonnet to save the week": it does reduce cost per turn, but tokn.watch notes it still spends the same all-models weekly bucket — [tokn.watch](https://tokn.watch/blog/claude-usage-limits/). (Fable is the exception with its own sub-cap — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached).)
- Shifting work off-peak: peak-hour throttling affects the **5-hour** limit only; users in #41930 called off-peak shifting "not a solution for professionals" — [#41930](https://github.com/anthropics/claude-code/issues/41930), [TechRadar](https://www.techradar.com/ai-platforms-assistants/claude/claude-is-limiting-usage-more-aggressively-during-peak-hours-heres-what-changed)
- Upgrading to Max 20x/Ultra during a drain bug "bought time but didn't fix the rate"; a $100 extra-usage purchase was used up in ~3 hours — Eth66, sascha-schaath in [#105240](https://github.com/anthropics/claude-code/issues/105240)
- Version rollback: some said rolling back to 2.0.61 fixed it (Jan 2026), others disagreed — [The Register, 2026-01-05](https://www.theregister.com/2026/01/05/claude_devs_usage_limits/); in April, downgrades or cache patches helped some but cache fixes alone didn't stop faster drain for others — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Local token counters (ccusage, etc.) show what the client sent, not how the server metered it — [#105240](https://github.com/anthropics/claude-code/issues/105240)
- `/limit-reset` (added 2026-09-03, per BetterClaw) reportedly clears the 5-hour limit once a week but **not** the weekly cap — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- Projects: note.com warns to "be wary of the Project feature", while BetterClaw recommends storing frequently used material in project knowledge — [note.com](https://note.com/rorosuke/n/n13bb93206897?hl=en) vs [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached) (conflicting advice)

### Inferences
- The tips that shrink context (fresh chats, /clear, fewer connectors, fewer sub-agents) are the most consistent across sources, and they cut weekly use as well as session use, because the weekly meter counts the same tokens.
- Timing tips (off-peak, starting after reset) mainly help the 5-hour limit, not the weekly one.

### Gaps
- No controlled user test was found comparing weekly use with connectors or extended thinking on vs off.
- Reddit vote counts or "most agreed" rankings could not be checked because Reddit was unreadable.

## 4. Limit changes, bugs, peak-time differences and Anthropic staff replies (2025–2026)

### Takeaway
2026 saw repeated changes: a holiday bonus ending (Jan), weekday peak-hour throttling of 5-hour limits (Mar), a confirmed cache/drain bug fixed in April, a Claude Code weekly boost (May–Sept) that ended as a net 17% cut, 5-hour increases (May, Sept), and a new unexplained drain on Max 5x/Ultra from mid-Oct 2026 with no staff reply on GitHub as of 2026-11-23.

### Cited Findings
**Timeline (official announcements as reported; user reports labelled):**
- 2025-07-28 / Aug 2025: weekly limits introduced, aimed at account sharing, reselling and 24/7 background use (predates current models) — [HN 44713754](https://news.ycombinator.com/item?id=44713754), [TechCrunch](https://techcrunch.com/2025/07/28/anthropic-unveils-new-rate-limits-to-curb-claude-code-power-users/)
- 2025-12-25 to 31: holiday 2× usage bonus; in Jan 2026 users on Reddit/Discord reported limits hit within an hour (Max) or 10–15 min (Sonnet); one claimed a ~60% cut from log analysis — [The Register, 2026-01-05](https://www.theregister.com/2026/01/05/claude_devs_usage_limits/)
- 2026-03-26: weekday peak-hour change, 5am–11am PT: 5-hour limits drain faster; "Your weekly limits remain unchanged"; "~7 percent of users will hit session limits they wouldn't have before" — Thariq Shihipar (Anthropic) on X, via [TechRadar](https://www.techradar.com/ai-platforms-assistants/claude/claude-is-limiting-usage-more-aggressively-during-peak-hours-heres-what-changed) (search summary) and [#41930](https://github.com/anthropics/claude-code/issues/41930)
- 2026-03-23 to 04-24: widespread drain across Pro, Max 5x, Max 20x (e.g. Max 20x 5-hour session gone in 19 min, cited from r/ClaudeAI; one prompt = 7% of a Max 5x 5-hour window). Causes raised: peak throttling, 2× off-peak promo expiry on Mar 28, prompt-cache bugs, `--resume` bugs — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- 2026-05-06: 5-hour limits on Claude Code (and Cowork) doubled, peak throttle removed — [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- 2026-05-13 to 09-13: Claude Code weekly limits +50% (5-hour not affected), extended several times — [HN 48883064](https://news.ycombinator.com/item?id=48883064), [HN 49348751](https://news.ycombinator.com/item?id=49348751), [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- 2026-06-05: Cowork 5-hour limit doubled, weekly unchanged (end date disputed) — [mer.vin](https://mer.vin/2026/06/anthropic-doubles-claude-cowork-5-hour-limits-through-july-2026/)
- 2026-07-07: Fable 5 removed from plan weekly limits, usable via credits — [HN 48751978](https://news.ycombinator.com/item?id=48751978)
- 2026-09-14: Claude Code weekly limits permanently +25% over the old base, i.e. a 17% cut from the boosted 150% (commenters kedihacker, gs17 explained the maths); posted by @ClaudeDevs, no named staff in the thread — [HN 49491631](https://news.ycombinator.com/item?id=49491631)
- 2026-09-22: 5-hour limits raised on Pro, Max, Team (no numbers, weekly not mentioned); Opus 5.5 launched; SemiAnalysis measured ≈ 20% higher on Max, ≈ 50% higher on Pro — [Wokey](https://wokey.ai/claude-usage-limits), [BetterClaw](https://www.betterclaw.io/blog/claude-cowork-rate-limit-reached)
- 2026-10-30: Max 5x → "Max", Max 20x → "Ultra"; pricing page reportedly says Ultra is 10× Pro per week — [Wokey](https://wokey.ai/claude-usage-limits)
- 2026-10-17 onward: Max 5x/Ultra users report weekly limits gone in 2–4 days with the same workloads; suspected metering/cache-weighting change, Fable weighting, plan mismatch; support could not audit or restore usage — [#105240](https://github.com/anthropics/claude-code/issues/105240)
- 2026-11 (latest week): Wokey shows Pro and Ultra unchanged, Team plans up ≈ 27–35% in tokens ("rechecking") — [Wokey](https://wokey.ai/claude-usage-limits)

**Anthropic staff replies found:**
- Thariq Shihipar: confirmed peak-hour 5-hour throttling (X, 2026-03-26); said the team is "actively looking into" the cache issue (2026-03-31) — [#41930](https://github.com/anthropics/claude-code/issues/41930), [TechRadar](https://www.techradar.com/ai-platforms-assistants/claude/claude-is-limiting-usage-more-aggressively-during-peak-hours-heres-what-changed)
- Lydia Hallie (product lead): acknowledged the drain on X (2026-03-31) — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Anthropic's Reddit account called the drain "top priority" (2026-03-31), as reported in the GitHub issue; the Reddit post itself could not be read — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- bcherny (Anthropic collaborator on GitHub): "we have root caused and fixed this" (2026-04-24), linking a post-mortem (anthropic.com/engineering/april-23-postmortem, not verified) — [#41930](https://github.com/anthropics/claude-code/issues/41930)
- Unnamed Anthropic representative (Jan 2026): reduction claims "unfounded", complaints due to the holiday bonus ending; no token-usage flaw found — [The Register](https://www.theregister.com/2026/01/05/claude_devs_usage_limits/)
- **No staff reply** in the Oct–Nov 2026 Max 5x drain issue as of 2026-11-23 — [#105240](https://github.com/anthropics/claude-code/issues/105240)

### Inferences
- Peak-hour throttling is a 5-hour-only effect per Anthropic, so it should not change weekly totals, only how fast you reach the 5-hour wall.
- Periods of "my week vanished" reports cluster around model launches and promo endings (Opus 4.7 ~Apr 16, promo end Sept 13, Fable 5.x switches in Oct–Nov), so users comparing ratios should note the date.

### Gaps
- The April 23 post-mortem's contents were not checked.
- No Anthropic statement was found explaining the Oct–Nov 2026 Max 5x/Ultra weekly drain.
- Reddit megathreads (dates, upvotes, staff flair replies) could not be read directly; staff replies on Reddit are known only through GitHub and press quotes.
