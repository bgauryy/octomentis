# Implementation: Full Removal of Binary/Archive Tooling

> Decision: `RFC.md` §Summary / §Rationale and Alternatives (Option A)

## Resolved Questions

| RFC open question (§) | Resolution or explicit deferral | Evidence | Confidence |
|---|---|---|---|
| Orphaned `~/.octocode/tmp/binary` and `~/.octocode/tmp/unzip` cleanup for existing users | Deferred: document only (Phase 5), no code. These are plain, user-owned tmp directories under `paths.tmp`; `cache clear --all` already exists for the remaining buckets and adding a one-off migration purge for two now-dead paths is disproportionate to the risk (no secrets, no growth after this change ships) | `packages/octocode-tools-core/src/shared/paths.ts:27-42`; `packages/octocode/src/cli/commands/cache.ts:113-257` | Confirmed |
| Native rebuild requirement after deleting `binary.rs`/`goblin` | Resolved: required, not optional. Added as an explicit Phase 1 step (`yarn build:native:all` + `yarn platforms:check`) because napi-generated `index.d.ts`/`loader/index.d.ts` symbols are removed, changing the native ABI surface | `packages/octocode-engine/index.d.ts:60,90,125,138`; `AGENTS.md` §Build and local run | Confirmed |
| Semver-major bump for `octocode`/`@octocodeai/mcp` | Resolved: recommended, not blocking. No CHANGELOG convention exists outside `packages/octocode-vscode/CHANGELOG.md`; record the breaking change in the PR/release description instead of inventing a new process in this change | `packages/octocode/package.json:3` (`1.0.2`); `packages/octocode-mcp/package.json:3` (`1.0.2`) | Confirmed |
| `errorFactories.test.ts` pins the exact `localBinaryInspect` wording | Resolved (correction from `PREREQUISITES.md`): this test must be edited in the same change, not left as-is — see Phase 3 | `packages/octocode-tools-core/tests/errors/errorFactories.test.ts:16-24` | Confirmed |

Nothing remains uncertain for this removal; all facts were closed against live code, not assumed.

## Approach

Delete bottom-up (native engine → security allowlist → tool implementation → OQL wiring → interfaces → docs/skills/benchmarks), so that at every phase boundary the previous layer's dependents have already been removed and `yarn typecheck` surfaces any missed reference immediately (per `RFC.md` §Drawbacks "Failure trigger").

## Steps

### Phase 0: Baseline
- [ ] Confirm current tests pass before touching anything: `yarn workspace @octocodeai/octocode-tools-core test`, `yarn workspace @octocodeai/mcp test`, `yarn workspace octocode test`, `yarn workspace @octocodeai/octocode-engine test:rust` — RFC §Motivation (baseline claim must be re-verified, not assumed from research time)

### Phase 1: Rust engine — delete native `binary` module
- [ ] Delete `packages/octocode-engine/src/binary/mod.rs`, `types.rs`, `inspect.rs`, `strings.rs`, `read.rs` — `RFC.md` §Reference-Level Explanation (layer 1)
- [ ] Remove `mod binary;` from `packages/octocode-engine/src/lib.rs:1` and `packages/octocode-engine/src/bindings/mod.rs:1,15` (`pub use binary::*;`)
- [ ] Remove `InspectBinaryTask`/`ExtractBinaryStringsTask` from `packages/octocode-engine/src/bindings/tasks.rs:137-176`
- [ ] Remove `goblin = "0.10"` and its comment block from `packages/octocode-engine/Cargo.toml:56-62`; run `cargo` lockfile update so `Cargo.lock` drops the transitive `goblin` entries
- [ ] Rebuild native artifacts: `yarn build:native:all`, then `yarn workspace @octocodeai/octocode-engine build:dev` to regenerate `index.d.ts`/`loader/index.d.ts` without `inspectBinaryNative`/`extractBinaryStringsNative`/`BinaryInspectInfo`/`BinaryStrings` (`packages/octocode-engine/index.d.ts:60,90,125,138`)
- [ ] Run `yarn workspace @octocodeai/octocode-engine test:rust` — confirm no remaining reference to `crate::binary`
- [ ] Run `yarn platforms:check`

### Phase 2: Security allowlist — remove archive/decompress command gate
- [ ] Remove the 13-command block from `packages/octocode-engine/src/security/securityConstants.ts:8-21`
- [ ] Remove the corresponding `case` branches in `packages/octocode-engine/src/security/commandValidator.ts:339-382`
- [ ] Update `packages/octocode-engine/tests/security/commandValidator.test.ts` to drop assertions for the removed commands (do not leave dead test cases asserting behavior for commands no longer in the allowlist)

