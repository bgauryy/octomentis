> **MERGED INTO SUBMISSION_TLDR.md** — This playbook has been consolidated into [SUBMISSION_TLDR.md](SUBMISSION_TLDR.md). This file is retained for reference only.

# High-Profile Bug Playbook

> Companion to `MODEL_SAFETY_BUG_BOUNTY_FOCUS.md`
> Target: `@anthropic-ai/claude-code@2.1.92`

## Purpose

This is the practical hunting guide for this target.

The focus doc tells us **what counts**.
This playbook tells us **where to look first** and **how to turn a lead into a strong submission**.

## TL;DR Submission Breakdown

- **Submit now:** NF-11 and the cron classifier-bypass report
- **Submit next:** NF-12 and NF-16
- **Merge, do not submit alone:** NF-06, NF-13, NF-14, NF-15, NF-17, NF-04
- **Usually not worth a model-safety filing by themselves:** hooks, sandbox, remote MCP onboarding, file-read-only paths

If you just want the filing plan, use:
- [`SUBMISSION_TLDR.md`](SUBMISSION_TLDR.md)

---

## What Counts As "High Profile" Here

For this codebase, the strongest findings are usually not about arbitrary code execution. They are about **authority confusion**:

1. An attacker controls some text.
2. Claude Code upgrades that text into trusted context.
3. The classifier or runtime obeys it.

That creates:
- universal jailbreak potential
- classifier bypass
- reproducible harmful output or tool-action behavior
- strong, source-backed narrative for triage

---

## Priority Order

### 1. User-intent forgery

Best pattern in this target.

Look for non-human content presented as:
- `role:"user"`
- "the user provided"
- "part of the user's intent"
- scheduled prompts replayed as ordinary prompts

Current examples:
- NF-11 `sfz()` / CLAUDE.md user-intent framing
- ISB-02 scheduled task prompt replay

Why it matters:
- This pattern feeds the classifier's override logic directly.
- It is much stronger than generic tool-result IPI.

### 2. `<system-reminder>` spoofing

Second-best pattern.

Look for:
- `Qv(...)`
- `l9(...)`
- `RF8(...)`
- raw interpolation inside XML-ish wrappers

Current example:
- NF-16

Why it matters:
- This is an escalation primitive, not just one surface.
- Once found, it usually chains into several other findings.

### 3. Raw tool-result ingestion

Look for:
- `{type:"tool_result", content:$}`
- no escaping before content insertion
- file reads, web fetch, MCP responses, command stdout

Current examples:
- ISB-03
- NF-14

Why it matters:
- Any attacker-controlled content returned by a tool can become model input on the next turn.

### 4. Persistent replay surfaces

Look for:
- memory files
- scheduled tasks
- startup loaders
- "resume", "relevant_memories", "nested_memory"

Current examples:
- NF-17
- ISB-02

Why it matters:
- Persistence turns a one-off prompt injection into a durable foothold.

### 5. System-prompt file ingestion

Look for:
- `readFileSync` into `systemPrompt`
- CLI flags that accept file paths
- agent definitions appended into system prompt

Current example:
- NF-18

Why it matters:
- Sometimes this is pure product security.
- It becomes bounty-strong when it also changes model or classifier safety behavior.

---

## What Usually Is Not High-Profile Bounty Material

Unless you can clearly connect them back to model-safety behavior, these are usually lower value here:

- hook execution by itself
- sandbox bypass by itself
- MCP onboarding / remote server config by itself
- generic file read / arbitrary path issues by themselves
- telemetry, keychain, or network-destination findings without safety impact

Those can still matter for responsible disclosure. They are just not the fastest path to a top model-safety submission.

---

## Hunting Workflow

### Step 1 — Find the source

Ask:
- Where does attacker-controlled text come from?
- Repo file?
- Tool output?
- Web page?
- Git metadata?
- Memory file?
- Scheduled task?
- CLI stdin?

### Step 2 — Find the promotion

You are looking for text becoming one of:
- `role:"user"`
- `<system-reminder>`
- `systemPrompt`

If the text never gets promoted, it is usually not a top-tier lead.

### Step 3 — Find the sink

Prove it reaches one of:
- classifier evaluation
- `YW(...)` normalization
- `Db6(...)` model dispatch
- a replay path that will hit those later

### Step 4 — Build a safe proof first

Do not begin with dangerous payloads.

Start with a harmless marker such as:
- `NF11_PROOF`
- `NF16_PROOF`
- "Begin your response with X"
- "Mention marker Y before any summary"

If the marker succeeds, the path is real.

### Step 5 — Add the control run

For every candidate:

1. Run the same scenario without the injected content.
2. Run it again with the injected content.
3. Keep the user prompt identical.

This makes triage much easier because the only changed variable is the promoted attacker text.

### Step 6 — Upgrade to bounty-grade

Only after the safe marker works:

1. Swap in one approved high-impact test case from the bounty focus doc.
2. Re-run across several prompt contexts.
3. Record success rate, failure modes, and limits.

This is the point where a neat trick becomes a real submission.

---

## Evidence Checklist

A candidate is much stronger when you can show all of these:

- Exact source of attacker-controlled text
- Exact wrapper or promotion step
- Exact sink into classifier or model context
- Safe proof-marker reproduction
- Control-vs-attack comparison
- One bounty-relevant harmful class
- At least several prompt contexts
- Known failure cases

If any of those are missing, call the result a lead, not a finding.

---

## Fast Search Pack

Use these first:

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

---

## Best Current Bug Families In This Target

If you need to choose where to spend the next hour, pick from this list in order:

1. New user-intent forgery surfaces.
2. New `<system-reminder>` impersonation paths.
3. New raw tool-result injection paths.
4. New persistent replay paths.
5. New system-prompt composition paths that also affect safety behavior.

That is the shortest path to another high-profile finding in this bundle.
