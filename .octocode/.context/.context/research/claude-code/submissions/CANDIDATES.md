# Model Safety Bug Bounty — All Findings

> cli.js v2.1.92 / v2.1.97 | Validated 2026-04-09 | [Bounty Program](https://support.claude.com/en/articles/12119250-model-safety-bug-bounty-program)

## Master Ranking

| Rank | ID | Finding | Score | Tier | Status |
|------|----|---------|-------|------|--------|
| 1 | **S1** | CLAUDE.md User-Intent Forgery | **10.0** | CRITICAL | Submitted |
| 2 | **S2** | Persistent Cron Classifier Bypass | **9.5** | CRITICAL | Submitted |
| 2 | **S3** | System-Reminder Tag Spoofing | **9.5** | CRITICAL | Submitted |
| 2 | **S6** | Memory-Persistent Jailbreak | **9.5** | CRITICAL | Submitted |
| 2 | **S7** | Stage-1 Token Budget Forced Allow | **9.5** | CRITICAL | Submitted |
| 6 | **S4** | Classifier Rule Injection + Fast-Path | **8.5** | HIGH | Submitted |
| 6 | **S5** | WebFetch Indirect Prompt Injection | **8.5** | HIGH | Submitted |
| 6 | **C5** | Agentic Loop Safety Erosion | **8.5** | HIGH | Validate next |
| 9 | **C3** | Sub-LLM → Primary Model Chain | **8.0** | HIGH | Defer (overlaps S5) |
| 9 | **C7** | MCP Tool Result → Core Safety | **8.0** | HIGH | Needs test infra |
| 11 | **C1** | Classifier Transcript Poisoning | **7.5** | HIGH | Defer (subset of C5) |
| 12 | **C6** | Thinking Tag Injection | **6.0** | MEDIUM | Quick test |

---

## Submitted Findings

### S1: CLAUDE.md User-Intent Forgery — 10.0 CRITICAL

`sfz()`/`thz()` reads CLAUDE.md from disk, wraps it as `role:"user"` with `"should be treated as part of the user's intent"`. Classifier's stage-2 override (`"user explicitly authorized" → shouldBlock:false`) fires on forged text. No CLAUDE.md trust gate. No `isMeta` flag. Deterministic, zero-interaction.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| `thz()` emits `role:"user"` + intent preamble | line 2926 (v2.1.97) / 2003 (v2.1.92) | ✅ |
| `<user_claude_md>` wrapping tags | lines 2928-2930 | ✅ |
| Override: `"explicitly and specifically authorized" → shouldBlock:false` | line 2834 / 1911 | ✅ |
| `shouldBlock:y.boolean()` schema | line 2939 | ✅ |
| No `Av("claudemd")` trust gate | 0 hits | ✅ |

**Submission:** `01_claudemd_user_intent_forgery/` — EXPLANATION, WHY_BUG, VALIDATION, POC (marker + dangerous variants, verify.sh)

---

### S2: Persistent Cron Classifier Bypass — 9.5 CRITICAL

Cron prompts in `.claude/scheduled_tasks.json` replay as `role:"user"` via `k57()` → `mode:"prompt"`. Classifier has no rule for "user messages from scheduled tasks." AV-12 variant: direct file write bypasses `CronCreate` classifier entirely.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| `queued_command` → `role:"user"` via `xm4()` | line 1998, charOffset 7,021,282 | ✅ |
| `isMeta:!0` is display-only (48 uses, 0 in security path) | bundle-wide | ✅ |
| Direct write bypasses CronCreate | 7 refs to `scheduled_tasks.json` | ✅ |

**Submission:** `02_cron_classifier_bypass/` — 2 POC variants (direct write + oneshot), verify.sh

---

### S3: `<system-reminder>` Tag Spoofing — 9.5 CRITICAL

15 occurrences of `<system-reminder>` in bundle. Zero nonce, signing, HMAC, stripping, or sanitization. Any input surface (git, files, web, memory, MCP) can inject spoofed `<system-reminder>` tags that the model treats as system-level directives.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| 15 `system-reminder` occurrences | multi-line | ✅ |
| 0 nonce/sign/hmac/verify/strip adjacent | bundle-wide | ✅ |
| Git context raw-interpolated into tag | line 1496 | ✅ |
| Memory files raw-interpolated | line 5045 | ✅ |

**Submission:** `03_system_reminder_spoofing/` — 4 variant POCs (git, file, webfetch, memory)

---

### S4: Classifier Rule Injection + Fast-Path — 8.5 HIGH

`tfz()` uses `.replace()` to inject `settings.local.json` allow/deny rules into the classifier system prompt template. Combined with fast-path: if stage-1 emits `<block>no</block>` within 256 tokens, stage-2 never runs. Requires trust dialog click.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| `tfz()` → `.replace(/<user_allow_rules_to_replace>/)` | line 2013, charOffset 7,025,694 | ✅ |
| `Ng6()` reads settings allow/deny/env | line 2010 | ✅ |
| `Vm4()` fast-path return on `<block>no</block>` | line 2013 | ✅ |

**Submission:** `04_classifier_rule_injection/` — verify.sh with 15 evidence checks

---

### S5: WebFetch Indirect Prompt Injection — 8.5 HIGH

5 attack surfaces: (1) Turndown HTML→MD passthrough, (2) preapproved hosts bypass sub-LLM entirely, (3) sub-LLM has empty system prompt `eK([])`, (4) cache poisoning via 15-min TTL, (5) `skipWebFetchPreflight` disables blocklist.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| `systemPrompt:eK([])` + `hasAppendSystemPrompt:!1` | line 3436 | ✅ |
| `isPreapprovedUrl` (Z17) in exports | line 3136 | ✅ |
| `checkDomainBlocklist` → `api.anthropic.com/api/web/domain_info` | line 3136 | ✅ |
| Turndown escapes only MD metacharacters, not prompt injection | lines 3122-3134 | ✅ |

**Submission:** `05_webfetch_indirect_prompt_injection/` — POC with HTTP server, chaining table

---

### S6: Memory-Persistent Universal Jailbreak — 9.5 CRITICAL

Memory files at `~/.claude/projects/<hash>/memory/` load every session as `role:"user"` with `isMeta:!0` (display-only). No content validation, no expiry, no change notification. HOME directory — survives repo deletion. Most durable persistence mechanism.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| `nested_memory` → `i8({content:..., isMeta:!0})` | line 5037, charOffset 9,868,237 | ✅ |
| `relevant_memories` → `i8({content:..., isMeta:!0})` | line 5039, charOffset 9,868,358 | ✅ |
| `memoryDir` path in `~/.claude/projects/` | line 7748, charOffset 11,546,609 | ✅ |
| 0 content validation calls on memory | bundle-wide | ✅ |
| 0 expiry/TTL/freshness checks | bundle-wide | ✅ |

**Submission:** `06_memory_persistent_jailbreak/` — POC with marker payload, durability test (survives rm -rf repo)

---

### S7: Stage-1 Token Budget Forced Allow — 9.5 CRITICAL

Stage-1 classifier gets 256 tokens (`max_tokens:(w==="fast"?256:64)+Z`). If `<block>no</block>` emitted within budget → hard return, stage-2 **skipped entirely**. Stage-1 instruction says "does NOT apply user intent" but stage-2 (which does) never runs. Context biasing forces fast-path allow.

| Evidence | Location | Confirmed |
|----------|----------|-----------|
| `max_tokens:(w==="fast"?256:64)+Z` | line 2936 (v2.1.97) / 2015 (v2.1.92) | ✅ |
| `"Allowed by fast classifier"` hard-return string | line 2936 | ✅ |
| `Vm4()` parses first `<block>` tag, returns immediately | line 2013 | ✅ |
| Stage-1 instruction defers user intent to stage-2 | classifier template | ✅ |
| 0 probabilistic stage-2 sampling on fast-path allow | bundle-wide | ✅ |

**Submission:** `07_token_budget_forced_allow/` — POC with context-biasing CLAUDE.md

---

## Remaining Candidates

### C5: Agentic Loop Safety Erosion — 8.5 HIGH → VALIDATE NEXT

Each auto-mode iteration's tool output shifts context toward permissiveness. No safety reset. Both classifier and model susceptible to in-context learning. After N iterations, previously-blocked actions are allowed.

| Claim | Confirmed |
|-------|-----------|
| No safety reset between tool calls in auto-mode | ✅ (0 hits for reset/clear) |
| Classifier receives full accumulated transcript (no windowing) | ✅ |
| `tool_result` → `role:"user"` (153 refs, all flattened) | ✅ |
| Auto-compact preserves semantics, doesn't sanitize | ✅ |
| 0 drift/erosion detection in classifier | ✅ |

```
Iter 0: clean context → classifier blocks dangerous action
Iter 1-N: boundary-adjacent tool outputs accumulate as role:"user"
Iter N: same action now allowed — classifier context saturated
```

**Verdict:** Highest-priority remaining. Novel attack class. Needs empirical degradation curve (block rate at iter 0 vs N). If demonstrated → CRITICAL.

---

### C3: Sub-LLM → Primary Model Chain — 8.0 HIGH → DEFER

Sub-LLM (`eK([])`, zero safety instructions) acts as content **amplifier** — web page jailbreaks it → it generates harmful content → primary model receives as `role:"user"`.

| Claim | Confirmed |
|-------|-----------|
| `systemPrompt:eK([])` at `querySource:"web_fetch_apply"` | ✅ (line 3436) |
| `hasAppendSystemPrompt:!1` | ✅ (line 3436) |
| 0 content filters between sub-LLM output and primary model | ✅ |

**Verdict:** Code confirmed. Overlaps S5 (same pipeline). Differentiator: S5=IPI, C3=content amplification. Only pursue if S5 rejected.

---

### C7: MCP Tool Result → Core Safety — 8.0 HIGH → NEEDS INFRA

MCP results arrive as `role:"user"` with zero content filtering. One-time per-server approval, then no per-response validation. Targets Constitutional AI safety, not just classifier.

| Claim | Confirmed |
|-------|-----------|
| 40 mcp+tool_result cross-references | ✅ |
| 0 MCP-specific content sanitization | ✅ |
| No `source` provenance on tool_result | ✅ |
| 170+ validate/sanitize calls exist, 0 for MCP content | ✅ |

**Verdict:** Gap is real. Needs test MCP server. Risk: "user installed malware" argument. Counter: trust-once-no-filter is the bug.

---

### C1: Classifier Transcript Poisoning — 7.5 HIGH → DEFER

Many-shot jailbreak targeting classifier LLM via accumulated `tool_result` precedent. Specific instance of C5.

| Claim | Confirmed |
|-------|-----------|
| Classifier gets full transcript, no windowing | ✅ |
| `tool_result` → `role:"user"` (153 refs) | ✅ |
| No context reset between classifications | ✅ |

**Verdict:** Defer. Submit C5 first (broader). C1 is a sub-case.

---

### C6: Thinking Tag Injection — 6.0 MEDIUM → QUICK TEST

`Bm4()` strips `<thinking>` from classifier **output** only. Input `<thinking>` tags (via CLAUDE.md/memory/tool_result) pass through unstripped → may steer classifier reasoning.

| Claim | Confirmed |
|-------|-----------|
| `Bm4()` exists, operates on output only | ✅ (1 match, call site is post-response) |
| `<thinking>` in bundle: 6 hits, 4 in prompt examples | ✅ |
| 0 input sanitization for `<thinking>` | ✅ |

**Verdict:** Structural prerequisites confirmed. Unknown: whether classifier LLM follows pre-filled thinking. 10-min experiment. If works → 8.0+. If not → drop.

---

## Priority Queue

| # | Candidate | Effort | Yield |
|---|-----------|--------|-------|
| 1 | **C5** — empirical erosion curve | HIGH | CRITICAL if demonstrated |
| 2 | **C6** — 10-min thinking tag test | LOW | HIGH if works, DROP if not |
| 3 | **C7** — build test MCP server | MEDIUM | HIGH (supply-chain angle) |
| 4 | **C3** — only if S5 rejected | LOW | MEDIUM |
| 5 | **C1** — only after C5 | LOW | MEDIUM |

---

## Kill Chain

```
S1 (intent forgery) ──┐
                       ├──▶ S4 (rule injection) ──▶ S3 (system-reminder) ──▶ S2 (cron persist)
S5 (webfetch IPI) ────┘                                                      │
                                                                              ▼
                                                                       S6 (memory persist) ✅
                                                                              │
                                                                              ▼
                                                              C5 (agentic erosion) ← NEXT

S7 (token budget) ✅ ─────── force multiplier, any stage
C3 (sub-LLM chain) ──────── extends S5, content amplification
C7 (MCP supply chain) ────── parallel entry to S1/S5
C6 (thinking tags) ────────── experimental amplifier
C1 (transcript poison) ────── specific instance of C5
```
