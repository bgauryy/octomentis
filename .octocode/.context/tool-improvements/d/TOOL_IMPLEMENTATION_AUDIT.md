# Tool Implementation Audit — Scheme & Results

> Focused on actual source code: canonical schemas (`octocode-core/src/schemas/index.ts`), tool-level overrides (`octocode-tools-core/src/tools/*/scheme.ts`), output schemas (`octocode-core/src/schemas/outputs.ts`), tool descriptions (`octocode-core/src/resources/tools/`), execution layer, and config constants.

---

## Files Read

| File | Content |
|------|---------|
| `octocode-mcp-host/packages/octocode-core/src/schemas/index.ts` | Canonical Zod schemas for all 12 tools |
| `octocode-mcp-host/packages/octocode-core/src/schemas/outputs.ts` | All output schemas |
| `octocode-mcp-host/packages/octocode-core/src/resources/tools/ghSearchPRs.ts` | PR description + field descriptions |
| `octocode-mcp-host/packages/octocode-core/src/resources/tools/localSearchCode.ts` | Ripgrep description + field descriptions |
| `octocode-mcp-host/packages/octocode-core/src/resources/tools/localGetFileContent.ts` | File content description + field descriptions |
| `octocode-mcp-host/packages/octocode-core/src/resources/tools/ghSearchCode.ts` | Code search description + field descriptions |
| `octocode-mcp-host/packages/octocode-core/src/resources/tools/ghGetFileContent.ts` | GitHub file description + field descriptions |
| `octocode-tools-core/src/tools/github_search_pull_requests/scheme.ts` | PR local schema overrides |
| `octocode-tools-core/src/tools/local_ripgrep/scheme.ts` | Ripgrep local schema overrides |
| `octocode-tools-core/src/tools/local_ripgrep/execution.ts` | Ripgrep execution + evidence builder |
| `octocode-tools-core/src/tools/github_search_pull_requests/execution.ts` | PR execution — content stripping logic |
| `octocode-tools-core/src/scheme/fields.ts` | Shared field helpers (clamping, bulk schema) |
| `octocode-tools-core/src/scheme/responseEnvelope.ts` | `evidence` + `responsePagination` envelope |
| `octocode-tools-core/src/config.ts` | All numeric constants |

---

## Bugs / Discrepancies Found

### 1. `mode:"count"` described but not in schema

**Where:** `localSearchCode` description (`resources/tools/localSearchCode.ts`)

**Description says:**
```
"count" for cheapest match-count-only (no content — fastest orientation)
```

**Actual schema (`schemas/index.ts`):**
```ts
mode: z.enum(["paginated", "discovery", "detailed"]).default("paginated"),
```

`"count"` does not exist. The actual count-mode is via boolean flags:
```ts
countLinesPerFile: z.boolean().optional(),   // line count per file
countMatchesPerFile: z.boolean().optional(), // match count per file
```

**Impact:** Any agent that sends `mode:"count"` will get a Zod validation error — the call fails silently or returns an error result. The description is **wrong**.

---

### 2. `content` + `reviewMode` stripped silently when `prNumber` is absent

**Where:** `github_search_pull_requests/execution.ts`

```ts
if (!hasPrNumber) {
  effectiveQuery.content = undefined;
  effectiveQuery.reviewMode = undefined;
}
```

And a hint is added:
```
'Broad PR search returns metadata only. Re-call with prNumber and content selectors...'
```

**Impact:** An agent that sends `content: { body: true }` on a list-mode PR search will silently receive nothing but metadata + a hint. The content request is completely ignored. Not documented anywhere in the schema or description.

---

### 3. `minify:"symbols"` unavailable on `ghSearchPRs`

**Core schema for `ghSearchPRs`:**
```ts
minify: z.enum(["none", "standard"]).default("standard"),
```

**Core schema for `localGetFileContent` and `ghGetFileContent`:**
```ts
minify: z.enum(["none", "standard", "symbols"]).default("standard"),
```

`"symbols"` mode is only available on file-read tools, not on PR search. This is intentional (symbols mode = code skeleton, not meaningful on PR diffs) but undocumented. Any agent trying `minify:"symbols"` on a PR call gets a Zod validation error.

---

