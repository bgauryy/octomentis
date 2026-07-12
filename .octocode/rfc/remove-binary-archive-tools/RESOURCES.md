# Resources: Full Removal of Binary/Archive Tooling

## Primary Sources

| Resource | Link or path | Why it matters |
|---|---|---|
| Tool catalog (core) | `packages/octocode-tools-core/src/tools/toolConfig.ts` | Single source of the 13→12 always-on tool list; every registration/removal traces back here |
| Tool catalog (MCP) | `packages/octocode-mcp/src/tools/toolConfig.ts` | MCP-specific fn-map wiring on top of the core catalog |
| `localBinaryInspect` implementation | `packages/octocode-tools-core/src/tools/local_binary_inspect/` (8 files) | The entire tool being deleted: `binaryInspector.ts`, `binaryInspector/handlers.ts`, `binaryInspector/helpers.ts`, `scheme.ts`, `execution.ts`, `archiveOps.ts`, `decompressOps.ts`, `binaryOps.ts` |
| Rust native `binary` module | `packages/octocode-engine/src/binary/mod.rs`, `types.rs`, `inspect.rs`, `strings.rs`, `read.rs` | Native inspect/strings backend; `goblin`-based, deleted alongside the JS tool |
| napi bindings | `packages/octocode-engine/src/bindings/tasks.rs:137-176`, `bindings/mod.rs:1,15`, `src/lib.rs:1` | Exposes the Rust module to JS; must be unwired before the module is deleted |
| Security allowlist | `packages/octocode-engine/src/security/securityConstants.ts:8-21`, `commandValidator.ts:339-382` | Gates the shell-exec archive/decompress backends; the entire attack-surface reduction this removal buys |
| OQL `target:artifacts` adapter | `packages/octocode-tools-core/src/oql/adapters/researchTargets/artifacts.ts` | Direct 1:1 wrapper over `localBinaryInspect`; proves the OQL target has no independent value once the tool is gone |
| CLI `unzip` command | `packages/octocode/src/cli/commands/unzip.ts` | Thin wrapper with zero logic beyond calling `localBinaryInspect`; confirms it cannot survive the tool's removal |

## Local Code References

