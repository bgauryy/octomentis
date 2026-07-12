# AI Coding Tools — Security Research

White-hat security research on AI coding assistants. Static analysis of client bundles, prompt extraction, and vulnerability discovery.

**Date:** April 2026
**Method:** Octocode + local-explorer-mcp (byte-offset extraction from minified JS bundles)

---

## Targets

| Target | Version | Type | Findings | Prompts | Submissions |
|--------|---------|------|----------|---------|-------------|
| [Codex](codex/) | 26.325.31654 (build 1272) | Electron (macOS arm64) | 7 | 40+ | 5 |
| [Cursor](cursor/) | 3.0.12 | Electron (macOS) | 8 | 18 | 8 |
| [Claude Code](claude-code/) | 2.1.92 | Node CLI (ESM bundle) | 17 | — | 7 |

## Structure (per target)

```
<target>/
├── README.md          # Target overview & quick links
├── docs/              # Architecture, findings, bounty reports
│   ├── overview.md    #   App structure, entry points, IPC, endpoints
│   ├── research.md    #   Executive summary & audit verdict
│   ├── findings.md    #   Detailed security findings
│   └── ...            #   Bounty docs, strings, templates
├── prompts/           # Extracted system prompts
│   ├── README.md      #   Prompt inventory
│   └── *.md           #   Individual prompt documents
├── submissions/       # Bounty submission write-ups
│   └── NN_title/      #   One folder per submission
└── extracted/         # Raw extracted bundles (if applicable)
```

## Quick Start

| What | Where |
|------|-------|
| **Codex prompts** (36 use cases + system) | [`codex/prompts/README.md`](codex/prompts/README.md) |
| **Cursor prompts** (18 system prompts) | [`cursor/prompts/README.md`](cursor/prompts/README.md) |
| **Claude Code audit** (classifier bypass) | [`claude-code/README.md`](claude-code/README.md) |
| **Codex architecture** | [`codex/docs/overview.md`](codex/docs/overview.md) |
| **Cursor architecture** | [`cursor/docs/overview.md`](cursor/docs/overview.md) |
| **Claude Code execution flow** | [`claude-code/EXECUTION_FLOW.md`](claude-code/EXECUTION_FLOW.md) |

## Cross-Cutting Themes

| Theme | Codex | Cursor | Claude Code |
|-------|-------|--------|-------------|
| **Compaction** | Server-side, configurable via `compact_prompt` | Client-side, full prompt in bundle | — |
| **Guardrails** | Guardian subagent (server-side) | Sandbox modes, tool approval, subagent restrictions | Classifier pipeline (prompt-based) |
| **Approval system** | `approval_policy` + `guardian_subagent` | YOLO/sandbox/admin modes | Cron classifier + permission checks |
| **Memory** | — | Session memory + intent profiling | CLAUDE.md trust elevation |
| **Config injection** | `config.toml` `developer_instructions` | `.cursor/rules/` injection | `.claude.md` / hooks |
