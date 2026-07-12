# Codex v26.325.31654 — Security Audit & System Research

**Target:** OpenAI Codex Desktop (`com.openai.codex`) build 1272
**Date:** 2026-04-09
**Method:** Static analysis of extracted Electron app bundles (Vite + Rollup)

---

## Directory Structure

```
research/codex/
├── docs/                         # Architecture & research documentation
│   ├── overview.md               #   Bundle overview, execution model, IPC, endpoints
│   ├── research.md               #   Executive summary & audit verdict
│   ├── findings.md               #   Security findings (F1–F7)
│   ├── BOUNTY_CANDIDATES.md      #   Bounty-eligible findings ranked
│   └── SUBMISSION_TEMPLATE.md    #   Submission write-up template
├── extracted/                    # Raw extracted bundles (JS, HTML, native modules)
│   ├── webview/assets/           #   Renderer bundles (React frontend, 3.9MB index)
│   ├── package.json              #   App metadata
│   └── node_modules/             #   Native modules (better-sqlite3, node-pty, tslib)
├── prompts/                      # Extracted system prompts (40+ documents)
│   ├── README.md                 #   Prompt inventory & metadata
│   ├── usecase_*.md              #   36 use case prompts (18 automation)
│   ├── code_review_system_prompt.md
│   ├── agent_output_preferences.md
│   ├── config_prompt_fields.md
│   └── guardian_approvals.md
└── submissions/                  # Bounty submission write-ups
    ├── 01_automation_memory_poisoning/
    ├── 02_automation_toml_prompt_replacement/
    ├── 03_developer_instructions_injection/
    ├── 04_heartbeat_xml_tag_injection/
    └── 05_unencrypted_sqlite_exposure/
```

## Quick Links

| Area | Start here |
|------|------------|
| Architecture | [docs/overview.md](docs/overview.md) |
| Executive summary | [docs/research.md](docs/research.md) |
| Security findings | [docs/findings.md](docs/findings.md) |
| Bounty candidates | [docs/BOUNTY_CANDIDATES.md](docs/BOUNTY_CANDIDATES.md) |
| Extracted prompts | [prompts/README.md](prompts/README.md) |
