# RFC: Storage & Persistence Controls (tools / CLI / MCP)

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Decision type** | Reversible (two-way door) — config defaults preserve current behavior |
| **Author(s)** | cursor (research + draft) |
| **Created** | 2026-07-11 |
| **Last Updated** | 2026-07-11 |
| **Related** | [bgauryy/octocode#443](https://github.com/bgauryy/octocode/issues/443) — Config to disable logs |
| **Out of scope** | `octocode-awareness` SQLite / wiki / hooks (excluded by request) |

---

## Audit Reasoning — kept (2026-07-12)

**Status:** Not implemented — 0% shipped. No `storage` config keys in `@octocodeai/config`, no `OCTOCODE_STORAGE_STATS`-style env var, session/stats flush path unchanged (`sessionCache.ts`/`sessionDiskIO.ts`).
**Why kept:** Addresses a real, filed upstream issue (bgauryy/octocode#443) with an accurate current-state inventory; no other RFC or code change has addressed it.
**Remaining work:** the entire RFC — Phase 1 (storage policy in config), Phase 2 (CLI `status` surfacing), Phase 3 (tmp TTL, deferred by the RFC itself).

---

## Summary

Issue [#443](https://github.com/bgauryy/octocode/issues/443) reports continuous disk writes under Octocode home that wear SSDs. Inventory of **tools-core / MCP / CLI / config** (excluding Awareness) shows: **file tool logging is already gone**, but **session/stats flush every ≤60s when dirty** and **tmp materialization caches** (clone/tree/binary/unzip) still write heavily. This RFC proposes a single **`storage` persistence policy** (env + `.octocoderc`) to disable or throttle disk writes, document the full home layout, and optionally GC orphan legacy artifacts (`logs/`, `data.db`).

---

## Goals and Non-Goals

### Goals

1. Publish an accurate inventory of what tools/CLI/MCP write under `OCTOCODE_HOME` (excluding Awareness).
2. Give users a **documented, default-preserving** way to turn off or reduce **non-essential** disk persistence (stats/session flush; optional tmp aggressiveness).
3. Document and optionally clean **orphan** paths (`logs/`, `data.db`) that no longer have writers.
4. Keep credentials auth, clone usefulness, and MCP stdio hygiene intact unless the user opts in to stricter modes.

### Non-Goals

- Changing Awareness memory / SQLite / wiki projection.
- Re-introducing file-based `tools.log` / `errors.log`.
- Shipping a full telemetry pipeline or remote analytics.
- Encrypting or relocating credentials beyond today’s AES-GCM layout.
- Guaranteeing zero disk I/O (git clone / binary extract inherently write).

---

## Motivation

### Problem

Users monitoring Octocode see frequent writes under `~/.octocode` and want a config switch to stop them ([#443](https://github.com/bgauryy/octocode/issues/443)). Framing “disable logs” underspecifies the real writers: after the research skill file logger was deleted, **stats/session and tmp caches** dominate continuous I/O.

### Current state (evidence)

| Path under `OCTOCODE_HOME` | Role | Writer today? | Cadence / size signal |
|---|---|---|---|
| `logs/tools.log`, `logs/errors.log` | Legacy HTTP/tool NDJSON | **No** — logger removed in OQL work (`skills/.../logger.ts` deleted, commit `a2d85a950`) | Orphan; sample host: last write `tools.log` 2026-06-29, content from Jan 2026 HTTP routes |
| `data.db` | Legacy SQLite | **No** code path owns it (only ignored as `*.db` in filters) | Orphan; sample ~34 MB, last write 2026-01-06 |
| `session.json` | Session id + activity | **Yes** — `sessionDiskIO.writeSessionToDisk` | Atomic write with stats |
| `stats.json` | Tool/char/cache counters | **Yes** — same flush | Dirty on tool stats updates; timer `FLUSH_INTERVAL_MS = 60_000` in `sessionCache.ts` |
| `tmp/clone`, `tmp/tree` | Clone / directory materialization | **Yes** — `github_clone_repo/cache.ts` | TTL `OCTOCODE_CACHE_TTL_MS` (24 h), caps `OCTOCODE_MAX_CACHE_SIZE` / `OCTOCODE_MAX_CLONES` |
| `tmp/binary` | `localBinaryInspect` extracts | **Yes** — `binaryInspector.ts` writes under `paths.binary` | Sample host: **155 MB** (largest live bucket) |
| `tmp/unzip` | CLI `unzip` / archive ops | **Yes** | Smaller on sample host |
| `credentials.json`, `.key` | Auth | **Yes** — on login | Rare |
| `.octocoderc`, `.env`, `config.json` | Config | User / install | Rare |
| HTTP API response cache | GitHub/npm | **Memory only** — `utils/http/cache.ts` (`NodeCache`) | No disk |
| `skills/`, `skill-sources/`, `repos/` | CLI skill/install leftovers | CLI paths | Not per-tool-call |

Canonical path map (no `logs`): `packages/octocode-tools-core/src/shared/paths.ts` (`session`, `stats`, `tmp/*`, credentials).

Flush policy: `packages/octocode-tools-core/src/shared/session/sessionCache.ts` — dirty flag on `writeSession`, interval flush 60 s, exit/SIGINT/SIGTERM sync flush; `writeSessionToDisk` always writes **both** `stats.json` and `session.json` atomically (`sessionDiskIO.ts`).

Stats mutation on the hot path: `incrementToolCharSavings` from `utils/response/bulk.ts` (and related session helpers) → `updateSessionStats` → `writeSession` → dirty.

MCP (`packages/octocode-mcp`) is a thin stdio registrar — **no independent log files**; it inherits tools-core session/stats and caches.

CLI (`packages/octocode`) uses the same runners plus install/auth/skill/cache/unzip commands that touch home.

Config SSOT (`@octocodeai/config`): `.octocoderc` types cover github/local/tools/network/lsp/output only — **no storage/logging section** (`config/types.ts`). Documented advanced knobs today: cache TTL/size/clone count + tool timeouts (`docs/CONFIGURATION.md` “Advanced runtime”). Home file table documents `.env`, `.octocoderc`, credentials, `stats.json`, `session.json` — **omits `tmp/`, `logs/`, orphans**.

### Evidence (local sample host, 2026-07-11)

- `session.json` / `stats.json` mtime advanced during live MCP/CLI use (e.g. 11:24).
- `du`: `tmp` ≈ **228 MB** (binary 155 M + clone 72 M); `logs` ≈ 616 K stale; `data.db` ≈ 34 M orphan.
- No remaining `tools.log` / `LOGS_DIR` / `fileLoggingEnabled` writers in packages (search empty). Optional CDP NDJSON only when `OCTOCODE_CDP_DEBUG=1` (`octocode-pi-extension` chrome-debug) — out of MCP default path.

### Impact

- Laptop / always-on MCP users: continuous small writes (stats/session) + large tmp churn.
- Issue reporter mental model (“logs”) ≠ current writers → need docs + correct knobs.
- `octocode-stats` skill / dashboards depend on `stats.json` — disabling disk must be explicit.

### Use cases

1. Power user: “never write stats/session; keep credentials + optional clones.”
2. CI: ephemeral `OCTOCODE_HOME` already isolates; still wants no flush noise on shared volumes.
3. Maintainer reply to #443: “logs gone; here is the real control surface.”

---

## Guide-Level Explanation

After this ships, docs describe home as:

```text
$OCTOCODE_HOME/
  credentials.json, .key     # auth (always allowed unless OCTOCODE_HOME is ephemeral)
  session.json, stats.json   # controlled by storage.stats / storage.session
  tmp/clone, tmp/tree, tmp/binary, tmp/unzip  # materialization; TTL/caps already exist
  .octocoderc, .env          # config
  # legacy (optional GC): logs/, data.db
```

User enables quiet mode:

```bash
# MCP env block or shell
export OCTOCODE_STORAGE_STATS=off          # or memory
export OCTOCODE_STORAGE_SESSION=memory     # id in-process only
# optional
export OCTOCODE_STORAGE_GC_ORPHANS=true    # delete logs/ + data.db once at startup
```

Or `.octocoderc`:

```jsonc
{
  "storage": {
    "stats": "off",       // "disk" | "memory" | "off"
    "session": "memory",  // "disk" | "memory"
    "gcOrphans": false
  }
}
```

Defaults remain **`disk`** for both stats and session (today’s behavior). Clone/tmp caps stay as today; a later optional `storage.tmpPolicy` can tighten TTL without breaking clone.

Teaching: #443 “disable logs” → answer “file logs removed; set `storage.stats` / `storage.session` to stop the continuous writers.”

---

## Reference-Level Explanation

### Design

1. **Add `storage` to ResolvedConfig** in `@octocodeai/config` (types, defaults, validator, resolver, docs).
2. **Gate `writeSessionToDisk`** in tools-core:
   - `stats=off` → skip stats file; do not mutate disk counters (in-memory optional for process).
   - `stats=memory` → keep counters in process; never write `stats.json`.
   - `session=memory` → keep session object in cache; never write `session.json`.
   - `stats=disk` + `session=disk` → current behavior.
3. **Do not start flush timer** when both are non-disk (or when dirty can never flush).
4. **`gcOrphans`**: on `ensureHome` / first session touch, if enabled, unlink `logs/**` and `data.db*` if present; log once to stderr if MCP-safe.
5. **MCP/CLI**: no duplicate logic — both import tools-core + config.
6. **Docs**: expand “Where everything lives” with `tmp/*`, legacy orphans, and the new knobs; mention #443.

### Compatibility

- Default = current behavior → non-breaking.
- Env vars win over `.octocoderc` (existing override rule).
- `octocode-stats` readers: document that `stats=off|memory` means no durable file.

### Corner cases

- Mid-process env change: not supported (same as other runtime knobs).
- Partial disk (`session=disk`, `stats=off`): write session payload only; do not create/update `stats.json`.
- Exit flush: respect the same gates.

---

## Drawbacks

- Config surface growth in an already large settings doc.
- Users who disable stats lose local usage dashboards.
- `gcOrphans` could surprise someone who still scrapes old `tools.log` (unlikely; document).
- Does not eliminate clone/binary tmp writes — only reduces continuous small-file I/O unless users also disable clone / lower TTL.

### Pre-mortem

1. **Users set `stats=off` and report “stats skill broken”** → Docs + CLI `status` shows persistence mode.
2. **Flush timer still runs empty** → Gate `startFlushTimer` on disk mode.
3. **Orphan GC deletes user data.db they cared about** → Default `gcOrphans=false`; only explicit opt-in.
4. **Issue closed as “logs already fixed” without knobs** → SSD wear complaint continues from stats/tmp → ship knobs, not only a comment.

---

## Rationale

**Chosen:** Unified `storage` policy for stats/session + docs + optional orphan GC.

Why not “disable logs” only: **no live file logger remains** — that fix already shipped; the issue’s symptom needs the real writers addressed.

Why not “do nothing”: leaves continuous 60 s dual atomic writes and undocumented orphans; weak #443 response.

Why not full “diskless mode” including forbidding tmp: breaks `ghCloneRepo` / binary inspect; too large for v1.

---

## Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **A. Do nothing** — reply logs removed | Zero eng cost | Ignores live stats/tmp I/O; orphans undocumented | Reject as sole response |
| **B. Docs-only** — document writers + existing cache caps | Fast | No disable switch for stats/session | Insufficient for #443 |
| **C. `storage` policy (this RFC)** | Correct problem; default-safe; MCP+CLI share brain | Modest config work | **Recommend** |
| **D. Delete stats/session persistence entirely** | Least I/O | Breaks stats skill / session continuity | Reject as default |
| **E. Re-add log toggle** | Matches issue title | Dead feature; confuses | Reject |

---

## Prior Art

- Existing cache caps: `OCTOCODE_CACHE_TTL_MS`, `OCTOCODE_MAX_CACHE_SIZE`, `OCTOCODE_MAX_CLONES` (`cache.ts`, CONFIGURATION.md).
- In-memory HTTP cache already avoids disk (`http/cache.ts`).
- Industry pattern: log level / telemetry opt-out (Node, OpenTelemetry exporters) — map here to **persistence mode**, not log level, because file logging is gone.

---

## Unresolved Questions

1. Exact env names: `OCTOCODE_STORAGE_STATS` vs nested `OCTOCODE_STORAGE=stats:off` — prefer discrete vars for MCP `env` blocks?
2. Should v1 include a `tmp.binary` TTL/GC (largest sample bucket), or defer to a follow-up?
3. Should `octocode status --json` expose persistence mode + approximate home disk usage?

(Resolutions → `IMPLEMENTATION.md`.)

---

## Success Signal

Users can set one env/rc knob and observe **no mtime changes** on `stats.json`/`session.json` under sustained tool traffic, while tools still function; docs list every home path; #443 can be closed with the inventory + knob.

## Document set

This decision lives with `PREREQUISITES.md`, `IMPLEMENTATION.md`, `KPI.md`, and `RESOURCES.md` in the same folder.
