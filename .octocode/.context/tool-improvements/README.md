# Tool Improvements

Improvement specs for all 12 octocode tools. Each file covers three areas:
**description** · **scheme** · **output**

Goal: make tools smarter for research agents — dynamic, no rigid instructions, no data loss, no inconsistencies.

Derived from:
- [`TOOL_IMPLEMENTATION_AUDIT.md`](../TOOL_IMPLEMENTATION_AUDIT.md) — real scheme bugs, output shape issues, undocumented validation
- [`OCTOCODE_TOOLS_VS_RTK_SKILL_AUDIT.md`](../OCTOCODE_TOOLS_VS_RTK_SKILL_AUDIT.md) — field coverage gaps vs RTK agent calls
- [`CLI_VS_RTK_TOOL_CALLS_AUDIT.md`](../CLI_VS_RTK_TOOL_CALLS_AUDIT.md) — CLI vs MCP query quality and token efficiency

---

## Tool Files

| Tool | File | Priority | What's Wrong |
|------|------|:--------:|---|
| `ghSearchCode` | [ghSearchCode.md](./ghSearchCode.md) | 🟡 Medium | `match:"path"` undocumented; `matchIndices` ≠ lineHint; `filename` unknown |
| `ghGetFileContent` | [ghGetFileContent.md](./ghGetFileContent.md) | 🔴 High | ENABLE_CLONE coupled into description; 1000-char default silently truncates; mutual exclusions undocumented |
| `ghViewRepoStructure` | [ghViewRepoStructure.md](./ghViewRepoStructure.md) | 🟢 Low | `verbose` undocumented; clone reference to remove; field descriptions missing |
| `ghCloneRepo` | [ghCloneRepo.md](./ghCloneRepo.md) | 🚨 Critical | Referenced in other tools as a routine step — it requires an operator flag agents cannot control |
| `ghSearchRepos` | [ghSearchRepos.md](./ghSearchRepos.md) | 🟡 Medium | 16 of 22 fields undocumented; `verbose` lean vs structured never explained; all filter formats missing |
| `ghSearchPRs` | [ghSearchPRs.md](./ghSearchPRs.md) | 🚨 Critical | `content` silently stripped without `prNumber`; defaults stripped in override; `matchString` bypasses `minify` |
| `localSearchCode` | [localSearchCode.md](./localSearchCode.md) | 🚨 Critical | `mode:"count"` described but does not exist — breaks any agent that uses it |
| `localGetFileContent` | [localGetFileContent.md](./localGetFileContent.md) | 🔴 High | `matchRanges→lineHint` handoff not explained; continuation pattern vague; mutual exclusions undocumented |
| `localViewStructure` | [localViewStructure.md](./localViewStructure.md) | 🟡 Medium | 12 of 18 fields undocumented; output shape unexplained; mutual exclusion undocumented |
| `localFindFiles` | [localFindFiles.md](./localFindFiles.md) | 🔴 High | Virtually undocumented — most efficient tool for temporal/metadata queries, agents never use it |
| `lspGetSemantics` | [lspGetSemantics.md](./lspGetSemantics.md) | 🚨 Critical | `lineHint` hard prerequisite not stated — wrong lineHint = silent empty result; `format:"compact"` saves 50% tokens |
| `npmSearch` | [npmSearch.md](./npmSearch.md) | 🟢 Low | `mode` distinction undocumented; lean vs rich output shape never explained |

---

## Bugs to Fix First

These are real bugs causing broken or incorrect behavior — fix before anything else.

### 1. `mode:"count"` does not exist — `localSearchCode`

**File:** `octocode-mcp-host/packages/octocode-core/src/resources/tools/localSearchCode.ts`

The description says `"count" for cheapest match-count-only`. The schema only has `"paginated"`, `"discovery"`, `"detailed"`. Any agent that sends `mode:"count"` gets a Zod validation error.

```diff
- "count" for cheapest match-count-only (no content — fastest orientation).
+ Use countLinesPerFile:true or countMatchesPerFile:true for count-only output.
```

---

### 2. `content` + `reviewMode` stripped silently — `ghSearchPRs`

**File:** `octocode-mcp-host/packages/octocode-core/src/resources/tools/ghSearchPRs.ts`

