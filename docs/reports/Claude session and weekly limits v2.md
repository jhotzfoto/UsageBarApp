# Claude limits on Max: why your week runs out, and what to change

*v2, 26 Nov 2026. Plan: Max (was "Max 5x"), US$100/month. Times in ET.*

> ### At a glance
> - **The weekly limit is what stops you, not the 5-hour one.** Every message counts on both bars, and the weekly cap is set far below the week's 33.6 five-hour windows.
> - **Your rate: about 16% of the week per full session, so about 6 full sessions a week.** Trackers measure about 8% (12 sessions) for typical Max accounts. *(Estimate from your data.)*
> - **Why:** Cowork is 99% of your week and is the heaviest way to use Claude. Fable costs about 4x Sonnet. A weekly drain that other Max users have reported since mid-October is unexplained.
> - **Top 4 fixes:** Sonnet by default · connectors "On demand" · lower effort · short, tightly scoped Cowork tasks.
> - **Budget:** about **14% a day**. Checkpoints: **43% by Tue night, 71% by Thu night**. Resets **Sun 4:00 am**.
> - **This week:** 16% left, about one session, until Sun 4:00 am. Keep Friday light.

---

## 1. How the limits work

| Bar | Resets | What it means |
|---|---|---|
| **Session (5h)** | 5 h after your first message, in full | Caps your speed. You often end sessions with lots unused. |
| **Weekly · all models** | Fixed time per account: yours is **Sun 4:00 am** | Caps your total. This is the one you hit. |
| **Weekly · Fable** | Same weekly reset | A sub-cap **inside** the weekly bar, up to 50% of it. Filling it blocks only Fable. |

