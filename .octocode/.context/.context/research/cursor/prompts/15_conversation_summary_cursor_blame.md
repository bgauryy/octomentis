# Conversation Summary — Cursor Blame

**Source:** `workbench.desktop.main.js` — `cursor_blame_conversation_summary_prompts` Statsig config

## Description

Dynamic prompts fetched at runtime from Statsig for generating conversation summaries used in the "Cursor Blame" feature (attributing code changes to specific agent conversations). The prompts are stored as a `Record<string, { systemPrompt?: string, model?: string }>` and can be updated server-side without client deployment.

**Default:** Empty `{}` — prompts are fully server-controlled.
