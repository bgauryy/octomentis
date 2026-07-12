# Opportunities for a Stronger `octocode-engine` Agent Research Core

## Goal

Make `packages/octocode-engine` a stronger native engine for AI-agent code research: better parsing, better minification, better LSP anchoring, better AST/structural search, and better context packaging for agents that must understand real codebases without guessing.

This document synthesizes lessons from:

- `context-aware-scanning-for-parsing-extensible-languages_summary.md`
- `efficient-and-flexible-incremental-parsing_summary.md`
- `incremental-analysis-of-real-programming-languages_summary.md`
- `practical-algorithms-for-incremental-software-development-environments_summary.md`

It is grounded in the current engine shape:

- Rust native API root: `packages/octocode-engine/src/lib.rs`
- public native declarations: `packages/octocode-engine/index.d.ts`
- minification bindings: `packages/octocode-engine/src/bindings/minify.rs`
- signature/symbol extraction: `packages/octocode-engine/src/signatures/mod.rs`
- structural search: `packages/octocode-engine/src/structural.rs` and `packages/octocode-engine/src/structural/`
- LSP fuzzy symbol resolver: `packages/octocode-engine/src/lsp/resolver.rs`

## Executive summary

The best direction is **not** to immediately build a full IDE-scale incremental parser or custom LR/GLR stack. The high-value path is to evolve `octocode-engine` into a **versioned, structure-aware, uncertainty-preserving analysis engine** with clear line-map guarantees and pay-as-you-go parsing.

The strongest opportunities:

1. Add a shared `FileSnapshot` / `AnalysisMetadata` protocol across minification, structural search, sanitizer, ripgrep parsing, and LSP helpers.
2. Return explicit uncertainty/fallback metadata: `empty`, `unsupported`, `ambiguous`, `parserFailed`, `truncated`, `sanitized`, and `staleSnapshot` are different states.
3. Build a native **Agent Context IR**: structured slices, symbols, line maps, redaction spans, parse diagnostics, LSP evidence, and omitted-region summaries in one reusable representation.
4. Upgrade minification from “string in/string out” toward **lossy views with source maps**: every transformed byte/line should map back to original source lines.
5. Make structural search more agent-grade: better query diagnostics, AST parse diagnostics, per-file fallback metadata, language-region support, reusable parsed AST caches, and stable match IDs.
6. Improve LSP anchoring with candidate sets and ambiguity reasons instead of one fuzzy position result.
7. Treat compound documents as first-class: Markdown fences, Vue/Svelte, HTML scripts/styles, TSX/JSX, package scripts, CI YAML shell blocks.
8. Add benchmarks/evals for context quality, not only raw speed: citation fidelity, token reduction, symbol recall, fallback clarity, and agent task success.

## Motivation

Octocode is used by agents that must decide what code means before editing, reviewing, or explaining it. For agents, weak context is dangerous: a text hit can be mistaken for a semantic reference, an empty LSP result can be mistaken for proof of absence, and minified content can lose the line fidelity needed for citations.

The motivation for this roadmap is to make `octocode-engine` return **trustworthy research evidence**, not just compact strings:

- Agents need to know **what was analyzed** and **what was skipped**.
- Agents need to know whether a result is **exact, parser-backed, heuristic, fallback, partial, or unsupported**.
- Agents need compact context that still maps back to original files and lines.
- Agents need AST/LSP/minification outputs to compose into one coherent research flow.
- Agents need the native engine to own this consistency so MCP and CLI callers do not invent duplicate interpretation logic.

In product terms: the engine should reduce agent guessing. In architecture terms: the Rust core should expose structure, source mapping, diagnostics, and uncertainty as first-class data.

## Proposed changes

### Change 1 — Add result-quality metadata

Add structured status/diagnostics to new metadata-returning APIs first, then migrate callers deliberately.

Core concepts:

- status: `ok`, `partial`, `unsupported`, `ambiguous`, `parserFailed`, `fallback`, `truncated`, `stale`;
- diagnostics: stage, severity, code, message, optional range, recovery hint;
- line-map guarantee: `exact`, `range-preserving`, `line-preserving`, `none`;
- fallback info: what fallback ran, why, and what fidelity was lost.

### Change 2 — Make minification a source-faithful content view

Keep current string-returning minify functions stable, but add a metadata path that reports strategy, warnings, line-map guarantee, omitted regions, and parse/fallback reasons.

The immediate target is not a perfect source map for every strategy. The first target is honesty: never imply exact citation safety when a strategy collapsed or reshaped lines.

### Change 3 — Make structural search explainable

Extend structural search with file-level statuses, query diagnostics, stable match IDs, and node/language metadata.

The main behavior change should be interpretive, not disruptive: callers should be able to distinguish true zero matches from skipped files, unsupported languages, invalid queries, unreadable files, large-file skips, or conservative prefiltering.

### Change 4 — Make LSP anchoring return evidence strength

Keep existing `resolvePosition` behavior, but add a detailed resolver that returns candidates, chosen method, ambiguity reason, and fallback status.