Sources: [usage limits](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work), [pricing](https://claude.com/pricing), [Fable on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan).

- **Both bars count the same usage.** Max promises "5x Pro usage every 5 hours and every week", so either bar can stop you. Anthropic never says word for word that each message counts on both, but nothing else fits the wording, and every user report agrees.
- **The weekly cap is lower on purpose.** Anthropic's product lead said (Oct 2026) the top plan was 20x Pro per 5 hours but about 10x per week. That's why "Max 20x" was renamed **Ultra** and "Max 5x" became **Max** on 30 Oct 2026 ([Overell](https://x.com/mboverell/status/2116221457252659275), [Claude](https://x.com/claudeai/status/2116220869479428500), both seen only as search snippets).
- **There's no official ratio for Max.** [Wokey](https://wokey.ai/claude-usage-limits), a third-party tracker that measured real accounts, found **about 12 full windows a week** (16 to 23 Nov 2026). Anthropic's 2025 guide gave Max US$100 users **15 to 35 h of Opus a week** ([TechCrunch](https://techcrunch.com/2025/07/28/anthropic-unveils-new-rate-limits-to-curb-claude-code-power-users/)). That was for older models.
- **What your Fable bar's 37% means is unclear.** One user reported a "Fable weekly 99%" reading ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). That's impossible if the bar measured the whole week, so it most likely shows a share of the Fable cap: **about 18.5 of your 84 points, roughly a fifth of your week**. If it is a share of the whole week instead, Fable was 37 points, close to half. *(Inference.)*

## 2. Your week, in numbers

Week began **Sun 22 Nov 4:00 am**. "Weekly" figures are estimates: session % × (84 ÷ 515 ≈ 0.163).

| Day | Session % used | Weekly that day | Running total | Even pace (14.3%/day) |
|---|---|---|---|---|
| Sun 22 | 74 | 12 | 12 | 14 |
| Mon 23 | 130 | 21 | 33 | 29 |
| Tue 24 | 40 | 7 | 40 | 43 |
| **Wed 25** | **159** | **26** | **66** | 57 |
| Thu 26 (to 6:41 pm) | 112 | 18 | **84** *(measured)* | 71 |

- You were on pace until **Wednesday, which cost more than 1.5 days' worth** and put you about 9 points ahead. Thursday added more.
- **About 57 h left with 16%:** roughly one full session for Friday and Saturday together.
- **The 5-hour limit isn't your problem.** On 25 Nov, about 2.7 sessions' worth went unused at resets.
- The Sunday 74 may include a little use from before 4:00 am, which would make the real cost a bit above 16%.

### Why 16% and not about 8%? *(All inference. These can overlap.)*

If both bars weighted every token the same way, heavier work would fill both faster but in step, and the ratio wouldn't change. A doubled ratio points to the bars or caps changing.

| Possible cause | Evidence |
|---|---|
| **The weekly drain on Max since about 17 Oct 2026** | Users report weekly rising faster than session: 94% weekly with session at 73% in under 48 h, 50% weekly in 1.5 to 2 days with no 5-hour limit hit, and about 14% weekly per full session. Your 16% fits that range. No staff reply as of 23 Nov ([#105240](https://github.com/anthropics/claude-code/issues/105240)). |
| **Cowork may miss Claude Code's boost** | Claude Code weekly limits are **permanently +25% since 14 Sep 2026** ([help](https://support.claude.com/en/articles/15910845)). If that covers only Claude Code, a 99%-Cowork week misses it, which alone moves about 8% to about 10%. Anthropic also warns usage "may be measured slightly differently" during the Cowork and chat merge ([help](https://support.claude.com/articles/16761823)). Wokey found one of three identical accounts about 20% lower. |
| **Fable** | It fills your week faster. It changes the *ratio* only if it counts differently on the two bars, and no source says it does. |
| **Measurement** | Adding up session gains from periodic readings can miss use just before a reset. That undercounts sessions and pushes the per-session figure up. |

**Cheap test:** log one Sonnet-only chat session and one Cowork session, then compare weekly points per session point. If they differ a lot, the product matters more than the model.

## 3. What makes a session expensive

Usage is counted in **tokens**, even though the help pages say "messages". Each request **re-sends the whole conversation plus every tool result**, so "a one-line question in a session that has been open all day still draws usage for the whole conversation" ([costs](https://code.claude.com/docs/en/costs)). Officially, "**Claude Code and Cowork sessions are significantly more token-intensive than chat**". Cowork's multi-step work and Skills also create "significant intermediate token usage that may not be visible to end users" ([consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)).

| Kind of use | Weight | Why |
|---|---|---|
| **Cowork tasks** · 99% of your week | 🔴 High | Every step is a new request carrying the growing context. Screenshots, file reads and connectors add to it, and tasks can run sub-agents in parallel ([Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)). |
| **Claude Code** · 1% | 🔴 High | Same loop. One debugging session "can consume more than a day of chat" ([costs](https://code.claude.com/docs/en/costs)). |
| **Research** | 🟠 Above chat | Runs on Opus 5.5 with "multiple searches that build on each other", and the results stay in the chat ([Research](https://support.claude.com/en/articles/11088861-use-research-on-claude)). |
| **Regular chat** | 🟢 Low | One request per reply. Cost grows with chat length, attachments and model ([best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)). |
| **Model** | Fable ≈ 2x Opus ≈ 4x Sonnet | API prices per million tokens in/out: Fable 5.2 $8/$40 · Opus 5.5 $4/$20 · Sonnet 5.5 $2/$10 · Haiku 5.5 $0.10/$0.50 ([pricing](https://platform.claude.com/docs/en/about-claude/pricing)). Anthropic rates Fable "Very High". Whether plan limits follow API prices isn't confirmed. |
| **Long chats** | Grows each message | The whole history is re-read every time. Automatic context management "consume[s] more of your usage limit" ([limits](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)). |
| **Connectors and tools** | Fixed cost per step | "Token-intensive". Use "On demand" once you have 10 or more ([connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities)). Browser control adds about 6,600 tokens per request before screenshots (API). |
| **Sub-agents** | Multiplies | Each "sends its own requests". Agent teams use "approximately 7x more tokens" in plan mode ([costs](https://code.claude.com/docs/en/costs)). |
| **Scheduled tasks** | Steady background draw | Run in the cloud even while your Mac sleeps ([schedule](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork)). In Claude Code they resend the full context each run. Cowork's cost per run isn't documented. |

- **These costs multiply.** A 40-step Fable task with a dozen connectors and a long thread pays Fable prices on every step's full context.
- **Breaks cost money.** Cached context is cheap, but after inactivity "your first message counts that content in full again" ([best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)). In Claude Code the cache lasts 1 h, and sub-agents' 5 min ([caching](https://code.claude.com/docs/en/prompt-caching)). Cowork's cache lifetime isn't published.
- **Watch for silent model switches.** Users report Fable bars filling without picking Fable, including desktop sessions jumping from Opus 5.5 to Fable 5.2 mid-turn on 20 Nov ([#105240](https://github.com/anthropics/claude-code/issues/105240)). **Check which model Cowork is actually on.**
- Claude Code at 1% shows UsageBarApp's own login renewals aren't a factor. *(Inference.)*

## 4. What to do

Cutting tokens helps **both** bars. Timing tricks mostly help only the 5-hour bar.

### Checklist, biggest payoff first

- [ ] **1. Sonnet 5.5 as your everyday model** in Cowork and chat. Opus only for hard reasoning, Fable only when needed. Check the model picker before big tasks. *Fable ≈ 4x Sonnet, and it also fills the Fable sub-cap.*
- [ ] **2. Settings > Connectors: "On demand"**, and turn off what you don't use. You have many connectors and plugins installed. *Anthropic's advice at 10+; this cost hits every step.*
- [ ] **3. Lower effort for routine work.** *"Higher effort uses more tokens", and thinking can't be turned off on current models ([limits](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)).*
- [ ] **4. Review scheduled tasks.** Run them less often, on Sonnet, tightly scoped, and pause any whose output you don't read. *They draw usage while you sleep (inferred for Cowork).*
- [ ] **5. New task per topic, and finish related work in one sitting.** *No re-reading old context, and no full price after a break.*
- [ ] **6. Word Cowork requests tightly** (see the table below). *Fewer steps means fewer full-context requests.*
- [ ] **7. Pace to about 14% of the week a day,** which for you is about 85 to 90% of one session. *At your rate, it's the only way the week lasts.*
- [ ] **8. Stuck late in the week? Use a Fable limit reset.** The Fable 5.2 launch gave Max subscribers 1 to 3, expiring **8 Mar 2027** ([promo](https://support.claude.com/en/articles/17506494)). *It returns the week's Fable usage and refills the 5-hour session ([limit reset](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)). That it also lowers the all-models bar is inferred.*
- [ ] **9. Turn on usage credits with a small monthly cap** as overflow, not a habit.

### How to word Cowork requests

Anthropic's tips: group related work into one task, use a new conversation for unrelated work, and say when you only want a quick answer, not a file ([Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)). "Vague requests ... trigger broad scanning" ([costs](https://code.claude.com/docs/en/costs)). *The rows about sub-agents and the browser are inferred, and nobody has confirmed that Cowork always obeys them.*

| ✗ Instead of | ✓ Try |
|---|---|
| "Look through my client stuff and tidy it up" | "In 05_Clients/Smith only, rename the 12 PDFs to YYYY-MM-DD_invoice.pdf. Don't open other folders." |
| "Can you check this?" | "Quick answer only, no file or report: is the total on this invoice correct?" |
| 3 tasks sent minutes apart | "In one task: 1) …, 2) …, 3) …. Then stop." |
| An open-ended goal | "First give me a 5-step plan and wait for my OK." |
| Letting it pick tools | "Use the QuickBooks connector and the attached file. Don't use the browser or screenshots." |
| A job that could fan out | "Do this yourself in one pass. Don't start sub-agents." |
| A new topic in an old thread | Open a new task and paste a 3-line summary of the old one. |

### When to run heavy work

| When | Do |
|---|---|
| **Tue night**, under 43%? | On pace. Over? Push big optional jobs back. |
| **Thu night**, under 71%? | Same check. |
| **Saturday** | Use leftover capacity on batch jobs and Research. Unused weekly capacity is lost at Sun 4:00 am. |
| **Within a day** | Start big Cowork jobs early in a fresh 5-hour window so they don't stall halfway. Work through them without long breaks so the context stays cached. |
| **Skip** | Starting the 5-hour clock early with a tiny message, and planning around peak hours. Neither helps the weekly bar. |

On peak hours: 5-hour limits were tighter on weekdays 5 to 11 am PT (8 am to 2 pm ET) from March 2026. That was removed for Claude Code on Pro and Max on 6 May 2026 ([Anthropic](https://www.anthropic.com/news/higher-limits-spacex)). Whether Cowork and chat still see it is undocumented, and it never affected the weekly limit ([TechRadar](https://www.techradar.com/ai-platforms-assistants/claude/claude-is-limiting-usage-more-aggressively-during-peak-hours-heres-what-changed)).

### How to watch usage

- **Settings > Usage** shows the session, weekly and Fable bars, the per-product breakdown and the next reset.
- **Claude Code `/usage`** breaks usage down by skill, sub-agent, plugin and connector, but only for Claude Code on that Mac, not Cowork or claude.ai ([costs](https://code.claude.com/docs/en/costs)).
- **Local token counters** show what was sent, not what was billed ([#105240](https://github.com/anthropics/claude-code/issues/105240)).
- **UsageBarApp idea:** a pace marker comparing weekly % used with % of the week gone. Thursday evening would have read **"84% used · 66% of week gone"**.

### Paying for more (USD, before tax)

| Option | Cost | Best when |
|---|---|---|
| **Usage credits** (Settings > Usage) | Standard API rates, up to a monthly cap you set ([credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)) | You run short only now and then |
| **Prepaid bundles** | $45 buys $50 · $200 buys $250 · $700 buys $1,000. Non-refundable ([bundles](https://support.claude.com/en/articles/14246112-buy-usage-bundles)). Bought on or after 7 Dec 2026, they expire after 12 months. | You top up regularly |
| **Ultra** | $200/month for "10x Pro usage every week", double Max's weekly, with no 5-hour limit. Prorated mid-cycle ([pricing](https://claude.com/pricing)). | You run short most weeks |

- **Rough maths:** Wokey estimates a Max week at **about US$844** of API-priced use. So one day's shortfall (about 14%) is **very roughly US$120** in credits, and Ultra's extra US$100 a month wins if you're short most weeks.
- **Caution:** one user's US$100 of credits lasted about 3 hours during the drain ([#105240](https://github.com/anthropics/claude-code/issues/105240)). Set a cap, and try the free fixes for a week or two first.
- **Canada:** no CAD prices are published. Web billing is presumably USD plus GST/HST, and iOS prices "may vary" ([Max plan](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)).

## 5. How solid this is

- **Official** (Anthropic help centre and docs): how sessions start, the fixed weekly reset, the shared pool across all products, the 50% Fable sub-cap, and what makes agent work heavy. The key claims were re-checked against the live pages on 26 Nov 2026.
- **Not official:** per-session ratios and the drain reports.
- **Reddit couldn't be read directly.** reddit.com was blocked for both the research tools and the built-in browser, so all "Reddit says" claims come second-hand, through GitHub issues, press and blogs. Treat them as user reports.
- **Model cost ratios use API prices as a stand-in,** because Anthropic doesn't publish how plan usage converts to tokens.

| Where sources disagree | Used here |
|---|---|
| **6 May 2026 changes:** some notes had only secondary sources | Anthropic's own post: Claude Code's 5-hour limits doubled and the peak-hour cut removed for Pro and Max ([news](https://www.anthropic.com/news/higher-limits-spacex)) |
| **Claude Code weekly boost:** [Techsy](https://techsy.io/en/blog/claude-2x-usage-limits-explained) says 13 May to 13 Jul or 19 Aug | Anthropic: 13 May to 13 Sep, then permanently +25% ([help](https://support.claude.com/en/articles/15910845)) |
| **End of the Cowork 5-hour doubling:** 5 Jul or 5 Aug 2026 | 5 Aug (extended), per Anthropic's page in search results. Weekly was unchanged either way. |
| **Fable on Pro:** the [launch post](https://www.anthropic.com/news/claude-fable-and-mythos-5-2) says included up to 50%, the help page says credits only | Unresolved. Doesn't affect Max. |
| **5-hour raise on 22 Sep 2026** | Third-party only ([Wokey](https://wokey.ai/claude-usage-limits)). Unconfirmed. |
| **Projects:** a blog warns against them | Anthropic: project content is cached and "counts less", but the cache expires after breaks |
| **Cowork "auto mode" costs more** | Seen only in a search snippet. Not used. |

**Biggest open question:** the Oct to Nov drain. Only users have documented it, Anthropic hasn't explained it, and support reportedly couldn't audit or restore usage ([#105240](https://github.com/anthropics/claude-code/issues/105240)). Your habits can't fix whatever part of your 16% it causes.

## Bottom line

**Think of your plan as about 6 full sessions to spend between Sunday 4:00 am resets.** The 5-hour bar just shows how fast you're spending. One heavy Cowork day like Wednesday costs more than 1.5 days of even pace. The savings are decided **before** a task starts: which model, which connectors are loaded, and how you word the request.

**Track your ratio.** If it drops toward 8% after moving routine work to Sonnet, the cause was settings and habits. If it stays near 16% on light, Sonnet-only weeks, it's the account-level drain. That's the evidence to send Anthropic support, and the point where Ultra or capped credits become a real decision.
