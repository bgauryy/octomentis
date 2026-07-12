# Idea Brief: Trade-Secret-vs-Patent AI Triage Engine (from real code/binaries)

**Follow-up to:** [`2026-07-07-ai-patent-service-for-orgs.md`](./2026-07-07-ai-patent-service-for-orgs.md) — this is the one angle out of that brief's six framings that survived three research rounds (Serper + Tavily + GitHub/npm) without a single direct competitor.

| Field | Value |
|-------|-------|
| **Status** | Exploratory — narrowed from parent brief, not yet customer-validated |
| **Mode** | Validate (single narrowed angle) |
| **Created** | 2026-07-07 |
| **Verdict** | Underserved (absence-based) — the only unclaimed angle found across the parent research |
| **Decision** | Prototype First — validate demand via customer interviews before writing code |
| **Research limits** | No new searches run for this doc; it consolidates evidence already gathered in the parent brief's three rounds. No direct customer discovery has been done yet — this is desk research only. |

---

## TL;DR

Every other patent-tech angle researched in the parent brief (invention mining, infringement monitoring, drafting, full-lifecycle platforms, SMB self-serve) has a funded, shipping competitor — several with $40–65M raised. The one exception: an **automated tool that looks at a company's actual shipped code/APIs/binaries and recommends patent vs. trade-secret protection based on how easily the underlying technique could be reverse-engineered.** Senior IP counsel at 3M, Agilent, and Techtronic Industries described this exact decision, on the record, as a manual "gut-feel formula" today — no product was found operationalizing it against real artifacts. The opportunity is real but the evidence is **absence-based, not demand-based**: nobody has confirmed they'd pay for this, only that nobody else builds it. Next step is customer interviews, not code.

---

## The Idea

**Input:** a shipped product surface — source code, compiled binary, public API, SaaS UI/behavior, or a technical description of an internal process.

**Output:** a structured recommendation:
1. **Reverse-engineerability score** — how easily and cheaply could a competent competitor derive the underlying technique from what's publicly observable (decompilation difficulty, API response fingerprinting, behavioral inference, whether the "how" is exposed at all vs. only the "what")?
2. **Time-to-independent-discovery estimate** — given the technique's novelty and the pace of the field, how long before someone else invents it independently anyway?
3. **Protection recommendation** — patent (if detectable/reverse-engineerable, since a patent is worthless once secrecy is lost anyway) vs. trade secret (if genuinely undetectable from the outside, since trade secrets can outlast any patent term with no disclosure cost) vs. "both are weak, consider a different moat" (e.g., data network effects, execution speed).
4. **Evidence trail** — the specific code paths, API behaviors, or technical characteristics that drove the score, so legal counsel can sanity-check the reasoning rather than trust a black box.

This directly operationalizes the heuristic described by Arash Behravesh (Agilent Enterprise Counsel) in the IPWatchdog Unleashed podcast cited in the parent brief: *"Can it be reverse engineered? How much does it cost the competitor to reverse engineer it? And if we decide to keep it as a trade secret, how long will it be before somebody potentially discloses the information to the public?"* — today answered by intuition and industry experience; this would answer it with evidence pulled from the actual artifact.

---

## Why This Survived (Evidence Recap from Parent Brief)

- **Zero direct competitors** found across two engines (Serper + Tavily) and ~20 targeted queries, including after Tavily deep-research surfaced 6 additional funded competitors for every *other* angle (Lightbringer, Patentext, Edge, Patently Create, PatentPal, Fearn). `strong` (empty-scope, two independent search engines)
- **The manual heuristic is confirmed real and current**, not hypothetical — three named IP executives (3M, Agilent, Techtronic Industries) describe using it as their actual decision framework in a July 2025 industry podcast. `moderate` — https://ipwatchdog.com/2025/07/22/patents-vs-trade-secrets/
- **The closest adjacent capability** — Lumenci's "automated risk scoring based on feature alignment" — is explicitly scoped to Freedom-to-Operate/infringement risk (comparing a product against *existing patents*), not to the patent-vs-trade-secret classification decision itself. `moderate` — https://lumenci.com/blogs/ai-assisted-fto-search
- **The underlying legal doctrine is live and evolving right now**, which raises both the stakes and the defensibility of getting this right: courts are actively re-litigating what counts as "improper means" of AI-assisted reverse-engineering, and whether AI makes previously-secret information "readily ascertainable" (and thus unprotectable as a trade secret). `strong` — https://masslawyersweekly.com/2025/12/08/reverse-engineering-in-the-age-of-ai-are-your-trade-secrets-still-safe , https://scholarship.kentlaw.iit.edu/cgi/viewcontent.cgi?article=4489&context=cklawreview
- **A public decision framework already exists as content** (not product): arapackelaw.com publishes a "patent when / trade secret when" checklist keyed on reverse-engineering risk — confirming the framework is well-understood conceptually, just not automated against real artifacts. `moderate`

---

## Perspective Review (carried over from parent brief, reframed for this angle)

### Critical Architect
- Scoring reverse-engineerability from real code requires genuine static/dynamic analysis capability (not just an LLM summarizing a README) — this is closer to a security/decompilation tooling problem than a legal-NLP problem, which is a different skillset than what drafting-focused competitors (DeepIP, Patlytics, Lightbringer) have built. Decision impact: the hardest technical unknown to prove first. `moderate`
- The same local-first/zero-retention architecture bar that applies to every other angle in this space applies here too — no company will upload proprietary source code or binaries to a third-party server for this analysis. `strong`

