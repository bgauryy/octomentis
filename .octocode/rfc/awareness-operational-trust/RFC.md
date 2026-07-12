# RFC: Octocode Awareness Operational Trust

Status: In Review — Amendment 1; production cutover paused

Mode: RFC — full folder set

Decision type: final-schema reset with a reversible local archive; the new store is a one-way door after meaningful v4 writes

Owners: Awareness maintainers

Approver: package owner (identity and approval evidence required at P0)

Original evidence date: 2026-07-09 at commit `debb3de0`

Revalidated: 2026-07-10 at commit `a4383dec`

Amendment reason: interim v3 fixes invalidated several current-state claims, the live store now has an ACTIVE plan/task/run, and the provisional v4 schema drops memory fields that current retrieval still uses. Only the isolated schema-identity/bootstrap and SQLite runtime-classification slice of Phase 0 exists under `packages/octocode-awareness/src/v4/`; Phase 0 is not complete and v4 is not wired to production.

## Document Set

- [Prerequisites](./PREREQUISITES.md)
- [Implementation](./IMPLEMENTATION.md)
- [Success and verification](./KPI.md)
- [Resources and evidence](./RESOURCES.md)

## Audit Reasoning — kept (2026-07-12)

**Status:** Mixed — interim v3 items (work/plan/task CLI, hooks) are live; the RFC's core **v4 16-relation schema-reset plan is obsolete**. `canonical-awareness-v1` already shipped and was accepted with `OCT1`/`user_version=1` on the current 22-table schema, and explicitly removed the staged `src/v4/schema.ts` this RFC proposed replacing it with.
**Why kept (not deleted):** Other kept RFCs (`awareness-reflection-scorecards`, the operational remainder of `homeostatic-awareness-loop`) still point here as "the umbrella that owns operational remainder" — deleting this file would orphan those dependency notes. Several still-open product goals from this RFC (exact `WorkspaceSnapshot` parity, hook debt without per-edit HOOK runs, a `doctor` diagnostic route, one route-level command contract) have not landed under any other RFC either.
**Evidence:** `AWARENESS_APPLICATION_ID = 0x4f435431` (`db-runtime.ts`) is `OCT1`, not `OCT4`; no `src/v4/` tree exists; no `doctor` route; `src/intents.ts`/`src/verify.ts`/`src/refinements.ts` — this RFC's deletion targets — are all still present and in active use.
**Action needed before this RFC is trustworthy again:** strip the v4 cutover/schema-reset plan from `RFC.md`/`IMPLEMENTATION.md`, keep only the still-open product goals listed above, and re-point dependent RFCs at the corrected version.

## Summary

Keep the useful domain model—Plan → Task → Run → RunFile, with advisory file awareness and optional exclusive locks—but replace the accumulated v3 storage/API shape with one smaller final v4 coordination design. There are no external users to preserve, but the local data is real and currently active: archive the complete v3 database, preserve authored plan files and memory behavior losslessly, require explicit disposition of live/actionable rows, reset only reviewed volatile runtime debt, and delete compatibility paths.

The change has seven connected parts:

1. A fresh 16-relation v4 schema removes duplicated claims/locks/events/refinements/read-state and separates stable agents from host sessions.
2. One exact, agent-aware `WorkspaceSnapshot` feeds `attend`, workboard, `doctor`, projections, and hooks.
3. Plan, task, run, session, verification, and lock transitions gain explicit invariants and one transactional owner.
4. Hooks attach edits to a Task or Work attempt. Sensitive/self-modifying paths require explicit work and fail closed; ordinary uncovered edits may open one session-scoped Work from the current goal. There are no per-edit HOOK runs.
5. One route-level command contract and one application dispatcher replace CLI/tool/schema aliases and duplicated switches.
6. The common agent flow becomes at most three Awareness commands. The always-visible skill remains a compact lobby; deeper references load only when active work, coordination, or maintenance needs them.
7. Runtime diagnosis, atomic projections, package verification, and report-first retention make failures visible before they become silent state drift.

This is an umbrella RFC. It consolidates the remaining operational work from earlier Awareness RFCs so implementation has one dependency order and one success contract.

## Decision Contract — Amendment 1 Draft

This section is normative when accepted. `IMPLEMENTATION.md` may elaborate steps but may not change this contract without another RFC amendment.

