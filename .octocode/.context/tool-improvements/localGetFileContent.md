# `localGetFileContent` — Improvements

## Current State
- `minify:"symbols"` use case is in the description but not explained well enough — agents default to `"standard"` even when orientation is all they need
- `matchStringIsRegex` and `matchStringCaseSensitive` have descriptions but are rarely used because agents don't know when they need them
- Mutual exclusion (`fullContent` XOR `matchString` XOR `startLine/endLine`) not stated in description — silent Zod errors
- `matchRanges[]` output not connected to LSP handoff pattern — agents miss the lineHint
- `isPartial` and `isSkeleton` output signals unexplained
- `charOffset` continuation pattern vague — agents compute manually instead of reading `pagination.nextCharOffset`
- `lastModified` / `lastModifiedBy` output fields completely undocumented

---

## Description

### Current
```
Read local file/region.
Choose mode by goal: readable page, exact text, or skeleton gutter.
Use matchString or startLine/endLine for focused reads; charOffset/charLength continues partial content.
Next: lspGetSemantics(uri,symbolName,lineHint), localSearchCode before unknown symbols.
```

### Proposed
```
Read a local file or region. Choose one extraction mode per query — these are mutually exclusive:

- matchString: find all occurrences of text/regex across the file; returns merged slices + matchRanges line numbers
- startLine/endLine: read a specific line range (1-based)
- fullContent: read the entire file — reserve for small files only
- default (nothing set): reads first charLength chars from line 1

Choose minify mode by goal:
- "symbols": skeleton + line gutter only, 55–97% smaller — use first on any unknown file for fast orientation
- "standard" (default): strips comments and blank lines — normal investigation reads
- "none": exact raw text including comments — use when quoting, testing, or matching whitespace

Mutual exclusion rules (Zod enforced — validation error if violated):
- fullContent, matchString, and startLine/endLine are mutually exclusive
- endLine must be >= startLine

Output signals:
- isPartial:true → response was capped by charLength; use pagination.nextCharOffset to continue
- isSkeleton:true → minify:"symbols" was applied; content is structural outline, not source
- matchRanges[i] = [startLine, endLine] (1-based) → line numbers of each matchString hit; matchRanges[0][0] is the lineHint for lspGetSemantics
- lastModified → file modification timestamp
- warnings[] → security layer redacted content (secrets removed)

Continuation: read pagination.nextCharOffset from the response — do not compute charOffset manually.

Next: lspGetSemantics(uri=path, symbolName, lineHint=matchRanges[0][0]) for semantic navigation; localSearchCode before reading if the symbol location is unknown.
```

---

## Schema

### `minify` field — sharpen the symbols description

**Current:** `'"standard" strips comments+blanks; "none" keeps exact raw text/comments; "symbols" returns skeleton+gutter and skips matchString/charLength.'`

**Proposed:** `'"symbols": structural skeleton with line numbers in the gutter — 55–97% smaller than source. Use for orientation on any unknown file before reading details. matchString and charLength are ignored in symbols mode. "standard" (default): strips comments and blank lines. "none": exact raw text — use when quoting or matching whitespace precisely.'`

### `matchString` field — connect to LSP handoff

**Current:** `'Anchor text or regex; all occurrences return as merged slices; matchRanges present only when 2+ occurrences (omitted for single match). matchRanges[].start/end are 1-based file LINE NUMBERS (use as lineHint for lspGetSemantics). startLine/endLine are the overall window bounds. Case-insensitive unless matchStringCaseSensitive is true. Not applied when minify:"symbols".'`

**Proposed:** `'Text or regex anchor. All occurrences are returned as merged slices. matchRanges[i].start/end are 1-based line numbers — use matchRanges[0].start directly as lineHint for lspGetSemantics. Mutually exclusive with startLine/endLine and fullContent. Case-insensitive by default; set matchStringCaseSensitive:true for exact case. Set matchStringIsRegex:true to treat as regex. Not applied when minify:"symbols".'`

### `charOffset` field

**Current:** `"Continuation char offset from a prior partial page. Compute as pagination.charOffset+pagination.charLength, or read the value from the hint."`

**Proposed:** `"Char offset for continuation reads. Do not compute manually — read pagination.nextCharOffset from the prior response and pass it here directly. Start at 0 (default). Only needed when isPartial:true in the previous response."`

### `charLength` field

**Current:** `"Char page size."`

**Proposed:** `"Page size in chars. Set explicitly for any file larger than ~100 lines — default is small and will silently truncate. Use 5000–20000 for normal source files. Use 50000 (max) for large generated files. Check isPartial:true in the response to know if truncation occurred."`

### `contextLines` field

**Current:** `"Lines of context around each matchString hit."`

**Proposed:** `"Lines of context to include before and after each matchString hit. Default 5. Raise to 20–50 when you need surrounding function body without a separate startLine/endLine read. Max 100."`

### `matchStringIsRegex` field

**Current:** `"Treat matchString as a regex pattern."`

**Proposed:** `"Treat matchString as a JavaScript-compatible regex pattern. Use for flexible anchoring: function signatures, import paths, JSDoc tags, etc. Example: 'export (default )?function\\w+' to find all exported functions."`

### `fullContent` field

**Current:** `"Whole file. Exclusive with matchString and startLine/endLine — reserve for small files."`

**Proposed:** `"Read the entire file. Mutually exclusive with matchString and startLine/endLine. Reserve for files you know are small (< a few hundred lines). For large files, use matchString or startLine/endLine to read targeted regions, or charLength to page through."`

---

## Output

### Document all output signals

```
data: {
  path: string                → absolute file path
  content: string             → file content (may be partial or skeleton)
  contentView?: "none" | "standard" | "symbols"  → which minify mode was actually applied
  isSkeleton?: boolean        → true when minify:"symbols"; content is outline, not source
  totalLines?: number         → total line count in the full file
  startLine?: number          → first line returned (1-based)
  endLine?: number            → last line returned (1-based)
  isPartial?: boolean         → true when charLength capped the response
  matchRanges?: Array<[number, number]>  → [startLine, endLine] per matchString hit (1-based)
  pagination?: {
    hasMore: boolean
    charOffset: number
    charLength: number
    totalChars: number
    nextCharOffset: number    → use this as charOffset in the next call
  }
  lastModified?: string       → file last modified timestamp
  lastModifiedBy?: string     → last commit author (if available)
}
```

### Key reading patterns

**Pattern 1 — Orientation:**
```
minify:"symbols"  → get skeleton with line numbers
→ pick the line range you need
→ re-call with startLine/endLine, minify:"standard"
```

**Pattern 2 — Symbol anchor:**
```
matchString:"functionName"  → get matchRanges
→ lspGetSemantics(uri=path, symbolName="functionName", lineHint=matchRanges[0][0])
```

**Pattern 3 — Large file pagination:**
```
charLength:10000  → read first 10000 chars
→ if isPartial:true → re-call with charOffset=pagination.nextCharOffset
```

**Pattern 4 — Exact quote:**
```
matchString:"exact text"
minify:"none"  → get exact content without stripping
```

### Consolidate dual-shape
`data.*` fields are canonical. Flat `path`, `content`, `contentView`, `isSkeleton`, `pagination` are the legacy read path. Document `data.*` as the one to use.
