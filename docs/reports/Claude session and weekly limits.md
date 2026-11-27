# Cowork and Fable Drain Your Week First

On the Max plan, both the 5-hour session meter and the weekly meter count the same usage. The weekly meter is set well below the total of every 5-hour session in a week, so you can't max out every session. For you, the weekly limit is the one that runs out. Your own data shows about **5.2 full sessions' worth of use took 84% of the week**. That's an estimated **16% of the weekly limit per full session**, or about 6 full sessions a week. Third-party trackers measured about 8% per session (about 12 sessions a week) on Max in the same month. Your gap probably comes from three things together: an unexplained weekly drain that Max users have reported since mid-October 2026, Cowork-heavy use, and noise in how the sessions were added up. Nobody can pin down the exact cause from public sources. What you can control is what each step costs. **Cowork (99% of your week)** runs many model calls per task, and **Fable** is the priciest model, about 2x Opus and 4x Sonnet at API prices. Long chats, connectors, sub-agents and scheduled tasks all add to every call. The biggest wins come from four changes: use Sonnet by default, keep Cowork tasks short and tightly scoped, switch connectors to "On demand", and pace yourself to about one full session a day. Timing tricks around the 5-hour window don't help much, because the weekly limit is the one that stops you.

## Both meters count the same usage, and the weekly one is smaller

Anthropic's rules are simple. A 5-hour session **starts with your first message and resets in full five hours later**. The weekly limit resets at a **fixed time assigned to your account** ([How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)). Your reset is Sunday at 4:00 am ET. The Max plan promises "**5x Pro usage every 5 hours and every week**" ([claude.com/pricing](https://claude.com/pricing)), so both caps apply at the same time and either one can stop you. Anthropic never says word for word that every message counts on both meters. It's the only reading that fits the wording, though, and every community report agrees with it.

