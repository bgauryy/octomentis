# Prerequisites: Full Removal of Binary/Archive Tooling

> RFC anchor: `RFC.md` §Reference-Level Explanation

## Scope

Existing, shipping code across five packages: `octocode-engine` (Rust native module + security allowlist), `octocode-tools-core` (tool impl + OQL engine), `octocode-mcp` (MCP registration), `octocode` (CLI), plus docs and the `skills/octocode-research` skill. No new code is introduced; this is deletion + a small number of text edits to cross-cutting references.

## Required Current-State Evidence

| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| `localBinaryInspect` is one of the 13 always-on default tools in both packages | `packages/octocode-tools-core/src/tools/toolConfig.ts:311-355`; `packages/octocode-mcp/src/tools/toolConfig.ts:32,65,113-115`; `AGENTS.md` "Always-on (13)" table | Confirmed (read) | implementer |
| CLI `unzip` has no logic of its own — it only calls `executeDirectTool` with tool name `'localBinaryInspect'` and mode `'unpack'` | `packages/octocode/src/cli/commands/unzip.ts:46-56` | Confirmed (read) | implementer |
| `inspect`/`strings` modes are native (Rust `goblin`), not shell-exec; `list`/`extract`/`decompress`/`unpack` are shell-exec chains over `unzip`/`tar`/`7z`/`bsdtar`/`aa` and `zcat`/`gunzip`/`bzcat`/`xzcat`/`zstdcat`/`zstd`/`lz4cat`/`brotli`/`lzfse` | `packages/octocode-tools-core/src/tools/local_binary_inspect/binaryOps.ts:11-78`, `archiveOps.ts:1-222`, `decompressOps.ts:1-197` | Confirmed (read) | implementer |
| The engine's `binary` Rust module and the `goblin` crate are used only by the two napi tasks that back `inspect`/`strings` — no other engine feature (AST, minify, secrets, LSP) imports `crate::binary` or `goblin` | Grep: `crate::binary` only in `bindings/tasks.rs:142-172`, `bindings/mod.rs:1,15`, `lib.rs:1`; Grep: `goblin` only in `binary/*.rs`, `Cargo.toml:62`, `Cargo.lock`, `index.d.ts`, `loader/index.d.ts` | Confirmed (repo-wide grep) | implementer |
| The shell-exec command allowlist (13 commands) exists only to gate `archiveOps.ts`/`decompressOps.ts` — no other tool calls `safeExec` with these command names | `packages/octocode-engine/src/security/securityConstants.ts:8-21`, `commandValidator.ts:339-382`; grep confirms `archiveOps.ts`/`decompressOps.ts` are the only in-repo callers | Confirmed (repo-wide grep) | implementer |
| OQL `target:artifacts` wraps `localBinaryInspect` directly via `runDirect('localBinaryInspect', ...)` and has no independent backend | `packages/octocode-tools-core/src/oql/adapters/researchTargets/artifacts.ts:1-64` | Confirmed (read) | implementer |
| `target:artifacts` is wired through 9 OQL-engine files and 3 CLI `search` files, none shared with other active targets' logic (each `case`/map entry is target-specific) | `oql/types/targets.ts:18,41`; `oql/adapters/researchTargets.ts:31,56`; `oql/planner/predicateRouting.ts:199-200`; `oql/shorthand/target-params.ts:105-108`; `oql/transformers/registry.ts:248-262`; `oql/targetParams.ts:159,249`; `oql/schemeText.ts` (9 spots); `oql/run/continuations/records.ts:138-208`; CLI `commands/search/shorthandParts.ts`, `targetInference.ts`, `inputParsing.ts` | Confirmed (read) | implementer |
| Exactly one live cross-tool text dependency survives deletion: `ToolErrors.binaryFileUnsupported` names `localBinaryInspect` in its message and is raised by `localGetFileContent`, a tool that is *not* being removed | `packages/octocode-tools-core/src/errors/errorFactories.ts:69-74`; raised at `local_fetch_content/fetchContent/validation.ts:155` | Confirmed (read) | implementer |
| `localSearchCode`'s `mode` field only shares a name with `localBinaryInspect`'s `mode` field in a disambiguation comment — no shared code | `packages/octocode-tools-core/src/tools/local_ripgrep/scheme.ts:36-46` | Confirmed (read) | implementer |
| `paths.binary`/`paths.unzip` are dedicated cache dirs, separate from `paths.clone`/`paths.tree` used by clone/materialize features | `packages/octocode-tools-core/src/shared/paths.ts:27-42` | Confirmed (read) | implementer |
| No existing `.octocode/rfc/` entry already covers or contradicts this removal | Grep across `.octocode/rfc/**` for `unzip`/`binary`/`localBinaryInspect` — only unrelated storage-management mentions | Confirmed (grep) | implementer |

