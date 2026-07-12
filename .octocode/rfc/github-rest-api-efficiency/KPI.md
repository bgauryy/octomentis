# Success & Verification: GitHub REST API Efficiency

> Verifies `RFC.md` §Goals and the `IMPLEMENTATION.md` build. Goals are referenced, not restated.

## User Stories to Check

- **As a** research agent, **I want** deep `ghViewRepoStructure` without hundreds of Contents calls, **so that** I orient on monorepos without secondary rate limits. (→ `RFC.md` §Goals #2)
- **As a** multi-user / multi-token MCP host, **I want** cache entries scoped by auth, **so that** private results never leak across tokens. (→ §Goals #1)
- **As a** agent re-reading unchanged files, **I want** conditional GETs, **so that** refreshes after TTL do not burn primary quota. (→ §Goals #3)
- **As a** agent triaging PRs, **I want** lean search lists without per-hit `pulls.get`, **so that** triage stays within search+REST budgets. (→ §Goals #4)

## Acceptance Criteria (Gherkin)

```gherkin
Feature: Cache key correctness
  Scenario: Repo search filters change cache identity
    Given two repo searches identical except archived or forks or visibility
    When both run through searchGitHubReposAPI
    Then they must not share a withDataCache entry

  Scenario: Token scopes cache
    Given the same code search params under token A and token B
    When both are cached
    Then keys differ by token fingerprint

Feature: Structure via Git Trees
  Scenario: Deep structure uses trees
    Given maxDepth > 1 and OCTOCODE_GH_STRUCTURE_TREES enabled
    When ghViewRepoStructure runs against a multi-directory repo
    Then git.getTree recursive is used and getContent is not called per directory

  Scenario: Shallow structure stays cheap
    Given maxDepth = 1
    When ghViewRepoStructure runs
    Then a single Contents getContent listing is used

  Scenario: Truncated tree is visible
    Given a tree response with truncated true
    When structure is returned
    Then a truncation/incomplete warning is present and the tree is not claimed complete

Feature: ETag conditional fetch
  Scenario: Unchanged file refresh
    Given a cached file body with etag E
    When a refresh sends If-None-Match E and GitHub returns 304
    Then the prior body is returned and treated as a cache hit

Feature: Lean PR search
  Scenario: Concise PR list
    Given type prs search without prNumber and without content enrichment
    When results are transformed from search
    Then pulls.get is not called per hit
```

## Definition of Done

- [ ] Acceptance scenarios pass (unit + mocked integration)
- [ ] Tests added and green (`IMPLEMENTATION.md` V&V)
- [ ] Tool descriptions updated where lean PR / truncated tree behavior is user-visible
- [ ] `RESOURCES.md` research trail intact
- [ ] Rolled out per phase; Phase A does not require trees flag
- [ ] No GraphQL client introduced (Non-Goal check)

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| REST `getContent` calls per deep structure (fixture monorepo, depth 2) | lagging | O(#dirs) today | ≤ 5 total REST (ref + tree + optional) | per request | instrumented test / debug counter |
| Repo-search cache incorrect reuse | lagging | possible today | 0 known collisions in tests | CI | unit tests |
| PR search lean page `pulls.get` count | lagging | ≈ page size | 0 | per lean request | mock call count |
| Authorized 304 path exercised | leading | 0 | ≥1 unit test + optional live | CI | tests |
| Existing github tool test suite pass rate | guardrail | 100% on touched suites | 100% | each PR | vitest |
| Agent-visible structure correctness on small repos | guardrail | Contents truth | Trees output matches Contents filtered set | CI fixture | compare test |

## Decision Rule

**Ship / keep** if Phase A–D acceptance scenarios pass and guardrail suites stay green.

**Revert Phase B** if truncated handling false-completes trees or structure fixture compare fails.

**Revert Phase D** if lean lists break documented required fields for default PR triage (draft/additions must remain available via detail path; if skills break, add enrich or restore list hydration).

**Do not ship GraphQL** under this RFC regardless of REST wins.

## Traceability Matrix

| RFC requirement | User story | Acceptance | Verification | Post-ship status |
|---|---|---|---|---|
| §Goals #1 cache keys + token | multi-token host | Cache key scenarios | unit tests | pending |
| §Goals #2 trees | deep structure | Trees / shallow / truncated | unit + optional live count | pending |
| §Goals #3 ETag | re-read files | 304 scenario | unit | pending |
| §Goals #4 lean PR | triage | Concise PR list | unit mock counts | pending |
| §Non-Goals GraphQL | — | No GraphQL client | grep / review | pending |
| §Goals #5 contracts | — | DoD + guardrail suites | vitest | pending |
