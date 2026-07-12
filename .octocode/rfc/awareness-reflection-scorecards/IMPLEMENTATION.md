# Implementation: Awareness Reflection Scorecards and Wiki-Memory Review Queue

> Decision: see `RFC.md` sections "Summary" and "Rationale and Alternatives". This file does not restate goals or scope.

## Resolved Questions

| Open question (RFC section) | Resolution | Evidence | Confidence |
|---|---|---|---|
| Should v1 use a new `reflection_scorecards` table or store scorecards only in `harness_log.payload_json`? | Use a new additive table and optionally mirror lifecycle events into `harness_log`. Scorecards must be queryable by score, route, status, and scope; `harness_log` is an audit stream. | `harness_log` stores event payload JSON and event types (`packages/octocode-awareness/docs/HARNESS.md:429-454`); memories have no scorecard fields today (`packages/octocode-awareness/docs/HARNESS.md:214-245`). | confirmed |
| Which route/rung enum is narrow enough for v1? | Use `memory`, `repo_context`, `skill_context`, `workflow`, `harness_code`, and `evaluator`. This maps local Awareness concepts to the external "fix at the lowest rung" guidance without naming broad research systems in the DB. | Local flows already distinguish memory, repo context, skills, workflow/harness logs, and verification (`packages/octocode-awareness/README.md:16-30`; `packages/octocode-awareness/docs/HARNESS.md:13-20`). External guidance says fix failures at the lowest expressive rung (self-improvement-loops raw skill lines 6-7). | likely |
| Should `repo inject` add `.octocode/REFLECTIONS.md` or only sections in `.octocode/LEARN.md`? | Add `.octocode/REFLECTIONS.md` plus `.octocode/references/wiki-health.md`, and add only a concise pointer in `.octocode/AGENTS.md`. Keep `.octocode/LEARN.md` focused on accepted lessons/opportunities. | Existing `repo inject` already writes multiple top-level generated docs and reference notes (`packages/octocode-awareness/src/repo-context.ts:878-910`); generated docs already say to regenerate instead of hand-editing (`packages/octocode-awareness/src/repo-context.ts:1018-1023`). | likely |
| Should scorecard acceptance ever apply a harness or skill edit? | No. `accepted` only affects projection/export ranking. File edits still use normal implementation, locks, tests, and human approval. | Current tool operation text already reports harness improvement as "a human merges" (`packages/octocode-awareness/src/tool-operations.ts:307-315`). External guidance reserves evaluator changes, surface expansion, and production promotion for humans (self-improvement-loops raw skill lines 24-28). | confirmed |
| Should `mineWeakness()` fix the below-threshold surface-merge gap before `wiki-health` relies on cluster counts? | Yes for `wiki-health` correctness. Either fix `mineWeakness()` to merge base signatures before applying `minCount`, or have `wiki-health` compute its own base-signature counts. Prefer fixing `mineWeakness()` with tests. | The known gap is documented in tests (`packages/octocode-awareness/tests/mine-weakness.test.ts:75-84`); the implementation currently applies `HAVING freq >= ?` before surface merge (`packages/octocode-awareness/src/memory.ts:1016-1029`). | confirmed |
| What evaluator and held-out split would be required for future autonomous harness evolution? | Deferred. This RFC intentionally stops before autonomous self-modification. Revisit only after scorecards, candidate archives, and deterministic evaluators exist. | External guidance requires hidden held-out splits, evaluator isolation, raw candidate archives, and human decision points (self-improvement-loops raw skill lines 9-31). | n/a |

## Approach

Implement the recommendation from `RFC.md` "Why This Design": an additive scorecard table, optional scorecard capture in `reflect`, queryable review views, and repo-context projections. Keep generated files non-canonical and keep code edits outside scorecard acceptance.

## Steps

### Phase 1: Data Contract and Schema

- [ ] Add `ReflectionScorecardRoute`, `ReflectionReviewStatus`, `ReflectionScorecardInput`, and `ReflectionScorecardRecord` to `packages/octocode-awareness/src/types.ts`.
- [ ] Add a `reflection_scorecards` table and indexes in `packages/octocode-awareness/src/db.ts`; migrate old stores without touching existing memory columns.
- [ ] Add SQL constants in `packages/octocode-awareness/src/sql/scorecards.ts` or the existing SQL module pattern.
- [ ] Add `src/scorecards.ts` with deterministic validation and scoring helpers.
- [ ] Add schema entries in `packages/octocode-awareness/scripts/schema.mjs` for `reflection_scorecard` and any new query fields.
- [ ] Add legacy migration tests modeled after existing migration coverage.

