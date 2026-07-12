# Whitehat Audit: `@anthropic-ai/claude-code` v2.1.197

> Audit date: 2026-07-01  
> Method: npm pack → Mach-O arm64 binary strings extraction + Bun SEA JS bundle analysis  
> Binary: 227MB, Mach-O 64-bit arm64, Bun Single Executable Application  
> Verdict: **`understood / no risk`** — no supply-chain indicators, no passive exfiltration

---

## 1. PII & Logging

### 1.1 IP Address Collection

**Trigger:** User-initiated bug report only (`bun report`).  
**Endpoint:** `https://bun.report/v1/feedback` (Bun runtime relay — NOT Anthropic).  
**Data collected:**

```js
// From embedded JS bundle — runs only on explicit feedback submission
let S = "none", A = "none";
const ifaces = os.networkInterfaces() || {};
for (const [, addrs] of Object.entries(ifaces))
  for (const M of addrs || [])
    if (M.family === "IPv4") {
      if (M.internal) A = v(M, A);  // local interface IP
      else            S = v(M, S);  // external-facing IP
    }
$.append("localIPSupport", A);   // ← capability flag derived from local IP
$.append("remoteIPSupport", S);  // ← capability flag derived from external IP
```

**Severity:** `medium` — IP is read but only on voluntary submission, labeled as "support" capability.

---

### 1.2 Timezone Collection

**Trigger:** When user runs `/schedule` command.  
**Endpoint:** Injected into agent system prompt → sent with session to `api.anthropic.com/v1/sessions`.

```js
const l = Intl.DateTimeFormat().resolvedOptions().timeZone;
// e.g. "America/New_York" — included in scheduler prompt for cron expression context
```

**Severity:** `low` — expected for scheduling; disclosed in prompt context.

---

### 1.3 Hardware Telemetry (bug reports only)

Sent to `https://bun.report/v1/feedback` on voluntary bug report:

| Field | Source |
|---|---|
| `platform` | `"darwin"` hardcoded at build time |
| `arch` | `"arm64"` hardcoded at build time |
| `bunRevision` | Bun runtime build hash |
| `hardwareConcurrency` | `navigator.hardwareConcurrency` |
| `availableMemory` | `process.availableMemory()` |
| `totalMemory` | `os.totalmem()` |
| `osVersion` | `os.version()` |
| `osRelease` | `os.release()` |

**Severity:** `low` — voluntary path only.

---

### 1.4 Grove — Training Data Consent System

Grove is Anthropic's opt-in mechanism for using conversation data to improve models.

**Key endpoints:**
- `POST /api/oauth/account/grove_notice_viewed` — logged when user first sees consent dialog
- `GET/POST` grove settings (implied by `api_grove_settings_update` event)
- `grove_enabled` boolean on account object

**Telemetry on toggle:**
```js
G("tengu_grove_policy_toggled", { state: c.grove_enabled, location: Ve("settings") })
```

**Opt-out URL:** `https://claude.ai/settings/data-privacy-controls`

**Severity:** `info` — disclosed, opt-in by default (not opt-out).

---

### 1.5 Telemetry Event System

**Scale:** 1,449 unique `tengu_*` event names in binary.  
**Functions:** `G()` fire-and-forget · `He()` success · `De()` error · `xt()` warning  
**Endpoint:** Proxied through `api.anthropic.com` (no separate Statsig hostname found).

Events carry **operational metadata only** — no evidence of code content, file paths, or prompt text in event payloads. Sample events:

| Event | Data |
|---|---|
| `tengu_api_query` | Model name, token counts |
| `tengu_grove_policy_toggled` | Training opt-in state |
| `tengu_image_resize` | Image size bytes, dimensions |
| `coordinator_mode_start` | Mode activation (no payload) |
| `tengu_reactive_compact_attempt` | Attempt#, group counts |
| `tengu_session_forked_branches_fetched` | Branch count statistics |

---

### 1.6 Session / Account Tracking

- `session_id` is pervasive across all API calls and websocket headers
- OAuth `account_id` tied to Claude.ai login
- No persistent `installId` found — `CLAUDE_CODE_SESSION_ID` env var seeds session identity

---

## 2. Agent Prompts & Instructions

### 2.1 System Prompt Variants (3)

```
Variant 1 — Standard CLI (interactive):
  "You are Claude Code, Anthropic's official CLI for Claude."

Variant 2 — SDK non-interactive with append:
  "You are Claude Code, Anthropic's official CLI for Claude, running within
  the Claude Agent SDK."

Variant 3 — Pure agent (no Claude Code branding):
  "You are a Claude agent, built on Anthropic's Claude Agent SDK."
```

**Selection logic:**
```js
function selectSystemPrompt(opts) {
  if (provider === "vertex") return VARIANT_1;
  if (opts?.isNonInteractive) {
    return opts.hasAppendSystemPrompt ? VARIANT_2 : VARIANT_3;
  }
  return VARIANT_1;
}
```

---

### 2.2 Coordinator / Orchestrator System Prompt

Activated when orchestrator mode starts (`coordinator_mode_start` event):

