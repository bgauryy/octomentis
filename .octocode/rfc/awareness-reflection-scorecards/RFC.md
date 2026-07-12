# RFC: Awareness Reflection Scorecards and Wiki-Memory Review Queue

> **Dependency note (2026-07-10):** this remains a follow-on RFC. It may resume only after core v4 passes the lossless-memory gate in [`awareness-operational-trust`](../awareness-operational-trust/RFC.md); it is not part of the coordination cutover.

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Decision type** | Reversible (two-way door) |
| **Author(s)** | Codex + Guy |
| **Created** | 2026-07-08 |
| **Last Updated** | 2026-07-08 |

## Audit Reasoning — kept (2026-07-12)

**Status:** Not implemented — all 6 `IMPLEMENTATION.md` phases are unchecked. No `reflection_scorecards` table, `scorecards.ts`, `reflect scorecard` command, or `reflection-review`/`wiki-health` query views exist in `packages/octocode-awareness`.
**Why kept:** The goal (bounded human review of reflection quality, no auto harness edits) is still wanted and nothing supersedes it.
**Correction needed:** the dependency note above points at `awareness-operational-trust`'s v4 "lossless-memory gate," which is itself obsolete (see that RFC's own Audit Reasoning note). Rebase the dependency onto the current memory model (post `canonical-awareness-v1`) instead of a stale v4 milestone before resuming work.

## Summary

Add a measured reflection-review layer to `@octocodeai/octocode-awareness`: structured scorecards for post-task reflections, queryable review queues for weak or high-impact lessons, and `.octocode/` projections that make the awareness store behave more like a repo-level LLM wiki without making generated markdown canonical. The change is additive: SQLite remains the source of truth, `reflect record` remains the capture point, and harness or skill changes still require human approval.

## Goals and Non-Goals

### Goals

- **G1: Score reflection quality.** Every reflection that claims a reusable lesson, eval failure, repo fix, or harness fix can attach a structured scorecard covering evidence, verification, lesson quality, failure signature quality, routing, and regression risk.
- **G2: Route improvement proposals to the right rung.** Reflections should say whether the fix belongs in memory, repo context, skill context, workflow, harness code, or evaluator/acceptance criteria.
- **G3: Make review queues queryable.** Add read views for low-score reflections, harness candidates, and repo-wiki health so agents and humans can inspect what needs review before changing skill or harness files.
- **G4: Improve `.octocode/` projections.** `repo inject` should surface reflection review state and wiki-memory health while preserving the rule that generated files are projections, not the canonical store.
- **G5: Keep self-improvement bounded.** Do not auto-apply prompt, skill, workflow, or harness edits from reflections. Store evidence and proposals; humans approve the changes.
- **G6: Preserve existing compatibility.** Existing memory, reflection, query, repo inject, and hook flows must continue working for callers that do not provide scorecards.

### Non-Goals

- A fully autonomous self-modifying harness.
- A full Karpathy-style interlinked markdown wiki with entity/topic/source page synthesis in v1.
- A model-judge-only acceptance gate.
- Replacing `memory record`, `reflect record`, `reflect mine-weakness`, or `reflect export-harness`.
- Making `.octocode/` generated files the source of truth.
- Changing repository sharing policy for `.octocode/`.

## Motivation

The awareness package already owns a useful agent memory and reflection substrate, but it does not yet rate whether a reflection is good enough to become durable guidance or a harness-change proposal.

Current evidence:

- The package owns the awareness runtime, including the TypeScript library, canonical CLI, primary skill sources, hooks, and Pi bridge (`packages/octocode-awareness/README.md:5-14`).
- One SQLite store tracks memories, file locks, verification gates, agents, signals, refinements, reflection records, harness proposals, and audit events (`packages/octocode-awareness/README.md:16-30`).
- The CLI already exposes `reflect record|mine-weakness|export-harness`, `query <view>`, and `repo inject` as command groups (`packages/octocode-awareness/README.md:66-86`; `packages/octocode-awareness/bin/awareness.ts:140-170`).
- `reflect()` already records narrative observations, `judgmentNote`, `failureSignature`, eval-failure memories, repo-fix refinements, harness log events, novelty, similar memories, and advisory supporter/skeptic prompts (`packages/octocode-awareness/src/reflect.ts:33-221`; `packages/octocode-awareness/src/types.ts:395-452`).
- Tests confirm `judgmentNote`, advisory duo prompts, and eval failures are preserved without storing duo prompts as extra memories (`packages/octocode-awareness/tests/fixes-doc-contract.test.ts:23-66`).
- `mineWeakness()` clusters recurring failure signatures by frequency times average importance, merges `|surface:` variants, and filters near-duplicates (`packages/octocode-awareness/src/memory.ts:990-1118`). Tests also document a known gap where surface variants below `minCount` are dropped before merging (`packages/octocode-awareness/tests/mine-weakness.test.ts:75-84`).
- `exportHarness()` already prioritizes harness-tagged memories and high-importance general lessons, but its output is a flat markdown list with no scorecard, review status, held-out check, or acceptance record (`packages/octocode-awareness/src/maintenance.ts:916-1009`).
- `repo inject` writes `.octocode/AGENTS.md`, `.octocode/MEMORY.md`, `.octocode/GOTCHAS.md`, `.octocode/LEARN.md`, CSVs, HTML, and compact references from the same SQLite store (`packages/octocode-awareness/src/repo-context.ts:855-929`), and generated row docs are flat summaries with optional failure signatures and refs (`packages/octocode-awareness/src/repo-context.ts:1018-1040`).
- The current repo-context RFC explicitly keeps SQLite canonical and generated files read-only projections (`.octocode/rfc/awareness-repo-context/RFC.md:19-24`).
- Live awareness data captured while drafting this RFC showed 189 active memories, 50 gotchas, 37 lessons, 463 tasks, 17 known agents, and 500 tracked files for this workspace. That is enough material to justify review queues, but it also raises the cost of low-quality lessons.

External prior art points in the same direction:

- Karpathy's LLM Wiki pattern says durable knowledge should compound through a maintained wiki layer, with ingest, query, lint, index, and log operations rather than rediscovering raw documents every time (raw gist lines 2-18).
- The self-improvement-loops skill warns that self-improving systems optimize the metric they are given, recommends evaluator and permission controls outside the mutable loop, requires empirical acceptance with held-in plus held-out evidence, and treats human decisions as necessary for evaluator changes and production promotion (raw skill lines 9-28).

## Guide-Level Explanation

After this RFC, a reflection can produce two artifacts:

1. A normal awareness memory, as it does today.
2. An optional scorecard row linked to that memory.

Example conceptual output:

```text
memory_id: mem_...
scorecard_id: score_...
total_score: 14 / 18
route: skill_context
review_status: pending
human_required: true
weak_dimensions: verification
next:
  - query reflection-review
  - review before editing skill files
```

Scorecard dimensions are deterministic integers from 0 to 3:

| Dimension | 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| `evidence` | none | prose only | file/URL references | raw command/test/source evidence refs |
| `verification` | none | planned only | one check run | deterministic check plus result/ref |
| `lesson_quality` | routine status | local observation | reusable pattern | reusable mechanism with scope |
| `failure_signature` | absent | vague | `mechanism` plus `cause` | `mechanism`, `cause`, and `surface` |
| `route_quality` | none | broad | plausible rung | lowest expressive rung with reason |
| `regression_risk` | absent | generic | specific risk | specific risk plus preservation note |

Routes are a small enum:

```text
memory | repo_context | skill_context | workflow | harness_code | evaluator
```

The default behavior stays gentle:

- `reflect record` works exactly as it does today when no scorecard is provided.
- `reflect record --scorecard-json ...` attaches a scorecard at capture time.
- `reflect scorecard --memory-id ... --scorecard-json ...` can add or replace a scorecard after review.
- `query reflection-review` shows weak, unreviewed, or high-impact reflections.
- `query harness-candidates` shows reviewed and pending harness/skill/workflow/evaluator proposals.
- `query wiki-health` summarizes repo-memory projection health: stale projections, low-scored lessons, unreviewed harness candidates, missing failure signatures, and top weakness clusters.
- `repo inject` adds `.octocode/REFLECTIONS.md` and richer `.octocode/references/wiki-health.md` or equivalent sections in `.octocode/LEARN.md`.

## Reference-Level Explanation

### Data Model

Add a normalized `reflection_scorecards` table rather than hiding the score in `memories.observation` or only in `harness_log.payload_json`.

Candidate shape:

```sql
CREATE TABLE IF NOT EXISTS reflection_scorecards (
  scorecard_id TEXT PRIMARY KEY,
  memory_id TEXT NOT NULL REFERENCES memories(memory_id) ON DELETE CASCADE,
  agent_id TEXT NOT NULL,
  workspace_path TEXT,
  artifact TEXT,
  repo TEXT,
  ref TEXT,
  route TEXT NOT NULL,
  review_status TEXT NOT NULL DEFAULT 'pending',
  human_required INTEGER NOT NULL DEFAULT 0,
  evidence_score INTEGER NOT NULL,
  verification_score INTEGER NOT NULL,
  lesson_quality_score INTEGER NOT NULL,
  failure_signature_score INTEGER NOT NULL,
  route_quality_score INTEGER NOT NULL,
  regression_risk_score INTEGER NOT NULL,
  total_score INTEGER NOT NULL,
  max_score INTEGER NOT NULL DEFAULT 18,
  evidence_refs_json TEXT NOT NULL DEFAULT '[]',
  verification_refs_json TEXT NOT NULL DEFAULT '[]',
  risk_note TEXT,
  preserve_note TEXT,
  reviewer_note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
```

Indexes:

- `memory_id`
- `(workspace_path, artifact)`
- `(repo, ref)`
- `(review_status, total_score)`
- `(route, human_required)`

The table is additive. Existing `memories`, `memory_refs`, `harness_log`, and `repo-context` paths stay valid.

### API and CLI

Extend:

- `ReflectParams` with `scorecard?: ReflectionScorecardInput`.
- `ReflectResult` with `scorecard_id?`, `scorecard_total?`, `review_status?`, and `weak_dimensions?`.
- `EvalFailure` only if needed to connect failed binary questions to a scorecard dimension; do not overload eval failures as scorecards.

Add:

- `reflect scorecard` command for post-hoc scorecard create/update.
- `reflection_scorecard` schema in `scripts/schema.mjs`.
- `ReflectionScorecardInput` and `ReflectionScorecardRecord` types in `src/types.ts`.
- `insertReflectionScorecard`, `getReflectionScorecards`, and `scoreReflectionInput` helpers, likely in a new `src/scorecards.ts`.
- Tool-operation support so Pi/future host bridges can call scorecard operations without shelling out.

### Query and Projection

Add views to `AWARENESS_QUERY_VIEWS`:

- `reflection-review`
- `harness-candidates`
- `wiki-health`

`reflection-review` sorts by:

1. `review_status = 'pending'`
2. lower `total_score`
3. higher memory importance
4. recency

`harness-candidates` includes routes `skill_context`, `workflow`, `harness_code`, and `evaluator`, plus memories tagged `harness`.

`wiki-health` includes aggregate counts:

- reflections without scorecards
- scorecards below threshold
- unreviewed harness candidates
- memories with failure signatures missing `surface`
- top weakness clusters from `mineWeakness`
- generated projection freshness when `.octocode/awareness/manifest.json` exists

`repo inject` should write:

```text
.octocode/REFLECTIONS.md
.octocode/awareness/csv/reflection_scorecards.csv
.octocode/references/wiki-health.md
```

It may also add a short "Reflection Review" section to `.octocode/AGENTS.md`.

### Review State

Review statuses:

```text
pending | accepted | rejected | superseded | deferred
```

Rules:

- `pending`: default for any scorecard.
- `accepted`: a human or trusted reviewer has accepted the lesson as durable guidance.
- `rejected`: do not surface as standing guidance, but keep it as negative evidence.
- `superseded`: another memory/scorecard replaced it.
- `deferred`: valid but not actionable until an explicit trigger.

Acceptance does not apply code. It only changes what projections and exports surface as guidance.

### Compatibility

This is backward-compatible if:

- no scorecard is required by `reflect record`;
- scorecard tables are additive migrations;
- query views are additive;
- generated projection files are additive and still marked generated;
- existing `exportHarness()` output remains available.

## Drawbacks

- More schema and CLI surface area in a package that already has a broad command set.
- Scoring can become performative if agents optimize the score instead of improving evidence.
- A scorecard is still metadata about a reflection, not proof that the proposed fix works.
- Generated `.octocode/REFLECTIONS.md` can become stale if users rely on it instead of live `query`.
- Review statuses introduce human process. If nobody reviews, queues can become clutter.

### Pre-mortem - how this fails

1. **Score inflation.** Agents fill every dimension with `3` without evidence. Mitigation: schema requires evidence refs for top evidence/verification scores, and tests cover invalid high scores without refs.
2. **Harness edits sneak in as "accepted" scorecards.** Mitigation: accepted scorecards still cannot apply files; implementation preserves explicit human apply and existing lock/verification flow.
3. **Generated docs become canonical.** Mitigation: every generated file repeats that SQLite is canonical and points to live `query` commands.
4. **The review queue is too noisy.** Mitigation: start with thresholds and limits; add `deferred`/`rejected` states before expanding automation.
5. **Known `mineWeakness()` surface-merge gap hides review candidates.** Mitigation: fix or explicitly account for below-threshold surface variants before relying on weakness counts for wiki-health.

## Rationale and Alternatives

### Why This Design?

The chosen design adds a small, queryable scorecard layer over existing reflection and repo-context infrastructure. It aligns with the current package's SQLite-first model, current `reflect()` capture point, current query/repo-inject surfaces, and prior-art advice to keep self-improvement bounded by evidence and human approval.

It deliberately stops at reviewability. Full self-modification needs hidden held-out evaluators, raw trace archives, sandbox boundaries, and stronger acceptance gates. Those are not present today.

### Alternatives Considered

#### Alternative A: Do nothing

- **What**: Keep `reflect`, `mineWeakness`, `exportHarness`, and `repo inject` as-is.
- **Evidence**: Current commands already exist (`packages/octocode-awareness/README.md:66-86`), and current `exportHarness()` surfaces harness-tagged memories (`packages/octocode-awareness/src/maintenance.ts:916-1009`).
- **Pros**: No implementation cost; no new schema; no new review workflow.
- **Cons**: Harness candidates remain flat prose without quality/risk/evidence ratings; generated `.octocode/` remains wiki-adjacent but not review-aware.
- **Why not chosen**: It does not address the user's request for reflections to "check all and rate out and others."

#### Alternative B: Store scorecards only in `harness_log.payload_json`

- **What**: Add scorecard payloads to harness events and query JSON payloads ad hoc.
- **Evidence**: `reflect()` already inserts a harness log event with payload metadata (`packages/octocode-awareness/src/reflect.ts:170-188`), and `harness_log` supports event types such as `reflect`, `mine`, `propose`, `validate`, and `apply` (`packages/octocode-awareness/docs/HARNESS.md:429-454`).
- **Pros**: No new top-level table; natural audit trail.
- **Cons**: Harder to index, filter, and project without JSON querying assumptions; less direct linkage to current memory/repo views.
- **Why not chosen**: Review queues and repo projections need first-class sorting/filtering by score, route, and status.

#### Alternative C: Full LLM Wiki generator

