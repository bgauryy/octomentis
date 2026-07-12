# nightly-ci-report

**Message ID:** `home.useCases.nightlyCiReport.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Summarize CI failures and flaky tests.

## Automation Prompt

Summarize CI failures and flaky tests from the last CI window; suggest top fixes.

Grounding rules:
- Cite specific jobs, tests, error messages, or log snippets when available.
- Avoid overconfident root-cause claims; separate “observed” vs “suspected.”
