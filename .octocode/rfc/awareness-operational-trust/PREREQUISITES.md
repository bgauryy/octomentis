# Prerequisites: Octocode Awareness Operational Trust

Status: BLOCKED — RFC amendment review, live-state disposition, memory parity, and package gates are open

Scope authority: [RFC goals and non-goals](./RFC.md#goals-and-non-goals)

## Required Current-State Evidence

Before changing behavior, preserve reproducible baselines for the current checkout and a sanitized snapshot of the real store:

1. Record commit, package versions, Node version, `process.versions.sqlite`, database path/fingerprint, `PRAGMA user_version`, journal mode, and database byte size.
2. Record exact counts for plans, tasks by status, runs by origin/status, open run files, claims, locks, signals, refinements, memories, edit log, run log, and sessions.
3. Capture `attend --compact`, `query workboard --compact`, `verify audit`, `workspace status`, `maintenance digest --dry-run`, route help/schema output, and isolated package verification.
4. Generate fixtures for: more than 500 ready tasks; expired WORK; paused/completed plan with open task; two agents editing one file; an undeclared edit; and every unsupported schema version.
5. Save the commands and sanitized results under the implementation evidence directory, not in mutable task state.

The 2026-07-09 baseline that motivated this RFC is summarized in [RFC.md](./RFC.md#current-evidence) and sourced in [RESOURCES.md](./RESOURCES.md#local-measurements).

## Environment and Setup

- Work from the monorepo root and read both root `AGENTS.md` and `packages/octocode-awareness/AGENTS.md`.
- Use the canonical package source under `packages/octocode-awareness`; never edit `dist/`, `.agents/skills/`, or Pi mirrors by hand.
- Run `yarn workspace @octocodeai/octocode-awareness build` after canonical skill or generated-contract changes.
- Tests must use isolated temporary stores. Never mutate `~/.octocode/memory/awareness.sqlite3` in a test.
- Preserve unrelated user changes in a dirty worktree.
- Use advisory Awareness work declarations for ordinary files and `--exclusive` only for migration/release-sensitive files.

## Baseline Verification

Run the following on the starting commit and attach the results. Any failure remains an explicit gate; the current `check:no-workspace` failure is P4 evidence, not a reason to omit the command:

```bash
yarn workspace @octocodeai/octocode-awareness test
yarn workspace @octocodeai/octocode-awareness typecheck
yarn workspace @octocodeai/octocode-awareness build
yarn workspace @octocodeai/octocode-awareness pack:check
yarn workspace @octocodeai/pi-extension test
yarn workspace @octocodeai/pi-extension check:no-workspace
```

Also record targeted hook, CLI-contract, plan/task, verification, package, and migration tests from the v3 baseline. The original baseline was 38 files/654 tests and 130 isolated files. Revalidation at `a4383dec` passed Awareness `test:quiet`, typecheck, 29 focused v4 tests, the 133-file isolated package check, and Pi 11 files/192 tests (2 skipped); `check:no-workspace` failed on two runtime dependencies. The implementer must rerun rather than copy these results.

## Gate Ledger

| Gate | Status | Owner | Evidence / exit | Last checked | Blocks |
| --- | --- | --- | --- | --- | --- |
| P0 decision approval | open | package owner | named approval + accepted RFC revision | 2026-07-10 | Phase 1/public contracts |
| P1 recovery copy | open | plan lead | sanitized audit + restore proof on copy | 2026-07-10 | canonical cutover |
| P2 runtime safety | partial | runtime maintainer | classifier exists; supported runtime matrix + `doctor` remain | 2026-07-10 | file-backed concurrency/release |
| P3 archive/import | open | migration owner | disposable create-copy-swap and failure preservation | 2026-07-10 | canonical cutover |
| P4 package integrity | blocked | Awareness/Pi maintainers | strict declarations, real tarballs, TS consumer, no workspace protocols | 2026-07-10 | release |
| P5 live-state disposition | blocked | plan lead | zero active mutators/unreviewed actionable rows | 2026-07-10 | canonical cutover |
| P6a memory representability | blocked | memory owner | field inventory + frozen corpus/v3 expectations + amended schema representation | 2026-07-10 | schema freeze |
| P6b memory parity | blocked | memory owner | implemented importer/readers prove field/ref/FTS/embedding/recall/no-ghost parity | 2026-07-10 | canonical cutover |

## Gates Before Implementation

### P0 — RFC approval

The package owner approves the amended schema, sensitive-path fail-closed rule, cooperative-host disclosure, ordinary-policy experiment/decision rule, evidence-bearing finish, route/API deletion map, local reset/import policy, and RFC consolidation table. The ordinary strict-versus-session default may remain gated until its KPI sample passes; without P0 approval, do not mutate public contracts.

### P1 — State audit and recovery copy

Create a sanitized state audit and a restorable database backup before any migration experiment. Prove the restore procedure on a copy. Existing plan anomalies and unverified debt are reported; they are not silently fixed.

### P2 — Runtime safety baseline

The supported runtime matrix must identify the SQLite library actually embedded in each supported Node line. SQLite documents a WAL-reset concurrency defect in versions through 3.51.2, fixed in 3.51.3 and backported to 3.50.7/3.44.6. The policy is closed by RFC R-A7: classified-unsafe versions use rollback journaling and are diagnosed; WAL is enabled only for classified-safe versions. Node 22.22.3 includes SQLite 3.51.3.

Exit: CI covers at least one supported safe runtime and `doctor` can identify an unsafe one.

### P3 — local archive/import proof

There are no external users, so a compatibility release is unnecessary. Before replacing the local v3 store:

- close connections and take a SQLite-consistent archive beside the database;
- prove the archive opens read-only with the old code;
- create v4 in a temporary path from canonical DDL, never by shape mutation;
- transform the durable-entity allowlist and generate source/import/omitted counts plus ID mappings;
- run `foreign_key_check`, `integrity_check`, domain invariant checks, and representative reads;
- atomically swap only after every check passes;
- prove failed import leaves the original path untouched;
- prove the v4 runtime rejects every version other than 4 before DDL or writes.

The old database is the audit archive, not an indefinitely supported live format. Volatile runtime rows are summarized and deliberately reset; no pending row is relabeled successful.

### P4 — Awareness and Pi package integrity

Verify both packed packages from clean installs without ancestor `node_modules`. Awareness declaration generation must fail closed for release, the exact `package.json#types` target must be present, and a clean TypeScript consumer must compile against the `.tgz`. Pi must resolve every emitted runtime import. Choose publish/pin, bundle, or deliberate delegation for Awareness and tools-core; current `workspace:*` dependencies make `check:no-workspace` fail.

Exit: real Awareness/Pi tarballs install in empty directories, a TS consumer imports Awareness, Pi starts, skill/CLI smokes pass, declaration generation is fatal, and no workspace/file dependency protocol remains.

### P5 — Existing-state import audit

Before cutover, produce counts and IDs for:

- DRAFT/PAUSED/COMPLETED/CANCELLED plans with OPEN, IN_PROGRESS, BLOCKED, or VERIFY children;
- expired claims and ACTIVE runs;
- terminal runs with live files, locks, or claims;
- session IDs associated with conflicting agent/workspace/artifact values.

Revalidation found 4 plans (1 ACTIVE), 13 tasks (1 IN_PROGRESS), one ACTIVE TASK run, 34 OPEN signals, and 90 OPEN/ONGOING refinements. P5 is therefore blocked. Immediately before cutover, produce a disposition ledger for every nonterminal plan/task/run and actionable signal/refinement: complete, cancel/resolve, import as Task/Signal/Memory, or explicitly archive with owner/reason. Require no live mutator and zero unreviewed actionable rows. Preserve authored plan directories and summarize non-imported history in the manifest. Archive volatile runtime state. No anomaly is promoted to SUCCESS, DONE, or trusted knowledge.

### P6a — Memory inventory and pre-freeze representability

The provisional v4 DDL omits fields that current code uses for embeddings, validity, failure clustering, novelty, access/decay, ranking, and retrieval. Before schema freeze:

- inventory every used v3 memory column and reference kind;
- classify explicit synthetic/test rows separately from real knowledge;
- freeze a sanitized corpus, query set, and expected v3 field/reference/FTS/embedding/visibility results;
- amend the schema so it can represent every production-used field or an explicitly approved equivalent without loss.

### P6b — Implemented migration parity and forgetting proof

After Phase 1 provides the importer/readers and before canonical swap:

- reconcile IDs, rows, references, FTS hits, embeddings, validity behavior, failure clusters, and every frozen query result;
- prove default recall does not hide imported knowledge merely because provenance is incomplete;
- prove forget/retire removes FTS/projection/navigation/delivery ghosts while immutable operational evidence remains.

Blanket `ACTIVE → CANDIDATE` import is prohibited unless its visibility, trust, and recall behavior passes P6b.

## Contracts and Migration Constraints

- Database files are local single-store coordination boundaries. No remote consistency claim is made.
- Normal v4 startup accepts exactly schema v4 and performs no migration DDL. Fresh create and explicit v3 import are separate code paths.
- The v3 archive is created before v4; failed import leaves the original usable and at the original path.
- Imported memory/reference IDs remain stable, all used fields and representative recall behavior reconcile, and plan documents remain authored files. All omitted entity counts and dispositions are recorded in the migration manifest.
- Compact results use the final exact totals/row metadata and structured `next_action`; no v3 response compatibility layer is required.
- Removed routes/flags fail with the compact final command inventory; no aliases or replacement shims remain.
- ACTIVE work cannot be pruned. Unresolved signals and terminal activity history cannot be hard-deleted until a separate rollup design passes the KPI gate.
- Generated mirrors and packed artifacts must be derived from canonical source and parity-checked.

## Start Gate

Schema/service implementation may begin against temporary v4 fixtures when P0 is complete and P6a has frozen the corpus/representation contract. File-backed concurrent-WAL tests and production use also require P2; an unsafe local SQLite may run isolated in-memory schema tests only. The real local swap requires P1, P3, P5, and P6b. Hook/session work requires the amended v4 identity model. Release-related phases require P4.

If a gate fails, record it as a blocker with evidence; do not weaken the invariant to preserve momentum.