- **Storage inventory:** exactly 16 named logical relations: `agents`, `sessions`, `plans`, `plan_docs`, `tasks`, `task_paths`, `task_dependencies`, `runs`, `run_files`, `activity_events`, `signals`, `signal_recipients`, `deliveries`, `memories`, `memory_refs`, and `memories_fts`.
- **R-A1 session instances:** host-session uniqueness applies only to non-ended internal instances; resuming an ended host conversation creates a new immutable instance.
- **R-A2 plan-document scope:** plan-directory uniqueness is `(workspace, artifact, doc_dir)`, never global `doc_dir` alone.
- **R-A3 run truth:** ABANDONED has no result receipt, terminal runs have no live presence/exclusivity, and run/session/task/plan agent/scope equality is enforced transactionally.
- **R-A4 signal audience:** direct versus broadcast is explicit; every broadcast reader has independent read state without changing the audience.
- **R-A5 memory preservation:** every production-used memory field/reference/FTS/embedding/default-visibility behavior has a pre-freeze representation and pre-cutover parity proof.
- **R-A6 snapshot envelope:** every bounded lane, including an empty lane, returns one `LaneEnvelope` with `rows`, `total_count`, `returned_count`, `omitted_count`, and `exact`; count and row queries use identical explicit null-artifact scope semantics. The accepted response fixture/hash is frozen beside the route manifest.
- **R-A7 SQLite journal policy:** classified-unsafe embedded SQLite versions use rollback journaling and are diagnosed; WAL is enabled only on classified-safe versions. The runtime matrix and `doctor` evidence remain a release gate, not an open policy choice.
- **Public route revision:** 37 routes grouped as `attend`; plan 4; task 8; work 4; signal 4; memory 3; `reflect`; `query`; `project`; `prune`; `doctor`; hooks 3; docs 2; schema 3. `memory forget` is the non-ghosting removal vocabulary. The exact route names are frozen with the accepted fingerprint/manifest.
- **Deletion boundary:** remove separate public lock/verify/refinement/agent/session-maintenance lifecycles, per-edit HOOK runs, adapter correlation stores, aliases, and duplicated dispatch/schema/help facts. Do not delete current memory capabilities or actionable rows by calling them compatibility state.
- **Migration boundary:** no rolling v3 compatibility; byte-for-byte archive plus just-in-time disposition and lossless-memory manifests; no swap with live mutators or unreviewed actionable rows.

Accepted schema fingerprint: **pending R-A1–R-A5 TDD amendments and P6a**. Accepted snapshot fixture/hash: **pending R-A6 TDD fixture**. Accepted route/deletion manifest: **pending Amendment 1 approval**.

## Goals and Non-Goals

### Goals

- **G1 — Truthful state:** all displayed totals are exact, bounded row lists disclose what was omitted, and every stale/abandoned attempt reported by `doctor` is discoverable from the primary workspace view.
- **G2 — Useful next action:** `attend` selects a safe next action for the current agent and workspace, explains why, and never turns another agent's debt into the caller's action.
- **G3 — Coherent lifecycle:** plan status governs task readiness; agent, session, task, run, file, result, signal, and exclusivity state cannot contradict each other after a successful transaction.
- **G4 — Awareness without lock pressure:** on a healthy host with blocking hooks, every edit belongs to a reasoned Task/Work run, sourced either explicitly or from the current session goal. Multiple agents may work on the same file; expiring exclusivity remains opt-in for sensitive work. Incapable/degraded hosts are reported as cooperative-only and expose unattributed-edit diagnostics instead of claiming enforcement.
- **G5 — No per-edit synthetic debt:** finish records explicit evidence atomically and hooks never create durable per-edit fallback runs; at most one session-scoped Work may cover ordinary uncovered edits.
- **G6 — Low-cost agent UX:** a normal task or standalone change uses no more than three Awareness commands; compact outputs remain bounded; passive workspace guidance loads only the compact lobby, not deep references.
- **G7 — One small public contract:** one dispatcher and route registry own runtime validation, CLI help, JSON schemas, docs examples, hook capabilities, install guidance, and packaged artifacts; legacy aliases are removed.
- **G8 — Safe local operation:** schema versions fail closed, sessions cannot be reused across identities/scopes, supported SQLite versions are diagnosed, and expiry/retention never silently converts unfinished work into success.
- **G9 — Lossless knowledge cutover:** every current memory field, reference, FTS behavior, and representative recall result is reconciled before swap; no unreviewed memory becomes more trusted and no active knowledge disappears behind a new default filter.

### Non-Goals

- Remote or multi-machine synchronization, a hosted coordination service, or distributed consensus.
- Mandatory exclusive locking for ordinary file changes.
- Replacing the database task graph with Markdown checklists, an issue tracker, or a second `plan_steps` entity.
- Automatically running tests or inferring success from process exit without explicit finish evidence; second-agent review is modeled as a review task, not a hidden generic verification queue.
- Surprise ranking, learned memory navigation, adaptive context curation, autonomous instruction/harness mutation, model-weight evolution, or a persistent Awareness persona. Those require follow-on RFCs after the core v4 store is stable; this RFC keeps only exact provenance/drill-down and migration-safety hooks needed by the cutover.
- Preserving the v3 database as a live store, the broad function-by-function package export surface, flat/notification/pre-flight aliases, `--compat-coerce`, ignored flags, or lock release implicitly completing a run.

