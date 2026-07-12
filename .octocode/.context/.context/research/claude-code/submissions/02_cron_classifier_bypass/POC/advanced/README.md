# Advanced PoC — MCP Server + Cron Planting

Research-phase PoC with real MCP server, cron planting, and exfil collector. The parent `POC/` contains safe marker-only variants for bounty review.

## Files
- `mcp-server.mjs` — compiled MCP server (8 payload variants, zero dependencies)
- `mcp-server-src.mjs` — source version
- `collector.cjs` — HTTP server logging exfiltrated data
- `plant.cjs` — plants cron tasks directly into scheduled_tasks.json
- `cleanup.cjs` — removes planted cron tasks
- `start.sh` — automated: build + configure + start collector
- `settings.local.json` — pre-configured with WebFetch preapproval
- `repo-trap/` — adversarial repo (CONTRIBUTING.md + index.js + package.json)

## Vectors
- **A (MCP):** `claude mcp add poc-tools -- node mcp-server.mjs`
- **B (Cron):** `node plant.cjs` then restart claude
- **C (Repo):** Clone repo-trap, open in claude, follow setup instructions