| Area | File and lines | Decision relevance |
|---|---|---|
| Tool registration (core) | `packages/octocode-tools-core/src/tools/toolConfig.ts:311-322,340-355` | `LOCAL_BINARY_INSPECT` construction and its place in `ALL_TOOLS` |
| Tool registration (MCP) | `packages/octocode-mcp/src/tools/toolConfig.ts:32,65,113-115`; `packages/octocode-mcp/src/tools/local_binary_inspect/register.ts:1-16` | MCP fn-map entry and registration file to delete |
| Tool names | `packages/octocode-tools-core/src/tools/toolNames.ts:24` | `STATIC_TOOL_NAMES.LOCAL_BINARY_INSPECT` constant |
| Schema exports | `packages/octocode-tools-core/src/tools/toolSchemaImports.ts:29-30`; `src/index.ts:65-66` | Re-export surface consumed by both interface packages |
| Direct-tool catalog | `packages/octocode-tools-core/src/tools/directToolCatalog/toolCatalogDefinitions.ts:39-41,225-228`; `toolCommandPatternQueries.ts` | Powers CLI `tools localBinaryInspect --queries` direct execution and its example patterns |
| Error message dependency | `packages/octocode-tools-core/src/errors/errorFactories.ts:69-74`; test at `tests/errors/errorFactories.test.ts:16-24`; raised at `src/tools/local_fetch_content/fetchContent/validation.ts:155` | The one non-deletable, must-reword cross-tool text dependency |
| Cache paths | `packages/octocode-tools-core/src/shared/paths.ts:27-42,75-87` | `paths.binary`/`paths.unzip`, `ensureBinary`/`ensureUnzip`; isolated from `paths.clone`/`paths.tree` |
| `local_ripgrep` name collision (non-goal) | `packages/octocode-tools-core/src/tools/local_ripgrep/scheme.ts:36-46` | Explicit in-code comment proving `mode` field overlap is naming-only, not a code dependency |
| OQL target union | `packages/octocode-tools-core/src/oql/types/targets.ts:8-46` | `'artifacts'` in `OqlActiveTarget`/`ACTIVE_TARGETS`; deleting first drives exhaustiveness-check-guided cleanup |
| OQL target registration | `packages/octocode-tools-core/src/oql/adapters/researchTargets.ts:31,56` | Wires `executeArtifacts` into the target dispatch map |
| OQL planner | `packages/octocode-tools-core/src/oql/planner/predicateRouting.ts:199-200` | `case 'artifacts': return 'inspectArtifact';` |
| OQL shorthand | `packages/octocode-tools-core/src/oql/shorthand/target-params.ts:105-108` | CLI shorthand-to-params lowering for `artifacts` |
| OQL transformer registry | `packages/octocode-tools-core/src/oql/transformers/registry.ts:248-262` | `local.artifacts` entry (`recordType: 'artifact'`, `adapterFunctions: ['executeArtifacts']`) |
| OQL target params schema | `packages/octocode-tools-core/src/oql/targetParams.ts:159,249` | `artifactsParams` zod schema and its map entry |
| OQL scheme text | `packages/octocode-tools-core/src/oql/schemeText.ts:12,17,28,34,58,89-90,152,182-183` | All natural-language prose describing `artifacts` to the OQL planner/agent |
| OQL continuations | `packages/octocode-tools-core/src/oql/run/continuations/records.ts:3,138-208` | `buildArtifactContinuations`, `next.artifactStrings`, `next.artifactContent` |
| CLI search shorthand | `packages/octocode/src/cli/commands/search/shorthandParts.ts:27,57,263-270`, `targetInference.ts:16,53,56`, `inputParsing.ts:24` | `--artifact-mode`, `--extract`, extension-based target inference to `'artifacts'` |
| CLI unzip/help wiring | `packages/octocode/src/cli/commands/unzip.ts`, `commands/index.ts:21`, `main-help.ts:24,190`, `tool-command/context.ts:69`, `tool-command/formatting.ts` | Quick-command registration and help text |
| CLI status/cache | `packages/octocode/src/cli/commands/status.ts:67-181`, `cache.ts:113-257` | Binary/unzip cache-bucket size reporting and `cache clear --binary/--unzip` |
| Rust engine binary module | `packages/octocode-engine/src/binary/mod.rs`, `types.rs`, `inspect.rs`, `strings.rs`, `read.rs` | Full native implementation being deleted |
| Rust napi tasks | `packages/octocode-engine/src/bindings/tasks.rs:137-176` | `InspectBinaryTask`, `ExtractBinaryStringsTask` |
| Rust module wiring | `packages/octocode-engine/src/lib.rs:1`; `src/bindings/mod.rs:1,15` | `mod binary;` declarations |
| Rust dependency | `packages/octocode-engine/Cargo.toml:56-62` | `goblin = "0.10"`, confirmed used nowhere else in the crate |
| Generated native types | `packages/octocode-engine/index.d.ts:60,90,125,138`; `loader/index.d.ts` | `BinaryInspectInfo`, `BinaryStrings`, `inspectBinaryNative`, `extractBinaryStringsNative` — regenerated by napi build, not hand-edited |
| MCP manifest | `packages/octocode-mcp/manifest.json:82` | `mcp_octocode_localBinaryInspect` entry |
| MCP sanity tests | `packages/octocode-mcp/sanity_tests/localBinaryInspect.md`, `sanity_tests/README.md` | Dedicated sanity doc to delete; README index to trim |

## Test Inventory (update or delete, per `IMPLEMENTATION.md`)

