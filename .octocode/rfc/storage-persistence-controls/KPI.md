# Success & Verification: Storage & Persistence Controls

> Verifies `RFC.md` §Goals. Goals are referenced, not restated.

## User Stories to Check

- **As a** laptop MCP user, **I want** to disable durable stats/session writes, **so that** Octocode stops touching those files every minute. (→ Goals 2)
- **As a** maintainer, **I want** a documented inventory of home paths (excl. Awareness), **so that** #443 can be answered accurately. (→ Goals 1, 3)
- **As a** default user, **I want** unchanged behavior when I set nothing, **so that** stats dashboards keep working. (→ Goal 4)

## Acceptance Criteria (Gherkin)

```gherkin
Feature: Storage persistence modes

  Scenario: Default preserves disk writes
    Given OCTOCODE_HOME is a fresh temp directory
    And storage defaults are unset
    When a tool call records char savings
    And the session flush runs
    Then stats.json and session.json exist under OCTOCODE_HOME

  Scenario: stats=off skips stats file
    Given OCTOCODE_STORAGE_STATS=off
    And OCTOCODE_STORAGE_SESSION=memory
    When many tool calls run for >60s of process time
    Then stats.json is not created
    And session.json is not created
    And tool results still return successfully

  Scenario: Docs inventory
    Given docs/CONFIGURATION.md
    Then the home layout documents session.json, stats.json, tmp/clone, tmp/tree, tmp/binary, tmp/unzip
    And legacy logs/ and data.db are marked orphan or GC-only
    And storage env vars are listed in All Settings Reference

  Scenario: Orphan GC opt-in
    Given OCTOCODE_STORAGE_GC_ORPHANS=true
    And OCTOCODE_HOME contains logs/tools.log and data.db
    When Octocode home is initialized
    Then those orphan paths are removed
```

## Definition of Done

- [ ] Acceptance scenarios pass
- [ ] Config + tools-core tests green
- [ ] CONFIGURATION.md updated
- [ ] Defaults unchanged for unset users
- [ ] #443 reply draftable from `RESOURCES.md` inventory

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| Continuous stats/session writes when `stats=off` | lagging | mtime advances ≤60s under load | **zero** mtime on those files | post-ship verify | `stat` under isolated home |
| Default behavior | guardrail | disk write on flush | still writes | same | unit + integration |
| Doc completeness | leading | tmp/logs omitted | tmp + orphans documented | ship | CONFIGURATION.md review |
| #443 resolution quality | qualitative | open / unclear | closed or “waiting on user” with correct knobs | 1 release | issue thread |

## Decision Rule

- **Ship** if Phase 1 tests pass and docs inventory is complete.
- **Hold** if default mode regresses stats persistence or MCP stdio is polluted by GC messages.
- **Follow-up** Phase 3 if users still report SSD wear dominated by `tmp/binary` after stats/session quiet mode.

## Traceability Matrix

| RFC requirement | User story | Acceptance | Verification | Post-ship |
|---|---|---|---|---|
| Goal 1 inventory | maintainer docs | Docs inventory | CONFIGURATION review | |
| Goal 2 disable non-essential writes | laptop user | stats=off scenario | unit/integration | |
| Goal 3 orphans | maintainer / GC | Orphan GC | unit with fixtures | |
| Goal 4 keep auth/defaults | default user | Default scenario | unit | |
