# RFC: `octocode ingest` — local SQLite code-graph for agentic research

**Status:** Draft / build-ready · **Date:** 2026-06-22 · **Track:** OQL Expansion
**Companion:** `docs/octocode-language/OQL_AGENTIC_IMPROVEMENT_PLAN.md` (§2)
**Decision:** Build in-engine. **MVP = Option B** — store owned by
`octocode-tools-core` (TS) via **`better-sqlite3`**; the Rust engine adds one
per-file `extractGraph` napi function. `rusqlite` deferred to a perf tier behind
the same `GraphStore` interface.

---

## Audit Reasoning — kept (2026-07-12)

**Status:** Not implemented — no graph store, no `octocode ingest` command, no OQL `target:"impact"`.
**Why kept:** Still a valid, well-evidenced expansion track (cites measured payoff from prior art); nothing elsewhere has replaced this architecture.
**Evidence of absence:** no `oql/graph/` tree, no `GraphStore`/`ingest_runs` in `packages/octocode-tools-core`, no `ingest` subcommand in `packages/octocode`. The engine's `extractGraphFacts` (`signatures.rs:73-76`) returns JSON research facts for `oql/research/analyze/source-graph.ts` — it is not this RFC's proposed per-file symbols+edges `extractGraph` napi API.
**Remaining work:** the entire RFC — this is a from-scratch build if pursued.

---

## 1. Summary

Add `octocode ingest --path=<dir>`: precompute a symbol + call/reference graph
into a single home-scoped SQLite DB (`getOctocodeDir()/db/index.sqlite`), keyed by
workspace root, with per-file `mtime`+`content_hash` for incremental, freshness-
checked queries. OQL gains a routed `from:{kind:"index"}` source, a `target:"impact"`
(blast-radius), graph-backed `semantics`/`research`, and a `resolution` proof-class
on every row. Freshness-first stays the default: a stale graph never silently
answers — it emits `staleIndex` + an executable `next.ingest`.

**Why:** verified gaps (live `octocode search`):
- relational questions ("who calls X / blast radius / is X dead") need per-query
  LSP boots or noisy grep; none is proof.
- `target:"research"` reachability returns `sourceFiles:0` for non-JS/TS repos yet
  reports `complete:true`.
- broad structural rules parse every file (`60 of 1269 matches`).

**Payoff (prior art, `strong`):** Codebase-Memory (arXiv 2603.27277) measured
**~10× fewer tokens, 2.1× fewer tool calls at 90% quality parity**, blast-radius
**~0.3 ms**, dead-code **~150 ms** on a 196k-edge graph, incremental re-index
**~1.2 s**.

---

## 2. Current state (verified)

| Primitive | Location | Reused how |
|---|---|---|
| ~30 tree-sitter grammars | `octocode-engine/Cargo.toml` | parse any of 47 signature-outline langs |
| `.scm`-query symbol extraction | `signatures/extractor.rs` (uses `tree_sitter::Query` + `cfg.body_query`) | **extend** to emit nodes+edges (tags-queries) |
| node-kind labels | `search/classify.rs` | symbol `kind`, edge ranking |
| native LSP client | `lsp/` | optional proof-upgrade pass (Go/C/C++/TS receivers) |
| OXC JS/TS scopes/bindings/refs | `signatures/js_oxc.rs` | high-accuracy JS/TS extraction |
| home dir resolver | `tools-core/shared/config/loader.ts:133` (`getOctocodeDir()` → `paths.home`, mode 0700, **no override env**) | DB location |
| clone cache (precedent) | `github_clone_repo/cache.ts:32` (`getOctocodeDir()/tmp/clone`) | DB is a **sibling**: `getOctocodeDir()/db` |
| `.sqlite` secret-scanner filter | `security/discoveryFilter.ts:166`, `filePatterns.ts` | **must self-exclude** the DB |

The engine has every input; nothing adoptable embeds in a Rust engine
(CodeGraph=TS, Codebase-Memory=C, Serena=Python, SCIP=per-lang CLIs, stack-graphs=
archived Sep 2025) → build it ourselves.

---

## 3. Architecture (Option B)

```
                octocode-tools-core (TS)                         octocode-engine (Rust)
  ┌──────────────────────────────────────────────┐        ┌──────────────────────────────┐
  │ oql/graph/                                     │        │ signatures/extractor.rs       │
  │   ingest.ts   walk → mtime/xxh3 → extract →    │ napi   │   + extractGraph(path,content)│
  │               resolve(cascade) → store         │──────► │     → {symbols, edges}        │
  │   store.ts    better-sqlite3 (GraphStore)      │ (per   │   (tags-query .scm + OXC)     │
  │   query.ts    callers/impact/reachable + FTS5  │  file) └──────────────────────────────┘
  │   resolve.ts  6-strategy confidence cascade    │
  └───────────────┬────────────────────────────────┘
                  │ reads/writes
                  ▼
   $HOME/.octocode/db/index.sqlite  (WAL: 1 writer + N readers; CLI & MCP share)
```

- **Engine** stays stateless: extracts one file's symbols + *raw* edges
  (src-symbol-index + callee name + import path). No DB in Rust for the MVP.
