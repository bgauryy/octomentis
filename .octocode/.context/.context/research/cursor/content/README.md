# Cursor API Surface & Prompts — Live Extraction

Extracted via `cursor-api.sh` — reverse-engineered client mimicking how Cursor IDE calls `api2.cursor.sh` over gRPC-web (connect-rpc / `@bufbuild/connect`).

## Quick Links

- **[ALL_PROMPTS.md](ALL_PROMPTS.md)** — All 20 extracted prompts combined
- **[cursor-api.sh](cursor-api.sh)** — The script to reproduce all API calls
- **[server_config_formatted.json](server_config_formatted.json)** — Full server config (25KB)
- **[agent_usable_models_formatted.json](agent_usable_models_formatted.json)** — All 83 AI models

---

## Authentication Protocol

| Header | Value | Source |
|--------|-------|--------|
| `Authorization` | `Bearer <JWT>` | `cursorAuth/accessToken` from `state.vscdb` |
| `x-cursor-checksum` | `<base64(xor_chain(ts))><machineId>` | Reverse-engineered from workbench bundle |
| `x-cursor-client-version` | `3.0.16` | `product.json` |
| `Content-Type` | `application/json` | connect-rpc JSON encoding |
| `connect-protocol-version` | `1` | connect-rpc v1 |

### Checksum Algorithm (reverse-engineered)
```javascript
const y = Math.floor(Date.now() / 1e6);
const b = new Uint8Array([(y>>40)&255,(y>>32)&255,(y>>24)&255,(y>>16)&255,(y>>8)&255,y&255]);
let e = 165;
for (let t = 0; t < b.length; t++) { b[t] = (b[t] ^ e) + t % 256; e = b[t]; }
return Buffer.from(b).toString('base64') + machineId;
```

---

## 20 Extracted Prompts

| # | Prompt | Type |
|---|--------|------|
| 01 | User Intent Analysis | Statsig config — analyzes transcripts for behavior patterns |
| 02 | User Intent Writeback | Generates index.md from analysis |
| 03 | Conversation Categorization | Classifies chats along 5 axes |
| 04 | Rules Assembly | How .cursor/rules/ files are injected |
| 05 | Deeplink Blocklist | Validates prompt text in deep links |
| 06 | Claude Agent — General Purpose | Subagent system prompt |
| 07 | Claude Agent — Explore | Read-only codebase exploration agent |
| 08 | Claude Agent — Plan | Planning/design agent |
| 09 | Claude Agent — Guide | Onboarding/tutorial agent |
| 10 | Claude Agent — Status Line | CLI status bar setup agent |
| 11 | Memory Selector | Selects relevant memory files |
| 12 | Home Directory Agent | Operates in home directory |
| 13 | MCP Auth Status | Authentication status messages |
| 14 | Glass Worktree Mode | Injected for worktree-based Glass sessions |
| 15 | Conversation Summary (Cursor Blame) | Server-controlled via Statsig |
| 16 | Tool Limits Config | ReadFile/EditFile/Search operational limits |
| 17 | Chat Operational Config | Token limits, rules, MCP tool caps |
| 18 | Base System Prompt Fallback | "You are a helpful assistant." |
| 19 | Categorization Schema | Full taxonomy (15 categories, 4 complexity, 4 intent) |
| 20 | Summarization & Model Config | Models for summarization, BugBot, Linear |

**Note:** The main system prompt is **not** a static file — it's dynamically assembled server-side per-request using the Priompt templating system, incorporating user rules, project context, tool definitions, mode instructions, and MCP tool prompts.

---

## API Responses (all real data, no errors)

### Models & Configuration
| File | Size | Description |
|------|------|-------------|
| `agent_usable_models.json` | 14KB | 83 AI models (GPT-5.4, Opus 4.6, Grok 4.20, Kimi K2.5) |
| `server_config.json` | 25KB | Full server config — 27 top-level keys |
| `ai_available_docs.json` | 88KB | 498 indexed documentation sources for @docs |
| `ai_cpp_config.json` | 1.2KB | CursorPrediction config (heuristics, radii) |

### Agent Operations
| File | Description |
|------|-------------|
| `agent_default_cli_model.json` | CLI default model: `composer-2-fast` |
| `agent_name_agent.json` | AI-generated agent tab names |
| `agent_transcript_overview.json` | Conversation summarization |

### Identity & Teams
| File | Description |
|------|-------------|
| `auth_email.json` | User email + sign-up type |
| `dashboard_teams.json` | Team: Wix, 2398 seats, enterprise, SSO |

### Operational State
| File | Description |
|------|-------------|
| `ai_server_time.json` | Server timestamps |
| `ai_queue_position.json` | Queue position (-1 = no queue) |
| `ai_prediction_enabled.json` | CursorPrediction: enabled |
| `ai_cpp_onboarding.json` | CPP onboarding: should turn on |
| `ai_welcome_screen.json` | Welcome cards: `["privacy"]` |
| `ai_user_instructions.json` | User instructions state |
| `git_index_handshake.json` | Git indexing: STATUS_NO_INDEXING |
| `network_public_ip.json` | Server-reported IP |
| `bugbot_deeplink.json` | BugBot: success |

---

## Key Findings

### Server Config Highlights
- **Agent URL**: `https://agentn.us.api5.cursor.sh` — new agent infra
- **Chat token limit**: 30,000 | **Max rule length**: 100,000 chars
- **Max MCP tools**: 100 (warn at 80)
- **Background agent**: 8 preloaded windows, max 10
- **CLI sandbox**: disabled by default
- **Claude Code hooks**: enabled
- **Model migrations**: Sonnet 4 → 4.5, Opus 4.5, Codex 5.1 → Max

### Model Inventory (83 models across 6 providers)
- **OpenAI**: GPT-5.4 (1M context, Mini, Nano), GPT-5.3 Codex (Spark), GPT-5.2 Codex, GPT-5.1 Max, GPT-5 Mini
- **Anthropic**: Opus 4.6 (1M, thinking, max), Sonnet 4.6/4.5/4 (1M, thinking), Opus 4.5
- **xAI**: Grok 4.20 (+ thinking)
- **Google**: Gemini 3.1 Pro, Gemini 3 Flash
- **Moonshot**: Kimi K2.5
- **Cursor**: Composer 2 Fast, Composer 2, Composer 1.5

---

*Generated: April 14, 2026 — Cursor v3.0.16*