### 4. `limit` default stripped in tools-core PR override

**Core schema default:**
```ts
limit: intRange(1, MAX_GITHUB_SEARCH_LIMIT).default(DEFAULT_GITHUB_SEARCH_LIMIT),  // default: 30
```

**tools-core override (`github_search_pull_requests/scheme.ts`):**
```ts
limit: clampedInt(1, GITHUB_SEARCH_MAX_LIMIT).optional(),  // no default!
```

Same for `itemsPerPage`:
- Core: `.default(DEFAULT_PR_ITEMS_PER_PAGE)` = 20
- Override: `.optional()` — no default

**Impact:** Callers relying on server-side defaults for `limit`/`itemsPerPage` get `undefined` at the tools-core layer. The actual default behavior depends on the downstream GitHub API, not on a controlled schema default. Inconsistent with how other tools handle defaults.

---

### 5. `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 1_000`

**Where:** `octocode-tools-core/src/config.ts`

The default char length for file content reads is **1000 chars**. This is very small — about 40 lines of average TypeScript. Agents that omit `charLength` on file reads will get truncated responses with no warning if the file is large.

**Impact:** Silent truncation on every file read larger than ~40 lines when `charLength` is not set.

---

### 6. Dual-shape output responses

Every output schema returns the same data at **two levels**: flat top-level fields AND inside `data: {}`.

Example from `LocalSearchCodeOutputSchema`:
```ts
// Top-level (legacy path):
files: z.array(LocalSearchCodeFileSchema).optional(),
pagination: PaginationInfoSchema.optional(),

// Nested (current path):
data: z.object({
  files: z.array(LocalSearchCodeFileSchema),
  pagination: PaginationInfoSchema.optional(),
}).optional(),
```

**Impact:** Consumers must handle both shapes. There is no schema-enforced single canonical path. This is a backward-compat shim that adds parsing complexity for every tool consumer.

---

### 7. `matchString` disables `minify` on `ghSearchPRs`

**From the field description:**
```
matchString: "Filter patch/body text — disables minify so matched lines stay visible."
```

When `matchString` is set on a PR detail call, minify is bypassed for the matched section. This means:
- `minify:"standard"` + `matchString` → matched content is **not** minified
- This can cause unexpectedly large responses when `matchString` matches large diffs

**Not documented anywhere in SKILL.md.**

---

## `superRefine` Validation Rules — Complete List

These are enforced by Zod and will return a `Validation error: ...` result if violated. Not documented anywhere.

### `localSearchCode`
| Rule | Error |
|------|-------|
| `filesOnly: true` + `filesWithoutMatch: true` | `"filesOnly and filesWithoutMatch are mutually exclusive."` |
| `fixedString: true` + `perlRegex: true` | `"fixedString and perlRegex are mutually exclusive."` |
| `caseSensitive: true` + `caseInsensitive: true` | `"caseSensitive and caseInsensitive are mutually exclusive."` |
| `multilineDotall: true` without `multiline: true` | `"multilineDotall requires multiline=true."` |
| `countLinesPerFile: true` + `countMatchesPerFile: true` | `"countLinesPerFile and countMatchesPerFile are mutually exclusive."` |

### `localGetFileContent` + `ghGetFileContent`
| Rule | Error |
|------|-------|
| `fullContent: true` + `matchString` | `"Cannot use fullContent with matchString"` |
| `fullContent: true` + `startLine`/`endLine` | `"Cannot use fullContent with startLine/endLine"` |
| `matchString` + `startLine`/`endLine` | `"Cannot use matchString with startLine/endLine"` |
| `endLine < startLine` | `"endLine must be greater than or equal to startLine"` |

### `ghSearchPRs`
| Rule | Error |
|------|-------|
| `content.patches.mode:"selected"` with no `files[]` or `ranges[]` | `'mode="selected" requires non-empty files or ranges'` |
| `content.patches.files[]` or `ranges[]` without `mode:"selected"` | `'files/ranges require mode="selected"'` |

### `localViewStructure`
| Rule | Error |
|------|-------|
| `filesOnly: true` + `directoriesOnly: true` | `"filesOnly and directoriesOnly are mutually exclusive."` |

