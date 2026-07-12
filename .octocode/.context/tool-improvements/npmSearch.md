# `npmSearch` — Improvements

## Current State
- 4 fields total — smallest schema of all 12 tools
- `mode` field is undocumented in practice — agents always get `"smart"` behavior without understanding what it means
- `mode:"lean"` vs `mode:"full"` distinction never explained — agents never choose
- `page` for keyword result pagination — never documented
- Output shape (lean strings vs rich objects) never explained
- No guidance on exact name vs keyword search behavior

---

## Description

### Current
*(Reconstructed from schema)*
```
npm lookup returning package identity, metadata, and source-repo handoff when available.
Mode controls enrichment; smart keeps exact hits rich and broad searches lean. Exact package name returns one canonical rich result; keyword queries return lean results with no totalMatches count — use page to paginate keyword results.
Next: ghViewRepoStructure, ghSearchCode, ghGetFileContent when owner/repo exists.
```

### Proposed
```
npm package lookup and keyword search. Returns package metadata and source repository handoff.

Two behaviors based on packageName:
- Exact package name (e.g. "react", "@octokit/rest"): returns one rich result with full metadata — version, description, keywords, repository URL, owner/repo
- Keyword query (e.g. "http client typescript"): returns lean results list with no total count — paginate with page

Output modes:
- "smart" (default): exact name → full rich result; keyword query → lean result. Use this for all standard lookups.
- "full": always rich output regardless of exact vs keyword — use when you need metadata for a known exact name and want to ensure richness
- "lean": always lean output — use for keyword discovery when you only need names and want minimal tokens

Source repo handoff:
- When the package has a GitHub repository, owner and repo are present in the result
- Pass owner+repo directly to ghViewRepoStructure, ghSearchCode, or ghGetFileContent

Pagination: keyword results only; exact name lookups always return one result regardless of page.

Next: ghViewRepoStructure(owner, repo) to browse package source; ghSearchCode to search its code; ghGetFileContent for specific files.
```

---

## Schema

### `mode` field

**Current:** `'Enrichment mode: "smart", "full", or "lean".'`

**Proposed:** `'Output enrichment. "smart" (default): exact package name → rich metadata; keyword query → lean list. "full": always rich — guarantees version, description, keywords, repository, maintainers regardless of query type. "lean": always minimal — package name and basic info only; lowest token cost for keyword discovery. Use "smart" for all standard lookups.'`

### `packageName` field

**Current:** `"Exact npm package name or keyword query."`

**Proposed:** `"npm package name or keyword search query. An exact package name (e.g. 'react', '@octokit/rest') returns one canonical rich result. A keyword query (e.g. 'typescript http client') returns a lean list of matching packages. Scoped packages need the full scope: '@octokit/rest' not 'rest'."`

### `page` field

**Current:** `"Keyword-result page. Exact package names return one canonical package."`

**Proposed:** `"Pagination page for keyword search results (1-based). Exact package name lookups always return page 1 regardless. Use when keyword results have more matches — no total count is returned, so paginate until results thin out."`

---

## Output

### Document lean vs rich output shapes

**Rich output (exact name or mode:"full"):**
```
packages[0]: {
  name: string
  version: string
  description?: string
  keywords?: string[]
  repository?: {
    url: string          → GitHub URL when available
    owner?: string       → GitHub owner (use for ghViewRepoStructure)
    repo?: string        → GitHub repo name
  }
  maintainers?: string[]
  license?: string
  homepage?: string
  downloads?: number
  weeklyDownloads?: number
  lastPublished?: string
}
```

**Lean output (keyword search or mode:"lean"):**
```
packages[]: string[]    → package names only, pipe-separated or array
pagination?: {
  currentPage, totalPages, perPage, totalFound, returned, hasMore
}
```

### Key output signals
- `repository.owner` + `repository.repo` → pass directly to `ghViewRepoStructure` or `ghSearchCode`
- `pagination.hasMore:true` → increment `page` to get more keyword results
- No result for exact name → package doesn't exist on npm or was unpublished
- `evidence.answerReady:false` → zero results; try broader keyword terms