Agents should know whether a line hint resolved through grammar-backed analysis or through a weaker text scan.

### Change 5 — Add compound-document regionization gradually

Introduce lightweight language regions for files that naturally contain multiple syntaxes. Start where the engine already has adjacent responsibilities: Markdown, HTML/Vue/Svelte, TSX/JSX, and YAML/script-like regions.

This should feed existing minification, structural search, sanitizer, and context-building flows rather than becoming a separate parser stack.

## Pros and cons

### Pros

- **Better agent reliability:** agents can avoid overclaiming from weak evidence.
- **Better citations:** content views can state exactly how output maps to source.
- **Better debugging:** failures and fallbacks become visible instead of hidden in empty arrays or generic strings.
- **Better architecture:** native owners remain the source of truth; TypeScript wrappers stay thin.
- **Better evolution path:** metadata APIs allow gradual migration without immediately breaking existing callers.
- **Better performance story:** snapshot/cache metadata creates a path toward bounded recomputation and reusable analysis.
- **Better security reasoning:** redaction can become an explicit span-preserving transformation rather than silent mutation.

### Cons / costs

- **More API surface:** new result types and detailed variants increase maintenance burden.
- **More payload size:** diagnostics, candidates, and line-map metadata can add tokens if not opt-in or compact.
- **More test matrix:** line-map guarantees, fallback states, and compound documents need fixtures across languages.
- **Migration complexity:** MCP/CLI tools must decide when to expose metadata versus keeping responses concise.
- **NAPI compatibility work:** new `#[napi(object)]` structs require careful TypeScript declaration and fixture tests.
- **Potential performance overhead:** metadata collection must be measured and should not slow existing string-only hot paths.
- **Risk of abstraction drift:** a global diagnostic framework can become too generic; start domain-local where possible.

## Breaking-change assessment

### Should this roadmap require breaking changes?

No, not initially. The recommended path is **additive first**:

- keep existing string-returning APIs such as `minifyContentSync`, `applyMinification`, and current LSP resolver behavior;
- add detailed/metadata-returning variants;
- let MCP/CLI migrate call sites one tool at a time;
- only remove or reshape old APIs after downstream usage is migrated and a release plan exists.

### Potential breaking changes later

Breaking changes may be justified only when old shapes actively cause incorrect agent behavior.

Potential later breaks:

1. Replacing ambiguous empty arrays with structured result objects.
2. Changing minification responses to always include mapping/fallback metadata.
3. Returning structural search skipped-file diagnostics where callers currently assume only matched files.
4. Changing LSP resolution to reject ambiguous anchors unless callers opt into fallback selection.
5. Making sanitization expose redaction spans and warning metadata by default.

### Compatibility strategy

- Prefer `fooDetailed`, `fooResult`, or `fooView` APIs before changing existing `foo` APIs.
- Keep TypeScript wrappers responsible for response compactness, not semantic reinterpretation.
- Add tests that lock old API behavior while new APIs are introduced.
- Mark old APIs as legacy only after MCP/CLI callers have migrated.
- Do not add compatibility shims that duplicate logic; wrappers should call the same Rust owner.

### Release-risk level

- PR 1 structural diagnostics: **low to medium** if added fields are optional/additive; medium if public result shapes change.
- PR 2 minify content-view metadata: **low** if introduced as a new API; high if existing string functions change.
- PR 3 detailed LSP resolver: **low** if additive; medium if callers start rejecting ambiguous anchors by default.
- Compound-document regionization: **medium to high** because it can affect output content and search scope.
- Snapshot-aware caches: **medium** because stale-cache bugs can produce misleading evidence.

## Current strengths to preserve

The engine already has the right center of gravity: Rust owns hot paths and TypeScript surfaces orchestrate tools.

Current public API evidence:

- Native LSP client and semantic primitives are exposed via `NativeLspClient` and methods such as `getDefinition`, `getReferences`, `getDocumentSymbols`, and call hierarchy operations in `packages/octocode-engine/index.d.ts:3`.
- Minification APIs already distinguish sync/async and structured results through `minifyContent`, `minifyContentResult`, and `MinifyResult` in `packages/octocode-engine/index.d.ts:365`.
- Symbol extraction and boundary support exist through `extractSignatures`, `getSemanticBoundaryOffsets`, and supported signature extension APIs in `packages/octocode-engine/index.d.ts:92` and `packages/octocode-engine/index.d.ts:290`.
- Structural search exists and returns AST match ranges plus metavars in `packages/octocode-engine/src/structural/types.rs:5`.
- File-level structural search already tracks parsed/skipped/unreadable/large counters and warnings in `packages/octocode-engine/src/structural/types.rs:34`.
- LSP fuzzy resolution already uses tree-sitter where possible before line scanning in `packages/octocode-engine/src/lsp/resolver.rs:96`.

Preserve these principles:

- Rust owns performance-sensitive analysis.
- Public outputs expose domain concepts, not parser internals.
- TypeScript stays a thin orchestration and response-shaping layer.
- Exact source line citation remains product-critical.
- Whole-file fallback is allowed, but should become visible and measurable.

