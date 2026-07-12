# Implementation: GitHub REST API Efficiency

> Decision: see `RFC.md` §Summary / §Rationale. This file does not restate goals — it references them.

## Resolved Questions (were open in RFC.md)

| Open question (RFC §) | Resolution | Evidence (`octocode-research`) | Confidence |
|---|---|---|---|
| Q1 Trees threshold | **Use trees whenever `maxDepth > 1`**; depth 1 stays on single `getContent` | Contents recursion already gated on `depth > 1` in `repoStructure.ts:285`; trees replace that branch only | confirmed |
| Q2 Truncated trees | **Warn + emit `incompleteTree`/`truncated` flag**; attempt Contents recursion only for the requested `path` subtree if still needed for agent completeness; never silently present truncated as complete | GitHub trees `truncated` field; partial-tree pattern already in `repoStructureRecursive.ts` failure count | likely |
| Q3 Lean PR enrich override | **No new flag** — enrichment only when `prNumber` or `content`/`reviewMode` requires it (mirrors how execution already strips content for broad lists) | `execution.ts` lean strip + `prContentFetcher.ts:310-319` | confirmed |
| Q4 ETag storage | **Soft side-store `etagSoftCache` (24h) + `withDataCacheConditional`** — primary TTL unchanged; soft body+etag survives so 304 can restore without full download. Public API stays `withDataCache` for non-conditional callers | Soft store outlives file TTL (300s); avoids polluting cached value with `_etag` | confirmed |
| Q5 Token fingerprint | **Reuse `hashToken(token)` from `client.ts`**; `"anon"` if no token; include `baseUrl`/hostname if non-github.com when available | `client.ts` instance cache already hashes token | confirmed |
| GraphQL for these tools? | **Deferred permanently for this RFC** (Non-Goal) | GraphQL SearchType has no CODE; zero local `.graphql(` usage | confirmed |

## Approach

Implement `RFC.md` §Reference-Level phases **A → B → C → D**, then optional E/F. Each phase is separately shippable and reversible.

## Steps (dependency-ordered)

### Phase A: Cache hygiene (`RFC.md` §Phase A)

- [x] Inventory every `generateCacheKey('gh-api-*'|…)` call site; add token fingerprint helper (export or share `hashToken`).
- [x] Fix `repoSearch.ts` cache object: add `repo`, `archived`, `visibility`, `forks`, `license`, `goodFirstIssues`.
- [x] Fix `issues.ts` `buildIssueSearchCacheKey`: add `archived`.
- [x] Pass fingerprint into all GitHub `withDataCache` keys (code, repos, prs, issues, history, releases, file, structure).
- [x] Bump `VERSION` in `cache.ts` (e.g. `v1` → `v2`) to drop poisoned entries.
- [x] Tests: key differs when each new field flips; key differs for token A vs B; extend `api-caching` coverage.
- [ ] Companion: document owner-list `sort:stars` → `full_name` in tool describe or client-sort; surface repo `incomplete_results` if present.

### Phase B: Structure via Git Trees (`RFC.md` §Phase B)

- [x] Add `fetchStructureViaGitTree` (new module or `repoStructure.ts` helper): resolve SHA → `git.getTree({ recursive: 'true' })` → filter path/depth → map items.
- [x] Wire `maxDepth > 1` path to trees; honor `OCTOCODE_GH_STRUCTURE_TREES=0` Contents fallback.
- [x] Handle `truncated`: set warning fields; optional Contents fill for `path`.
- [x] Remove duplicate root `getContent` when using recursive Contents fallback.
- [x] Keep depth=1 on Contents.
- [x] Unit tests with mocked tree payloads (truncated true/false, path prefix, maxDepth).
- [x] Live smoke (optional): instrument call counts on a wide public repo — expect ≪ Contents baseline.

### Phase C: ETag conditional requests (`RFC.md` §Phase C)

