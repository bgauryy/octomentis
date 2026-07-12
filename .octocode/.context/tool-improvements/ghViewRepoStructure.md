# `ghViewRepoStructure` — Improvements

## Current State
- Description is accurate but doesn't explain when to choose this vs `ghSearchCode(match:"path")`
- `verbose` flag undocumented — agents never use it
- `depth` field description missing — agents don't know defaults or limits
- Output shape (`files[]`, `folders[]`, `entries[]`, `summary`) not explained — agents parse blindly
- No guidance on using `path` for subtree browsing vs repo root

---

## Description

### Current
*(Not available — reconstructed from schema)*
```
Inspect GitHub repo tree and separate implementation from tests, fixtures, docs, generated code.
Output key is structure[] (array of {dir, files[], folders[]}), not tree. Paginate with page=N when hasMore is true — total entries shown in pagination.
Next: ghGetFileContent(path), ghSearchCode, ghCloneRepo for local+LSP.
```

### Proposed
```
Browse a GitHub repository's directory tree. Returns files[], folders[], and a summary for each level.

When to use vs alternatives:
- Use this to map an unknown repo's layout before searching
- Use ghSearchCode(match:"path") when you already know a partial file name — faster
- Use ghGetFileContent(path, type:"directory") when you need a local subtree for LSP work

Scoping:
- Omit path for repo root
- Set path:"src" to browse a subtree
- Set depth to control recursion (default shallow; max 20)
- Set verbose:true to get file sizes and last-modified dates per entry

Pagination: when hasMore:true, increment page — itemsPerPage controls entries per page (max 200).

Output structure:
- files[]: file paths at this level
- folders[]: subdirectory paths at this level  
- entries[]: combined list with type, size, modified (only when verbose:true)
- summary: total entry count string

Next: ghGetFileContent for file content; ghSearchCode to search within a known path.
```

---

## Schema

### `verbose` field
**Current:** no description set.

**Proposed:** `"Set true to include file size and last-modified date per entry in entries[]. Default false returns only paths. Enable when you need to identify large files or recently changed files."`

### `depth` field
**Current:** no description set.

**Proposed:** `"Recursion depth for nested tree output. 0 = immediate children only. Max 20. Raise to expose deeper subtrees in one call. Default is shallow (typically 1–2 levels)."`

### `path` field
**Current:** no description.

**Proposed:** `"Repo-relative directory to browse. Omit or use empty string for repo root. Use a subdirectory path (e.g. 'src/utils') to scope the tree. No leading slash."`

### `itemsPerPage` field
**Current:** no description.

**Proposed:** `"Entries per page. Max 200. Raise to get more entries in one call when the repo has many files. Default 100."`

### Remove from description: any `ghCloneRepo` reference
The current description likely references clone for local+LSP. Replace with:
`"Next: ghGetFileContent for file content; lspGetSemantics after localSearchCode for semantic analysis."`

---

## Output

### Document the output shape explicitly
The output has two shapes — always document the canonical one:

```
data.files[]      → file paths (strings) at this directory level
data.folders[]    → subdirectory paths (strings) at this level
data.entries[]    → [{path, name, type, size?, modified?}] — only when verbose:true
data.summary      → human-readable entry count (e.g. "14 entries (11 files, 3 dirs)")
data.pagination   → {currentPage, totalPages, hasMore, totalEntries, entriesPerPage}
```

### Add output signal documentation
- `hasMore:true` → pass `page+1` to get more entries — same `path` and `depth`
- `entries[].modified` → only present when `verbose:true`
- `entries[].size` → bytes — only present when `verbose:true`

### Consolidate dual-shape
`data.files[]` and flat `files[]` carry the same data. Document `data.*` as canonical. Mark flat fields as the legacy read path for backward compatibility.
