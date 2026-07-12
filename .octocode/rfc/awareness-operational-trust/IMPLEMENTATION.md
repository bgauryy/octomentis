# Implementation Plan: Octocode Awareness Operational Trust

Authority: [RFC goals and non-goals](./RFC.md#goals-and-non-goals)

Normative contract: [RFC Decision Contract — Amendment 1 Draft](./RFC.md#decision-contract--amendment-1-draft)

Prerequisites: [PREREQUISITES.md](./PREREQUISITES.md)

Verification contract: [KPI.md](./KPI.md)

Current checkpoint: **Phase 0 partial.** Schema identity/fingerprint/bootstrap and runtime-safety classification are implemented TDD-first in isolation. File-backed concurrent initialization, transition/service invariants, snapshot envelopes, final route/response fixtures, import/cutover, hooks, and production wiring are not implemented. The provisional DDL must be amended before it is called final.

The phases are dependency-ordered and TDD-first. There are no external users, so this plan chooses one final schema/API, performs one local create-copy-swap cutover, and deletes compatibility code rather than maintaining it.

## Resolved and Gated Decisions

### Q1 — What is the durable work model?

**Resolved:** Plan → Task → Run → RunFile. A task belongs to one plan and carries reasoning, acceptance criteria, paths, and dependencies. A run is one TASK or standalone WORK attempt. There is no `plan_steps`, “today” queue, or durable HOOK attempt.

### Q2 — Must every edit be locked?

**Resolved:** no. Every edit must belong to one active Task/Work run; ordinary work may be explicit or session-scoped from a stable current goal. Run-file presence is advisory by default. `--exclusive` adds an expiring exclusivity lease only for sensitive work. Two advisory attempts may overlap and both stay visible.

### Q3 — What happens when an agent edits without active work?

**Gated:** sensitive/self-modifying paths always block before mutation on a healthy blocking-capable host unless an explicit exclusive Task/Work is active. For ordinary paths, compare strict blocking with one visible session-scoped Work from a stable goal; otherwise block with the exact compact `work start` command. Incapable/degraded hosts are cooperative-only and expose unattributed-edit diagnostics. No per-edit HOOK run exists. The ordinary default remains unresolved until the KPI experiment passes.

### Q4 — How does work finish?

**Resolved:** `task finish` and `work finish` require `--result SUCCESS|FAILED`, `--evidence`, and `--evidence-kind`. They atomically terminalize the run, close file presence/exclusivity, append the event, and update the task. Evidence kind is `AUTOMATED|INDEPENDENT|USER|SELF_REPORT`; it affects learning trust, not whether the receipt is stored. No PENDING/VERIFY queue exists. Expiry/crash becomes ABANDONED. Independent review is a dependent review task.

### Q5 — What does plan status control?

**Resolved:** plans are ACTIVE by default. Only ACTIVE plans expose/claim tasks. PAUSED blocks new claims. COMPLETED requires every child DONE or CANCELLED and no active run. CANCELLED requires no active run and transactionally cancels remaining nonterminal tasks. Only the lead changes plan status.

### Q6 — How are claims and locks represented?

**Resolved:** the ACTIVE TASK run is the claim; lease/heartbeat live on `runs`. Advisory presence and optional `exclusive_expires_at` live on `run_files`. Separate `task_claims` and `locks` tables and public lock commands are deleted.

### Q7 — How are participants represented?

**Resolved:** the plan stores its lead. Other participation is derived from task authors/runs/doc authors/signals/activity. `plan_members` and manual `plan join` are deleted.

### Q8 — Where do handoffs, refinements, and learning go?

**Resolved for core v4:** actionable planned work is a task; a live handoff/question/blocker/developer-review item is a signal; operational history is an activity event. Current memory fields, references, FTS, and recall behavior are preserved losslessly. The catch-all `refinements` entity is deleted only after an explicit disposition ledger. Candidate promotion, surprise ranking, learned navigation, and harness optimization move to follow-on RFCs.

### Q9 — How is command drift removed?

**Resolved:** one typed route manifest owns flags, validation, handler, help, schemas, compact response, exit semantics, and examples. CLI and Pi call one application dispatcher. Flat aliases, Notification vocabulary, pre-flight names, `--compat-coerce`, and removed-command shims are deleted.

### Q10 — How is v3 migrated?

**Resolved:** v3 is not a supported runtime format. A one-time local, unshipped create-copy-swap tool archives v3 and imports the reviewed durable allowlist into fresh v4. It refuses cutover while live mutators or unreviewed actionable rows exist. Normal runtime accepts empty or exact-v4 stores only; all other non-empty versions hard-error before DDL or writes.

### Q11 — What can pruning delete?

**Resolved:** `prune` is dry-run by default. It never deletes ACTIVE runs or unresolved signals and never turns unfinished work into success. Terminal event retention remains disabled until a measured rollup policy is separately approved.

### Q12 — Does `--smart` relax explicit tags/labels?

**Resolved:** no. They remain hard filters. Recall returns the mode and exact relaxation applied.

### Q13 — Is remote collaboration included?

**Resolved:** no. This is same-store, same-machine coordination. `doctor` reports the store fingerprint/boundary. Remote synchronization requires another RFC.

## Amended v4 Schema Contract (Pending Fingerprint Freeze)

Use SQLite `application_id=0x4f435434` (`OCT4`) and `PRAGMA user_version=4`. The exact normalized DDL and schema fingerprint become frozen test fixtures only after the Amendment 1 schema corrections and P6a representability proof. The inventory remains 16 named logical relations: 15 regular tables and one FTS5 virtual table. Indexes and SQLite-owned FTS shadow tables are implementation artifacts and are not counted as contract relations.

### Identity

`agents`

- `agent_id` primary key; stable across sessions.
- `agent_name`, `registered_at`, `last_seen_at`.
- Mutating commands require `--agent-id` or `OCTOCODE_AGENT_ID` and auto-upsert; no public register command.

`sessions`

- generated internal `session_id` primary key;
- `host`, nullable external `host_session_id`, `agent_id` FK;
- canonical `workspace_path`, nullable `artifact`, nullable `goal` and `goal_source`;
- `started_at`, `heartbeat_at`, nullable `ended_at`, nullable `summary`;
- partial unique active identity `(host, host_session_id, workspace_path, ifnull(artifact,'')) WHERE host_session_id IS NOT NULL AND ended_at IS NULL`;
- an existing session can never change agent or scope.

Public commands do not accept raw session IDs; adapters resolve them once. Resuming an ended external host conversation creates a new internal session instance rather than reopening history.

### Planning

`plans`

- `plan_id` primary key, `name`, `objective`, `lead_agent_id` FK;
- `status` CHECK `ACTIVE|PAUSED|COMPLETED|CANCELLED`;
- workspace/artifact, timestamps; `doc_dir` is unique within `(workspace_path, artifact)` rather than globally.

Plan creation writes `.octocode/plan/<millisecond-timestamp>-<slug>/PLAN.md` and `docs/`. The primary doc is implicit; no manifest file or PRIMARY row is needed.

`plan_docs`

- `(plan_id, relative_path)` primary key;
- title, author agent FK, ordinal;
- supporting docs only, constrained beneath the plan's `docs/` directory.

`tasks`

- `task_id` primary key, `plan_id` FK, title, reasoning, acceptance criteria;
- persisted status CHECK `OPEN|BLOCKED|DONE|FAILED|CANCELLED`;
- priority, creator FK, timestamps, nullable completion time.

IN_PROGRESS is a projection of an ACTIVE run. VERIFY is deleted.

`task_paths`

- `(task_id, path)` primary key plus ordinal;
- at least one canonical workspace-relative path per task.

`task_dependencies`

- `(task_id, depends_on_task_id)` primary key;
- same-plan and acyclic invariants enforced transactionally.

Ready means: plan ACTIVE, task OPEN, every dependency DONE, and no ACTIVE run.

### Execution, presence, and exclusivity

`runs`

- `run_id` primary key; nullable task FK;
- kind CHECK `TASK|WORK` with `TASK` iff task ID is non-null;
- source CHECK `EXPLICIT|SESSION`; SESSION is permitted only for WORK with a stable session goal;
- agent/session FKs, rationale, test plan, optional context ref;
- state CHECK `ACTIVE|SUCCESS|FAILED|ABANDONED`;
- heartbeat/lease expiry, workspace/artifact, result evidence, evidence kind, timestamps;
- partial unique index: one ACTIVE run per session;
- partial unique index: one ACTIVE run per task;
- ABANDONED requires `completed_at` and null result evidence/evidence kind;
- service transitions require run agent/workspace/artifact to equal the resolved session and task/plan scope.

`run_files`

- `(run_id, file_path)` primary key;
- source CHECK `DECLARED|OBSERVED`, optional reason override;
- presence started/heartbeat/expiry/ended timestamps;
- nullable `exclusive_expires_at` on the same row.

Acquiring exclusivity is a transaction that fails if another active presence or exclusivity exists on the canonical file. Advisory attachment only fails when another active exclusivity exists. Terminalizing/releasing a run clears presence and exclusivity in the same transaction.

`activity_events`

- event ID and type, workspace/artifact, agent/session;
- nullable plan/task/run/file/old-file typed columns;
- message, JSON payload, created time;
- optional host event ID unique per session for post-edit dedupe;
- indexes for event type, scope, task, run, file, and time.

Lifecycle, edit, reflection, migration-summary, and diagnostic events share this append-only ledger. Common edit fields stay typed/indexed; line counts, content hash, and host metadata live in validated payload. Events never become backlog state.

### Collaboration

`signals`

- signal ID, scope, sender FK, explicit audience `DIRECT|BROADCAST`, kind, subject/body, file/ref JSON;
- thread/reply FK, importance 1–10, status `OPEN|RESOLVED`, timestamps;
- kinds are a checked final vocabulary: `HANDOFF|QUESTION|BLOCKER|REQUEST|DECISION|FYI|REVIEW`.

`signal_recipients`

- `(signal_id, agent_id)` primary key, nullable `read_at`;
- direct signals require one or more recipients; broadcast visibility is defined by the signal audience and each reader receives an independent recipient/read row without changing the audience.

`deliveries`

- `(consumer_id, channel, scope_key)` primary key, fingerprint and delivered time;
- one mechanism for prompt/peer/projection dedupe; no adapter filesystem/in-memory peer state.

### Knowledge

`memories`, `memory_refs`, `memories_fts`

- preserve every v3 field currently used by retrieval, scope, validity, failure clustering, novelty, access/decay, embeddings, and bookkeeping until a separate memory RFC proves a replacement;
- preserve stable IDs, current state semantics, reference strings/kinds, and default visibility during the coordination cutover;
- exact-fetch provenance may be added only when resolvable; import cannot infer trust merely from a reference string;
- rebuild FTS from imported/live rows and prove query parity; never copy FTS shadow tables;
- classify explicit synthetic/test rows and unresolved unreferenced rows in the migration manifest instead of silently promoting or hiding them;
- no `refinements` or `harness_log`; deletion requires the disposition ledger and no-ghost tests.

## Proposed Final Public CLI

The final documented surface is 37 routes, down from 68. Hidden adapter dispatch is not a user route.

### Core collaboration

```text
attend

plan create
plan list [--plan-id]
plan doc
plan status

task create
task list [--task-id] [--ready]
task claim [--exclusive]
task heartbeat
task finish --result SUCCESS|FAILED --evidence <text> --evidence-kind <kind>
task release [--blocked-reason]
task reopen
task depend

work start [--exclusive]
work heartbeat
work finish --result SUCCESS|FAILED --evidence <text> --evidence-kind <kind>
work list [--file]

signal send
signal list
signal reply
signal close
```

### Knowledge and operations

```text
memory recall
memory record
memory forget
reflect

query <view>
project
prune                 # dry-run unless --apply
doctor

hooks install
hooks check
hooks remove

docs list
docs show

schema commands
schema show
schema validate
```

`plan list --plan-id`, `task list --task-id`, and `work list --file` replace separate show verbs. `task list --ready` replaces `task ready`. `doctor` replaces status/audit/diagnose commands. `project` replaces repo inject/view writing. `prune --kind ...` replaces fragmented maintenance cleanup.

## Deletion and Simplification Map

### Database/runtime

Delete from the live schema: `plan_members`, `task_claims`, `locks`, `task_events`, `run_log`, `edit_log`, `harness_log`, `refinements`, `signal_reads`, and all dead legacy tables. Rename `task_runs` to `runs`, `agents` remains the stable identity table, and replace `delivery_state` with `deliveries`.

Delete automatic migration/repair code in `src/db.ts`: legacy task-run moves, generic column addition, canonical-table introspection/rebuild, v3 execution conversion, CHECK repair, refinement constraint migration, and the nested-transaction bypass. Normal open becomes: pragmas → application/version read → fresh create or exact-v4 fast path → otherwise hard error.

Add shared `withImmediateTransaction` and `withReadSnapshot` helpers with savepoints for nesting. Replace handwritten transaction fragments.

### Domain/application

- Delete `src/intents.ts`; exclusivity is part of Task/Work start/finish.
- Delete `src/verify.ts`; evidence-bearing finish and `doctor` own terminal/stale behavior.
- Delete `src/refinements.ts` and `src/sql/refinements.ts`.
- Replace audit/task/run/harness insert functions with `appendActivityEvent`.
- Rename `notifications.ts` and Notification types to signal-only vocabulary.
- Make agent upsert and session lifecycle internal.
- Split the 2,130-line `repo-context.ts` into snapshot queries, renderers, and atomic projection writing.
- Split `maintenance.ts` into `doctor` and `prune`; move session lifecycle to its own service.
- Replace the 743-line `tool-operations.ts` switch and the CLI switch with one application dispatcher generated from the route manifest.
- Narrow package-root exports to the Awareness service/dispatcher, route contract, Pi bridge, and stable public types; internal DB/domain helpers stop being public promises.
- Move domain types beside their modules and generate command input/output types; delete the giant catch-all type barrel when consumers migrate.

### CLI/flags

Delete public routes for lock, verify, refinement, agent registration/list, session capture, maintenance init/self-test/digest, docs staleness, workspace status, and public hook dispatch. Delete all flat internal/legacy command names and replacement hints.

Delete compatibility or duplicate flags: `--compat-coerce`, `--created-by`, `--target-file`, `--out-dir`, plural `--tags`, `--view`, `--strict-agent-id`, `--ttl-seconds`, public `--session-id`, `--file-tree-fingerprint`, task `--name`, lock release status/verified flags, and internal `--action`. Use one canonical spelling and minutes-based lease duration.

### Generated/package surfaces

- Canonical authored skill/docs stay under `packages/octocode-awareness/skills/octocode-awareness`.
- Compiled `awareness.mjs`, `schema.mjs`, hook runner, and extractor are emitted only into build/install destinations, not written back into the authored source tree.
- Pi consumes the Awareness built skill once; remove its second root `skills/**` package tree and publish one `dist/skills` tree.
- Replace package verification that copies local `dist` with a real `.tgz` extract/install test.
- Resolve Pi's tools-core runtime import by bundling, publishing, or deliberate delegation before release.

### Tests

Delete tests whose only purpose is old schema/alias/refinement/notification/per-edit-HOOK/lock-verification behavior. Replace them—not merely remove coverage—with final-schema fingerprint, wrong-version refusal, fresh concurrent init, local cutover, final route contract, lifecycle invariants, explicit-hook enforcement, signal recipients, activity event, and real-tarball journeys.

## Phase 0 — Amend and Freeze Schema/Contract with Failing Tests

Dependencies: RFC Amendment 1 approval, closed R-A7 journal policy, and memory-representability prerequisite P6a.

1. [x] Check in a provisional 16-relation DDL, application/version identity, fingerprint check, and wrong-version refusal — `src/v4/schema.ts`, `tests/v4-schema.test.ts`.
2. [x] Implement R-A7 SQLite WAL safety classification and rollback-journal fallback — `src/v4/runtime.ts`, `tests/v4-runtime.test.ts`.
3. [ ] Amend DDL/tests for R-A1 session resume, R-A2 scoped plan directories, R-A3 ABANDONED/scope truth, R-A4 broadcast read state, and R-A5 lossless memory fields.
4. [ ] Add file-backed multi-connection fresh initialization; current tests are in-memory and do not prove concurrency.
5. [ ] Freeze transition tables, the 37-route inventory/deletion revision, and compact response fixtures.
6. [ ] Write failing service tests for session/task/plan scope equality, one active run, task readiness, advisory overlap, exclusivity, atomic finish, and unsupported no-work edit.
7. [ ] Define and freeze the R-A6 snapshot lane envelope, null-artifact equality semantics, and response fixture/hash.
8. [ ] Create large/stale/migration-memory fixtures without touching the user database.

Exit: every item above has a test/evidence path, the amended fingerprint is approved in the RFC decision record, and tests describe the final model and fail against v3 for the intended reasons.

## Phase 1 — Build Fresh v4 Storage and One Application Service

Dependencies: Phase 0 and P6a.

1. Implement fresh/exact-v4 connection and shared transactions; delete runtime legacy migration.
2. Implement repositories for the 16-relation schema and one `AwarenessService` command dispatcher.
3. Implement Task/Work transitions and activity events before adapters.
4. Migrate CLI and Pi to the service; stop direct orchestration and broad root exports.
5. Generate validation/help/schema/examples/dispatch from the route manifest.

Tests first at every transition. The old local database is not opened by the new runtime during this phase.

## Phase 2 — Perform the One-Time Local Cutover

Dependencies: Phase 1 and prerequisites P1/P3/P5/P6b.

1. Disable hooks/Pi, acquire a migration marker/lock, require no live mutators, checkpoint WAL.
2. Create a consistent timestamped v3 archive with SQLite backup/VACUUM INTO semantics; never copy only the main file while WAL may contain data.
3. Generate the just-in-time disposition ledger. Abort unless every nonterminal plan/task/run and actionable signal/refinement has an owned disposition and no mutator is live.
4. Create same-directory v4 temp DB from final DDL.
5. Import the P6a-approved memory shape losslessly: stable IDs, all used fields, references, embeddings, and current visibility semantics; rebuild FTS. Explicit synthetic/test rows and omitted rows remain in the archive/manifest with reasons. Preserve authored plan directories as files, then close P6b with the implemented parity suite.
6. Import only the approved planning/actionable allowlist from the disposition ledger. If any current ACTIVE plan/task/run remains, abort—never assume the queue is empty and never use plan Markdown as a substitute for task state.
7. Do not import volatile agents/sessions/runs/files/claims/locks/logs/delivery state. Import or archive each signal/refinement exactly as its disposition row requires.
8. Run FK/integrity/schema fingerprint, memory field/count/reference/FTS/embedding/recall parity, disposition reconciliation, and runtime-state assertions.
9. Atomically move old canonical DB to immutable archive and temp v4 to canonical; clear hook/peer/digest state and regenerate projections.
10. Dogfood; retain file-swap rollback until acceptance, then delete the unshipped importer from the release branch.

Failure at any point leaves the old canonical path unchanged. After meaningful v4 writes, fix forward; never reopen v4 with v3 code.

## Phase 3 — Build the Exact Workspace Snapshot

Dependencies: Phase 1.

1. Implement one read-snapshot service for exact totals, bounded rows, derived task phase, stale attempts, signals, plans, overlaps/exclusivity, and structured `next_action`.
2. Return one `LaneEnvelope` per bounded lane, including empty lanes, with fields `rows`, `total_count`, `returned_count`, `omitted_count`, and `exact`. Never repeat count metadata on each row. Artifact-null equality is explicit in every count/row query.
3. Feed `attend`, workboard/query, `doctor`, and projection generation from it.
4. Make compact `project` summary-only and projection writes temp+fsync+rename with manifest last and stale-file cleanup.
5. Apply an explicit field allowlist to share-mode projections.

Tests: 550/10k/100k counts across attend/workboard/repo-profile/projections/direct SQL, actor scoping, null-artifact scope, plan-only/empty state, stale ABANDONED visibility, payload/performance budgets, atomic projection crash tests.

## Phase 4 — Enforce Hooks, Collaboration, and Lifecycle

Dependencies: Phases 1 and 3.

1. Resolve stable agent + internal session once per adapter; never use a host session as agent ID.
2. Pre-edit requires explicit exclusive work for sensitive/self-modifying paths on healthy blocking-capable hosts. For ordinary uncovered edits, compare strict blocking with one `WORK/SESSION` created from the stable session goal; both policies attach/heartbeat the file and expose the declaration. Incapable/degraded hosts remain cooperative-only and emit visible unattributed-edit diagnostics.
3. Post-edit appends a deduplicated EDIT activity event. Stop warns; shutdown abandons unfinished work and ends the session.
4. Enforce plan/task transition tables, dependency readiness, lead authorization, reopen, and one active run constraints.
5. Implement one multi-recipient signal transaction, explicit direct/broadcast audience, independent per-agent broadcast reads, and one deliveries API.
6. Make `doctor` report capability gaps, stale/abandoned work, store/runtime identity, and invariant violations.

Tests: two agents advisory same file; exclusivity races; sensitive undeclared refusal; cooperative-host diagnosis; ordinary strict/session policies; missing/unstable goal refusal; new file attachment; session collision and resume-after-end; Pi/shell parity; crash/expiry ABANDONED with null result evidence; direct/broadcast fan-out and independent read/close; no filesystem correlation state.

## Phase 5 — Simplify Skill, Docs, and Agent Flow

Dependencies: final routes and hooks.

1. Put the two three-command flows and optional exclusivity first in the canonical skill.
2. Generated `.octocode/AGENTS.md` and the always-available 49-line skill entry remain short lobbies; focused references load for active edits/collaboration, not every read-only question.
3. Document planned Task, standalone Work, visible session-scoped ordinary Work, and blocked sensitive edit; remove per-edit fallback and verify/lock/refinement vocabulary.
4. Document `.octocode/plan/<timestamp>-<slug>/PLAN.md` plus supporting `docs/`, with live tasks only in SQLite.
5. Use one install matrix and implicit fresh DB creation; remove placeholders.
6. Correct smart-recall docs and return applied mode/relaxations.
7. Rebuild generated mirrors and verify canonical parity.

Tests: instruction budgets, fresh-agent journeys ≤3 commands, every README command against packed artifact, no stale command names or placeholders.

## Phase 6 — Prune, Package, and Release

Dependencies: Phases 1–5 and Pi dependency gate.

1. Implement `prune` dry-run default over eligible signals/memory/events/deliveries; no hard terminal-event deletion in the first release.
2. Remove generated/package duplication and enforce one skill tree.
3. Install real Awareness and Pi tarballs in empty directories without ancestor `node_modules`; make declaration emit fatal, assert the declared types target, and compile a clean TypeScript consumer.
4. Exercise `attend`, plan/task/work, both ordinary hook policies, sensitive hard gates, signals, memory, project, doctor, docs, and schemas from tarballs.
5. Run the supported Node/SQLite matrix and unsafe-WAL diagnosis.
6. Update release guide and all package docs from the route manifest and schema contract.

## Follow-On RFC Gates — Not Core Phases

After the stable v4 cutover, separate RFCs may propose candidate-memory promotion, surprise ranking, learned navigation, adaptive context curation, or a human-gated improvement laboratory. Each must start from measured baselines, preserve negative evidence, protect evaluators/permissions, and have independent rollout/rollback. None blocks core operational trust, and none may modify the core schema or migration allowlist implicitly.

## Cross-Phase TDD and Verification Order

For every phase:

1. write the smallest failing contract/invariant test;
2. implement through the one service/repository boundary;
3. run focused tests;
4. run package test and typecheck;
5. build canonical skill and prove generated parity;
6. run real-tarball tests for public/package changes;
7. run lint and repository verify at release gate;
8. attach measurements and update [KPI traceability](./KPI.md#traceability-matrix).

No phase is complete because code exists; its acceptance rows require evidence.

## Documentation and Release Checklist

- Update `packages/octocode-awareness/README.md` and all affected `packages/octocode-awareness/docs/`.
- Update canonical skill references and rebuild, never patch generated mirrors.
- Regenerate CLI/schema facts from the route manifest.
- Remove every deleted command/flag/entity from root docs, Pi tools/prompts, examples, architecture, DB docs, and release guide.
- Mark earlier operational RFCs superseded by this folder.
- Verify plan docs do not duplicate live task state.
- Verify all public examples against the packed artifact.
- Record cutover archive path, manifest, integrity/count results, and rollback decision without committing private DB contents.
