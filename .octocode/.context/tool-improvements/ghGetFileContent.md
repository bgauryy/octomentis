# `ghGetFileContent` — Improvements

## Current State
- Description mentions `type:"directory"` requires `ENABLE_CLONE=true` — this couples a tool description to an operator deployment flag that agents have no control over and cannot detect. Agents should not be told to check flags.
- `matchStringIsRegex` and `matchStringCaseSensitive` undocumented in description
- `forceRefresh` undocumented
- `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 1000` is too small — agents reading any real file without `charLength` get ~40 lines silently truncated
- `minify:"symbols"` use case not explained — agents never use it
- Mutual exclusion rules (`fullContent` XOR `matchString` XOR `startLine/endLine`) not stated — agents trigger validation errors
- `matchRanges[]` in output not explained — agents miss the LSP lineHint handoff

---

## Description

### Current
```
Read GitHub file/region.
Use matchString or startLine/endLine for focused reads; fullContent for small whole-file reads.
type:"directory" needs ENABLE_CLONE=true+ENABLE_LOCAL=true; use ghViewRepoStructure otherwise.
Continuation: for char pagination read "Next: charOffset=N" from the hint (or compute pagination.charOffset+pagination.charLength); for matchString slices use startLine=N from the hint.
Next: ghSearchCode for usages, ghViewRepoStructure for surrounding paths.
```

### Proposed
```
Read a file or region from a GitHub repository.

Choose extraction mode — these are mutually exclusive:
- matchString: find all occurrences of text/regex; returns merged slices + matchRanges (line numbers)
- startLine/endLine: read a specific line range
- fullContent: read the entire file (small files only)
- default (none set): returns first charLength chars from line 1

Choose minify mode:
- "symbols" — skeleton + line gutter only, 55–97% smaller; use for orientation before reading details
- "standard" (default) — strips comments and blank lines
- "none" — exact raw text; use when quoting or diffing

Output signals:
- isPartial:true → charLength capped the response; use pagination.nextCharOffset to continue
- matchRanges[].start/end → 1-based line numbers of each matchString hit; use as lineHint for lspGetSemantics
- isSkeleton:true → minify:"symbols" was applied; content is a structural outline, not full source
- warnings[] → content was sanitized (secrets redacted)
- pagination.nextCharOffset → exact value to pass as charOffset for the next page

Continuation: pass pagination.nextCharOffset as charOffset — do not compute manually.

Next: lspGetSemantics(uri, symbolName, lineHint=matchRanges[0].start) for semantic navigation; ghSearchCode to find usages.
```

---

## Schema

### `type` field — remove ENABLE_CLONE coupling

**Current:**
```
"Content target: 'file' reads path; 'directory' materializes a subtree to disk and requires ENABLE_LOCAL=true plus ENABLE_CLONE=true."
```

**Proposed:**
```
"Content target. 'file' (default) reads a single file. 'directory' materializes a subtree to a local path for LSP analysis — only available when the server has clone enabled. If type:'directory' is unavailable, use ghViewRepoStructure to browse structure."
```

Remove the `ENABLE_CLONE` flag reference. Agents can't query flags. The error response when it's unavailable is sufficient signal.

### `matchString` field

**Current:**
```
'Anchor text or regex; all occurrences return as merged slices; matchRanges present only when 2+ occurrences (omitted for single match). matchRanges[].start/end are 1-based file LINE NUMBERS. Structured output in results[0].files[0] (not results[0].data) — use files[0].content, files[0].startLine, files[0].endLine. Case-insensitive unless matchStringCaseSensitive is true. Not applied when minify:"symbols".'
```

**Proposed:**
```
'Text or regex to anchor the read. All occurrences are returned as merged slices. matchRanges[].start/end are 1-based line numbers — use as lineHint for lspGetSemantics. Case-insensitive by default; set matchStringCaseSensitive:true for exact case. Set matchStringIsRegex:true for regex. Mutually exclusive with startLine/endLine and fullContent. Not applied when minify:"symbols".'
```

### `minify` field

**Current:**
```
'"standard" strips comments+blanks; "none" keeps exact raw text/comments; "symbols" returns skeleton+gutter and skips matchString/charLength.'
```

**Proposed:**
```
'Output density. "symbols": skeleton+line gutter only (55–97% smaller) — use first for orientation on unknown files. "standard" (default): strips comments and blank lines. "none": exact raw text — use when quoting, diffing, or matching whitespace. When "symbols" is set, matchString and charLength are ignored.'
```

### `charLength` field

**Current:** no mention of the 1000-char default issue.

**Proposed addition:**
```
'Page size in chars. Default is small — always set explicitly for files larger than ~50 lines. Raise to 10000–50000 for large files. Read pagination.nextCharOffset from the response to continue.'
```

### `forceRefresh` field

**Current:** `"Bypass cache and re-fetch from GitHub."`

**Proposed:** `"Bypass the server-side cache and re-fetch from GitHub. Use when you need the latest commit version of a file, not a cached snapshot."`

### `matchStringIsRegex` and `matchStringCaseSensitive`
These fields have no descriptions in the current tool spec. Add:
- `matchStringIsRegex`: `"Treat matchString as a regex pattern. Use for flexible anchoring (e.g. function signatures, import patterns)."`
- `matchStringCaseSensitive`: `"Use case-sensitive matchString matching. Default is case-insensitive."`

---

## Scheme

### Fix `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH`
**File:** `octocode-tools-core/src/config.ts`

```ts
// Current — causes silent truncation on almost every real file read
export const GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 1_000;

// Proposed — covers ~200 lines of average TypeScript
export const GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 8_000;
```

### Add `superRefine` error messages to description
The schema enforces mutual exclusion silently. The tool description should state these rules:
- `fullContent`, `matchString`, and `startLine/endLine` are mutually exclusive — only one extraction mode per query
- `endLine` must be ≥ `startLine`

---

## Output

### `matchRanges` — clarify format
Current output schema: `matchRanges: z.array(z.array(z.number()))` — array of tuples.
The description must say: `matchRanges[i] = [startLine, endLine]` (1-based). Use `matchRanges[0][0]` as `lineHint`.

### `contentView` field — document what it means
```
contentView: "none"     → minify:"none" was applied — exact text
contentView: "standard" → minify:"standard" was applied — stripped
contentView: "symbols"  → minify:"symbols" was applied — skeleton only
```

### `isSkeleton` flag
Add to description: "`isSkeleton:true` means minify:'symbols' produced a structural outline. Do not parse this as real source code. Use startLine values from the gutter to anchor follow-up startLine/endLine reads."

### `warnings[]`
Document that warnings can contain redacted secret notifications — if present, the content has been modified by the security layer.
