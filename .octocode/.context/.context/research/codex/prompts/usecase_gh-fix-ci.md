# gh-fix-ci

**Message ID:** `home.useCases.ghFixCi.prompt`
**Mode:** `worktree`
**Skill:** `gh-fix-ci`

## Prompt

$gh-fix-ci iterate on my PR until CI is green.

Constraints:
- Make the smallest set of changes required to fix failures.
- Prefer targeted fixes over refactors.

Output:
- ≤5 bullets: Failures observed, Root cause (with evidence), Patch summary, Tests/CI rerun results, Remaining risks.
