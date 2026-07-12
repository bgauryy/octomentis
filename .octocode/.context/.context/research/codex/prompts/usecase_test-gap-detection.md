# test-gap-detection

**Message ID:** `home.useCases.testGapDetection.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Find test gaps from recent changes; create draft PRs.

## Automation Prompt

Identify untested paths from recent changes; add focused tests and use $yeet for draft PRs.

Constraints:
- Keep scope tight to the changed areas; avoid broad refactors.
- Prefer small, reliable tests that fail before and pass after.