The execution layer strips both fields when `prNumber` is absent and adds a hint. Nothing in the description warns agents. They send `content:{body:true}` on list calls and get metadata-only output with no error.

```diff
+ content and reviewMode are ignored when prNumber is absent — list mode always returns metadata only.
```

---

### 3. `limit` and `itemsPerPage` defaults stripped — `ghSearchPRs`

**File:** `octocode-tools-core/src/tools/github_search_pull_requests/scheme.ts`

The core schema has `.default(30)` for `limit` and `.default(20)` for `itemsPerPage`. The tools-core override changes both to `.optional()` with no default. Behavior becomes undefined.

```ts
// Fix:
limit: clampedInt(1, GITHUB_SEARCH_MAX_LIMIT).optional().default(GITHUB_SEARCH_DEFAULT_LIMIT),
itemsPerPage: clampedInt(1, PR_CONTENT_MAX_ITEMS_PER_PAGE).optional().default(PR_CONTENT_DEFAULT_ITEMS_PER_PAGE),
```

---

### 4. `GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 1_000` — too small

**File:** `octocode-tools-core/src/config.ts`

1000 chars ≈ 40 lines of TypeScript. Any file read without an explicit `charLength` silently truncates. Agents reading files without setting `charLength` get fragments.

```ts
// Fix:
export const GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH = 8_000;
```

---

## Remove `ghCloneRepo` from All Other Tool Descriptions

`ghCloneRepo` requires `ENABLE_CLONE=true` — an operator deployment flag. Agents cannot query it, detect it, or enable it. Every reference in another tool's description creates a broken research chain.

**Current broken chain (in descriptions + skill files):**
```
ghCloneRepo → localViewStructure(localPath) → localSearchCode → lspGetSemantics
```

**Replacement (always works):**
```
ghGetFileContent(owner, repo, path:"src", type:"directory")
→ localViewStructure(data.directories[0].localPath)
→ localSearchCode(keywords, localPath)
→ lspGetSemantics(uri, symbolName, lineHint)
```

**Remove from these files:**

| File | Reference to remove |
|------|---------------------|
| `ghGetFileContent.ts` description | `type:"directory" needs ENABLE_CLONE=true+ENABLE_LOCAL=true` |
| `ghViewRepoStructure.ts` description | `Next: … ghCloneRepo for local+LSP` |
| `lspGetSemantics.ts` description (if present) | any clone chain reference |
| `.agents/skills/octocode/SKILL.md` | `Deep cross-package LSP: ghCloneRepo → …` |
| `AGENTS.md` (root) | any clone chain reference |

**What to keep:** `ghCloneRepo`'s own description should state it requires server-side configuration and is not always available. When unavailable the error response is the signal — agents do not need to pre-check.

---

## Description Principles

What every tool description must do after these changes:

**1. State the mode choices upfront**
Every tool with multiple modes (`minify`, `mode`, `format`, `verbose`, `match`) must open with a decision table — not bury it in field descriptions.

**2. State mutual exclusion rules explicitly**
Every `superRefine` Zod rule causes a silent validation error. If an agent can trigger it, the description must warn about it. Examples:
- `fullContent` XOR `matchString` XOR `startLine/endLine` — `ghGetFileContent`, `localGetFileContent`
- `filesOnly` XOR `filesWithoutMatch` — `localSearchCode`
- `fixedString` XOR `perlRegex` — `localSearchCode`
- `filesOnly` XOR `directoriesOnly` — `localViewStructure`
- `content.patches.mode:"selected"` requires `files[]` or `ranges[]` — `ghSearchPRs`
- `symbolName` + `lineHint` required unless `type:"documentSymbols"` — `lspGetSemantics`

**3. Explain output signals, not just input fields**
Agents read output signals to decide next steps. Every description must cover the key signals:
- `isPartial:true` → paginate
- `matchRanges[]` → lineHint for LSP
- `evidence.answerReady` → stop or continue
- `resolvedSymbol` → verify LSP hit
- `searchEngine:"grep"` → ripgrep unavailable

