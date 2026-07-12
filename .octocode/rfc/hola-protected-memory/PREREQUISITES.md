# Prerequisites: HOLA-Inspired Protected Memory

## Readiness

This RFC can start as a prototype without schema migration because the current awareness database already carries the metadata needed for a first protected-memory score.

Required current-state references are listed in `RESOURCES.md`.

## Existing Capabilities To Reuse

| Capability | Current source | Reuse in v0 |
| --- | --- | --- |
| Memory scoring constants | `packages/octocode-awareness/src/memory.ts` | Keep current decay/BM25/importance behavior as the baseline. |
| Novelty at insert | `packages/octocode-awareness/src/memory.ts` | Use `novelty_score` as the closest local analog to HOLA surprise. |
| Memory refs | `packages/octocode-awareness/src/db.ts` and `src/memory.ts` | Use refs as provenance and trust signals. |
| Exact filters | `packages/octocode-awareness/src/memory.ts` | Reuse workspace, ref, file, regex, and `asOf` filtering before ranking. |
| Attend orchestration | `packages/octocode-awareness/src/attend.ts` | Surface protected candidates and trace entries here. |
| Optional semantic recall | `packages/octocode-awareness/src/memory.ts` and `bin/awareness.ts` | Keep optional; do not require for v0. |
| Memory tests | `packages/octocode-awareness/tests/*.test.ts` | Add protected-memory fixtures beside existing upgrade and scope tests. |

## Baseline Checks

Run before code changes:

```bash
yarn workspace @octocodeai/octocode-awareness test
yarn workspace @octocodeai/octocode-awareness typecheck
node packages/octocode-awareness/dist/bin/awareness.js attend --workspace "$PWD" --query "protected memory recall baseline" --compact
```

The attend command should be treated as a smoke check, not as an assertion suite. The real gate is fixture-based recall and scope testing.

## Data Contracts

V0 depends on these existing fields:

- `memories.id`
- `memories.workspace`
- `memories.text`
- `memories.importance`
- `memories.novelty_score`
- `memories.last_accessed_at`
- `memories.access_count`
- `memories.failure_signature`
- `memories.valid_until`
- `memory_refs.kind`
- `memory_refs.value`

No new table or migration is required for the prototype.

## Design Preconditions

Before implementation starts, close these choices in `IMPLEMENTATION.md`:

- Initial protected score weights and caps.
- Default output behavior for `attend`.
- Whether protected candidates should include rows that normal recall already selected.
- How compact mode should avoid duplicate text.
- How trust warnings should be represented.

## Test Preconditions

Add fixtures that cover:

- Exact important fact hidden among high-frequency decoys.
- Old but still valid memory that loses to newer related memories.
- High-novelty memory that is irrelevant and should not be promoted.
- Shared reference across workspaces that must not leak.
- Generated or low-trust reference that should be annotated.
- Compact attend output that remains bounded.

## Operational Preconditions

- Re-run awareness `attend` before implementation to check locks and live repo state.
- Keep changes inside `packages/octocode-awareness` and `.octocode/rfc/hola-protected-memory` unless a test proves otherwise.
- Do not modify generated mirrors under `.agents/skills` by hand.
- Do not add runtime npm dependencies for the prototype.

## Exit From Prerequisites

The implementation may begin when:

- Baseline tests are recorded.
- Protected-memory fixtures are written or clearly sketched.
- Score weights are documented.
- Output shape is documented.
- Rollback is a simple removal of the selector and attend surface.

**Optional POC path:** if ranking lift is still uncertain, start with `IMPLEMENTATION.md` Phase 0 (ranker + fixtures only) before attend wiring. POC is not a prerequisite for MVP when equivalent fixture evidence already exists — see `RFC.md` §Delivery Phases.

**Baseline recorded 2026-07-10:**

```text
attend --workspace "$PWD" --query "protected memory recall baseline" --compact  → ok
yarn workspace @octocodeai/octocode-awareness test --run tests/memory-upgrades.test.ts
  → 10 passed (use full package yarn test for coverage gate)
```

Resources for readiness: `RESOURCES.md` §POC And MVP Resource Map.
