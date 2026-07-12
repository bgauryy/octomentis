# Prerequisites: Keep only Awareness + Research skills

> RFC anchor: `RFC.md` §Motivation / §Reference-Level Explanation

## Scope

Canonical skill trees under `skills/`, Awareness packaging (`out/skills`, `.agents/skills`), Octocode CLI known-skill list, Pi extension skill prompts/tests, and all docs that catalog the nine-skill set.

## Required Current-State Evidence

| Requirement | Evidence | Confidence | Owner |
|---|---|---|---|
| Nine skill folders exist under `skills/` | Directory listing: awareness, brainstorming, eval, prompt-optimizer, research, rfc-generator, roast, skills, subagent | confirmed | implementer |
| Awareness bundles every `SKILL.md` folder | `packages/octocode-awareness/build.mjs` L158–188 | confirmed | implementer |
| CLI hardcodes nine names | `packages/octocode/src/cli/commands/skill/types.ts` L48–58 | confirmed | implementer |
| Pi expects multi-skill set | `EXPECTED_OCTOCODE_SKILLS` in `packages/octocode-pi-extension/tests/package.test.ts` L45–54; `src/prompts/sections/skills.md` | confirmed | implementer |
| Docs advertise 9 skills | `AGENTS.md` L139; root `README.md` skill table; duplicated package README tables | confirmed | implementer |
| Awareness help still requires octocode-skills pairing | `packages/octocode-awareness/bin/cli-help-data.ts` L14, L20 | confirmed | implementer |
| Verify/harness call skill-review from octocode-skills | `packages/octocode-awareness/docs/HARNESS.md` L89–90; `docs/VERIFY.md` L129 | confirmed | implementer |

## Environment and Setup

| Need | How to verify | Source |
|---|---|---|
| Built Octocode CLI | `node packages/octocode/out/octocode.js skill --list` | monorepo build |
| Awareness build | `yarn workspace @octocodeai/octocode-awareness build` | package scripts |
| Search for stale names | `localSearchCode` / CLI discovery for retired skill ids | dogfood |

## Baseline Verification

| Check | Command or method | Expected baseline | Evidence |
|---|---|---|---|
| Skill folder count | `ls skills/*/SKILL.md` | 9 | pre-change listing |
| KNOWN list length | read `types.ts` | 9 entries | L48–58 |
| Awareness help mentions octocode-skills | `--help` / help strings | mentions skills pairing | cli-help-data |

## Blockers Before Implementation

| Blocker | Impact | Owner | Resolution before Step 1 |
|---|---|---|---|
| Confirm roast removal | Scope of delete set | requester | Accept RFC default (remove) or override to keep roast |
| None technical | — | — | Trees are independent; packaging is scan-based |

## Owners and Dependencies

| Area | Owner package | Depends on |
|---|---|---|
| Delete skill trees | repo `skills/` | none |
| Rebuild mirrors | `@octocodeai/octocode-awareness` | deleted trees |
| Known list + menus | `octocode` | updated trees |
| Prompts/tests | `@octocodeai/pi-extension` | awareness out/skills |
| Docs | root + packages | catalog decision frozen in RFC |

## Open Prerequisite Questions

None that block drafting. Roast confirmation is a scope gate on Accept, not a code readiness gap.