- **tools-core** owns the walk, hashing, the cross-file resolution cascade, the
  store, and all queries — next to the OQL planner.
- **Per-file boundary** = only tens–hundreds of nodes cross napi per call (bounded;
  no whole-repo marshaling).

---

## 4. Storage — `better-sqlite3` schema + migrations

`oql/graph/store.ts`. Open with WAL; run migrations on first use keyed by
`schema_meta.schema_version`.

```sql
-- ── pragmas (set on every open) ─────────────────────────────────────────────
PRAGMA journal_mode = WAL;       -- many readers (CLI+MCP) + one writer (ingest)
PRAGMA foreign_keys = ON;
PRAGMA synchronous  = NORMAL;    -- WAL-safe, fast bulk insert
PRAGMA busy_timeout = 5000;

-- ── migration bookkeeping ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS schema_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
-- seed: ('schema_version','1'), ('engine_version', <napi version>)

-- ── roots: many repos share one DB (enables cross-repo lookups) ─────────────
-- Provenance columns implement FPP (plan §2A): a graph root records WHAT it
-- indexed and at WHICH version, so it revalidates like any other disk artifact.
CREATE TABLE roots (
  id            INTEGER PRIMARY KEY,
  abs_path      TEXT UNIQUE NOT NULL,
  label         TEXT,
  source_kind   TEXT NOT NULL DEFAULT 'local',  -- local|github|materialized|npm
  source_ref    TEXT,                            -- e.g. "owner/repo@main" / "pkg@1.2.3"
  resolved_sha  TEXT,                            -- git HEAD sha when ingested from a clone (version anchor)
  provenance_path TEXT,                          -- pointer to the artifact's .octocode.json (FPP)
  engine_version TEXT,
  indexed_at    INTEGER NOT NULL                 -- epoch ms
);

-- ── files: the freshness anchor ─────────────────────────────────────────────
CREATE TABLE files (
  id            INTEGER PRIMARY KEY,
  root_id       INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
  path          TEXT NOT NULL,                -- relative to root.abs_path
  lang          TEXT NOT NULL,
  mtime_ms      INTEGER NOT NULL,
  size          INTEGER NOT NULL,
  content_hash  TEXT NOT NULL,                -- XXH3 hex
  parse_status  TEXT NOT NULL DEFAULT 'ok',   -- ok|unparsable  (what actually ingested)
  indexed_at    INTEGER NOT NULL,
  run_id        INTEGER REFERENCES ingest_runs(id) ON DELETE SET NULL,  -- which run last touched it
  UNIQUE(root_id, path)
);
CREATE INDEX idx_files_root ON files(root_id);

-- ── ingest_runs: audit log → "last ingest", history, smart-ingest stats ─────
CREATE TABLE ingest_runs (
  id              INTEGER PRIMARY KEY,
  root_id         INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
  started_at      INTEGER NOT NULL,            -- epoch ms
  finished_at     INTEGER,
  mode            TEXT NOT NULL,               -- full|incremental|check (check = dry-run, not persisted to files)
  trigger         TEXT,                        -- cli|mcp|auto-stale
  files_scanned   INTEGER NOT NULL DEFAULT 0,
  files_ingested  INTEGER NOT NULL DEFAULT 0,  -- new + changed actually (re)parsed
  files_fresh     INTEGER NOT NULL DEFAULT 0,  -- skipped: mtime+hash unchanged
  files_deleted   INTEGER NOT NULL DEFAULT 0,  -- pruned (gone from disk)
  files_unparsable  INTEGER NOT NULL DEFAULT 0,
  files_unsupported INTEGER NOT NULL DEFAULT 0,
  files_too_large   INTEGER NOT NULL DEFAULT 0,
  symbols_written INTEGER NOT NULL DEFAULT 0,
  edges_written   INTEGER NOT NULL DEFAULT 0,
  edges_resolved  INTEGER NOT NULL DEFAULT 0,
  duration_ms     INTEGER,
  engine_version  TEXT,
  ok              INTEGER NOT NULL DEFAULT 1,
  error           TEXT
);
CREATE INDEX idx_runs_root ON ingest_runs(root_id, started_at DESC);  -- last run = first row

-- ── symbols = graph nodes (LSP-shaped → maps onto target:"semantics") ───────
CREATE TABLE symbols (
  id            INTEGER PRIMARY KEY,
  root_id       INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
  file_id       INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  kind          TEXT NOT NULL,                -- function|method|class|interface|enum|type|route|var|module
  scip_id       TEXT,                         -- (package,version,descriptor) for cross-repo (nullable)
  start_line    INTEGER NOT NULL, start_col INTEGER NOT NULL,
  end_line      INTEGER NOT NULL, end_col   INTEGER NOT NULL,
  is_exported   INTEGER NOT NULL DEFAULT 0,
  is_entrypoint INTEGER NOT NULL DEFAULT 0,
  signature     TEXT,
  doc           TEXT
);
CREATE INDEX idx_symbols_file ON symbols(file_id);
CREATE INDEX idx_symbols_name ON symbols(root_id, name);
CREATE INDEX idx_symbols_scip ON symbols(scip_id) WHERE scip_id IS NOT NULL;

-- ── edges = graph edges, provenance + confidence ────────────────────────────
-- dst_symbol_id ON DELETE SET NULL (NOT cascade) + dst_name retained: when a file
-- changes and its symbols are deleted, inbound edges become re-resolvable, not lost.
CREATE TABLE edges (
  id            INTEGER PRIMARY KEY,
  root_id       INTEGER NOT NULL REFERENCES roots(id) ON DELETE CASCADE,
  src_symbol_id INTEGER NOT NULL REFERENCES symbols(id) ON DELETE CASCADE,
  dst_symbol_id INTEGER          REFERENCES symbols(id) ON DELETE SET NULL,  -- NULL = unresolved
  dst_name      TEXT NOT NULL,                -- raw callee/import name (always kept → re-resolve)
  import_path   TEXT,                         -- module specifier when known (drives import-map strategy)
  kind          TEXT NOT NULL,                -- CALLS|IMPORTS|IMPLEMENTS|INHERITS|REFERENCES|DEFINES|CONTAINS
  resolution    TEXT NOT NULL,                -- import-map|import-suffix|same-module|unique-name|suffix|fuzzy|lsp|unresolved
  confidence    REAL NOT NULL,                -- 0.0 .. 1.0
  src_file_id   INTEGER NOT NULL REFERENCES files(id) ON DELETE CASCADE,     -- ownership for incremental
  src_line      INTEGER, src_col INTEGER
);
CREATE INDEX idx_edges_src     ON edges(src_symbol_id, kind);
CREATE INDEX idx_edges_dst     ON edges(dst_symbol_id, kind);   -- reverse / "who-calls"
CREATE INDEX idx_edges_srcfile ON edges(src_file_id);           -- incremental delete
CREATE INDEX idx_edges_pending ON edges(root_id, dst_name) WHERE dst_symbol_id IS NULL;

-- ── FTS5 symbol search (contentless external-content table + sync triggers) ──
CREATE VIRTUAL TABLE symbol_fts USING fts5(name, signature, content='symbols', content_rowid='id');
CREATE TRIGGER symbols_ai AFTER INSERT ON symbols BEGIN
  INSERT INTO symbol_fts(rowid, name, signature) VALUES (new.id, new.name, new.signature);
END;
CREATE TRIGGER symbols_ad AFTER DELETE ON symbols BEGIN
  INSERT INTO symbol_fts(symbol_fts, rowid, name, signature) VALUES('delete', old.id, old.name, old.signature);
END;
```

