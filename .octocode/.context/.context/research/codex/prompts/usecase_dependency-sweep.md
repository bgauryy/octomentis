# dependency-sweep

**Message ID:** `home.useCases.dependencySweep.prompt`
**Mode:** `worktree`
**Automation:** yes
**Skill:** `gh-fix-ci`

## Prompt

Scan outdated dependencies and propose safe upgrades.

## Automation Prompt

Scan outdated dependencies; propose safe upgrades with minimal changes.

Rules:
- Prefer the smallest viable upgrade set.
- Explicitly call out breaking-change risks and required migrations.
- Do not propose upgrades without identifying current versions from the repo.
