# `ghSearchPRs` — Improvements

## Current State
- **Bug:** `content` and `reviewMode` silently stripped when `prNumber` absent — not documented
- **Bug:** `limit` and `itemsPerPage` defaults stripped in tools-core override (`optional()` with no default)
- **Schema gap:** `minify:"symbols"` not available — Zod error if attempted (only `"none"` | `"standard"`)
- `matchString` disables `minify` for matched sections — undocumented side effect
- 35 fields; only ~12 used by CLI; sort/order/date/draft filters never surfaced
- `content.patches.ranges` (line-level diff targeting) completely undocumented
- Output shape for broad vs detail mode not explained — agents parse wrong keys
- `bodyEmpty`, `absent`, `sanitizationWarnings`, `in_reply_to_id` output signals not documented

---

## Description

### Current
```
PR search/review. Broad search returns lean metadata (output key: pull_requests[]); prNumber fetches requested surfaces; reviewMode="full" fetches body+changedFiles+patches+comments+reviews in one call.
Signals: bodyEmpty=requested empty body, absent=not fetched, sanitizationWarnings=filtered/redacted, in_reply_to_id=inline reply.
Use lighter diffs for scans, raw diffs for quotes, matchString for known text.
Pagination: search page/limit, content filePage/commentPage/commitPage/itemsPerPage, body charOffset/charLength; page only on hasMore.
Next: prNumber+reviewMode="full" for single-PR deep dive, ghGetFileContent for current source, ghSearchCode for usages.
```

### Proposed
```
Search and review GitHub pull requests. Two modes:

LIST MODE (no prNumber):
- Returns lean pull_requests[] metadata only
- content and reviewMode are ignored — broad search never returns file content
- Use filters to narrow: state, author, label, base, draft, created, merged-at, sort, order
- match:["title"] narrows keyword search to title only (faster); default searches all fields

DETAIL MODE (prNumber required):
- Fetches requested content surfaces for one PR
- reviewMode:"full" fetches all surfaces in one call (body + changedFiles + patches + comments + reviews + commits)
- content.patches.mode:"selected" with files[] or ranges[] for targeted diffs — far cheaper than mode:"all"
- minify:"standard" (default) strips comment-only diff lines. Use "none" only when quoting exact patch text.
- matchString filters patch/body text to matching lines — bypasses minify for matched sections, response may be larger than expected
- charLength/charOffset paginate large PR bodies

Validation rules (Zod enforced — will error if violated):
- content.patches.mode:"selected" requires non-empty files[] or ranges[]
- files[] or ranges[] require mode:"selected"

Output signals:
- bodyEmpty:true → body was requested but PR has no description
- absent → surface was not requested (not missing data)
- sanitizationWarnings → content was redacted by security layer
- in_reply_to_id on a comment → this is a reply in a thread, not a top-level comment
- bodyPagination.hasMore:true → pass charOffset+charLength to get more body text

Next: ghGetFileContent for current source of changed files; ghSearchCode for symbol usages.
```

---

## Schema

### Fix `limit` and `itemsPerPage` defaults in tools-core override

**File:** `octocode-tools-core/src/tools/github_search_pull_requests/scheme.ts`

```ts
// Current — defaults stripped, behavior undefined
limit: clampedInt(1, GITHUB_SEARCH_MAX_LIMIT).optional(),
itemsPerPage: clampedInt(1, PR_CONTENT_MAX_ITEMS_PER_PAGE).optional(),

// Fix — restore defaults to match core schema intent
limit: clampedInt(1, GITHUB_SEARCH_MAX_LIMIT).optional().default(GITHUB_SEARCH_DEFAULT_LIMIT),
itemsPerPage: clampedInt(1, PR_CONTENT_MAX_ITEMS_PER_PAGE).optional().default(PR_CONTENT_DEFAULT_ITEMS_PER_PAGE),
```

### `content` field — document the prNumber dependency

