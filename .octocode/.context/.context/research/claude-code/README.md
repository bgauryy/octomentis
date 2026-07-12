# Claude Code CLI — Security Research

> **Target:** `@anthropic-ai/claude-code@2.1.92` — `cli.js` (13,221,767 bytes, minified ESM bundle)
> **Date:** 2026-04-05 | **Validated:** 2026-04-06 | **Tools:** Octocode + local-explorer-mcp `analyze_minified_js`

---

## Bounty Scope

Does the finding cause **the model** to bypass **its own safety classifier**?

| In scope | Out of scope |
|----------|-------------|
| Universal jailbreaks (reliable, broad) | CSRF / XSS / SQL injection |
| Classifier bypass (Constitutional Classifiers) | Privilege escalation in infra |
| Indirect prompt injection → model bypasses its own rules | Code execution via config (model not involved) |
| Structural gaps in classifier design | Runtime security (sandbox, permissions) |

If the **model never decides** anything, it is **product security**, not model safety.

Start here if you are extending this research:
- [`EXECUTION_FLOW.md`](EXECUTION_FLOW.md) — unified reference: execution flow, input legitimization, classifier pipeline, bug traces, hunting patterns, and defensive gaps
- [`bounty/SUBMISSION_TLDR.md`](bounty/SUBMISSION_TLDR.md) — filing plan + hunting guide (incorporates playbook)

---

## TL;DR Submission Breakdown

If the goal is to turn this research into actual bounty reports:

- **Submit now:** NF-11 and the cron classifier-bypass report
- **Submit next:** NF-12 and NF-16
- **Merge, do not submit alone:** NF-06, NF-13, NF-14, NF-15, NF-17, NF-04
- **Usually product security / lower priority for this track:** hooks, sandbox, remote MCP onboarding, arbitrary-file-read-only paths

Full breakdown:
- [`bounty/SUBMISSION_TLDR.md`](bounty/SUBMISSION_TLDR.md)

---

## Findings

The safety classifier is entirely prompt-instruction-based — no hard code enforces the BLOCK list. Six structural gaps enable bypass.

### Bounty-Eligible (Model Safety)

| # | ID | Sev | Score | Gap | Gate | Function | Offset | Status | Links |
|---|-----|-----|-------|-----|------|----------|--------|--------|-------|
| 1 | **NF-11** | **CRIT** | **10/10** | CLAUDE.md framed as "user intent" → classifier override | **None** | `sfz()` | `7022896` | Confirmed | [finding](findings/09_NF11_CLAUDEMD_USER_INTENT_ESCALATION.md), [PoC](pocs/CLAUDE_MD_Trust_Elevation/), [submission](bounty/SUBMISSION_NF11_CLAUDEMD_TRUST_ELEVATION.md) |
| 2 | **NF-16** | **CRIT** | **9.5/10** | `<system-reminder>` tag replication — any external content impersonates runtime directives | **None** | `RF8()` | `7886` | Confirmed | [finding](findings/14_NF16_SYSTEM_REMINDER_BYPASS.md) |
| 3 | **F-14** | **HIGH** | **9/10** | Cron prompts share `role:"user"` with human input | **None** | `$6O` | `12519922` | Reproduced | [submission](bounty/SUBMISSION_CRON_CLASSIFIER_BYPASS.md), [PoC](pocs/Cron_Task/) |
| 4 | **NF-12** | **HIGH** | **8/10** | Classifier ALLOW/DENY rules replaceable via project settings | Trust dialog | `tfz()` | `7023272` | Confirmed | [finding](findings/10_NF12_CLASSIFIER_RULE_INJECTION.md), [PoC](pocs/Classifier_Rule_Injection/) |
| 5 | **NF-06** | **HIGH** | **7/10** | CLAUDE.md enters as system context, no trust gate | **None** | `Av("claudemd")` → 0 hits | — | Confirmed | [merged into NF-11](findings/09_NF11_CLAUDEMD_USER_INTENT_ESCALATION.md), [PoC](pocs/CLAUDE_MD_System_Prompt_Injection/) |
| 6 | **NF-15** | **HIGH** | **7/10** | Git commit messages/branch names injected into `<system-reminder>` startup block | **None** | `RF8()` | `7886` | Confirmed | [finding](findings/13_NF15_GIT_CONTENT_INJECTION.md) |
| 7 | **NF-17** | **HIGH** | **7/10** | Memory files `~/.claude/projects/*/memory/` — persistent cross-session injection | **None** | `relevant_memories` | `5039` | Confirmed | [finding](findings/15_NF17_MEMORY_PERSISTENCE.md) |
| 8 | **NF-14** | **HIGH** | **6/10** | WebFetch: Turndown passthrough + ~100 preapproved hosts direct to primary model | skipPreflight | `v17`/`T17`/`KqY` | `3066, 3134` | Confirmed | [finding](findings/12_NF14_WEBFETCH_IPI.md) |
| 9 | **NF-04** | **HIGH** | **6/10** | Spawn-time check can't predict runtime behavior (TOCTOU) | None | — | `6999891` | Confirmed | [finding](findings/06_NF04_SUBAGENT_DELEGATION.md) |
| 10 | **NF-18** | **HIGH** | **5/10** | Stdin/`--print` CI injection; `--system-prompt-file` arbitrary file read | None/CLI | L16896 | `16896` | Likely | [finding](findings/16_NF18_STDIN_CLI_INJECTION.md) |
| 11 | **NF-13** | **MED** | **4/10** | Fast classifier (256 tokens) short-circuits to ALLOW | N/A | — | `7026254` | Confirmed | [finding](findings/11_NF13_FAST_CLASSIFIER_SHORTCUT.md) |

