# `ghSearchRepos` — Improvements

## Current State
- 22 schema fields; only ~6 documented or used in practice
- `verbose` mode completely undocumented — agents never use it and get lean pipe-separated strings when they need structured data
- Range filters (`stars`, `forks`, `size`) undocumented — agents don't know the format
- `topicsToSearch`, `license`, `goodFirstIssues`, `visibility`, `archived`, `match:["readme"]` all undocumented
- `sort` options undocumented
- Output format (lean strings vs structured objects) never explained

---

## Description

### Current
*(Reconstructed from schema)*
```
Discover GitHub repos by name, keywords, owner, topic, language, or popularity.
Owner alone enumerates org repos; keywords combine together. Lean output is pipe-separated strings (not filterable); verbose=true returns structured objects with stars, language, topics, dates — use verbose=true when filtering/sorting programmatically.
Next: ghViewRepoStructure, ghSearchCode/ghGetFileContent, npmSearch for npm names.
```

### Proposed
```
Search and discover GitHub repositories. Returns lean pipe-separated strings by default; verbose:true returns structured objects.

Output modes:
- verbose:false (default): fast, lean, one repo per string — use for discovery and presenting to users
- verbose:true: structured objects with stars, forks, language, topics, license, dates — required for filtering or comparing repos

Search scope:
- keywords + owner: find repos in a specific org
- owner alone (no keywords): enumerate all org repos
- topicsToSearch: filter by GitHub topics (sparser than keywords — fewer repos tag topics)
- match:["readme"]: search README text — broader, slower

Filters (all accept GitHub query format):
- stars:">100" or "50..500" — star count range
- forks:">10"
- size:"<1000" — repo size in KB
- created:">2023-01-01"
- updated:">2024-06-01" — last commit push date
- license:"mit" — SPDX identifier
- goodFirstIssues:">5" — repos actively seeking contributors
- visibility:"public" or "private"
- archived:true to include archived repos (excluded by default)

Sort: "stars" | "forks" | "updated" | "help-wanted-issues" | "best-match" (default)

Next: ghViewRepoStructure(owner, repo) to map structure; ghSearchCode for code patterns; npmSearch if the repo is an npm package.
```

---

## Schema

### `verbose` field
**Current:** `"Set true for structured repository objects with owner/repo, metadata, topics, dates, and url."`

**Proposed:** `"Output mode. false (default): pipe-separated lean strings — fast, good for discovery. true: structured objects with stars, forks, language, license, topics, dates, url — required when filtering programmatically or comparing repos. Always set true when your goal involves ranking, filtering, or presenting repo metadata."`

### `stars`, `forks`, `size` fields — add format examples
**Current:** just `"Star-count filter ('>100', '50..500')."` etc.

**Proposed additions:**
- `stars`: `"Star-count filter. Format: '>100', '<1000', '50..500', '>=500'. Use to narrow discovery to established or niche repos."`
- `forks`: `"Fork-count filter. Same format as stars. High forks = widely used base."`
- `size`: `"Repo size filter in KB. '<1000' for small repos. '>10000' for large codebases."`

### `created`, `updated` fields
**Current:** `"Repo creation date/window."` / `"Last code-push date/window."`

**Proposed:**
- `created`: `"Repo creation date. Format: '>2023-01-01', '<2020-01-01', '2022-01-01..2023-01-01'. Use to find recently created or older established repos."`
- `updated`: `"Last commit push date (maps to GitHub pushed: qualifier). '>2024-01-01' for actively maintained repos. Not a metadata update date — it tracks actual code pushes."`

### `match` field
**Current:** `"Repository text fields to search: name, description, and/or readme."`

**Proposed:** `"Which repo text fields to search keywords in. Default searches name and description. Add 'readme' to search README content — broader results but slower. Use ['name'] for the most precise repo name match."`

### `topicsToSearch` field
**Current:** `"Self-reported GitHub topics. Sparse — fewer repos tag topics than set a language."`

**Proposed:** `"GitHub topic tags to filter by. Repos must have all listed topics. Sparse — most repos don't tag topics. Best used in combination with keywords or language, not alone. Example: ['react', 'typescript'] for repos tagged with both."`

### `goodFirstIssues` field
**Current:** `"Filter by number of 'good first issue' labels ('>5')."`

**Proposed:** `"Filter by number of open 'good first issue' labeled issues. Use '>5' to find repos actively inviting contributors. Combine with sort:'help-wanted-issues' for best results."`

### `sort` field
**Current:** `"Sort field: 'stars' | 'forks' | 'help-wanted-issues' | 'updated' | 'best-match'."`

**Proposed:** `"Sort order. 'best-match' (default): GitHub relevance ranking. 'stars': most popular first. 'forks': most forked first. 'updated': recently pushed first — best for finding active repos. 'help-wanted-issues': repos seeking contributors."`

---

## Output

### Document verbose vs lean output shapes explicitly

**Lean (verbose:false):**
```
results[].data.repositories[]: string[]   → pipe-separated: "owner|repo"
```

**Structured (verbose:true):**
```
results[].data.repositories[]: Array<{
  owner: string
  repo: string
  stars?: number
  forks?: number
  openIssuesCount?: number
  language?: string
  license?: string
  description?: string
  homepage?: string
  pushedAt?: string      → last commit push date
  createdAt?: string
  defaultBranch?: string
  topics?: string[]
  visibility?: string
  url?: string
  updatedAt?: string     → metadata update date (different from pushedAt)
}>
```

### Add output signal documentation
- `evidence.answerReady:false` + zero results → keywords too narrow, try broader terms or remove filters
- `pagination.totalMatchesKind:"lowerBound"` → GitHub capped the count; result set is a sample
- `pagination.hasMore:true` → paginate with `page+1`