### Phase 2: Reflection Capture and Review Commands

- [ ] Extend `reflect()` to accept an optional scorecard input and return optional scorecard metadata without changing old callers (`packages/octocode-awareness/src/reflect.ts:33-221`).
- [ ] Extend `bin/awareness.ts` to parse `--scorecard-json` for `reflect record`, mirroring the existing `--eval-failure-json` parse pattern (`packages/octocode-awareness/bin/awareness.ts:440-475`).
- [ ] Add `reflect scorecard --memory-id ... --scorecard-json ...` for post-hoc review.
- [ ] Add shared operation support in `src/tool-operations.ts` so host integrations can create/update scorecards without shelling out.
- [ ] Insert a `harness_log` event for scorecard create/update only as audit metadata, not as the query source of truth.

### Phase 3: Query Views

- [ ] Add `reflection-review`, `harness-candidates`, and `wiki-health` to `AWARENESS_QUERY_VIEWS` (`packages/octocode-awareness/src/repo-context.ts:15-32`).
- [ ] Implement row builders in `src/repo-context.ts` or a split `src/views.ts` if the file grows too large.
- [ ] Fix `mineWeakness()` surface-merge ordering or make `wiki-health` compute base-signature totals directly before using weakness counts.
- [ ] Add table, JSON, CSV, markdown, and HTML coverage for the new views.

### Phase 4: Repo Context Projections

- [ ] Add `.octocode/REFLECTIONS.md` generation in `injectRepoContext()` next to the existing `MEMORY.md`, `GOTCHAS.md`, and `LEARN.md` writes (`packages/octocode-awareness/src/repo-context.ts:878-881`).
- [ ] Add `reflection_scorecards.csv` under `.octocode/awareness/csv/`.
- [ ] Add `.octocode/references/wiki-health.md` with generated warnings and live-query commands.
- [ ] Add a compact "Reflection Review" pointer to generated `.octocode/AGENTS.md`, keeping it concise (`packages/octocode-awareness/src/repo-context.ts:970-1015`).
- [ ] Preserve generated-file banners and source-of-truth language (`packages/octocode-awareness/src/repo-context.ts:1018-1023`).

### Phase 5: Scorecard-Aware Harness Export

- [ ] Add optional scorecard-aware ordering/filtering to `exportHarness()` without changing the default output shape (`packages/octocode-awareness/src/maintenance.ts:916-1009`).
- [ ] Prefer accepted or high-scoring harness candidates; include pending candidates only in review views unless explicitly requested.
- [ ] Ensure rejected scorecards remain accessible as negative evidence but are not exported as standing guidance.

### Phase 6: Docs, Skill Wiring, and Mirrors

- [ ] Update `packages/octocode-awareness/README.md` command examples and command group list if a new `reflect scorecard` command is added.
- [ ] Update `packages/octocode-awareness/docs/HARNESS.md` with scorecard table, review statuses, and score dimensions.
- [ ] Update `packages/octocode-awareness/skills/octocode-awareness/references/memory-recall.md` or add a focused reference only if scorecard usage needs more than a few lines.
- [ ] Update `repo-context-management.md` to mention `.octocode/REFLECTIONS.md` and `wiki-health`.
- [ ] Run `yarn workspace @octocodeai/octocode-awareness build` so package-owned skill sources and generated copies stay aligned.

## Files / APIs / Contracts Touched