## Motivation

### Current Evidence

The package is not starting from a broken foundation. The original `debb3de0` baseline passed 38 test files/654 tests. Revalidation at `a4383dec` passed the package `test:quiet` workflow, Awareness typecheck, the 29 focused v4 tests, the 133-file isolated package check, and Pi's 11 files/192 tests (2 skipped). The Pi publish-protocol gate still fails because two runtime dependencies remain `workspace:*`.

The original trust gaps appeared under real accumulated state and concurrency. Revalidation separates historical evidence from what is fixed or still open:

| Observation | 2026-07-10 evidence | State / why it matters |
| --- | ---: | --- |
| Pending HOOK runs in this workspace | 1,265; 749 older than 24 hours by `julianday(updated_at)` | **Open.** The earlier count of 238 used a non-equivalent ISO-text comparison. Per-edit fallback still creates debt faster than agents close it. |
| Workboard Ready count beyond row cap | exact SQL totals now implemented | **Fixed in interim v3.** Preserve as a v4 regression test, not a current defect. |
| Repo-profile file total | 500-row fetch reused as `tracked_files`; live query reports 500 with 243 missing refs | **Open.** Another capped lower bound is still presented as a total. |
| Expired active WORK | isolated probe: `attend` Verify 0; `verify audit` 1 | **Open.** The primary view can still deny stale work. |
| Plan status gates task readiness/claim | ACTIVE predicates now implemented | **Fixed in interim v3.** Preserve as a v4 invariant. |
| Live migration state | 4 plans (1 ACTIVE), 13 tasks (1 IN_PROGRESS), 1 ACTIVE TASK run | **Blocks cutover.** Hard-coded empty-queue assumptions are stale. |
| Memory preservation | 102 ACTIVE workspace memories; 51 have no refs; current retrieval fields omitted by provisional v4 DDL | **Blocks schema freeze.** Simplification cannot precede parity evidence. |
| Actionable collaboration residue | 34 OPEN signals; 90 OPEN/ONGOING refinements, including 81 handoffs | **Blocks blind reset.** Every actionable row needs disposition or explicit archive. |
| Public contract/package gates | 68 routes; declaration emit can fail open; Pi has two `workspace:*` runtime specs | **Open.** Release artifacts are not yet fail-closed or registry-installable. |

The remaining root causes are visible at `a4383dec`, which still has 23 named logical relations including FTS and overlapping application paths (`bin/awareness.ts` 2,197 lines, `scripts/schema.mjs` 1,303, `src/tool-operations.ts` 753, `src/types.ts` 1,144):

- workboard exact totals are fixed at `src/repo-context.ts:1419`–`1432`, but repo-profile still derives totals from capped file rows at `src/repo-context.ts:945`–`1006` and `:1045`–`:1058`;
- stale active work is audited in `src/verify.ts:248`–`:277` but the workboard Verify selection at `src/repo-context.ts:1262`–`:1292` includes PENDING rows, not expired ACTIVE attempts;
- plan gating is fixed at `src/tasks.ts:279`–`:304` and `:324`–`:333`; this is historical evidence for the invariant rather than a remaining cause;
- hooks open and pend fallback runs in `bin/hook-runner.ts:545` and `:609`, with the same origin in `src/pi-hooks.ts:400`–`:421`;
- noun-level flag unions live at `bin/awareness.ts:175`–`:183` while routes, schemas, and help are separate registries;
- v3 now rejects foreign/future stores before journal/DDL at `src/db.ts:81`–`:125`; the remaining storage problem is duplicated v3 repair/migration logic, not future-version mutation.

### User Problem

An agent needs answers to four cheap questions before editing:

1. What plan or task should I work on?
2. Who else is touching these files, and why?
3. Is exclusivity required, or is shared awareness sufficient?
4. What must I verify before handing off?

Today those answers exist, but they are split across capped projections, lifecycle commands, skill references, and hook-created residue. The system can therefore be technically active while giving an agent a false picture of the workspace.

## Guide-Level Explanation

### Simple change, no task

The agent runs `attend`, then starts advisory work with files, rationale, and test plan. Other agents see the files under work and may still edit them. The agent runs its check and finishes with one evidence-bearing command:

```text
attend --compact
work start --file src/a.ts --rationale "fix parser" --test-plan "parser tests"
work finish --result SUCCESS --evidence "parser tests pass"
```