### Phase 3: Tool implementation — delete `local_binary_inspect`
- [ ] Delete `packages/octocode-tools-core/src/tools/local_binary_inspect/**` (`binaryInspector.ts`, `binaryInspector/handlers.ts`, `binaryInspector/helpers.ts`, `scheme.ts`, `execution.ts`, `archiveOps.ts`, `decompressOps.ts`, `binaryOps.ts`)
- [ ] Delete `packages/octocode-tools-core/tests/tools/local_binary_inspect/inspect.test.ts` and `strings-match.test.ts`
- [ ] Remove the `LOCAL_BINARY_INSPECT` entry from `packages/octocode-tools-core/src/tools/toolNames.ts:24`
- [ ] Remove `LOCAL_BINARY_INSPECT` construction/exports/`ALL_TOOLS` entry from `packages/octocode-tools-core/src/tools/toolConfig.ts:2-6,29-30,34,311-322,340-355,370,394,396` (13 → 12 tools)
- [ ] Remove `LocalBinaryInspect*Schema` re-exports from `packages/octocode-tools-core/src/tools/toolSchemaImports.ts`
- [ ] Remove the two `export * from './tools/local_binary_inspect/execution.js'` and `'./tools/local_binary_inspect/scheme.js'` lines from `packages/octocode-tools-core/src/index.ts:65-66`
- [ ] Remove the `LOCAL_BINARY_INSPECT` entry (name/schema/inputSchema) from `packages/octocode-tools-core/src/tools/directToolCatalog/toolCatalogDefinitions.ts:39-41,225-228`
- [ ] Remove any `localBinaryInspect` command-pattern examples from `packages/octocode-tools-core/src/tools/directToolCatalog/toolCommandPatternQueries.ts`; update `packages/octocode-tools-core/tests/tools/directToolCatalog.commandPatterns.test.ts` accordingly
- [ ] Reword `ToolErrors.binaryFileUnsupported` in `packages/octocode-tools-core/src/errors/errorFactories.ts:69-74` to drop the `localBinaryInspect` clause, keep the `localSearchCode` recovery suggestion and the `BINARY_FILE_UNSUPPORTED` error code
- [ ] Update `packages/octocode-tools-core/tests/errors/errorFactories.test.ts:16-24` — remove the `expect(err.message).toContain('localBinaryInspect')` assertion; keep/adjust the `localSearchCode` assertion
- [ ] Remove `paths.binary`/`paths.unzip`/`ensureBinary`/`ensureUnzip` from `packages/octocode-tools-core/src/shared/paths.ts:37,39,75-87`; update `packages/octocode-tools-core/tests/shared/paths/paths.test.ts`
- [ ] Trim the `localBinaryInspect` disambiguation clause from the `mode` field comment/description in `packages/octocode-tools-core/src/tools/local_ripgrep/scheme.ts:36-46` (leave the field and its remaining disambiguation against `ghHistoryResearch` intact)

### Phase 4: OQL engine — remove `target:artifacts`
- [ ] Remove `'artifacts'` from `OqlActiveTarget`/`ACTIVE_TARGETS` in `packages/octocode-tools-core/src/oql/types/targets.ts:18,41`
- [ ] Delete `packages/octocode-tools-core/src/oql/adapters/researchTargets/artifacts.ts`; remove its import/registration in `packages/octocode-tools-core/src/oql/adapters/researchTargets.ts:31,56`
- [ ] Remove the `case 'artifacts': return 'inspectArtifact';` branch in `packages/octocode-tools-core/src/oql/planner/predicateRouting.ts:199-200`
- [ ] Remove the `case 'artifacts':` branch in `packages/octocode-tools-core/src/oql/shorthand/target-params.ts:105-108`
- [ ] Remove the `local.artifacts` transformer entry in `packages/octocode-tools-core/src/oql/transformers/registry.ts:248-262`
- [ ] Remove `artifactsParams` and its `artifacts:` key in `packages/octocode-tools-core/src/oql/targetParams.ts:159,249`
- [ ] Remove all `artifacts`/`artifact` prose from `packages/octocode-tools-core/src/oql/schemeText.ts` (description, `sourceGuide.local`, `answerType`, `targetOptions`, cheatsheet "inspect a binary/archive" row, "artifact inspect/list" example, `where` filter mention, `artifacts` params block)
- [ ] Remove `buildArtifactContinuations`/`next.artifactStrings`/`next.artifactContent` from `packages/octocode-tools-core/src/oql/run/continuations/records.ts:138-208`; update its file-header comment (`records.ts:3`) to drop "artifact" from the continuation-category list
- [ ] Update OQL tests: `packages/octocode-tools-core/tests/oql/v2-targets.test.ts`, `artifact-continuations.test.ts`, `open-gaps-materialize.test.ts`, `parity-gaps.test.ts`, and `packages/octocode-tools-core/tests/scheme/scheme-text.test.ts` — delete artifact-specific cases; update any shared fixture that enumerates all active targets
- [ ] Remove artifact-mode/target-inference handling from CLI `search`: `packages/octocode/src/cli/commands/search/shorthandParts.ts:27,57,263-270`, `targetInference.ts:16,53,56`, `inputParsing.ts:24`; update `packages/octocode/tests/cli/commands/search.test.ts`