### `localFindFiles`
| Rule | Error |
|------|-------|
| `minDepth > maxDepth` | `"minDepth must be less than or equal to maxDepth."` |

### `lspGetSemantics`
| Rule | Error |
|------|-------|
| `type` ≠ `documentSymbols` without `symbolName` | `"symbolName is required unless type is documentSymbols"` |
| `type` ≠ `documentSymbols` without integer `lineHint` | `"lineHint is required unless type is documentSymbols"` |

---

## Scheme Constants (Hard Limits)

All from `octocode-tools-core/src/config.ts`:

| Constant | Value | Used by |
|---|---|---|
| `GITHUB_SEARCH_MAX_LIMIT` | 100 | `ghSearchCode`, `ghSearchPRs`, `ghSearchRepos` |
| `GITHUB_SEARCH_DEFAULT_LIMIT` | 30 | Default results per search query |
| `GITHUB_SEARCH_MAX_PAGES` | 10 | Max pages for GitHub searches |
| `GITHUB_STRUCTURE_MAX_ENTRIES_PER_PAGE` | 200 | `ghViewRepoStructure` |
| `GITHUB_STRUCTURE_DEFAULT_ENTRIES_PER_PAGE` | 100 | Default entries per structure page |
| `PR_CONTENT_MAX_ITEMS_PER_PAGE` | 100 | `ghSearchPRs` comments/commits/files |
| `PR_CONTENT_DEFAULT_ITEMS_PER_PAGE` | 20 | Default PR content items |
| `LOCAL_DEFAULT_FILES_PER_PAGE` | 20 | `localSearchCode`, `localFindFiles` |
| `LOCAL_MAX_FILES_PER_PAGE` | 50 | `localViewStructure` |
| `LOCAL_MAX_LIMIT` | 10,000 | `localFindFiles.limit`, `localViewStructure.limit` |
| `LOCAL_MAX_DEPTH` | 20 | `localViewStructure.depth`, `lspGetSemantics.depth` |
| `MAX_PAGE_NUMBER` | 1,000 | All `page` fields |
| `MAX_CONTEXT_LINES` | 100 | All `contextLines` fields |
| `MAX_CHAR_LENGTH` | 50,000 | All `charLength` fields |
| `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH` | **1,000** | ⚠️ Default for ghGetFileContent — very small |
| `MAX_MATCH_CONTENT_LENGTH` | 100,000 | `localSearchCode.matchContentLength` max |

---

## Output Schema — What Each Tool Actually Returns

### `localSearchCode`

```ts
{
  // Result data (check data.files first, then flat files)
  data?: {
    files: Array<{
      path: string,
      matchCount: number,
      matches?: Array<{ line: number, value?: string, column?: number }>,
      modified?: string,
    }>,
    pagination?: PaginationInfo,
    searchEngine?: string,
  },
  // Flat shape (legacy path — same data):
  files?: Array<...>,
  pagination?: PaginationInfo,
  // Envelope:
  hints?: string[],
  warnings?: Array<string | { kind: string }>,
  error?: string,
  // evidence, base, shared, responsePagination (from responseEnvelope)
}
```

**Key output signal:** `searchEngine` tells you if it fell back from ripgrep to grep.

---

### `localGetFileContent`

```ts
{
  data?: {
    path: string,
    content: string,
    contentView?: "none" | "standard" | "symbols",   // what minify mode was applied
    isSkeleton?: boolean,                             // true when minify:"symbols"
    totalLines?: number,
    startLine?: number,
    endLine?: number,
    isPartial?: boolean,                              // true when charLength capped output
    matchRanges?: Array<[number, number]>,            // line ranges of matchString hits
    pagination?: CharPagination,
    lastModified?: string,
    lastModifiedBy?: string,
  },
  // Flat shape (legacy path)
  path?: string,
  content?: string,
  contentView?: ...,
  isSkeleton?: boolean,
  pagination?: CharPagination,
  hints?: string[],
  warnings?: string[],
  error?: string,
}
```

**Key output signals:**
- `isPartial: true` → use `charOffset` to get more content
- `isSkeleton: true` → content is the symbol skeleton (`minify:"symbols"` was applied)
- `matchRanges[]` → line ranges where `matchString` was found; use `[0]` as `lineHint` for LSP

