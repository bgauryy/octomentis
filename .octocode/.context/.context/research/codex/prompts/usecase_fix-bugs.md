# fix-bugs

**Message ID:** `home.useCases.fixBugs.prompt`
**Mode:** `worktree`

## Prompt

Find and fix bugs in my codebase with minimal, high-confidence changes.

Method (grounded + disciplined):
1) Reproduce: run tests/lint/build (or follow the existing repo scripts). If I provided an error, reproduce that exact failure.
2) Localize: identify the smallest set of files/lines involved (stack traces, failing tests, logs).
3) Fix: implement the minimal change that resolves the issue without refactors or unrelated cleanup.
4) Prove: add/update a focused test (or a tight repro) that fails before and passes after.

Constraints:
- Do NOT invent errors or pretend to run commands you cannot run.
- No scope drift: no new features, no UI embellishments, no style overhauls.
- If information is missing, state what you can confirm from the repo and what remains unknown.

Output:
- Summary (3–6 sentences max): what was broken, why, and the fix.
- Then ≤5 bullets: What changed, Where (paths), Evidence (tests/logs), Risks, Next steps.
