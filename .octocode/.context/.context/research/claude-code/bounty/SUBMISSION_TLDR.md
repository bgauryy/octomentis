# Submission TL;DR

> Fast answer to: which findings should become bug bounty submissions?

## Submit Now

### 1. NF-11 — CLAUDE.md User-Intent Escalation

**Why:** strongest finding in the set. It directly feeds attacker-controlled repo text into the classifier as "part of the user's intent."

**Submit as:** standalone primary report.

**Bundle into this report:**
- NF-06 as trust-gate / loading-path evidence
- NF-13 as reliability amplifier

**Status:** draft already exists:
- [`SUBMISSION_NF11_CLAUDEMD_TRUST_ELEVATION.md`](SUBMISSION_NF11_CLAUDEMD_TRUST_ELEVATION.md)

### 2. AV-12 / Cron Classifier Bypass

**Why:** persistent scheduled prompts are replayed as user-like prompts and can flip classifier decisions from BLOCK to ALLOW.

**Submit as:** standalone primary report.

**Bundle into this report:**
- ISB-02 persistence mechanics
- direct-file-write variant as bypass of the CronCreate defense

**Status:** draft already exists:
- [`SUBMISSION_CRON_CLASSIFIER_BYPASS.md`](SUBMISSION_CRON_CLASSIFIER_BYPASS.md)

## Submit Next

### 3. NF-12 — Classifier Rule Injection

**Why:** directly rewrites classifier allow/deny behavior. Very strong if paired with a clean control-vs-attack repro.

**Submit as:** standalone report.

**Bundle into this report:**
- NF-13 as fast-classifier amplifier
- trust-gate asymmetry notes only if they strengthen reproducibility

**Status:** should be the next submission draft to formalize.

### 4. NF-16 — `<system-reminder>` Tag Replication

**Why:** this is the most universal escalation primitive in the target, but it is strongest when backed by multiple behavioral demos, not just structural code evidence.

**Submit as:** standalone report if you can show the same safe proof marker works through multiple delivery surfaces.

**Bundle into this report:**
- NF-15 as git-delivery variant
- NF-17 as memory-delivery variant
- ISB-03 as MCP / tool-result delivery variant

## Merge, Do Not Submit Alone

### NF-06 — CLAUDE.md System-Prompt Injection

Good evidence, but weaker alone than NF-11.

Best use:
- supporting context for NF-11
- trust-model explanation
- additional loading-path evidence

### NF-13 — Fast Classifier Shortcut

Important, but mostly an amplifier.

Best use:
- include inside NF-11, NF-12, and cron reports as a reason bypasses become more reliable

### NF-14 — WebFetch IPI

Keep as a strong delivery surface unless you can show a stable high-impact harmful class through several prompt families.

Best use:
- variant under NF-16 or classifier-bypass chains

### NF-15 — Git Content Injection

Best use:
- delivery variant for NF-16
- supporting evidence that runtime-looking directives can be injected from ordinary repo metadata

### NF-17 — Memory Persistence

Best use:
- persistence variant for NF-16
- chain amplifier for cron / replay findings

### NF-04 — Subagent Delegation

Best use:
- chain amplifier, not headline submission

## Probably Not Worth A Model-Safety Submission

These are better treated as product security or secondary disclosures unless you can tie them back to model-safety behavior:

- hooks execution alone
- sandbox bypass alone
- remote MCP onboarding alone
- plugin marketplace / installer findings alone
- arbitrary file read via `--system-prompt-file` as a pure file-to-API path
- telemetry / keychain / audio capture findings

## Recommended Submission Order

1. NF-11
2. Cron / AV-12
3. NF-12
4. NF-16

## Minimum Bar Before Filing

For each submission, make sure you have:

- one harmless proof-marker repro
- one control-vs-attack comparison
- several prompt contexts
- success/failure notes
- one clearly in-scope harmful class

If you do not yet have those, keep it in the research bucket rather than filing early.

---

