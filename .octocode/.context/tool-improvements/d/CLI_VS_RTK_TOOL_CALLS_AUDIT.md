# CLI vs RTK Tool Calls — Quality & Token Audit

> **RTK** = pi MCP runtime tool calls (`octocode_local_*`) — the full MCP schema exposed to AI agents.  
> **CLI** = octocode-cli source tool calls — what `octocode pr` / `octocode search` actually send.

---

## What Was Checked

### Files Inspected

| File | What Was Read |
|------|---------------|
| `packages/octocode-cli/src/cli/commands/pr.ts` | `fetchPRList()` and `fetchPRDetail()` — full query objects sent to `ghSearchPRs` |
| `packages/octocode-cli/src/cli/commands/search.ts` | `searchLocal()` and `searchGithub()` — full query objects sent to `localSearchCode` / `ghSearchCode` |
| `packages/octocode-cli/src/cli/commands/specs.ts` | CLI command help specs — flags exposed to users |
| `packages/octocode-cli/out/octocode-cli.js` | Compiled entry point (5 KB) — confirms chunk layout |
| `packages/octocode-tools-core/dist/tools/github_search_pull_requests/scheme.d.ts` | Full `ghSearchPRs` Zod schema — all available fields |
| `packages/octocode-tools-core/dist/tools/local_ripgrep/scheme.d.ts` | Full `localSearchCode` Zod schema — all available fields |

### Tools Compared

- `ghSearchPRs` — list mode (`fetchPRList`)
- `ghSearchPRs` — detail/view mode (`fetchPRDetail`)
- `localSearchCode` — local search (`searchLocal`)
- `ghSearchCode` — GitHub search (`searchGithub`) *(partial, see below)*

---

## `ghSearchPRs` — List Mode

**CLI sends** (`pr.ts:419–442`):
```ts
{
  owner, repo,
  keywordsToSearch: opts.query ? [opts.query] : undefined,
  state, author, label, base,
  page: opts.page ?? 1,
  itemsPerPage: opts.pageSize,
  mainResearchGoal: 'List pull requests',
  researchGoal: `List PRs for ${owner}/${repo}`,
  reasoning: 'CLI pr command list mode',
}
```
**Fields used: 12 of 35+**

| Feature | CLI | RTK | Schema field |
|---------|-----|-----|--------------|
| Basic filters | ✅ | ✅ | `state`, `author`, `label`, `base` |
| Sort results | ❌ | ✅ | `sort`, `order` |
| Date windows | ❌ | ✅ | `created`, `updated`, `merged-at`, `closed` |
| Draft filter | ❌ | ✅ | `draft` |
| Keyword scope | ❌ | ✅ | `match: ['title'\|'body'\|'comments']` |
| Relationship filters | ❌ | ✅ | `commenter`, `involves`, `review-requested`, `reviewed-by`, `mentions` |
| Negation filters | ❌ | ✅ | `no-label`, `no-milestone`, `no-project`, `no-assignee` |
| Rich metadata | ❌ | ✅ | `verbose` |
| Response size control | ❌ | ✅ | `minify`, `responseCharLength`, `responseCharOffset` |
| Reaction/comment count filters | ❌ | ✅ | `reactions`, `comments`, `interactions` |
| Archive scope | ❌ | ✅ | `archived` |

---

## `ghSearchPRs` — Detail Mode