- [x] Extend raw file fetch + structure fetch to capture `etag` from response headers (`responseHeaders.ts` / `extractEtag`).
- [x] Soft side-store (`etagSoftCache`, 24h) outlives primary TTL; on miss send `If-None-Match`; map 304 → prior body + hit stat (`withDataCacheConditional`).
- [x] Wire `fileContent.ts` / `fileContentRaw.ts` and structure depth-1 Contents + Git Trees `getTree`.
- [x] `forceRefresh` bypasses conditional.
- [x] Tests: `tests/github/etagConditional.test.ts` (200→304, forceRefresh, errors not soft-cached, raw 304).

### Phase D: Lean PR search (`RFC.md` §Phase D)

- [x] Gate `pulls.get` in `transformPullRequestItemFromSearch` behind “needs enrichment”.
- [x] Unit test: lean search transform does not call `pulls.get`; detail/content still does.
- [ ] Update tool description prose if list fields change.
- [x] Companion: `mapPool` on PR commit `getCommit` fan-out (parity with `history.ts`).

### Phase E/F (optional, after A–D green)

- [ ] E: Directory fetch reuse `fetchRawGitHubFileContent` / SHA cache.
- [ ] F: Search-bucket pacing prototype + metrics via `recordRateLimit`.

## Files / APIs / Contracts Touched

| File | Change | RFC anchor |
|------|--------|------------|
| `src/utils/http/cache.ts` | VERSION bump; optional helpers | Phase A/C |
| `src/github/client.ts` | Export/share `hashToken` | Phase A |
| `src/github/repoSearch.ts` | Complete cache key | Phase A |
| `src/github/issues.ts` | `archived` in key | Phase A |
| `src/github/codeSearch.ts`, `pullRequestSearch.ts`, `prByNumber.ts`, `history.ts`, `releases.ts`, `fileContent.ts`, `repoStructure.ts` | Token in key | Phase A |
| `src/github/repoStructure.ts` / new tree helper / `repoStructureRecursive.ts` | Trees path | Phase B |
| `src/github/fileContentRaw.ts` / `fileContent.ts` | ETag | Phase C |
| `src/github/prContentFetcher.ts` | Lean gate | Phase D |
| Tests under `tests/github/`, `octocode-mcp/tests/github/` | Coverage | all |

## Risk Mitigations

| Risk (`RFC.md` §Pre-mortem) | Mitigation in steps |
|---|---|
| Truncated tree | Phase B truncated handling + tests |
| Lean PR field loss | Phase D docs + detail path tests |
| Unstable auth key | Phase A reuse `hashToken` |
| 304 as error | Phase C Octokit/header handling test |
| Rollout regress | `OCTOCODE_GH_STRUCTURE_TREES=0`; phase A VERSION bump only first |

## Test and Verification Plan (V&V)

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Unit | Cache keys | Field/token permutations | `vitest run tests/github` + new key tests |
| Unit | Trees mapper | Mock `getTree` truncated/full | `vitest run tests/github/*structure*` |
| Unit | Lean PR | Mock octokit; assert call counts | `vitest run tests/github/*pr*` |
| Unit | ETag | Mock 200 then 304 | `vitest run` caching tests |
| Typecheck | tools-core | `tsc --noEmit` | workspace script |
| Integration | CLI smoke | Real public repo structure depth 2 | `octocode.js tools ghViewRepoStructure …` |
| Guardrail | Existing PR/releases/issues modes | Regression suite | `vitest run tests/tools/github_search_pull_requests` |

Validation vs KPIs: see `KPI.md` decision rule after ship.

## Rollout / Rollback

1. Land Phase A alone (safe correctness).
2. Land Phase B behind env flag default **on**; monitor structure errors / truncated warnings.
3. Land Phase C; verify 304 path in staging.
4. Land Phase D; watch skill/eval PR-list quality.

**Rollback:** revert PR(s) per phase; or set `OCTOCODE_GH_STRUCTURE_TREES=0` for B; cache VERSION bump is one-way for old entries (acceptable).

## Open Follow-ups (explicitly not this RFC)

- GraphQL for PR/history nesting (separate RFC with call-count KPI).
- OQL `target:issues`.
- Redis shared cache.
