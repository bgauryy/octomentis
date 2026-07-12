# Guardrail: Subagent Tool Restrictions & Critical Reminders

**Source:** `cursor-agent/dist/claude-agent-sdk/cli.js`
**System:** `disallowedTools` + `criticalSystemReminder_EXPERIMENTAL`

---

## Subagent Tool Restrictions

Each subagent type defines `disallowedTools` — tools that are stripped from the agent's available toolset regardless of user configuration.

| Agent | Disallowed Tools | Model | Rationale |
|-------|-----------------|-------|-----------|
| **General Purpose** | None (has `["*"]`) | inherit | Full access for research tasks |
| **Explore** | Edit, Write, Delete, Bash (write), NotebookEdit | `haiku` | Read-only codebase search |
| **Plan** | Edit, Write, Delete, Bash (write), NotebookEdit | `inherit` | Read-only architecture planning |
| **Guide** | (limited to) Glob, Grep, Read, WebFetch, Bash | N/A | Documentation lookup only |
| **Statusline Setup** | (limited to) Read, Edit | `sonnet` | Only settings file modification |

## Critical System Reminders (Experimental)

A `criticalSystemReminder_EXPERIMENTAL` field is appended to the system prompt as an extra enforcement layer for read-only agents:

### Explore Agent Reminder
```
CRITICAL: This is a READ-ONLY task. You CANNOT edit, write, or create files.
```

### Plan Agent Reminder
```
CRITICAL: This is a READ-ONLY task. You CANNOT edit, write, or create files.
```

## How `criticalSystemReminder_EXPERIMENTAL` Is Injected

At charOffset ~7974585, the reminder is passed through the agent execution pipeline:

```javascript
// Assembled into systemPrompt construction:
criticalSystemReminder_EXPERIMENTAL: e.criticalSystemReminder_EXPERIMENTAL

// Passed through to cache-safe params and fork context
```

The reminder is appended to the system prompt in addition to the main agent instructions, providing a defense-in-depth mechanism. It's marked `_EXPERIMENTAL` suggesting it may be refined.

## Custom Agent Schema Validation

Custom subagents defined by users must conform to a Zod schema:

```javascript
{
  agentType: string,
  whenToUse: string,        // Natural language description
  tools: string[],          // Optional: allowed tool names
  disallowedTools: string[],// Optional: denied tool names
  prompt: string,           // System prompt
  model: "sonnet" | "opus" | "haiku" | "inherit",
  criticalSystemReminder_EXPERIMENTAL: string,
  skills: string[],         // Preloaded skills
  maxTurns: number          // Max API round-trips
}
```

## Agent Mode Guardrails (Cursor IDE)

Each Cursor mode has built-in guardrail defaults:

| Mode | autoFix | autoRun | fullAutoRun | shouldAutoApply |
|------|---------|---------|-------------|-----------------|
| **Agent** | true | true | false | true |
| **Triage** | false | true | false | false |
| **Plan** | false | false | false | false |
| **Ask** | false | false | false | false |

Enabled tools per mode:
- **Agent**: All tools
- **Triage**: `TASK_V2`, `APPLY_AGENT_DIFF` only
- **Plan**: No tools (read-only)
- **Ask**: No tools (read-only)

## Compact/Summary Mode Guardrail

When context gets too large and conversation is compacted:

```javascript
systemPrompt: "You are a helpful AI assistant tasked with summarizing conversations."
thinkingConfig: { type: "disabled" }
```

The compaction agent:
- Has thinking disabled to save tokens
- Gets a minimal tool set (only MCP tools for state preservation)
- Has a max output token cap via `Math.min(zgA, Ud6(model))`