### Phase 5: Interfaces — MCP + CLI
- [ ] Delete `packages/octocode-mcp/src/tools/local_binary_inspect/register.ts`; remove its import/map entry/export in `packages/octocode-mcp/src/tools/toolConfig.ts:32,65,113-115`
- [ ] Remove the `mcp_octocode_localBinaryInspect` entry from `packages/octocode-mcp/manifest.json:82`
- [ ] Delete `packages/octocode-mcp/sanity_tests/localBinaryInspect.md`; update `packages/octocode-mcp/sanity_tests/README.md` to drop its reference
- [ ] Update MCP tests that enumerate all tools: `packages/octocode-mcp/tests/tools/toolConfig.test.ts`, `toolConfig.branches.test.ts`, `toolMetadata.final.test.ts`, `all-tools.pagination-contract.test.ts`, `stats_emission_contract.test.ts`, `packages/octocode-mcp/tests/scheme/all-tools.schema-contract.test.ts`, `packages/octocode-mcp/tests/security/all-tools-sanitization.test.ts`, `packages/octocode-mcp/tests/setup.ts` — expect 12 tools, not 13
- [ ] Delete `packages/octocode/src/cli/commands/unzip.ts`; remove its entry from `packages/octocode/src/cli/commands/index.ts:21`
- [ ] Remove `'unzip'` from `QUICK_COMMAND_NAMES` and its `quick(...)` help line in `packages/octocode/src/cli/main-help.ts:24,190`
- [ ] Remove the `unzip` mention from `packages/octocode/src/cli/tool-command/context.ts:69`; update `packages/octocode/src/cli/tool-command/formatting.ts` if it special-cases `localBinaryInspect`
- [ ] Remove binary/unzip cache-bucket reporting and `cache clear --binary/--unzip` flags from `packages/octocode/src/cli/commands/status.ts:67-181` and `packages/octocode/src/cli/commands/cache.ts:113-257`
- [ ] Update `packages/octocode/tests/cli/commands/status.test.ts`, `command-spec-coverage.test.ts`, `tool-command.test.ts`, `help-modules.test.ts` — drop binary/unzip/artifacts expectations

### Phase 6: Docs
- [ ] `docs/OCTOCODE_TOOLS.md`: delete the "Binary Tools Reference" section (`:700-864`), its ToC entry (`:25`), its Tool Inventory row (`:17`), and the `localBinaryInspect` pointer row (`:313`)
- [ ] `docs/OCTOCODE_MCP.md:79`: drop `localBinaryInspect` from the Local tools list
- [ ] `packages/octocode/docs/OCTOCODE_CLI.md:23,75,131,262-266`: remove the `unzip` command row/section and the `localBinaryInspect`/`--target artifacts` row
- [ ] `packages/octocode/docs/OQL_LANGUAGE_REFERENCE.md`, `OQL_INTERNALS.md`, `OCTOCODE_QUERY_LANGUAGE.md`: remove `artifacts` target documentation
- [ ] `docs/CONFIGURATION.md`, `docs/OCTOCODE_RESEARCH_MANIFEST.md`: remove `localBinaryInspect` mentions
- [ ] `AGENTS.md`: update the Tools table — "Always-on (13)" → "Always-on (12)", drop `localBinaryInspect` from the Local row
- [ ] Root `README.md`: remove `localBinaryInspect`/`unzip`/`artifacts` mentions
- [ ] `packages/octocode-pi-extension/src/constants.ts:18`, `src/subagents.ts:150-220`, `src/tools/render-helpers.ts:216-231`, `src/prompts/sections/tools.md:16`, `src/prompts/sections/octocode-cli.md:9`, `README.md`: remove tool from subagent tool lists, prompt sections, and render-helper special-casing; update `tests/render-helpers.test.ts` and `tests/package.test.ts`

