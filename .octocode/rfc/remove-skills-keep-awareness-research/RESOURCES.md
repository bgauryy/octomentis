# Resources: Keep only Awareness + Research skills

## Primary Sources

| Resource | Link or path | Why it matters |
|---|---|---|
| User request | chat 2026-07-12 | Defines remove list + KEEP Awareness/Research + update docs |
| Existing retirement pattern | `packages/octocode-awareness/build.mjs` L158 | Shows how prior skills were retired from mirrors |
| Prior prompt redirect | `packages/octocode-pi-extension/src/prompts/sections/skills.md` L15 | Pattern for renaming old skill ids to Awareness |

## Local Code References

| Area | File and lines | Decision relevance |
|---|---|---|
| Known install list | `packages/octocode/src/cli/commands/skill/types.ts` L48–58 | Must shrink to two names |
| Awareness bundle scan | `packages/octocode-awareness/build.mjs` L158–188 | Auto-picks remaining skills; needs retired purge |
| Required skill set | `packages/octocode-awareness/bin/cli-model.ts` L26 | Awareness-only required |
| Help coupling to octocode-skills | `packages/octocode-awareness/bin/cli-help-data.ts` L14, L20 | Must stop requiring skills skill |
| Pi awareness vendors | `packages/octocode-pi-extension/scripts/build.mjs` L73 | Drop octocode-skills vendor |
| Pi expected skills | `packages/octocode-pi-extension/tests/package.test.ts` L45–54 | Test contract |
| AGENTS catalog | `AGENTS.md` L139 | “9 skills” claim |
| Public skill table | `README.md` ~L393+ | User-facing index |

## Prior Art and Related Systems

| Resource | Link | Lesson for this RFC |
|---|---|---|
| Retired awareness sibling skills | build `retiredSkills` set | Delete + purge mirrors + redirect docs |
| skills.sh index | https://www.skills.sh/bgauryy/octocode-mcp | External catalog may lag; follow-up after merge |

## Internal Research Artifacts

| Artifact | Path | What it supports |
|---|---|---|
| This RFC set | `.octocode/rfc/remove-skills-keep-awareness-research/` | Decision + build + KPI |
| Related skills packaging docs | `packages/octocode-awareness/docs/SKILLS.md` | Install path that currently mentions octocode-skills |

## Open Research Leads

- Whether `skills/scripts/sync.mjs` is only for multi-skill sync — confirm before deleting `skills/scripts/`.
- Whether duplicated README skill tables are generated or hand-copied — if generated, update generator once.

## Reproducible Search Prompts

- `octocode-brainstorming|octocode-eval|octocode-subagent|octocode-rfc-generator|octocode-prompt-optimizer|octocode-skills|octocode-roast` — discovery blast radius
- `9 skills|Skills \(repo\)` — catalog count claims
- `KNOWN_OCTOCODE_SKILLS|EXPECTED_OCTOCODE_SKILLS|AWARENESS_SKILLS` — packaging contracts
