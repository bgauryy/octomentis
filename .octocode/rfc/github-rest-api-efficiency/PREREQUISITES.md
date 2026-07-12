# PREREQUISITES

## Scope

Existing-code area affected: `packages/octocode-tools-core/src/github/*`, `src/utils/http/cache.ts`, PR content fetcher, structure tools, related tests under `packages/octocode-tools-core/tests/github/` and `packages/octocode-mcp/tests/github/`.

RFC anchor: `.octocode/rfc/github-rest-api-efficiency/RFC.md` §Goals / §Reference-Level.

## Required Current-State Evidence

| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| Repo search cache key omits query-affecting filters | `repoSearch.ts:68-83` vs `queryBuilders.ts` repo filters (`archived`, `visibility`, `forks`, `license`, `goodFirstIssues`, `repo`) | confirmed | implementer |
| No `git.getTree` / recursive trees usage | Repo search for `getTree` / `git/trees` — only disk `getTreeDir` helpers | confirmed | implementer |
| Structure recursion = Contents only | `repoStructure.ts` + `repoStructureRecursive.ts` | confirmed | implementer |
| No ETag / If-None-Match in tools-core | Empty ripgrep across `*.ts` | confirmed | implementer |
| PR search path always `pulls.get` when owner/repo set | `prContentFetcher.ts:310-319` | confirmed | implementer |
| Zero live GraphQL calls | Empty `.graphql(` / `octokit.graphql` under `src/` | confirmed | implementer |
| Issues/history/releases already TTL-cached | `issues.ts`, `history.ts`, `releases.ts`, `cache.ts` TTL entries | confirmed | prior landing |
| Token hashed for Octokit instance cache | `client.ts` `hashToken` | confirmed | reuse for cache keys |

## Environment And Setup

| Need | How to verify | Source |
|---|---|---|
| Auth for live smoke | `node packages/octocode/out/octocode.js auth status` | CLI |
| Built tools-core + octocode | `yarn workspace @octocodeai/octocode-tools-core build` then `yarn workspace octocode build:dev` | AGENTS.md |
| Fixture repos | Public small repo (Contents≈Trees) + wider public monorepo for call-count smoke | implementer choice |
| Node + yarn workspace | `yarn -v` | monorepo |

## Baseline Verification

| Check | Command or method | Expected baseline | Evidence |
|---|---|---|---|
| Unit tests (github) | `yarn workspace @octocodeai/octocode-tools-core vitest run tests/github tests/tools/github_search_pull_requests` | Pass on current branch | pre-change CI local |
| Typecheck | `yarn workspace @octocodeai/octocode-tools-core exec tsc --noEmit -p tsconfig.json` | exit 0 | pre-change |
| Structure depth>1 call pattern | Code review / optional instrumented count | O(directories) `getContent` | `repoStructureRecursive.ts` |
| Cache API tests exist for code/repos/PR/file | `packages/octocode-mcp/tests/github/api-caching*.ts` | Present; **missing** issues/history/releases/trees/ETag | audit 2026-07-11 |
| CLI tools registered | `node packages/octocode/out/octocode.js tools --compact` | 13 tools incl. GitHub family | dogfood |

## Blockers Before Implementation

| Blocker | Impact | Owner | Resolution needed before Step 1 |
|---|---|---|---|
| RFC acceptance (Status → Accepted) | No impl without decision | reviewer | Accept or revise Draft |
| Open Q1: trees threshold | Changes Phase B branching | author+reviewer | Decide in IMPLEMENTATION Resolved Questions |
| Open Q2: truncated tree policy | Fallback complexity | author+reviewer | Decide warn+partial vs Contents fill |
| Competing edits on `prContentFetcher` / structure | Merge conflict | awareness locks | `lock acquire` on touch files |

No external package version bump is required to start Phase A (Octokit already exposes `git.getTree`).

## Contracts And Migration Constraints

| Contract/data/API | Compatibility constraint | Rollback or guardrail |
|---|---|---|
| Tool names / MCP schemas | No new tools; structure/search I/O shape stable | Feature flag `OCTOCODE_GH_STRUCTURE_TREES` default on; set 0 to force Contents |
| Cache keys | Intentional invalidation of old keys on deploy (VERSION bump or new fields) | Accept miss storm; optional bump `VERSION` in `cache.ts` |
| PR list fields | Lean list may omit draft/additions/SHAs | Detail via `prNumber` / `content`; document in scheme describe |
| Pagination envelopes | Keep `pagination` / `hasMore` / `next` patterns | Snapshot tests |
| GHES | Trees + ETag must work on GitHub Enterprise if supported today | Smoke against GHES only if product requires; else document GitHub.com first |
