# Octocode Tools vs RTK — Skill Audit

> **RTK** = pi MCP runtime (`octocode_local_*`) — all 12 tools exposed directly to AI agents.  
> **Octocode tools** = the 12 tool implementations in `packages/octocode-tools-core`.  
> **Skill** = `/Users/guybary/Documents/octocode-mcp/.agents/skills/octocode/SKILL.md`.

Checked: all 12 tool schemas (`packages/octocode-tools-core/dist/tools/*/scheme.d.ts`), the octocode SKILL.md, and pi RTK tool descriptions.

---

## Which Tools Can Be Compared to RTK

11 of 12 map directly. `ghCloneRepo` has no RTK equivalent.

| Octocode Tool | RTK Tool | Schema Fields | Parity |
|---|---|---|---|
| `ghSearchCode` | `octocode_local_ghSearchCode` | 16 | ✅ Full parity |
| `ghGetFileContent` | `octocode_local_ghGetFileContent` | 18 | ✅ Full parity |
| `ghViewRepoStructure` | `octocode_local_ghViewRepoStructure` | 11 | ✅ Full parity |
| `ghCloneRepo` | ❌ **No RTK equivalent** | 8 | ⛔ RTK gap |
| `ghSearchRepos` | `octocode_local_ghSearchRepos` | 22 | ✅ Full parity |
| `ghSearchPRs` | `octocode_local_ghSearchPRs` | 35 | ✅ Full parity |
| `localSearchCode` | `octocode_local_localSearchCode` | 30 | ✅ Full parity |
| `localGetFileContent` | `octocode_local_localGetFileContent` | 15 | ✅ Full parity |
| `localViewStructure` | `octocode_local_localViewStructure` | 18 | ✅ Full parity |
| `localFindFiles` | `octocode_local_localFindFiles` | ~20 | ✅ Full parity |
| `lspGetSemantics` | `octocode_local_lspGetSemantics` | 15 | ✅ Full parity |
| `npmSearch` | `octocode_local_npmSearch` | 4 | ✅ Full parity |

**`ghCloneRepo` gap:** The RTK skill mentions "deep cross-package LSP" requires clone, but RTK agents can't call it — `ENABLE_CLONE` is an operator toggle. The SKILL.md must stop recommending clone as a routine step and replace it with `ghGetFileContent(type:"directory")`.

---

## Tool-by-Tool Schema Gap Analysis

### `ghSearchCode` — 16 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `keywordsToSearch[]` | ✅ | ✅ | |
| `owner`, `repo` | ✅ | ✅ | |
| `extension`, `language` | ✅ | ✅ | |
| `filename` | ❌ | ✅ | Exact filename match — cheaper than keyword search |
| `path` | ✅ | ✅ | |
| `match: "path"` | ❌ | ✅ | **File-path search only — 10× cheaper than file content scan** |
| `verbose` | ❌ | ✅ | Adds URL per hit; default false is fine |
| `limit`, `page` | partial | ✅ | |

**Gap:** `match:"path"` is the cheapest way to check if a file exists in a repo. Not documented in SKILL.md.

---

### `ghGetFileContent` — 18 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `owner`, `repo`, `path`, `branch` | ✅ | ✅ | |
| `matchString` | ✅ | ✅ | |
| `matchStringIsRegex` | ❌ | ✅ | Regex anchors on match — not documented |
| `matchStringCaseSensitive` | ❌ | ✅ | Case-sensitive matching — not documented |
| `startLine`, `endLine` | ✅ | ✅ | |
| `fullContent` | ✅ | ✅ | |
| `contextLines` | ✅ | ✅ | |
| `charOffset`, `charLength` | ✅ | ✅ | |
| `minify` | ✅ | ✅ | |
| `minify:"symbols"` | ❌ | ✅ | **Skeleton + line gutter, 55–97% smaller — ideal for orientation** |
| `forceRefresh` | ❌ | ✅ | Cache busting — not documented |
| `type:"directory"` | mentioned | ✅ | **Should replace `ghCloneRepo` recommendation** |

---

### `ghCloneRepo` — 8 fields

**No RTK equivalent.** Requires `ENABLE_CLONE=true` — an operator-level feature flag, not available to standard RTK agents.

