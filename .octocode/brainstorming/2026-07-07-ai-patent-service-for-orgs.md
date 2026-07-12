# Idea Brief: AI startup that mines patentable inventions from an org's code, protects patents via infringement crawling, and helps draft patents (missing parts, flow, legal)

| Field | Value |
|-------|-------|
| **Status** | Contested → **Update (Round 2, Tavily): Crowded, harder** |
| **Mode** | Validate + Map |
| **Created** | 2026-07-07 (Round 1: Serper only) · **Updated 2026-07-07 (Round 2: Tavily deep-research added)** |
| **Verdict** | Crowded (as framed) — **Round 2 also closes the one wedge Round 1 left open** |
| **Decision** | Narrow → validate the one remaining sliver (trade-secret-vs-patent triage) before building anything, or pivot away from patent-tech |
| **Research limits** | Round 1 ran on Serper only (Tavily key was invalid, 401). **Round 2 added Tavily (`--depth advanced`) after the user fixed the key** — this surfaced 6 additional funded competitors Serper's keyword search missed, including one (Lightbringer) that fully closes the previously-open "SMB self-serve" wedge. No GitHub/npm open-source competitors or building blocks found in either round (confirms closed-source, SaaS-native niche). |

---

## TL;DR

All three pillars the user described — (1) mine patentable inventions from code, (2) protect patents via crawling/infringement monitoring, (3) help draft patents — already exist as **funded, shipping products**, several of them bundled into exactly this 3-pillar platform. **Patlytics** ($65M total raised, $40M Series B led by SignalFire) is explicitly marketed as "the only AI platform purpose-built for the entire patent lifecycle: invention harvesting → drafting → infringement/invalidity → portfolio management." Pillar-specific niches are also taken: **ObviouslyNot.ai** (code-mining), **Patent Watch** YC F25 (infringement monitoring), **DeepIP** ($40M)/**Solve Intelligence** ($55M, Microsoft + Thomson Reuters backed) (drafting + lifecycle).

**Round 2 update (Tavily deep-research):** the "SMB self-serve, no-in-house-counsel" wedge this brief originally flagged as the most promising open angle is now **closed** — **Lightbringer** (Sweden, $14.4M raised, 200+ deep-tech customers, 300% YoY revenue growth, fresh $10M Series A in June 2026) is built *specifically* for "startups and SMEs that cannot absorb the cost or timeline of traditional patent services," combining agentic AI with attorney oversight across invention capture, drafting, prosecution, portfolio, and competitor intelligence — i.e., almost exactly the user's full framing, already shipping. Five more funded drafting competitors also surfaced (Patentext, Edge, Patently Create, PatentPal, Fearn) that Serper's keyword search had missed entirely. The market is meaningfully more crowded than Round 1 concluded. The only angle that still shows no direct competitor is the narrower **trade-secret-vs-patent automated triage** wedge — and even that is absence-based evidence, not confirmed demand.

---

## Framings Considered

1. **Invention Mining from Code** (user's #1) — researched, direct competitor found (ObviouslyNot.ai).
2. **Patent Protection via Infringement Crawling** (user's #2) — researched, direct competitor found (Patent Watch).
3. **AI Patent Drafting Copilot** (user's #3) — researched, multiple funded competitors found (DeepIP, Patlytics, Solve Intelligence, PowerPatent, InventNext).
4. **Unified code+law "context management" layer** (implied by the user's framing: "AI for code, law, patents understanding and context management") — researched as the connective differentiator; found to already be DeepIP's and Patlytics' core pitch ("one workflow, zero disconnects" / full-lifecycle OS for IP).
5. **Dev-embedded / CI-bot continuous invention capture for SMB startups without in-house counsel** — narrowed wedge, researched in depth (round 2).
6. **Trade-secret-vs-patent AI triage engine** (reverse-engineerability risk scoring from shipped code/binaries) — narrowed wedge, researched in depth (round 2).

---

## Landscape — Prior Art

### Web / Products — Full-lifecycle platforms
- **Patlytics** — AI platform covering invention harvesting, patent application drafting, infringement analysis, invalidity contentions, transactional due diligence, and portfolio management. **$65M total raised** (corrected/reconciled in Round 2: $14M Series A Feb 2025 led by Next47 + Google's Gradient Ventures, then $40M Series B led by SignalFire, "raised in under two and a half years" per official press release). Serves 40%+ of Am Law 100 including Quinn Emanuel, Google, Xerox, Koch Industries, Foley & Lardner; 80% project-time reduction, $30k+ saved per claim chart, 15+ hours recovered per application. `strong` — https://www.businesswire.com/news/home/20260408770722/en/Patlytics-Raises-%2440-Million-Series-B-to-Expand-the-AI-Platform-Purpose-Built-for-IP-Work , https://www.alleywatch.com/2026/04/patlytics-ai-patent-platform-ip-lifecycle-management-legal-tech-paul-lee/
- **DeepIP** — Secure end-to-end AI platform: invention harvesting, invention disclosure, patentability/novelty assessment, patent drafting, drawings generation, prosecution, FTO analysis (element-by-element claim charting), invalidity search & charts, portfolio intelligence, landscape analysis. **$40M total raised** (Series A + $25M Series B, Mar 2026, co-led by Korelya Capital and Serena/Dataiku, with Headline/Mistral AI and Balderton/Revolut participating). Embedded in MS Word/IPMS; SOC2 Type II, ISO27001, ISO42001, GDPR; trusted by 400+ law firms and corporate IP teams across 25 jurisdictions and 5 continents, including Philips, Greenberg Traurig, Schwegman Lundberg & Woessner, Dilworth IP, Dexcom, Mewburn Ellis. `strong` — https://www.deepip.ai/ , https://ipwatchdog.com/press/deepip-reaches-40m-in-funding-establishing-the-ai-standard-in-patent-work
- **Solve Intelligence** — End-to-end patent drafting platform (YC S23); **$55M total raised** ($3M seed → $12M Series A Apr 2025 backed by Microsoft's M12 and Thomson Reuters Ventures → $40M Series B Dec 2025). Acquired **Palito.ai** (Mar 2026) to add patent litigation, infringement analysis, invalidity contentions, and case-law research — active horizontal consolidation into the exact same 3-pillar bundle, plus a new Munich office. Customer Advisory Board includes partners from DLA Piper and Perkins Coie; 400+ IP teams across six continents; recently launched "Charts" for infringement/invalidity/SEP/FTO claim charting. `strong` — https://blog.patentext.com/blog-posts/best-solve-intelligence-alternatives , https://pulse2.com/solve-intelligence-40-million-series-b , https://www.law.com/legaltechnews/2026/04/02/solve-intelligence-acquires-ai-patent-litigation-startup-palitoai-announces-munich-office/
- **Lightbringer** — **[Round 2 — decisive finding]** Malmö/Sweden-based AI-native patent platform (founded 2023) built *explicitly* for "startups and SMEs that need IP protection but cannot absorb the cost or timeline of traditional patent services." Combines agentic AI with licensed in-house patent attorney oversight in a single "Service-as-Software" workflow: invention capture, claim drafting, prosecution tracking, portfolio management, competitor intelligence, and white-space analysis. Fixed-price subscription cuts costs ~50% and filing time from 2 months to a few days. **$14.4M total raised** ($10M/€8.6M Series A, June 2026, co-led by 6 Degrees Capital and Newion, following a €4.2M round in Dec 2024). 200+ deep-tech customers across 17 countries (TERASi, Arctic Ravn, DIASENSE, Cler); 300% YoY revenue growth reported Q2 2026; SOC2 Type 2 + GDPR certified; 4.8/5 on G2. Explicitly positions as taking on "Big Law." `strong` — https://www.eu-startups.com/2026/06/swedish-ai-patent-platform-lightbringer-raises-e8-6-million-to-take-on-big-law-and-replace-existing-patent-firms , https://arcticstartup.com/lightbringer-raises-10m-series-a

### Web / Products — Pillar-specific
- **ObviouslyNot.ai** — Near-exact match to pillar #1. Local-first LLM scanner (no cloud upload) reads Git repos, PRs, and agent files to surface "hidden patents" with code-line evidence, distinctiveness scores, and prior-art context; sells to patent attorneys and in-house counsel as a new-client / intake-acceleration pipeline. Explicitly Alice/§101-aware and architected around confidentiality/foreign-filing-license (35 U.S.C. §184) risk. `strong` — https://obviouslynot.ai/attorneys
- **Patent Watch (YC F25)** — Direct match to pillar #2. Automated patent infringement detection, identification of infringement targets, automated claim charts, patent analysis. $2.8M seed raised Apr 2026, $3.2M total. `strong` — https://www.f6s.com/companies/intellectual-property/mo , LinkedIn (Alex Stroe, Apr 2026)
- **PowerPatent** — Patent prosecution software: invention disclosure capture, flowchart/drawing management, graphical claim drafting, computer-aided description drafting, §112/claim diagnostics, inventor/attorney collaboration, Private PAIR integration. SOC2 Type 2 certified; per Round 2 comparison data, positioned as a hybrid AI+attorney-review model specifically for "cost-conscious inventors and startups," custom quotes, cheaper than traditional law-firm fees. `moderate` — https://powerpatent.com/
- **InventNext AI** — Self-serve, chat-interview-driven provisional patent drafting for solo/bootstrapped inventors: $300 AI-generated draft (guided interview + basic prior-art check + DOCX/PDF), $3,000 attorney review upsell, $6,000 premium review. Confirms a real, already-served SMB/self-serve *drafting* segment — but via manual plain-language interview, not code-mining. `strong` — https://inventnext.ai/
- **Patentext** — **[Round 2]** Structured, non-chat drafting platform built around a visual, editable "Invention Graph" that breaks an invention into components/relationships before drafting begins — a distinct UX differentiator vs. chat-based tools. $200/application-draft pricing, free pilot program; founder has 10+ years drafting patents for Uber, Dropbox, and other unicorns. `moderate` — https://blog.patentext.com/blog-posts/best-solve-intelligence-alternatives
- **Edge** — **[Round 2]** AI drafting platform emphasizing disclosure management and a built-in figure editor (lead lines, reference numbers, AI-generated flowcharts); positions as a "strategic partner" across the full invention-to-application workflow. Pricing undisclosed. `moderate` — https://blog.patentext.com/blog-posts/best-solve-intelligence-alternatives
- **Patently Create** — **[Round 2]** Part of the broader "Patently" platform (search + review + drafting + project management); in-browser drawing editor with an AI assistant ("Onardo") that extracts claim features and auto-generates figure descriptions; claims 90%+ drafting-time reduction. `moderate` — https://blog.patentext.com/blog-posts/best-solve-intelligence-alternatives
- **PatentPal** — **[Round 2]** Narrow, speed-focused tool: "reverse-engineers" specifications, flowcharts, and block diagrams directly from claims. Not a full drafting platform. `moderate` — https://blog.patentext.com/blog-posts/best-solve-intelligence-alternatives
- **Fearn** — **[Round 2, weak/single-source lead]** Reportedly raised $5.5M from Kindred Ventures and a16z; claims to cut patent drafting from 50+ hours to ~20 minutes; notable for outcome-based pricing ($2,000 per finished patent, not per-seat/month) — a differentiated pricing model worth noting even though the company itself is only corroborated by one LinkedIn post so far. `weak` — surfaced via Tavily search results referencing a LinkedIn post; not independently verified on a company site.

### Web / Products — Prior-art / FTO / novelty search (saturated sub-market)
10 distinct AI-native vendors found in a single roundup, several enterprise-priced ($400–700+/month): **PQAI**, **IPRally** (Graph AI + IPRally Agent), **Ambercite** (citation-network search), **PatSeer**, **PatSnap Eureka** (task-specific agents, MCP/API access), **Amplified** ($500/mo+), **Cypris**, **Relecura**, **Octimine** (Dennemeyer), **The Lens**. `strong` — https://projectpq.ai/top-ai-patent-search-tools-2026/

### Incumbents
- **LexisNexis PatentSight+** / Clarivate-class tools already sell AI-assisted infringement analysis to enterprise IP teams. `moderate` — https://www.lexisnexisip.com/resources/patent-infringement-analysis/

### GitHub / npm
- Zero relevant results across multiple targeted queries (`patent`, `prior-art-search`, `invention disclosure generator`, `github action patent invention detector`). `strong` (proof of empty scope) — confirms this niche is entirely closed-source/SaaS-native; there is no open-source ecosystem or building block to leverage, and no OSS hobbyist competitor to worry about either.

---

## Perspective Review

### Critical Architect
- Local-first/on-device LLM scanning of proprietary source code, plus SOC2/ISO27001/ISO42001 certification and zero-data-retention guarantees, is now a **baseline enterprise requirement, not a differentiator** — ObviouslyNot already ships local-first scanning; DeepIP already holds the full certification stack. Evidence: obviouslynot.ai, deepip.ai security sections. Decision impact: raises the technical/compliance bar substantially before a new entrant can even reach the legal-analysis layer. `strong`
- The hardest unresolved technical unknown is precision on "is this actually patentable" (Alice/Mayo/§101-eligible) triage — Section 101 rejection rates are climbing (~15.5% by mid-2025 per Patently-O, cited by ObviouslyNot's own research page) and this judgment is contested even among human examiners. Evidence: obviouslynot.ai research section (self-reported). Decision impact: core ML/product risk for any invention-mining feature. `moderate` (single source)

### Visionary Entrepreneur
- Capital timing is validated but the window to be *first* has closed: three funding/M&A events landed in the same ~2 month window as this research (Patlytics $40M Apr 2026, Patent Watch seed Apr 2026, Solve Intelligence acquiring Palito.ai Mar 2026). Evidence: alleywatch.com, f6s.com, law.com. Decision impact: a horizontal full-lifecycle entrant competes on capital and distribution it doesn't have. `strong`
- Distribution is owned via two channels a new entrant lacks: law-firm Word/IPMS plugin relationships (DeepIP) and enterprise IP-team direct sales (Patlytics, DeepIP). A developer-first, bottom-up GTM (PR/CI integration) is comparatively unproven in this market and requires behavior change from engineers who have no built-in incentive to flag inventions today. `moderate`
- Round 2 finding softens the "crowded" read specifically for SMB/dev-embedded: InventNext ($300 interview-based drafts) and ObviouslyNot (enterprise/attorney code-mining) approach the same space from opposite ends, but neither is *cheap + automatic + code-native* simultaneously — that specific convergence point is still open, though closing fast given how quickly adjacent players are moving. `moderate` (inferred from absence, not confirmed demand)

### Product
- The user's 3-pillar bundle spans three distinct buyers/workflows (engineering leadership deciding what to protect, IP counsel drafting/filing, licensing/litigation teams monitoring infringement) that the market has already unbundled into specialist products precisely because they have different budget owners and success metrics — shipping all three at once repeats the incumbents with no scope razor. Evidence: structural comparison of ObviouslyNot vs. Patent Watch vs. DeepIP vs. Patlytics product lines. `strong`
- Round 2: neither narrowed wedge is a clean greenfield MVP. Wedge A (dev-embedded capture) must still solve the same local-first/security architecture as ObviouslyNot before a security-conscious SMB will connect a repo. Wedge B (trade-secret-vs-patent triage) is validated as a *real, currently manual* decision (IPWatchdog podcast: senior IP counsel at 3M/Agilent/Techtronic Industries describe it as a qualitative "can it be reverse-engineered, how much does it cost, how long until disclosure" heuristic) but zero automated tooling was found doing this against actual code/product artifacts — the smallest de-risking step is customer interviews, not a build. `moderate`

### Conceded / Resolved
- No claim was seriously contested in round 1 — architecture, timing/distribution, and buyer-structure arguments converged independently on "crowded as framed."
- In round 2, the initial optimistic read of both wedges as "clean gaps" was conceded once InventNext (drafting) and PowerPatent (disclosure capture, though attorney-facing) surfaced — the gaps are narrower slivers, not open fields.

### Decision Delta (Round 1 → Round 2)
Round 1 → Round 2 (Serper) did not flip the top-line verdict but narrowed the two proposed wedges. **Round 3 (Tavily deep-research) flips Wedge A entirely**: what looked like "no one does cheap + automatic + code-native capture for startups" is now "**Lightbringer already does almost exactly this** (agentic AI + attorney oversight, invention capture through portfolio management, fixed-price, explicitly targeting startups/SMEs without in-house counsel, $14.4M raised, 200+ customers, 300% YoY growth)." This is the single biggest evidence update across all rounds — a claim that survived two rounds as "moderate/open" was conceded outright once a direct, well-funded, fast-growing competitor surfaced. The Visionary and Product lenses' "the middle convergence point is still open" claim from Round 2 is now **retracted**. Only Wedge B (trade-secret-vs-patent triage) survived all three rounds without a direct competitor — but its evidence is still absence-based, not demand-based, and the underlying legal complexity (AI-era reverse-engineering, "improper means" doctrine, "readily ascertainable" redefinition) is well-documented and current, which raises the bar for building it correctly.

---

## Verdict

**As framed** — a general platform doing invention mining + infringement crawling + drafting + context management for orgs — this space is **crowded and actively consolidating, more so than Round 1/2 found**. In the ~5 months bracketing this research: Patlytics raised $40M (total $65M, serving 40%+ of Am Law 100), Solve Intelligence raised $40M (total $55M, Microsoft/Thomson Reuters-backed) and acquired Palito.ai, DeepIP raised $25M (total $40M, 400+ firms across 5 continents), Patent Watch raised a $2.8M seed, and **Lightbringer raised $10M specifically to scale the startup/SMB segment** — five separate funding/M&A events in one product category is a strong "market is already picking winners" signal.

**On the narrower wedges** — Round 3 changes the verdict from *contested* to **closed for Wedge A, still-open-but-unvalidated for Wedge B**. Lightbringer's existence and traction (200+ customers, 300% YoY growth) means the "cheap + automatic + code-adjacent capture for engineering teams without counsel" angle is no longer a gap worth building into — at best it's a feature request to make to an existing, well-capitalized vendor. The trade-secret-vs-patent automated triage angle remains the only one with zero direct competitor found across three research rounds and two search engines — but that is still an absence signal, not a validated demand signal, and building it would require getting ahead of a legal complexity space (AI-era reverse-engineering doctrine) that is itself actively evolving in the courts right now.

---

## Gaps & Opportunities / Risks & Hard Problems

- **Regulatory risk (real, not theoretical):** USPTO's Dec 2025 revised guidance reaffirms only natural persons can be inventors — any "AI finds your patents" product must stay strictly in disclosure-surfacing framing, never inventorship claims. `strong` — https://www.bhfs.com/insight/uspto-issues-revised-inventorship-guidance-for-ai-assisted-inventions-what-it-means-for-patent-strategy/
- **Privilege/discovery risk:** a Feb 2026 federal court ruling found AI-generated documents are not automatically privileged; sending unfiled inventions/source code to third-party AI servers also risks 35 U.S.C. §184 foreign-filing-license violations — this is exactly why ObviouslyNot architected local-first scanning as core, non-negotiable infrastructure. `strong` — https://www.butzel.com/alert-your-ai-generated-documents-are-not-protected-according-to-first-ever-federal-court-ruling
- **UPL (unauthorized practice of law) exposure:** ObviouslyNot's own FAQ explicitly designs around this by outputting "technical disclosures," never legal advice or filing recommendations — any wedge product needs the same guardrail from day one.
- **Unbenchmarked precision problem:** distinguishing genuinely patentable/§101-eligible concepts from routine engineering remains unsolved at scale (~15.5% Section 101 rejection rate, climbing). `moderate`
- **No open-source ecosystem to build on** — the entire stack (code understanding + legal NLP + patent-office-format compliance) must be built from scratch, against teams with $40–65M and law-firm design partners already 1-2 years ahead.
- **Opportunity — pricing/packaging gap:** enterprise tools cluster at $400–700+/month (PatSnap, Amplified) or full enterprise contracts (DeepIP, Patlytics); self-serve tools cluster at $300 one-time + $3-6k attorney upsell (InventNext) for *idea-description* drafting. There is no product priced for a Series A engineering team ($50-500/month) that wants **continuous, code-native** capture rather than a one-time interview or an enterprise IP-team seat.
- **Opportunity — trade-secret triage:** a real, named, currently-manual decision ("can this be reverse-engineered, how long until independent discovery") articulated on the record by IP counsel at 3M, Agilent, and Techtronic Industries, with zero automated tooling found. `moderate`, absence-based.

---

## Angles to Pursue

1. ~~Continuous, code-native invention capture priced for Series A/seed engineering teams (no in-house counsel)~~ — **RETIRED after Round 3.** Lightbringer already serves this exact buyer (startups/SMEs without in-house counsel) with a fixed-price, attorney-augmented, full-lifecycle platform, 200+ customers and 300% YoY growth. Building this now means competing head-on with a funded, fast-growing, already-loved (4.8/5 G2) incumbent rather than filling a gap. Closest prior art: Lightbringer (direct), ObviouslyNot.ai (code-mining mechanics), InventNext (SMB price point).
2. **Trade-secret-vs-patent triage engine** — the one angle that survived three research rounds unclaimed. Given a shipped feature/binary/API surface, score reverse-engineerability and recommend patent vs. trade-secret protection, operationalizing the heuristic senior IP counsel (3M, Agilent, Techtronic) already articulate manually. Closest prior art: none found directly; Lumenci's "automated risk scoring" is adjacent but scoped to FTO/infringement, not trade-secret classification. Still absence-based evidence — validate before building. **Deep-dived in a follow-up doc:** [`2026-07-07-trade-secret-vs-patent-triage.md`](./2026-07-07-trade-secret-vs-patent-triage.md).
3. **Vertical-specific mining** (e.g., AI/ML infra, or a narrow technical domain where generic code-to-patent NLP under-performs) as a defensible wedge versus horizontal players like Patlytics/DeepIP/Lightbringer — not yet researched in depth; flagged as an open question below.
4. **[New, Round 3]** If pursuing patent-tech at all, the **outcome-based pricing model** (Fearn's reported $2,000-per-finished-patent, vs. everyone else's per-seat/month) is a genuinely under-explored packaging angle worth testing even inside an existing wedge — most competitors charge for access/effort, not the deliverable. Weak evidence (single source) but worth a pricing-strategy look if any wedge advances.

---

## Recommended Next Step

**Do not build the general platform or Wedge A — both are now confirmed crowded/closed.** If there's still appetite for this space, run 5-10 customer-discovery interviews specifically testing Wedge B (automated trade-secret-vs-patent triage from real code/binaries) before writing any code or an RFC — it is the only angle that survived three research rounds and two search engines without a direct competitor, but it still rests on vendor-absence evidence, not confirmed willingness to pay. If Wedge B doesn't validate either, the honest recommendation is to look outside patent-tech entirely: this space has absorbed at least $250M+ in disclosed funding across 7+ well-differentiated competitors in roughly the last 18 months.

---

## Open Questions

- [x] ~~Would a Series A engineering team actually pay $50-500/month for continuous PR-level invention flagging?~~ — Moot after Round 3: Lightbringer already serves this buyer profile with a proven, growing product; the question is no longer "is there demand" but "why would they switch."
- [ ] Is the trade-secret-vs-patent triage decision (Wedge B) valuable enough to buy as a standalone product, or is it a feature IP counsel would only trust bundled inside a platform they already use (DeepIP/Patlytics/Lightbringer), making it a feature request for incumbents rather than a standalone wedge?
- [ ] Vertical-specific mining (angle 3) was flagged but not researched — worth a follow-up pass if Wedge B doesn't validate.
- [ ] Is "Fearn" (outcome-based $2,000/patent pricing) a real, verifiable company? Only one LinkedIn-post-derived source was found — worth a direct company-site check before citing further.

---

## Resources

### Web
- [Patlytics Raises $40M as AI Drives a Simultaneous Surge in Patent...](https://www.alleywatch.com/2026/04/patlytics-ai-patent-platform-ip-lifecycle-management-legal-tech-paul-lee/) — AlleyWatch, Apr 8 2026; backs §Landscape claim that full-lifecycle AI patent platforms are funded and shipping. `strong`
- [How Patlytics is automating the hardest workflows in IP](https://www.signalfire.com/blog/patlytics-investor) — SignalFire, Apr 2026; backs same claim from investor's perspective. `strong`
- [Solve Intelligence Acquires AI Patent Litigation Startup Palito.ai](https://www.law.com/legaltechnews/2026/04/02/solve-intelligence-acquires-ai-patent-litigation-startup-palitoai-announces-munich-office/) — Law.com, Apr 2 2026; backs §Perspective Review consolidation/timing claim. `strong`
- [For Patent Attorneys - Structured Technical Disclosures from Code](https://obviouslynot.ai/attorneys) — ObviouslyNot.ai; backs §Landscape direct-competitor claim for pillar 1 and §Risks privilege/local-first architecture claim. `strong`
- [DeepIP - Better & Faster Patents with Gen AI](https://www.deepip.ai/) — backs §Landscape full-lifecycle platform claim and enterprise security/certification baseline claim. `strong`
- [Patent Watch (YC F25) — F6S listing](https://www.f6s.com/companies/intellectual-property/mo) — backs §Landscape direct-competitor claim for pillar 2. `strong`
- [Top AI Patent Search Tools for 2026: 10 Platforms](https://projectpq.ai/top-ai-patent-search-tools-2026/) — PQAI, May 20 2026; backs §Landscape saturated prior-art/FTO search sub-market claim. `strong`
- [PowerPatent](https://powerpatent.com/) — backs §Landscape pillar-3 competitor claim and §Angles pricing/positioning gap claim. `moderate`
- [InventNext AI](https://inventnext.ai/) — backs §Angles SMB self-serve drafting claim and §Perspective Review wedge-narrowing claim. `strong`
- [USPTO Issues Revised Inventorship Guidance for AI-Assisted Inventions](https://www.bhfs.com/insight/uspto-issues-revised-inventorship-guidance-for-ai-assisted-inventions-what-it-means-for-patent-strategy/) — Dec 2 2025; backs §Risks regulatory claim. `strong`
- [Your AI-Generated Documents Are Not Protected According to First-Ever Federal Court Ruling](https://www.butzel.com/alert-your-ai-generated-documents-are-not-protected-according-to-first-ever-federal-court-ruling) — Feb 20 2026; backs §Risks privilege/discovery claim. `strong`
- [Patents vs. Trade Secrets: Do You Need a Patent, or is a Secret Good Enough?](https://ipwatchdog.com/2025/07/22/patents-vs-trade-secrets/) — Gene Quinn / IPWatchdog Unleashed podcast w/ IP counsel from 3M, Agilent, Techtronic Industries; backs §Angles trade-secret-triage-gap claim. `moderate` (confirms the manual heuristic exists; does not confirm demand for automating it)

### Web — Round 2 (Tavily deep-research)
- [Swedish AI patent platform Lightbringer raises €8.6 million to "take on Big Law"](https://www.eu-startups.com/2026/06/swedish-ai-patent-platform-lightbringer-raises-e8-6-million-to-take-on-big-law-and-replace-existing-patent-firms) — EU-Startups, June 2026; backs §Landscape and §Decision Delta claim that Wedge A is closed. `strong`
- [Swedish legaltech startup Lightbringer secures $10M Series A](https://arcticstartup.com/lightbringer-raises-10m-series-a) — ArcticStartup; corroborates customer count (200+), country count (17), and revenue growth (300% YoY) claims. `strong`
- [Patlytics Raises $40 Million Series B](https://www.businesswire.com/news/home/20260408770722/en/Patlytics-Raises-%2440-Million-Series-B-to-Expand-the-AI-Platform-Purpose-Built-for-IP-Work) — BusinessWire official press release, Apr 8 2026; most authoritative source for the reconciled $65M total-funding figure (resolves the contradiction with the older $21M figure in the Patentext blog). `strong`
- [Solve Intelligence vs Patlytics: full comparison (2026)](https://blog.patentext.com/blog-posts/solve-intelligence-vs-patlytics) — Patentext (competitor blog, dated Jan 19 2026 — pre-dates Patlytics' April Series B, explaining the stale $21M figure); backs §Landscape funding-history detail for both companies. `moderate` (vendor-authored comparison content, but funding figures cross-checked against BusinessWire/Tracxn)
- [7 best Solve Intelligence alternatives (2026)](https://blog.patentext.com/blog-posts/best-solve-intelligence-alternatives) — Patentext; primary source for Patentext, Edge, Patently Create, PatentPal, and PowerPatent entries in §Landscape. `moderate` (vendor-authored, but names/features cross-checked are the actual competitors' own positioning)
- [DeepIP Reaches $40M in Funding](https://ipwatchdog.com/press/deepip-reaches-40m-in-funding-establishing-the-ai-standard-in-patent-work) — IPWatchdog press release, Mar 2026; backs §Landscape DeepIP funding/investor/customer-count claim. `strong`
- [Reverse engineering in the age of AI: Are your trade secrets still safe?](https://masslawyersweekly.com/2025/12/08/reverse-engineering-in-the-age-of-ai-are-your-trade-secrets-still-safe) — Gregory S. Bombard, Mass Lawyers Weekly, Dec 8 2025; backs §Wedge B legal-complexity claim (courts scrutinizing "improper means" and "readily ascertainable" doctrines in the AI era). `strong`
- [Trade Secrecy Meets Generative AI](https://scholarship.kentlaw.iit.edu/cgi/viewcontent.cgi?article=4489&context=cklawreview) — Kent Law Review (academic, PDF); corroborates the same legal-complexity claim from a scholarly source. `strong`
- [AI-Powered Freedom to Operate](https://lumenci.com/blogs/ai-assisted-fto-search) — Lumenci; backs the claim that "automated risk scoring" exists for FTO/infringement but not for trade-secret-vs-patent classification specifically. `moderate`

### GitHub / npm
- No entries — zero relevant results across `patent`, `prior-art-search`, `invention disclosure generator`, and `github action patent invention detector` queries via Octocode CLI (`ghSearchRepos`/npm search). Backs §Landscape claim that this niche has no open-source ecosystem or building blocks. `strong` (empty-scope proof)