## Design principles from the papers

### 1. Context beats global token meaning

The context-aware scanning paper’s lesson is not “use LR everywhere.” It is: a token candidate should be constrained by its syntactic or analysis context when ambiguity matters.

For Octocode this means:

- TSX `<` can be JSX, generic syntax, or comparison.
- JavaScript `/` can be regex or division.
- Markdown contains host prose plus embedded language regions.
- YAML package/CI files often embed shell, JSON, glob, regex, or JS snippets.
- HTML/Vue/Svelte contain markup, script, style, and sometimes framework DSLs.

Opportunity: introduce an internal `LanguageRegion` model:

```ts
interface LanguageRegion {
  languageId: string
  kind: 'host' | 'embedded' | 'string-dsl' | 'comment-doc' | 'generated'
  originalRange: Range
  parentRegionId?: string
  confidence: 'exact' | 'heuristic' | 'fallback'
  diagnostics: AnalysisDiagnostic[]
}
```

This gives minification, structural search, security scanning, and LSP helpers a shared way to avoid global one-extension-one-language assumptions.

### 2. Preserve uncertainty instead of guessing

The GLR/abstract parse DAG papers emphasize that ambiguity should be represented, not hidden.

For `octocode-engine`, this should become a public result-quality contract:

```ts
type AnalysisStatus =
  | 'ok'
  | 'partial'
  | 'unsupported'
  | 'ambiguous'
  | 'parserFailed'
  | 'fallback'
  | 'truncated'
  | 'stale'
```

This is especially important for agents. An empty result currently risks being interpreted as “proof of absence.” Better responses should say whether zero means:

- no match exists,
- parser was unsupported,
- language server capability was missing,
- fallback search was used,
- syntax was malformed,
- content was truncated,
- result was sanitized,
- symbol resolution was ambiguous.

### 3. Incremental means shared snapshots, not every feature inventing freshness

The incremental parsing and development-environment papers converge on one practical idea: expensive analysis should take a stable snapshot and produce reusable metadata.

Opportunity: define a native-owned `FileSnapshot` protocol:

```ts
interface FileSnapshot {
  id: string
  path: string
  contentHash: string
  byteLength: number
  lineCount: number
  encoding: 'utf8'
  lineIndexId: string
  previousId?: string
  changedRanges?: Range[]
}
```

Then every expensive engine API can return:

```ts
interface AnalysisMetadata {
  snapshotId: string
  analyzer: string
  analyzerVersion: string
  languageId?: string
  status: AnalysisStatus
  warnings: AnalysisDiagnostic[]
  fallback?: FallbackInfo
  reusedRanges?: Range[]
  recomputedRanges?: Range[]
  lineMapGuarantee: 'exact' | 'range-preserving' | 'line-preserving' | 'none'
}
```

This does not require implementing full incremental parsing immediately. It creates the contract that allows incremental caches later.

### 4. Long sequences must not become hidden linked lists

The incremental parsing paper warns that long list-like structures must be balanced. For Octocode this applies beyond parse trees:

- token streams,
- line maps,
- minified sections,
- search matches,
- archive entries,
- AST match groups,
- context chunks,
- symbol lists,
- diagnostics.

Opportunity: introduce balanced chunk structures for internal context and result storage, especially where pagination is common. The goal is stable paging and cheap slicing without reparsing or reserializing huge strings.

### 5. Minified content is a view, not the source

The practical algorithms summary stresses that whitespace/comments and original positions are meaningful. Octocode’s agent value depends on citation fidelity, so minification should never destroy the ability to map back to source.

Opportunity: move from plain minified strings to `ContentView`:

```ts
interface ContentView {
  content: string
  mode: 'none' | 'standard' | 'symbols' | 'agent-context'
  sourceMap: LineMap
  omitted: OmittedRegion[]
  diagnostics: AnalysisDiagnostic[]
  metadata: AnalysisMetadata
}
```

This would make “symbols mode,” standard minify, and future context packs all share the same line-map rules.

## Major opportunity areas

## A. Agent Context IR

### Problem

Agents need compact context that is faithful enough to reason from. Plain file slices, regex matches, and skeleton strings are useful, but they do not express enough provenance, uncertainty, or relationships.

### Opportunity

Create a native `AgentContextDocument` IR that can be generated from a file, directory, search result set, PR diff, or LSP trace.

Possible shape:

```ts
interface AgentContextDocument {
  snapshot: FileSnapshot
  regions: ContextRegion[]
  symbols: SymbolSummary[]
  imports?: ImportSummary[]
  diagnostics: AnalysisDiagnostic[]
  redactions: RedactionSpan[]
  lineMap: LineMap
  quality: ContextQuality
}

interface ContextRegion {
  id: string
  kind:
    | 'exact'
    | 'signature'
    | 'body-summary'
    | 'omitted-body'
    | 'comment-summary'
    | 'embedded-language'
    | 'search-hit'
    | 'lsp-evidence'
  originalRange: Range
  outputRange: Range
  languageId?: string
  text: string
  confidence: 'exact' | 'parser' | 'heuristic' | 'fallback'
}
```

