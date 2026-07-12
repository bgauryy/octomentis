# Implementation Plan: HOLA-Inspired Protected Memory

> Decision: see `RFC.md` §Summary / §Decision / §Delivery Phases. This file does not restate goals — it references them.

## Resolved Questions (were open in RFC.md)

| Open question (RFC §) | Resolution | Evidence | Confidence |
| --- | --- | --- | --- |
| Exact initial score weights and caps | Deterministic heuristic below; fixture-tuned, no learned weights | Existing decay/BM25 constants at `packages/octocode-awareness/src/memory.ts:26`; novelty at insert `:552` | confirmed |
| Storage | Derived read path only; no schema migration | `memories` / `memory_refs` / FTS already exist (`src/db.ts:262`, `:474`, `:695`) | confirmed |
| Surprise signal | Use `novelty_score`, with small boosts for failure signatures and exact refs | Insert path stores novelty (`src/memory.ts:552`) | likely |
| Output shape | Optional `protected_memory` on `attend` when non-empty; keep normal `evidence` unchanged | Attend result shape `src/attend.ts:45`; orchestration `:285` | confirmed |
| Duplicates | Allow overlap internally; compact avoids repeating full text | Compact attend path already budgets evidence (`src/attend.ts`) | likely |
| Semantic recall | Defer post-MVP; do not require embeddings in v0 | Optional embed path `src/memory.ts` + CLI `bin/awareness.ts` | confirmed |
| Trust | Annotate low-trust first; suppress only when scope or validity fails | Existing trust warnings in attend | likely |
| POC mandatory? | **No** — optional falsification spike; skip if equivalent fixture evidence already exists | `RFC.md` §Delivery Phases | confirmed |

## Approach

Implement the derived protected ranker from `RFC.md` §Proposal / §Rationale (Alternatives: derived ranker chosen). Sequence: optional POC → MVP → optional CLI/docs polish.

## Functionality (MVP contract)

What MVP must deliver (maps to `RFC.md` §Guide-Level Explanation):

1. **Pure ranker** `rankProtectedMemories(candidates, options) → ProtectedMemoryCandidate[]` with `protected_score` + `reasons[]`.
2. **Attend surface:** when protected candidates are non-empty, emit `protected_memory` and a trace entry; never rewrite default `evidence` ordering semantics.
3. **Scope safety:** reuse existing workspace / ref / validity filters before ranking (`getMemory` / lexical path).
4. **Explainability:** every score bump/penalty has a reason string from the same branch that changed the score.
5. **Forget compatibility:** no new retention semantics; `forgetMemory` unchanged.
6. **Measurability:** Vitest fixtures for exact-old-fact, irrelevant-novelty, scope twin, trust annotation, compact budget.

Optional POC delivers (1) + fixture subset of (6) only — no attend wiring required to pass the spike.

## Steps (dependency-ordered)

### Phase 0: Optional POC (not mandatory)

Skip this phase when fixture evidence for ranking lift already exists from a prior spike. Purpose: falsify cheaply before attend UX.

- [ ] Add a throwaway or keepable pure helper `rankProtectedMemories` (may live temporarily in a test file or `src/protected-memory.ts`).
- [ ] Seed Vitest fixtures: target old exact gotcha vs recency/frequency decoys; irrelevant high-novelty; workspace twin.
- [ ] Assert Recall@3 / MRR@3 lift vs baseline normal `getMemory` ordering on the same seed.
- [ ] **Exit:** pass → proceed to MVP; fail → park (update `RFC.md` Status / Decision) without attend changes.
- [ ] **Do not** wire CLI flags or change `AttendResult` in POC unless the spike is immediately promoted.

Resources for POC: HOLA paper + local scoring anchors in `RESOURCES.md` §Primary Sources / §Local Code References / §POC And MVP Resource Map.

### Phase 1: MVP — ranking helper + fixtures

Ship the smallest product slice from `RFC.md` §Delivery Phases.

- [ ] Land (or promote) `rankProtectedMemories` in `src/protected-memory.ts` or beside `src/memory.ts`.
- [ ] Candidate selection reuses scoped recall/filtering; ranking stays pure over hydrated rows.
- [ ] Must-pass fixtures from `KPI.md` (exact old fact, irrelevant novelty, scope, trust, compact budget sketch).
- [ ] Preferred test homes: `tests/memory-upgrades.test.ts`, `tests/memory.test.ts`, and/or new `tests/protected-memory.test.ts`.

Suggested API:

```text
ProtectedMemoryCandidate:
- id, text, score, protected_score, reasons, refs, labels, updated_at

rankProtectedMemories(candidates, options) → ProtectedMemoryCandidate[]
```

### Phase 2: MVP — attend integration

