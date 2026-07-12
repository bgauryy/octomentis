# RESOURCES — Storage & Persistence Controls

Source appendix for `RFC.md`. Companion files: `PREREQUISITES.md`, `IMPLEMENTATION.md`, `KPI.md`. Claims stay in the RFC; this file holds the trail.

## Issue

- https://github.com/bgauryy/octocode/issues/443 — Config to disable logs (SSD wear / continuous writes)

## Local inventory (excl. Awareness)

### Path / module anchors

| Topic | Path |
|---|---|
| Home path map | `packages/octocode-tools-core/src/shared/paths.ts` |
| Atomic session/stats write | `packages/octocode-tools-core/src/shared/session/sessionDiskIO.ts` |
| 60 s flush | `packages/octocode-tools-core/src/shared/session/sessionCache.ts` |
| Stats merge API | `packages/octocode-tools-core/src/shared/session/storage.ts` |
| Char-savings hook | `packages/octocode-tools-core/src/utils/response/bulk.ts` |
| In-memory HTTP cache | `packages/octocode-tools-core/src/utils/http/cache.ts` |
| Clone/tree disk cache + env caps | `packages/octocode-tools-core/src/tools/github_clone_repo/cache.ts` |
| Binary tmp writes | `packages/octocode-tools-core/src/tools/local_binary_inspect/binaryInspector.ts` |
| Config types (no storage yet) | `packages/octocode-config/src/config/types.ts` |
| Config defaults | `packages/octocode-config/src/config/defaults.ts` |
| Public config docs | `docs/CONFIGURATION.md` (§ Where everything lives, Advanced runtime) |
| MCP registration (thin) | `packages/octocode-mcp/src/tools/registerRemoteTool.ts` |

### Historical

- Commit `a2d85a950` (“Support oql #427”) deleted `skills/octocode-research/src/utils/logger.ts` which wrote `~/.octocode/logs/tools.log` and `errors.log` (10 MB rotate).

### Sample host measurements (2026-07-11, researcher machine)

| Path | Approx size / note |
|---|---|
| `tmp/` | ~228 MB (binary 155 M, clone 72 M) |
| `logs/` | ~616 K stale |
| `data.db` | ~34 MB orphan SQLite |
| `stats.json` / `session.json` | small; mtime tracks live use |

## Surfaces checked

| Surface | Disk behavior |
|---|---|
| tools-core | Session/stats flush; tmp caches; credentials helpers |
| MCP | No independent log files; inherits tools-core |
| CLI | Same runners + auth/install/skill/unzip/cache commands |
| config | Env/rc SSOT; no persistence disable today |
| Awareness | **Excluded** from this RFC |

## Existing knobs (already shipped)

| Env | Purpose |
|---|---|
| `OCTOCODE_HOME` | Relocate all home I/O |
| `OCTOCODE_CACHE_TTL_MS` | Clone/tree freshness |
| `OCTOCODE_MAX_CACHE_SIZE` | Clone cache byte cap (default 2 GB) |
| `OCTOCODE_MAX_CLONES` | Clone count cap (default 50) |
| `OCTOCODE_CDP_DEBUG` | Optional chrome CDP NDJSON (pi-extension; not MCP default) |

## Proposed knobs (this RFC)

| Env | `.octocoderc` | Values |
|---|---|---|
| `OCTOCODE_STORAGE_STATS` | `storage.stats` | `disk` (default) \| `memory` \| `off` |
| `OCTOCODE_STORAGE_SESSION` | `storage.session` | `disk` (default) \| `memory` |
| `OCTOCODE_STORAGE_GC_ORPHANS` | `storage.gcOrphans` | `false` (default) \| `true` |

## Search prompts used

- Local: `tools.log|errors.log|stats.json|session.json|writeSessionToDisk|FLUSH_INTERVAL`
- Local: `appendFile|writeFileSync` excluding awareness
- Local: `OCTOCODE_CACHE_TTL_MS|ENABLE_|data.db`
- Docs: CONFIGURATION home + Advanced runtime
- Git: `-S tools.log` → deleted skill logger

## Related RFCs (do not conflate)

- `.octocode/rfc/RFC-lean-memory-writes.md` — Awareness memory write policy (out of scope here)
