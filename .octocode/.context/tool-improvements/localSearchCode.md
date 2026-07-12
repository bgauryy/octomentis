# `localSearchCode` — Improvements

## Current State
- **Bug:** Description mentions `mode:"count"` which does not exist in the schema — Zod validation error for any agent that uses it
- 30 schema fields; description covers ~10; CLI uses 8
- `mode:"discovery"` and `mode:"detailed"` undocumented in practice
- All glob filters (`include`, `exclude`, `excludeDir`) undocumented
- Count modes (`countLinesPerFile`, `countMatchesPerFile`) undocumented
- 5 `superRefine` mutual exclusion rules — all silent Zod errors, none documented
- Output signals (`searchEngine`, `matchPage` pagination) not explained
- `matchContentLength` default is 500 chars — often clips long lines silently

---

## Description

### Current
```
Local ripgrep search for file+line.
Page only on hasMore; use matchPage for more matches in one file; narrow path/include/exclude/keywords before paging noisy results.
Next: localGetFileContent(path,matchString), lspGetSemantics(uri,symbolName,lineHint), localViewStructure if root unknown.
```

### Proposed
```
Local ripgrep search returning file paths, line numbers, and match snippets.

Choose mode first (drives output size):
- "paginated" (default): full match list with snippets — for reading matches
- "discovery": file paths only, no snippets — cheapest orientation, use before reading
- "detailed": expanded snippets with surrounding context — for deep reading without follow-up reads
- count mode: set countLinesPerFile:true OR countMatchesPerFile:true for count-only output

Scope before you search:
- include:["*.ts"] — glob whitelist of file patterns
- exclude:["*.min.js", "dist/**"] — glob blacklist
- excludeDir:["node_modules", "dist", ".git"] — directory skip list
- langType:"ts" — ripgrep language type (ts, js, py, go, rust, etc.)
- path must be absolute for reliable results

Match control:
- fixedString:true — literal match, disables regex
- perlRegex:true — PCRE2 features (lookaheads, backreferences)
- caseInsensitive / caseSensitive — default is case-sensitive
- wholeWord:true — whole-word boundary match
- multiline:true — cross-line pattern matching; add multilineDotall if dot must match newlines

Result budgeting:
- maxMatchesPerFile — cap matches per file (prevents flood from large files)
- maxFiles — cap total files returned
- matchContentLength — chars per snippet (default 500; raise for minified or JSON lines)
- matchPage — paginate matches within a single file (use with maxMatchesPerFile)

Mutual exclusion rules (Zod enforced — returns validation error if violated):
- filesOnly XOR filesWithoutMatch
- fixedString XOR perlRegex
- caseSensitive XOR caseInsensitive
- multilineDotall requires multiline:true
- countLinesPerFile XOR countMatchesPerFile

Output signal: searchEngine:"grep" means ripgrep was unavailable and grep was used as fallback — results may be slower and less precise.

Next: localGetFileContent(path, matchString) for exact text; lspGetSemantics(uri, symbolName, lineHint=matches[0].line) for semantic navigation.
```

---

## Schema

### Fix `mode` field description — remove `"count"` reference

**Current:**
```
'"paginated" for normal reading; "discovery" for cheap file-list-only presence checks; "detailed" for expanded snippets with surrounding context; "count" for cheapest match-count-only (no content — fastest orientation).'
```

**Proposed:**
```
'Search output mode. "paginated" (default): match list with file paths, line numbers, and snippets. "discovery": file paths only — no snippets, cheapest token cost, use for orientation. "detailed": expanded snippets with surrounding context lines — for deep reading without follow-up file reads. For count-only output, use countLinesPerFile:true or countMatchesPerFile:true instead of a mode.'
```

### `include` / `exclude` / `excludeDir` fields — add usage examples

**`include`:** `"File path include globs. Only files matching any listed glob are searched. Examples: ['*.ts', 'src/**/*.tsx']. Combine with path for double-scoping."`