### Why it matters

This would let the MCP/CLI layer ask for “best context for this research task” instead of manually composing exact reads, minified reads, symbol skeletons, LSP snippets, and search snippets.

### Best first version

Do not build a huge semantic model first. Start with a `ContentView`-compatible IR for one file:

1. exact cited regions,
2. symbol skeleton,
3. omitted body markers,
4. source line map,
5. parse/fallback warnings,
6. redaction spans.

Then add multi-file context packs later.

## B. Minification with line-map and omission semantics

### Current state

The engine exposes many minification functions and structured `MinifyResult` with `content`, `failed`, `type`, and optional `reason` in `packages/octocode-engine/index.d.ts:409`. Signature extraction has a “skeleton must not grow beyond source” guard in `packages/octocode-engine/src/signatures/mod.rs:449`.

### Opportunity

Add `minifyContentViewResult` or evolve internal minification to return metadata:

```ts
interface MinifyViewResult {
  content: string
  failed: boolean
  type: string
  reason?: string
  sourceMap: LineMap
  omittedRegions: OmittedRegion[]
  preservedRegions: Range[]
  diagnostics: AnalysisDiagnostic[]
  languageRegions: LanguageRegion[]
}
```

### Best practices

- Preserve original line numbers as a hard invariant.
- Mark omitted function/class bodies explicitly rather than only dropping them.
- Record when parser-grade minification declined and heuristic minification took over.
- Use embedded-language regions for HTML/Vue/Svelte/Markdown instead of one global strategy.
- Ensure redaction and minification compose without shifting citations invisibly.

### Creative extension: “research minify”

Add a mode optimized for agents:

- keep public APIs, imports, exports, type names, route declarations, RPC method names, config keys, and error strings;
- summarize or omit implementation bodies;
- preserve nearby comments only when they explain intent, TODOs, security, public contracts, or deprecation;
- include an omission table with line ranges and reasons.

This could sit between `standard` and `symbols`:

```text
none      = exact text
standard  = compact readable text
symbols   = skeleton only
research  = skeleton + high-signal literals + selected comments + body omission map
```

## C. Structural search as an evidence engine, not only a matcher

### Current state

Structural matches include range, text, and metavars in `packages/octocode-engine/src/structural/types.rs:5`. File search tracks counts and warnings in `packages/octocode-engine/src/structural/types.rs:34`. Query prefiltering derives a literal anchor from patterns/rules in `packages/octocode-engine/src/structural/query.rs:30`.

### Opportunity

Make structural search output agent-grade metadata:

```ts
interface StructuralSearchFileResultV2 {
  path: string
  languageId?: string
  parseStatus: AnalysisStatus
  parseDiagnostics: AnalysisDiagnostic[]
  fallback?: FallbackInfo
  matches: StructuralMatchV2[]
}

interface StructuralMatchV2 extends StructuralMatch {
  id: string
  nodeKind: string
  fieldPath?: string
  ancestorKinds?: string[]
  confidence: 'exact-ast' | 'partial-ast' | 'fallback-text'
  sourceMap?: LineMap
}
```

### Best practices

- Distinguish “zero AST matches” from “file skipped,” “unsupported extension,” “parse failed,” and “prefilter skipped.”
- Return query diagnostics that tell agents how to repair bad ast-grep rules.
- Cache parsed ASTs by content hash + language adapter + parser version.
- Keep prefiltering conservative and report when it eliminated files.
- Support compound documents by searching relevant embedded regions, not just full files by extension.

### Creative extension: structural search plans

Add a dry-run/explain mode:

```ts
explainStructuralQuery(pattern | rule, languageId) -> {
  normalizedPattern,
  literalAnchor,
  unsafePrefilterReasons,
  expectedNodeKinds,
  examples,
  diagnostics
}
```

This helps agents construct better AST queries instead of trial-and-error loops.

## D. LSP anchoring and semantic fusion

### Current state

`resolvePosition` maps fuzzy symbol name + line hint to exact line/character in `packages/octocode-engine/index.d.ts:450`. Internally, the resolver tries grammar-based candidates and falls back to scanning near the line or whole file in `packages/octocode-engine/src/lsp/resolver.rs:96` and `packages/octocode-engine/src/lsp/resolver.rs:275`.

### Problem

Agents often have approximate anchors: a search hit, symbol skeleton line, or minified output line. If a symbol appears multiple times, a single selected position can be wrong but plausible.

### Opportunity

Return candidate sets and resolution reasons:

```ts
interface ResolvePositionResult {
  selected: JsResolvedSymbol
  candidates: ResolvedSymbolCandidate[]
  ambiguity: 'none' | 'multiple-on-line' | 'multiple-nearby' | 'fallback-scan'
  method: 'tree-sitter' | 'line-scan' | 'whole-file-scan'
  diagnostics: AnalysisDiagnostic[]
  snapshotId?: string
}
```

