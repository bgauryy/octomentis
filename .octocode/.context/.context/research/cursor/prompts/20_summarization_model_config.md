# Summarization & Model Configuration

**Source:** `workbench.desktop.main.js` — Statsig dynamic configs

## Summarization Models (priority order)
1. `gemini-2.5-flash`
2. `gpt-4.1-mini`
3. `claude-4.5-haiku`

## Summarization Prompt Size Guards
Configured via `summarization_prompt_size_guards` Statsig config (values fetched at runtime).

## BugBot Configuration
- **Model:** `claude-4-5-sonnet-20250929`
- **Iterations:** 0 (non-agentic)
- **Agentic iterations:** 1
- **Agentic model:** `claude-4.5-haiku`
- **Context lines:** 10
- **PR Summary prompt version:** `2025-09-22`

## Linear Agent
- **Orientation model:** `gpt-5-mini`