**Current:** `"Surface selector object. Include prNumber because broad searches return metadata."`

**Proposed:** `"Content surface selector. Only applied when prNumber is set — content is silently ignored on list-mode searches. Select only the surfaces you need: metadata, body, changedFiles, patches, comments, reviews, commits. Omitting unneeded surfaces reduces response size significantly."`

### `content.patches.ranges` — add complete description

**Current:** no meaningful description beyond field names.

**Proposed:**
```
Per-file line-level diff targeting. Each entry specifies:
- file: the changed file path (must match the diff path exactly)
- additions: line numbers of added lines to include
- deletions: line numbers of deleted lines to include
Use for surgical diff reads when you only care about specific lines. Requires mode:"selected".
Example: { file:"src/auth.ts", additions:[42,43,44] }
```

### `sort` and `order` fields — improve descriptions

**`sort`:** `"Sort broad search results. 'created': newest first. 'updated': recently active first. 'comments': most discussed. 'reactions': most reacted. 'best-match' (default): GitHub relevance."`

**`order`:** `"Sort direction for the sort field. 'desc' (default): highest/newest first. 'asc': oldest/lowest first."`

### `draft` field
**Current:** `"Draft-state filter."`

**Proposed:** `"Filter by draft state. true: only draft PRs. false: only non-draft PRs. Omit to include both."`

### `created`, `updated`, `merged-at`, `closed` fields
**Current:** one-liner date descriptions.

**Proposed pattern for all:**
`"Date window filter. Format: '>2024-01-01', '<2023-06-01', '2023-01-01..2024-01-01'. Maps to GitHub's created:/updated:/merged:/closed: qualifiers."`

### `minify` field — clarify `"symbols"` is NOT available

**Current:** `'"standard" strips comment-only diff lines; "none" keeps raw exact diffs for quoting patch text.'`

**Proposed:** `'"standard" (default): strips comment-only diff lines — reduces patch size. "none": raw exact diffs — use only when quoting patch text verbatim. Note: "symbols" is not available for PR content.`

### `matchString` field — document the minify bypass

**Current:** `"Filter patch/body text — disables minify so matched lines stay visible."`

**Proposed:** `"Filter patch/body text to lines matching this string. When set, minify is bypassed for matched sections — matched content is returned unminified regardless of the minify setting. Response may be larger than expected when matchString matches large diffs. Use for targeted searches within known PR content."`

### `reviewMode` field

**Current:** `'"full" = body + changedFiles + patches + comments + reviews + commits in one call.'`

**Proposed:** `'"full": fetches all content surfaces in one call — equivalent to setting content:{body:true, changedFiles:true, patches:{mode:"all"}, comments:{discussion:true, reviewInline:true}, reviews:true, commits:{list:true}}. Only valid with prNumber. Use for thorough PR reviews; use individual content selectors for targeted reads.`

---

## Output

### Document list vs detail output shape

**List mode (`pull_requests[]`):**
```
pull_requests[]: Array<{
  number: number
  title: string
  state?: "open" | "closed" | "merged"
  draft?: boolean
  author?: string
  url?: string
  created_at?: string
  updated_at?: string
  merged_at?: string
  head_ref?: string   → source branch
  base_ref?: string   → target branch
}>
pagination: { currentPage, totalPages, hasMore, perPage, totalMatches }
```

**Detail mode (results[0].data):**
```
PR metadata + requested surfaces only. Absent fields = not requested (not missing).
bodyPagination.hasMore:true → more body text available via charOffset+charLength
```

### Document all output signals

```
bodyEmpty: true           → body requested but PR has no description
in_reply_to_id            → comment is a thread reply, not top-level
sanitizationWarnings      → security layer redacted content from this response
bodyPagination.hasMore    → use charOffset to get more body text
evidence.answerReady      → false when zero PRs found; check filters before retrying
evidence.complete         → false when pagination has more results
```