### Best practices

- Prefer tree-sitter/grammar candidates over text scanning.
- Keep fallback explicit.
- Preserve `orderHint`, but explain why it was needed.
- Attach snapshot/version metadata so line hints are not reused after edits without mapping.
- Normalize LSP empty responses into reasoned statuses: server unavailable, capability unsupported, stale snapshot, ambiguous anchor, true no result.

### Creative extension: LSP + AST consensus

For high-value queries, return a confidence score from multiple evidence sources:

```text
localSearch hit + AST candidate + LSP definition = high confidence
localSearch hit only = low confidence
AST candidate but LSP unavailable = syntactic confidence, semantic unknown
```

This would make agents less likely to overclaim from one weak signal.

## E. Context-aware scanning for mixed and extensible languages

### Problem

Many engine features currently receive a file path and infer one language/strategy. Real research input is mixed-language and context-sensitive.

### Opportunity

Add lightweight context-aware scanning where ambiguity matters, without replacing tree-sitter or ast-grep.

High-value targets:

1. Markdown fenced code blocks.
2. HTML/Vue/Svelte `<script>` and `<style>` regions.
3. TSX/JSX angle-bracket ambiguity for symbol extraction and boundary offsets.
4. JS/TS template literals tagged with `sql`, `gql`, `html`, `css`.
5. YAML/JSON config fields containing shell scripts, globs, regexes, or package commands.
6. Rust macro bodies and attributes.

### Best practices

- Use simple disjoint tokenization where sufficient.
- Use context-aware scanning only for ambiguous/mixed regions.
- Make token precedence explicit and local.
- Do not rely on global maximal munch if the longer token is invalid in context.
- Report context-detection confidence.

### First implementation idea

Create a `regionizer` module, not a full parser generator:

```text
file path + content -> language regions + confidence + diagnostics
```

Then let existing minifier, structural search, and sanitizer consume regions.

## F. Incremental caches and bounded recomputation

### Problem

For MCP/agent workflows, the same files are often searched, read, minified, and semantically queried repeatedly. Whole-file recomputation wastes time and loses stable identities.

### Opportunity

Add shared snapshot-aware caches:

- line index cache,
- signature/skeleton cache,
- minified view cache,
- sanitizer span cache,
- structural AST cache,
- structural query compiled matcher cache,
- archive listing cache,
- LSP anchor resolution cache.

### Best practices

- Cache by content hash + analyzer version + relevant options, not only path/mtime.
- Return reuse/recompute metadata.
- Invalidate with boundary context, not exact changed bytes only.
- Keep whole-file fallback explicit and measured.
- Avoid exposing cache internals in public API unless intentionally diagnostic.

### First implementation idea

Start with pure functions plus optional caller-provided snapshot IDs. Do not build a daemon cache first. The TypeScript layer or MCP session cache can later decide lifecycle.

## G. Better diagnostics and fallback contracts

### Problem

Agents need to know when evidence is weak. A terse error string or empty array is not enough.

### Opportunity

Standardize diagnostics across engine APIs:

```ts
interface AnalysisDiagnostic {
  code: string
  severity: 'info' | 'warning' | 'error'
  message: string
  range?: Range
  stage:
    | 'regionize'
    | 'scan'
    | 'parse'
    | 'match'
    | 'minify'
    | 'sanitize'
    | 'lsp'
    | 'paginate'
  recovery?: string
}
```

Example diagnostic codes:

- `parser.unsupportedLanguage`
- `parser.malformedInput`
- `structural.prefilterSkipped`
- `structural.queryInvalid`
- `lsp.capabilityUnsupported`
- `lsp.serverUnavailable`
- `minify.heuristicFallback`
- `content.truncated`
- `security.redacted`
- `snapshot.staleLineHint`

### Why it matters

This turns engine outputs into agent-safe evidence. Agents can decide the next tool call based on structured reasons rather than guessing.

## H. Security-aware structure preservation

### Problem

Sanitization must redact secrets without destroying source reasoning.

### Opportunity

Return redaction span metadata and preserve line/column mapping:

```ts
interface RedactionSpan {
  originalRange: Range
  outputRange: Range
  category: string
  confidence: 'high' | 'medium' | 'low'
  replacement: string
}
```

### Best practices

- Sanitization should be an explicit filtering stage, not silent mutation.
- Keep original offsets/ranges or range maps where practical.
- Redaction should compose with minification and context packaging.
- For agents, report “content was redacted” as evidence quality metadata.

## I. Benchmarks and evals for agent usefulness

### Problem

Raw speed is necessary but not sufficient. A research engine can be fast while giving agents misleading or low-signal context.

### Opportunity

Add quality benchmarks alongside performance benchmarks.

Metrics:

- token reduction ratio,
- source line-map correctness,
- signature recall,
- structural match precision/recall on fixtures,
- LSP anchor accuracy,
- fallback classification accuracy,
- redaction span preservation,
- context pack usefulness for agent tasks,
- malformed-file partial-result rate,
- compound-document region detection accuracy.