**Migration policy:** `runMigrations(db)` reads `schema_version`, applies ordered
`MIGRATIONS: Array<(db)=>void>`, bumps the version in one transaction. A version
the binary doesn't know → refuse with `indexMissing`-style error + advise `--reset`.

---

## 5. `GraphStore` interface (TS)

`oql/graph/store.ts` — the seam that lets the writer move to `rusqlite` later
without touching OQL.

```ts
export type RootId = number; export type SymbolId = number;

export interface FileState { mtimeMs: number; contentHash: string; }
export interface SymbolRow {
  id?: SymbolId; name: string; kind: SymbolKind; scipId?: string;
  startLine: number; startCol: number; endLine: number; endCol: number;
  isExported: boolean; isEntrypoint: boolean; signature?: string; doc?: string;
}
export interface EdgeRow {
  srcLocalIndex: number;          // index into the file's symbol array (resolved to id on write)
  dstName: string; importPath?: string; kind: EdgeKind;
  resolution: Resolution; confidence: number; srcLine?: number; srcCol?: number;
}
export interface ImpactRow { symbolId: SymbolId; depth: number; minConfidence: number; }

export interface GraphStore {
  // lifecycle
  upsertRoot(absPath: string, label?: string): RootId;
  rootStatus(rootId: RootId): {
    files: number; symbols: number; edges: number;
    unresolvedEdges: number; staleFiles: number; indexedAt: number;
  };

  // incremental ingest (all writes in a single transaction per file)
  fileState(rootId: RootId, relPath: string): FileState | null;
  replaceFile(rootId: RootId, file: { path: string; lang: string; mtimeMs: number;
              size: number; contentHash: string },
              symbols: SymbolRow[], edges: EdgeRow[]): void;   // delete old + insert new + set-null inbound
  deleteFile(rootId: RootId, relPath: string): void;
  resolvePending(rootId: RootId): number;                     // bind unresolved edges → returns # resolved

  // queries (read-only)
  callers(symbolId: SymbolId, opts?: { minConfidence?: number }): SymbolRow[];
  callees(symbolId: SymbolId): SymbolRow[];
  impact(symbolId: SymbolId, maxDepth: number): ImpactRow[];  // reverse-CALLS transitive closure
  reachableFrom(roots: SymbolId[], maxDepth?: number): Set<SymbolId>;
  searchSymbols(rootId: RootId, query: string, limit: number): SymbolRow[];  // FTS5
  resolveSymbol(rootId: RootId, name: string, lineHint?: number): SymbolRow[];

  // ── observability: "last ingest / what & which ingested / check all" ───────
  recordRun(run: IngestRunRow): RunId;                 // write an audit row (start), update on finish
  lastRun(rootId: RootId): IngestRunRow | null;        // most recent run (idx_runs_root first row)
  runHistory(rootId: RootId, limit: number): IngestRunRow[];
  coverage(rootId: RootId): {                           // "what is ingested"
    byLang: Array<{ lang: string; files: number; symbols: number }>;
    parseStatus: { ok: number; unparsable: number };
    totals: { files: number; symbols: number; edges: number; unresolvedEdges: number };
  };
  listFiles(rootId: RootId, filter?: {                 // "which files are ingested"
    lang?: string; parseStatus?: 'ok' | 'unparsable'; staleOnly?: boolean;
  }): Array<FileRow & { symbols: number; stale: boolean }>;
  verify(rootId: RootId): {                             // "check all" — integrity + freshness doctor
    ok: boolean;
    issues: Array<{ kind: VerifyIssueKind; severity: 'info'|'warning'|'error'; count: number; detail?: string }>;
  };

  close(): void;
}

// VerifyIssueKind: 'orphanEdge' | 'danglingDstName' | 'staleFile' | 'missingFromGraph'
//                | 'schemaVersionMismatch' | 'ftsCorrupt' | 'highUnresolvedRatio'
```