### Phase 7: Skill — `skills/octocode-research`
- [ ] `skills/octocode-research/references/octocode.md:18,39`: remove the `artifacts` row from the target/tool table and the alias-mapping note
- [ ] `skills/octocode-research/references/workflow-local.md:16-19`: remove the binary/archive decision-tree branch
- [ ] `skills/octocode-research/references/workflow-external.md:19-20`: remove the "materialize then localBinaryInspect" guidance
- [ ] `skills/octocode-research/references/code-research.md:16`: remove the "binary/archive" table row
- [ ] `skills/octocode-research/references/research-flow.md:25`: remove the "Artifact:" flow line
- [ ] `skills/octocode-research/references/algorithm.md:15`: remove the "binary/archive" row
- [ ] Do not touch `skills/octocode-research/evals/cases.json`'s `binaryQuestions` field — confirmed unrelated (it names true/false eval questions, not this tool; see `RESOURCES.md`)

### Phase 8: Benchmarks
- [ ] `packages/octocode-benchmark/BENCHMARK.md:274`: remove the "Binary/archive" row
- [ ] `packages/octocode-benchmark/docs/BENCHMARKS.md:20,264`: remove `localBinaryInspect` mentions and the comparison-matrix row
- [ ] `packages/octocode-benchmark/benchmark/cli/check-cli-metadata.mjs:398,729-733`: drop `'unzip'` from the quick-command list and remove the `artifacts` metadata fixture
- [ ] Update `packages/octocode-benchmark/benchmark/octocode/run-live-smoke.mjs`, `validate-output-runs.mjs`, `README.md`, and `local/README.md` for any `artifacts`/`localBinaryInspect` fixtures or assertions

### Phase 9: Full verification
- [ ] `yarn build && yarn test && yarn lint && yarn typecheck` — zero remaining references confirmed by `yarn typecheck` failing loudly on any missed import (RFC §Drawbacks "Failure trigger")
- [ ] `yarn workspace @octocodeai/octocode-engine test:rust`
- [ ] `node packages/octocode/out/octocode.js tools` — confirm 12 tools, no `localBinaryInspect`
- [ ] `node packages/octocode/out/octocode.js --help` — confirm no `unzip` quick command
- [ ] `node packages/octocode/out/octocode.js search app.zip --target artifacts` — confirm a clean "unsupported target" failure, not a crash

## Files, APIs, and Contracts

| Surface | Change | Blast-radius evidence | Compatibility |
|---|---|---|---|
| MCP tool `localBinaryInspect` | Deleted | `packages/octocode-mcp/src/tools/local_binary_inspect/register.ts`; `toolConfig.ts:32,65,113-115`; `manifest.json:82` | Breaking — no shim |
| CLI command `unzip` | Deleted | `packages/octocode/src/cli/commands/unzip.ts`; `commands/index.ts:21`; `main-help.ts:24,190` | Breaking — no shim |
| OQL `target:artifacts` | Deleted | 9 `oql/*` files + 3 CLI `search/*` files (§Steps Phase 4) | Breaking — query becomes invalid, fails as any unsupported target does |
| `ToolErrors.binaryFileUnsupported` message | Edited (code/behavior unchanged, wording changed) | `errorFactories.ts:69-74`; `errorFactories.test.ts:16-24` | Non-breaking for consumers keyed on `errorCode`; breaking for any consumer string-matching the removed clause (none found in-repo) |
| `paths.binary`/`paths.unzip`, `cache clear --binary/--unzip`, `status` cache report rows | Deleted | `shared/paths.ts:37,39,75-87`; `cli/commands/status.ts`; `cli/commands/cache.ts` | Breaking for scripts using these flags; pre-existing on-disk dirs orphaned (documented, not migrated — RFC §Unresolved Questions) |
| `octocode-engine` native ABI (`inspectBinaryNative`, `extractBinaryStringsNative`, `BinaryInspectInfo`, `BinaryStrings`) | Deleted | `index.d.ts:60,90,125,138`; `bindings/tasks.rs:137-176` | Breaking at the native boundary — requires rebuild, not hot-swappable |
| Security allowlist (13 shell commands) | Deleted | `securityConstants.ts:8-21`; `commandValidator.ts:339-382` | Reduces attack surface; no other feature depended on these commands (confirmed) |

## Risk Mitigations