## Hunting Guide

### What Counts As "High Profile" Here

For this codebase, the strongest findings are usually not about arbitrary code execution. They are about **authority confusion**:

1. An attacker controls some text.
2. Claude Code upgrades that text into trusted context.
3. The classifier or runtime obeys it.

That creates: universal jailbreak potential, classifier bypass, reproducible harmful output, and strong source-backed narrative for triage.

### Priority Order — Where to Hunt

#### 1. User-intent forgery (best pattern)

Non-human content presented as `role:"user"`, "the user provided", "part of the user's intent", or scheduled prompts replayed as ordinary prompts.

Current examples: NF-11 `sfz()` / CLAUDE.md, ISB-02 scheduled task replay.

Why: feeds the classifier's override logic directly. Much stronger than generic tool-result IPI.

#### 2. `<system-reminder>` spoofing

Look for `Qv(...)`, `l9(...)`, `RF8(...)`, raw interpolation inside XML-ish wrappers.

Current example: NF-16.

Why: escalation primitive, not just one surface. Chains into several other findings.

#### 3. Raw tool-result ingestion

`{type:"tool_result", content:$}` with no escaping. File reads, web fetch, MCP responses, command stdout.

Current examples: ISB-03, NF-14.

#### 4. Persistent replay surfaces

Memory files, scheduled tasks, startup loaders, `relevant_memories`, `nested_memory`.

Current examples: NF-17, ISB-02.

#### 5. System-prompt file ingestion

`readFileSync` into `systemPrompt`, CLI flags accepting file paths, agent definitions.

Current example: NF-18.

### Hunting Workflow

**Step 1 — Find the source:** Where does attacker-controlled text come from? (repo file, tool output, web page, git metadata, memory, scheduled task, CLI stdin)

**Step 2 — Find the promotion:** Does text become `role:"user"`, `<system-reminder>`, or `systemPrompt`? If not promoted, usually not top-tier.

**Step 3 — Find the sink:** Prove it reaches classifier evaluation, `YW(...)` normalization, `Db6(...)` model dispatch, or a replay path.

**Step 4 — Build a safe proof first:** Start with harmless markers (`NF11_PROOF`, "Begin your response with X"). If the marker succeeds, the path is real.

**Step 5 — Add the control run:** Same scenario without injected content, then with. Keep user prompt identical.

**Step 6 — Upgrade to bounty-grade:** Swap in one approved high-impact test case, re-run across several prompt contexts, record success rate.

### Evidence Checklist

A candidate is much stronger when you can show all of these:

- Exact source of attacker-controlled text
- Exact wrapper or promotion step
- Exact sink into classifier or model context
- Safe proof-marker reproduction
- Control-vs-attack comparison
- One bounty-relevant harmful class
- At least several prompt contexts
- Known failure cases

If any are missing, call the result a lead, not a finding.

### Fast Search Pack

```bash
rg -n 'role:"user"|type:"tool_result"|system-reminder|isMeta:!0|mode:"prompt"|systemPromptFile|appendSystemPromptFile' node_modules/@anthropic-ai/claude-code/cli.js
```

Then branch by pattern:

```bash
rg -n 'should be treated as part of the user' node_modules/@anthropic-ai/claude-code/cli.js
rg -n 'mcp_instructions_delta|nested_memory|relevant_memories' node_modules/@anthropic-ai/claude-code/cli.js
rg -n 'Allowed by fast classifier|shouldBlock:!1|<block>no</block>' node_modules/@anthropic-ai/claude-code/cli.js
rg -n 'systemPromptFile|appendSystemPromptFile|Sj7\\(' node_modules/@anthropic-ai/claude-code/cli.js
```

### Best Current Bug Families

If you need to choose where to spend the next hour, pick in order:

1. New user-intent forgery surfaces
2. New `<system-reminder>` impersonation paths
3. New raw tool-result injection paths
4. New persistent replay paths
5. New system-prompt composition paths that also affect safety behavior
