# Cursor v3.0.16 — Complete Prompt & API Extraction

**Source:** Static analysis of `/Applications/Cursor.app/Contents/Resources/app/` + live API calls
**Date:** 2026-04-14
**Method:** Byte-offset extraction from minified JS bundles + authenticated gRPC-web calls to `api2.cursor.sh`

---

## How Prompts Are Fetched

Cursor uses **bufbuild/connect** (gRPC-web over HTTP/2) to communicate with `api2.cursor.sh`.

### Authentication Required
```
Authorization: Bearer <JWT from cursorAuth/accessToken>
x-cursor-client-version: 3.0.16
x-cursor-client-type: ide
x-cursor-client-os: darwin
x-cursor-client-arch: arm64
x-cursor-client-device-type: desktop
x-cursor-checksum: <computed integrity hash>  ← REQUIRED
x-ghost-mode: true|false
connect-protocol-version: 1
```

### Checksum Algorithm (from bundle)
```javascript
function computeChecksum(machineId, macMachineId) {
  const y = Math.floor(Date.now() / 1e6);
  const bytes = new Uint8Array([
    (y >> 40) & 255, (y >> 32) & 255, (y >> 24) & 255,
    (y >> 16) & 255, (y >> 8) & 255, y & 255
  ]);
  let e = 165;
  for (let t = 0; t < bytes.length; t++) {
    bytes[t] = (bytes[t] ^ e) + t % 256;
    e = bytes[t];
  }
  const prefix = Buffer.from(bytes).toString('base64');
  return macMachineId ? `${prefix}${machineId}/${macMachineId}` : `${prefix}${machineId}`;
}
```

### Prompt Delivery Architecture
| Type | How delivered | Location |
|------|-------------|----------|
| **Main agent system prompt** | Server-side, sent with each StreamChat/agent request | NOT in client bundle |
| **Subagent prompts** (explore, plan, guide, etc.) | Embedded in `cursor-agent/claude-agent-sdk/cli.js` | Client-side |
| **Behavior prompts** (categorization, intent, rules) | Embedded in `workbench.desktop.main.js` as dynamic config fallbacks | Client-side |
| **MCP tool prompts** | Fetched from MCP servers at runtime via `$getMcpLeasePrompts()` | Runtime |
| **Dynamic config prompts** | Fetched from Statsig SDK at startup | Server-side |
| **Custom system prompts** | User-configured, sent via `PrewarmRequest.custom_system_prompt` | Client → Server |

---

## Client-Side Embedded Prompts (18 extracted)

| # | File | Source | Description |
|---|------|--------|-------------|
| 01 | `01_user_intent_analysis.md` | workbench.desktop.main.js | Analyzes user chat transcripts to build a behavioral profile |
| 02 | `02_user_intent_writeback.md` | workbench.desktop.main.js | Follow-up step — writes the user profile to disk |
| 03 | `03_conversation_categorization.md` | workbench.desktop.main.js | Classifies conversations along 5 axes (task, complexity, intent, focus, guidance) |
| 04 | `04_rules_assembly.md` | workbench.desktop.main.js | How `.cursor/rules/` files are injected into system prompt |
| 05 | `05_deeplink_blocklist.md` | cursor-deeplink/dist/main.js | Prompt content validation blocklist (9 regex patterns) |
| 06 | `06_claude_agent_general_purpose.md` | cursor-agent/claude-agent-sdk/cli.js | General-purpose subagent system prompt |
| 07 | `07_claude_agent_explore.md` | cursor-agent/claude-agent-sdk/cli.js | Read-only codebase exploration subagent |
| 08 | `08_claude_agent_plan.md` | cursor-agent/claude-agent-sdk/cli.js | Software architect / planning subagent |
| 09 | `09_claude_agent_guide.md` | cursor-agent/claude-agent-sdk/cli.js | Claude Code guide agent (docs helper) |
| 10 | `10_claude_agent_statusline.md` | cursor-agent/claude-agent-sdk/cli.js | Status line configuration subagent |
| 11 | `11_memory_selector.md` | cursor-agent/claude-agent-sdk/cli.js | Memory file selection prompt |
| 12 | `12_home_directory_agent.md` | cursor-agent-exec/dist/main.js | Home directory workspace agent prompt |
| 13 | `13_mcp_auth_status.md` | workbench.desktop.main.js | MCP authentication status copy/messages |
| 14 | `14_guardrail_sandbox_modes.md` | workbench.desktop.main.js | Sandbox mode descriptions, network policy, YOLO defaults |
| 15 | `15_guardrail_tool_approval.md` | workbench.desktop.main.js | Full tool permission system — denial reasons, approval modes |
| 16 | `16_guardrail_subagent_restrictions.md` | cursor-agent/claude-agent-sdk/cli.js | Subagent tool restrictions, mode guardrails |
| 17 | `17_compaction_system.md` | cursor-agent/claude-agent-sdk/cli.js | Compaction: triggers, prompts, flows, malware guardrail |
| 18 | `18_session_memory.md` | cursor-agent/claude-agent-sdk/cli.js | Session memory: note-taking, forked LLM, skill generation |

