# dependency-sdk-drift

**Message ID:** `home.useCases.dependencySdkDrift.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Detect dependency and SDK drift; propose alignment.

## Automation Prompt

Detect dependency and SDK drift and propose a minimal alignment plan.

Grounding rules:
- Cite current and target versions from the repo when possible (lockfiles, package manifests).
- Do not guess versions; if targets are unclear, propose options and label them as suggestions.