SKILL.md currently lists this in the "common research chain" for deep LSP analysis. This is wrong for RTK context — it must be replaced.

**Replacement chain:**  
`ghGetFileContent(type:"directory")` → `localViewStructure(localPath)` → `lspGetSemantics`

---

### `ghSearchRepos` — 22 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `keywordsToSearch[]` | ✅ | ✅ | |
| `topicsToSearch[]` | ❌ | ✅ | GitHub topic search — not documented |
| `language` | ✅ | ✅ | |
| `owner` | ✅ | ✅ | |
| `stars`, `forks`, `size` | ❌ | ✅ | Range filters (`">100"`, `"50..500"`) — not documented |
| `created`, `updated` | ❌ | ✅ | Date window filters — not documented |
| `license` | ❌ | ✅ | SPDX license filter — not documented |
| `goodFirstIssues` | ❌ | ✅ | Contributor filter — not documented |
| `visibility` | ❌ | ✅ | public/private scope — not documented |
| `archived` | ❌ | ✅ | Include archived repos — not documented |
| `match: ["readme"]` | ❌ | ✅ | Search README text — not documented |
| `sort` | ❌ | ✅ | `stars`/`forks`/`updated`/`best-match` — not documented |
| `verbose` | ❌ | ✅ | Rich structured objects vs lean pipe strings |

**Gap:** Without `verbose:true`, `ghSearchRepos` returns lean pipe-separated strings — fast and cheap. With `verbose:true`, it returns structured objects with stars, language, topics, dates — needed for filtering. SKILL.md never mentions this distinction.

---

### `ghSearchPRs` — 35 fields

*(Full breakdown in [`CLI_VS_RTK_TOOL_CALLS_AUDIT.md`](./CLI_VS_RTK_TOOL_CALLS_AUDIT.md).)*

Key gaps in SKILL.md:
- `minify` on detail mode — should always be `"standard"` unless quoting exact diff text
- `charOffset`/`charLength` for large PR body pagination — not documented
- `sort`, `order`, `draft`, `created`, `merged-at` filters — not documented
- `content.patches.ranges` for line-level diff targeting — not documented

---

### `localSearchCode` — 30 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `keywords`, `path` | ✅ | ✅ | |
| `mode: "discovery"` | ❌ | ✅ | **File paths only — 80%+ token savings for orientation** |
| `mode: "detailed"` | ❌ | ✅ | Expanded snippets + context |
| `include[]`, `exclude[]`, `excludeDir[]` | ❌ | ✅ | Glob filters — critical for scoped searches |
| `contextLines` | ❌ | ✅ | Lines around each match |
| `matchContentLength` | ❌ | ✅ | Snippet char budget per match |
| `maxMatchesPerFile`, `maxFiles` | ❌ | ✅ | Result budgeting |
| `filesOnly`, `filesWithoutMatch` | ❌ | ✅ | File-mode scans |
| `countLinesPerFile`, `countMatchesPerFile` | ❌ | ✅ | Count-only mode — near-zero output tokens |
| `caseInsensitive`, `caseSensitive`, `wholeWord` | ❌ | ✅ | Match precision |
| `fixedString`, `perlRegex` | ❌ | ✅ | Regex type control |
| `multiline`, `multilineDotall` | ❌ | ✅ | Cross-line patterns |
| `noIgnore`, `hidden` | ❌ | ✅ | .gitignore bypass |
| `sortReverse` | ❌ | ✅ | |
| `matchPage` | ❌ | ✅ | Per-file match pagination |
| `langType` | ✅ | ✅ | |

**Biggest gap:** `mode:"discovery"` is the single most token-efficient way to answer "what files match this pattern?" — SKILL.md never mentions it.

---

### `localGetFileContent` — 15 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `path`, `matchString`, `startLine`/`endLine` | ✅ | ✅ | |
| `minify:"symbols"` | ❌ | ✅ | **Skeleton mode — 55–97% smaller; use for orientation** |
| `matchStringIsRegex` | ❌ | ✅ | Regex anchor on match |
| `matchStringCaseSensitive` | ❌ | ✅ | |
| `charOffset`, `charLength` | ✅ | ✅ | |
| `contextLines` | ✅ | ✅ | |
| `fullContent` | ✅ | ✅ | |

---