---

## 6. `extractGraph` napi signature (Rust + TS)

Extends `signatures/extractor.rs`; same `#[napi(object)]`/`js_name` convention as
`StructuralMatch`. Returns **raw, intra-file** symbols + edges (cross-file
resolution is TS-side). Synchronous like the other extract calls.

```rust
// octocode-engine/src/signatures/graph.rs  (new) + bindings/graph.rs
#[napi(object)]
pub struct ExtractedSymbol {
    pub name: String,
    pub kind: String,            // function|method|class|interface|enum|type|route|var|module
    pub start_line: u32, pub start_col: u32,
    pub end_line: u32,   pub end_col: u32,
    pub is_exported: bool,
    pub signature: Option<String>,
    pub doc: Option<String>,
}

#[napi(object)]
pub struct ExtractedEdge {
    pub src_index: i32,          // index into `symbols` (-1 = file/module scope)
    pub dst_name: String,        // raw callee/import/type name
    pub import_path: Option<String>,
    pub kind: String,            // CALLS|IMPORTS|IMPLEMENTS|INHERITS|REFERENCES
    pub src_line: u32, pub src_col: u32,
}

#[napi(object)]
pub struct ExtractedGraph {
    pub lang: String,
    pub parsed: bool,            // false → caller marks file unparsable, keeps mtime to avoid re-try storms
    pub symbols: Vec<ExtractedSymbol>,
    pub edges: Vec<ExtractedEdge>,
}

/// Parse one file with tree-sitter (tags-query `.scm`; OXC for js/ts) and return
/// its symbols + raw edges. Pure function: no IO beyond the passed content.
#[napi(js_name = "extractGraph")]
pub fn extract_graph(path: String, content: String) -> ExtractedGraph { /* … */ }
```

```ts
// engine .d.ts (generated)
export function extractGraph(path: string, content: string): ExtractedGraph;
```

Per-language tags queries live beside the existing body queries (e.g.
`signatures/queries/<lang>.scm`), capturing `@definition.function`,
`@definition.class`, `@reference.call`, `@name`, `@local.import`. JS/TS route
through OXC for export/binding accuracy.

---

## 7. Ingest pipeline (`oql/graph/ingest.ts`)

```
ingest(rootAbsPath, { full }):
  rootId = store.upsertRoot(rootAbsPath)
  walk(rootAbsPath)            # reuse engine ignore-walker; skip getOctocodeDir(), node_modules, .git…
    for each supported file f:
      st = stat(f); if !full and store.fileState matches (mtime_ms && xxh3) → skip (fresh)
      g  = engine.extractGraph(f, read(f))          # bounded, per-file
      rows = mapSymbols(g.symbols); edges = mapEdges(g.edges)   # raw, dstName only
      store.replaceFile(rootId, fileMeta, rows, edges)          # 1 txn: del old, set-null inbound, insert
  resolved = store.resolvePending(rootId)            # cross-file cascade (§8) binds dstName → dst_symbol_id
  optional: lspProofPass(rootId, receiverHeavyLangs) # upgrade confidence→1.0 resolution:"lsp"
  store sets roots.indexed_at
```

- **Incremental:** mtime pre-filter → XXH3 confirm → `replaceFile` only changed
  files. `replaceFile` deletes the file's symbols (cascade drops its outbound
  edges; **inbound edges' `dst_symbol_id` → NULL via SET NULL**, `dst_name` kept),
  inserts new symbols/edges, leaving re-binding to `resolvePending`.
- **Concurrency:** an advisory lock file in `getOctocodeDir()/db/.ingest.lock`
  prevents two concurrent ingests of the same root; readers are unaffected (WAL).

### 7.1 Smart ingest (default) — diff, prune, re-resolve, record

"Smart ingest" is the default mode: do the **least work** to make the graph
correct, prune what disappeared, and record the run so freshness is observable.

