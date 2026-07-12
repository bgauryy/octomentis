# ci-monitor

**Message ID:** `home.useCases.ciMonitor.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Check CI failures; group likely root causes.

## Automation Prompt

Check CI failures; group by likely root cause and suggest minimal fixes.

Grounding rules:
- Cite jobs, tests, errors, and log evidence.
- Avoid overconfident root-cause claims; label uncertain items as “Suspected.”