The catch is simple arithmetic. A week holds **33.6 five-hour windows**, and Anthropic deliberately sets the weekly cap below what those windows would add up to. Its subscriptions product lead explained this in October 2026: the top plan launched with only a 5-hour limit at 20x Pro, and when weekly limits were added, they were set at about **10x Pro per week**, so the "Max 20x" name stopped fitting ([Mike Overell on X, search snippet](https://x.com/mboverell/status/2116221457252659275)). That mismatch is why "Max 20x" was renamed "Ultra" on 30 October 2026 and "Max 5x" became just "Max" ([Claude on X, search snippet](https://x.com/claudeai/status/2116220869479428500)). Anthropic publishes no ratio for Max. A third-party tracker that measured real accounts in the week of 16 to 23 November 2026 found **about 12 full 5-hour windows per week on Max**, or roughly 8% of weekly per full window ([Wokey](https://wokey.ai/claude-usage-limits)). Back in 2025, when weekly caps arrived, Anthropic's own rough guide gave Max $100 users **15 to 35 hours of Opus a week** ([TechCrunch](https://techcrunch.com/2025/07/28/anthropic-unveils-new-rate-limits-to-curb-claude-code-power-users/)). That's far short of continuous use, though the models have changed since.

Fable sits inside the weekly limit, not beside it. On Max, Fable is "**included, up to half your weekly limit**" ([claude.com/pricing](https://claude.com/pricing)). Fable use draws from your regular weekly limit and uses it up faster than other models ([Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan)). So the "Weekly · Fable" bar is a sub-cap. Filling it blocks only Fable, but every Fable step also fills "Weekly · all models".

**Your Fable reading of 37%.** The official pages don't say whether the bar shows a share of the Fable cap or of the whole week. One user in the October to November drain thread reported a "Fable weekly 99%" reading ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). That's impossible if the bar measured the whole week, since Fable can use at most half of it. So the bar most likely shows a share of the Fable cap. This is an inference from one user report. If it's right, your 37% is **about 18.5 points of your 84%**, so Fable made up roughly a fifth of your week. If the other reading is right, Fable made up 37 points, which is close to half.

## Your own data: about 16% of the week per full session

The table uses your usage-tracker figures. The weekly column is an **estimate**: each day's session total multiplied by your average of 84 ÷ 515 ≈ 0.163. The "even pace" column is what lasting all 7 days would allow, about 14.3% a day. Your week began **Sunday 22 November at 4:00 am ET**.

| Day (your week) | Session % used (your data) | Weekly used that day (estimate) | Running total (estimate) | Even pace by end of day |
|---|---|---|---|---|
| Sun 22 Nov | 74 | 12 | 12 | 14 |
| Mon 23 Nov | 130 | 21 | 33 | 29 |
| Tue 24 Nov | 40 | 7 | 40 | 43 |
| Wed 25 Nov | 159 | 26 | 66 | 57 |
| Thu 26 Nov (to 6:41 pm) | 112 | 18 | 84 (measured) | 71 |

You stayed close to an even pace until Wednesday. That one 159% day put you about 9 points ahead of pace, and Thursday added to it. With **16% left and about 57 hours until Sunday 4:00 am**, you have roughly one full session's worth for Friday and Saturday together. Your days also often ended with lots of unused session capacity: on 25 November about 2.7 sessions' worth went unused. That confirms the 5-hour limit isn't what's stopping you. The Sunday figure of 74 may include a little use from before the 4:00 am reset, which would make the real per-session cost slightly higher than 16%.

**Why 16% and not 8%: likely causes, all inference.** First, if both meters counted every token the same way, the ratio would stay fixed whatever you did. A heavier model or a longer chat would fill both meters faster but in step. So a doubled ratio points to the meters or the caps changing, not just to heavier work. Four explanations fit, and they can overlap.

The first is the reported weekly drain on Max since about 17 October 2026. Users describe the weekly meter rising faster than the session meter. One reported 94% of weekly used with the session at 73% in under 48 hours. Another passed 50% of weekly in 1.5 to 2 days without hitting a single 5-hour limit. A third measured about 14% of weekly for one full session. As of 23 November, no Anthropic staff member had replied in that thread ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). Your 16% sits right in that range.

The second is how your use is spread across products. Anthropic made Claude Code's weekly limits **permanently 25% higher from 14 September 2026** ([Claude Code weekly limits promotion](https://support.claude.com/en/articles/15910845)). If that boost covers only Claude Code, a week that's 99% Cowork misses it. That alone would move about 8% to about 10% per session. Anthropic also warns that while the merged Cowork and chat experience rolls out, "usage may be measured slightly differently" between accounts ([Claude Cowork and chat are one Claude](https://support.claude.com/articles/16761823)). Separately, one analyst found one of three identical accounts about 20% lower ([Wokey](https://wokey.ai/claude-usage-limits)).

The third is Fable. It clearly speeds up how fast your week fills. It changes the ratio only if Fable counts differently on the two meters, and no source says it does.

The fourth is measurement. Adding up session gains from periodic readings can miss use between the last reading and a reset. That undercounts sessions and pushes the per-session figure up.

One cheap test is worth running: log one Sonnet-only chat session and one Cowork session, then compare the weekly points each costs per session point. If the ratios differ a lot, the product you use matters more than the model.

## Cowork steps, Fable and long context make each session cost more

Under the hood, usage is counted in tokens even though the help pages talk about "messages". Claude Code's docs say each request **re-sends the full conversation plus every tool result**, so "a one-line question in a session that has been open all day still draws usage for the whole conversation" ([Manage costs effectively](https://code.claude.com/docs/en/costs)). Agent products make that worse because one task is dozens of requests. Anthropic says plainly that "**Claude Code and Cowork sessions are significantly more token-intensive than chat**". It adds that Cowork's multi-step work and Skills "generate significant intermediate token usage that may not be visible to end users" ([Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)). That explains why your week is 99% Cowork. It doesn't mean Cowork is the wrong tool. It means every vague or wide-open Cowork task is costly.

| Kind of use | Why it costs what it does | How heavy (relative) |
|---|---|---|
| Cowork agent tasks | Each step is a new request carrying the whole growing context. Screenshots, file reads and app connections add more. It may run several sub-agents at once ([Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)) | Officially "higher intensity". For you it's 99% of the week |
| Claude Code | Same agent loop. Its own guide says one debugging session "can consume more than a day of chat" ([Manage costs](https://code.claude.com/docs/en/costs)) | Officially "higher intensity". For you it's 1% |
| Regular chat | One request per reply. Cost grows with chat length, attachments and model ([Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)) | Officially "lower intensity" |
| Research | Runs on Opus 5.5 and does "multiple searches that build on each other". The results stay in the chat as input ([Use research on Claude](https://support.claude.com/en/articles/11088861-use-research-on-claude)) | Faster than chat, per Anthropic |
| Model choice | API prices per million input/output tokens: Fable 5.2 $8/$40, Opus 5.5 $4/$20, Sonnet 5.5 $2/$10, Haiku 5.5 $0.10/$0.50 ([API pricing](https://platform.claude.com/docs/en/about-claude/pricing)). Anthropic rates Fable's consumption "Very High" | Fable about 2x Opus and 4x Sonnet, if plan limits follow API prices (not confirmed) |
| Long context | Every new message re-reads the whole history. Chats that trigger automatic context management "consume more of your usage limit" ([limits article](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)) | Cost per message keeps climbing as a chat grows |
| Connectors and tools | Anthropic calls them "token-intensive" and suggests "On demand" once you have 10 or more ([Use connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities)). On the API, browser control adds about 6,600 tokens per request before any screenshots ([API pricing](https://platform.claude.com/docs/en/about-claude/pricing)) | A fixed extra cost on every step |
| Sub-agents | Each one "sends its own requests" and still counts. Agent teams use "approximately 7x more tokens" when teammates run in plan mode ([Manage costs](https://code.claude.com/docs/en/costs)) | Multiplies whole conversations |
| Scheduled tasks | They run in the cloud on their schedule, even while your Mac sleeps ([Schedule recurring tasks](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork)). In Claude Code, scheduled tasks resend the full context each time they run | Steady background draw. Cowork's cost per run isn't documented |

These costs multiply rather than add. A 40-step Cowork task on Fable, with a dozen connectors loaded and a long thread behind it, pays the Fable price on every step's full context. A short, scoped task on Sonnet pays a fraction of that. Breaks also cost you. Saved (cached) context is cheap to re-read, but after a period of inactivity "your first message counts that content in full again" ([Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)). In Claude Code the main conversation's cache lasts an hour on a subscription, and sub-agents' caches last only five minutes ([How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)). Anthropic doesn't publish Cowork's cache lifetime. Users also report **silent model switches** that ran up Fable bars without anyone choosing Fable, including desktop sessions jumping from Opus 5.5 to Fable 5.2 mid-turn on 20 November ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). So it's worth checking which model Cowork is actually using. Claude Code at 1% also shows that UsageBarApp's own login renewals aren't a factor (inference).

## What to do, in order of payoff

The steps that shrink tokens help both meters. Timing tricks mostly help only the 5-hour meter. That's why tokens come first in this list.

| # | Do this | Why |
|---|---|---|
| 1 | **Set Sonnet 5.5 as your everyday model in Cowork and chat.** Switch to Opus only for hard reasoning and to Fable only when you need it. Check the model picker before each big task | Fable is about 4x Sonnet at API prices, and every Fable step also counts toward the Fable sub-cap |
| 2 | **Settings > Connectors: switch to "On demand"** and turn off the ones you don't use. Your setup has a large number of connectors and plugins installed | Anthropic's own advice once you have 10 or more connectors. It cuts a cost that applies to every step |
| 3 | **Lower the effort level for routine work** | "Higher effort uses more tokens", and on current models you can't turn thinking off, so effort is the setting to change ([limits article](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)) |
| 4 | **Review your scheduled tasks.** Run them less often, use Sonnet for them, scope them tightly, and pause any whose output you don't read | They draw from your week while you sleep (inferred for Cowork) |
| 5 | **Start a new task for each new topic and finish related work in one sitting** | Saves re-reading old context and avoids paying full price again after a break |
| 6 | **Word Cowork requests tightly** (see the next table) | Fewer steps and tools means fewer full-context requests |
| 7 | **Pace to about 14% of weekly a day**, which for you is about 85 to 90% of one session | At your ratio that is the only way the week lasts 7 days |
| 8 | **Use a Fable limit reset when you're stuck late in a week.** The Fable 5.2 launch gave Max subscribers 1 to 3, depending on how long they've subscribed, expiring 8 March 2027 ([Fable 5.2 launch promotion](https://support.claude.com/en/articles/17506494)) | It returns the weekly usage you spent on Fable and refills the 5-hour session ([What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)). That it also lowers the all-models bar is inferred, not stated |
| 9 | **Turn on usage credits with a small monthly cap** as an overflow, not a habit | You keep working past the limit with a bounded cost (see below) |

### How to word requests in Cowork

Anthropic's own Cowork tips are to group related work into one task, start a new conversation for unrelated work, and tell Claude "when you only need a quick answer, not a file or finished deliverable" ([Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)). Claude Code's docs add that "vague requests ... trigger broad scanning" ([Manage costs](https://code.claude.com/docs/en/costs)). The phrasings below apply those rules. The ones about sub-agents and the browser are inferred from how those features cost, and nobody has tested whether Cowork always follows such instructions.

| Instead of | Try |
|---|---|
| "Look through my client stuff and tidy it up" | "In the folder 05_Clients/Smith only, rename the 12 PDFs to YYYY-MM-DD_invoice.pdf. Don't open other folders." |
| "Can you check this?" (when you just want a yes or no) | "Quick answer only, no file or report: is the total on this invoice correct?" |
| Three separate tasks sent minutes apart | "In one task: 1) …, 2) …, 3) …. Then stop." |
| An open-ended goal | "First give me a 5-step plan and wait for my OK before doing anything." |
| Letting it pick tools | "Use the QuickBooks connector and the file I attached. Don't use the browser or take screenshots." |
| A job that could fan out | "Do this yourself in one pass. Don't start sub-agents." |
| Adding a new topic to an old thread | Open a new task and paste a 3-line summary of what matters from the old one |

### When to run heavy work

Your weekly reset is **Sunday 4:00 am ET**. Treat it as the real deadline. Check yourself mid-week. Even pace is about **43% by the end of Tuesday and about 71% by the end of Thursday**. If you're ahead, push big optional jobs back. If you're behind on Saturday, that's the time for big batch jobs and Research runs, because unused weekly capacity is lost at the reset.

Within a day, start a big Cowork job early in a fresh 5-hour window so it doesn't stall halfway. Then work through it without long breaks so the saved context stays cheap to re-read. The well-known trick of sending a small message to start the 5-hour clock early only helps the 5-hour meter, so it won't fix your problem.

Peak hours aren't worth planning around either. Anthropic briefly tightened 5-hour limits on weekdays from 5 to 11 am PT (8 am to 2 pm ET) in March 2026. It removed that for Claude Code on Pro and Max on 6 May 2026 ([Anthropic news](https://www.anthropic.com/news/higher-limits-spacex)). Whether Cowork or chat still sees it is undocumented, and it never touched the weekly limit ([TechRadar](https://www.techradar.com/ai-platforms-assistants/claude/claude-is-limiting-usage-more-aggressively-during-peak-hours-heres-what-changed)).

For this week, with about one session left, keep Friday to light Sonnet chat. Use a Fable reset or capped credits only if something urgent comes up before Sunday.

### How to watch usage

Settings > Usage shows the session bar, the weekly bar, the Fable bar, the per-product breakdown and the next reset time. In Claude Code, `/usage` shows a breakdown by skill, sub-agent, plugin and connector, but it covers only Claude Code use on that machine, not Cowork or claude.ai ([Manage costs](https://code.claude.com/docs/en/costs)). Local token counters show what your computer sent, not what the server counted ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). An idea for UsageBarApp: show a pace marker that compares weekly % used with % of the week gone. On Thursday evening that would have read "84% used, 66% of week gone".

### The paid safety net (all prices USD, before tax)

Usage credits switch on in Settings > Usage. Past the limit they bill at **standard API rates**, up to a monthly cap you set ([Manage usage credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)). Prepaid bundles give a discount: **US$45 buys US$50 of credits, US$200 buys US$250, and US$700 buys US$1,000**. They're non-refundable ([Buy usage bundles](https://support.claude.com/en/articles/14246112-buy-usage-bundles)). Credits bought on or after 7 December 2026 expire after 12 months.

**Ultra costs US$200 a month** for "10x Pro usage every week", which is double Max's weekly limit. Upgrading mid-cycle is prorated ([claude.com/pricing](https://claude.com/pricing)). One tracker estimates a Max week at **about US$844 of API-priced use** ([Wokey](https://wokey.ai/claude-usage-limits)). At that rate, one day's shortfall (about 14% of weekly) would cost very roughly US$120 in credits. So if you run short most weeks, Ultra's extra US$100 a month costs less than topping up with credits. If it happens only now and then, capped credits are cheaper. One warning from the drain thread: a user's US$100 credit purchase was used up in about 3 hours ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). Set a cap, and try the free changes for a week or two first.

Canadian prices aren't published. Web billing is presumably in USD plus GST/HST, and in-app prices on iOS "may vary" ([What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)).

## How solid the evidence is, and where sources disagree

The mechanics (how sessions start, the fixed weekly reset, the shared pool, the 50% Fable sub-cap, what makes agent work heavy) come from Anthropic's help centre and docs. The per-session ratios and drain reports don't. **Reddit couldn't be read directly.** Both the research tools and the built-in browser blocked reddit.com, so every "Reddit says" claim here comes second-hand, through GitHub issues, press articles and blogs that cite Reddit. Treat all community figures as user reports, not measurements Anthropic endorses. Anthropic doesn't publish how plan "usage" converts to tokens, so the model cost ratios above use API prices as a stand-in.

| Topic | What the sources say | What this report uses |
|---|---|---|
| 6 May 2026 changes | One set of notes had only secondary sources. Another found Anthropic's own post: Claude Code's 5-hour limits doubled and the peak-hour cut removed for Pro and Max | Anthropic's post ([Anthropic news](https://www.anthropic.com/news/higher-limits-spacex)) |
| Claude Code weekly boost | Techsy gave 13 May to 13 July or 19 August ([Techsy](https://techsy.io/en/blog/claude-2x-usage-limits-explained)). Anthropic's help page says 13 May to 13 September, then permanently 25% above the old base | Anthropic's help page ([promotion article](https://support.claude.com/en/articles/15910845)) |
| Cowork 5-hour doubling | Ended 5 July or 5 August 2026 | 5 August (extended), per Anthropic's page as shown in search results. Weekly limits were unchanged either way |
| Fable on Pro | The launch post says it's included up to 50%, the help article says credits only ([launch post](https://www.anthropic.com/news/claude-fable-and-mythos-5-2)) | Unresolved. It doesn't affect Max |
| 5-hour raise on 22 September 2026 | Reported only by third parties ([Wokey](https://wokey.ai/claude-usage-limits)) | Unconfirmed |
| Projects | One blog warns against them. Anthropic says project content is cached and "counts less" | Anthropic, with the warning that the cache expires after breaks |
| Cowork "auto mode" costs more | Appeared only in a search snippet, not on the live page | Not used |

The Oct to Nov 2026 drain is the biggest open question. It's documented only by users, Anthropic hasn't explained it, and support reportedly couldn't audit or restore usage ([GitHub #105240](https://github.com/anthropics/claude-code/issues/105240)). Any part of your 16% caused by it isn't something your habits can fix.

## Conclusion

The useful shift is to stop thinking of your plan as "sessions" and start treating it as about six full sessions to spend between one Sunday 4:00 am reset and the next. On that budget the 5-hour bar mostly just tells you how fast you're spending. Each 16-point full session is one-sixth of your week, so one heavy Cowork day like Wednesday costs more than a day and a half of even pace. The best savings come before a task starts: the model you pick, the connectors loaded and the wording of the request decide how many full-context steps Cowork takes.

Your measured ratio is also worth tracking in its own right. If it drops toward the trackers' 8% after you move routine work to Sonnet, the problem was mostly your settings and habits. If it stays near 16% even on light, Sonnet-only weeks, the cause is the account-level drain that other Max users report. That would be the evidence to send Anthropic support, and the point where Ultra or capped credits become a real decision.
