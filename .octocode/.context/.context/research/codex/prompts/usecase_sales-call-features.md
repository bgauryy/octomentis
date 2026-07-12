# sales-call-features

**Message ID:** `home.useCases.salesCallFeatures.prompt`
**Mode:** `worktree`

## Prompt

Analyze a sales call and implement the highest-impact missing features.

Method:
- Extract customer pain points and explicit feature requests.
- Map them to the current product (repo evidence), then select 1–2 features with best ROI.
- Implement minimal end-to-end slices with clear acceptance criteria.

Constraints:
- No broad product rewrites.
- If the call notes are ambiguous, present 2–3 interpretations with labeled assumptions and pick the simplest build.

Output:
- ≤5 bullets: Requests, Chosen features, Implementation plan, Files changed, How to verify.
