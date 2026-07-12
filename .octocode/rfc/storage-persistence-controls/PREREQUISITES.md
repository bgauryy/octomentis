# PREREQUISITES

## Scope

Existing-code area affected: `@octocodeai/config`, `@octocodeai/octocode-tools-core` session/paths, docs `CONFIGURATION.md`; thin consumers MCP + CLI inherit via tools-core.

RFC anchor: `RFC.md` §Goals, §Reference-Level Explanation.

Excluded: `packages/octocode-awareness` (per product request).

## Required Current-State Evidence

| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| Path map has no `logs` | `packages/octocode-tools-core/src/shared/paths.ts` (session/stats/tmp only) | confirmed | tools-core |
| Dual-file atomic flush | `sessionDiskIO.ts` `writeSessionToDisk` writes `STATS_FILE` + `SESSION_FILE` | confirmed | tools-core |
| 60 s dirty flush | `sessionCache.ts` `FLUSH_INTERVAL_MS = 60_000` | confirmed | tools-core |
| Stats hot path | `utils/response/bulk.ts` → `incrementToolCharSavings` | confirmed | tools-core |
| File logger removed | git `a2d85a950` deleted `skills/octocode-research/.../logger.ts`; repo search empty for `tools.log` writers | confirmed | — |
| HTTP cache is memory-only | `utils/http/cache.ts` `NodeCache` | confirmed | tools-core |
| Clone/tmp knobs exist | `OCTOCODE_CACHE_TTL_MS` / `MAX_CACHE_SIZE` / `MAX_CLONES` in `github_clone_repo/cache.ts` + CONFIGURATION.md Advanced | confirmed | tools-core |
| Config has no storage section | `octocode-config/src/config/types.ts` — github/local/tools/network/lsp/output only | confirmed | config |
| MCP has no own log files | `octocode-mcp` registers tools via tools-core; no `logs/` path | confirmed | mcp |
| Issue framing | https://github.com/bgauryy/octocode/issues/443 | confirmed | community |

## Environment And Setup

| Need | How to verify | Source |
|---|---|---|
| Isolated home for tests | `OCTOCODE_HOME=$(mktemp -d)` | paths.ts / CONFIGURATION.md |
| Package builds | `yarn workspace @octocodeai/config test` · `yarn workspace @octocodeai/octocode-tools-core test` | monorepo scripts |

## Baseline Verification

Before coding, capture on a dirty home (optional local):

```bash
stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$OCTOCODE_HOME/session.json" "$OCTOCODE_HOME/stats.json"
# run N tool calls with disk mode
# expect mtimes to advance within ~60s
```

## Blockers

| Blocker | Severity | Unblock |
|---|---|---|
| Product choice on env naming (RFC Q1) | low | Decide discrete env vars in IMPLEMENTATION |
| Whether v1 includes binary tmp GC (RFC Q2) | low | Defer to Phase 3 / follow-up unless product insists |

## Owners

| Area | Package |
|---|---|
| Config schema / docs | `octocode-config`, `docs/CONFIGURATION.md` |
| Persistence gate | `octocode-tools-core` session |
| Status surfacing (optional) | `octocode` CLI |
| Issue reply | maintainer after draft acceptance |