| RFC risk/pre-mortem | Preventive action | Detection |
|---|---|---|
| Dangling doc/skill reference to a deleted tool | Phases 6-7 enumerate every known file by exact grep hit; re-run the same `localBinaryInspect\|unzip\|target:artifacts` grep after Phase 8 and require zero hits outside git history/CHANGELOG | Final grep sweep in Phase 9, before calling the change done |
| Missed OQL wiring point leaves a partial `'artifacts'` branch | Delete `'artifacts'` from the target union type first (Phase 4, step 1) so TypeScript's exhaustiveness checks on `switch`/map literals surface every remaining `case`/entry as a type error | `yarn typecheck` after each Phase 4 step |
| Native ABI mismatch after engine rebuild | Explicit `yarn build:native:all` + `yarn platforms:check` step (Phase 1) before any JS-side code is written against the new `index.d.ts` | `yarn platforms:check` |
| Error-message test regression (the one non-obvious dependency) | Called out explicitly in Resolved Questions and Phase 3; edited in the same commit as the deletion, not left for a follow-up | `errorFactories.test.ts` run in Phase 3 and Phase 9 |
| Orphaned `~/.octocode/tmp/binary` and `~/.octocode/tmp/unzip` confuse a future contributor into thinking the feature still exists | One-line note in release/CHANGELOG text (Phase 6 doc pass) stating these directories are dead and safe to delete manually | Reviewer checklist item, not automated |

## Test and Verification Plan

| Type | Scope | Approach | Command |
|---|---|---|---|
| Unit | `octocode-tools-core` tool catalog, OQL engine, error factories, paths | Delete tool/target-specific tests; update tests that enumerate all tools/targets to the new counts | `yarn workspace @octocodeai/octocode-tools-core test` |
| Unit | `octocode-mcp` registration, schema contracts, sanitization | Update all-tools enumeration tests to 12 tools | `yarn workspace @octocodeai/mcp test` |
| Unit | `octocode` CLI commands (`unzip`, `search`, `status`, `cache`) | Delete `unzip` command tests; update `search`/`status`/`cache` tests | `yarn workspace octocode test` |
| Unit | Rust engine `binary` module removal | Confirm no remaining reference; engine test suite still green | `yarn workspace @octocodeai/octocode-engine test:rust` |
| Integration | Full monorepo build/lint/typecheck | Confirms no orphaned import anywhere (the primary safety net per RFC §Drawbacks) | `yarn build && yarn lint && yarn typecheck` |
| Manual/CLI smoke | Real CLI behavior post-`build:dev` | Per `AGENTS.md` "rebuild → real CLI/MCP/skill path" — do not claim done from compile alone | `node packages/octocode/out/octocode.js tools`; `--help`; `search app.zip --target artifacts` |
| Native | Platform matrix | Confirms native module still loads on all shipped targets after ABI change | `yarn build:native:all && yarn platforms:check` |

Verification asks whether the build matches this plan; validation (`KPI.md`) asks whether the removal is actually complete and clean in the shipped artifact.

## Rollout, Migration, and Rollback

- Sequence: Phases 0-9 in order, as a single logical change (may be split into reviewable commits along phase boundaries, but should land together — a half-removed tool is worse than the tool intact). Observable proceed signal: `yarn typecheck` passes after each phase.
- No flag/canary/percentage gate — per `RFC.md` §Non-Goals, this ships as a hard removal, not a staged rollout. The only "gate" is the Phase 9 full verification pass.
- Rollback trigger: if `yarn platforms:check` fails post-native-rebuild (Phase 1) and cannot be fixed within the same change, `git revert` the whole change — there is no partial-rollback path once the native module is rebuilt, because the ABI change is atomic.
- Owner/approver: implementer opens the change; repo owner approves per normal review (no special approval process defined for this repo beyond standard PR review).

## Critical References

- `packages/octocode-tools-core/src/tools/toolConfig.ts:340-355` — the `ALL_TOOLS` array whose length (13→12) is the single most load-bearing assertion across the test suite; every "enumerate all tools" test keys off this.
- `packages/octocode-tools-core/src/oql/types/targets.ts:18,41` — deleting `'artifacts'` here first makes TypeScript find every other OQL touchpoint via exhaustiveness/type errors, turning Phase 4 into a compiler-guided checklist rather than a pure grep exercise.
- `packages/octocode-tools-core/src/errors/errorFactories.ts:69-74` and its test at `tests/errors/errorFactories.test.ts:16-24` — the one place this removal is a content edit, not a deletion; easy to miss if working purely from "delete these files" instinct.
- `AGENTS.md` §Tools table — the canonical "13 always-on tools" claim that must be corrected to 12, since this file is read by every future agent session in this repo.
