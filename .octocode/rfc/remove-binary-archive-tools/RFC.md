# RFC: Full Removal of Binary/Archive Tooling (`localBinaryInspect`, CLI `unzip`, OQL `target:artifacts`)

Status: Draft
Decision type: Irreversible (public tool/CLI/schema surface removed; no backward-compat shim)
Author(s): AI agent (octocode-rfc-generator), on request
Created / Updated: 2026-07-12 / 2026-07-12

## Summary

Fully remove the binary/archive inspection surface from Octocode — the `localBinaryInspect` MCP+CLI tool, the CLI `unzip` quick command, the OQL `target:artifacts` lane, the native Rust `binary` engine module (`goblin`-backed inspect/strings), and the shell-exec archive/decompress backends (`unzip`/`tar`/`7z`/`bsdtar`/`zcat`/… ) — across `octocode-mcp`, `octocode` (CLI), `octocode-tools-core`, `octocode-engine`, docs, tests, benchmarks, and the `skills/octocode-research` skill. This is a full deletion, not a deprecation: no compatibility shim, no flag to re-enable.

## Goals and Non-Goals

- Goal: `localBinaryInspect` no longer exists as an MCP tool, a CLI `tools` entry, or a direct-tool-catalog entry, in either package (`octocode-mcp`, `octocode`).
- Goal: CLI `unzip` quick command is removed; `search`/`context`/`main-help` no longer advertise it.
- Goal: OQL `target:artifacts` (schema, planner routing, shorthand, transformer, continuations, CLI `search --target artifacts`/`--artifact-mode` shorthand) is removed from `octocode-tools-core`'s OQL engine.
- Goal: `octocode-engine`'s native `binary` module (`mod.rs`/`inspect.rs`/`strings.rs`/`read.rs`/`types.rs`, napi bindings, `goblin` dependency) is deleted; no native symbol/export remains in `index.d.ts`.
- Goal: The shell-exec archive/decompress command allowlist (`unzip`, `tar`, `bsdtar`, `7z`, `7zz`, `zcat`, `gunzip`, `bzcat`, `xzcat`, `zstdcat`, `zstd`, `lz4cat`, `brotli`, `lzfse`) is removed from `octocode-engine`'s `commandValidator`/`securityConstants`.
- Goal: All docs (`docs/OCTOCODE_TOOLS.md`, `OCTOCODE_MCP.md`, `OCTOCODE_CLI.md`, `OQL_LANGUAGE_REFERENCE.md`, `OQL_INTERNALS.md`, `OCTOCODE_QUERY_LANGUAGE.md`, `CONFIGURATION.md`, `OCTOCODE_RESEARCH_MANIFEST.md`, `AGENTS.md`, `README.md`) and the `octocode-research` skill (`references/octocode.md`, `workflow-local.md`, `workflow-external.md`, `code-research.md`, `research-flow.md`, `algorithm.md`) drop every mention, with tool counts corrected (13 → 12 always-on local/default tools).
- Goal: The dangling cross-tool reference in `ToolErrors.binaryFileUnsupported` (which currently tells users to run `localBinaryInspect`) is reworded, not left pointing at a deleted tool.
- Non-goal: `localSearchCode`'s own `mode` field and description text are untouched — its `mode` enum (`paginated`/`discovery`/`detailed`/`structural`) only *mentions* `localBinaryInspect` in a disambiguation comment (`packages/octocode-tools-core/src/tools/local_ripgrep/scheme.ts:38-46`); no shared code path exists. That comment is trimmed, the tool itself is not touched.
- Non-goal: `paths.clone`/`paths.tree`/clone-and-materialize flows (`ensureClone`, `ensureTree`, github clone/cache) are untouched — they are separate cache subtrees in `packages/octocode-tools-core/src/shared/paths.ts:27-42` with no code path through `local_binary_inspect`.
- Non-goal: no migration shim, feature flag, or deprecation window — this repo's convention is "No backward compat by default — refactor freely" (`AGENTS.md`).

## Motivation and Current State