**CLI sends** (`pr.ts:493–520`):
```ts
{
  owner, repo, prNumber,
  content: { metadata: true, body: true, changedFiles: true, patches?, comments?, commits?, reviews? },
  reviewMode: opts.deep ? 'full' : undefined,
  matchString: opts.matchString,
  filePage, commentPage, commitPage, itemsPerPage,
  mainResearchGoal: 'View pull request details',
  researchGoal: `View PR #${prNumber} in ${owner}/${repo}`,
  reasoning: 'CLI pr command view mode',
}
```
**Fields used: 13 of 35+**

| Feature | CLI | RTK | Schema field |
|---------|-----|-----|--------------|
| Content surfaces | ✅ good | ✅ | `content.metadata/body/changedFiles/patches/comments/commits/reviews` |
| Patch mode selection | ✅ | ✅ | `content.patches.mode` (none/selected/all) |
| Per-file patch | ✅ `--file` | ✅ | `content.patches.files[]` |
| `reviewMode: 'full'` | ✅ only with `--deep` | ✅ | `reviewMode` |
| **Response minification** | ❌ absent | ✅ | **`minify`** |
| **Body pagination** | ❌ absent | ✅ | **`charOffset`**, **`charLength`** |
| Per-file line ranges | ❌ | ✅ | `content.patches.ranges[].additions/deletions` |
| Bot comment filter | ❌ | ✅ | `content.comments.includeBots` |

**Critical:** No `minify` means a large PR diff/body returns full unminified YAML on every CLI call. A 50-file diff PR can return 3–5× more tokens than necessary.

---

## `localSearchCode` — Biggest Gap

**CLI sends** (`search.ts:53–75`):
```ts
{
  keywords: pattern,
  path: dirPath,
  langType: typeFilter,
  page,
  itemsPerPage: pageSize,
  mainResearchGoal: 'Search local codebase',
  researchGoal: `Find "${pattern}" in ${dirPath}`,
  reasoning: 'CLI search command',
}
```
**Fields used: 8 of 30+**

| Feature | CLI | RTK | Schema field |
|---------|-----|-----|--------------|
| Language filter | ✅ `--type` | ✅ | `langType` |
| Search mode | ❌ always `paginated` | ✅ | `mode` (paginated/discovery/detailed) |
| Glob include/exclude | ❌ | ✅ | `include[]`, `exclude[]`, `excludeDir[]` |
| Case control | ❌ | ✅ | `caseInsensitive`, `caseSensitive`, `wholeWord` |
| Regex type | ❌ | ✅ | `fixedString`, `perlRegex` |
| Context lines | ❌ | ✅ | `contextLines` |
| Match budget | ❌ | ✅ | `maxMatchesPerFile`, `maxFiles`, `matchContentLength` |
| File-only mode | ❌ | ✅ | `filesOnly`, `filesWithoutMatch` |
| Count mode | ❌ | ✅ | `countLinesPerFile`, `countMatchesPerFile` |
| Invert match | ❌ | ✅ | `invertMatch` |
| Hidden/noIgnore | ❌ | ✅ | `noIgnore`, `hidden` |
| Multiline regex | ❌ | ✅ | `multiline`, `multilineDotall` |
| Sort control | ❌ | ✅ | `sort`, `sortReverse` |
| Per-file match page | ❌ | ✅ | `matchPage` |

**CLI `--search` flags exposed to users:** `--type`, `--limit`, `--page`, `--page-size`, `--branch`, `--json`  
All other ripgrep capabilities are schema-available but unreachable from the CLI surface.

---

## `ghSearchCode` — Partial Check

**CLI sends** (`search.ts:86–115`):
```ts
{
  keywordsToSearch: [pattern],
  owner, repo,
  extension: typeFilter,
  path: subpath,
  page, limit: pageSize,
  mainResearchGoal: 'Search GitHub codebase',
  researchGoal: `Find "${pattern}" in ${owner}/${repo}`,
  reasoning: 'CLI search command',
}
```

> Schema was not fully read for this tool (only source side inspected). Full schema comparison pending — see [What Can Still Be Compared](#what-can-still-be-compared).

---

## Token Count Estimates

### Input tokens per call

| Call | CLI (est.) | RTK (est.) | Delta |
|------|-----------|-----------|-------|
| PR list | ~80–120 | ~150–300 | RTK +80–180 |
| PR detail | ~150–250 | ~200–350 | RTK +50–100 |
| Local search | ~70–100 | ~120–250 | RTK +50–150 |

RTK overhead is ~50–150 tokens from richer context strings and extra fields. Acceptable — buys routing quality.

### Output tokens (where CLI has a real problem)

| Scenario | CLI output | RTK output | Impact |
|----------|-----------|-----------|--------|
| PR detail, large diff | Unbounded — no `minify` | Bounded via `minify:"standard"` + `responseCharLength` | **3–5× bloat risk** |
| PR body, large text | Full dump — no `charOffset`/`charLength` | Clean pagination | Truncation or flood |
| Local search, discovery | Full match dump — always paginated | `mode:"discovery"` = file paths only | **80%+ savings** possible |
| Local search, count | Full match dump | `countLinesPerFile` = counts only | **90%+ savings** possible |

---

## Scores

| | Quality | Token Efficiency |
|---|---|---|
| **CLI — PR list** | 5/10 | 7/10 — small input, uncontrolled output |
| **CLI — PR detail** | 6/10 — content surfaces good | 4/10 — no `minify`, no body pagination |
| **CLI — local search** | 3/10 — 8/30 fields used | 6/10 — no `discovery` mode |
| **RTK — PR search** | 9/10 | 8/10 |
| **RTK — local search** | 9/10 | 9/10 |

---

## Top 3 Fixes for CLI

### Fix 1 — `pr.ts:fetchPRDetail` — Add response size control
```ts
// Add to detail query:
minify: 'standard',
charLength: opts.charLength,
charOffset: opts.charOffset,
```
Expose `--char-length` and `--char-offset` CLI flags. Saves **2–4× output tokens** on large PRs.

### Fix 2 — `search.ts:searchLocal` — Expose glob filters and mode
```ts
// Add to local search query:
mode: opts.mode ?? 'paginated',
include: opts.include,
exclude: opts.exclude,
contextLines: opts.contextLines,
maxMatchesPerFile: opts.maxMatchesPerFile,
```
Expose `--include`, `--exclude`, `--mode`, `--context` flags. Most impactful missing surface area.

### Fix 3 — `pr.ts:fetchPRList` — Add sort and date filters
```ts
// Add to list query:
sort: opts.sort,
order: opts.order,
draft: opts.draft,
created: opts.created,
'merged-at': opts.mergedAt,
```
Expose `--sort`, `--order`, `--draft`, `--created`, `--merged-at` flags. Schema already supports all of them — zero backend work needed.

---

## What Can Still Be Compared

These were **not** fully checked in this audit and represent open work:

### Other CLI tool calls (not yet read)

| Tool | CLI source file | What to compare |
|------|----------------|-----------------|
| `ghGetFileContent` | `packages/octocode-cli/src/cli/commands/files.ts` (get sub-command) | `minify`, `startLine`/`endLine`, `charOffset`/`charLength`, `type:"directory"` |
| `ghViewRepoStructure` | `packages/octocode-cli/src/cli/commands/files.ts` (tree sub-command) | `depth`, `page`, `itemsPerPage`, `verbose` |
| `ghSearchRepos` | (if exposed in CLI) | date filters, topic filters, `sort`, `stars`/`forks` range |
| `ghSearchCode` | `packages/octocode-cli/src/cli/commands/search.ts:86` | Full schema not read — only source-side inspected |
| `ghCloneRepo` | (if exposed in CLI) | subtree, branch, cache TTL |
| `localGetFileContent` | `packages/octocode-cli/src/cli/commands/files.ts` | `minify`, `matchString`, `charOffset`/`charLength`, `startLine`/`endLine` |
| `localViewStructure` | (if exposed in CLI) | `depth`, `recursive`, `extensions`, `sortBy` |
| `localFindFiles` | (if exposed in CLI) | size/time/permission filters, `regex` |
| `lspGetSemantics` | (if exposed in CLI) | `type` routing (definition/references/callers/callees/hover), `depth` |
| `npmSearch` | (if exposed in CLI) | `mode` (smart/full/lean), `page` |

### Response shape — not yet compared

| Area | What to check |
|------|--------------|
| Structured output parsing | Does CLI fully consume `structuredContent` vs `content[0].text` fallback? |
| Evidence field | Is `evidence.answerReady` / `evidence.confidence` read by CLI for UX decisions? |
| Hints field | Are tool `hints[]` surfaced to CLI users or silently discarded? |
| `responsePagination` | Does CLI use `hasMore`/`nextCharOffset` for automatic pagination? |
| Error handling | Does CLI distinguish `isError` types (auth 401, rate limit 429, not found 404) correctly across all commands? |
| `warnings[]` | Are sanitization warnings (redacted secrets) surfaced to CLI users? |

### Schema fields not yet mapped to CLI flags

| Schema field | Available in RTK | CLI command that should expose it |
|-------------|-----------------|-----------------------------------|
| `minify` | All content tools | `pr --view`, `get`, `search` |
| `responseCharLength` | All tools | Global `--response-length` flag |
| `responseCharOffset` | All tools | Global `--response-offset` flag |
| `mode: 'discovery'` | `localSearchCode` | `search --mode discovery` |
| `mode: 'symbols'` | `localGetFileContent` | `get --mode symbols` |
| `contextLines` | `localSearchCode` | `search --context <n>` |
| `matchContentLength` | `localSearchCode` | `search --match-length <n>` |
| `include[]` / `exclude[]` | `localSearchCode` | `search --include <glob>` |
| `sort`, `order` | `ghSearchPRs` | `pr --sort updated --order desc` |
| `draft` | `ghSearchPRs` | `pr --draft` |
| `created`, `merged-at` | `ghSearchPRs` | `pr --created >2024-01-01` |
| `verbose` | `ghSearchPRs`, `ghSearchRepos` | `pr --verbose`, `search --verbose` |
| `matchString` | `ghSearchPRs` | already in CLI as `--match-string` ✅ |
| `content.patches.ranges` | `ghSearchPRs` | `pr --file <path> --lines <range>` |
| `charOffset`, `charLength` | `ghSearchPRs` | `pr --char-offset <n> --char-length <n>` |

### Compiled output (not deeply analyzed)

The `out/octocode-cli.js` entry point (5 KB) was confirmed to be only the router. The real logic lives in `out/chunks/` (total ~285 KB across 20 files). The compiled PR chunk (`pr-EIXFFF2G.js`, 11 KB) and search chunk were not decompiled/compared against source — this could reveal minification artifacts or tree-shaking gaps.

### Token count — real measurement (not yet done)

Estimates above are based on field counts. For a real token comparison:
1. Instrument `executeDirectTool` to log serialized query JSON
2. Run `tiktoken` on both CLI and RTK query payloads for the same operations
3. Compare output response sizes with and without `minify`

---

## Related References

- [`docs/dev/reference/GITHUB_TOOLS_REFERENCE.md`](https://github.com/bgauryy/octocode/blob/main/docs/dev/reference/GITHUB_TOOLS_REFERENCE.md) — full `ghSearchPRs` param docs
- [`docs/dev/reference/LOCAL_TOOLS_REFERENCE.md`](https://github.com/bgauryy/octocode/blob/main/docs/mcp/tools/LOCAL_TOOLS.md) — full `localSearchCode` param docs
- `packages/octocode-tools-core/dist/tools/github_search_pull_requests/scheme.d.ts` — authoritative PR schema
- `packages/octocode-tools-core/dist/tools/local_ripgrep/scheme.d.ts` — authoritative ripgrep schema
- `packages/octocode-cli/src/cli/commands/pr.ts` — CLI PR tool call source
- `packages/octocode-cli/src/cli/commands/search.ts` — CLI search tool call source
