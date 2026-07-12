# viral-feature

**Message ID:** `home.useCases.viralFeature.prompt`
**Mode:** `worktree`
**Skill:** `figma-implement-design`

## Prompt

Propose AND implement one high-leverage viral feature for my app.

Rules:
- Pick ONE feature that fits the app’s existing product surface (no multi-feature bundles).
- Optimize for minimal engineering scope and measurable impact.
- Reuse existing patterns, auth, analytics, and UI components.
- Do NOT introduce a new design system or a complex growth framework.

Process:
1) Quickly infer the app’s core loop and shareable moment from repo signals (routes, copy, analytics, existing flows).
2) Choose one feature (e.g., share link/referral/invite loop) and state assumptions clearly if the repo doesn’t reveal intent.
3) Implement the end-to-end slice: UI entry point → backend/API (if needed) → tracking (if present) → success state.
4) Add a small measurement hook: define 1–2 concrete events/metrics (e.g., share_clicked, invite_accepted).

Output:
- 1 short overview paragraph.
- Then ≤5 bullets: Feature, Why (evidence/assumptions), Implementation plan, Files changed, How to verify.