**Ranking criteria:** generalized across BLOCK rules, deterministic/stable, high signal-to-noise, novel mechanism, well-documented evidence.

**NF-11** tops because `sfz()` wraps attacker CLAUDE.md as `{role:"user"}` + "user's intent" — directly feeding the classifier's override path. **NF-16** is near-critical because it's an escalation primitive that amplifies every other IPI surface — any injected content can impersonate a runtime system directive.

**NF-13** is a pure amplifier — reduces classifier scrutiny but has no independent bypass capability.

### Product Security (Non-Bounty)

| ID | Sev | Finding | Evidence |
|----|-----|---------|----------|
| NF-01 | HIGH | Hooks execute arbitrary shell from `.claude/settings.local.json` (trust-gated) | `Av("hooks")` @ 8440696, 8445128, 8498685 — [finding](findings/05_NF01_HOOK_RCE.md) |
| F-01 | HIGH | Remote MCP servers gain broad access; `.mcp.json` repo trust; SSE streaming | `cli.js:12998618` |
| F-02 | HIGH | `bypassPermissions` skips all tool prompts in CLI/SDK | `cli.js:13175733` |
| F-03 | HIGH | `dangerouslyDisableSandbox` skips seccomp; Windows has no sandbox | `cli.js:9451634` |
| NF-02 | HIGH | Plugin marketplace installs MCP servers from URLs with auto-update | Line 4758, 6080 |
| NF-05 | MED | Project settings override permissions/sandbox/hooks (trust-gated) | `cli.js:188` |
| F-15 | MED | `.mcp.json` in cloned repos auto-configures MCP servers | `cli.js:10489880` |
| F-04 | MED | Audio capture addon; `AUDIO_CAPTURE_NODE_PATH` env redirects binary | `cli.js:9269000` |
| F-05 | MED | Telemetry `tengu_*` events — no opt-out; Prometheus on port 9464 | `cli.js:7911558` |
| F-06 | MED | API keys in macOS keychain or plaintext fallback | `cli.js:3516317` |
| F-07 | MED | Enterprise MCP blocking requires enterprise config deployed | `cli.js:4968393` |
| F-08 | MED | Opaque vendor binaries — no source or reproducibility artifacts | package.json |
| NF-03 | MED | Grove API team memory — server-controlled privacy config | Line 3999, 2052 |
| NF-07 | MED | `osascript -e` terminal launcher with template literals (macOS) | Line 16669 |
| NF-08 | MED | Hidden `heapdump` tool dumps JS heap to ~/Desktop | Line 6761 |
| NF-09 | LOW | Auto-update TOCTOU race in `.claude/.update.lock` | Line 2130 |
| NF-10 | LOW | Bridge debug commands: `injectFault`, `fireClose` | Line 6772 |
| F-09 | LOW | 20+ `child_process`/`exec`/`spawn` — gated by permissions | `cli.js:892377` |
| F-10 | LOW | 8 `eval`/`new Function`/`vm` — Ajv, Azure, CSS sanitizer; no attacker input | `cli.js:601484` |
| F-11 | LOW | `.ssh`, `.env`, `.npmrc` strings — in policy/help text only | multiple |