```
smartIngest(rootAbsPath, { mode }):                 # mode: incremental(default)|full|check
  rootId = store.upsertRoot(rootAbsPath)
  run = store.recordRun({ rootId, mode, startedAt: now, trigger })   # mode=check → not persisted to files
  disk   = walk(rootAbsPath)                         # supported files only (skip getOctocodeDir(), ignores)
  known  = store.listFiles(rootId)                   # what the graph currently has

  plan = diff(disk, known):                          # the "what would change" set
    new      = disk \ known
    changed  = { f in disk∩known : mtime_ms≠db OR xxh3≠db }     # mtime pre-filter → hash confirm
    deleted  = known \ disk                           # pruned (gone from disk)
    fresh    = (disk∩known) \ changed                 # untouched

  if mode == check:                                   # DRY RUN — write nothing
    return { plan, lastRun: store.lastRun(rootId) }   # caller prints; no mutation

  for f in new ∪ changed:  store.replaceFile(rootId, …, engine.extractGraph(f))
  for f in deleted:        store.deleteFile(rootId, f)         # cascades; inbound edges → dst_symbol_id NULL
  resolved = store.resolvePending(rootId)             # re-bind unresolved + edges freed by deletions/changes
  store.finishRun(run, { ...counts, finishedAt: now, ok: true })
```

- **Smart = incremental + prune + targeted re-resolve.** Only `new ∪ changed` files
  are parsed; `deleted` files are pruned (their inbound edges revert to
  re-resolvable, not lost — the `ON DELETE SET NULL` design); `resolvePending`
  re-binds just the affected edges via the `idx_edges_pending` partial index.
- **Auto-stale trigger:** a graph-backed OQL query that finds touched files newer
  than the DB returns `staleIndex` + `next.ingest` (manual), and — when
  `controls` opt in — may run a **scoped smart ingest of just those files**
  inline before answering (`trigger:"auto-stale"`), so the agent stays correct
  without a full re-index.
- **`--check` is a pure dry-run:** it reports the `plan` (counts + sample paths of
  new/changed/deleted/fresh) and the last run, mutating nothing — the cheap "what
  *would* re-ingest?" probe.

---

## 8. Resolution cascade (`oql/graph/resolve.ts`)

Codebase-Memory's 6-strategy `FunctionRegistry`, verbatim, against the global
symbol table. Strategies 1–3 resolve ~80% in well-structured code.

| # | Strategy | Match | `confidence` | `resolution` |
|---|---|---|---|---|
| 1 | import-map | `dst_name` + `import_path` → exact imported symbol | 0.95 | `import-map` |
| 2 | import-suffix | import path suffix match | 0.85 | `import-suffix` |
| 3 | same-module | symbol in the same file/module | 0.90 | `same-module` |
| 4 | unique-name | exactly one project-wide symbol with that name | 0.75 | `unique-name` |
| 5 | suffix+distance | suffix match weighted by import distance | 0.55 | `suffix` |
| 6 | fuzzy | string similarity ≥ threshold | 0.30–0.40 | `fuzzy` |
| — | unresolved | none matched | 0.0 | `unresolved` (kept with `dst_name`) |
| ★ | lsp pass | LSP confirms the edge (Go/C/C++/TS receivers) | 1.00 | `lsp` |

`resolvePending` runs only over edges with `dst_symbol_id IS NULL` (the
`idx_edges_pending` partial index) — cheap on incremental re-index.

---

## 9. Query layer (`oql/graph/query.ts`)

```sql
-- who-calls (reverse edges)
SELECT s.* FROM edges e JOIN symbols s ON s.id = e.src_symbol_id
WHERE e.dst_symbol_id = @sym AND e.kind = 'CALLS' AND e.confidence >= @minConf;

-- impact / blast-radius: reverse-CALLS transitive closure, depth-capped, deduped
WITH RECURSIVE impact(sym, depth) AS (
  SELECT @sym, 0
  UNION                                   -- UNION (not UNION ALL) dedups visited → no cycles blow-up
  SELECT e.src_symbol_id, impact.depth + 1
  FROM edges e JOIN impact ON e.dst_symbol_id = impact.sym
  WHERE e.kind = 'CALLS' AND impact.depth < @maxDepth
)
SELECT DISTINCT s.*, impact.depth FROM impact JOIN symbols s ON s.id = impact.sym
WHERE impact.sym <> @sym ORDER BY impact.depth;

-- reachability / dead-code: forward closure from roots; symbols NOT in it = candidate-dead
WITH RECURSIVE reach(sym) AS (
  SELECT value FROM json_each(@roots)
  UNION
  SELECT e.dst_symbol_id FROM edges e JOIN reach ON e.src_symbol_id = reach.sym
  WHERE e.dst_symbol_id IS NOT NULL
)
SELECT s.* FROM symbols s
WHERE s.root_id = @root AND s.id NOT IN (SELECT sym FROM reach)
  AND s.is_entrypoint = 0 AND s.is_exported = 0;   -- roots = entrypoints ∪ exports (∪ routes ∪ test refs)

-- symbol search
SELECT s.* FROM symbol_fts f JOIN symbols s ON s.id = f.rowid
WHERE f.symbol_fts MATCH @q AND s.root_id = @root LIMIT @limit;
```

Roots for reachability = `is_entrypoint OR is_exported` plus route handlers and
test-file references; everything else is **candidate**, never `dead:true`, and any
symbol reached only through `confidence < 1.0` or `unresolved` edges is flagged
`dynamicEdgeUnresolved`.