If a host hook observes an ordinary edit before explicit work starts, it may open one session-scoped Work whose rationale is the current session goal and whose source is `SESSION`; subsequent edits reuse it. The response tells the agent what was declared and how to replace it with an explicit Task/Work. For sensitive or self-modifying paths—schema, migrations, hooks, skills, security, release metadata—pre-edit requires explicit work plus exclusivity and fails closed with one remediation command. Hosts that cannot provide a stable session goal use strict mode.

### Planned collaboration

`plan create` continues to create a durable folder at `.octocode/plan/<timestamp>-<slug>/`, a lead-agent-owned plan record, `PLAN.md`, and `docs/`. Millisecond timestamps reduce same-name collision; the database uniqueness key is still scoped by workspace/artifact because two repositories may legitimately produce the same relative directory. The redundant per-plan manifest is removed. Tasks remain live database entities belonging to exactly one plan. Each task has reasoning, acceptance criteria, one or more workspace-relative paths, dependencies, and any number of execution runs.

Plans are ACTIVE by default; PAUSED/COMPLETED/CANCELLED plans expose no ready tasks. Agents choose and atomically claim work; participation is derived from lead, task creator/claimant, document author, and signals rather than stored twice. The lead controls plan status and may reopen a blocked/failed task with an explicit reason. `PLAN.md` describes objective and durable decisions; it does not duplicate a mutable task checklist.

### Shared file, optional exclusivity

Advisory work is the default. When two agents touch the same file, both declarations remain visible and conflict signals identify the overlap. `task claim --exclusive` or `work start --exclusive` adds an expiring exclusivity lease to the attempt's declared files only for sensitive operations such as migrations, generated manifests, release metadata, or edits that cannot be safely merged.

There is no separate public lock lifecycle. Exclusivity expires or is released when the attempt finishes/releases; it can never succeed or fail work independently.

### Finishing

`task finish --result SUCCESS|FAILED --evidence <text> --evidence-kind <kind>` and `work finish ...` atomically close presence/exclusivity, record the receipt, and terminalize the attempt. Evidence kind distinguishes automated checks, independent observation, user confirmation, and agent self-report. Neither command executes tests or invents a result. A crash/expired attempt becomes ABANDONED, never FAILED or SUCCESS. If independent review is needed, the plan lead creates a dependent review task.

## Reference-Level Explanation

### 1. Shared Workspace Snapshot

Add an internal `WorkspaceSnapshot` service parameterized by workspace, artifact, agent, row limit, and current time. It performs one consistent read transaction and returns:

- exact SQL totals per lane;
- bounded rows with `returned_count`, `total_count`, `omitted_count`, and `exact: true`;
- effective stale state for expired runs and active run files;
- current agent's run, unread direct signals, and abandoned/stale work;
- plans including plan status, lead, and ready-task totals;
- overlapping file work and exclusive locks as distinct concepts;
- a structured `next_action` (`command`, `args`, `reason`, `batch`, `destructive`) plus the current text `next` during migration.

Snapshot derivation is read-only. Claim/start/finish commands perform authoritative reconciliation transactionally. This avoids surprising writes from `attend` while preventing stale rows from becoming false presentation.

Next-action priority is: caller's stale/abandoned work → direct conflict/inbox → caller's active attempt → ready task on an ACTIVE plan → ACTIVE plan needing task selection → standalone work suggestion → due maintenance.

### 2. Lifecycle Invariants

- Only ACTIVE plans permit new task claims or contribute tasks to Ready; new plans are ACTIVE by default.
- PAUSED retains tasks but blocks new claims. CANCELLED blocks all work. COMPLETED requires every child task DONE or CANCELLED.
- Pausing/cancelling a plan does not falsify an already running claim; the lead must choose drain or explicit release, and the status response lists those claims.
- `task reopen` is lead-only, accepts BLOCKED or FAILED tasks, records a reason, and returns the task to OPEN only when its plan is ACTIVE.
- A session ID is immutable to its original agent/workspace/artifact. Reuse with different scope fails.
- Pi and shell shutdown both end the session; an unfinished run becomes ABANDONED.
- A terminal run has no live run files or exclusivity leases.
- A run is ACTIVE, SUCCESS, FAILED, or ABANDONED; there is no PENDING verification status.
- expiry/reconcile operations are one transaction and report changed and remaining anomalies.

### 3. Hook Enforcement

