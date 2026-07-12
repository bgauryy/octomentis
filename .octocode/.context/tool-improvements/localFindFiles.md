# `localFindFiles` — Improvements

## Current State
- Virtually undocumented — the skill barely mentions this tool despite it being the most efficient way to answer temporal and metadata queries
- No field descriptions in the resource spec
- `modifiedWithin`, `modifiedBefore`, `accessedWithin` — no format examples documented
- `sizeGreater`, `sizeLess` — no format examples
- `pathPattern` for monorepo slice filtering — completely unknown to agents
- `regex` for Rust regex against basename — completely unknown
- `sortBy:"modified"` — the most useful default for "what changed" queries — not documented
- `entryType:"d"` — directory-only finds — not documented
- `minDepth`/`maxDepth` interaction not documented (and has a Zod validation rule)

---

## Description

### Current
*(Minimal — reconstructed from schema)*
```
Find local paths by basename glob, full-path glob, Rust basename regex, size, or time; returns metadata, not content.
Next: localGetFileContent(path), localSearchCode for content, lspGetSemantics after a content hit.
```

### Proposed
```
Find local files and directories by metadata — name pattern, path glob, size, modification time, permissions. Returns paths and metadata, not file content. Significantly cheaper than localSearchCode when you only need file locations.

When to use instead of localSearchCode:
- "What files changed recently?" → modifiedWithin:"24h", sortBy:"modified"
- "Find all test files in src/" → names:["*.test.ts"], pathPattern:"src/**"
- "Find large files" → sizeGreater:"1m", sortBy:"size"
- "Find all index files" → regex:"^index\\."
- "Find directories" → entryType:"d"

Name matching (pick one per query):
- names:["*.ts","*.tsx"] — basename glob array, any match
- pathPattern:"packages/*/src/**" — full-path glob (monorepo slice filter)
- regex:"^(index|main)\\.(ts|js)$" — Rust regex against basename only

Time filters (format: "7d", "2h", "30m"):
- modifiedWithin:"24h" — modified in the last 24 hours
- modifiedBefore:"30d" — not modified in the last 30 days (stale files)
- accessedWithin:"1h" — recently accessed

Size filters (format: "100k", "1m", "500b"):
- sizeGreater:"1m" — larger than 1 MB
- sizeLess:"10k" — smaller than 10 KB

Depth: maxDepth:2 for shallow; combine minDepth + maxDepth for a depth window.
entryType:"f" — files only; entryType:"d" — directories only.

Validation rule (Zod enforced): minDepth must be <= maxDepth.

Sorting:
- sortBy:"modified" (default) + showFileLastModified:true — newest files first
- sortBy:"size" — largest files first
- sortBy:"name" — alphabetical
- sortBy:"path" — full path alphabetical

Next: localGetFileContent(path) to read a found file; localSearchCode(keywords, path) to search content.
```

---

## Schema

All field descriptions are currently missing from the resource spec. Add:

### `names[]` field
`"Basename glob array. Any listed glob may match — OR logic between globs. Example: ['*.ts', '*.tsx', 'package.json']. Use for extension-based or name-pattern file discovery."`

### `pathPattern` field
`"Full-path glob filter. Matches files whose full repo-relative path matches this glob. Use for monorepo slice filtering: 'packages/*/src/**' finds src directories across all packages. More precise than names[] when directory context matters."`

### `regex` field
`"Rust regex pattern against the basename only (not full path). Use for complex name patterns that glob syntax can't express. Example: '^(index|main)\\.(ts|js)$' matches index.ts, main.js etc. More powerful than names[] for precise matching."`

### `modifiedWithin` field
`"Only include files modified within the past N. Format: '7d' (days), '2h' (hours), '30m' (minutes). Use for 'what changed recently' queries. Maps to find -mtime."`

### `modifiedBefore` field
`"Only include files NOT modified in the past N — last touched more than N ago. Format same as modifiedWithin. Use to find stale or abandoned files."`

### `accessedWithin` field
`"Only include files accessed within the past N. Format same as modifiedWithin. Less reliable than modifiedWithin on some filesystems."`

### `sizeGreater` field
`"Only include files larger than this size. Format: '100k' (kilobytes), '1m' (megabytes), '500b' (bytes). Use to find large generated files, bundles, or assets."`

### `sizeLess` field
`"Only include files smaller than this size. Same format as sizeGreater. Combine with names[] to find unexpectedly small config or entry files."`

### `sortBy` field
`"Sort found entries. 'modified' (default): newest-modified first. 'size': largest first. 'name': alphabetical basename. 'path': alphabetical full path. Always combine with showFileLastModified:true when using 'modified'."`

### `entryType` field
`"Entry kind to match. 'f': files only. 'd': directories only. Omit to match both."`

### `minDepth` / `maxDepth` fields
`"Depth bounds relative to the search root. maxDepth:0 = root only. maxDepth:1 = root and immediate children. Combine minDepth + maxDepth for a depth window (e.g. minDepth:2 + maxDepth:2 = exactly two levels deep). Validation: minDepth must be <= maxDepth."`

### `showFileLastModified` field
`"Include last-modified timestamps in output. Required to see modification dates when sortBy:'modified'. Default false."`

### `details` field
`"Include size and permissions per entry. Enables size-based output reading."`

### `limit` field
`"Cap on total discovered entries. Use to prevent large directory scans. Max 10000."`

### `executable` / `readable` / `writable` fields
`"Filter by file permission: executable/readable/writable by the current process. Use for finding scripts, config files, or permission issues."`

---

## Output

### Document the output shape

```
data: {
  files: Array<{
    path: string           → absolute file path
    type?: string          → "file" | "directory" | "symlink"
    size?: number          → bytes (when details:true or sizeGreater/sizeLess used)
    modified?: string      → ISO timestamp (when showFileLastModified:true)
    permissions?: string   → octal permissions string (when details:true)
  }>
  pagination?: {
    currentPage, totalPages, hasMore, totalFiles, filesPerPage
  }
}
```

### Key usage patterns

**Recent changes:**
```
{ path, modifiedWithin:"24h", sortBy:"modified", showFileLastModified:true }
→ files[0] is the most recently changed file
```

**Scoped test files:**
```
{ path, names:["*.test.ts","*.spec.ts"], pathPattern:"src/**" }
→ all test files under src/
```

**Large generated files:**
```
{ path, sizeGreater:"500k", sortBy:"size", details:true }
→ biggest files first
```

**Monorepo package entry points:**
```
{ path, regex:"^index\\.(ts|js)$", pathPattern:"packages/*/src/**" }
→ all package entry files
```

**Stale source files:**
```
{ path, include:["*.ts"], modifiedBefore:"90d", sortBy:"modified", sortReverse:true }
→ files not touched in 3+ months
```