The user directive is explicit: *"FULL removal of unzip in npx octocode, FULL removal of binary tools and schemes, impl, docs and all (MCP + CLI), REMOVE also from skills."* This is a scope directive, not a bug fix — the current code is working as designed; the decision is to delete the capability entirely rather than fix or narrow it.

Current state, confirmed by direct reads:

- CLI `unzip` (`packages/octocode/src/cli/commands/unzip.ts:46-56`) is a thin wrapper that calls `executeDirectTool` with tool name `'localBinaryInspect'` and mode `'unpack'` — it has no logic of its own; deleting `localBinaryInspect` strands it immediately.
- `localBinaryInspect` is registered as one of the 13 always-on default tools in both packages: `packages/octocode-tools-core/src/tools/toolConfig.ts:311-322,340-355` (`LOCAL_BINARY_INSPECT`, `isDefault: true`, `isLocal: true`, `isBinary: true`) and `packages/octocode-mcp/src/tools/toolConfig.ts:32,65,113-115` (MCP fn map) plus `packages/octocode-mcp/src/tools/local_binary_inspect/register.ts:9-15`.
- Its six modes split into two backend families:
  - `inspect`/`strings` → native Rust engine, no shell-exec: `packages/octocode-tools-core/src/tools/local_binary_inspect/binaryOps.ts:11-78` calls `contextUtils.inspectBinaryNative`/`extractBinaryStringsNative` (`packages/octocode-tools-core/src/utils/contextUtils.ts:192-208`), backed by `packages/octocode-engine/src/binary/mod.rs`, `types.rs`, `inspect.rs`, `strings.rs`, `read.rs` via napi task `InspectBinaryTask`/`ExtractBinaryStringsTask` (`packages/octocode-engine/src/bindings/tasks.rs:137-176`) and the `goblin = "0.10"` crate (`packages/octocode-engine/Cargo.toml:56-62`, used nowhere else in the engine).
  - `list`/`extract`/`decompress`/`unpack` → shell-exec chains over `unzip`/`tar`/`bsdtar`/`7z`/`7zz`/`aa` and `zcat`/`gunzip`/`bzcat`/`xzcat`/`zstdcat`/`zstd`/`lz4cat`/`brotli`/`lzfse` (`packages/octocode-tools-core/src/tools/local_binary_inspect/archiveOps.ts:1-222`, `decompressOps.ts:1-197`), gated by a dedicated command allowlist and per-command argument validator in `packages/octocode-engine/src/security/securityConstants.ts:8-21` and `commandValidator.ts:339-382`.