---

## 10. OQL integration

- **Source:** `from:{kind:"index"; path:string}` added to `QuerySource`
  (`types.ts`, `schema.ts`, `normalize.ts`, `shorthand.ts`).
- **Routing (`planner.ts`):** a relational query (callers/callees/impact/dead-code)
  over a path with a **fresh** index → `PUSHDOWN` to the graph; **missing/stale** →
  `ROUTE` to live LSP/AST (today's behavior) + emit `next.ingest`.
- **Targets:** graph-backed `semantics` (`callers`/`callees`/`callHierarchy`),
  graph-backed `research` reachability (multi-language now), and **new
  `target:"impact"`** (blast-radius rows: `{symbol, depth, minConfidence, dynamicEdgeUnresolved}`).
- **Result rows:** add **`resolution: "lexical" | "semantic" | "index"`** and carry
  edge `confidence`; bind evidence: `index`+`lsp`/OXC → `proof`, else `candidate`.
- **Diagnostics:** `staleIndex`, `indexMissing`, `dynamicEdgeUnresolved`.
- **Continuation:** `next.ingest` (executable `octocode ingest` for the root).
- **Introspection target `index`** (operation target, like `materialize`): a typed
  way for agents to "check last ingest / what & which ingested / check all" without
  shelling the CLI. `recordType:"index"`:

```jsonc
{ "schema":"oql","target":"index","from":{"kind":"index","path":"."},
  "params":{"op":"status"} }     // op: status | coverage | which | check | verify
```

  | `op` | Returns (`data`) |
  |---|---|
  | `status` | `lastRun` (when/mode/duration/counts) + totals + `staleFiles` |
  | `coverage` | per-lang files/symbols, parse-status breakdown, unresolved-edge count |
  | `which` | the ingested-file inventory (lang, symbols, mtime, parse_status, stale) — paginated |
  | `check` | the smart dry-run **plan** (new/changed/deleted/fresh) — no mutation |
  | `verify` | integrity/freshness issues with severity; `ok:false` blocks `proof` |

  A `status`/`check` showing `staleFiles>0` carries `staleIndex` + `next.ingest`.

```jsonc
// "what breaks if I change compileMatcher?"
{ "schema":"oql","target":"impact","from":{"kind":"index","path":"."},
  "params":{"symbolName":"compileMatcher","maxDepth":5},
  "select":["data","resolution"],"view":"paginated" }
```

---

## 11. CLI / MCP surface

**Reconciled with the existing `cache` command (verified `cli/commands/cache.ts`)
— no duplicate surface.** `cache status` / `cache clear --…` / `cache fetch
--force-refresh` already exist; status + eviction route through them (a `--graph`
selector joins `--clone|--tree|--binary|--unzip|--all`). `ingest` is the one new
build/introspect verb; **avoid `ingest --status`** (collides with top-level
`octocode status` = auth).

```bash
octocode ingest [--path=./src]          # SMART incremental (default): changed+new, prune deleted, re-resolve
octocode ingest --path=./src --full     # force full re-index of this root
octocode ingest --path=./src --check    # DRY RUN: print plan (new/changed/deleted/fresh) + last run; writes nothing
octocode ingest which  [--path=./src]   # list ingested files: lang, #symbols, mtime, parse_status, stale?
octocode ingest verify [--path=./src]   # "check all": integrity + freshness doctor; exit≠0 on errors

# status + eviction reuse the EXISTING cache family (extended, not duplicated):
octocode cache status                   # now also reports the graph store (last ingest / coverage / stale)
octocode cache clear --graph            # NEW selector beside --clone|--tree|--binary|--unzip|--all
```

- **`cache status`** (the "check last ingest"): the existing command, extended —
  prints the graph store's `lastRun` (started/finished, mode, duration, files
  ingested/fresh/deleted/unparsable, symbols/edges/resolved), per-lang coverage,
  and `staleFiles` (on-disk newer than DB), beside clone/tree/binary/unzip. `--json`.
- **`ingest which`** (the "what & which ingested"): `listFiles` — every ingested
  file with lang, symbol count, mtime, parse_status, and a `stale` flag; filterable
  (`--lang`, `--stale`, `--unparsable`).
- **`ingest --check`** (the "smart preview"): the dry-run plan — cheap "what would
  change?" without touching the store.
- **`ingest verify`** (the "check all"): runs `GraphStore.verify` — orphan/dangling
  edges, stale files, files on disk missing from the graph, unresolved-edge ratio,
  schema-version match, FTS integrity — and exits non-zero on any `error`.
- **eviction:** `cache clear --graph` (new selector) joins the existing
  `--clone|--tree|--binary|--unzip|--all` GC — one disk budget, not two.

MCP: an `ingest` tool (`op: ingest|check|which|verify`) + a `--graph`-aware
`cache` (`op: status|clear`) + the new OQL targets; schema/descriptions sourced
from `octocode-core` (single-source metadata).

---

## 12. Honesty & security

- Graph answers are **`candidate`** unless an edge is `resolution:"lsp"`/OXC → `proof`.
- Reachability/impact never emit `dead:true`; flag `dynamicEdgeUnresolved` for any
  symbol reached only via `confidence<1.0`/`unresolved` edges. Static-only blind
  spots (macros, reflection, dynamic dispatch, DI, generated code) stated in output.
