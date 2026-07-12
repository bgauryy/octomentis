# weekly-engineering-summary

**Message ID:** `home.useCases.weeklyEngineeringSummary.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Synthesize this week’s PRs, rollouts, incidents, and reviews.

## Automation Prompt

Synthesize this week’s PRs, rollouts, incidents, and reviews into a weekly update.

Grounding rules:
- Do not invent events; if data is missing, say that briefly.
- Prefer concrete references (PR #, incident ID, rollout note, file path) where available.