### Visionary Entrepreneur
- This is a wedge that could be **sold into existing platforms** (DeepIP, Patlytics, Lightbringer) as a feature/API rather than fought as a standalone product — those platforms already have the attorney relationships and enterprise trust; a standalone entrant would need to build both the technical capability and the buyer relationship from zero. `moderate`
- Alternatively, this could be a **narrow consulting-augmentation tool** sold directly to IP counsel/GCs at companies making this decision today (SaaS companies with reverse-engineerable APIs, hardware companies, deep-tech), positioned as evidence-generation for a decision they already have to make, not a new workflow. `weak` (not yet validated with a buyer)

### Product
- The buyer is genuinely ambiguous and needs to be resolved before anything else: is it (a) in-house IP counsel at a company making the patent-or-secret call, (b) a patent attorney at a firm advising multiple clients, or (c) an engineering leader trying to self-serve this decision before ever talking to counsel? Each implies a different product, price point, and distribution channel. `strong` (this is the single highest-leverage open question)
- Smallest de-risking step is not a prototype — it's 5-10 structured interviews with people who currently make this call manually (in-house IP counsel, patent attorneys with a mixed patent/trade-secret practice) to find out whether they'd trust an automated first-pass score, and what would make them trust it. `strong`

---

## Gaps & Opportunities / Risks & Hard Problems

- **Opportunity:** genuinely no competitor found after exhaustive search — the strongest "underserved" signal in the entire parent research effort.
- **Opportunity:** the reverse-engineering legal doctrine is actively shifting in the AI era (courts, 2025-2026), which means incumbents built years ago haven't had time to build this feature yet either — a rare moment where "hasn't been built" might mean "the problem is newly urgent," not "no one wants it."
- **Risk — buyer ambiguity:** unresolved as of this doc; see Product review above. This is the top blocker to designing anything, including a customer interview script.
- **Risk — technical difficulty is a different discipline:** reverse-engineerability scoring from binaries/APIs is closer to security research (decompilation, black-box API fingerprinting, side-channel analysis) than to the legal-NLP/document-generation stack every other competitor in this space has built. A team without that specific skill set would need to acquire it.
- **Risk — UPL and liability:** a "you should patent this" or "you should keep this secret" recommendation is closer to legal advice than ObviouslyNot's careful "structured technical disclosure, not legal advice" framing — this product would need an equally careful UPL guardrail, arguably a harder one since the output is a strategic recommendation, not just a fact pattern.
- **Risk — thin evidence:** every claim above is absence-based (no competitor found) rather than demand-based (no confirmed willingness to pay). This is explicitly flagged as the weakest link in the parent brief's evidence chain.

---

## Recommended Next Step

**Do not build a prototype yet.** Run 5-10 structured customer-discovery interviews with people who make this decision today — in-house IP counsel at deep-tech/SaaS companies, and patent attorneys with a mixed patent/trade-secret practice — to resolve three things before any design or code:

1. **Who is the real buyer** (in-house counsel vs. law firm vs. self-serve engineering leader)?
2. **Would they trust an automated first-pass score** on this decision, or is it the kind of judgment call that stays irreducibly human regardless of evidence quality?
3. **What would the minimum credible evidence trail look like** for them to act on a recommendation — i.e., what's the bar for "trustworthy," not just "accurate"?

Only after those three are answered does this become a `Build RFC` candidate for `octocode-rfc-generator`.

---

## Open Questions

- [ ] Who is the primary buyer: in-house IP counsel, outside patent attorneys, or engineering leadership self-serving before ever engaging counsel?
- [ ] Would this be sold standalone, or pitched as a feature/API integration into an existing platform (DeepIP, Patlytics, Lightbringer)?
- [ ] What's the minimum technical capability needed for a credible first pass — static analysis of source code only, or does it need to extend to compiled binaries and live API behavioral fingerprinting to be trustworthy?
- [ ] Does UPL risk materially change if the output is framed as "reverse-engineering risk score + evidence" (a fact pattern) rather than "you should patent this" (a recommendation)?
- [ ] Is there a cheaper way to validate this than interviews — e.g., a landing page + waitlist targeted at IP counsel LinkedIn audiences, to test message-market fit before any interviews?

---

## Resources

All sourced from the parent brief's Round 2/3 research; see [`2026-07-07-ai-patent-service-for-orgs.md`](./2026-07-07-ai-patent-service-for-orgs.md) for full citation list and confidence markers on every claim above.

- [Patents vs. Trade Secrets: Do You Need a Patent, or is a Secret Good Enough?](https://ipwatchdog.com/2025/07/22/patents-vs-trade-secrets/) — primary evidence that the manual heuristic is real and current. `moderate`
- [Reverse engineering in the age of AI: Are your trade secrets still safe?](https://masslawyersweekly.com/2025/12/08/reverse-engineering-in-the-age-of-ai-are-your-trade-secrets-still-safe) — evidence the legal doctrine is live/evolving. `strong`
- [Trade Secrecy Meets Generative AI](https://scholarship.kentlaw.iit.edu/cgi/viewcontent.cgi?article=4489&context=cklawreview) — academic corroboration of the same doctrine shift. `strong`
- [AI-Powered Freedom to Operate](https://lumenci.com/blogs/ai-assisted-fto-search) — evidence of the closest adjacent (but not overlapping) automated capability. `moderate`
- [Proprietary vs Patented: Understanding the Key Differences and Impacts](https://arapackelaw.com/intellectual-property/proprietary-vs-patented-2) — evidence the decision framework exists as published content, not automated tooling.