**Combined file:** `ALL_PROMPTS_COMBINED.md` (759 lines, 35KB)

---

## API-Fetched Data

### Live Endpoint Responses (2026-04-14)

| Endpoint | Result |
|----------|--------|
| `AgentService/GetUsableModels` | **83 models** — see `models.json` |
| `AgentService/NameAgent` | Works — returns AI-generated conversation names |
| `AgentService/CreateTranscriptOverview` | Works — returns conversation summaries |
| `AiService/GetUserInstructions` | Returns `"# No Instructions Found"` (no recent history) |
| `AiService/GetSimplePrompt` | Requires specific query context |
| `AiService/GetPassthroughPrompt` | Unimplemented |
| `AiService/GetEvaluationPrompt` | Unimplemented |
| `AiService/ModelQuery` | Deprecated |
| `AiService/GetUserInfo` | Deprecated |

### Available Models (83 total) — `models.json`

**OpenAI:**
- GPT-5.4 (low/medium/high/xhigh, fast variants)
- GPT-5.4-mini (none/low/medium/high/xhigh)
- GPT-5.4-nano (none/low/medium/high/xhigh)
- GPT-5.3-codex (low/med/high/xhigh, fast variants + Spark preview)
- GPT-5.2 (low/med/high/xhigh + codex variants)
- GPT-5.1 (low/med/high + codex-max + codex-mini)
- GPT-5-mini

**Anthropic:**
- Claude 4.6 Opus (high/max, thinking variants)
- Claude 4.6 Sonnet (medium, thinking)
- Claude 4.5 Opus (high, thinking)
- Claude 4.5 Sonnet (standard, thinking)
- Claude 4 Sonnet (standard/1m, thinking)

**Google:**
- Gemini 3.1 Pro
- Gemini 3 Flash

**xAI:**
- Grok 4-20 (standard, thinking)

**Moonshot:**
- Kimi K2.5

**Cursor:**
- Composer 1.5, 2, 2-fast
- Default (auto)

---

## gRPC API Surface

Full API documentation: `../.research/api-prompts-findings.md`

- **1,606+ protobuf message types** across `agent.v1` and `aiserver.v1`
- **34 streaming AI endpoints** (chat, edit, completion, agent, bug bot)
- **83 available models**
- **29+ tool types** (Shell, Edit, Write, Read, Grep, Glob, Fetch, WebSearch, Task, etc.)
- **10 subagent types** (Bash, BrowserUse, ComputerUse, Debug, Explore, Shell, etc.)

---

## Notes

- The **main system prompt** (with `<tool_calling>`, `<citing_code>`, `<making_code_changes>`, etc.) is **served from the Cursor API server** at runtime, NOT embedded in the client bundle. It is constructed server-side and included in each agent request.
- The `cursor_blame_conversation_summary_prompts` config ships with empty `prompts: {}` — actual prompts fetched from Statsig dynamic config.
- The `x-cursor-checksum` header is **required** for all API calls — it's a timestamp-based integrity hash using the machine ID.
- Privacy mode (`x-ghost-mode`) controls whether conversation data is used for training.