| Package | Files |
|---|---|
| `octocode-tools-core` | Delete: `tests/tools/local_binary_inspect/inspect.test.ts`, `tests/tools/local_binary_inspect/strings-match.test.ts`. Update: `tests/tools/directToolCatalog.commandPatterns.test.ts`, `tests/tools/outputSchemaContract.test.ts`, `tests/scheme/outputSchemas.test.ts`, `tests/scheme/crossToolFieldDisambiguation.test.ts`, `tests/errors/errorFactories.test.ts`, `tests/shared/paths/paths.test.ts`, `tests/oql/v2-targets.test.ts`, `tests/oql/artifact-continuations.test.ts`, `tests/oql/open-gaps-materialize.test.ts`, `tests/oql/parity-gaps.test.ts`, `tests/scheme/scheme-text.test.ts` (delete artifact-specific cases within) |
| `octocode-mcp` | Update: `tests/tools/toolConfig.test.ts`, `toolConfig.branches.test.ts`, `toolMetadata.final.test.ts`, `all-tools.pagination-contract.test.ts`, `stats_emission_contract.test.ts`, `tests/scheme/all-tools.schema-contract.test.ts`, `tests/security/all-tools-sanitization.test.ts`, `tests/setup.ts`, `tests/tools/local_fetch_content.test.ts:707` (asserts the surviving error code, not the removed wording) |
| `octocode` (CLI) | Update: `tests/cli/commands/status.test.ts`, `tests/cli/command-spec-coverage.test.ts`, `tests/cli/tool-command.test.ts`, `tests/cli/help-modules.test.ts`, `tests/cli/commands/search.test.ts`, `vitest.config.ts` (check for `unzip`/`binary` path references) |
| `octocode-engine` | `tests/security/commandValidator.test.ts`, `tests/ffi.test.ts` |
| `octocode-pi-extension` | `tests/render-helpers.test.ts`, `tests/package.test.ts` |

## Prior Art and Related Systems

Not applicable — this RFC is a scope decision on existing in-repo code, not a design choice requiring external prior art (see `RFC.md` §Prior Art).

## Internal Research Artifacts

| Artifact | Path | What it supports |
|---|---|---|
| None pre-existing | — | No prior `.octocode/rfc/` entry covers this removal; checked `.octocode/rfc/RFC-cli-issues-fixes.md`, `RFC-engine-lsp-production.md`, `RFC-octocode-ingest.md`, and `storage-persistence-controls/` for `unzip`/`binary`/`localBinaryInspect` — no conflicting or overlapping claims found |

## Open Research Leads

- Whether any external (non-monorepo) consumer of the published `@octocodeai/mcp` or `octocode` npm packages scripts against `localBinaryInspect`/`unzip`/`target:artifacts` — out of scope to research from inside this repo; addressed procedurally via the semver/release-notes recommendation in `IMPLEMENTATION.md` §Rollout rather than left as a blocking unknown.
- Whether `packages/octocode-benchmark/benchmark/octocode/run-live-smoke.mjs` and `validate-output-runs.mjs` contain artifact/binary fixtures beyond what a targeted grep at implementation time will surface — flagged as a Phase 8 catch-all rather than fully enumerated here, since benchmark scripts are not decision-gating.

## Reproducible Search Prompts

- `rg -i "localBinaryInspect|LOCAL_BINARY_INSPECT|BinaryInspect|binaryInspect"` — full-repo enumeration used to build this RFC's blast-radius claims (~95 files at research time).
- `rg -i "\bunzip\b"` — CLI/quick-command and archive-backend surface.
- `rg "target:\s*\"?artifacts\"?|'artifacts'|\"artifacts\""` — OQL `target:artifacts` wiring across the OQL engine and CLI `search`.
- `rg "crate::binary|goblin"` under `packages/octocode-engine/src` — confirms Rust-side isolation before deleting `Cargo.toml`'s `goblin` dependency.
