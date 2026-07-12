# GitHub API Deprecation Tracker

_Updated: 2026-06-14_

---

## TL;DR — octocode-mcp is not affected by any active deprecation.

---

## Active Deprecation: `/search/code` Embedded Fields

**Sunset: 2026-09-27** · [Changelog](https://github.blog/changelog/2026-03-27-deprecation-of-api-search-code-fields) · [REST docs](https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28)

Three fields on `items[].repository` in code search results will return `null`:

| Deprecated field | Replacement |
|-----------------|-------------|
| `items[].repository.description` | `GET /repos/{owner}/{repo}` → `description` |
| `items[].repository.owner.type` | `GET /repos/{owner}/{repo}` → `owner.type` |
| `items[].repository.owner.node_id` | `GET /repos/{owner}/{repo}` → `owner.node_id` |

**Status: NOT AFFECTED.** `codeSearch.ts:294-298` only reads `full_name`, `url`, `pushed_at`, `default_branch` — none of the three deprecated fields. The endpoint itself is staying.

If `description` is ever needed: use `octokit.rest.repos.get()` — already wired at `client.ts:207`.

---

## Partial Deprecation: `repos.listCommits` Stats

[REST docs](https://docs.github.com/en/rest/commits/commits?apiVersion=2022-11-28)

GitHub deprecated the `stats` sub-object on commit list entries.

**Status: NOT AFFECTED.** `fileContentProcess.ts:70-90` only reads `commit.committer.date`, `commit.author.name`, `author.login`.

---

## No API for Blackbird (New Code Search Engine)

[Blackbird blog post](https://github.blog/engineering/architecture-optimization/the-technology-behind-githubs-new-code-search/) · [Syntax docs](https://docs.github.com/en/search-github/github-code-search/understanding-github-code-search-syntax)

GitHub's Blackbird engine (GA 2025) — symbol search, regex, boolean ops, glob paths — is **web UI only**. No REST or GraphQL endpoint exposes it. GraphQL `SearchType` has no `CODE` variant.

`GET /search/code` (legacy) remains the only programmatic code search. No announced API timeline.

---

## All Endpoints in Use

All 18 endpoints are safe. Marked where partial deprecations exist.

| Endpoint | Source file | Notes |
|----------|-------------|-------|
| `GET /search/code` | `codeSearch.ts` | 3 sub-fields deprecated (sunset 2026-09-27) — not used |
| `GET /search/repositories` | `repoSearch.ts` | Safe |
| `GET /search/issues` | `pullRequestSearch.ts` | Safe |
| `GET /repos/{owner}/{repo}/contents/{path}` | `fileContentRaw.ts`, `directoryFetch.ts`, `repoStructure.ts` | Safe |
| `GET /repos/{owner}/{repo}/git/blobs/{sha}` | `fileContentRaw.ts` | Safe |
| `GET /repos/{owner}/{repo}` | `client.ts` | Safe |
| `GET /repos/{owner}/{repo}/branches/{branch}` | `client.ts` | Safe |
| `GET /repos/{owner}/{repo}/commits` | `fileContentProcess.ts` | `stats` deprecated — not used |
| `GET /repos/{owner}/{repo}/commits/{ref}` | `prContentFetcher.ts` | Safe |
| `GET /repos/{owner}/{repo}/pulls` | `pullRequestSearch.ts` | Safe |
| `GET /repos/{owner}/{repo}/pulls/{pull_number}` | `prByNumber.ts`, `prContentFetcher.ts` | Safe |
| `GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews` | `prContentFetcher.ts` | Safe |
| `GET /repos/{owner}/{repo}/pulls/{pull_number}/comments` | `prContentFetcher.ts` | Safe |
| `GET /repos/{owner}/{repo}/pulls/{pull_number}/files` | `prContentFetcher.ts` | Safe |
| `GET /repos/{owner}/{repo}/pulls/{pull_number}/commits` | `prContentFetcher.ts` | Safe |
| `GET /repos/{owner}/{repo}/issues/comments` | `prContentFetcher.ts` | Safe |
| `GET /orgs/{org}/repos` | `repoSearch.ts` | Safe |
| `GET /users/{username}/repos` | `repoSearch.ts` | Safe |

---

## Rate Limits

[Rate limit docs](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api)

| Bucket | Limit | Scope |
|--------|-------|-------|
| `code_search` | **10 req/min** | `/search/code` only (separate, tighter bucket) |
| `search` | 30 req/min | `/search/repositories`, `/search/issues`, etc. |
| `core` | 5,000 req/hour | All `/repos/**`, `/git/**`, `/pulls/**` |

Handled via `@octokit/plugin-throttling` — `client.ts:85-112`, max 3 retries, 60s cap.

---

## Known Gaps (API Constraints, Not Deprecations)

- **Archived repos silently excluded** from `/search/code` — zero results ≠ not found. Verify with `repos.getContent` directly.
- **Default branch only** — `/search/code` has no `branch:` qualifier.
- **1,000-result ceiling** — 10 pages × 100 max. Narrow with qualifiers.
- **Files >384 KB excluded** from code search index. Fetch by path via `repos.getContent`.
- **Directory listing cap: 1,000 entries** — use Git Trees API for larger dirs (not implemented).