- [ ] Extend `attendAwareness` (`src/attend.ts:285`): compute normal recall; rank protected from hydrated pool.
- [ ] Add `protected_memory` only when non-empty; add trace entries (candidate count, selected count, top reasons).
- [ ] Compact mode: avoid duplicating full memory text already in `evidence`.
- [ ] Do not change the default meaning of `evidence`.

### Phase 3: MVP — docs + package verification

- [ ] Update `packages/octocode-awareness/docs/MEMORY_NAVIGATION.md` — "protected = ranking lane, not undeletable".
- [ ] Run package test / typecheck / lint (see Validation).
- [ ] Refresh this RFC packet if weights or output shape change during implementation.

### Phase 4: Post-MVP (optional)

- [ ] `octocode-awareness memory recall --protected --query "…"` if attend-only is insufficient for debugging.
- [ ] Optional semantic candidate blend (still no required embedder).
- [ ] Adaptive / TinyLFU-style admission experiments.

## Initial Scoring

Start with a simple bounded score:

```text
protected_score =
  0.40 * relevance
  + 0.20 * novelty_score
  + 0.15 * importance
  + 0.10 * reference_signal
  + 0.10 * failure_or_gotcha_signal
  + 0.05 * access_signal
  - penalties
```

Rules:

- `relevance` must be non-zero for query-driven protected recall.
- `novelty_score` clamped to `[0, 1]`.
- `importance` normalized to `[0, 1]`.
- `reference_signal` rewards exact file/ref hits and non-generated provenance.
- `failure_or_gotcha_signal` rewards gotchas / failed assumptions / corrections.
- `access_signal` capped so frequency cannot dominate relevance.
- Penalties: expired/superseded, scope uncertainty, low trust (annotate; suppress only on hard scope/validity failure).

Weights are intentionally boring. POC/MVP evals reveal whether the idea works before sophistication.

## Files / APIs / Contracts Touched

| Path | Change |
|---|---|
| `packages/octocode-awareness/src/protected-memory.ts` (new) or `src/memory.ts` | Pure ranker |
| `packages/octocode-awareness/src/attend.ts` | Optional `protected_memory` + trace |
| `packages/octocode-awareness/tests/*` | Fixtures + acceptance scenarios |
| `packages/octocode-awareness/docs/MEMORY_NAVIGATION.md` | User-facing wording |
| `packages/octocode-awareness/bin/awareness.ts` | Optional `--protected` post-MVP only |

No `db.ts` migration for v0.

## Risk Mitigations

Traces to `RFC.md` §Risks / §Pre-mortem:

- Relevance floor before novelty boosts.
- Workspace filters before ranking.
- Compact id/reason emission on overlap.
- Explicit docs wording against "undeletable".
- Park after failed POC rather than shipping attend noise.

## Test and Verification Plan (V&V)

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Unit | Ranker | Seeded fixtures, pure function | `yarn workspace @octocodeai/octocode-awareness test` |
| Integration | Attend output | Compact/explain attend with protected section | same + manual `attend --compact` smoke |
| Regression | Existing recall/scope/forget | Existing suites must stay green | same |
| Type/lint | Package | Static gates | `yarn workspace @octocodeai/octocode-awareness typecheck` / `lint` |

## Validation

```bash
yarn workspace @octocodeai/octocode-awareness test
yarn workspace @octocodeai/octocode-awareness typecheck
yarn workspace @octocodeai/octocode-awareness lint
node packages/octocode-awareness/dist/bin/awareness.js attend --workspace "$PWD" --query "protected memory" --compact
```

Repo-level (optional confidence):

```bash
yarn verify
```

**Baseline recorded 2026-07-10:** `attend` smoke OK; `tests/memory-upgrades.test.ts` — 10 passed (coverage threshold fails when running a single file in isolation — use full package `yarn test` for the gate).

## Rollout / Migration / Rollback

- **Sequencing:** Phase 0 (optional) → Phase 1–3 MVP → Phase 4 optional.
- **Flags / gating:** no feature flag required if output is additive and empty-by-default; can gate behind explain/compact verbosity if needed.
- **Rollback trigger:** KPI Decision Rule fail (no lift, compact noise, scope leak) — remove ranker + attend wiring + tests + docs; no DB rollback.
- **Owner / approver:** Guy + package maintainers.

## References

Use `RESOURCES.md` for the full inventory. Implementation-critical:

- `packages/octocode-awareness/src/memory.ts:26` — scoring constants baseline.
- `packages/octocode-awareness/src/memory.ts:288` / `:764` — lexical + recall API to reuse.
- `packages/octocode-awareness/src/attend.ts:45` / `:285` — result shape + orchestration.
- `packages/octocode-awareness/src/db.ts:262` / `:474` / `:695` — schema fields / FTS.
- https://arxiv.org/html/2607.02303v1 — HOLA surprise-auxiliary-memory lesson.
