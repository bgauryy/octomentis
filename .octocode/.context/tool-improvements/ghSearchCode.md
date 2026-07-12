# `ghSearchCode` — Improvements

## Current State
- 16 schema fields; `match:"path"` and `filename` undocumented in description
- Description mentions indexing fallback but buries the key routing signal
- `verbose` flag effect never explained
- `matchIndices` in output are char offsets in the snippet, not file lines — agents misuse them as `lineHint`

---

## Description

### Current
```
GitHub code/path search returning path+snippet; matchIndices are snippet char offsets, not file lines — no line numbers available from search alone.
Empty with owner+repo usually means repo is unindexed (new/private repos lag GitHub indexing) — fall back to ghGetFileContent with a known path. Retry owner-only to confirm for established public repos.
Next: ghGetFileContent(owner, repo, path, matchString=same-keyword) for source — use files[0].startLine as rough lineHint; ghViewRepoStructure for context; ghSearchRepos if owner/repo unknown.
```

### Proposed
```
GitHub code and path search. Returns file paths + snippets for content search, or paths only for match:"path".

Two modes:
- match:"file" (default) — searches file contents, returns snippets with char-offset matchIndices
- match:"path" — searches file paths/names only; 10× cheaper, use to verify a file exists before reading it

Output signals:
- matchIndices = char offsets inside the snippet string, NOT file line numbers — do not use as lineHint
- emptyQueries[].nonExistentScope:true — owner/repo does not exist or is not indexed; no retry needed
- totalMatchesKind:"lowerBound" — GitHub capped the count; real total is higher
- verbose:true adds html_url per file pinned to the matched commit

When empty with owner+repo: repo may not be indexed (new or private). Fall back to ghGetFileContent with a known path.

Next: ghGetFileContent(path, matchString=same-keyword) — files[0].startLine is a rough line anchor for reading context; ghViewRepoStructure to map the repo before searching.
```

---

## Schema

### Fields to add/clarify descriptions

**`match`**
```
Current: 'Search target: "file" searches file contents; "path" searches file paths/names.'
Proposed: 'Search target. "file" (default) searches file contents and returns snippets. "path" searches file paths/names only — no snippet, no matchIndices, 10× cheaper. Use "path" to check if a file exists before reading it.'
```

**`filename`**
```
Current: 'Filename filter (GitHub filename:) — name equals or contains the value ("Button.tsx", "jest.config").'
Proposed: 'Exact filename filter. Matches files whose name equals or contains this value. More precise than keywordsToSearch for known filenames — use instead of keyword search when you know the file name.'
```

**`verbose`**
```
Current: 'Set true to add per-file html url pinned to the matched commit.'
Proposed: 'Set true to add html_url per file pinned to the matched commit SHA. Default false — lean output. Only enable when you need to surface clickable links to the user.'
```

**`keywordsToSearch`**
```
Current: 'All terms are combined. Split independent terms into separate items; keep an exact phrase together when needed.'
Proposed: 'Search keywords. All terms are ANDed together — every keyword must appear. Split independent alternatives into separate query objects. Keep an exact phrase in one item. Use match:"path" instead when searching for a file by name.'
```

### No schema field changes needed — all fields are correct.

---

## Output

### Add to description (output signals)

The description must explain these output fields that agents currently ignore:

```
results[].data.files[].matches[].pathOnly: true   → match:"path" was used; no snippet value
results[].data.files[].matches[].matchIndices[]   → char offsets in the snippet, NOT line numbers
results[].data.pagination.totalMatchesKind        → "exact" | "reported" | "lowerBound"
results[].data.pagination.totalMatchesCapped      → true when GitHub hit its count cap
results[].data.pagination.uniqueFileCount         → distinct files matched (vs total match count)
emptyQueries[].nonExistentScope: true             → owner/repo doesn't exist or isn't indexed
evidence.answerReady                              → false when zero results; stop, don't re-query blindly
```

### What to fix in output schema
- `matchIndices` field description must explicitly say "char offsets in the snippet string — not line numbers, not usable as lineHint"
- `pathOnly: true` must be documented on the match object: "present when match:'path' was used; value field will be absent"
