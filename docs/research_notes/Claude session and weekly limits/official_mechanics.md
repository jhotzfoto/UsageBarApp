# Official mechanics of Claude subscription limits (Max plan, formerly "Max 5x"), as of 26 November 2026

Research done 2026-11-26. Help-center pages show only relative "Updated over N weeks ago" stamps, so exact revision dates aren't known. Unless a finding says otherwise, quotes come from the live pages fetched on 2026-11-26. Some X posts couldn't be fetched (X returned HTTP 402), so wording from them comes from search snippets and is marked that way.

**Important naming note:** On 30 October 2026 Anthropic renamed "Max 5x" to just **"Max"** ($100/month) and "Max 20x" to **"Ultra"** ($200/month). The user's "Max 5x" plan is now called "Max". — [Claude on X (search snippet)](https://x.com/claudeai/status/2116220869479428500); [claude.com/pricing](https://claude.com/pricing)

## Q1. How do the 5-hour session window and the weekly window start and reset?

### Takeaway
The official wording is that the 5-hour session starts with your first message and resets in full five hours later. That makes it a window that starts when you begin, not a fixed clock and not a sliding window. The weekly limit resets at a fixed day and time assigned to each account, and it doesn't depend on when you started using Claude.

### Cited Findings
- Session start and reset: "The period starts when you send your first message, and your limit resets in full five hours later." Also: "If you reach the limit before then, you can use Claude again once it resets." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Weekly reset: "Weekly limits reset at a fixed time each week that is assigned to your account." The page adds (paraphrased by the fetch tool) that the reset time doesn't change with when you started using Claude or when your subscription began, and you get your full weekly allowance each cycle. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- The Max plan page repeats this: "The weekly limit resets at a fixed time each week that is assigned to your account." — [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- Limit resets (one-off offers) don't move the schedule: "Your weekly limits still reset on their usual day and time." — [What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)
- Reset times appear under Settings > Usage (web, Desktop, mobile). — [What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)

### Inferences
- "Resets in full five hours later" means the whole session allowance comes back at once at the 5-hour mark. Usage doesn't drip back message by message as it would with a sliding window. Anthropic doesn't use the words "rolling" or "fixed".
- The next session presumably starts with the next message after a reset, not automatically at the reset moment. That fits "starts when you send your first message", but the page doesn't spell it out.
- Anthropic doesn't say how a weekly reset time is assigned to an account (signup time, first use or random). Its wording only says the time is fixed per account.

### Gaps
- Anthropic doesn't publish how the weekly reset day/time is chosen, or whether it's expressed in a particular time zone.
- Officially undocumented: whether a session that is open when the weekly reset hits gets refreshed too.

## Q2. Does usage count toward the session and weekly limits at the same time? Is weekly smaller than (sessions per week) × (session limit)? Any published ratios or hours?

### Takeaway
Anthropic presents both as limits that apply together ("5x Pro usage every 5 hours and every week"), and either one can stop you. It doesn't state outright that each message counts against both. No current help page publishes a ratio, token count or number of hours for Max. A product lead's October 2026 explanation confirms the top plan's weekly cap was set below what its session cap would add up to. Per that post, Max 20x (now Ultra) had 20x Pro per 5 hours but only 10x Pro per week.

