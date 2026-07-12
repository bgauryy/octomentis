# performance-audit

**Message ID:** `home.useCases.performanceAudit.prompt`
**Mode:** `worktree`
**Automation:** yes
**Skill:** `gh-fix-ci`

## Prompt

Audit performance regressions; propose fixes.

## Automation Prompt

Audit performance regressions and propose highest-leverage fixes.

Grounding rules:
- Ground claims in measurements/traces when available.
- If evidence is missing, state uncertainty briefly and suggest what to measure next.
