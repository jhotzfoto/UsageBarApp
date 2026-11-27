# Official tips for stretching Claude subscription usage, and timing work around resets (as of 2026-11-26)

Research notes. Official sources only for findings; secondary sources are flagged as such. Help center pages show only relative "updated" dates (e.g. "Updated over 3 weeks ago" as read on 2026-11-26), so exact page dates are unknown unless stated.

## What does Anthropic recommend to use limits efficiently (general / chat)?

### Takeaway
The official "Usage limit best practices" article focuses on fewer, better messages: plan, be specific, batch, reuse context via projects (cached), and watch Settings > Usage. A second article adds: turn off unneeded tools and connectors, start fresh instead of letting chats grow long, and remember model and effort choice affect usage.

### Cited Findings
- Listed factors that affect usage: message length, attachment size, current conversation length, tool usage (Research, web search), model choice, effort level, artifact creation and use, and multi-step tasks (running code, creating files, browsing). — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- Tips in that article: plan your conversations; be specific and concise; use memory and chat search instead of repeating background (paid plans); batch similar requests into one message; review the prompt before sending; use project knowledge bases (projects also offer a RAG mode for larger knowledge); monitor usage in Settings > Usage; upload core documents at the start of a project. — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- Caching: project content is cached and "counts less" when reused, but caches expire after inactivity, so the first message after a long break counts that content in full again. — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- Use-case tips: coding (give full environment context and complete relevant code in one message), writing (state requirements, audience and key points; send whole texts for editing at once), research (define the question early, give all data in one structured message). — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- "Tools and connectors are token-intensive", so turning off unneeded ones helps. — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- "Longer conversations that trigger automatic context management consume more of your usage limit." The article also advises removing project files you no longer use. — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Usage depends on "the features you use, which Claude model you're chatting with, and the effort level you've selected." — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- One shared pool: usage across "claude.ai, Claude Code, Claude Desktop" counts toward the same limit. Weekly limits apply across all models; "some plans also have a separate weekly limit for Fable." — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)

### Inferences
- The practical chat recipe from these two pages: one well-built message beats several short ones; put reusable reference material in a project and use it while the cache is warm; open a new chat rather than dragging a long one past automatic context management; keep only the connectors you need switched on; drop to a lighter model or lower effort for simple asks.

### Gaps
- The best-practices article body does not explicitly mention extended thinking, connectors or Cowork; those come from the second article or from Claude Code docs. A search snippet claimed related articles say "turn off extended thinking when it isn't needed" and "keep project instructions concise", but I did not see that wording on a fetched official page.
- No official numeric figures for how much a given model, effort level or connector costs in usage terms.

## Cowork-specific guidance: settings that affect usage and how to check usage

### Takeaway
Official Cowork guidance on usage is thin. Anthropic says everything counts toward plan limits, longer agentic tasks use more, and to check Settings > Usage. Connector advice ("token-intensive", turn off unused ones) is general, not Cowork-specific. Nothing official found on computer use vs connectors cost, plugin/skill overhead, or scheduled-task usage.