---

## New Injection Surfaces (2026-04-06 Audit)

Five new injection surfaces confirmed by 5-agent parallel analysis of `cli.js`:

| ID | Surface | Entry | Severity | Finding |
|----|---------|-------|----------|---------|
| **NF-14** | WebFetch — Turndown HTML→MD passthrough, preapproved host direct | `KqY` @ L3066, `v17` @ L3134 | HIGH | [finding](findings/12_NF14_WEBFETCH_IPI.md) |
| **NF-15** | Git commit messages/branch names/filenames → startup system-reminder | `RF8()` @ L7886 | HIGH | [finding](findings/13_NF15_GIT_CONTENT_INJECTION.md) |
| **NF-16** | `<system-reminder>` tag replication — no signing/nonce | `RF8()` @ L7886 | **CRITICAL** | [finding](findings/14_NF16_SYSTEM_REMINDER_BYPASS.md) |
| **NF-17** | Memory files `~/.claude/projects/*/memory/` — persistent IPI | `relevant_memories` @ L5037 | HIGH | [finding](findings/15_NF17_MEMORY_PERSISTENCE.md) |
| **NF-18** | Stdin/`--print` CLI injection; `--system-prompt-file` arbitrary file read | L16896 | HIGH | [finding](findings/16_NF18_STDIN_CLI_INJECTION.md) |

Also merged into existing findings:
- **ISB-03**: Full tool result pipeline confirmed (3 surfaces — `xN5()`, `mcp_instructions_delta`, task output)
- **NF-06**: 6 additional file-to-prompt paths confirmed (symlinks, traversal depth, memory, `--system-prompt-file`, `nested_memory`, agent definitions)

---

## Kill Chain (NF-11 + NF-12 + NF-13)

```
1. CLAUDE.md with "authorized operations" language
   → sfz() wraps as {role:"user"} + "user intent" (NF-11)
   → Classifier sees "user explicitly authorized"

2. .claude/settings.local.json with custom ALLOW rules (NF-12, trust-gated)
   → tfz() injects into <user_allow_rules_to_replace>
   → BLOCK list disabled for target actions

3. Fast classifier evaluates with 256-token budget (NF-13)
   → Adversarial context + injected rules → <block>no</block>
   → Stage 2 (thinking) never fires → action executes
```

NF-11 alone (no trust gate) is sufficient. NF-12 and NF-13 are amplifiers.

---

## Execution Flow Analysis

The complete execution flow from prompts to classifier decisions is documented in:

**[`EXECUTION_FLOW.md`](EXECUTION_FLOW.md)** — unified reference covering:
- Function map (30+ functions, all validated with charOffsets)
- Architecture diagram, dispatch pattern, input surface inventory (20 surfaces)
- Classifier pipeline (two-stage: TS8 → OZz, fast + thinking)
- Bug traces #1–#5 with inline validation and verbatim code
- Kill chain, role flattening root cause, hunting patterns, grep cheat sheet
- Defensive gaps and replication status

---

## Architecture Documentation

Reverse-engineering groundwork underpinning all findings.