### `localViewStructure` — 18 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `path`, `depth`, `recursive` | ✅ | ✅ | |
| `pattern` | ❌ | ✅ | Glob/substring filename filter |
| `extensions[]` | ❌ | ✅ | Extension whitelist |
| `filesOnly`, `directoriesOnly` | ❌ | ✅ | Mode restriction |
| `showFileLastModified` | ❌ | ✅ | Timestamps for "find newest files" |
| `sortBy: "time"` | ❌ | ✅ | Sort by modification time |
| `reverse` | ❌ | ✅ | |
| `hidden` | ❌ | ✅ | Include dot files |
| `details` | ❌ | ✅ | Size + permissions per entry |
| `limit` | ❌ | ✅ | Cap on discovered entries |

---

### `localFindFiles` — ~20 fields

Virtually undocumented in SKILL.md. Key undocumented fields:

| Field | What it does |
|---|---|
| `names[]` | Basename glob array — any match |
| `pathPattern` | Full-path glob — monorepo slice filter |
| `regex` | Rust regex against basename |
| `modifiedWithin` | Recently changed files (`"7d"`, `"2h"`) |
| `modifiedBefore` | Files not touched in N time |
| `sizeGreater`, `sizeLess` | File size filters |
| `sortBy: "modified"` | Newest files first — essential for "what changed" queries |
| `executable`, `readable`, `writable` | Permission filters |
| `entryType: "d"` | Directories only |

---

### `lspGetSemantics` — 15 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `uri`, `symbolName`, `lineHint` | ✅ | ✅ | |
| `type` routing | ✅ | ✅ | 9 types documented |
| `format: "compact"` | ❌ | ✅ | **50%+ token savings on call trees** |
| `groupByFile` | ❌ | ✅ | **Compact per-file reference summary** |
| `depth` | ❌ | ✅ | Call tree recursion depth |
| `orderHint` | ❌ | ✅ | Nth occurrence disambiguation |
| `contextLines` | ❌ | ✅ | Lines of context around call-flow results |
| `includeDeclaration: false` | ❌ | ✅ | Omit declaration itself from references |
| `workspaceRoot` | ❌ | ✅ | Override workspace root |
| `itemsPerPage` | ❌ | ✅ | Pagination for large symbol sets |

**Gap:** `format:"compact"` on `callers`/`callees`/`callHierarchy` cuts output by ~50%. Never documented.

---

### `npmSearch` — 4 fields

| Field | In SKILL.md | RTK uses it | Notes |
|---|---|---|---|
| `packageName` | ✅ | ✅ | |
| `mode: "smart"` | ❌ | ✅ | **Exact hits: rich. Broad: lean. Default.** |
| `mode: "lean"` | ❌ | ✅ | Keyword search — lean output |
| `mode: "full"` | ❌ | ✅ | Always rich — for exact known package names |
| `page` | ❌ | ✅ | Keyword result pagination |

---

## Best Practices to ADD to the SKILL.md

### 1. Response budget — always set it for large operations

```
responseCharLength:  cap total response in chars
charLength:          cap a single file/PR body
matchContentLength:  cap snippet length in search results
maxMatchesPerFile:   cap matches per file
maxFiles:            cap total files returned
```

**Rule:** Any operation that might return >5 files or an entire PR diff needs at least one of these. Default `responseCharLength` for unknown-size queries: `10000`.

---

### 2. minify decision table (per-tool)

| Tool | What you're doing | Use |
|---|---|---|
| Any content read | Quick orientation | `minify:"symbols"` |
| Any content read | Normal investigation | `minify:"standard"` (default) |
| Any content read | Quoting exact text / diffs | `minify:"none"` |
| `ghSearchPRs` detail | PR review | `minify:"standard"` always; `minify:"none"` only for raw diff quoting |
| `lspGetSemantics` | Call tree navigation | `format:"compact"` — saves 50% |
| `ghSearchRepos` | Discover repos | `verbose:false` (default) for lean; `verbose:true` only when filtering on stars/topics/dates |
| `ghSearchCode` | File existence check | `match:"path"` — 10× cheaper than file content scan |

---

### 3. Discovery-first pattern for local search

Never run a full paginated `localSearchCode` as the first call on an unknown codebase.