Fixture types:

- huge TypeScript files,
- TSX ambiguity,
- malformed JS/TS/Rust/Python,
- Markdown with mixed code fences,
- Vue/Svelte/HTML embedded scripts/styles,
- CI YAML shell blocks,
- generated/minified files,
- files with secrets and redactions,
- repos with repeated symbol names.

## Code-grounded implementation map

This package is already organized around clear native owners. Future work should extend these owners rather than adding parallel flows in TypeScript.

| Capability | Current owner | What that means for this roadmap |
|---|---|---|
| NAPI exports | `packages/octocode-engine/src/lib.rs`, `packages/octocode-engine/src/bindings/` | Add new public APIs as thin `#[napi]` wrappers; keep logic in inner Rust modules. |
| Shared result/config structs | `packages/octocode-engine/src/types.rs`, plus domain-specific `types.rs` files | Put common diagnostic/status structs here only if they are truly cross-domain; keep structural/LSP-only details local. |
| Minification dispatch | `packages/octocode-engine/src/minifier.rs` | `ContentView`, line-map guarantees, and minify diagnostics should start here because sync and structured-result paths already share dispatch. |
| Minification strategy details | `packages/octocode-engine/src/strategies/` | Do not create a second minifier. Add source-map/omission metadata by extending strategy outputs behind the existing dispatch. |
| Signature/symbol skeletons | `packages/octocode-engine/src/signatures/mod.rs`, `packages/octocode-engine/src/signatures/languages.rs` | Symbol/research views should reuse the existing tree-sitter language table and body queries; `languages.rs` is the registry owner. |
| Structural search | `packages/octocode-engine/src/structural.rs`, `packages/octocode-engine/src/structural/` | Query diagnostics, match IDs, node metadata, and per-file parse status belong here. The current split already has `query`, `language`, `matcher`, `files`, and `types` owners. |
| LSP position anchoring | `packages/octocode-engine/src/lsp/resolver.rs` | Candidate sets and ambiguity metadata should extend resolver output; avoid doing fuzzy resolution in callers. |
| LSP server selection/validation | `packages/octocode-engine/src/lsp/config.rs`, `packages/octocode-engine/src/lsp/validation.rs`, `packages/octocode-engine/src/lsp/commands.rs` | Status reasons such as unavailable command, rejected shell wrapper, unsupported language, and missing capability should be normalized from these owners. |
| LSP transport/runtime | `packages/octocode-engine/src/lsp/client.rs`, `packages/octocode-engine/src/lsp/json_rpc.rs` | Keep protocol/runtime errors separate from semantic “no result” states. |
| Search hot path | `packages/octocode-engine/src/ripgrep_search.rs`, `packages/octocode-engine/src/ripgrep_parser.rs` | Snapshot/cache ideas should preserve current UTF-16 column handling and result-shaping behavior. |
| Line slicing and offsets | `packages/octocode-engine/src/utf8_offsets.rs`, `packages/octocode-engine/src/line_extractor.rs` | Line maps should build on existing UTF-8/UTF-16 conversion and match-range extraction instead of inventing offset math elsewhere. |
| Security detection/sanitization | `packages/octocode-engine/src/security/detector.rs`, `packages/octocode-engine/src/security/sanitizer.rs`, `packages/octocode-engine/src/security/native.ts` | Redaction span metadata should extend detector/sanitizer outputs and preserve the TS fallback bridge contract. |
| Filesystem/query utilities | `packages/octocode-engine/src/fs_query.rs`, `packages/octocode-engine/src/file_extension.rs` | Regionization and language detection should reuse extension helpers and existing traversal filters. |

### Current code constraints to respect

- `packages/octocode-engine/src/minifier.rs` has a 1 MiB guard (`MAX_SIZE`) and already differentiates structured failure from string-only fallback. New metadata should preserve that behavior.
- `packages/octocode-engine/src/signatures/mod.rs` already has anti-growth behavior for skeleton extraction. Research views should preserve “do not return a larger skeleton than source” unless the caller explicitly asks for richer context.
- `packages/octocode-engine/src/structural/query.rs` derives a conservative literal prefilter anchor. Any stronger prefilter must remain conservative and explain when it skips or cannot safely skip.
- `packages/octocode-engine/src/security/detector.rs` scans in chunks with overlap. Redaction spans must account for chunk overlap and preserve canonical pattern ordering.
- `packages/octocode-engine/src/utf8_offsets.rs` uses JavaScript UTF-16 index semantics at the NAPI boundary. New line maps and LSP anchors must not mix byte, Unicode-scalar, and UTF-16 offsets silently.
- `packages/octocode-engine/src/lsp/config.rs` and `packages/octocode-engine/src/lsp/validation.rs` now reject shell wrappers and validate executability. LSP quality work must not weaken those safety checks.

## Proposed roadmap

## Phase 1 — Metadata and diagnostics foundation

High impact, low architectural risk.

