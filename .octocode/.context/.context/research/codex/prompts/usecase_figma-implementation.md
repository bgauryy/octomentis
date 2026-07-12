# figma-implementation

**Message ID:** `home.useCases.figmaImplementation.prompt`
**Mode:** `worktree`
**Automation:** yes
**Skill:** `figma-implement-design`

## Prompt

Implement designs from my Figma file in this codebase using $figma-implement-design.

Design-system & scope discipline:
- Match the existing design system/tokens exactly; do NOT invent new colors, shadows, spacing scales, or animations.
- Implement ONLY what’s in the provided Figma frames (no extra UX features).

Workflow:
1) Identify target screens/components in Figma and map them to existing routes/components.
2) Reuse existing primitives; create new components only when reuse is clearly impossible.
3) Ensure responsive behavior consistent with the repo’s conventions.
4) Validate: pixel-ish alignment where feasible, but prioritize correctness and consistency over overfitting.

Output:
- A compact change summary: What changed + file paths.
- A checklist of what to verify in the UI (states, responsiveness, accessibility basics).
- If any Figma detail is ambiguous, pick the simplest interpretation and note it briefly.

## Automation Prompt

Scan recent commits (since the last run, or last 24h) for likely bugs and propose minimal fixes.

Grounding rules:
- Use ONLY concrete repo evidence (commit SHAs, PRs, file paths, diffs, failing tests, CI signals).
- Do NOT invent bugs; if evidence is weak, say so and skip.
- Prefer the smallest safe fix; avoid refactors and unrelated cleanup.