```
Step 1: localSearchCode(keywords, path, mode:"discovery")  → file list, ~0 output tokens
Step 2: localSearchCode(keywords, path, include:[confirmed files])  → targeted paginated
Step 3: localGetFileContent(matchString)  → focused read
```

Or for count-only orientation:
```
localSearchCode(keywords, path, countLinesPerFile:true)  → file + count, ~5 tokens/file
```

---

### 4. LSP prerequisites — hard rules

```
documentSymbols  → needs uri only
All other types  → needs uri + symbolName + lineHint from a PRIOR localSearchCode hit
```

Never call `lspGetSemantics` with a guessed `lineHint`. Always get it from a real `localSearchCode` result. A wrong `lineHint` returns empty results silently.

Use `groupByFile:true` for `references` when checking blast radius — it returns a per-file summary instead of every call site.

---

### 5. ghSearchRepos verbose flag rule

`verbose:false` (default) returns pipe-separated lean strings — cheap, good for discovery.  
`verbose:true` returns structured objects with stars, language, topics, dates — **required** if you need to filter, sort, or compare repos programmatically.

Always specify `verbose:true` explicitly when the goal involves filtering (e.g. "find repos with >1000 stars that use TypeScript").

---

### 6. ghGetFileContent — use `type:"directory"` instead of ghCloneRepo

For cross-file LSP analysis on a GitHub repo:
```
ghGetFileContent(owner, repo, path:"src", type:"directory")
→ localViewStructure(localPath)
→ localSearchCode(keywords, localPath)
→ lspGetSemantics(uri, symbolName, lineHint)
```

Do **not** route through `ghCloneRepo` — it requires `ENABLE_CLONE=true` and is unavailable in standard RTK context.

---

### 7. localFindFiles for temporal queries

When the question is "what changed recently?" or "find all test files in src/":
```
localFindFiles(path, modifiedWithin:"24h", sortBy:"modified")   → recent changes
localFindFiles(path, names:["*.test.ts"], pathPattern:"src/**") → scoped test files
localFindFiles(path, regex:"^index\\.", entryType:"f")          → all index files
```

These are O(1) filesystem queries — far cheaper than `localSearchCode` when you only need file paths.

---

### 8. Parallel batch rules

Batch independent queries. Serialize dependent ones.

```
✅ OK to batch:
- Multiple different ghSearchCode queries for the same research goal
- localSearchCode + localFindFiles (independent targets)
- ghGetFileContent on N known files

❌ Must serialize:
- localSearchCode → lspGetSemantics (need lineHint from step 1)
- ghSearchRepos → ghViewRepoStructure (need owner/repo from step 1)
- ghGetFileContent → lspGetSemantics (need localPath from step 1)
```

Max 5 queries per batch call (schema limit).

---

### 9. Evidence field — read before follow-up calls

Every tool response includes an `evidence` field:
```yaml
evidence:
  answerReady: true     # stop — you have enough
  complete: true        # no more pages
  confidence: high      # trust the result
  kind: code            # content type
```

Check `evidence.answerReady` before spawning follow-up calls. If `answerReady:true`, stop. If `complete:false`, paginate with `charOffset`/`page` before issuing a different query.

---

### 10. ghSearchPRs — always set minify and content budget

```
# List mode: minimal surface
{ state:"open", owner, repo, limit:10 }  ← fine, lean output

# Detail mode: always bound it
{
  prNumber, owner, repo,
  minify: "standard",         ← never omit this
  charLength: 20000,          ← cap PR body
  content: { metadata:true, body:true, changedFiles:true }
}

# Large diff: use patches.mode:"selected" not "all"
content.patches: { mode:"selected", files:["src/critical.ts"] }
```

---

## What to REMOVE from the SKILL.md

### Remove: Rigid common research chains

The "Common Research Chains" section lists fixed pipelines:
```
Local symbol investigation:
localViewStructure → localSearchCode → localGetFileContent → lspGetSemantics
```

**Why remove:** These present research as a fixed sequence instead of evidence-driven decisions. An agent following this chain will call `localViewStructure` even when it already knows the file path, wasting a call. Replace with the "Discovery-first pattern" and "Evidence field" practices above.

---

### Remove: `ghCloneRepo` from the standard deep-LSP chain