**4. Replace static `Next:` lines with conditional routing**
Static `Next: tool1, tool2, tool3` chains are rigid. Replace with:
```
Next: localGetFileContent(path, matchString) when snippet is insufficient
      lspGetSemantics(uri, symbolName, lineHint=matches[0].line) for semantic navigation
      localViewStructure if path is unknown
```

**5. No operator flags in agent-facing descriptions**
`ENABLE_CLONE`, `ENABLE_LOCAL`, `ENABLE_TOOLS` — these are deployment config. Agents cannot read them. Replace with: "When unavailable, the tool returns a clear error — use [alternative] instead."

---

## Scheme Principles

**Preserve defaults across layers**
When the core schema sets a `.default(N)`, the tools-core override must not strip it to `.optional()`. Default stripping makes behavior undefined and forces callers to guess.

**Clamping over rejection**
The tools-core override pattern (`clampedInt`) clamps out-of-range values instead of rejecting them. This is intentional and correct for JSON-over-stdio transport. Do not change this pattern — but document it: agents sending `page:0` silently get `page:1`.

**`minify:"symbols"` scope**
`"symbols"` mode is only valid on file-read tools (`localGetFileContent`, `ghGetFileContent`). It is intentionally absent from `ghSearchPRs` (no schema `"symbols"` option). Every file-read tool description must call out when `"symbols"` is the right first choice (orientation on unknown files).

---

## Output Principles

**Canonical path is `data.*`**
Every output schema has both `data.files[]` and flat `files[]` with identical content. This is a backward-compat shim. All descriptions must direct agents to `data.*` as the canonical read path.

**`evidence` is always present on success — read it**
```
evidence.answerReady:true  → result is sufficient; stop issuing follow-up calls
evidence.complete:true     → no more pages; do not paginate
evidence.confidence        → "high" | "medium" | "low" — calibrate trust
```

**`hints[]` are actionable**
Tool hints surface things like "repo may not be indexed", "ripgrep fallback used", "content was stripped — include prNumber". Descriptions must tell agents to read hints when results are empty or unexpected.

---

## Token Efficiency Wins (implement in descriptions)

| Change | Tool | Savings |
|--------|------|---------|
| `mode:"discovery"` before full paginated search | `localSearchCode` | 80–90% |
| `countLinesPerFile:true` for file orientation | `localSearchCode` | ~95% |
| `minify:"symbols"` for unknown file orientation | `localGetFileContent`, `ghGetFileContent` | 55–97% |
| `format:"compact"` on call trees | `lspGetSemantics` | ~50% |
| `groupByFile:true` for reference blast radius | `lspGetSemantics` | ~70% |
| `match:"path"` for file existence check | `ghSearchCode` | ~90% |
| `verbose:false` (default) for repo discovery | `ghSearchRepos` | ~60% |
| `content.patches.mode:"selected"` with files[] | `ghSearchPRs` | 50–80% vs `mode:"all"` |
| `minify:"standard"` always set on PR detail | `ghSearchPRs` | 20–40% |

---

## Implementation Order

Fix in this sequence — each layer depends on the one above:

```
1. Bugs (break agents today)
   ├── localSearchCode: remove mode:"count" from description
   ├── ghSearchPRs: document content stripping; restore limit/itemsPerPage defaults
   └── ghGetFileContent: raise GITHUB_FILE_CONTENT_DEFAULT_CHAR_LENGTH

2. Cross-cutting removal
   └── Remove ghCloneRepo from all other tool descriptions and skill files

3. Critical description fixes (agents use these tools most)
   ├── lspGetSemantics: lineHint hard prerequisite; format:"compact"; groupByFile
   ├── localSearchCode: modes; glob filters; count flags; mutual exclusions
   └── ghSearchPRs: mode split; content surface docs; filter fields

4. High-value description additions
   ├── localGetFileContent: matchRanges→lineHint; continuation; minify decision
   ├── localFindFiles: full field documentation; usage patterns
   └── ghGetFileContent: minify:"symbols"; matchString regex/case flags

5. Medium improvements
   ├── ghSearchRepos: verbose mode; filter formats; sort options
   ├── ghSearchCode: match:"path"; matchIndices clarification
   └── localViewStructure: field docs; output shape

6. Output schema documentation
   └── Mark data.* as canonical across all tools; document all output signals
```