| Doc | Contents | Key Offsets | Links |
|-----|----------|-------------|-------|
| **ISB-01** — Classifier Architecture | BLOCK/ALLOW rules (18 categories), 7 user-intent rules, override flip, hard gates (`ig8()`, enterprise) | `~6996000–7035000`, override `7004584`, schema `7033544`, `ig8()` `9923142` | [finding](findings/02_ISB01_CLASSIFIER_BYPASS.md) |
| **ISB-02** — Cron Persistence | `wS4()` job creation, `zy6()` reader (no schema validation), `$6O` startup loader, `a27()` scheduler | `wS4` `6621431`, `zy6` `6625643`, `$6O` `12519922`, `a27` `12322625` | [finding](findings/03_ISB02_CRONCREATE_PERSISTENCE.md) |
| **ISB-03** — MCP Indirect PI | `.mcp.json` supply chain, context exposure, Rule 6 as only defense | Rule 6 `6996641`, MCP `12998618`, enterprise `4968393` | [finding](findings/04_ISB03_MCP_INDIRECT_PI.md) |
| **Attack Chains** | 5 campaigns ranked by effort/reach/stealth/persistence | — | [finding](findings/08_ATTACK_CHAINS.md) |

### Audit Data

| File | Contents |
|------|----------|
| [`EXECUTION_FLOW.md`](EXECUTION_FLOW.md) | Unified reference: execution flow + input legitimization + bug traces + hunting patterns |
| [`bounty/SUBMISSION_TLDR.md`](bounty/SUBMISSION_TLDR.md) | Filing plan + hunting guide (incorporates playbook) |
| [`audit/README.md`](audit/README.md) | **Master synthesis** — 11 injection surfaces, all byte-offset validated |
| [`audit/flows.md`](audit/flows.md) | 11 call chains: classifier, cron, hooks, CLAUDE.md loading, MCP, sub-agent, settings |
| [`audit/agent1_mcp_injection.md`](audit/agent1_mcp_injection.md) | MCP tool response flows — 5 injection paths, confirmed zero sanitization |
| [`audit/agent2_webfetch_injection.md`](audit/agent2_webfetch_injection.md) | WebFetch pipeline + full classifier architecture with all bypass chains |
| [`audit/agent3_claudemd_injection.md`](audit/agent3_claudemd_injection.md) | CLAUDE.md + 6 additional file-to-prompt paths |
| [`audit/agent4_git_injection.md`](audit/agent4_git_injection.md) | Git content injection — 5 surfaces confirmed |
| [`audit/agent5_ipi_sinks.md`](audit/agent5_ipi_sinks.md) | Complete IPI sink map — 14 sources, 6 attack scenarios |

---

## Directory Layout

```
research/claude-code/
├── README.md                          ← this file
├── EXECUTION_FLOW.md                  ← unified reference (merged from 4 files, deduplicated)
├── audit/                             ← reverse-engineering groundwork
│   ├── flows.md                       — 11 traced call chains
│   ├── agent1_mcp_injection.md        — MCP injection vectors
│   ├── agent2_webfetch_injection.md   — WebFetch injection vectors
│   ├── agent3_claudemd_injection.md   — CLAUDE.md injection vectors
│   ├── agent4_git_injection.md        — Git injection vectors
│   └── agent5_ipi_sinks.md           — IPI sinks analysis
├── findings/                          ← one write-up per finding
│   ├── 02_ISB01_CLASSIFIER_BYPASS.md
│   ├── 03_ISB02_CRONCREATE_PERSISTENCE.md
│   ├── 04_ISB03_MCP_INDIRECT_PI.md       ← UPDATED: mcp_instructions_delta + tool result pipeline
│   ├── 05_NF01_HOOK_RCE.md
│   ├── 06_NF04_SUBAGENT_DELEGATION.md
│   ├── 07_NF06_CLAUDEMD_INJECTION.md     ← MERGED into NF-11
│   ├── 08_ATTACK_CHAINS.md               ← UPDATED: campaigns 6/7/8 added
│   ├── 09_NF11_CLAUDEMD_USER_INTENT_ESCALATION.md
│   ├── 10_NF12_CLASSIFIER_RULE_INJECTION.md
│   ├── 11_NF13_FAST_CLASSIFIER_SHORTCUT.md
│   ├── 12_NF14_WEBFETCH_IPI.md           ← NEW
│   ├── 13_NF15_GIT_CONTENT_INJECTION.md  ← NEW
│   ├── 14_NF16_SYSTEM_REMINDER_BYPASS.md ← NEW (CRITICAL)
│   ├── 15_NF17_MEMORY_PERSISTENCE.md     ← NEW
│   └── 16_NF18_STDIN_CLI_INJECTION.md    ← NEW
├── pocs/                              ← working proof-of-concepts
│   ├── CLAUDE_MD_Trust_Elevation/     — NF-11 PoC (13/13 validations)
│   ├── CLAUDE_MD_System_Prompt_Injection/ — NF-06 PoC (16/16 validations)
│   ├── Classifier_Rule_Injection/     — NF-12 PoC (8/8 validations)
│   ├── Cron_Task/                     — F-14 PoC (3 vectors: MCP + cron + repo trap)
│   └── WebFetch_IPI/                  — NF-14 PoC (9/9 validations, 7-layer guardrail analysis)
└── bounty/                            ← submission drafts
    ├── BOUNTY_FORMAT.md
    ├── MODEL_SAFETY_BUG_BOUNTY_FOCUS.md ← bounty scope criteria
    ├── SUBMISSION_TLDR.md             ← filing plan + hunting guide (consolidated)
    ├── SUBMISSION_NF11_CLAUDEMD_TRUST_ELEVATION.md
    ├── SUBMISSION_CRON_CLASSIFIER_BYPASS.md
    └── SUBMISSION_CLASSIFIER_RULE_INJECTION.md
```