- `packages/octocode-awareness/src/types.ts` - add scorecard route/status/input/output types.
- `packages/octocode-awareness/src/db.ts` - add table, migration, indexes.
- `packages/octocode-awareness/src/scorecards.ts` - new deterministic scorecard operations.
- `packages/octocode-awareness/src/reflect.ts` - optional scorecard capture and result metadata.
- `packages/octocode-awareness/src/memory.ts` - fix surface-merge ordering if using `mineWeakness()` for `wiki-health`.
- `packages/octocode-awareness/src/repo-context.ts` - new query views and generated projection files.
- `packages/octocode-awareness/src/maintenance.ts` - optional scorecard-aware harness export.
- `packages/octocode-awareness/bin/awareness.ts` - `reflect scorecard`, `--scorecard-json`, help, and dispatch.
- `packages/octocode-awareness/scripts/schema.mjs` - schemas and examples.
- `packages/octocode-awareness/src/tool-operations.ts` - host operation support.
- `packages/octocode-awareness/tests/*.ts` - unit, CLI, migration, repo inject, query, and export tests.
- `packages/octocode-awareness/skills/octocode-awareness/*` - docs/reference updates.

## Risk Mitigations

- **Score inflation:** validation rejects top evidence/verification scores without evidence refs.
- **Process bloat:** scorecards are optional; low-score reflections still store as memories but are not promoted as guidance.
- **Projection staleness:** generated files include timestamps, source-of-truth notices, and live query commands.
- **Schema risk:** additive table plus legacy migration tests.
- **Autonomy creep:** accepted scorecards cannot write files; apply remains a separate human-approved implementation path.
- **Known weakness-mining gap:** fix below-threshold surface-merge behavior before `wiki-health` uses cluster counts.

## Test and Verification Plan

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Unit | Scorecard validation | Validate dimensions, required refs, total score, weak dimensions, route enum, review status. | `yarn workspace @octocodeai/octocode-awareness test:quiet -- scorecard` |
| Unit | Reflection capture | `reflect()` with and without scorecards; old callers unchanged; eval failures still create memories. | `yarn workspace @octocodeai/octocode-awareness test:quiet -- reflect` |
| Unit | Weakness mining | Fix or preserve documented behavior with explicit tests for below-threshold surface variants. | `yarn workspace @octocodeai/octocode-awareness test:quiet -- mine-weakness` |
| CLI | Scorecard commands | `reflect record --scorecard-json`, `reflect scorecard`, invalid JSON, compact JSON. | `yarn workspace @octocodeai/octocode-awareness test:quiet -- cli` |
| Integration | Query views | Seed temp DB; query `reflection-review`, `harness-candidates`, `wiki-health` in JSON/markdown/CSV/HTML. | `yarn workspace @octocodeai/octocode-awareness test:quiet -- cli` |
| Integration | Repo inject | Generate into temp workspace; assert `REFLECTIONS.md`, CSV, wiki-health reference, generated banners, no `.gitignore` edits. | `yarn workspace @octocodeai/octocode-awareness test:quiet -- cli` |
| Regression | Existing awareness | Full package test and self-test stay green. | `yarn workspace @octocodeai/octocode-awareness test:quiet && yarn workspace @octocodeai/octocode-awareness build && yarn workspace @octocodeai/octocode-awareness self-test` |
| Docs/skills | Skill mirrors | Build and inspect mirror parity if tests cover it. | `yarn workspace @octocodeai/octocode-awareness build` |

## Rollout / Migration / Rollback

- **Sequencing:** land data/schema and tests first, then capture commands, then query/projection views, then docs and optional export ordering.
- **Flags / gating:** no runtime flag required because the table and views are additive; keep scorecard capture optional.
- **Rollback trigger:** if existing `reflect record`, `query all`, or `repo inject` outputs regress, hide new command routes and keep the unused additive table.
- **Owner / approver:** awareness package owner/reviewer; human approval required before any skill/harness file edit based on scorecard output.

## References

- `packages/octocode-awareness/README.md:16-30` - current awareness store scope.
- `packages/octocode-awareness/src/reflect.ts:33-221` - current reflection capture behavior.
- `packages/octocode-awareness/src/memory.ts:990-1118` - current weakness mining behavior.
- `packages/octocode-awareness/tests/mine-weakness.test.ts:75-84` - known surface-merge gap.
- `packages/octocode-awareness/src/repo-context.ts:855-929` - current repo projection writer.
- `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:5-18` - canonical store/projection rule.
- Karpathy LLM Wiki raw gist lines 2-18 - persistent wiki pattern and ingest/query/lint/index/log model.
- self-improvement-loops raw skill lines 9-31 - evaluator isolation, evidence gates, archives, and human decision points.
