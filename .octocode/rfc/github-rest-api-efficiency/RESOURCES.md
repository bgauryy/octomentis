# Resources: GitHub REST API Efficiency

## Primary Sources

| Resource | Link or path | Why it matters |
|---|---|---|
| GitHub REST best practices (conditional requests, concurrency) | https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api | 304 free when authorized; avoid request storms |
| GitHub rate limits | https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api | Primary vs secondary; search buckets |
| Git Trees API | https://docs.github.com/en/rest/git/trees | `recursive=1`, truncation |
| REST Search (code / repos) | https://docs.github.com/en/rest/search/search | Code search is REST-only |
| GraphQL Search / SearchType | https://docs.github.com/en/graphql/reference/enums#searchtype | No CODE search type |
| Migrating REST → GraphQL | https://docs.github.com/en/graphql/guides/migrating-from-rest-to-graphql | Nesting wins are PR/issue graphs, not code search |

## Local Code References

| Area | File and lines | Notes |
|---|---|---|
| Cache TTL / withDataCache | `packages/octocode-tools-core/src/utils/http/cache.ts` | PREFIX TTLs; VERSION |
| Token hash | `packages/octocode-tools-core/src/github/client.ts` | Reuse for cache fingerprint |
| Code search | `…/src/github/codeSearch.ts` | `search.code` + text-match |
| Repo search + incomplete key | `…/src/github/repoSearch.ts:68-83` | Phase A fix |
| Query builders | `…/src/github/queryBuilders.ts` | Filters that must enter cache keys |
| Structure recursion | `…/src/github/repoStructure.ts`, `repoStructureRecursive.ts` | Phase B replace deep path |
| File raw/process | `…/src/github/fileContent.ts`, `fileContentRaw.ts` | Phase C ETag |
| Directory bypass | `…/src/github/directoryFetch.ts` | Phase E |
| PR N+1 | `…/src/github/prContentFetcher.ts:310-319` | Phase D |
| Issues (landed) | `…/src/github/issues.ts` | Prior work; add `archived` to key |
| History concurrency | `…/src/github/history.ts` | `mapPool` pattern to copy |
| Existing cache tests | `packages/octocode-mcp/tests/github/api-caching*.ts` | Extend |

## Prior Art And Related Systems

| Resource | Link | Use for this RFC |
|---|---|---|
| Octokit + plugin-throttling | https://github.com/octokit/octokit.js | Keep; do not replace with GraphQL-first |
| github/github-mcp-server | https://github.com/github/github-mcp-server | Error observability prior art; not caching reference |
| `@octokit/graphql` | npm | Available but **not** chosen for these tools |

## Internal Research Artifacts

| Artifact | Path / id | Notes |
|---|---|---|
| Brainstorm: search/fetch/structure + GraphQL park | Chat 2026-07-11 | Verdict: REST-improve |
| Subagent: code+repo search audit | agent `f24533d5-…` | Cache key gaps, dual topics search |
| Subagent: fetch+structure audit | agent `aef5dbbf-…` | Trees gap, directory bypass, call models |
| Subagent: GraphQL vs REST | agent `4da3de04-…` | Park GraphQL; trees+ETag |
| Prior: issues mode landed | `src/github/issues.ts` + awareness signal | Out of scope for re-impl |
| Prior: API+cache audit | Chat 2026-07-11 | PR N+1, auth-blind keys |

## Open Research Leads

| Lead | Why not decisive yet |
|---|---|
| GHES ETag/trees parity | Product may be GitHub.com-first; smoke later |
| Exact code-search quota (9 vs 10/min) | Docs disagree slightly; pacing Phase F |
| GraphQL for PR detail bundling | Separate RFC with KPI |

## Search Prompts (recreate trail)

```
local: generateCacheKey gh-api-repos repoSearch
local: getTree OR git.getTree under packages/octocode-tools-core
local: pulls.get transformPullRequestItemFromSearch
local: ETag OR If-None-Match under packages/octocode-tools-core
web: GitHub REST conditional requests 304 rate limit
web: GitHub GraphQL SearchType CODE
web: GitHub git trees recursive truncated
```
