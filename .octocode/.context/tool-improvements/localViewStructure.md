# `localViewStructure` — Improvements

## Current State
- 18 schema fields; most undocumented in descriptions
- `pattern`, `extensions[]`, `filesOnly`, `directoriesOnly`, `showFileLastModified`, `sortBy:"time"`, `reverse`, `hidden`, `details`, `limit` — all undocumented
- Mutual exclusion (`filesOnly` XOR `directoriesOnly`) is a Zod error — not documented
- Output shape (`files[]`, `folders[]`, `entries[]`, `summary`) not explained
- No guidance on when to use this vs `localFindFiles` or `localSearchCode(mode:"discovery")`

---

## Description

### Current
*(Reconstructed from schema)*
```
Inspect local directory tree and separate implementation from tests, fixtures, docs, generated output.
Output keys: files[] and folders[] at each level (data.tree is not populated — use files[]/folders[]). Paginate with page=N when hasMore is true.
Next: localGetFileContent(path), localSearchCode, lspGetSemantics after localSearchCode gives uri/symbolName/lineHint.
```

### Proposed
```
Browse a local directory tree. Returns files[], folders[], and a summary.

When to use vs alternatives:
- Use this to map a directory's layout before searching
- Use localFindFiles when you need metadata (size, modified date) or filename patterns
- Use localSearchCode(mode:"discovery") when you need to find which files contain a pattern

Scope and filter:
- depth: recursion depth (0 = immediate children only, max 20)
- pattern: filename glob or substring filter — only entries matching are returned
- extensions:["ts","tsx"] — file extension whitelist
- filesOnly:true — return only files (mutually exclusive with directoriesOnly)
- directoriesOnly:true — return only directories (mutually exclusive with filesOnly)
- hidden:true — include dot files and dot directories
- limit: cap total entries discovered

Sorting:
- sortBy:"name" (default) | "size" | "time" | "extension"
- reverse:true — reverse sort order (e.g. sortBy:"time" + reverse:true = oldest first)
- showFileLastModified:true — include timestamps per entry (independent of details)

Rich metadata:
- details:true — adds size and permissions per entry (enables entries[] output)

Pagination: when hasMore:true, increment page — itemsPerPage controls entries per page (max 50).

Mutual exclusion (Zod enforced — returns validation error):
- filesOnly and directoriesOnly cannot both be true

Output:
- files[]: file name strings at this directory level
- folders[]: subdirectory name strings at this level
- entries[]: structured objects {path, name, type, size?, modified?} — populated when details:true
- summary: human-readable entry count

Next: localGetFileContent(path) to read a file; localSearchCode(keywords, path) to search within.
```

---

## Schema

### `pattern` field — add description

**Current:** no description.

**Proposed:** `"Filename or directory name filter — glob (e.g. '*.ts', 'test*') or plain substring. Only entries whose name matches are returned. Applies to both files and folders. Use for targeted browsing of large directories."`

### `extensions` field

**Current:** no description.

**Proposed:** `"File extension whitelist (without dot). Example: ['ts', 'tsx', 'js']. Only files with a matching extension are returned. Ignored for directories. Combine with depth for scoped file discovery."`

### `filesOnly` / `directoriesOnly` fields

**`filesOnly`:** `"Return only files, no directories. Mutually exclusive with directoriesOnly. Use for flat file lists within a directory."`

**`directoriesOnly`:** `"Return only directories, no files. Mutually exclusive with filesOnly. Use to map a project's folder structure without listing files."`

### `hidden` field

**Current:** no description.

**Proposed:** `"Include hidden files and directories (names starting with '.'). Default false. Enable to see .env, .git, .github, .agents directories."`

### `showFileLastModified` field

**Current:** no description.

**Proposed:** `"Include last-modified timestamp per file entry. Independent of details:true. Enable when you need to identify recently changed files without switching to localFindFiles."`

### `sortBy` field

**Current:** default set to `"name"` but no description.

**Proposed:** `"Sort entries by: 'name' (default, alphabetical), 'size' (bytes), 'time' (last modified), 'extension' (file type grouping). Combine with reverse:true for descending order."`

### `reverse` field

**Current:** no description.

**Proposed:** `"Reverse the sort order. With sortBy:'time' + reverse:true → oldest files first. With sortBy:'size' + reverse:true → smallest files first."`

### `details` field

**Current:** no description.

**Proposed:** `"Include size and permissions per entry. Enables the entries[] output array with structured objects instead of just file/folder name strings. Use when you need to identify large files or check permissions."`

### `limit` field

**Current:** no description.

**Proposed:** `"Cap on total discovered entries before pagination. Use to prevent large directory scans from flooding output. Default uncapped. Set to 100–500 for focused exploration of large codebases."`

### `depth` field

**Current:** no description.

**Proposed:** `"Recursion depth. 0: immediate children only. 1: one level of subdirectories. Max 20. For deep monorepos, start with depth:2 to get the project structure, then drill into specific subdirectories."`

---

## Output

### Document the output shape

```
data: {
  path?: string         → the browsed directory path
  files?: string[]      → file names at this level
  folders?: string[]    → subdirectory names at this level
  entries?: Array<{     → structured entries (only when details:true)
    path: string
    name: string
    type: "file" | "directory" | "symlink"
    size?: number       → bytes
    modified?: string   → ISO timestamp
  }>
  summary?: string      → e.g. "14 entries (11 files, 3 dirs, 67.9KB)"
  pagination?: {
    currentPage, totalPages, hasMore, totalEntries, entriesPerPage
  }
}
```

### Key output signals
- `hasMore:true` → pass `page+1` with same `path` and options to get more entries
- `summary` → read this first — tells you if the directory is large before reading all entries
- `entries[].modified` → only present when `showFileLastModified:true` or `details:true`
- `entries[].size` → only present when `details:true`

### When to use each output path
- Quick orientation: read `summary` + `folders[]` only
- Find specific files: use `pattern` or `extensions` to filter before reading
- Metadata needed: set `details:true` and read `entries[]`
- Recent changes: set `showFileLastModified:true` and `sortBy:"time"`