```
You are Claude Code, an AI assistant that orchestrates software engineering
tasks across multiple workers.

## 1. Your Role
You are a **coordinator**. Your job is to:
- Help the user achieve their goal
- [dispatch work to workers]

## 2. Your Tools
[coordinator-only tools listed]

## 3. Workers
[worker capabilities and constraints]

## 4. Task Workflow
[how to decompose and assign]

## 5. Writing Worker Prompts
- Give enough context about the surrounding problem that the agent can make
  judgment calls rather than just following a narrow instruction.

## 6. Example Session
[worked example]
```

**Key property:** Coordinator prompt is self-contained — workers receive their own isolated prompts, not the coordinator's context.

---

### 2.3 Subagent Restrictions (injected per subagent)

```
[Tool X] is not available inside subagents. Complete the task with the
tools provided and return findings to the orchestrator.

Do NOT spawn subagents with the Agent tool. The "default to forking"
guidance is for the parent; you ARE the fork, execute directly.

Do not spawn subagents.
```

**Registered subagent types:**

| Type | Behavior |
|---|---|
| `"Explore"` | Research-only, no mutations |
| `"Plan"` | Planning-only |
| `"code-reviewer"` | Review mode |
| `"fork"` | Inherits full parent context |
| `"statusline-setup"` | Terminal config helper |
| Custom (via `opts.agentType`) | Plugin/agent definition |

**Isolation control:**
```js
opts.isolation: 'worktree'
// Runs agent in fresh git worktree — EXPENSIVE (~200-500ms + disk)
// Use ONLY when agents mutate files in parallel and would otherwise conflict
```

---

### 2.4 Agent Memory Instructions

Injected when user mentions "memory", "remember", "persist", etc.:

```
7. **Agent Memory Instructions**: If the user mentions "memory", "remember",
"learn", "persist", or similar concepts, OR if the agent would benefit from
building up knowledge across conversations (e.g., code reviewers learning
patterns, architects learning codebase structure, etc.), include domain-specific
memory update instructions in the systemPrompt.
```

---

### 2.5 Compact / Summarization Prompt

Fires when context window fills (`tengu_reactive_compact_attempt`):

```
REMINDER: Do NOT call any tools. Respond with plain text only —
an <analysis> block followed by a <summary> block. Tool calls will be
rejected and you will fail the task.
```

**Flow:**
1. Segment messages into groups
2. Try to summarize oldest N groups
3. On `prompt_too_long` → increase preserve window, retry
4. On success → inject summary as `isCompactSummary:true` message

---

### 2.6 Best Practices Reference (embedded in binary)

Large SDK guide embedded as a string constant. Key excerpts:

```markdown
- At `xhigh` or `max`, set a large `max_tokens` — start at 64K and tune.

- opts.isolation: 'worktree' — EXPENSIVE, use ONLY for parallel file mutations.

- [TUNE] Add search-first instruction; add explicit triggering guidance for
  subagents, file-based memory, and custom tools (4.8 under-reaches for these
  by default) — in the system prompt AND in each tool's description
  (prescriptive "call this when…" descriptions give measurable lift).

- Agents have NO delete — only `archive` (permanent). Confirm before archiving.

- `speed: "fast"` — Opus 4.7 fast mode is deprecated; Opus 4.8 is the durable
  fast-capable tier.
```

---

## 3. Network Endpoints Summary

| Endpoint | Purpose |
|---|---|
| `api.anthropic.com/v1/messages` | LLM inference |
| `api.anthropic.com/v1/sessions` | Cloud session lifecycle |
| `api.anthropic.com/v1/agents` | Managed agent CRUD |
| `api.anthropic.com/v1/environments` | Cloud environment management |
| `api.anthropic.com/v1/files` | File uploads |
| `api.anthropic.com/api/frame/track` | Artifact publish tracking |
| `api.anthropic.com/api/frame/deploy/*` | Artifact deployment |
| `api.anthropic.com/api/oauth/account/grove_notice_viewed` | Training consent tracking |
| `claude.ai/api/*` | OAuth, account management |
| `bun.report/v1/feedback` | Bug report (Bun, not Anthropic) |
| `storage.googleapis.com` | Artifact storage (signed PUT URLs) |

---

## 4. Verdict

| Finding | Severity | Confidence |
|---|---|---|
| IP address collected in bug reports | medium | confirmed |
| Timezone sent in scheduling prompts | low | confirmed |
| Hardware stats in bug reports | low | confirmed |
| Grove training opt-in tracking | info | confirmed |
| 1,449 telemetry events (metadata only, no content) | medium | confirmed |
| Session/account ID tracked across calls | low | confirmed |
| 3 system prompt variants | info | confirmed |
| Coordinator/orchestrator prompt (multi-agent) | info | confirmed |
| Subagent restrictions injected per agent | info | confirmed |
| Managed Agents SDK guide embedded in binary | info | confirmed |

**Overall: `understood / no risk`**

No supply-chain attack indicators. No `eval()`/`exec()` of remote code. No passive exfiltration of code content or file paths. IP collection is scoped to explicit bug-report submission (Bun runtime artifact). Grove is disclosed and opt-in. 1,449 telemetry events carry operational metadata only — not content. Agent prompts are competent, well-scoped, and anti-injection hardened.