Each session instance may have at most one ACTIVE Task or Work run. A resumed external host conversation creates a new internal session instance; only one non-ended instance may own a given host/workspace/artifact identity. Pre-edit resolves the stable agent/session, checks peer exclusivity, and attaches/heartbeats the file as advisory presence. If ordinary work is uncovered and the host exposes a stable current goal, it opens one `WORK/SESSION` run for the session; otherwise it blocks with the exact start command. Sensitive/self-modifying paths always require an explicit run and exclusivity on healthy blocking-capable hosts. Incapable/degraded hosts are explicitly cooperative-only and must surface unattributed edits in `doctor`. Post-edit appends one typed EDIT activity event. Shell Stop/Pi `agent_end` warn on unfinished work; session shutdown marks it ABANDONED with no result evidence and ends presence.

Because run ownership is unique per session, hooks do not need filesystem run queues or a durable hook-correlation table. A host event ID deduplicates activity events when provided. The ordinary-edit policy is validated by a strict-versus-session-work experiment before production defaulting; false blocks, unattributed edits, bypass/retry, abandoned work, coordination discovery, token cost, and task quality decide the result.

### 4. Route-Level Command Contract

A dependency-free command-contract module defines each canonical route, action, flags, cardinality, defaults, exit semantics, compact response, and examples. Build output materializes self-contained CLI and schema artifacts from it. Conceptual prose remains authored documentation; mechanical command facts are generated and parity-tested.

Ignored flags become errors. This is an intentional contract correction.

### 5. Skill and Install Surface

The generated workspace instruction and skill entry are a short lobby: use `attend` when freshness matters, declare edits, request `--exclusive` only for sensitive work, and load focused references for active work, collaboration, lifecycle, or maintenance. The 49-line lobby may be always available; read-only questions do not load the 27 deeper references.

The lobby puts the common commands directly in its first screen and makes deep references conditional. Reflection runs only for reusable lessons; maintenance runs only when the snapshot says it is due.

Install docs use one audience matrix: named skill install for Octocode users, exact package path for direct package consumers, and implicit database initialization on first command. No unresolved `<package>` placeholder remains.

### 6. Proposed v4 Storage Model

The v4 store has 16 named logical relations: 15 regular tables and one FTS5 virtual table. Indexes and SQLite-owned FTS shadow tables are implementation artifacts and are excluded from this count.

| Area | Tables | Simplification |
| --- | --- | --- |
| Identity | `agents`, `sessions` | stable agent ID is distinct from generated session instance ID and external host session ID |
| Planning | `plans`, `plan_docs`, `tasks`, `task_paths`, `task_dependencies` | contributors are derived from events; no `plan_members` table; document-directory uniqueness is workspace/artifact scoped |
| Execution | `runs`, `run_files`, `activity_events` | claim lease lives on run and exclusivity lease on run file; no claim/lock/hook/task/run/edit/harness side tables |
| Collaboration | `signals`, `signal_recipients`, `deliveries` | one signal can have many recipients; broadcast audience is explicit and each reader gets independent read state; one delivery dedupe mechanism |
| Knowledge | `memories`, `memory_refs`, `memories_fts` | preserve all currently used retrieval, validity, failure, access/decay, embedding, scope, and reference behavior through cutover; `refinements` is removed |

`agents.agent_id` is stable. `sessions.session_id` is internal and generated; `host` and `host_session_id` describe adapter identity. A session is immutable to one agent/workspace/artifact.

`runs` owns lease and heartbeat, so a separate claims table is unnecessary. A partial unique index permits at most one ACTIVE run per session and one ACTIVE run per task. Kinds are `TASK|WORK`; sources are `EXPLICIT|SESSION`; states are `ACTIVE|SUCCESS|FAILED|ABANDONED`. Task persisted state is only `OPEN|BLOCKED|DONE|FAILED|CANCELLED`; `IN_PROGRESS` is a projection derived from the active run and VERIFY is removed.

`activity_events` is the append-only lifecycle/audit stream with indexed agent/session/plan/task/run/file columns and typed payload for edit metrics. It replaces `task_events`, `run_log`, `edit_log`, and `harness_log` without making any event a queue.

Reusable learning is stored in memory. Core v4 preserves the current memory fields and recall behavior losslessly while adding exact-fetch provenance only where it can be verified. It does **not** blanket-convert all legacy ACTIVE rows into hidden candidates and does not remove fields before a representative parity corpus passes. Synthetic/test rows and unresolved unreferenced rows are classified in the migration manifest; no row becomes more trusted during import. Candidate promotion, surprise ranking, learned navigation, and automated curation remain follow-on decisions. Live handoff and developer-review work is a typed signal. Operational history is an event. Removing `refinements` eliminates the current ambiguous fourth place for the same information only after each actionable row has an explicit disposition.