```
# Current SKILL.md (wrong for RTK):
Deep cross-package LSP:
ghCloneRepo → localViewStructure(localPath) → localSearchCode → lspGetSemantics
```

**Why remove:** `ghCloneRepo` is not available in RTK unless `ENABLE_CLONE=true` is set by the operator. Agents following this will hit a tool-disabled error. Replace with `ghGetFileContent(type:"directory")`.

---

### Remove: Vague "evidence = discovery" statement

The SKILL.md says:
> "snippets from search = discovery (not proof)"

This is true but creates a habit of over-calling `localGetFileContent` to "confirm" every search hit. Replace with a concrete rule: call `localGetFileContent` only when the search hit's snippet is insufficient to answer the question, or when you need to quote exact text.

---

### Remove: LSP chain without prerequisites

The SKILL.md shows `lspGetSemantics` in chains without stating the hard prerequisite:

```
# Current (misleading):
localSearchCode → localGetFileContent → lspGetSemantics
```

An agent could try to call `lspGetSemantics` on a file it just read without a valid `lineHint`. Remove this loose description and replace with the hard rule: **LSP always needs `uri` + `symbolName` + `lineHint` from a real localSearchCode hit.**

---

### Remove: Redundant minify section (replace with table)

The SKILL.md has a `## Minify Modes` section listing `none/standard/symbols` with one-line descriptions. This doesn't tell agents *when* to use each. Replace with the per-tool decision table from "Best Practices to ADD #2" above.

---

## Summary Table

| Area | Status | Action |
|---|---|---|
| `ghCloneRepo` in RTK skill | ❌ Wrong | Remove, replace with `type:"directory"` |
| `minify` decision rules | ❌ Missing | Add per-tool table |
| `mode:"discovery"` for localSearchCode | ❌ Missing | Add discovery-first pattern |
| `responseCharLength` as budget control | ❌ Missing | Add response budget section |
| `format:"compact"` for LSP calls | ❌ Missing | Add to LSP guidance |
| `groupByFile` for LSP references | ❌ Missing | Add to LSP guidance |
| `verbose` flag semantics (ghSearchRepos, ghSearchCode) | ❌ Missing | Add verbose flag rule |
| `match:"path"` for cheap file search | ❌ Missing | Add to ghSearchCode guidance |
| `evidence.answerReady` check pattern | ❌ Missing | Add evidence field practice |
| LSP lineHint prerequisite (hard rule) | ❌ Soft | Make explicit and hard |
| Parallel vs serial batching rules | ❌ Missing | Add parallel batch rules |
| `localFindFiles` for temporal queries | ❌ Missing | Add temporal query pattern |
| `ghSearchRepos verbose:true` rule | ❌ Missing | Add verbose flag rule |
| Rigid "common research chains" | ⚠️ Replace | Remove, replace with evidence-driven patterns |
| Vague discovery/proof wording | ⚠️ Imprecise | Replace with concrete rule |
| Loose LSP chain description | ⚠️ Misleading | Replace with hard prerequisite |
| Redundant minify descriptions | ⚠️ Weak | Replace with decision table |

---

## Files Checked

| File | What was read |
|---|---|
| `.agents/skills/octocode/SKILL.md` | Full content — all sections |
| `packages/octocode-tools-core/dist/tools/*/scheme.d.ts` | All 12 tool schemas |
| `packages/octocode-tools-core/dist/tools/lsp/semantic_content/*.d.ts` | LSP schema |
| `packages/octocode-cli/src/cli/commands/pr.ts` | CLI PR tool call source |
| `packages/octocode-cli/src/cli/commands/search.ts` | CLI search tool call source |

## Related Docs

- [`docs/dev/CLI_VS_RTK_TOOL_CALLS_AUDIT.md`](./CLI_VS_RTK_TOOL_CALLS_AUDIT.md) — deep CLI vs RTK query comparison for PR and search
- [`docs/dev/reference/GITHUB_TOOLS_REFERENCE.md`](https://github.com/bgauryy/octocode/blob/main/docs/dev/reference/GITHUB_TOOLS_REFERENCE.md)
- [`docs/dev/reference/LOCAL_TOOLS_REFERENCE.md`](https://github.com/bgauryy/octocode/blob/main/docs/mcp/tools/LOCAL_TOOLS.md)