---

### `ghSearchPRs`

Broad list mode returns `pull_requests[]` with minimal metadata.  
Detail mode (with `prNumber`) returns the requested surfaces inside `results[0].data`.

**Key output signals:**
- `bodyEmpty: true` → `body` was requested but PR body is actually empty
- `absent` values → surface was not requested (not a missing value)
- `sanitizationWarnings` → content was redacted (secrets removed)
- `in_reply_to_id` on inline comments → this is a reply, not a top-level comment
- `bodyPagination.hasMore: true` → use `charOffset` + `charLength` to get more body

---

### `ghSearchCode`

```ts
{
  results: Array<{
    id: string,
    data: {
      files: Array<{
        id: string,
        owner: string,
        repo: string,
        path: string,
        matches: Array<{
          value?: string,              // snippet text
          pathOnly?: boolean,          // true when match:"path" was used
          matchIndices?: Array<{ start: number, end: number }>,  // char offsets in snippet
          url?: string,                // only when verbose:true
        }>,
      }>,
      pagination?: {
        currentPage, totalPages, perPage, totalMatches, hasMore,
        uniqueFileCount,
        totalMatchesKind: "exact" | "reported" | "lowerBound",
        totalMatchesCapped,
      },
    },
  }>,
  hints?: string[],
  emptyQueries?: Array<{ id: string, hints?: string[], nonExistentScope?: true }>,
  errors?: Array<{ id: string, error: string, hints?: string[] }>,
}
```

**Key output signals:**
- `matchIndices` are **char offsets in the snippet**, not file line numbers — cannot be used as `lineHint` directly
- `totalMatchesKind: "lowerBound"` → GitHub capped the count, real total is higher
- `emptyQueries[].nonExistentScope: true` → owner/repo does not exist or is not indexed
- `pathOnly: true` on a match → `match:"path"` was used; no snippet content

---

### `lspGetSemantics`

Each result has `resolvedSymbol` that shows where LSP actually resolved the symbol — use `resolvedSymbol.foundAtLine` to verify the `lineHint` was accurate.

For `documentSymbols`: returns a flat list of symbols with kind, name, and range — no `symbolName`/`lineHint` needed.

For `references` with `groupByFile:true`: compact per-file summary instead of every location.

For `callers`/`callees` with `format:"compact"`: line-oriented strings, ~50% fewer tokens than `format:"structured"`.

---

## Evidence Envelope — How It Works

Evidence is **computed by the execution layer**, not passed in by the caller. It is always present on successful responses.

```ts
{
  evidence: {
    kind: "code" | "content" | "structure" | ...,
    answerReady: boolean,    // true if the call returned useful results
    complete: boolean,       // true if no more pages exist
    confidence: "high" | "medium" | "low",
    reason?: string,         // why complete=false or answerReady=false
    missingFields?: string[] // fields that would improve the result
  }
}
```

**How the ripgrep evidence builder works** (`execution.ts:buildRipgrepEvidence`):
- `answerReady: true` when `files.length > 0` OR `pagination.totalFiles > 0`
- `complete: false` when file pagination has more OR any file has more matches
- Incomplete reasons are propagated from tool hints

**What this means for callers:** Check `evidence.answerReady` before issuing follow-up calls. Check `evidence.complete` before paginating.

---

## Bulk Query Schema — Hard Rules

From `scheme/fields.ts:createRelaxedBulkQuerySchema`:

```ts
z.strictObject({
  queries: z.array(querySchema).min(1).max(5),  // 1–5 queries per call
  responseCharOffset: ...,
  responseCharLength: ...,
}).superRefine(/* duplicate id check */)
```

- **Max 5 queries per call** — hard limit, enforced by Zod
- **Duplicate `id` fields** across queries fail validation
- `z.strictObject` — no extra fields on the bulk envelope are allowed
- `responseCharOffset`/`responseCharLength` control the **entire response** (all queries combined), not per-query

---

## Comparison: Core Schema vs Tools-Core Overrides

The tools-core layer applies local overrides via `createQueryShapeSchema` to fix types for the JSON-over-stdio transport.