- **Self-exclusion:** ingest + search skip `getOctocodeDir()` (the DB lives there);
  the `.sqlite` secret-scanner filter must not flag our own store.
- Path validation + secret sanitization apply to every row written and returned.
- **Freshness & provenance (FPP — plan §2A):** ingest is one participant in the
  unified protocol. A graph root built from a materialized GitHub source records
  `source_kind`/`source_ref`/`resolved_sha` + a pointer to the clone's
  `.octocode.json`, so it revalidates against upstream (git-sha anchor) exactly
  like the clone/tree caches — not on TTL alone. Local roots use the per-file
  `mtime+xxh3` anchor already in §2.1. The graph DB joins the **unified GC/disk
  budget** with `tmp/{clone,tree}` rather than running a separate eviction policy.

---

## 13. Alternatives considered

**Storage engine:** SQLite chosen. KuzuDB ❌ archived Oct 2025; CozoDB ❌ stale
(Dec 2024, pre-1.0); RocksDB ⚠️ no query ergonomics; DuckDB/Neo4j ❌ wrong tool.
Recursive CTEs verified fast enough (0.3 ms blast-radius / 150 ms dead-code @196k
edges).

**Where the store lives:** **B (tools-core/`better-sqlite3`) chosen for MVP** —
per-file ingest means no bulk napi marshaling, all logic next to the planner, FTS5
default, prebuilds fit distribution. **A (`rusqlite` in-engine)** deferred as the
whole-monorepo perf tier behind `GraphStore`. **C (split, two SQLite libs on one
file)** rejected. `node:sqlite` verified working (Node v22.22, FTS5+CTE) but
experimental → not under a core capability.

**Build vs adopt:** build — nothing embeds in a Rust engine; the only embeddable
Rust crate (`stack-graphs`) is archived. SCIP kept as optional read-only interop.

**Do nothing:** leaves relational queries to per-query LSP/grep (slow, not proof)
and `research` broken for non-JS/TS — the verified gaps persist.

---

## 14. Blast radius / files touched

- **tools-core (new):** `oql/graph/{store,ingest,resolve,query}.ts`, `ingest` command.
- **tools-core (edit, ~10):** `oql/{types,schema,normalize,shorthand,defaults,capabilities,planner,run,schemeText}.ts`, `adapters/index.ts` (+ `compile`/`runner`/`resultMap`), `index.ts` barrel.
- **engine (new):** `signatures/graph.rs` + `bindings/graph.rs` (+ `.scm` per lang); regenerate `.d.ts`.
- **existing CLI (extend, not duplicate):** `cli/commands/cache.ts` (`cache status`
  reports the graph; `cache clear --graph` selector) and the shared sidecar/GC in
  `tools/github_clone_repo/cache.ts` (FPP `.octocode.json` schema + revalidation +
  unified eviction across clone/tree/binary/unzip/graph). New `cli/commands/ingest.ts`.
- **deps:** `better-sqlite3` → **new Node dep** of tools-core (prebuilds; bundle).
  **No new Cargo dep** (rusqlite deferred).
- **docs:** `OCTOCODE_QUERY_LANGUAGE.md`, `..._PLAN.md`, `..._PARITY_CHECKLIST.md`,
  `..._SEARCH_EVAL.md`, auto-gen `benchmark/SUPPORT.md`, `octocode-core` texts, `README.md`.

---

## 15. Test & verification plan

**Unit (tools-core):**
- migrations: fresh DB → v1; unknown future version → refuse + advise `--reset`.
- `GraphStore`: upsertRoot idempotent; replaceFile txn (old gone, inbound→NULL, new in); FTS sync triggers.
- resolve cascade: one fixture per strategy 1–6 + unresolved; confidence values exact.
- incremental: change 1 file → only its rows replaced; inbound edges re-bound by `resolvePending`; deleted symbol → inbound edge `dst_symbol_id` NULL not row-deleted.

**Unit (engine):** `extractGraph` per language fixture → expected symbols/edges; `parsed:false` on syntax error (no panic); comment/string callees excluded (reuse classify immunity).

**Integration:**
- ingest a fixture repo (multi-lang) → assert counts; `callers`/`impact`/dead-code queries return expected sets; staleness: touch a file → query emits `staleIndex` + `next.ingest`; after re-ingest → fresh.
- `impact` depth cap + cycle (A↔B) terminates (UNION dedup).

**Smart ingest & observability:**
- **smart incremental:** edit 1 file, add 1, delete 1 → second ingest parses only the 2 (edited+new), prunes the deleted (its inbound edges revert to `unresolved`, not dropped), `files_fresh` counts the rest; `lastRun` reflects exact counts.
- **`--check` dry-run:** run after edits → plan lists correct new/changed/deleted/fresh and **mutates nothing** (row counts + `lastRun` unchanged afterward).
- **`--status`:** reports `lastRun` (mode/duration/counts) + per-lang coverage + `staleFiles` after a touch; `--json` shape stable.
- **`--which`:** `listFiles` returns every ingested file with symbol count + `stale` flag; `--lang`/`--stale`/`--unparsable` filters narrow correctly.
- **`--verify` doctor:** seed each issue and assert detection — orphan edge, dangling `dst_name`, stale file, on-disk file missing from graph, forced `schema_version` mismatch, `PRAGMA integrity` / FTS `'integrity-check'`, high unresolved ratio; exit≠0 only on `error`-severity.
- **OQL `target:"index"`:** each `op` (status/coverage/which/check/verify) returns the documented `data`; `verify ok:false` blocks `proof`; `staleFiles>0` attaches `staleIndex`+`next.ingest`.

