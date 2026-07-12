# `ghCloneRepo` — Improvements

## Current State
- `ghCloneRepo` is referenced in **other tools' descriptions** as a standard research step. It is not. It requires an operator flag (`ENABLE_CLONE=true`) that AI agents cannot query, detect, or enable.
- Every reference to `ghCloneRepo` in other tools' `Next:` lines must be removed.
- The tool itself has a small and accurate schema — the only issue is description language that suggests it is always available.
- `sparsePath` is undocumented.

---

## Cross-Tool Description Cleanup (Priority 1)

Remove `ghCloneRepo` from the `Next:` guidance in all other tool descriptions. Every instance below creates a broken research chain for agents that don't have `ENABLE_CLONE`.

| Tool | Current `Next:` reference | Fix |
|------|--------------------------|-----|
| `ghViewRepoStructure` | `ghCloneRepo for local+LSP` | Replace with `ghGetFileContent(type:"directory")` |
| `ghGetFileContent` | `type:"directory" needs ENABLE_CLONE=true` | State availability is server-configured, not user-controlled |
| `lspGetSemantics` | any clone references | Remove; LSP already works on local paths from `ghGetFileContent(type:"directory")` |
| Skill / AGENTS.md | `ghCloneRepo → localViewStructure` chain | Replace with `ghGetFileContent(type:"directory") → localViewStructure(localPath)` |

**Replacement chain for deep LSP analysis:**
```
Before (broken for most agents):
ghCloneRepo(owner, repo) → localViewStructure(localPath) → localSearchCode → lspGetSemantics

After (always works):
ghGetFileContent(owner, repo, path:"src", type:"directory")
  → localViewStructure(data.directories[0].localPath)
  → localSearchCode(keywords, localPath)
  → lspGetSemantics(uri, symbolName, lineHint)
```

---

## Description

### Current
*(Operator docs only — no public agent-facing description)*

### Proposed
```
Clone a GitHub repository or subtree to a local path for deep LSP and filesystem analysis.

Availability: requires server-side ENABLE_CLONE configuration. When unavailable, the tool returns a clear error — use ghGetFileContent(type:"directory") as an alternative for subtree access.

Use cases:
- Cross-package LSP analysis that requires the full repo on disk
- Large subtree access without per-file API calls
- Offline / cached repo work (TTL-based cache, use forceRefresh to invalidate)

sparsePath: optional subdirectory to clone only that subtree — faster and smaller than a full clone.
forceRefresh: bypass the cache and re-clone from GitHub.

Output: localPath (absolute path on disk), branch, cached (true if served from cache), cloneTimeMs, totalSize, fileCount.

Next: localViewStructure(localPath), localSearchCode(keywords, localPath), lspGetSemantics for semantic analysis.
```

---

## Schema

### `sparsePath` field — add description
**Current:** no description.

**Proposed:** `"Optional subdirectory to sparse-clone. Only this path and its children are materialized on disk — significantly faster than a full repo clone for large repositories. Example: 'src/components'."`

### `forceRefresh` field
**Current:** no description.

**Proposed:** `"Bypass the clone cache and re-fetch from GitHub. Use when you need the latest commit. Default uses cached clone (TTL: 24h)."`

### `branch` field
**Current:** `"Branch, tag, or commit SHA. Omit to resolve the repository branch."`
Fine as-is.

---

## Output

### Document all output fields
```
data.localPath    → absolute path on disk; pass directly to localViewStructure, localSearchCode, lspGetSemantics
data.branch       → resolved branch name (the branch that was cloned)
data.cached       → true if served from cache; false if freshly cloned
data.sparsePath   → the subdirectory that was cloned (if requested)
data.cloneTimeMs  → clone duration in milliseconds
data.totalSize    → total bytes on disk
data.fileCount    → number of files materialized
```

### Key output signal
`data.cached:true` means the `localPath` already exists — no need to wait for a new clone. If the cache is stale, set `forceRefresh:true`.
