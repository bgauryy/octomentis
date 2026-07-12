# Success and Verification: Keep only Awareness + Research skills

> Verifies `RFC.md` §Goals and the `IMPLEMENTATION.md` build.

## User Stories

- As an agent user, I want only Awareness and Research as official Octocode skills, so that routing stays simple and current.
- As an installer, I want `--install-all` / known-name install to resolve only those two, so I do not pull retired workflows.
- As a docs reader, I want every skill table and AGENTS pointer to match `skills/`, so catalogs do not lie.

## Acceptance Criteria

```gherkin
Feature: Two-skill Octocode surface
  Scenario: Canonical folders
    Given the repo after the change
    When I list skills/*/SKILL.md
    Then only octocode-awareness and octocode-research exist

  Scenario: CLI known list
    Given packages/octocode skill types
    When I read KNOWN_OCTOCODE_SKILLS
    Then it equals [octocode-awareness, octocode-research]

  Scenario: Awareness package bundle
    Given a fresh awareness build
    When I list packages/octocode-awareness/out/skills
    Then only the two kept skills are present
    And retired skill dirs are absent from .agents/skills

  Scenario: Docs and prompts
    Given a repo content search for retired skill ids
    When excluding .octocode/rfc/remove-skills-keep-awareness-research
    Then product docs, prompts, and tests do not advertise those skills as shipped
```

## Definition of Done

- [ ] Acceptance scenarios pass
- [ ] Awareness + octocode + pi-extension tests covering skills pass
- [ ] Documentation catalogs updated (root, packages, awareness, pi)
- [ ] Migration note present for operators with old host installs

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|---|---|---|---|---|---|
| Canonical skill count | leading | 9 | 2 | at merge | `ls skills/*/SKILL.md` |
| KNOWN_OCTOCODE_SKILLS length | leading | 9 | 2 | at merge | types.ts |
| Stale product refs to retired ids | guardrail | many | 0 (excl. this RFC) | at merge | localSearchCode discovery |
| Awareness/Pi/CLI skill tests | guardrail | green | green | at merge | yarn workspace tests |

## Decision Rule

- Success if skill count and known list are 2, builds mirror only those two, and stale-ref search is clean outside this RFC.
- Iterate if CI or docs still advertise retired skills; roll back by restoring skill trees from git if packaging breaks install paths for Awareness/Research.

## Traceability

| RFC goal | Acceptance / metric | Implementation phase |
|---|---|---|
| Only two skill folders | Canonical folders scenario | Phase 1 |
| Contracts agree | CLI + Awareness bundle scenarios | Phase 2–4 |
| Docs updated | Docs and prompts scenario | Phase 3 |
| No skill-review re-home | DoD / HARNESS-VERIFY edits | Phase 3 |