---

## Validation Notes

All findings independently validated against the live `cli.js` bundle using byte-offset extraction (`rg -ob`, `dd`). Each finding write-up includes a **Validation Metadata** section.

**Minor corrections applied during validation:**
- NF-11: XML tag is `<user_claude_md>` not `<claude_md>` (functionally identical)
- ISB-03: `.mcp.json` offset `10489880` points to codebase survey prompt context, not loader itself

## Rating Changes

| Finding | Previous | Current | Reason |
|---------|----------|---------|--------|
| NF-11 | — | BOUNTY-CRITICAL | New — `sfz()` wraps CLAUDE.md as "user intent" → classifier override |
| NF-12 | — | BOUNTY-HIGH | New — classifier rules replaceable via settings (trust-gated) |
| NF-13 | — | BOUNTY-MEDIUM | New — fast classifier can ALLOW without stage 2 (amplifier) |
| NF-06 | BOUNTY-MEDIUM | BOUNTY-HIGH | System-prompt PI, no trust gate proven, enabler for NF-11 |
| NF-01 | BOUNTY-HIGH | BOUNTY-LOW | Product security — model never involved, trust dialog exists |
| NF-02 | BOUNTY-MEDIUM | BOUNTY-LOW | Supply chain, not model behavior |
| NF-03 | BOUNTY-MEDIUM | OUT-OF-SCOPE | Unconfirmed — grove API is privacy toggle |
| NF-05 | BOUNTY-MEDIUM | OUT-OF-SCOPE | Runtime config, not model behavior |
| NF-07 | BOUNTY-LOW | OUT-OF-SCOPE | macOS product security only |
| NF-09 | BOUNTY-LOW | OUT-OF-SCOPE | TOCTOU, zero model angle |

## Network Destinations

| Destination | Purpose |
|-------------|---------|
| `api.anthropic.com` | Model inference (`x-api-key` / Bearer) |
| `claude.ai` | OAuth, account flows |
| `{BASE_API_URL}/api/ws/.../voice_stream` | Voice STT WebSocket |
| User-configured OTLP endpoint | OpenTelemetry export |
| `localhost:{port}` | OAuth redirect / Prometheus (9464) |

Proxy allowlist enforced at `cli.js:4354395`.

## Limitations

- 12.6MB minified megabundle (~16.9k lines, many extremely long)
- LSP has limited effectiveness on minified single-file bundles
- Vendor native binaries are opaque (no source/reproducibility)
- No previous version for delta analysis

## References

- [Model Safety Bug Bounty Program](https://support.claude.com/en/articles/12119250-model-safety-bug-bounty-program)
- [Anthropic Responsible Disclosure](https://www.anthropic.com/responsible-disclosure-policy)
- [NPM](https://www.npmjs.com/package/@anthropic-ai/claude-code) | [Source](https://github.com/anthropics/claude-code)
- [HackerOne Report Assistant](https://hackerone.com/hai/report_assistant?programHandle=anthropic-vdp)
