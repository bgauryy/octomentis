# PREREQUISITES

## Scope

Existing-code area affected: `packages/octocode-awareness` read/query/projection/maintenance surfaces, plus generated workspace `.octocode/` docs.

RFC anchor: `RFC.md` sections "Goals and Non-Goals", "Reference-Level Explanation", and "Rationale and Alternatives".

## Required Current-State Evidence

| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| SQLite is canonical; `.octocode` is projection | `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:12`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7` | confirmed | Awareness maintainer |
| Existing loop already has attend/claim/verify/reflect/project vocabulary | `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:24` | confirmed | Awareness maintainer |
| Tasks/locks are verification debt | `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:49`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:58` | confirmed | Awareness maintainer |
| Refinements are durable follow-up queue | `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:75`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:136` | confirmed | Awareness maintainer |
| Query views and formats already exist | `packages/octocode-awareness/src/repo-context.ts:14`, `packages/octocode-awareness/src/repo-context.ts:31`, `packages/octocode-awareness/src/repo-context.ts:794` | confirmed | Awareness maintainer |
| Profile/activity rows can seed bloat metrics and workboard | `packages/octocode-awareness/src/repo-context.ts:642`, `packages/octocode-awareness/src/repo-context.ts:677` | confirmed | Awareness maintainer |
| Repo inject already writes wiki, CSV, and HTML projections | `packages/octocode-awareness/src/repo-context.ts:855` | confirmed | Awareness maintainer |
| Digest already performs cleanup, but current dry-run has no eligible cleanup | `packages/octocode-awareness/src/maintenance.ts:642`; `node packages/octocode-awareness/dist/bin/awareness.js maintenance digest --workspace "$PWD" --dry-run --compact` returned all `would_*` counts as 0 on 2026-07-08 | confirmed | Awareness maintainer |
| Memory novelty/similarity exists for consolidation hints | `packages/octocode-awareness/src/memory.ts:567`, `packages/octocode-awareness/src/memory.ts:584` | confirmed | Awareness maintainer |
| Navigation/workboard is already a recommended prototype direction | `.octocode/MEMORY_NAVIGATION.md:11`, `.octocode/MEMORY_NAVIGATION.md:78` | confirmed | Awareness maintainer |
| Source skill can expose the organ map without bloating generated wiki | `packages/octocode-awareness/skills/octocode-awareness/SKILL.md`; `packages/octocode-awareness/skills/octocode-awareness/references/homeostatic-loop.md` | confirmed | Awareness maintainer |

## Environment And Setup

| Need | How to verify | Source |
|---|---|---|
| Use local awareness CLI in this repo | `node packages/octocode-awareness/dist/bin/awareness.js workspace status --workspace "$PWD" --compact` | `packages/octocode-awareness/skills/octocode-awareness/SKILL.md:11` |
| Use source skill, not generated mirror, for awareness instruction changes | edit `packages/octocode-awareness/skills/octocode-awareness`; regenerate generated mirrors with the package build | root `AGENTS.md` "Awareness skill source of truth" |
| Keep generated `.octocode` projections non-canonical | regenerate via `repo inject`; do not hand-edit generated projections when a DB update is the real fix | `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:31` |
| Start with read-only surfaces | implement derived `query workboard` / `attend` before schema-heavy stores | `.octocode/MEMORY_NAVIGATION.md:11` |
| Preserve existing lifecycle commands | `schema commands --compact` should still show existing memory/lock/verify/signal/refinement/query/repo commands | `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:51` |

## Baseline Verification

| Check | Command or method | Expected baseline | Evidence |
|---|---|---|---|
| Workspace status | `node packages/octocode-awareness/dist/bin/awareness.js workspace status --workspace "$PWD" --compact` | command succeeds; current baseline has 212 active memories, 17 active tasks, 43 open refinements, 0 locks | observed 2026-07-08 |
| Repo profile | `node packages/octocode-awareness/dist/bin/awareness.js query repo-profile --workspace "$PWD" --format json --compact` | command succeeds; current baseline has 212 active memories, 562 tasks, 43 open refinements, 500 tracked files | observed 2026-07-08 |
| Digest dry-run | `node packages/octocode-awareness/dist/bin/awareness.js maintenance digest --workspace "$PWD" --dry-run --compact` | command succeeds; current baseline has all `would_*` counts 0 | observed 2026-07-08 |
| Projection size | `wc -l .octocode/AGENTS.md .octocode/MEMORY.md .octocode/GOTCHAS.md .octocode/LEARN.md .octocode/MEMORY_NAVIGATION.md` | current baseline is 1291 total lines across five docs | observed 2026-07-08 |
| CSV projection exists | `find .octocode/awareness/csv -maxdepth 1 -type f -name '*.csv' -print | sort` | generated CSVs exist for activity, agents, files, gotchas, lessons, locks, memories, refinements, signals, tasks | observed 2026-07-08 |

## Blockers Before Implementation

| Blocker | Impact | Owner | Resolution needed before Step 1 |
|---|---|---|---|
| None for a read-only RFC/prototype | `query workboard` and `attend` can be derived from existing DB rows | Awareness maintainer | Start with derived read surface |
| Automatic cleanup policy not yet defined | Unsafe to hard-delete tasks/memories based only on this RFC | Awareness maintainer + user | Keep sleep/digest report-first and dry-run by default |
| Projection budgets may need tuning | Too strict hides useful data; too loose bloats docs | Awareness maintainer + user | Ship budgets as defaults with explicit flags and metrics |
| Generated mirror editing risk | Editing `.agents/skills/octocode-awareness` directly would be lost/regenerated | Implementer | Edit `packages/octocode-awareness/skills/octocode-awareness` source and run package build when touching skill docs |

## Contracts And Migration Constraints

| Contract/data/API | Compatibility constraint | Rollback or guardrail |
|---|---|---|
| Awareness DB schema | MVP should not require a migration | Keep first slice read-only; add migrations only after traces prove need |
| `query <view>` | Existing views and formats keep working | Add `workboard` as new view or `attend` as separate command without altering current view semantics |
| `repo inject` | Generated files remain projections | Include manifest counts/caps; never import CSV/Markdown |
| `maintenance digest` | Cleanup remains non-destructive by default in new sleep flow | Dry-run first; explicit destructive command only |
| Tasks/locks lifecycle | Tasks remain verification debt | Workboard groups tasks without mutating raw audit rows |
| Refinements lifecycle | Refinements remain follow-up backlog | Workboard surfaces refinements but does not replace them |