### Cited Findings
- "Everything you do with Claude counts toward your plan's usage limits." "Longer agentic tasks that search the web, run code, or create files generally use more than a quick question." "While the new experience rolls out, usage may be measured slightly differently for accounts that have it and accounts that don't." "Check your current usage in Settings > Usage." — [Claude Cowork and chat are one Claude](https://support.claude.com/articles/16761823)
- Team/Enterprise seat allowance "is shared with Claude chat and Cowork"; the Enterprise consumption guide "explains how consumption differs across Claude chat, Claude Code, and Cowork." — [Claude Code docs: Manage costs](https://code.claude.com/docs/en/costs)
- Scheduled tasks: "Scheduled tasks run remotely, so they run on their cadence" even when the computer is asleep or the app is closed, unless "Require this computer" is on (set when you pick a folder manually), in which case "the task runs only while your computer is awake and Claude Desktop is open." On Pro, Max and Ultra, tasks created on your computer "move to the cloud automatically." The article says nothing about usage cost. — [Schedule recurring tasks in Claude Cowork](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork)
- Cowork 5-hour limit was doubled from June 5 to August 5, 2026 (originally announced to end July 5, then extended); weekly limits unchanged. Ended; limits back to standard. — search-result snippet of [Claude Cowork June 2026 promotion](https://support.claude.com/en/articles/15400594-claude-cowork-june-2026-promotion) (direct fetch returned 404 on 2026-11-26); earlier end date reported by [The New Stack](https://thenewstack.io/anthropic-claude-cowork-promotion/) (secondary)
- Secondary only (not verified on an Anthropic page): the Pro plan card reportedly says "Claude Cowork consumes limits faster than Chat. For heavy usage, consider upgrading." — quoted by [developersdigest.tech](https://www.developersdigest.tech/blog/claude-cowork-vs-claude-code-2026)

### Inferences
- Each scheduled Cowork task presumably runs as its own session and draws on the same limits, so frequent schedules quietly eat the 5-hour and weekly budget. Not stated officially.
- Claude Code docs say idle scheduled tasks resend the full context each run (see next section); the same mechanism likely applies in Cowork, but that is not documented for Cowork.

### Gaps
- No official Cowork page found on: model/effort choice inside Cowork, plugin or skill overhead, computer use vs connector cost, or a Cowork-specific usage breakdown.
- Third-party claims that Cowork uses "5 to 20 times" more than chat could not be confirmed on any Anthropic page.

## Claude Code guidance: /usage, /context, /compact, /clear, model, effort, subagents, MCP

### Takeaway
The Claude Code "Manage costs" page is the most detailed official source. Key levers: `/usage` (now shows plan bars plus a per-skill/subagent/plugin/MCP breakdown with fix recommendations), `/clear` between unrelated tasks, `/compact` with focus instructions, Sonnet by default and Opus only for hard problems, lower `/effort`, deferred MCP tools plus disabling unused servers, short CLAUDE.md, and watching background token use (loops, scheduled tasks, idle check-ins).

### Cited Findings
- `/usage` for subscribers shows "plan usage bars, activity stats, and a usage breakdown"; the Session dollar figure is for API users and "isn't relevant for billing" on Pro/Max/Ultra. — [Manage costs](https://code.claude.com/docs/en/costs)
- Plan usage breakdown: attribution to "skills, subagents, plugins, and individual MCP servers", recommendation rows (e.g. "Trim ~/code/api/CLAUDE.md · 49k tokens per request", "Switch from max to high effort · /effort high", "Compact before you step away · run /compact"), and Loops rows for heavy `/loop` or scheduled tasks. Press `d`/`w` for 24 hours vs 7 days; press `f` to apply fixes (v2.1.305+). Figures come from local history only, "so usage from other devices or claude.ai is not included." — [Manage costs](https://code.claude.com/docs/en/costs)
- "Clear between tasks: Use `/clear` to start fresh when switching to unrelated work. Stale context wastes tokens on every subsequent message." Use `/rename` then `/resume` to return later. "`/compact Focus on code samples and API usage` tells Claude what to preserve." — [Manage costs](https://code.claude.com/docs/en/costs)
- `/compact` "reads the conversation it summarizes, so compacting a large context is itself a large request... `/clear` costs nothing." — [Manage costs](https://code.claude.com/docs/en/costs)
- Model: "Sonnet handles most coding tasks well and costs less than Opus. Reserve Opus for complex architectural decisions or multi-step reasoning." Use `/model`; set `model: haiku` for simple subagents. — [Manage costs](https://code.claude.com/docs/en/costs)
- Thinking: "Thinking tokens are billed as output tokens"; lower effort with `/effort` or in `/model`, or disable thinking in `/config`. "You can't turn off thinking on Opus 5.5, Sonnet 5.5, Haiku 5.5, or the Fable models." — [Manage costs](https://code.claude.com/docs/en/costs)
- MCP: tool definitions are "deferred by default, so only tool names and server instructions enter context"; run `/context` to see what's using space; prefer CLI tools (`gh`, `aws`...) and disable unused servers with `/mcp`. — [Manage costs](https://code.claude.com/docs/en/costs)
- CLAUDE.md "is loaded into context at session start"; move specialised instructions into skills (load on demand). "Aim to keep CLAUDE.md under 200 lines." — [Manage costs](https://code.claude.com/docs/en/costs)
- Subagents keep verbose output out of the main context, but "The subagent's own requests still draw on your usage." Agent teams use "approximately 7x more tokens than standard sessions when teammates run in plan mode." — [Manage costs](https://code.claude.com/docs/en/costs)
- Other habits: specific prompts ("Vague requests like 'improve this codebase' trigger broad scanning"), plan mode (Shift+Tab), Esc early / `/rewind`, give verification targets, test incrementally; hooks to pre-filter big outputs. — [Manage costs](https://code.claude.com/docs/en/costs)
- Why long sessions climb: full conversation resent each request; cache misses after a break longer than cache lifetime reprocess the whole context; session-scoped scheduled tasks fire "even while the session is idle, sending your full context each time"; cross-session messages; goal check-ins; subagents and workflows; compaction. Background: session recap, idle compaction and prompt suggestions use tokens (suggestions are skipped near the limit). — [Manage costs](https://code.claude.com/docs/en/costs)
- Hitting a limit: "You've hit your session limit" or weekly limit is shared across all models, so switching with `/model` won't help; after a model-specific limit (e.g. Opus), switching family does. — [Manage costs](https://code.claude.com/docs/en/costs)
- Auto-continue: "When a claude.ai usage limit stops Claude mid-task, Claude Code waits in the open session and continues the task on its own after the limit resets." On by default in interactive subscription sessions (v2.1.234+); status shows e.g. "Usage limit reached · limit resets 3:45pm"; stops after three automatic continuations; control via `/rate-limit-options` or `autoContinueAtUsageLimit`. If the Mac slept over ~30 minutes through the reset, press Enter to continue. — [Interactive mode: Wait for a usage limit to reset](https://code.claude.com/docs/en/interactive-mode)

### Inferences
- For the user's own setup: keep loops and scheduled checks lean (they resend context while idle), `/clear` rather than `/compact` when continuity isn't needed, and check `/usage` breakdown weekly for the biggest single drain.

### Gaps
- No official per-model multiplier against subscription limits (only "costs less").

## Timing: when windows start and reset, peak/off-peak, where reset times show

### Takeaway
Officially: the 5-hour window starts at your first message and resets in full five hours later; the weekly limit resets at a fixed day and time assigned to your account. A weekday peak-hour reduction (5 to 11 am PT) was announced in March 2026, then removed for Claude Code on Pro and Max on May 6, 2026. No current official off-peak bonus found as of 2026-11-26. Reset times appear in Settings > Usage and in Claude Code's `/usage` and limit messages.

### Cited Findings
- 5-hour window: "The period starts when you send your first message, and your limit resets in full five hours later." — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- "Verified Ultra accounts don't have a five-hour limit." — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work); also reported 2026-10-30 by [The New Stack](https://thenewstack.io/?p=22842406) (secondary)
- Weekly: "Weekly limits reset at a fixed time each week that is assigned to your account." "Your reset day and time stay the same regardless of when you start using Claude." — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Where to see it: Settings > Usage shows "Current session" and weekly usage and your next reset time; paid plans see progress bars "including when the weekly limit resets". — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work); [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- Claude Code limit messages show "when the window resets"; the wait line shows "limit resets 3:45pm". — [Manage costs](https://code.claude.com/docs/en/costs); [Interactive mode](https://code.claude.com/docs/en/interactive-mode)
- Peak hours (March 26, 2026): Anthropic adjusted 5-hour session limits for Free/Pro/Max during weekday peak hours 05:00 to 11:00 PT (13:00 to 19:00 GMT); weekly limits unchanged; ~7% of users affected. Source was an Anthropic engineer's post on X, reported by press, not a help-center page. — [The Register](https://www.theregister.com/2026/03/26/anthropic_tweaks_usage_limits), [TechRadar](https://www.techradar.com/ai-platforms-assistants/claude/claude-is-limiting-usage-more-aggressively-during-peak-hours-heres-what-changed) (secondary)
- May 6, 2026 (official): "we're doubling Claude Code's five-hour rate limits for Pro, Max, Team, and seat-based Enterprise plans" and "we're removing the peak hours limit reduction on Claude Code for Pro and Max accounts." — [Anthropic: Higher usage limits for Claude and a compute deal with SpaceX](https://www.anthropic.com/news/higher-limits-spacex)
- Claude Code weekly-limit promotion ran May 13 to September 13, 2026 (weekly limits 50% higher; 5-hour limits not affected). From September 14, 2026, "weekly limits in Claude Code are 25% higher than they were before the promotion" for Pro, Max, Ultra, Team and seat-based Enterprise. — [Claude Code May–August 2026 weekly limits promotion](https://support.claude.com/en/articles/15910845)
- Other 2026 promotions (all ended): March 2026 off-peak doubling (official page [14063676](https://support.claude.com/en/articles/14063676-claude-march-2026-usage-promotion) returned 404 on 2026-11-26; headline via [Yahoo Tech](https://tech.yahoo.com/articles/anthropic-doubling-claudes-usage-limits-163645201.html), secondary); Cowork 5-hour doubling June 5 to August 5, 2026 (see Cowork section); artifact promotion October 1 to 15, 2026 per search snippet of [Artifact usage promotion](https://support.claude.com/en/articles/17274727-artifact-usage-promotion) (not fetched).
- The current "How do usage and length limits work" page does not mention peak hours at all. — [How do usage and length limits work](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)

### Inferences
- Because the 5-hour window starts at the first message, a small "kick-off" message timed so the window resets right when heavy work begins can give two windows' worth of capacity in a longer stretch. This is a reasonable deduction from the official rule, not Anthropic advice.
- Peak 5 to 11 am PT = 8 am to 2 pm Eastern. Official sources say the reduction was removed for Claude Code on Pro and Max; whether it still applies to chat or Cowork after May 6 is not stated.
- The weekly reset day is fixed per account, so heavy work late in the week before the reset uses capacity that would otherwise go unused.

### Gaps
- No official page found confirming whether peak-hour reductions still apply to chat or Cowork after May 6, 2026.
- No official statement on how long the March off-peak promotion ran (page gone).
- No current (November 2026) promotion found.

## Extra usage (usage credits) as a safety net

### Takeaway
Pro, Max and Ultra subscribers can turn on usage credits in Settings > Usage; past the plan limit, requests switch to pay-as-you-go at standard API rates until a monthly spend limit or balance runs out. In Claude Code, `/usage-credits` opens the same settings.

### Cited Findings
- Eligible: "individuals subscribed to paid Claude plans (Pro, Max, and Ultra)". Turn on: Settings > Usage, switch on Usage credits, add a payment method, set a spending limit, buy credits, optional auto-reload. — [Extra usage for paid Claude plans](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- Price: "Usage credits are billed at standard API rates." — [Extra usage for paid Claude plans](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- Caps: monthly spend limit via "Adjust limit", or "Set to unlimited"; usage alerts as you approach limits; auto-reload buys more when balance falls below a threshold ("only available on the web"). — [Extra usage for paid Claude plans](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- Behaviour at the limit: "Your requests switch to pay-as-you-go pricing on usage credits and keep working" until the monthly spend limit or balance runs out. — [Extra usage for paid Claude plans](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- Expiry: "usage credits purchased on or after December 7, 2026 expire 12 months after the purchase date"; earlier purchases don't expire. Mobile: buy credits and set a limit in-app where in-app purchases are available. — [Extra usage for paid Claude plans](https://support.claude.com/en/articles/12429409-extra-usage-for-paid-claude-plans)
- Claude Code: `/usage-credits` opens Settings > Usage on claude.ai; `/usage` shows this month's spend vs limit (or "Unlimited"); when the spend limit is hit with credits left, Claude Code prompts to raise or remove it. Finishing a purchase via `/usage-credits` during an auto-continue wait makes Claude Code resume right away. — [Manage costs](https://code.claude.com/docs/en/costs); [Interactive mode](https://code.claude.com/docs/en/interactive-mode)

### Inferences
- Setting a modest monthly cap (rather than unlimited) gives a "pay instead of being blocked" option with bounded risk.

### Gaps
- No CAD pricing or currency information on the extra-usage page; it defers to the pricing page, which I did not check for CAD.
- The fetched summary named chat and Claude Code (and Research, Projects) as covered; whether Cowork usage draws on credits was not stated clearly in what I retrieved.
- No minimum or maximum purchase amounts listed.