- The OQL `target:artifacts` lane is a direct wrapper: `packages/octocode-tools-core/src/oql/adapters/researchTargets/artifacts.ts:1-64` calls `runDirect('localBinaryInspect', ...)`. It is wired through `oql/types/targets.ts:18,41` (`ACTIVE_TARGETS`), `oql/adapters/researchTargets.ts:31,56` (registration), `oql/planner/predicateRouting.ts:199-200`, `oql/shorthand/target-params.ts:105-108`, `oql/transformers/registry.ts:248-262`, `oql/targetParams.ts:159,249`, `oql/schemeText.ts:12,17,28,34,58,89-90,152,182-183`, and `oql/run/continuations/records.ts:138-208` (`next.artifactStrings`/`next.artifactContent`). The CLI's `search` shorthand parses it too: `packages/octocode/src/cli/commands/search/shorthandParts.ts:27,57,263-270`, `targetInference.ts:16,53,56`, `inputParsing.ts:24`.
- Dedicated cache directories exist only for this feature: `paths.binary` and `paths.unzip` (`packages/octocode-tools-core/src/shared/paths.ts:37,39`), surfaced in CLI `status`/`cache` (`packages/octocode/src/cli/commands/status.ts:67-181`, `cache.ts:113-257`) for size reporting and `cache clear --binary/--unzip`.
- One error message currently *depends on the tool existing*: `ToolErrors.binaryFileUnsupported` (`packages/octocode-tools-core/src/errors/errorFactories.ts:69-74`), raised by `local_fetch_content/fetchContent/validation.ts:155` when `localGetFileContent` hits a binary file, says *"Use localBinaryInspect to read its format/strings…"* — this is the one place removal changes *behavior text*, not just deletion.
- Docs/skill footprint is large and mostly enumerable, not exploratory: 17 hits in `docs/OCTOCODE_TOOLS.md` (a whole "Binary Tools Reference" section, `docs/OCTOCODE_TOOLS.md:700-864`, plus a Tool Inventory row and ToC entry), plus `OCTOCODE_MCP.md:79`, `packages/octocode/docs/OCTOCODE_CLI.md:23,75,131,262-266`, `OQL_LANGUAGE_REFERENCE.md`, `OQL_INTERNALS.md`, `docs/OCTOCODE_QUERY_LANGUAGE.md`, `docs/CONFIGURATION.md`, `docs/OCTOCODE_RESEARCH_MANIFEST.md`, `AGENTS.md` (this file's own "Always-on (13)" table), root `README.md`, `packages/octocode-mcp/manifest.json:82`, `packages/octocode-pi-extension/src/constants.ts:18`, `src/subagents.ts:150-220`, `src/tools/render-helpers.ts:216-231`, `src/prompts/sections/tools.md:16`, `src/prompts/sections/octocode-cli.md:9`, `packages/octocode-mcp/sanity_tests/localBinaryInspect.md`, `sanity_tests/README.md`, and six files under `skills/octocode-research/references/`: `octocode.md:18,39`, `workflow-local.md:16,19`, `workflow-external.md:19-20`, `code-research.md:16`, `research-flow.md:25`, `algorithm.md:15`.
- Cost of doing nothing: none from a correctness standpoint (the feature works); the cost is scope mismatch with the explicit user directive to remove it entirely, plus continued exposure to a shell-exec allowlist (13 external archive/decompress binaries) that the org has decided it no longer wants to carry.

## Guide-Level Explanation

After this change:
- `npx octocode unzip <archive>` → unknown command (removed from `QUICK_COMMAND_NAMES`, `commands/index.ts`, `main-help.ts`).
- `tools localBinaryInspect ...` (MCP or CLI) → tool not found; it is absent from `tools --json`/`tools --scheme` listings and the MCP tool list.
- `search <archive> --target artifacts ...` (OQL shorthand) → `artifacts` is no longer a valid `--target`; CLI `targetInference` no longer infers it from archive extensions.
- `localGetFileContent`/`localSearchCode` on a binary file still refuse to return it as text (unchanged behavior), but the error message no longer names a tool that doesn't exist.
- `octocode status`/`octocode cache` no longer report or clear a `binary`/`unzip` cache bucket; any pre-existing `~/.octocode/tmp/binary` or `~/.octocode/tmp/unzip` directories from prior installs are orphaned on disk (user-owned, harmless, not auto-cleaned — see Unresolved Questions).
- Agents following `skills/octocode-research` no longer see binary/archive routing guidance; the "binary/archive" row in its decision tables is deleted, not replaced (no alternative tool is being introduced by this RFC).

## Reference-Level Explanation

Five architectural layers change, each independently deletable and independently testable (dependency order matters for the build, not for the decision):

1. **Rust engine (`octocode-engine`)** — delete `src/binary/*.rs`, the `mod binary;` declarations in `src/lib.rs:1` and `src/bindings/mod.rs:1,15`, `InspectBinaryTask`/`ExtractBinaryStringsTask` in `src/bindings/tasks.rs:137-176`, the `goblin` dependency in `Cargo.toml:56-62` (and `Cargo.lock` entry), and the generated `inspectBinaryNative`/`extractBinaryStringsNative`/`BinaryInspectInfo`/`BinaryStrings` symbols in `index.d.ts` and `loader/index.d.ts` (regenerated by the napi build, not hand-edited).
2. **Security allowlist (`octocode-engine`)** — delete the 13-command block in `securityConstants.ts:8-21` and its per-command argument validators in `commandValidator.ts:339-382` (`zcat`/`bzcat`/`zstdcat`/`lz4cat`/`gunzip`/`xzcat`/`zstd`/`brotli`/`lzfse`/`tar`/`bsdtar`/`unzip`/`7z`/`7zz`). No other feature calls these commands (confirmed: `archiveOps.ts`/`decompressOps.ts` are the only callers of `safeExec` with these command names in the repo).
3. **Tool implementation (`octocode-tools-core`)** — delete `src/tools/local_binary_inspect/**` (8 files: `binaryInspector.ts`, `binaryInspector/handlers.ts`, `binaryInspector/helpers.ts`, `scheme.ts`, `execution.ts`, `archiveOps.ts`, `decompressOps.ts`, `binaryOps.ts`) and its tests (`tests/tools/local_binary_inspect/inspect.test.ts`, `strings-match.test.ts`); remove its `TOOL_NAMES`/`STATIC_TOOL_NAMES` entry (`toolNames.ts:24`), its `toolConfig.ts` registration (13→12 `ALL_TOOLS`), its `toolSchemaImports.ts` exports, its `index.ts` re-exports (`index.ts:65-66`), its `directToolCatalog` entry (`toolCatalogDefinitions.ts:39-41,225-228`) and command-pattern examples (`toolCommandPatternQueries.ts`), and reword `errorFactories.ts:72`'s dangling tool reference. Remove `paths.binary`/`paths.unzip`/`ensureBinary`/`ensureUnzip` (`shared/paths.ts:37,39,75-87`).
4. **OQL engine (`octocode-tools-core`)** — remove `'artifacts'` from `oql/types/targets.ts` (`OqlActiveTarget`, `ACTIVE_TARGETS`), delete `oql/adapters/researchTargets/artifacts.ts` and its registration in `researchTargets.ts:31,56`, remove the `case 'artifacts'` branches in `planner/predicateRouting.ts:199-200` and `shorthand/target-params.ts:105-108`, the `local.artifacts` entry in `transformers/registry.ts:248-262`, `artifactsParams`/`artifacts` in `targetParams.ts:159,249`, all artifact prose in `schemeText.ts`, and `buildArtifactContinuations`/`next.artifactStrings`/`next.artifactContent` in `run/continuations/records.ts:138-208`.
5. **Interfaces (`octocode-mcp`, `octocode`)** — remove MCP registration (`register.ts`, `toolConfig.ts` fn map/exports) and manifest entry (`manifest.json:82`); remove CLI `unzip` command (`commands/unzip.ts`, `commands/index.ts:21`, `main-help.ts:24,190`, `tool-command/context.ts:69`, `tool-command/formatting.ts`), CLI `search` artifact shorthand (`commands/search/shorthandParts.ts`, `targetInference.ts`, `inputParsing.ts`), and `status.ts`/`cache.ts` binary/unzip cache-bucket reporting.

Edge cases and compatibility: this is a breaking change to the MCP tool list, the CLI command surface, and the OQL grammar (`target:artifacts` becomes an invalid query — the planner should reject it the same way it rejects any unknown target today, no special-cased error needed). No data migration is required; no persisted state has a schema that names `localBinaryInspect`.

## Drawbacks and Pre-mortem

- **Capability loss**: agents lose the ability to inspect native binaries (ELF/Mach-O/PE/COFF), list/extract archive entries, decompress single streams, or bulk-unpack archives through Octocode. Users must fall back to raw shell commands outside Octocode. This is the explicit intent, not a side effect.
- **Dangling guidance risk**: every doc/skill reference must be *removed*, not left as a broken link or a "use X" pointer to a deleted tool — the `binaryFileUnsupported` error message is the one place this is easy to miss (flagged in Files/APIs/Contracts, `IMPLEMENTATION.md`).
- **OQL grammar surface**: `target:artifacts` touches 9 files inside the OQL engine (targets/planner/shorthand/transformer/params/schemeText/continuations) plus 3 CLI files — the highest count of any single removal in this RFC and the most likely place to leave an orphaned branch or stale test fixture (`oql/artifact-continuations.test.ts`, `oql/v2-targets.test.ts`, `oql/parity-gaps.test.ts`, `oql/open-gaps-materialize.test.ts`, `scheme/scheme-text.test.ts`, `cli/commands/search.test.ts` — see `RESOURCES.md`).
- **Native build surface**: removing `goblin` and the napi bindings changes the compiled `.node` binary and its `index.d.ts`; every platform target (`yarn build:native:all`) must be rebuilt and `yarn platforms:check` must still pass, or downstream packages will load a stale/mismatched native module.
- **Orphaned disk state**: pre-existing users' `~/.octocode/tmp/binary` and `~/.octocode/tmp/unzip` directories are not cleaned by this change (see Unresolved Questions) — low severity (user-owned tmp dir, no secrets), but worth a one-line doc/CHANGELOG note.
- **Failure trigger**: if any test outside the deleted set still imports a deleted symbol (`BinaryInspectInfo`, `executeInspectBinary`, `LOCAL_BINARY_INSPECT`, `'artifacts'` as a `TargetLiteral`), the typecheck fails loudly at `yarn typecheck`/`yarn build` — this is the primary safety net, not a runtime risk.

## Rationale and Alternatives

| Option | Fit with directive | Complexity | Security/maintenance | Reversibility |
|---|---|---|---|---|
| **A. Full removal now (chosen)** | Exact match — "FULL removal" stated twice | High one-time cost (5 layers, ~90 touched files); zero ongoing cost after | Drops 13-command shell-exec allowlist + `goblin` native surface entirely | Irreversible without re-authoring; git history preserves the code |
| B. Deprecate-then-remove (mark tool deprecated, keep working one release, delete next) | Contradicts directive; adds a step not asked for | Extra release cycle, extra deprecation-notice code, dead code lingers | Shell-exec surface stays live during the deprecation window | Reversible during the window, at the cost of doing the removal twice |
| C. Partial removal (drop shell-exec archive/decompress `list`/`extract`/`decompress`/`unpack`, keep native `inspect`/`strings`) | Contradicts "FULL removal of binary tools" — leaves a tool, a schema, and native code behind | Lower (only layers 2 and part of 3) | Removes the largest security surface (external binaries) but keeps `goblin`/native inspect | Easiest to reverse, but not what was asked |
| D. Do nothing | Contradicts directive entirely | None | No change | N/A |

Recommendation: **A**. The directive is unambiguous ("FULL removal... FULL removal... impl, docs and all... REMOVE also from skills"), the repo's stated convention is no-backward-compat refactoring by default, and the isolation evidence above (every dependency chain terminates inside `local_binary_inspect`/`binary` engine module/`target:artifacts`, with exactly one cross-cutting text reference) shows the removal is mechanically clean, not entangled with other features.

## Prior Art

Not applicable as an external-prior-art question — this is a scope decision about an existing, working, in-repo feature, not a design choice needing outside comparison. See `RESOURCES.md` for the full local-code inventory that grounds the blast-radius claims above.

## Unresolved Questions

- [ ] Should removal include a one-time CLI notice or doc line telling existing users how to manually delete orphaned `~/.octocode/tmp/binary` and `~/.octocode/tmp/unzip` directories, given `cache clear --binary/--unzip` goes away? — Owner: implementer; resolved in `IMPLEMENTATION.md` (deferred: document only, no code, since these are plain tmp dirs under `paths.tmp` and `cache clear --all` still exists via the remaining buckets).
- [ ] Does removing `goblin`/the napi `binary` module require a native rebuild + `yarn platforms:check` across all shipped platform targets before publish, or can it ship JS-only until the next scheduled native release? — Owner: implementer; resolved in `IMPLEMENTATION.md` with an explicit rebuild step (native ABI changes on every platform target).
- [ ] Is a semver-major bump warranted for `octocode` (currently `1.0.2`) and `@octocodeai/mcp` (currently `1.0.2`) given a public tool and CLI command are deleted? — Owner: release owner; resolved in `IMPLEMENTATION.md` §Rollout as a recommendation, not a blocking gate (no CHANGELOG convention exists in this repo outside `packages/octocode-vscode/CHANGELOG.md`).

## Future Possibilities

Out of scope for this RFC by definition (full removal, not replacement). If a future need for binary/archive inspection resurfaces, it would be a new RFC, not a revival of this code path.