| Field | Core default | Tools-core override | Why |
|---|---|---|---|
| `prNumber` | `intRange(1, MAX_LINE_NUMBER)` | `clampedInt(1, 1_000_000_000)` — with clamping | Clamp instead of reject OOB values |
| `limit` (ghSearchPRs) | `.default(30)` | `.optional()` — **no default** | ⚠️ Strips default — inconsistent |
| `itemsPerPage` (ghSearchPRs) | `.default(20)` | `.optional()` — **no default** | ⚠️ Strips default — inconsistent |
| `contextLines` | hard `intRange` | `clampedInt` (clamped, not rejected) | Clamp instead of reject |
| `matchContentLength` | `intRange` `.default(500)` | `clampedInt(1, MAX).optional().default(500)` | Same default preserved |
| All page fields | strict `pageNumber()` | `relaxedPageNumberField` (clamps to 1–1000) | Clamped for transport safety |

**Key insight:** The tools-core overrides **relax** validation by clamping out-of-range values instead of rejecting them. This means callers sending `page: 0` get `page: 1` silently rather than a validation error.

---

## What to Fix / Improve

### Fix in `octocode-core` (description)

**1. Remove `mode:"count"` from `localSearchCode` description**  
The description mentions it but the schema doesn't have it. Fix:
```diff
- "count" for cheapest match-count-only (no content — fastest orientation).
+ Use countLinesPerFile:true or countMatchesPerFile:true for count-only mode.
```

**2. Document `content`/`reviewMode` stripping on broad PR search**  
Add to `ghSearchPRs` description:
```diff
+ content and reviewMode are silently stripped when prNumber is absent — broad search always returns metadata only.
```

**3. Document `matchString` + `minify` interaction on `ghSearchPRs`**  
Add to `matchString` field description:
```diff
+ When matchString is set, minify is bypassed for matched sections — response size may be larger than expected.
```

---

### Fix in `octocode-tools-core` (scheme)

**4. Restore `limit` and `itemsPerPage` defaults in `ghSearchPRs` override**  
```ts
// github_search_pull_requests/scheme.ts
const queryOverrides = {
  ...
  limit: clampedInt(1, GITHUB_SEARCH_MAX_LIMIT).optional().default(GITHUB_SEARCH_DEFAULT_LIMIT),
  itemsPerPage: clampedInt(1, PR_CONTENT_MAX_ITEMS_PER_PAGE).optional().default(PR_CONTENT_DEFAULT_ITEMS_PER_PAGE),
  ...
}
```

**5. Raise `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH`**  
1000 chars is too small for any real file read. Raise to at least 5000–10000:
```ts
// config.ts
export const GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 5_000;
```

---

### Fix in `octocode-core` (outputs)

**6. Consolidate the dual-shape output response**  
Every output schema has flat top-level fields AND nested `data: {}` fields with the same data. This dual shape exists for backward compatibility but adds complexity. Options:
- Deprecate flat fields and document `data.*` as the canonical path
- Add explicit JSDoc on the flat fields: `@deprecated — use data.files instead`

---

## Summary

| # | Type | Location | Issue |
|---|------|----------|-------|
| 1 | **Bug** | `resources/tools/localSearchCode.ts` | `mode:"count"` described, not in schema — breaks callers |
| 2 | **Behavior** | `tools/github_search_pull_requests/execution.ts` | `content`/`reviewMode` silently stripped without `prNumber` |
| 3 | **Schema gap** | `tools/github_search_pull_requests/scheme.ts` | `minify:"symbols"` not available — Zod error if attempted |
| 4 | **Schema inconsistency** | `tools/github_search_pull_requests/scheme.ts` | `limit`/`itemsPerPage` defaults stripped vs core |
| 5 | **Config** | `config.ts` | `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 1000` — too small, causes silent truncation |
| 6 | **Output design** | `schemas/outputs.ts` | Dual-shape responses (flat + `data.*`) — ambiguous canonical path |
| 7 | **Undocumented** | `resources/tools/ghSearchPRs.ts` | `matchString` disables `minify` — not in SKILL.md |
| 8 | **Undocumented** | `schemas/index.ts` | All `superRefine` mutual exclusion rules — silent validation errors |
| 9 | **Undocumented** | `scheme/fields.ts` | Clamping behavior (OOB values silently adjusted, not rejected) |