The public package exposes one Awareness service/dispatcher, its route contract, the Pi hook adapter, and stable public types. Direct table helpers and dozens of domain mutations stop being package-root exports. CLI and Pi call the same dispatcher.

### 7. Local Migration, Runtime, and Release

Because there are no external users, do not build a rolling v3/v4 compatibility system. The unshipped migration command quiesces/checkpoints the current store, takes a SQLite-consistent timestamped archive, creates a fresh v4 database from canonical DDL, copies only the approved durable allowlist, validates counts/foreign keys/integrity/recall parity, and atomically swaps the file.

The 2026-07-10 store does **not** have an empty queue: it has one ACTIVE plan, one IN_PROGRESS task, one ACTIVE TASK run, 34 OPEN signals, and 90 OPEN/ONGOING refinements. Cutover is therefore blocked. Immediately before swap, a just-in-time disposition ledger must prove that every nonterminal plan/task/run and every actionable signal/refinement was completed, cancelled/resolved, promoted to a new v4 Task/Signal/Memory, or consciously archived. Authored `.octocode/plan/**` documents remain as files; historical plan/task rows are summarized in the manifest unless the approved allowlist explicitly migrates them. Memory fields/references/FTS and representative recall results reconcile losslessly. Agents, sessions, volatile runs/files/claims/locks/delivery state, and logs are summarized but not imported. This resets reviewed runtime debt without pretending it was verified.

Old binaries fail on v4. The new binary reads `user_version` before DDL, accepts only v4 in normal operation, and never shape-migrates on connection. Legacy import is one explicit offline command, not an automatic startup path. Fresh initialization and v3 import are the only creation paths.

`doctor` reports database path/fingerprint, schema version, Node and SQLite versions, journal mode, hook capability/parity, stale or abandoned attempts, and package/build identity. It warns on SQLite WAL versions affected by the documented concurrent-write/checkpoint defect and points users to a safe runtime.

Retention is report-first. ACTIVE rows are never hard-deleted or marked successful. Unresolved signals cannot be age-pruned. Terminal-history deletion is disabled until an auditable rollup and measured retention policy are approved.

Repo projections write temporary files, fsync/rename each output, and publish the manifest last. Stale files from the previous manifest are removed. `share` mode has an explicit field allowlist rather than only different metadata.

The Pi package publishes one skill tree. Release verification installs the packed artifact in isolation and exercises `attend`, plan/task/work, hooks, schema help, and package resolution.

### 8. Core Memory Boundary

`attend` is a router, not a memory dump: it returns the smallest relevant abstraction, stable IDs, and exact-fetch actions back to authoritative evidence. `--smart` reports the relaxations it actually applied; explicit tags and labels remain hard filters. Before schema freeze, a representative golden set proves that cutover does not lose recall, FTS hits, failure clusters, validity filtering, embeddings, access/decay behavior, or references. Forget/retire operations must leave no FTS, projection, navigation, or delivery ghosts while preserving immutable operational evidence.

