# Prerequisites: Scheduled Connector Ingestion for Octocode Awareness

> RFC anchor: `RFC.md` §Reference-Level Explanation

## Scope
New content inside `packages/octocode-pi-extension/src/` (connectors, schedule state, ingestion
prompt mode), one reserved subcommand in `packages/octocode-agent/bin/launcher.mjs`, one additive
line in `packages/octocode-awareness/src/repo-workboard.ts`, reuse of
`skills/octocode-brainstorming/scripts/lib/web-search-common.mjs`. No new package.

## Required Current-State Evidence
| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| No existing scheduler/daemon to conflict with | Repo-wide search `cron\|setInterval\|scheduler\|daemon` under `packages/` — zero matches | Confirmed | — |
| `memories.tags_json` exists and is queryable | `packages/octocode-awareness/src/db-schema.ts:37` | Confirmed | — |
| `MemoryReview` lane is computed, not stored, and already uses a tag convention (`anti-bloat` → `policy_memory`) | `packages/octocode-awareness/src/repo-workboard.ts:147-157` | Confirmed | — |
| `memories.state` CHECK only allows `ACTIVE`/`SUPERSEDED` — no new state without a DDL/fingerprint break | `packages/octocode-awareness/src/db-schema.ts:34`; contract rule at `docs/DB.md:84-86` | Confirmed | — |
| `workspace_path` is nullable on memories (supports non-repo-scoped rows if ever needed) | `packages/octocode-awareness/src/db-schema.ts:38`; `--global-only` flag documented at `skills/octocode-awareness/references/memory-recall.md:17` | Confirmed | — |
| Headless, non-interactive Pi invocation exists | `node_modules/@earendil-works/pi-coding-agent/docs/json.md:1-7` (`pi --mode json "prompt"`); `PiContext.mode` field at `packages/octocode-pi-extension/src/types.ts:170` | Confirmed (doc + type level) | Implementer must smoke-test |
| `octocode-agent`'s launcher already has a reserved-subcommand router to extend | `packages/octocode-agent/bin/launcher.mjs:163-176` (`parseInvocation`) | Confirmed | — |
| `octocode-agent` is deliberately thin — no `src/`, only `bin/` | `packages/octocode-agent/package.json` (`files`: `bin/**`, `docs/**`); dependencies limited to Pi host + pi-extension | Confirmed | — |
| `octocode-pi-extension` owns all prompt/tool/skill content and the Awareness bridge | `packages/octocode-pi-extension/src/index.ts` (tool registration, `composeSystemPrompt`, `createAwarenessHooksAddon`) | Confirmed | — |
| `octocode-pi-extension` has zero dependency on `octocode-agent` (standalone invariant) | `packages/octocode-pi-extension/package.json` dependencies list — only `@octocodeai/octocode-awareness`, `@octocodeai/octocode-core`, `@octocodeai/octocode-engine`, `@octocodeai/octocode-tools-core` | Confirmed | — |
| `resolvePromptMode` establishes the option > env > default precedence pattern to reuse for ingestion mode | `packages/octocode-pi-extension/src/prompt.ts:45-51` | Confirmed | — |
| In-process memory tools were retired; the agent writes memory via `bash` + the Awareness CLI, guided by the bundled skill | `packages/octocode-pi-extension/src/index.ts:619-624` | Confirmed | — |
| Generic (non-GitHub) token loading exists for connector credentials | `packages/octocode-config/src/tokens/envTokens.ts` (used today by brainstorming's web scripts) | Confirmed | — |
| `memory record` CLI accepts repeatable `--tag` | `skills/octocode-awareness/references/memory-recall.md:18` (doc-level only — not yet grepped in `bin/`) | Moderate | Implementer confirms via `--help` |

## Environment and Setup
| Need | How to verify | Source |
|---|---|---|
| OS scheduler available on target host (cron/launchd/Task Scheduler) | platform check at install time | operator environment, not repo |
| `OCTOCODE_ALLOW_INGESTION=1` set only in the cron job's env, not globally | installer/docs show it written into the cron entry itself | mirrors `OCTOCODE_ALLOW_HARNESS_APPLY` pattern, `docs/HARNESS.md:76-78` |
| At least one web-search key present (`SERPER_API_KEY`/`TAVILY_API_KEY`/`EXA_API_KEY`) | `@octocodeai/config` `--check` per key | `skills/octocode-brainstorming/references/tools.md:22-28` |

## Baseline Verification
| Check | Command or method | Expected baseline | Evidence |
|---|---|---|---|
| Awareness schema fingerprint unaffected by this RFC | `yarn workspace @octocodeai/octocode-awareness test` (schema tests) before and after the `repo-workboard.ts` edit | identical fingerprint, only new computed lane behavior | `tests/schema.test.ts` per `docs/DB.md:109-111` |
| `repo-workboard.ts` review-reason change is additive | new focused unit test asserting existing 4 reasons still fire unchanged | no regression in existing MemoryReview triggers | new test, see `IMPLEMENTATION.md` |
| Headless Pi round-trip works with no TTY | manual run of `pi --mode json "echo test"` in a non-interactive shell | JSON lines out, exit 0 | to be captured as `IMPLEMENTATION.md` Phase 0 evidence |
| `octocode-pi-extension` never depends on `octocode-agent` | dependency-list assertion test | assertion passes on every CI run | `IMPLEMENTATION.md` Phase 4b |

## Blockers Before Implementation
| Blocker | Impact | Owner | Resolution before Step 1 |
|---|---|---|---|
| Headless Pi non-TTY behavior unverified | Could block the agent-runner design if `--mode json` requires a TTY or misbehaves without one | Implementer | Run the smoke command in Unresolved Questions row 1; capture exit code + stdout shape |
| `memory record --tag`/`--importance` exact flag names unconfirmed in code (only in docs) | Wrong flag name would silently fail or mis-tag rows | Implementer | `<cli> memory record --help` before writing connector/prompt code |

## Contracts and Migration Constraints
| Contract/data/API | Compatibility constraint | Rollback or guardrail |
|---|---|---|
| Awareness SQLite schema (`db-schema.ts`) | Must not change — any DDL edit is a contract break requiring a fresh store (`docs/DB.md:84-86`) | This RFC's design deliberately avoids any DDL change |
| `repo-workboard.ts` `reviewReasons` array | Existing 4 reasons must keep firing unchanged; new reason is additive only | Revert the one-line diff; zero data migration needed |
| `AGENTS.md` "no secrets in Awareness rows" rule | Ingestion code must never pass a credential into `memory record`'s payload | Code review gate + a test asserting no secret-shaped string in a recorded memory |
| `octocode-pi-extension` package.json dependency list | Must never add `octocode-agent` | Standing dependency-list assertion test (Phase 4b) |
