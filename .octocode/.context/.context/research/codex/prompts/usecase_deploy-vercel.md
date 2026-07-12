# deploy-vercel

**Message ID:** `home.useCases.deployVercel.prompt`
**Mode:** `local`
**Automation:** yes
**Skill:** `vercel-deploy`

## Prompt

Deploy this project to Vercel with $vercel-deploy and a safe, minimal setup.

Requirements:
- Detect existing deployment configuration (vercel.json, build settings, env vars) and reuse it.
- Ensure the project builds successfully with the repo’s standard commands.
- Identify required environment variables from the repo and document them clearly.

Constraints:
- No code changes unless required to make the build/deploy succeed.
- Do not guess secrets or values.

Output:
- Step-by-step deployment instructions.
- A concise list of required env vars (name + where referenced).
- A short validation checklist after deploy (key routes, smoke checks).

## Automation Prompt

Scan recent commits (since the last run, or last 24h) for likely bugs and propose minimal fixes.

Grounding rules:
- Use ONLY concrete repo evidence (commit SHAs, PRs, file paths, diffs, failing tests, CI signals).
- Do NOT invent bugs; if evidence is weak, say so and skip.
- Prefer the smallest safe fix; avoid refactors and unrelated cleanup.