### Cited Findings
- Max: "**5x Pro usage** every 5 hours and every week*". Footnote: "How fast you reach a limit depends on the model you use" (chat length and file size also matter). — [claude.com/pricing](https://claude.com/pricing)
- "Get five times the Pro plan's usage every five hours and every week." The Max plan also has a weekly limit across all models plus "a separate weekly limit for Fable." — [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- "If you hit your session limit or weekly limit, you can wait for it to reset or upgrade your plan." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Usage credits apply once you've used up "any five-hour session limit," your weekly limit, or your Fable weekly limit. — [Manage usage credits for paid Claude plans](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)
- Anthropic keeps discretion: "We may adjust usage limits at our discretion to manage capacity and ensure fair access to all users." The page also says longer conversations that trigger automatic context management use more of the limit. — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- The Max page adds that usage may be limited in other ways too, "such as weekly or monthly caps", and "We don't guarantee uninterrupted service." — [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- **Staff statement** (Mike Overell, "I lead product for Claude subscriptions", 30 Oct 2026, wording from a search snippet; the post itself wasn't fetchable): the top plan launched in April 2025 "had a single limit: 5 hours. It gave you 20x Pro's limit, so we called it Max 20x. When we added weekly limits to Max 20x, we…". Search summaries of the rest of the post say the weekly limits were set at 10x Pro, so the name no longer matched. — [Mike Overell on X](https://x.com/mboverell/status/2116221457252659275)
- Ultra today: "No 5-hour limit‡" and "10x Pro usage every week". ‡ = "No 5-hour limit for verified accounts." — [claude.com/pricing](https://claude.com/pricing)
- **Historical (announced 28 July 2025, effective 28 August 2025):** Anthropic gave rough weekly estimates for Claude Code. Pro: 40–80 h Sonnet 4. Max $100: 140–280 h Sonnet 4 and 15–35 h Opus 4. Max $200: 240–480 h Sonnet 4 and 24–40 h Opus 4. It expected the weekly limits to affect under 5% of subscribers. These were estimates for retired models and haven't been republished for current models. — [TechCrunch, 2025-07-28](https://techcrunch.com/2025/07/28/anthropic-unveils-new-rate-limits-to-curb-claude-code-power-users/); [The Decoder](https://the-decoder.com/anthropic-will-set-new-weekly-usage-limits-for-claude-subscribers-starting-august/)
- No fixed message or token counts are published for any plan. — Confirmed by the absence of any such figure on [pricing](https://claude.com/pricing), [usage and length limits](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work) and [Max plan](https://support.claude.com/en/articles/11049741-what-is-the-max-plan). Third-party measurements exist (for example wokey.ai claims Pro ≈ 21.3M tokens/week) but they aren't official. — [wokey.ai (third party, unverified)](https://wokey.ai/claude-usage-limits)

### Inferences
- Both limits are stated as multiples of Pro ("every 5 hours and every week"), and either one can block you. The natural reading is that every bit of usage draws down both meters at once. That is inferred, not stated word for word.
- A week has 33.6 five-hour windows. For Max, both limits are "5x Pro", so the session-to-weekly ratio is the same as Pro's. Anthropic doesn't publish Pro's ratio either, so no official number says how many full sessions fit in a week. The Ultra history shows Anthropic deliberately set a weekly cap below the sum of its sessions, which suggests the same design for Max. That suggestion is inferred, and no published Max number backs it.
- The 2025 hour estimates put Max $100 at 15–35 h of Opus per week. That is far below the 168 hours in a week, which is consistent with the weekly cap binding before continuous use of every session would. Treat this as historical context only.

### Gaps
- No official statement says how many maxed sessions a weekly Max limit allows.
- There are no current official "hours per week" figures for Max for Sonnet 5.5, Opus 5.5 or Fable 5.2.
- The full text of the Overell post couldn't be retrieved first-hand (X returned 402).

## Q3. What is the model-specific weekly limit (Fable)? Does it also count toward the all-models limit? What happens when either is hit?

### Takeaway
On Max, Fable draws from the same weekly allowance as every other model, but at most 50% of that weekly allowance can go to Fable. The "Weekly · Fable" bar is a sub-cap inside "Weekly · all models", not a separate pool. When a limit is hit you wait, upgrade, switch away from Fable (for the Fable cap), use usage credits if you've turned them on, or use a limit reset if you have one.

### Cited Findings
- "Weekly limits apply across all models, and some plans also have a separate weekly limit for Fable." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- Pricing page, Max: "Fable included, up to half your weekly limit". Comparison table: "50% of weekly limits*". Ultra is the same at 50%. — [claude.com/pricing](https://claude.com/pricing)
- Fable is included in plan limits on Max, Ultra, premium Team seats and premium seat-based Enterprise seats. Pro, standard Team seats and standard seat-based Enterprise seats get Fable through usage credits only. Users on plans that include it can use "up to 50% of your weekly usage limits on Fable models at no extra cost." Fable usage draws from the plan's regular weekly limits and uses them up faster than other models do. — [Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan)
- Conflicting note: the Fable 5.2 launch post says "Fable is included for up to 50% of weekly usage limits for Pro plans and standard seats on the Team plan". That contradicts the help article, which says Pro gets Fable through usage credits only. The help article is the more specific source, but the conflict is unresolved. — [Introducing Claude Fable 5.2 and Mythos 5.2 (9 Nov 2026)](https://www.anthropic.com/news/claude-fable-and-mythos-5-2) vs [Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan)
- When the Fable cap is reached, users on plans that include it can keep using Fable on usage credits or switch to another model and stay within plan limits. — [Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan)
- When the session or weekly limit is hit: "you can wait for it to reset or upgrade your plan." Also: "With usage credits enabled, your work continues on usage credits instead of stopping." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- How a Fable limit reset works: "you get back the weekly usage you've spent on Fable models." Also: "Usage you've spent on other models stays where it is." And: "If your account has a five-hour limit, it's fully refilled, including usage spent on other models." — [What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)
- Models covered: Fable 5.2, 5.1 and 5. Minimum Claude Code versions are 2.1.321 for 5.2, 2.1.255 for 5.1 and 2.1.170 for 5. — [Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan)

### Inferences
- Fable usage counts toward both "Weekly · Fable" and "Weekly · all models". Usage of other models counts only toward "all models". So the Fable bar can't stop you from using other models, but filling the all-models bar stops Fable too.
- A Fable reset gives back Fable usage, and that usage was also counted in all-models. The reset therefore probably lowers the all-models bar by the same amount ("weekly usage you've spent on Fable" comes back). This is inferred from the wording; the exact behaviour of the all-models bar isn't stated.
- No automatic switch to another model is documented for Max. The documented options are manual: switch models, or pay with credits.

### Gaps
- The Fable help article doesn't say whether Fable has its own 5-hour sub-cap or just uses the general session limit faster.
- How much faster Fable uses up the limit than Sonnet or Opus isn't published. The page points to API rates at anthropic.com/pricing#api.

## Q4. Is usage shared across claude.ai, Cowork, Claude Code, Desktop and mobile? Is the usage page breakdown (Cowork / Claude Code / Chats / Other) official?

### Takeaway
Yes, the pool is shared. Anthropic says usage across product surfaces counts toward the same limit, and the bundles and reset pages extend that to Cowork, mobile and third-party products signed in with the Claude account. I found no help-center text describing a per-surface breakdown on the usage page.

### Cited Findings
- Usage of "all different Claude product surfaces (claude.ai, Claude Code, Claude Desktop)" "counts towards the same usage limit." — [How do usage and length limits work?](https://support.claude.com/en/articles/11647753-how-do-usage-and-length-limits-work)
- The credit balance "applies across Claude, Claude Code, Claude Cowork, and third-party products that use your Claude account" (the full sentence also names Claude Desktop and mobile apps). — [Buy usage bundles](https://support.claude.com/en/articles/14246112-buy-usage-bundles)
- "Your usage limits are shared across your Claude account, so the usage a reset restores also applies in Claude Code." — [What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)
- The Agent SDK can run on a Claude plan, which is how "third-party products" draw on it. — [Use the Claude Agent SDK with your Claude plan](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan) (title only, from the collection listing; body not fetched)
- The Max plan includes Claude Code and Cowork under "one unified subscription". — [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- Limits can be viewed under Settings > Usage on web, Desktop and mobile, and with `/usage` in Claude Code. The "Reset for free" button isn't available in the Claude Code terminal or IDE. — [What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)

### Inferences
- Cowork isn't named in the main limits article, but it is named in the bundles article. Combined with the "shared across your Claude account" wording, that strongly implies Cowork uses the same session and weekly meters.

### Gaps
- I found no official documentation of the usage page's "Cowork / Claude Code / Chats / Other" breakdown. It exists in the product UI, per the user, but not in any help article I fetched.
- What "Other" covers (for example Agent SDK or third-party apps) isn't documented.

## Q5. What official options exist when you run out, what do they cost, and how are they billed (CAD vs USD)?

### Takeaway
There are four official routes: wait for the reset, turn on usage credits (pay-as-you-go at standard API rates, with a monthly cap you choose), prepay discounted usage bundles, or upgrade to Ultra ($200/month USD, prorated). All official prices are in USD, before tax. No CAD prices are published, and mobile in-app pricing "may vary".

### Cited Findings
- Usage credits are for Pro, Max and Ultra. "Usage credits are billed at standard API rates; see our pricing page for details." They start once any 5-hour, weekly or Fable weekly limit is used up. You set a monthly spending cap or choose "Set to unlimited". Auto-reload "is only available on the web." — [Manage usage credits for paid Claude plans](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)
- Credit expiry: "usage credits purchased on or after December 7, 2026 expire 12 months after the purchase date". Earlier purchases don't expire, and expiry varies in some countries. "Usage credit purchases are non-refundable, including if you cancel your subscription or delete your account" (local-law and fraud exceptions apply). — [Manage usage credits for paid Claude plans](https://support.claude.com/en/articles/12429409-manage-usage-credits-for-paid-claude-plans)
- Terminology: current pages say "usage credits". Older URL slugs on the same article ID show the earlier name "extra usage" (for example `12429409-manage-extra`). — [search results listing article 12429409 slugs](https://support.claude.com/en/articles/12429409-using-extra-usage)
- Usage bundles: "You can pre-purchase usage credits in bundles and save up to 30%". Prices are $50 for $45 (10% off), $250 for $200 (20% off) and $1000 for $700 (30% off). Individual Pro/Max/Ultra subscribers can buy up to $2000 of discounted bundles per month. "Bundle purchases are non-refundable." "Bundle credits only apply after you've exceeded your plan's limits and are using usage credits." Expiry "depends on your plan and where you live." — [Buy usage bundles](https://support.claude.com/en/articles/14246112-buy-usage-bundles)
- Upgrade to Ultra: $200/month, "10x Pro usage every week", no 5-hour limit for verified accounts, $200/month in API credits. Upgrades from Max are "charged on a prorated basis for the remainder of your billing cycle." — [claude.com/pricing](https://claude.com/pricing); [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- On the Ultra 5-hour limit: newer accounts keep a temporary 5-hour limit until verified, which Anthropic says is for fraud and abuse prevention. Users get an email when it's lifted. Weekly limits were unchanged by the rename. — [Claude on X (search snippet)](https://x.com/claudeai/status/2116220869479428500); [Mike Overell on X (search snippet)](https://x.com/mboverell/status/2116221457252659275)
- Max price: "The Max plan is available for $100 per month." Also: "This price is for web subscriptions only. Mobile pricing may vary depending on your app platform." — [What is the Max plan?](https://support.claude.com/en/articles/11049741-what-is-the-max-plan)
- The pricing page notes: "Prices shown don't include applicable tax." Also: "Price and plans are subject to change at Anthropic's discretion." Max includes "$100 a month in API credits to build on the Claude Platform" and "Priority access at high traffic times". — [claude.com/pricing](https://claude.com/pricing)
- Limit resets (free, occasional, for "eligible plans") are another route. "A reset doesn't refund extra usage you've already been billed for or change your usage credit balance." — [What is a limit reset?](https://support.claude.com/en/articles/17007452-what-is-a-limit-reset)

### Inferences
- For a Canadian subscriber on web billing, the charges are presumably in USD plus applicable Canadian sales tax (GST/HST). No official page confirms Canadian tax handling or CAD conversion. A subscription bought through iOS in-app purchase would be in Apple's CAD price tier, which "may vary".

### Gaps
- No CAD prices are published anywhere I checked.
- The per-model "standard API rates" weren't fetched (they're at anthropic.com/pricing#api).
- Bundle expiry periods for Canada aren't stated on the bundles page.

## Q6. Changes in 2025–2026 (weekly limits introduction, later changes, peak hours, promotions)

### Takeaway
Timeline: Max launched in April 2025 with only a 5-hour limit. Weekly limits followed on 28 August 2025. Reported changes in May 2026 doubled Claude Code's 5-hour limits and dropped the peak-hour reduction (secondary sources only). Fable was moved into plan limits with a 50% weekly cap in 2026. The 30 October 2026 rename brought in Max/Ultra and removed the 5-hour limit for verified Ultra accounts. A Fable 5.2 launch promotion (Fable limit resets) runs until 8 March 2027.

### Cited Findings
- **April 2025:** the top Max plan launched with "a single limit: 5 hours". — [Mike Overell on X (search snippet)](https://x.com/mboverell/status/2116221457252659275)
- **28 July 2025 announcement, 28 August 2025 effective:** weekly limits added for Pro and both Max tiers, with hour estimates as listed in Q2. Anthropic said they'd affect under 5% of subscribers. — [TechCrunch](https://techcrunch.com/2025/07/28/anthropic-unveils-new-rate-limits-to-curb-claude-code-power-users/); [The Decoder](https://the-decoder.com/anthropic-will-set-new-weekly-usage-limits-for-claude-subscribers-starting-august/)
- **6 May 2026 (secondary sources only):** Claude Code 5-hour limits were reportedly doubled for paid plans (Pro, Max, Team, seat-based Enterprise). Anthropic was quoted as "removing the peak hours limit reduction on Claude Code for Pro and Max accounts". Weekly limits were reported as unchanged. — [Appwrite blog](https://appwrite.io/blog/post/anthropic-doubles-claude-code-rate-limits); [Verdent guide](https://www.verdent.ai/guides/claude-code-limits-doubled-may-2026)
- **13 May 2026 (secondary sources, details conflict):** a temporary 50% increase in weekly limits, with a reported end date of either 13 July 2026 or 19 August 2026. — [Techsy](https://techsy.io/en/blog/claude-2x-usage-limits-explained)
- **15 May 2026 (secondary source):** a one-time reset of 5-hour and weekly counters for everyone. — [pasqualepillitteri.it](https://pasqualepillitteri.it/en/news/2614/claude-resets-rate-limits-5-hour-weekly-may-15-2026)
- **Peak hours:** I found no current official help page describing a peak-hour adjustment. Third parties note Anthropic never published which hours counted as peak. Max currently lists "Priority access at high traffic times". — [Appwrite blog](https://appwrite.io/blog/post/anthropic-doubles-claude-code-rate-limits); [claude.com/pricing](https://claude.com/pricing)
- **Fable promotions:** a 50% Fable 5 promotion ended 19 July 2026 at 11:59:59 PM PT. Fable 5 moved to usage credits for Pro and standard Team seats in July 2026, with a one-time credit. — [Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan)
- **30 October 2026:** "We're renaming our Max plans: Max 5x → Max, Max 20x → Ultra. Max is still $100/month, and Ultra is still $200. If you're a subscriber, there's nothing you need to do. We're also removing the 5-hour limit for verified Ultra accounts, starting today with most existing subscribers." — [Claude on X (search snippet)](https://x.com/claudeai/status/2116220869479428500); also staff confirmation from [Boris Cherny on X](https://x.com/bcherny/status/2116222842413142111)
- **9 November 2026, Fable 5.2 launch promotion:** Max subscribers get Fable limit resets based on how long they've subscribed, counted from the first paid bill. Under 6 months gets 1, 6–12 months gets 2 and over 12 months gets 3. "These resets expire on March 8, 2027 at 11:59 pm PT." — [Fable 5.2 launch promotion](https://support.claude.com/en/articles/17506494); [Anthropic news, 9 Nov 2026](https://www.anthropic.com/news/claude-fable-and-mythos-5-2)
- The Anthropic newsroom has no 2026 posts about Max, Ultra, rate limits or peak hours. The rename was announced on X and in the help center, not in a news post. — [anthropic.com/news](https://www.anthropic.com/news)

### Inferences
- The May 2026 "doubled 5-hour limits" were reportedly scoped to Claude Code. The current help pages describe one shared limit across surfaces and no Claude Code-specific multiplier. It's unclear whether the doubling was later applied account-wide or folded into today's "5x Pro" baseline.

### Gaps
- The primary Anthropic source for the May 2026 changes (doubling, peak-hour removal, temporary +50% weekly) wasn't retrieved, so treat those items as unverified.
- Whether any peak-hour adjustment still applies to Max chat or Cowork isn't documented.
- The help-center pages don't show exact revision dates.