ACE supports structured itemized deltas and deterministic merging but also reports higher raw input-token use and sensitivity to unreliable feedback ([Agentic Context Engineering](https://arxiv.org/html/2510.04618)). NapMem supports provenance-linked drill-down but evaluates a learned policy on user-memory benchmarks, not coding coordination ([NapMem](https://arxiv.org/html/2607.05794v1)). HOLA's surprise result is a model-level KV-cache result with limited transfer evidence ([HOLA](https://arxiv.org/html/2607.02303v1)). Core v4 therefore ships exact navigation, preservation, and raw/uncached token guardrails only; learned routing, adaptive curation, and surprise ranking move to follow-on RFCs.

### 9. Follow-On Improvement Boundary

Core v4 may preserve immutable activity/outcome evidence and exact provenance for later analysis. An improvement laboratory—failure clusters → bounded candidate RFC/diff → held-in, held-out, and repository-health evaluation → human promotion—is explicitly not a core cutover phase. It requires a follow-on RFC with evaluators, permissions, migration safety, acceptance rules, and sensitive-path policy outside the editable loop.

Self-Rewarding LMs supplies the judge/length/reward-hacking warning; SPIN supplies the stable-reference/target-ceiling warning, not independent evidence of judge error ([Self-Rewarding Language Models](https://arxiv.org/abs/2401.10020), [SPIN](https://arxiv.org/abs/2401.01335)). Self-Harness provides primary evidence for verifier-grounded failure clusters, bounded edits, held-in/out non-regression, and logged rejection, but only on a fixed task suite ([Self-Harness](https://arxiv.org/html/2606.09498v1)). Weng is retained as a secondary synthesis for protected evaluator/permission boundaries ([Harness Engineering for Self-Improvement](https://lilianweng.github.io/posts/2026-07-04-harness/)). None is evidence that the core migration should automate self-improvement.

## Rationale and Alternatives

### Proposed: Core Operational-Trust v4, With Follow-On Memory Research

This option preserves the useful concepts while deleting v3's duplicated coordination storage, synthetic fallback, verification, and adapter paths. It is larger than isolated patches, but there are no external consumers to justify permanent compatibility complexity. The archive/import boundary makes the reset inspectable and recoverable. Memory behavior is preserved through this cutover; experimental ranking/navigation/self-improvement is not on the core critical path.

Before Phase 1, compare corrected v3 with amended v4 on the defects that still survive: per-edit HOOK debt, stale-work disagreement, host/session identity, duplicated lifecycle/dispatch paths, repo-profile cap truth, package integrity, and maintenance cost. Interim v3 fixes reduce urgency but do not by themselves remove these architectural causes.

### Alternative A: Do Nothing

The green test suite would remain, but accumulated HOOK debt, capped totals, and cross-agent next actions would keep making the primary view less reliable as usage grows. Rejected because current live data already demonstrates the failure mode.

### Alternative B: Narrow Correctness Patches

Patch exact counts, add a plan-status predicate, fix `--abandon`, and reject a few flags. This is cheaper and most changes are reversible, but lifecycle logic would remain duplicated across attend, workboard, hooks, and commands. Rejected as the target architecture; retained as the first implementation slices inside the shared design.

### Alternative C: Batch Durable HOOK Runs and Keep Verify

One fallback run per session/turn would reduce amplification, and a separate verify queue would preserve delayed receipts. It still stores work with invented reasoning, requires correlation state, and leaves two finish steps. Rejected for the no-user final design. Explicit Work plus evidence-bearing finish is smaller and more truthful.

### Alternative D: Add a New Façade or `plan_steps`

A generic start/finish façade could hide ceremony, and a new steps table could model plans again. Both create vocabulary and another source of truth while Plan/Task/Run already express the domain. Rejected.

### Alternative E: Replace Awareness with an External Task Tracker

Tools such as Beads demonstrate ready work, dependencies, atomic claiming, compact context, and durable agent memory. Replacing Awareness would lose its local file declarations, verification ledger, locks, sessions, hooks, and repo-specific learning—or require maintaining two ledgers. Rejected; use adjacent prior art for UX and concurrency tests.

### Alternative F: Strictly Block Every Undeclared Edit

This gives the strongest provenance but may add false blocks, retries, and incentives to bypass the harness. The chosen two-tier policy hard-blocks sensitive/self-modifying paths and permits one visible session-scoped Work for ordinary uncovered edits. A strict-versus-session-work experiment remains a release gate rather than an assumption.

### Revalidation Comparison

| Dimension | Corrected v3 | Core v4 | Core v4 + experimental memory program |
| --- | --- | --- | --- |
| Remaining correctness | keeps stale-work, HOOK, identity, and lifecycle duplication | removes them behind one service/transaction model | same core result |
| Migration risk | none | one local archive/cutover with explicit disposition | same cutover plus avoidable research risk |
| Reversibility | highest | reversible until meaningful v4 writes | lowest |
| Maintenance | 68 routes and overlapping stores/dispatchers | 37-route target and 16 relations | adds evaluators/promotion/ranking machinery |
| Knowledge safety | current behavior intact | must prove lossless parity before freeze | experimental behavior can change retrieval |
| Decision | viable hold option | **proposed** | reject as umbrella scope; split follow-on RFCs |

## Risks and Pre-Mortem

| Failure mode | Prevention | Rollback trigger |
| --- | --- | --- |
| Snapshot becomes a slow mega-query | exact counts and bounded rows are separate prepared queries under one read transaction; benchmark at 10k/100k rows | `attend` p95 exceeds the KPI budget |
| Edit enforcement interrupts or hides work | hard-gate sensitive paths; compare strict ordinary blocking with one session-scoped Work; expose every automatic declaration | false-block, bypass, unattributed-edit, or abandoned-work guardrail fails |
| Host cannot enforce pre-edit | `doctor` reports blocking capability; incapable/degraded host is cooperative-only and audits unattributed edits | a cooperative host is presented as enforced |
| Plan gating strands valid work | audit existing non-ACTIVE plans before enforcement; expose drain/release list | a running claim is silently cancelled or lost |
| Atomic finish encourages false success | require explicit SUCCESS/FAILED and message; never run/infer tests | success can be recorded without an explicit receipt |
| Local migration drops valuable history | preserve the byte-for-byte v3 archive plus a migration manifest and count reconciliation | durable-entity counts or FK/integrity checks disagree |
| Cutover silently discards active/actionable state | just-in-time plan/task/run/signal/refinement disposition ledger; zero unreviewed actionable rows | any active run or unreviewed actionable row exists at swap |
| Memory simplification causes a knowledge blackout | preserve current fields/semantics and require recall/FTS/reference parity before schema freeze | representative queries or counts regress, or imported rows disappear from defaults |
| Old binary opens v4 | v4 changes the canonical shape and new runtime rejects non-v4; archive is never used as the live path | any unsupported binary mutates or relabels the new store |
| The registry generates unreadable docs | generate mechanical help/schema only; keep concepts hand-authored | generated output becomes the source of conceptual policy |
| Retention destroys audit evidence | no hard deletion until rollup design and KPI are approved | any unresolved or unrolled-up record is selected for deletion |
| Generic activity ledger weakens edit queries | keep indexed typed columns for file/old-file/event type and benchmark doc-staleness queries | edit/query KPI cannot be met without JSON scans |
| Future self-improvement rewards its own mistakes | separate RFC; immutable evidence; held-out gates; evaluator/permissions outside loop; human promotion | follow-on proposal lacks protected gates |
| The umbrella RFC increases scope indefinitely | core phases only; learned navigation/ranking/improvement are follow-on RFCs | a core phase adds experimental memory or harness optimization |

## Reversibility

Before v4 receives meaningful writes, rollback is an atomic restoration of the archived v3 file and old code. After new v4 writes, do not downgrade in place: fix forward or export v4 durable entities and consciously restore/import. Snapshot, next-action, command-contract, skill, compact-output, and package-layout behavior remains code-reversible.

## Consolidation and Supersession

| Existing RFC | Treatment |
| --- | --- |
| `awareness-audit-hardening` | implemented findings remain historical evidence; unresolved identity, audit, and bloat operations move here |
| `awareness-cli-skill-consolidation` | source/build/install parity requirements move here |
| `awareness-task-persistence` | superseded; do not add `plan_steps`; its portability and verification intent is served by current Plans/Tasks/Runs |
| `awareness-repo-context` | keep implemented query/inject design; compact-output and snapshot corrections move here |
| `homeostatic-awareness-loop` | retain its attend/maintenance framing; operational execution and budgets are governed here |
| `awareness-reflection-scorecards` | remains a follow-on RFC after core v4 and its lossless-memory gate |
| `hola-protected-memory` | remains a follow-on RFC after core v4; surprise ranking is not a cutover requirement |

The older documents should receive a short status note linking to this RFC when implementation starts; their research history is not deleted.

## Unresolved Questions and Deferrals

### Must close before P0 / RFC acceptance

1. **Normative contract fixtures:** implement and approve R-A1–R-A6 with failing-then-passing tests, then record the schema fingerprint, snapshot fixture/hash, and exact route/deletion manifest in this RFC. Owner: package owner. R-A7 policy is closed; only its runtime evidence remains partial.

### Explicitly deferred after RFC acceptance

1. **Ordinary hook default — release gate:** strict blocking or one visible session-scoped Work? Deferred because both satisfy the accepted enforcement boundary when healthy hosts expose attribution. Owner: package owner. Default-safe behavior before selection: strict on sensitive paths and whenever stable goal/session identity is absent. Trigger: the KPI's sample size and numeric false-block, bypass, unattributed-edit, abandonment, token, and task-quality thresholds pass.
2. **Pi dependency resolution — P4:** publish/pin, bundle, or deliberately delegate Awareness and tools-core. Deferred because it changes packaging, not the coordination model. Owner: Pi/package maintainer. Trigger: `check:no-workspace` and clean tarball install pass.
3. **Cutover disposition — P5/P6b:** the current ACTIVE plan/task/run and actionable signals/refinements must reach an explicit disposition, and implemented memory parity must pass. Deferred because the live queue changes during implementation. Owner: plan lead. Trigger: the just-in-time audit has zero unreviewed actionable rows/live mutators and the P6b manifest passes.

## Acceptance and Success Signal

The proposal is accepted only after the P0-blocking contract fixtures above are recorded and the named package owner approves the goals, R-A1–R-A7, amended 16-relation schema fingerprint, snapshot fixture/hash, local disposition/reset/import policy, and breaking CLI/API deletion-map revision. P4, P5/P6b, and ordinary-policy selection remain explicit ship/cutover gates; acceptance does not waive them.

The primary success signal is simple: for the same workspace and agent, `attend`, workboard, `doctor`, plan/task/work commands, hooks, and direct SQL agree on what is active, ready, overlapping, stale, and finished—while no edit lacks an attributable Task/Work attempt and a normal agent completes its Awareness lifecycle in three commands or fewer.
