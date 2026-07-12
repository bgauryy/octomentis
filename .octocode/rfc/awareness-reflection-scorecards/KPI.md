# Success & Verification: Awareness Reflection Scorecards and Wiki-Memory Review Queue

> Verifies `RFC.md` goals and the `IMPLEMENTATION.md` build. Goals are referenced, not restated.

## User Stories to Check

- **As an agent**, I want to attach a scorecard to a reflection, so that durable lessons carry evidence and review quality. (G1)
- **As an awareness maintainer**, I want reflection fixes routed to the lowest expressive rung, so that repeated failures do not become over-broad harness changes. (G2)
- **As a reviewer**, I want queryable review queues, so that weak reflections and harness candidates are visible before changing skill or harness files. (G3)
- **As a repo maintainer**, I want generated `.octocode/` reflection-health projections, so that repo memory behaves more like a maintained working wiki without splitting the source of truth. (G4)
- **As a safety-conscious maintainer**, I want scorecard acceptance to stop short of file edits, so that self-improvement remains human-governed. (G5)
- **As an integrator**, I want existing reflection and query flows to keep working, so that scorecards can roll out without breaking existing hosts. (G6)

## Acceptance Criteria

```gherkin
Feature: Optional reflection scorecards
  Scenario: Existing reflect record remains compatible
    Given an initialized awareness DB
    When I run reflect record without scorecard fields
    Then the command exits 0
    And it creates the same learning memory fields as before
    And no scorecard row is required
```

```gherkin
Feature: Scorecard validation
  Scenario: High evidence score requires evidence refs
    Given a scorecard JSON with evidence_score 3 and no evidence refs
    When I validate or record the scorecard
    Then the command exits nonzero
    And the JSON error explains which refs are required
```

```gherkin
Feature: Reflection review query
  Scenario: Low-scored reflection enters review queue
    Given a reflection scorecard with total_score below the configured threshold
    When I run query reflection-review
    Then the row appears with weak_dimensions and source memory id
```

```gherkin
Feature: Harness candidate governance
  Scenario: Accepted scorecard does not edit files
    Given a scorecard routed to harness_code with review_status accepted
    When I query harness-candidates or run repo inject
    Then the candidate is surfaced as guidance
    And no package file is modified by the scorecard operation
```

```gherkin
Feature: Wiki-memory projections
  Scenario: Repo inject writes reflection review projections
    Given a seeded awareness DB with scorecards
    When I run repo inject into a temp workspace
    Then REFLECTIONS.md exists
    And reflection_scorecards.csv exists
    And references/wiki-health.md exists
    And every generated markdown file says to regenerate instead of hand-editing
```

```gherkin
Feature: Weakness mining health
  Scenario: Surface variants qualify after merging
    Given two memories with the same base failure signature and different surface values
    And each raw surface variant is below minCount but the merged base signature reaches minCount
    When I run mine-weakness or wiki-health
    Then the merged base signature is visible as a cluster or explicit health warning
```

## Definition of Done

- [ ] Scorecard schema, table, migration, and types are added.
- [ ] Existing `reflect record` behavior is backward-compatible.
- [ ] New scorecard capture/update paths are covered by CLI and unit tests.
- [ ] New query views are available in JSON and at least one human-readable format.
- [ ] `repo inject` emits reflection review and wiki-health projections with generated-file notices.
- [ ] `exportHarness()` remains backward-compatible.
- [ ] `mineWeakness()` gap is fixed or `wiki-health` handles it independently.
- [ ] Skill docs and package docs are updated.
- [ ] Awareness build, focused tests, and self-test pass.

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| Scorecard coverage for harness candidates | lagging | 0 scorecard table rows before implementation | 100% of test-seeded harness candidates have scorecards | first release | CLI/query integration tests |
| Reflection review query usefulness | leading | no `reflection-review` view | seeded low-score and accepted/rejected rows sort into expected queues | first release | query view tests |
| Projection completeness | leading | no `.octocode/REFLECTIONS.md` or `reflection_scorecards.csv` | generated temp repo contains all new files with source-of-truth warnings | first release | repo inject tests |
| Existing command compatibility | guardrail | current `reflect`, `query`, `repo inject` tests pass | no regressions | every CI run | `yarn workspace @octocodeai/octocode-awareness test:quiet` |
| Autonomous write prevention | guardrail | scorecards do not exist | scorecard accept/update modifies only DB rows/projections, never package source files | every CI run | CLI tests plus git diff check in temp repo |
| Weakness cluster correctness | guardrail | known below-threshold surface-merge gap exists | test proves merged base signature is visible or warned | first release | `mine-weakness` tests |

## Decision Rule

- **Success if** all acceptance scenarios pass, existing awareness tests do not regress, and generated projections make reflection-review status visible without making generated files canonical.
- **Iterate if** scorecard views pass tests but reviewers still cannot tell which lessons are accepted, weak, or risky.
- **Roll back / hide if** existing `reflect record`, `query all`, or `repo inject` compatibility breaks, or if scorecard acceptance writes source files.

## Traceability Matrix

| RFC requirement | User story | Acceptance criteria | Verification method | Post-ship status |
|---|---|---|---|---|
| G1 score reflection quality | Agent scorecard story | Optional reflection scorecards; Scorecard validation | Unit and CLI tests | pending |
| G2 route to right rung | Maintainer routing story | Scorecard route enum and weak dimensions | Scorecard unit tests; review fixture assertions | pending |
| G3 query review queues | Reviewer queue story | Reflection review query; Harness candidate governance | Query integration tests | pending |
| G4 improve `.octocode/` projections | Repo maintainer projection story | Wiki-memory projections | Repo inject temp workspace tests | pending |
| G5 bounded self-improvement | Safety maintainer story | Harness candidate governance | CLI tests assert no source-file edits | pending |
| G6 compatibility | Integrator story | Existing reflect record remains compatible | Existing reflection/query/repo inject regression tests | pending |
| Pre-mortem weakness-mining risk | Awareness maintainer | Weakness mining health | `mine-weakness` focused tests | pending |