**`exclude`:** `"File path exclude globs. Files matching any listed glob are skipped. Examples: ['*.min.js', 'dist/**', '**/*.d.ts']."`

**`excludeDir`:** `"Directory names to skip entirely. Examples: ['node_modules', 'dist', '.git', 'coverage', 'out']. Faster than exclude globs for directory-level skips."`

### `countLinesPerFile` / `countMatchesPerFile` fields

**`countLinesPerFile`:** `"Return matching line count per file instead of match content. Mutually exclusive with countMatchesPerFile. Use for orientation: which files have the most matches. Near-zero output tokens — much cheaper than paginated mode."`

**`countMatchesPerFile`:** `"Return total match count per file (counts multiple matches per line). Mutually exclusive with countLinesPerFile. More precise than countLinesPerFile for lines with multiple occurrences."`

### `matchContentLength` field

**Current:** `"Chars per match snippet; raise for very long lines such as minified code or JSON blobs."`

**Proposed:** `"Chars per match snippet. Default 500 — clips long lines silently. Raise to 2000–5000 for minified code, JSON, or SQL. Raise to max (100000) if snippet truncation is causing missed matches."`

### `contextLines` field

**Current:** `"Lines of context around each match."`

**Proposed:** `"Lines of context to include before and after each match. Use with mode:'detailed' for self-contained snippets that don't need a follow-up file read. Max 100."`

### `matchPage` field

**Current:** `"Per-file match page (1-based). Use with maxMatchesPerFile."`

**Proposed:** `"Per-file match pagination page. Use with maxMatchesPerFile to iterate matches within a single noisy file. Only effective when itemsPerPage limits per-file matches."`

### `sortReverse` field

**Current:** `"Reverse sort order (e.g. sort=modified + sortReverse=true → oldest first)."`

**Proposed:** `"Reverse sort order. Combined with sort:'modified' and sortReverse:true gives oldest-first — useful for finding stale code. Combined with sort:'modified' and sortReverse:false gives newest-first."`

### `filesOnly` / `filesWithoutMatch` fields

**`filesOnly`:** `"Return only file paths that contain matches, without any match content. Mutually exclusive with filesWithoutMatch. Similar to mode:'discovery' but applies after other filters."`

**`filesWithoutMatch`:** `"Return file paths that do NOT contain the pattern. Useful for finding files missing a required import, header, or declaration. Mutually exclusive with filesOnly."`

---

## Output

### Document all output signals

```
data.files[]: Array<{
  path: string           → absolute file path; use as uri for lspGetSemantics
  matchCount: number     → total matches in this file
  matches?: Array<{
    line: number         → 1-based line number; use directly as lineHint for lspGetSemantics
    value?: string       → match snippet (absent in mode:"discovery" or filesOnly:true)
    column?: number      → 1-based column of match start
  }>
  modified?: string      → last modified timestamp (when sort:"modified" used)
}>
data.pagination: {
  currentPage, totalPages, hasMore,
  totalFiles             → total matched files (not total matches)
  filesPerPage
  matchesPerPage
}
data.searchEngine: string → "ripgrep" or "grep" (grep = fallback, less reliable)
```

### Key output signals for agents
- `files[].matches[0].line` → use directly as `lineHint` for `lspGetSemantics`
- `files[].path` → use directly as `uri` for `lspGetSemantics`
- `data.pagination.hasMore:true` → paginate with `page+1`; but narrow first — paging noisy results wastes tokens
- `searchEngine:"grep"` → ripgrep unavailable; results may be incomplete or slower
- `evidence.answerReady:false` → zero results; check path and pattern before retrying
- `evidence.complete:false` → more pages exist; consider narrowing with `include`/`exclude` instead of paginating

### Consolidate dual-shape
`data.files[]` and flat `files[]` are the same. Document `data.files[]` as canonical. Flat fields are the legacy read path.