1. Define internal `AnalysisStatus`, `AnalysisDiagnostic`, `FallbackInfo`, and `LineMap` concepts.
2. Add metadata-returning variants before changing existing string-returning APIs.
3. Normalize fallback/error reasons in minification, structural search, and LSP resolver.
4. Add tests proving “empty” is distinct from “unsupported/fallback/parser failed.”
5. Add line-map tests for exact, standard, symbols, and future research views.

Deliverable: engine can explain result quality consistently.

## Phase 2 — Source views and agent context view

1. Add `ContentView` internally for minified/symbol outputs.
2. Preserve source line maps and omitted-region tables.
3. Add a `research` view mode prototype for one file.
4. Include diagnostics and redaction metadata in the view.
5. Benchmark token reduction and citation fidelity.

Deliverable: agents get compact context without losing source traceability.

## Phase 3 — Structural search v2

1. Add parse/fallback diagnostics per searched file.
2. Add stable match IDs and node kind metadata.
3. Add query explain/dry-run diagnostics.
4. Cache compiled matchers by language + normalized query.
5. Add optional AST cache keyed by content hash + parser version.

Deliverable: structural search becomes reliable evidence, not just matches.

## Phase 4 — LSP candidate resolution

1. Add candidate-returning position resolver internally.
2. Distinguish grammar resolution, near-line fallback, and whole-file fallback.
3. Return ambiguity metadata for repeated symbols.
4. Attach snapshot/version metadata to resolved positions.
5. Fuse AST/LSP/local-search evidence into confidence where practical.

Deliverable: agents can trust line hints and know when they are weak.

## Phase 5 — Compound document regionization

1. Build a lightweight `LanguageRegion` detector for Markdown, HTML, Vue/Svelte, TSX, and YAML shell/script regions.
2. Let minification consume regions first.
3. Let structural search target embedded regions.
4. Let sanitizer preserve region and line-map metadata.
5. Add compound-document eval fixtures.

Deliverable: one file can contain multiple analyzable languages.

## Phase 6 — Snapshot-aware incremental foundation

1. Add optional `FileSnapshot` inputs/outputs.
2. Cache line indexes, minified views, structural ASTs, and sanitizer spans by snapshot hash.
3. Report reused/recomputed ranges.
4. Add edit-like benchmarks: small insert/delete/rename in large files.
5. Keep full incremental parsing out of scope until real cache data justifies it.

Deliverable: repeated agent workflows become faster and more stable.

## Anti-goals and cautions

1. Do not build a full LR/GLR parser generator unless a concrete engine feature needs it.
2. Do not leak parser implementation state into public outputs.
3. Do not add a duplicate parsing/minification path in TypeScript; extend the Rust owner.
4. Do not silently repair malformed source; isolate invalid regions and report diagnostics.
5. Do not treat a single file extension as proof of one language for the whole file.
6. Do not let minification break citations.
7. Do not optimize only for speed; optimize for agent evidence quality.
8. Do not preserve legacy behavior by layering parallel flows; replace the owning flow when changing behavior.

## High-leverage API sketches

### `analyzeContentView`

```ts
analyzeContentView(content: string, filePath: string, options: {
  mode: 'none' | 'standard' | 'symbols' | 'research'
  includeDiagnostics?: boolean
  includeLineMap?: boolean
  includeRegions?: boolean
}): ContentView
```

### `resolvePositionDetailed`

```ts
resolvePositionDetailed(filePath: string, fuzzy: JsFuzzyPosition): ResolvePositionResult
```

### `explainStructuralQuery`

```ts
explainStructuralQuery(input: {
  pattern?: string
  rule?: string
  filePath?: string
  languageId?: string
}): StructuralQueryExplanation
```

### `searchStructuralDetailed`

```ts
searchStructuralDetailed(options: StructuralSearchFilesOptions & {
  includeDiagnostics?: boolean
  includeNodeMetadata?: boolean
  includeSkippedFiles?: boolean
}): StructuralSearchFilesResultV2
```

### `regionizeContent`

```ts
regionizeContent(content: string, filePath: string): {
  snapshot: FileSnapshot
  regions: LanguageRegion[]
  diagnostics: AnalysisDiagnostic[]
}
```

## Recommended next 3 PRs

These are intentionally smaller than the full roadmap. They improve agent evidence quality while respecting the current Rust/NAPI boundaries.

### PR 1 — Structural search diagnostics and match identity

**Goal:** make structural search distinguish true zero matches from skipped/unsupported/invalid/fallback states.

**Primary files:**

- `packages/octocode-engine/src/structural/types.rs`
- `packages/octocode-engine/src/structural/query.rs`
- `packages/octocode-engine/src/structural/matcher.rs`
- `packages/octocode-engine/src/structural/files.rs`
- `packages/octocode-engine/src/structural.rs`
- `packages/octocode-engine/tests/ffi.test.ts` if the public NAPI shape changes

**Implementation notes:**

