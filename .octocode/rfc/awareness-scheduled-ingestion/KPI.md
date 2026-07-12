# Success and Verification: Scheduled Connector Ingestion for Octocode Awareness

> Verifies `RFC.md` §Goals and the `IMPLEMENTATION.md` build.

## User Stories
- As an operator, I want scheduled ingestion to run without any Awareness process change, so that I keep the existing safety/predictability guarantees. → RFC goal #2 (no daemon, no schema change)
- As a reviewing agent/human, I want unattended writes clearly separated from attended ones, so that I never silently trust unverified content. → RFC goal #2
- As a maintainer, I want the first connector to ship with zero new auth infrastructure, so that scope stays bounded. → RFC goal #3
- As a plain Pi user (no `octocode-agent`), I want the same ingestion capability available directly, so that the platform launcher never becomes a hidden requirement. → RFC goal #4

## Acceptance Criteria
```gherkin
Feature: Unattended memory writes are reviewable, not trusted by default
  Scenario: Ingestion agent records a finding
    Given the ingestion agent runs with OCTOCODE_ALLOW_INGESTION=1
    When it calls memory record with --tag unattended-write
    Then the row appears in query workboard under MemoryReview with reason unattended_write

  Scenario: Existing review reasons are unaffected
    Given a memory with missing file references and no unattended-write tag
    When workboard is queried
    Then it still surfaces reason missing_refs exactly as before this change

  Scenario: Ingestion is off by default
    Given OCTOCODE_ALLOW_INGESTION is unset
    When the ingestion CLI's run/ingest command is invoked
    Then it exits non-zero and performs no write

  Scenario: Standalone invocation works without octocode-agent
    Given a plain pi install with OCTOCODE_INGESTION_MODE=1 set directly
    When pi is run with --mode json and the fixed ingestion prompt, with no octocode-agent binary present
    Then ingestion behaves identically to the octocode-agent ingest convenience command

  Scenario: pi-extension never depends on octocode-agent
    Given packages/octocode-pi-extension/package.json
    When its dependency list is inspected
    Then octocode-agent never appears in it
```

## Definition of Done
- [ ] Acceptance scenarios pass
- [ ] Phase 0 spike evidence captured in `IMPLEMENTATION.md`
- [ ] `yarn workspace @octocodeai/octocode-awareness verify` green after the Phase 1 change
- [ ] Standalone dependency-list assertion test (Phase 4b) passes in CI
- [ ] Documentation (README for the affected packages) explains both entry points and the guard flags
- [ ] Rollout completed on one operator machine per `IMPLEMENTATION.md` §Rollout

## Success Metrics
| Metric | Type | Baseline | Target | Window | Source |
|---|---|---|---|---|---|
| `unattended_write` rows reviewed (promoted or archived) vs. recorded | lagging | 0 (feature doesn't exist yet) | ≥80% reviewed within 7 days of recording | rolling 7-day | `query workboard` MemoryReview counts |
| Ingestion runs completing without error | leading | N/A | ≥95% of scheduled runs | rolling 30-day | ingestion state file / run log |
| Existing MemoryReview reasons regression | guardrail | current pass rate (100%) | must stay 100% — zero regression | every CI run | `tests/schema.test.ts` + new `repo-workboard.ts` test |
| Secrets ever appearing in a recorded memory payload | guardrail | 0 | must stay 0 | every CI run + spot audit | test asserting no configured key substring in test-fixture payloads |
| `octocode-pi-extension` package.json gains an `octocode-agent` dependency | guardrail | 0 (must never happen) | must stay 0 | every CI run | dependency-list assertion test, Phase 4b |

## Decision Rule
- Success if ≥80% of `unattended_write` rows are reviewed within 7 days, zero guardrail
  regressions occur across two consecutive rollout weeks, and the standalone scenario passes
  identically to the `octocode-agent` convenience path.
- Roll back (disable cron job) or iterate on the ingestion prompt if the review-lane backlog grows
  unbounded (>7 days unreviewed) or a guardrail metric fails once — mirrors the rollback trigger in
  `IMPLEMENTATION.md` §Rollout.

## Traceability
| RFC requirement (§) | Story | Acceptance check | Verification | Post-ship status |
|---|---|---|---|---|
| No daemon/schema change (Goals) | Operator story | Scenario "Ingestion is off by default" + Phase 1 schema tests | `yarn workspace @octocodeai/octocode-awareness verify` | Pending |
| Unattended writes reviewable (Goals) | Reviewer story | Scenario "Ingestion agent records a finding" | Manual smoke, Phase 5 | Pending |
| Single connector, no new auth (Goals) | Maintainer story | Code review — no OAuth/credential code added | Manual review | Pending |
| Standalone reachability, no new package (Goals) | Plain Pi user story | Scenario "Standalone invocation works without octocode-agent" + dependency-list guardrail | Phase 4b test + Phase 5 dual-entry smoke | Pending |
