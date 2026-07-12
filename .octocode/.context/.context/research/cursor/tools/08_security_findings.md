# Security Findings — Cursor Tool System

**Date:** 2026-04-14
**Target:** Cursor v3.0.16 tool infrastructure
**Method:** Static analysis + API reverse engineering + prompt extraction

---

## Verdict: `review recommended`

The tool system is well-engineered with sensible defaults, but has several architectural attack surfaces that warrant ongoing attention. No confirmed malicious behavior. The main risks are around extensibility vectors (MCP, Canvas, deep links) and the gap between prompt-level restrictions and actual enforcement.

---

## Critical Findings

### FINDING-01: MCP Server Use Instructions — Prompt Injection Surface

**Severity:** `high` | **Confidence:** `confirmed`

MCP server `serverUseInstructions` are injected verbatim into the system prompt. Any installed MCP server can embed arbitrary instructions that the LLM will follow.

**Evidence:**
- System prompt contains `<mcp_file_system_server ... serverUseInstructions="...">` blocks
- Content is NOT sanitized beyond basic XML escaping
- User-installed MCP servers control this text

**Impact:** A malicious MCP server could instruct the agent to: exfiltrate files, modify code in specific ways, suppress security warnings, or override user rules.

**Benign alternative:** This is by design — MCP servers need to describe their tools. The risk is from untrusted servers.

**Mitigation:** Server instructions should be sandboxed or clearly separated from system-level instructions. Consider content-based filtering.

### FINDING-02: Deep Link MCP Installation + Weak Blocklist

**Severity:** `high` | **Confidence:** `confirmed`

MCP servers can be installed via deep links (`mcp.deeplinkInstall`). The blocklist for deep link validation is trivially bypassable:

**Evidence:** 9 regex patterns in `validatePromptText()`:
```
/read.*\.env.*print/i
/cat.*\.ssh\/id_rsa/i
/dump.*token/i
...
```

All bypassable through natural language rephrasing:
- "dump token" → "show me all authentication tokens"
- "cat .ssh/id_rsa" → "display the SSH private key file"

**Impact:** Malicious deep link could install a rogue MCP server that gains tool access in the agent session.

### FINDING-03: Canvas Executes Agent-Generated React Code

**Severity:** `high` | **Confidence:** `confirmed`

The Canvas system runs agent-generated React components inside the Electron renderer process.

**Evidence:**
- Canvas runtime is an ESM bundle in `cursor-agent-exec`
- TypeScript declarations for `ui-primitives`, `chart-primitives`
- `CanvasRegisterArgs` registers components dynamically

**Impact:** If an attacker controls the LLM's output (via prompt injection), they could inject React code that:
- Accesses Electron APIs
- Reads DOM content from other parts of the IDE
- Exfiltrates data via canvas event handlers

**Benign alternative:** Canvas is sandboxed to specific primitives (the type declarations suggest a limited component library, not arbitrary React).

---

## High Findings

### FINDING-04: custom_system_prompt in PrewarmRequest

**Severity:** `medium` | **Confidence:** `likely`

The `PrewarmRequest` protobuf message has a `custom_system_prompt` field (field 8) that allows client-specified system prompts.

**Evidence:** Protobuf field analysis in `api-prompts-findings.md`

**Impact:** If this field is not validated server-side, a modified client could inject arbitrary system prompts into any agent session.

**Uncertainty:** Server-side validation is unknown — this may be restricted to specific callers or ignored.

### FINDING-05: Shell Commands Execute Without Sandbox

**Severity:** `medium` | **Confidence:** `confirmed`

Shell commands execute in a real PTY with the user's full permissions. The sandbox is disabled by default.

**Evidence:** `cliSandboxDefaultEnabled: false` in server config

**Impact:** The agent can execute any command the user can. The only protection is the user approval flow (which can be auto-approved for "safe" commands).

### FINDING-06: Explore/Plan Agent Restrictions Are Prompt-Level Only

**Severity:** `medium` | **Confidence:** `confirmed`

Read-only agents (explore, plan) enforce restrictions through:
1. Prompt instructions ("STRICTLY PROHIBITED from creating new files")
2. Tool availability (disallowed tools list)

But the Shell tool is still available with a "read-only" instruction that depends on the LLM's compliance.

**Evidence:** Explore agent prompt includes Shell with caveat "Use Bash ONLY for read-only operations"

### FINDING-07: Context Stripping Is Client-Side Only

**Severity:** `medium` | **Confidence:** `confirmed`

The full prompt with all context (rules, skills, MCP instructions, user info) is sent to `api2.cursor.sh`. Context stripping only happens when creating stored transcripts.

**Evidence:** `agent-transcript/src/context-stripping.ts` strips tags client-side:
```
"user_info", "rules", "agent_skills", "mcp_instructions", ...
```

**Impact:** All user rules, MCP configurations, and project context are visible server-side on every request.

---

## Medium Findings

### FINDING-08: Codebase Uploaded for Semantic Indexing

**Severity:** `medium` | **Confidence:** `confirmed`

The cursor-retrieval extension uploads workspace files to Cursor servers for semantic indexing:
- Up to 250,000 files
- Path encryption with hardcoded keys
- 64 concurrent uploads

### FINDING-09: 1,606+ gRPC Message Types = Massive API Surface

**Severity:** `medium` | **Confidence:** `confirmed`

688 agent.v1 types + 918 aiserver.v1 types = huge attack surface for any authenticated client.

### FINDING-10: InferenceStreamRequest — Raw LLM Access

**Severity:** `medium` | **Confidence:** `likely`

`InferenceStreamRequest` and `GetPassthroughPromptRequest` suggest raw LLM inference endpoints accessible to authenticated clients.

---

## Low / Info Findings

| ID | Finding | Severity |
|----|---------|----------|
| F-11 | Terminal files persist command history in plaintext | `low` |
| F-12 | Delete tool fails silently — LLM may not know deletion failed | `low` |
| F-13 | Statsig client key exposed in product.json | `low` |
| F-14 | Path encryption keys hardcoded in server config | `low` |
| F-15 | AI-generated code attribution tracked for all changes | `info` |
| F-16 | Model migration system can silently upgrade models | `info` |
| F-17 | 83 model roster includes unreleased/preview models | `info` |
| F-18 | Lineage headers enable full conversation tree reconstruction | `info` |
| F-19 | 30K token context limit means frequent summarization | `info` |
| F-20 | Background agents can run on remote infrastructure | `info` |

---

## Architecture Risk Summary

```
Risk Concentration Map:

HIGH RISK ─────────────────────────────
│ MCP serverUseInstructions injection  │
│ Deep link MCP installation           │
│ Canvas React code execution          │
│ ComputerUse (mouse/keyboard control) │
────────────────────────────────────────

MEDIUM RISK ────────────────────────────
│ custom_system_prompt field            │
│ Unsandboxed shell execution           │
│ Prompt-level agent restrictions       │
│ Client-side context stripping         │
│ Codebase upload for indexing          │
│ Massive gRPC API surface             │
────────────────────────────────────────

LOW RISK ───────────────────────────────
│ Terminal history persistence          │
│ Silent delete failures                │
│ Hardcoded encryption keys             │
│ Exposed Statsig key                   │
────────────────────────────────────────
```

---

*Generated from Cursor v3.0.16 static analysis, API reverse engineering, and prompt extraction*