## Environment and Setup

| Need | How to verify | Source |
|---|---|---|
| Local monorepo build works end-to-end before touching code (clean baseline) | `yarn build && yarn test && yarn lint && yarn typecheck` | `AGENTS.md` §Build and local run |
| CLI dev build reflects source changes during implementation | `yarn local:fix && yarn workspace @octocodeai/octocode-engine build:dev && yarn workspace @octocodeai/octocode-tools-core build && yarn workspace octocode build:dev && yarn workspace @octocodeai/mcp build:dev` | `AGENTS.md` §Build and local run |
| Native rebuild is required after deleting the Rust `binary` module (ABI/`index.d.ts` change) | `yarn build:native:all` then `yarn platforms:check` | `AGENTS.md` §Build and local run |
| Rust unit tests for the engine run separately from JS tests | `yarn workspace @octocodeai/octocode-engine test:rust` | `AGENTS.md` §Build and local run |

## Baseline Verification

| Check | Command or method | Expected baseline | Evidence |
|---|---|---|---|
| Tool count before removal | `node packages/octocode/out/octocode.js tools` | 13 always-on tools including `localBinaryInspect` | Ran during research; confirmed 13-tool listing with `localBinaryInspect` present |
| `localBinaryInspect` scheme is currently well-formed and registered | `node packages/octocode/out/octocode.js tools localBinaryInspect --scheme` | Full schema prints (6 modes, pagination fields) | Ran during research; confirmed |
| Existing test suites for the tool and target currently pass | `yarn workspace @octocodeai/octocode-tools-core test -- local_binary_inspect`; `yarn workspace @octocodeai/octocode-tools-core test -- oql` | All green pre-removal (must be re-confirmed at implementation start, not assumed from this document's age) | Not re-run in this RFC pass — implementer must confirm immediately before Phase 1 |

## Blockers Before Implementation

| Blocker | Impact | Owner | Resolution before Step 1 |
|---|---|---|---|
| None identified — every dependency chain is isolated (see Required Current-State Evidence) except the one error-message text dependency, which is a same-PR text edit, not a design blocker | — | — | Reword `errorFactories.ts:72` in the same change that deletes `local_binary_inspect/` (tracked as an ordinary implementation step, not a blocker) |
| Native build tooling (Rust toolchain, napi-rs) must be available locally to rebuild after deleting `binary.rs`/`goblin` | Cannot verify the native module still links/loads without a rebuild | implementer | Confirm `yarn build:native:all` runs before merging; if unavailable in this environment, flag in `IMPLEMENTATION.md` rollout as a required CI step rather than skipping verification |

## Contracts and Migration Constraints

| Contract/data/API | Compatibility constraint | Rollback or guardrail |
|---|---|---|
| MCP tool list (`ALL_TOOLS`, `manifest.json`) | Public contract for any MCP client; removing `localBinaryInspect` is a breaking change for clients that call it by name | No shim — per `AGENTS.md` "No backward compat by default." Guardrail: `yarn workspace @octocodeai/mcp test` must show no test expects the tool to exist post-removal |
| CLI command surface (`unzip`, `search --target artifacts`) | Breaking change for scripts invoking these; no flag to re-enable | Same as above — document in release notes only (see `IMPLEMENTATION.md` §Rollout) |
| OQL grammar (`target:artifacts`) | A previously-valid query shape becomes invalid; must fail the same way any unknown/unsupported target fails today (no special error message needed) | Guardrail: `oql/v2-targets.test.ts` and `scheme/scheme-text.test.ts` (updated, not deleted wholesale) must assert `'artifacts'` is absent from `ACTIVE_TARGETS` and rejected cleanly |
| `ToolErrors.binaryFileUnsupported` message text | Currently names a tool being deleted, **and a test pins the exact wording** | Reword to drop the `localBinaryInspect` clause while keeping the `localSearchCode` recovery suggestion (that tool is not being removed) and the error code unchanged. Correction to initial assumption: `packages/octocode-tools-core/tests/errors/errorFactories.test.ts:16-24` asserts `err.message` contains the literal string `'localBinaryInspect'` — this test's second case (`'points the agent to a recovery tool instead of dead-ending'`) must be edited, not just left passing, as part of the same change. `packages/octocode-mcp/tests/tools/local_fetch_content.test.ts:711` only checks `hints` contains `'Binary'` (generic) and is unaffected |
| Native `.node` binary ABI | Deleting `binary.rs`/napi exports changes the compiled artifact for every platform target | Guardrail: `yarn platforms:check` after `yarn build:native:all`, before publish |
