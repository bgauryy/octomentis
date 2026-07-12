# issue-triage

**Message ID:** `home.useCases.issueTriage.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Triage new issues and suggest owners and priority.

## Automation Prompt

Triage new issues; suggest owner, priority, and labels.

Grounding rules:
- Base recommendations on issue content + repo context (CODEOWNERS, touched areas, prior similar issues).
- Do not guess owners without signals; if unclear, say “Owner: Unknown” and suggest a team instead.