- **What**: Generate and maintain interlinked `.octocode/wiki/*` entity/topic/source pages from all memories, reflections, and repo facts.
- **Evidence**: Karpathy's LLM Wiki pattern recommends source ingestion, wiki page synthesis, query, lint, index, and log flows (raw gist lines 9-18).
- **Pros**: Stronger knowledge-base experience; closer to a real wiki.
- **Cons**: Larger design surface; higher risk of stale generated authority; requires ingest/lint lifecycle and page ownership rules not present today.
- **Why not chosen**: The current package already has generated projections and query views; scorecards are the smaller next step that improves source data quality before expanding generated pages.

#### Alternative D: Autonomous self-improvement loop

- **What**: Let agents mine weakness clusters, propose patches, run evaluation, and apply accepted harness/skill edits.
- **Evidence**: Self-improvement-loop guidance requires evaluator isolation, held-in/held-out evidence, raw candidate archives, runtime-enforced permissions, and human decision points (raw skill lines 9-31).
- **Pros**: Potentially higher leverage if evaluators are strong.
- **Cons**: Current awareness has reflection, mining, and harness logs, but not hidden held-out evaluators or candidate archives.
- **Why not chosen**: Too risky for v1; this RFC creates the review data needed before any future autonomous loop.

### Comparison Matrix

| Dimension | Proposed scorecards | Do nothing | Harness-log only | Full wiki | Autonomous loop |
|---|---|---|---|---|---|
| Codebase alignment | High | High | Medium | Medium | Low |
| Implementation complexity | Medium | None | Low-medium | High | High |
| Maintenance burden | Medium | Low | Medium | High | High |
| Query/projection quality | High | Low | Medium | High | Medium |
| Safety/governance | High | Medium | Medium | Medium | Low until evaluators exist |
| Reversibility | High | n/a | High | Medium | Low |

### Trade-off Summary

The proposed scorecard layer adds schema and review process in exchange for much better signal quality. It is deliberately less ambitious than a full wiki or autonomous self-improvement loop, because current local evidence shows the system has capture/mining/projection primitives but not a trustworthy acceptance/evaluator/archive layer.

### What If We Do Nothing?

Awareness remains useful, but reflection quality stays implicit. Harness proposals continue to be flat prose; agents can recall and export them, but cannot cheaply distinguish well-evidenced lessons from weak status notes. `.octocode/` projections remain a memory index rather than a reviewable wiki-memory surface.

## Prior Art

- **Local awareness harness.** The existing harness docs already describe a self-improvement feedback loop with reflection, failure signatures, refinements, and human approval (`packages/octocode-awareness/docs/HARNESS.md:1-20`).
- **Local repo context RFC.** The existing `awareness-repo-context` RFC introduced query/view/inject and preserved SQLite as canonical (`.octocode/rfc/awareness-repo-context/RFC.md:11-24`).
- **LLM Wiki.** The external pattern argues for persistent, compounding knowledge artifacts with ingest/query/lint/index/log operations (Karpathy raw gist lines 2-18).
- **Self-improvement loops.** External guidance recommends fixing failures at the lowest expressive rung, keeping evaluators outside mutable surfaces, accepting modifications only on measured evidence, and preserving human decision points (self-improvement-loops raw skill lines 6-31).

## Unresolved Questions

These are closed in `IMPLEMENTATION.md` before build steps.

**Before acceptance:**

- [ ] Should v1 use a new `reflection_scorecards` table or store scorecards only in `harness_log.payload_json`?
- [ ] Which route/rung enum is narrow enough for v1?
- [ ] Should `repo inject` add a new `.octocode/REFLECTIONS.md` file, or only add sections to existing `.octocode/LEARN.md`?
- [ ] Should scorecard acceptance ever apply a harness or skill edit?

**During implementation:**

- [ ] Should `mineWeakness()` fix the below-threshold surface-merge gap before `wiki-health` relies on cluster counts?

**Out of scope:**

- [ ] What evaluator and held-out split would be required for future autonomous harness evolution?

## Future Possibilities

- A richer `.octocode/wiki/` page generator once scorecards improve source quality.
- A filesystem candidate archive for proposed harness changes.
- Pairwise reviewer workflows for scorecards.
- Hidden held-out evaluator integration for a future, explicitly approved self-improvement loop.
