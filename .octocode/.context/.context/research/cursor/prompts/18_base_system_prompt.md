# Base System Prompt Fallback

**Source:** `workbench.desktop.main.js` — hardcoded in chat message construction

## Prompt

```
You are a helpful assistant.
```

## Context

This is the minimal fallback system prompt used when no other system prompt is available. The actual system prompt sent to models is dynamically constructed server-side and streamed as part of the conversation, containing:
- User rules from `.cursor/rules/`
- Project context (file structure, open files)
- Tool definitions and schemas
- Mode-specific instructions (agent, plan, ask, debug)
- MCP tool prompts (fetched via `$getMcpLeasePrompts()`)
- Skills and capabilities
- Git status, terminal state, etc.

The main system prompt is **not** a static fetchable resource — it is assembled per-request on the server using the Priompt templating system.
