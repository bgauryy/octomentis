# dashboard

**Message ID:** `home.useCases.dashboard.prompt`
**Mode:** `worktree`
**Automation:** yes
**Skill:** `figma-implement-design`

## Prompt

Create a dashboard for ….

Interpretation rule:
- If the exact metrics/entities are not specified, build the simplest valid dashboard shell that’s easy to extend (layout + placeholders + wiring points), and clearly label assumptions.

Implementation requirements:
- Reuse the repo’s existing UI components, charts, and data-fetch patterns.
- No new charting libraries unless the repo has none and the dashboard cannot be built otherwise.
- Provide a clean information hierarchy: headline KPIs → trends → breakdown table.

Output:
- ≤5 bullets: What you built, Where it lives (routes/components), Data sources used (or TODOs), Risks, Next steps.
- Include a short “How to view” instruction.

## Automation Prompt

Scan recent commits (since the last run, or last 24h) for likely bugs and propose minimal fixes.

Grounding rules:
- Use ONLY concrete repo evidence (commit SHAs, PRs, file paths, diffs, failing tests, CI signals).
- Do NOT invent bugs; if evidence is weak, say so and skip.
- Prefer the smallest safe fix; avoid refactors and unrelated cleanup.