1. Add structural-local `StructuralDiagnostic` / `StructuralFileStatus` before creating a global diagnostic framework.
2. Add stable match IDs derived from path + range + query fingerprint, not random IDs.
3. Include `languageId` / extension-derived language where available.
4. Preserve existing `StructuralSearchFilesResult` fields so current callers do not lose parsed/skipped counters.
5. Keep prefiltering conservative; if a rule has `not:` or `any:`, report why no literal anchor was used.

**Tests:**

- invalid pattern returns diagnostic with recovery text;
- unsupported extension is not reported as true zero matches;
- prefilter-skipped files are counted and explainable;
- match IDs are stable across repeated runs on unchanged content;
- malformed-but-parseable source returns partial/ok status rather than panicking.

**Success metric:** an agent can tell whether “no structural result” means no match, unsupported language, invalid query, unreadable file, skipped large file, or prefilter skip.

### PR 2 — Minify/content-view metadata without changing default strings

**Goal:** add a metadata-returning minification path while keeping current `minifyContentSync` and `applyMinification` behavior stable.

**Primary files:**

- `packages/octocode-engine/src/types.rs`
- `packages/octocode-engine/src/minifier.rs`
- `packages/octocode-engine/src/bindings/minify.rs`
- `packages/octocode-engine/src/strategies/`
- `packages/octocode-engine/src/signatures/mod.rs`
- `packages/octocode-engine/src/utf8_offsets.rs`

**Implementation notes:**

1. Add a new result shape rather than overloading plain string functions.
2. Start with `lineMapGuarantee`, `warnings`, `strategy`, `failed`, and `reason`; defer full source maps until there is a concrete consumer.
3. Reuse the existing dispatch path so sync/result paths cannot diverge.
4. Preserve the 1 MiB guard and anti-growth skeleton guard.
5. Document whether each strategy is exact-line-preserving, line-preserving, range-preserving, or no-map.

**Tests:**

- oversized content returns unchanged content plus explicit size diagnostic;
- invalid JSON keeps current failure behavior plus structured diagnostic;
- symbols extraction reports anti-growth fallback when skeleton is not smaller;
- UTF-16/UTF-8 offset behavior remains unchanged for multibyte input;
- standard minify does not claim exact line mapping when lines were collapsed.

**Success metric:** an agent can safely cite source after minification because the engine states the mapping guarantee instead of implying one.

### PR 3 — Detailed LSP position resolution

**Goal:** expose why a fuzzy `symbolName + lineHint` resolved to a position and whether alternatives existed.

**Primary files:**

- `packages/octocode-engine/src/lsp/resolver.rs`
- `packages/octocode-engine/src/lsp/types.rs`
- `packages/octocode-engine/src/bindings/lsp.rs`
- `packages/octocode-engine/src/lsp/config.rs`
- `packages/octocode-engine/src/lsp/validation.rs`
- `packages/octocode-engine/src/lsp/client.ts` / `native.ts` only as thin wrappers if needed

**Implementation notes:**

1. Keep existing `resolvePosition` behavior for callers that need one position.
2. Add `resolvePositionDetailed` returning selected candidate, all nearby candidates, method (`tree-sitter`, `near-line-scan`, `whole-file-scan`), and ambiguity reason.
3. Use existing grammar-backed resolution first; do not move fuzzy anchoring into TypeScript.
4. Normalize validation/config errors without weakening command/path safety.
5. Keep byte/UTF-16 conversion rules explicit in the returned candidate positions.

**Tests:**

- repeated symbol on one line requires `orderHint` and reports ambiguity;
- comment/string hits are not preferred over grammar-backed symbol candidates;
- fallback scan method is reported when grammar resolution cannot resolve;
- non-ASCII prefixes return correct UTF-16 character offsets;
- rejected LSP commands remain rejected.

**Success metric:** an agent can decide whether an LSP query is anchored strongly enough or should first re-search/read the file.

## Success metrics for the roadmap

- **Citation fidelity:** transformed outputs can map every displayed line to an original source line or explicitly say they cannot.
- **Empty-result clarity:** all structural/LSP/minify-result surfaces distinguish true absence from unsupported, failed, fallback, stale, or truncated analysis.
- **Agent token efficiency:** research views reduce content size without increasing follow-up correction reads for common tasks.
- **Anchor accuracy:** detailed LSP resolution selects the intended symbol in repeated-name fixtures and reports ambiguity when it cannot.
- **Structural precision:** AST matches remain immune to comments/strings and report parse/query status per file.
- **Security preservation:** redaction never hides the fact that content changed and does not corrupt line/offset mapping silently.
- **Performance guardrail:** metadata paths add bounded overhead and keep existing string-only hot paths available until callers migrate.

## Main takeaway

A stronger `octocode-engine` should be **structure-aware, source-map faithful, uncertainty-preserving, and snapshot-ready**.

The winning design is incremental in architecture before it is incremental in implementation: define stable snapshots, line maps, diagnostics, fallback states, and context views now; then make parsing, minification, structural search, and LSP resolution progressively smarter behind those contracts.
