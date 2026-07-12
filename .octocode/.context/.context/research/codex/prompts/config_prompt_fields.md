# Codex Config — Prompt-Related Fields

**Source:** `config-queries-Bj2dEPP6.js`

These are user-configurable prompt fields in the Codex config system:

| Field | Description |
|-------|-------------|
| `instructions` | User instructions appended to the system prompt |
| `developer_instructions` | Developer-level instructions (higher priority) |
| `compact_prompt` | Custom prompt used when conversation is compacted |
| `model` | Model selection |
| `review_model` | Model used for code reviews |
| `model_reasoning_effort` | Reasoning effort level |
| `model_reasoning_summary` | Whether to show reasoning summaries |
| `approval_policy` | Approval mode (untrusted/on-failure/on-request/never) |
| `sandbox_mode` | Sandbox policy type |
| `sandbox_workspace_write` | Whether sandbox allows workspace writes |
| `web_search` | Whether web search is enabled |
| `tools` | Enabled tools configuration |
| `profile` | Active profile name |
| `profiles` | Profile definitions (each can override instructions) |

## Approval Policy Values

| Value | Label | Description |
|-------|-------|-------------|
| `untrusted` | Untrusted | Always ask before taking action |
| `on-failure` | On failure | Ask only when a command fails |
| `on-request` | On request | Ask when escalation is requested |
| `never` | Never | Run without asking for approval |
