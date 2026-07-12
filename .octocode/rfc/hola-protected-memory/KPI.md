# KPI: HOLA-Inspired Protected Memory

> Goals/scope SSOT: `RFC.md` §Goals / §Non-Goals / §Delivery Phases. This file measures them.

## Definition Of Done

**MVP** is done when protected-memory ranking improves exact recall in fixture tests without breaking existing recall, scope isolation, compact output, or deletion semantics — and `attend` exposes explainable `protected_memory` when candidates exist.

**Optional POC** is done when the pure ranker + fixtures show Recall@3 / MRR@3 lift (or an explicit park decision is recorded). POC success is not required if equivalent fixture evidence already exists before MVP.

## User Stories

1. As an agent entering a large workspace, I can recover a precise old gotcha even when many newer memories mention similar terms.
2. As a maintainer, I can see why a memory was protected instead of trusting a black-box score.
3. As a multi-workspace user, I do not see protected memories from another workspace even when refs overlap.
4. As a CLI user, I can keep compact attend output readable while still seeing protected exact facts.
5. As an implementer, I can run an optional POC that falsifies ranking lift before wiring attend UX.

## Acceptance Criteria

```gherkin
Scenario: Optional POC proves ranking lift
  Given seeded fixtures with an old exact gotcha and newer decoys
  When rankProtectedMemories runs without attend wiring
  Then Recall@3 / MRR@3 improve over baseline getMemory ordering
  Or the RFC is explicitly parked

Scenario: Exact old fact is protected (MVP)
  Given an old memory with exact file refs and a high novelty score
  And newer decoy memories with overlapping words
  When attend runs with a query matching the old fact
  Then the old memory appears in protected_memory top 3
  And its reasons include novelty and exact reference evidence

Scenario: Novel irrelevant fact is not promoted
  Given a high-novelty memory unrelated to the query
  When protected-memory ranking runs
  Then the memory is not selected above relevant candidates

Scenario: Workspace scope is enforced
  Given two workspaces share the same reference value
  When protected-memory ranking runs in one workspace
  Then candidates from the other workspace are excluded

Scenario: Compact attend remains compact
  Given protected candidates overlap with normal evidence
  When attend runs in compact mode
  Then duplicate full text is not repeated unnecessarily
  And trace still names the protected selection reason

Scenario: Trust is visible
  Given a protected candidate has low-trust or generated provenance
  When attend returns it
  Then output includes a trust warning or reason
```

## Metrics

| Metric | Baseline | Target |
| --- | --- | --- |
| Recall@3 on protected fixtures | Capture before implementation (POC or MVP) | 100% on must-pass fixtures or at least +20 percentage points over baseline |
| MRR@3 on protected fixtures | Capture before implementation | Improvement over baseline, no regression on existing recall fixtures |
| Scope leaks | Existing tests plus new protected fixtures | 0 |
| Existing package tests | Current suite | 100% pass |
| Compact output budget | Current compact attend output | No material growth when protected candidates duplicate evidence |
| Schema migrations | 0 | 0 for v0 |
| Required external services | 0 | 0 |
| POC attend wiring | n/a | 0 required (POC may skip attend) |

## Evaluation Harness

Add deterministic Vitest fixtures with seeded memories. Prefer direct database-backed tests over broad CLI snapshots.

Minimal fixture corpus:

- Target memory: old, exact, high novelty, exact file/ref, medium importance.
- Decoys: newer, repeated terms, high importance, weak/no exact refs.
- Irrelevant surprise: high novelty, unrelated terms.
- Scope twin: same ref value in another workspace.
- Trust-risk candidate: generated/provisional ref.

## Decision Rule

**Ship MVP only if:**

- All must-pass MVP acceptance scenarios pass.
- Existing memory and attend tests stay green.
- Protected ranking is explainable from trace output.
- No schema migration is introduced.

**Park or narrow if:**

- Optional POC (or equivalent fixtures) fails to show ranking lift.
- Protected ranking only improves synthetic fixtures by overfitting weights.
- Compact attend becomes noisy.
- Scope-safety tests become brittle.
- The implementation needs a new storage layer before proving retrieval lift.

**Rollback trigger:** any of the park conditions after a partial merge — remove ranker, attend wiring, tests, and docs; no DB rollback (`IMPLEMENTATION.md` §Rollback).

## Traceability

| RFC requirement | User story | Acceptance | Verification | Post-ship status |
| --- | --- | --- | --- | --- |
| Preserve exact likely-forgotten details | US1 | Exact old fact | Recall@3 / MRR@3 fixtures | pending |
| Avoid promoting irrelevant novelty | US1 | Novel irrelevant | Fixture assert | pending |
| Keep workspace safety | US3 | Scope enforced | Scope leak metric | pending |
| Keep v0 reversible | — | Decision rule / rollback | Migration count = 0 | pending |
| Keep output understandable | US2, US4 | Trust + compact | Trace + compact budget | pending |
| Avoid external dependency drift | — | Metrics | Required services = 0 | pending |
| Optional POC before UX | US5 | POC scenario | Ranker-only fixtures or skip-with-evidence | pending |
| MVP attend surface | US1–4 | MVP scenarios | Package test + attend smoke | pending |
