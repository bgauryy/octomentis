# performance-regression-watch

**Message ID:** `home.useCases.performanceRegressionWatch.prompt`
**Mode:** `worktree`
**Automation:** yes

## Prompt

Watch for performance regressions in recent changes.

## Automation Prompt

Compare recent changes to benchmarks or traces and flag regressions early.

Grounding rules:
- Ground claims in measurable signals (benchmarks, traces, timings, flamegraphs).
- If measurements are unavailable, state “No measurements found” rather than guessing.
