# sentry-monitor

**Message ID:** `home.useCases.sentryMonitor.prompt`
**Mode:** `worktree`
**Skill:** `sentry`

## Prompt

Monitor incoming bug reports on $sentry and attempt fixes.

Rules:
- Triage by severity and frequency.
- Do not guess root cause without stack traces/log evidence.
- Prefer minimal fixes and add regression tests when possible.

Output:
- ≤5 bullets: Top issues, Evidence (error + path), Proposed fix, Risk, Next steps.
