# pre-release-check

**Message ID:** `home.useCases.preReleaseCheck.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Run a pre-release checklist before tagging.

## Automation Prompt

Before tagging, verify changelog, migrations, feature flags, and tests.

Grounding rules:
- Report ONLY what you can confirm from the repo and CI context.
- If a check cannot be verified, mark it explicitly as “Unknown.”
