# What makes some Claude sessions use far more of the 5-hour and weekly limits (as of 2026-11-26)

Research notes. Sources fetched 2026-11-26. Most help-center pages show only relative dates ("Updated over a week ago"), so exact publication dates are unknown unless stated. "Official" = Anthropic help center (support.claude.com), Claude Code docs (code.claude.com), or Claude API docs (platform.claude.com). "Inference" = my reasoning from those sources.

---

## Q1. Is usage measured in tokens (input + output, including re-sent history and tool results) rather than messages? What does Anthropic say about long conversations, long context, attachments and project knowledge?

### Takeaway
Anthropic's consumer help pages still describe limits in terms of "messages" and time, but every factor they list is a token driver. The Claude Code docs say outright that each request re-sends the full conversation and tool results and that this counts against plan limits, at the cached rate when the cache is warm. Long conversations, big attachments, project files and automatic context management (compaction) all cost more.

### Cited findings
- The general limits article says limits control "how many messages you can send to Claude, or how long you can work with Claude Code". It does not explain limits in tokens. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Same article: "Your usage is affected by several factors, including the length and complexity of your conversations, the features you use, which Claude model you're chatting with, and the effort level you've selected." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Same article: "Longer conversations that trigger automatic context management consume more of your usage limit." Claude "summarizes earlier messages" as the conversation nears the context limit, when code execution is on. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- One shared pool: usage across "claude.ai, Claude Code, Claude Desktop" counts toward the same limit. Paid plans have a 5-hour session limit that starts with your first message, plus weekly limits. "Weekly limits apply across all models, and some plans also have a separate weekly limit for Fable." Verified Ultra accounts have no 5-hour limit. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- The best-practices article lists these "additional factors that affect your usage limits": "Message length", "File attachment size", "Current conversation length", "Tool usage (e.g., Research, web search)", "Model choice", "Effort level", "Artifact creation and usage", and "Multi-step tasks, like running code, creating files, or browsing websites". — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- Projects: "Content in projects is cached and counts less against your limits when reused." But "Caches expire after a period of inactivity" and "If you come back to a project after a long break, your first message counts that content in full again." — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- The usage-credits article says "Documents stored in project files count toward your context when used in conversations". Credits apply to "all tokens processed, including project content", and the article advises: "Begin fresh chats for new topics to minimize the size of your context window." — [Manage usage credits for paid Claude plans](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)
- Claude Code, in "Why usage climbs in a long session", which is about plan limits: "Claude Code sends your full conversation with every request, and each time Claude uses tools it sends another request carrying that batch of tool results. With prompt caching, Claude Code re-reads that history at the cached token rate, so a one-line question in a session that has been open all day still draws usage for the whole conversation." — [Manage costs effectively (Claude Code docs)](https://code.claude.com/docs/en/costs)
- "Token costs scale with context size: the more context Claude processes, the more tokens you use." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- How caching works: "The model doesn't remember anything between requests, so Claude Code re-sends the full context: the system prompt, your project context, every prior message and tool result, and your new message." — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- For Enterprise seats, among the parts of each turn, "the first item grows the fastest. This is where both cost and context limits originate." CLAUDE.md "is prepended to every turn". — [Models, usage, and limits in Claude Code (dated 2026-10-27)](https://support.claude.com/en/articles/14552983-models-usage-and-limits-in-claude-code)
- Context windows: newer paid-plan models support "up to a 1M token context window"; others support 500K or 200K. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Tokenizer, API docs: "Claude 4.7 and later models ... use a newer tokenizer ... [that] produces approximately 30% more tokens for the same text." — [Pricing (Claude API docs)](https://platform.claude.com/docs/en/about-claude/pricing)
- Usage beyond the plan (usage credits) "are billed at standard API rates". — [Manage usage credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)

### Inferences
- In practice usage is token-based, even though the consumer pages talk about "messages". Each model call is billed on its whole input (system prompt + tools + history + tool results + attachments) plus output. Once you are over the plan, credits are billed in API tokens. In Claude Code, the docs tie plan-limit draw directly to re-sent context.
- Cost per message rises roughly with conversation length. Message 50 of a long chat re-sends everything before it, even when cached reads are cheap.
- A cold cache is the costly case. Inside the cache lifetime, re-sent history is cheap. After a break, the first message pays for the full context again (stated for projects and for Claude Code).

### Gaps
- Anthropic does not publish how plan-limit "units" map to tokens, or whether plan limits weight input, output, cache reads and cache writes the same way API prices do. The Claude Code docs say re-reads count "at the cached token rate", which suggests the weighting follows API prices, but there is no explicit formula.
- No official statement says whether claude.ai chat (outside Claude Code) uses a 5-minute or 1-hour cache.

---

## Q2. How does model choice (Fable 5.2, Opus 5.5, Sonnet 5.5, Haiku 5.5) affect usage per message?

### Takeaway
It has a large effect. Anthropic says officially that Opus costs "several times more per turn than Sonnet, and Sonnet more than Haiku", and ranks Fable as "Very High" consumption. API list prices give the ratios: Fable 5.2 is 2x Opus 5.5, Opus 5.5 is 2x Sonnet 5.5, and Sonnet 5.5 is 20x Haiku 5.5 (for prompts up to 100K tokens). Some plans also have a separate weekly Fable limit.

### Cited findings
- "Opus costs several times more per turn than Sonnet, and Sonnet more than Haiku." Opus "uses meaningfully more of your quota". The article is dated 2026-10-27 and covers Enterprise seats and API keys. — [Models, usage, and limits in Claude Code](https://support.claude.com/en/articles/14552983-models-usage-and-limits-in-claude-code)
- Consumption tiers in the Enterprise guide: Fable "Very High", Opus "High", Sonnet "Moderate", Haiku "Low". — [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)
- "Weekly limits apply across all models, and some plans also have a separate weekly limit for Fable." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Haiku and recent Sonnet models offer "lower token costs than Opus models". — [Manage usage credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)
- API list prices per million tokens (input / output / cache hit): Fable 5.2 $8 / $40 / $0.20. Opus 5.5 $4 / $20 / $0.20. Sonnet 5.5 $2 / $10 / $0.10. Haiku 5.5 $0.10 / $0.50 / $0.01 for prompts up to 100K tokens, and $0.50 / $2.50 / $0.05 above that. — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- Cache-hit multipliers: Fable 5.2 0.025x, Opus 5.5 and Sonnet 5.5 0.05x, other models 0.1x of base input. — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- Fast mode runs at premium prices: Fable 5.2 $16 / $80 and Opus 5.5 $8 / $40, which is 2x standard. — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- Claude Code: "Sonnet handles most coding tasks well and costs less than Opus. Reserve Opus for complex architectural decisions or multi-step reasoning." A switch to Opus "also applies to the subagents that inherit your session's model". — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Session and weekly limits are "shared across all models", so switching models does not restore access. After a model-specific "You've hit your Opus limit" message, switching to another family does let you keep working. — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Switching models mid-session also costs a full uncached re-read: "Each model has its own cache." — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- Research "runs on Claude Opus 5.5 and falls back to Claude Opus 4.8 when needed." — [Use research on Claude](https://support.claude.com/en/articles/11088861-use-research-on-claude)

### Inferences
- If plan usage is weighted like API prices (not confirmed), the same work costs about 2x on Fable 5.2 compared with Opus 5.5, 4x compared with Sonnet 5.5, and roughly 80x compared with Haiku 5.5 on short prompts. The "several times more per turn" wording fits this.
- Model choice multiplies every other factor. A long agentic session on Fable or Opus stacks the model multiplier on top of the context multiplier.

### Gaps
- No official multiplier for how each model draws on subscription limits (Pro/Max/Ultra). The API ratios above are a proxy, not a stated plan rule.
- No public number for the separate Fable weekly limit, or for which plans have one.

---

## Q3. How do extended thinking/effort, web search, Research, computer use (screenshots), connectors/MCP tool definitions and sub-agents affect consumption?

### Takeaway
All of them add tokens. Effort/thinking adds output tokens, the priciest kind. Web search and Research add large search results as input and run many calls. Computer and browser use add several thousand tokens of tool definitions per request, plus a screenshot image on most steps. Connectors are "token-intensive". Each sub-agent or teammate is a separate full conversation drawing on the same limit. Agent teams in plan mode use "approximately 7x more tokens" than a standard session.

### Cited findings

**Effort / extended thinking**
- "Higher effort uses more tokens." The article advises: "Choose a lower effort level for routine tasks." Thinking is always on for models such as Opus 5.5 and Sonnet 5.5, so effort is the lever. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work); [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- "Thinking tokens are billed as output tokens, and the default budget can be tens of thousands of tokens per request depending on the model." "You can't turn off thinking on Opus 5.5, Sonnet 5.5, Haiku 5.5, or the Fable models." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- "higher effort levels consume more tokens than lower ones." Max effort is reserved for the most demanding tasks. — [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)
- Changing effort mid-session keeps the cache on Fable 5.1 and later, Opus 5.5, Sonnet 5.5 and Haiku 5.5 with a subscription. On most other models it forces a full uncached re-read. — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)

**Web search and Research**
- "Tool usage (e.g., Research, web search)" is listed as a usage factor. — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- "Research is subject to the same limits as standard Claude conversations." "research sessions can use up your limits faster due to Claude retrieving multiple sources" and "providing comprehensive responses". Research "runs multiple searches that build on each other". — [Use research on Claude](https://support.claude.com/en/articles/11088861-use-research-on-claude)
- "Research sessions may consume tokens more quickly due to multiple searches and comprehensive analysis." — [Manage usage credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)
- API docs: "Search results count as input tokens, both while Claude keeps searching within a turn and in later conversation turns." On the API, web search also costs $10 per 1,000 searches. Typical fetched-content sizes: average webpage ~2,500 tokens, large docs page ~25,000, research-paper PDF ~125,000. — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)

**Computer use / browser use / screenshots**
- API docs: declaring the computer-use toolset "adds about 4,500 input tokens to a request". The browser-use toolset "adds about 6,600 input tokens". On top of that come "Screenshot and zoom images returned in tool results, billed as image input" and, for the browser, text results such as "accessibility trees, page text, and console or network entries". — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- Claude Code: when images pile up past request limits, Claude Code drops a batch of old images, and "the next request reprocesses the conversation from the earliest of those messages onward" (a cache miss). — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- "Multi-step tasks, like running code, creating files, or browsing websites" is listed as a usage factor. — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)

**Connectors / MCP tool definitions**
- "Tools and connectors are token-intensive, so managing them helps both maximize your available context window" and optimize usage limits. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- "If you have 10 or more connectors active, consider switching to On demand to give your conversations more room." Auto is the default. — [Use connectors to extend Claude's capabilities](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities)
- Claude Code: "MCP tool definitions are deferred by default, so only tool names and server instructions enter context until Claude uses a specific tool." CLI tools such as `gh` "are still more context-efficient than MCP servers because they don't add any per-tool listing." The docs advise disabling unused servers via `/mcp`. — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Tool definitions sit in the system-prompt layer, so when tool search is off, adding a tool definition invalidates the whole cache. — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- API: tool use adds a tool-use system prompt (286 tokens on Opus 5.5, Sonnet 5.5 and Haiku 5.5) plus every tool's name, description and schema, plus tool_use and tool_result blocks. — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- In `/usage`, Claude Code's plan breakdown attributes recent usage "to skills, subagents, plugins, and individual MCP servers, each shown as a percentage of the total." — [Manage costs effectively](https://code.claude.com/docs/en/costs)

**Sub-agents / parallel agents**
- "every subagent, and every agent a dynamic workflow spawns, sends its own requests on top of the main conversation's." "The subagent's own requests still draw on your usage." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- "Agent teams use approximately 7x more tokens than standard sessions when teammates run in plan mode, because each teammate maintains its own context window and runs as a separate Claude instance." "Token usage scales with the number of active teammates and how long each one runs." "Each active teammate continues consuming tokens until it exits." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- A subagent's first request does not read the parent's cache. Subagents get a 5-minute cache TTL even on a subscription, while the main conversation gets 1 hour. Forks do inherit the parent's cache. — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- Cowork: "For complex tasks, Claude may coordinate multiple sub-agents working simultaneously." — [Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)

### Inferences
- Rough order of these features by impact (inference, not an official ranking): (1) parallel sub-agents and teams, which multiply whole conversations, about 7x for teams in plan mode; (2) Research and heavy web search/fetch, many calls carrying large results; (3) computer and browser use, thousands of definition tokens per call plus a screenshot on most steps, over many steps; (4) high or max effort, extra output tokens on every turn; (5) many connectors loaded up front.
- Delegating to a subagent saves context in the main conversation but does not save plan usage overall. The docs say plainly that subagent requests still count.

### Gaps
- No official token count per screenshot in Cowork or Claude in Chrome. The API docs point to image-size rules but give no consumer-product figure.
- I could not confirm how Cowork or claude.ai load connector tool definitions internally (deferred or up front) beyond the "Auto" and "On demand" setting.
- No figure for how much Research uses per run compared with a normal chat.

---

## Q4. Why are agentic products (Cowork, Claude Code) heavier than chat? Any official statements on Cowork using more of the limit?

### Takeaway
Officially yes, for both. Anthropic says "Claude Code and Cowork sessions are significantly more token-intensive than chat", and that "A single Cowork task or Claude Code debug session can consume many more tokens than chat." The reasons it gives: many steps per task ("Each step Claude takes uses tokens"), system prompts, file context, tool calls, multi-turn reasoning, Skills, and "significant intermediate token usage that may not be visible to end users."

### Cited findings
- Chat: "Lower intensity ... Standard back-and-forth conversation, summarization, drafting, and Q&A." Usage "scales with message length and conversation history". — [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)
- Claude Code: "Higher intensity. Each coding session includes system prompts, file context, tool calls, and multi-turn reasoning." — [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)
- Cowork: "Higher intensity. Agentic workflows, multi-step task execution, and Skills generate significant intermediate token usage that may not be visible to end users." — [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)
- "Claude Code and Cowork sessions are significantly more token-intensive than chat." "A single Cowork task or Claude Code debug session can consume many more tokens than chat." — [Claude Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide)
- Cowork help: "Multi-step tasks, like ones that run code, create files, or use your connected apps and browser, use more of your usage than a quick question. Each step Claude takes uses tokens." — [Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)
- Cowork tips: "Grouping related work into one task instead of several." "Starting a new conversation for unrelated work, so Claude isn't carrying extra context." "Telling Claude when you only need a quick answer, not a file or finished deliverable." — [Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)
- Search snippets of other versions of the Cowork article said: "Working on tasks with Cowork consumes more of your usage allocation than chatting with Claude. This is because complex, multi-step tasks are compute-intensive and require more tokens to execute". One version also said auto mode consumes more of the limit than other modes. These were **search-snippet text only**. The live page I fetched did not contain the auto-mode statement, so treat it as unverified or possibly from an older version. — [Get started with Claude Cowork (search result)](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)
- Cowork scheduled tasks "run in the cloud, so they don't need your computer to be awake". They can run "automatically on a cadence of your choosing". — [Get started with Claude Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork)
- Claude Code: "Budget more for a coding seat than a chat seat: each Claude Code turn carries file contents, tool calls, and multi-step reasoning, so one debugging session can consume more than a day of chat." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Claude Code, things that use usage while idle: session-scoped scheduled tasks "fire on [their] interval even while the session is idle, sending your full context each time". Cross-session messages and goal check-ins do the same. Session recap, idle compaction and prompt suggestions also send background requests. — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Shared allowance: on Team/Enterprise, Claude Code usage draws from a per-seat allowance on a rolling 5-hour window and a weekly window, "shared with Claude chat and Cowork". — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Enterprise average, API-billed: "around $13 per developer per active day and $150-250 per developer per month, with costs remaining below $30 per active day for 90% of users." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Dated: from June 5 to August 5, 2026, Anthropic doubled the Cowork-only 5-hour limit, with weekly limits unchanged. This promotion has ended. Source is a search snippet of the official page, not fetched. — [Claude Cowork June 2026 promotion](https://support.claude.com/en/articles/15400594-claude-cowork-june-2026-promotion)

### Inferences
- What makes agentic work heavier is the number of model calls. Each tool step is a separate request that re-sends the whole growing context: system prompt, tool definitions, history and every earlier tool result. A 40-step Cowork task is about 40 requests of growing size, compared with one request for a chat reply. Screenshots, file reads and command output grow that context fast. Parallel sub-agents add further full conversations.
- Scheduled and recurring tasks are a hidden steady draw, because each run starts or continues a full agentic conversation. That inference rests on the Claude Code statement about scheduled tasks re-sending full context.

### Gaps
- No official ratio for Cowork compared with chat, such as "a Cowork task averages N chat messages". Only relative wording exists.
- No official per-step token figure for Cowork browser or computer-use steps.

---

## Q5. Does prompt caching reduce subscription usage, and how does idle time (cache expiry) affect cost when resuming?

### Takeaway
Yes. Cached content "counts less against your limits", and Claude Code re-reads history "at the cached token rate". Cache reads cost 0.025x to 0.1x of normal input on the API. After an idle gap longer than the cache lifetime, the next message re-processes the entire context at full price. On a subscription, Claude Code's main conversation gets a 1-hour cache, while subagents and compaction get 5 minutes. Compacting after a long break is especially expensive.

### Cited findings
- "Content in projects is cached and counts less against your limits when reused." "If you come back to a project after a long break, your first message counts that content in full again." — [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices)
- "Prompt caching means turns after the first are billed at the much cheaper cache-read rate." — [Models, usage, and limits in Claude Code](https://support.claude.com/en/articles/14552983-models-usage-and-limits-in-claude-code)
- "Cache misses: your first message after a break longer than the cache lifetime misses the cache and reprocesses your full context." — [Manage costs effectively](https://code.claude.com/docs/en/costs)
- TTL defaults: on "Claude subscription, within plan usage", the main conversation gets "One hour". Everything else (subagents, workflows, teammates, forks, compaction, session titles) gets "Five minutes, except the server-controlled helper requests". On usage credits, an API key or a cloud provider, everything is 5 minutes by default. Once you are over the plan and on usage credits, Claude Code drops the main conversation to 5 minutes. — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- "Each request that hits the cache resets the timer, so the cache stays warm as long as you keep working." — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- Compaction: "After a break longer than the cache lifetime, there is no cache left to read, so the summarization request reprocesses that history as uncached input. This is why `/compact` costs the most when you resume an old session." `/clear` "costs nothing". — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching); [Manage costs effectively](https://code.claude.com/docs/en/costs)
- Actions that invalidate the cache: switching models, changing effort (on older models), turning fast mode on or off, connecting or removing MCP servers when tools are not deferred, enabling plugins that bring MCP servers, denying a whole tool, compacting, piling up many images, and upgrading Claude Code. — [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)
- API cache prices: 5-minute write 1.25x base input, 1-hour write 2x, read 0.1x on most models, 0.05x on Opus 5.5 and Sonnet 5.5, 0.025x on Fable 5.1 and 5.2. — [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- `/usage` shows a "Prompt cache (main)" line with hit share, misses, and warm or cold status, from v2.1.251. Its plan breakdown can recommend, for example, "Compact before you step away". — [Manage costs effectively](https://code.claude.com/docs/en/costs)

### Inferences
- Idle time is one of the biggest hidden multipliers in long sessions. Take a large context, say several hundred thousand tokens. Warm, a re-read costs roughly 5% of full price on Opus 5.5 or Sonnet 5.5 (API proxy). Cold, it costs 100%, plus a cache write at 1.25x or 2x. So the first message after a lunch break can cost about 20x to 40x a warm message of the same size. This is arithmetic from API rates, not a stated plan rule.
- Subagents' 5-minute TTL means long-running or paused subagents lose their cache sooner than the main session.

### Gaps
- No official TTL is published for claude.ai chat, projects or Cowork. The help center says only "after a period of inactivity".
- Not confirmed that plan-limit accounting uses exactly the API cache multipliers.

---

## Section notes by session type (for the report writer)

All rankings below are **inference** from the cited findings above, since Anthropic publishes no official ranking.

**Cowork (agentic tasks, computer use, browser use, sub-agents, scheduled tasks).** Officially "higher intensity" with "significant intermediate token usage that may not be visible to end users". Likely biggest drivers: (1) number of steps per task × growing context per step; (2) screenshots and browser page text in computer and browser use, plus large toolset definitions (~4.5K–6.6K tokens per request on the API); (3) parallel sub-agents; (4) model tier (Fable/Opus); (5) scheduled tasks running unattended; (6) connectors and Skills. Official tips: batch related work into one task, start new conversations for unrelated work, ask for quick answers rather than files. Sources: [Enterprise consumption guide](https://support.claude.com/en/articles/14782391-claude-enterprise-consumption-guide), [Get started with Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork), [Pricing](https://platform.claude.com/docs/en/about-claude/pricing).

**Claude Code.** Officially "higher intensity". Likely biggest drivers: (1) long sessions never cleared (full context re-sent on every request and every tool round); (2) model (Opus "several times" Sonnet per turn); (3) subagents, workflows and agent teams (~7x for teams in plan mode); (4) cache misses after idle, model switches and compaction after a break; (5) effort/thinking; (6) big CLAUDE.md, MCP servers and verbose tool output; (7) background requests (scheduled loops, goal check-ins, recap, idle compaction). Levers: `/clear`, `/compact` at breaks, `/model`, `/effort`, `/context`, `/usage` attribution, hooks that trim output, skills instead of CLAUDE.md bulk. Sources: [costs](https://code.claude.com/docs/en/costs), [prompt caching](https://code.claude.com/docs/en/prompt-caching), [Models, usage, and limits](https://support.claude.com/en/articles/14552983-models-usage-and-limits-in-claude-code).

**Regular chat.** Officially "lower intensity". Drivers: conversation length (each reply re-reads the history), message length, attachment size, model, effort, artifacts, and automatic context management in very long chats. Sources: [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices), [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work).

**Research / deep research.** "Same limits" as chat but "can use up your limits faster" because it retrieves multiple sources with searches that build on each other. It runs on Opus 5.5. Search results stay in context as input in later turns, so follow-up questions in the same chat are also heavier. Sources: [Use research on Claude](https://support.claude.com/en/articles/11088861-use-research-on-claude), [Manage usage credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans), [Pricing](https://platform.claude.com/docs/en/about-claude/pricing).

**Connectors/MCP, file uploads, projects.** Connectors are "token-intensive". Use "On demand" with 10 or more connectors. Project files count toward context but are cached, so they "count less" when reused, and count in full again after a long break. Attachment size is a listed factor. Sources: [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work), [Use connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities), [Usage limit best practices](https://support.claude.com/en/articles/9797557-usage-limit-best-practices), [Manage usage credits](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans).