**Parity / honesty:** graph `callers` vs LSP `references` on a fixture → graph ⊇ high-confidence subset; DI/reflection fixture → edge `unresolved` + `dynamicEdgeUnresolved` surfaced (never `dead:true`).

**Perf (gate):** ingest this monorepo; record fresh + incremental time, DB size, blast-radius/dead-code latency. Targets (order-of-magnitude of Codebase-Memory): incremental < ~2 s, blast-radius < ~5 ms, dead-code < ~300 ms on ~200k edges.

**OQL (`--explain`):** fresh index → `PUSHDOWN backend:"index"`; stale/missing → `ROUTE` + `next.ingest`; new diagnostics distinct; `resolution` on every row.

**Eval rows (`OCTOCODE_SEARCH_EVAL.md`):** ingest+status; who-calls; impact; dead-code multi-lang; staleness→continuation; index-vs-LSP confidence.

---

## 16. Implementation steps (ordered by dependency)

1. `extractGraph` napi + `.scm` tags-queries for top langs (ts/js via OXC, py, go, rust); `.d.ts` regen.
2. `store.ts`: schema + migrations + `GraphStore` over `better-sqlite3`; unit tests.
3. `ingest.ts`: smart pipeline (walk + mtime/XXH3 diff + `replaceFile` + **delete-prune** + `recordRun`); `ingest_runs` table; `--full`/`--check`/`--reset`.
4. `resolve.ts`: 6-strategy cascade + `resolvePending`; tests.
5. `query.ts`: callers/callees/impact/reachable/FTS; tests.
6. **Observability:** `lastRun`/`runHistory`/`coverage`/`listFiles`/`verify`; CLI `ingest which`/`ingest verify` + extend `cache status` (graph section) and `cache clear --graph` (`cli/commands/cache.ts`); tests.
7. OQL wiring: `from:{kind:"index"}`, `target:"impact"`, **`target:"index"` (status/coverage/which/check/verify)**, `resolution` field, diagnostics, `next.ingest`, planner routing; `--explain` tests.
8. Graph-backed `semantics` + multi-lang `research` reachability.
9. Optional LSP proof-pass (receiver-heavy langs).
10. Docs + eval rows + `octocode-core` texts; perf gate.
11. (Deferred) Option A `rusqlite` writer behind `GraphStore`; SCIP read-interop.

---

## 17. Risks & open questions

| Risk | Mitigation |
|---|---|
| `better-sqlite3` native prebuild gaps on a target platform | ship prebuilds in the bundle; fall back to `node:sqlite` (pinned Node) behind `GraphStore` |
| DB grows across many roots | size cap + LRU-evict cold roots; `--reset` |
| Two concurrent ingests corrupt state | advisory lock file; WAL keeps readers safe |
| Resolution false edges mislead agents | confidence + `resolution` on every edge; `candidate` unless LSP/OXC |
| Stale graph answers silently | mtime/hash check per touched file → `staleIndex` + `next.ingest`; never silent |
| Schema migration on a shipped DB | versioned migrations; unknown version refuses + advises `--reset` |
| **Open:** which langs get visitor vs tags-query extraction first? | start ts/js (OXC) + py/go/rust visitors; tags-query the rest |
| **Open:** entrypoint detection per ecosystem (roots for reachability) | manifests (`main`/`bin`/`exports`), framework routes, test globs — iterate per lang |

---

## 18. Evidence & sources

- Codebase-Memory (tree-sitter→SQLite, 6-strategy cascade, XXH3, perf, failure modes) — arXiv 2603.27277, Vogel et al., 2026-03-28. `strong`
- SQLite chosen / KuzuDB archived (Pavlo CMU 2026-01-04; The Register 2025-10-14) / CozoDB stale (Dec 2024); CTE perf — `strong`/`moderate`
- Node-native SQLite verified locally (Node v22.22: FTS5+CTE work, `ExperimentalWarning`) → `better-sqlite3` for stability. `strong` (local)
- Build-vs-adopt (CodeGraph TS / Serena Python / SCIP per-lang CLIs / stack-graphs archived Sep 2025) — `strong`
- tree-sitter tags-queries (ctags/GitHub code-nav `.scm`) — established pattern. `moderate`
- Engine facts: `extractor.rs` uses `tree_sitter::Query`+`.scm`; `getOctocodeDir()` (`loader.ts:133`, platform-aware, no env override); clone-cache sibling (`cache.ts:32`); `.sqlite` secret filter (`discoveryFilter.ts:166`); ~30 grammars / 47 signature / 56 LSP langs (`benchmark/SUPPORT.md`). `strong` (local code, verified)
