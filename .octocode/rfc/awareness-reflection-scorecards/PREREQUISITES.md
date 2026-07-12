# PREREQUISITES

## Scope

Existing-code area affected:

- `packages/octocode-awareness/src/`
- `packages/octocode-awareness/bin/awareness.ts`
- `packages/octocode-awareness/scripts/schema.mjs`
- `packages/octocode-awareness/tests/`
- `packages/octocode-awareness/skills/octocode-awareness/`
- Generated `.octocode/` repo-context projections

RFC anchor: `RFC.md` sections "Goals and Non-Goals", "Reference-Level Explanation", and "Rationale and Alternatives".

## Required Current-State Evidence

| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| Awareness is SQLite-first and already owns memories, verification, reflection, and harness proposals. | `packages/octocode-awareness/README.md:16-30` | confirmed | awareness maintainer |
| CLI has existing reflection, query, and repo-inject command surface. | `packages/octocode-awareness/README.md:66-86`; `packages/octocode-awareness/bin/awareness.ts:140-170` | confirmed | awareness maintainer |
| `reflect()` is the right capture point for scorecards. | `packages/octocode-awareness/src/reflect.ts:33-221`; `packages/octocode-awareness/src/types.ts:412-452` | confirmed | implementer |
| Eval failures already create structured memories and fallback failure signatures. | `packages/octocode-awareness/src/reflect.ts:122-144`; `packages/octocode-awareness/tests/fixes-doc-contract.test.ts:45-66` | confirmed | implementer |
| Weakness mining already clusters by failure signature and has a documented below-threshold surface-merge gap. | `packages/octocode-awareness/src/memory.ts:990-1118`; `packages/octocode-awareness/tests/mine-weakness.test.ts:75-84` | confirmed | implementer |
| Harness export currently surfaces candidate guidance but has no review status or scorecard. | `packages/octocode-awareness/src/maintenance.ts:916-1009` | confirmed | implementer |
| Repo context projections are generated from SQLite and must not become canonical. | `packages/octocode-awareness/src/repo-context.ts:855-929`; `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:5-18` | confirmed | implementer |
| Query/view/repo-inject operations already exist in the host operation union. | `packages/octocode-awareness/src/tool-operations.ts:30-44` | confirmed | implementer |

## Environment And Setup

| Need | How to verify | Source |
|---|---|---|
| Workspace is in repo root. | `pwd` returns `/Users/guybary/Documents/octocode-mcp`. | user-provided environment |
| Awareness command map is callable. | `node .agents/skills/octocode-awareness/scripts/awareness.mjs schema commands --compact` exits 0. | awareness skill fallback |
| No conflicting active locks on target implementation files. | `octocode-awareness workspace status --workspace "$PWD" --compact`; wait or coordinate if package files are locked. | `packages/octocode-awareness/skills/octocode-awareness/references/files-awareness.md:1-57` |
| Git worktree is dirty and must be preserved. | `git status --short` before implementation. | repo status during RFC drafting |

## Baseline Verification

| Check | Command or method | Expected baseline | Evidence |
|---|---|---|---|
| Awareness package self-test | `yarn workspace @octocodeai/octocode-awareness self-test` after build | exits 0 | package script in `packages/octocode-awareness/package.json` |
| Focused reflection tests | `yarn workspace @octocodeai/octocode-awareness test:quiet -- reflect` | existing reflect tests pass | `packages/octocode-awareness/tests/fixes-doc-contract.test.ts:23-66` |
| Weakness mining tests | `yarn workspace @octocodeai/octocode-awareness test:quiet -- mine-weakness` | existing behavior and known gap are visible | `packages/octocode-awareness/tests/mine-weakness.test.ts:1-105` |
| Repo context projections | temp workspace `repo inject`; assert generated files and no gitignore edit | existing query/inject behavior stays compatible | `packages/octocode-awareness/src/repo-context.ts:855-929` |
| Schema command list | `node packages/octocode-awareness/scripts/schema.mjs commands --compact` | command JSON remains parseable and includes new scorecard command after implementation | `packages/octocode-awareness/scripts/schema.mjs:900-921` |

## Blockers Before Implementation

| Blocker | Impact | Owner | Resolution needed before Step 1 |
|---|---|---|---|
| Active locks on package files may belong to another current task. | Editing locked files risks collision. | implementer | Run `workspace status`; wait, coordinate, or choose a non-overlapping slice. |
| Existing dirty worktree includes many unrelated changes. | Patch may accidentally absorb unrelated work. | implementer | Use focused diffs and stage nothing unless explicitly requested. |
| Scorecard table migration must preserve old stores. | Existing user databases may lack new columns/tables. | implementer | Add migration and legacy migration tests before exposing CLI commands. |
| Query views and generated docs can leak private data if not bounded. | Share-mode projections could expose sensitive reflection notes. | implementer/reviewer | Keep default local mode, row caps, summaries, and generated-file warnings. |

## Contracts And Migration Constraints

| Contract/data/API | Compatibility constraint | Rollback or guardrail |
|---|---|---|
| `reflect record` CLI | Scorecard fields must be optional; old flags keep working. | Roll back by hiding scorecard flags and leaving table unused. |
| `ReflectParams` / `ReflectResult` | Add optional fields only. | TypeScript callers remain source-compatible. |
| SQLite schema | Add table/indexes without changing existing columns. | Legacy migration tests cover older stores. |
| `query <view>` | Existing view names and formats keep behavior. | New views are additive. |
| `repo inject` | Existing generated files still written with source-of-truth warnings. | New files/sections can be disabled or omitted without breaking old projections. |
| `exportHarness()` | Existing markdown output remains available. | Scorecard-aware export can be an option or additional view first. |
