# RFC: Keep only Awareness + Research skills

Status: Accepted
Decision type: Reversible (git restore of skill trees; docs/tests are the main cost)
Author(s): Guy + agent
Created / Updated: 2026-07-12

## Audit Reasoning

Date: 2026-07-12

Classification: **Implemented** (canonical trees deleted; contracts/docs updated; rebuild/tests pending in same change).

Live checks at accept time: KEEP = Awareness + Research only; roast removed with the six named skills.


## Summary

Shrink the canonical Octocode skill surface under repo-root `skills/` to **two** folders: `octocode-awareness` and `octocode-research`. Delete the other skill trees, stop bundling/installing them, and rewrite every catalog/doc/prompt/test that still advertises the nine-skill set so agents and installers only see Awareness (coordination) and Research (evidence/code work).

## Goals and Non-Goals

- Goal: `skills/` contains only `octocode-awareness` and `octocode-research` (plus any non-skill helpers like `skills/scripts/` that are not Agent Skills).
- Goal: `KNOWN_OCTOCODE_SKILLS`, Awareness `out/skills/`, Pi extension skill lists/prompts, README skill tables, and `AGENTS.md` all agree on that two-skill catalog.
- Goal: Docs no longer route agents to brainstorming, eval, subagent, RFC generator, prompt-optimizer, skills-lifecycle, or roast as shipped Octocode skills.
- Non-goal: Removing the `octocode skill` CLI, marketplace install machinery, or ability to install arbitrary external skill folders by path/GitHub.
- Non-goal: Deleting Cursor/Claude user-global copies under `~/.cursor/skills` or `~/.claude/skills` (operator cleanup; document only).
- Non-goal: Re-implementing brainstorm/RFC/eval/subagent workflows inside Awareness or Research in this change.

## Motivation and Current State

Today the monorepo ships **9** Agent Skills and documents them as the team’s operating set (`AGENTS.md` L139; root `README.md` skill table ~L393+). Awareness build mirrors every `skills/*/SKILL.md` into `packages/octocode-awareness/out/skills/` and `.agents/skills/` (`packages/octocode-awareness/build.mjs` L158–188). The CLI fallback list `KNOWN_OCTOCODE_SKILLS` hardcodes all nine (`packages/octocode/src/cli/commands/skill/types.ts` L48–58). Pi prompts and package tests expect the full set (`packages/octocode-pi-extension/src/prompts/sections/skills.md`; `EXPECTED_OCTOCODE_SKILLS` in `tests/package.test.ts` L45–54).

Cost of doing nothing: agents keep loading retired workflows; install-all and docs lie; maintenance cost stays high for skills the product no longer wants to own.

User intent (this request): remove brainstorming, eval, subagent, rfc-generator, prompt-optimizer, skills; keep awareness + research; update all docs. `octocode-roast` was not in the remove list but is also not in KEEP — this RFC **includes roast removal** so KEEP means “only these two remain.” Confirm before Accept if roast should survive.

## Guide-Level Explanation

After this change:

| Need | Use |
|---|---|
| Shared-repo coordination, locks, memory, verify | `octocode-awareness` |
| Research, review, implement, diagnose with evidence | `octocode-research` |
| Install official skills | `npx octocode skill --name octocode-awareness\|octocode-research` |
| Skill authoring / lint / review scripts | Out of shipped skill set; use Research + normal package tooling (no `octocode-skills` skill) |

Migration for operators with old installs: uninstall or delete host skill dirs for retired names; reinstall Awareness + Research from current `skills/` or awareness `out/skills/`.

## Reference-Level Explanation

### Canonical source

- Delete trees under `skills/` for: `octocode-brainstorming`, `octocode-eval`, `octocode-subagent`, `octocode-rfc-generator`, `octocode-prompt-optimizer`, `octocode-skills`, `octocode-roast`.
- Keep `skills/octocode-awareness`, `skills/octocode-research`, and `skills/scripts/` only if still required by sync tooling (verify in implementation; retire if only used by removed skills).

### Packaging contracts

| Surface | Change |
|---|---|
| `packages/octocode-awareness/build.mjs` | Continues directory-scan bundling; after delete, only two skills land in `out/skills/` and `.agents/skills/`. Extend `retiredSkills` if stale mirrors must be purged by name. |
| `REQUIRED_BUNDLED_SKILLS` | Stay `octocode-awareness` only (`cli-model.ts` L26). Drop help text that pairs Awareness with `octocode-skills` as required (`cli-help-data.ts` L14, L20). |
| `AWARENESS_SKILLS` in pi-extension build | Shrink to `['octocode-awareness']` (today also vendors `octocode-skills` — `scripts/build.mjs` L73). |
| `KNOWN_OCTOCODE_SKILLS` | Exactly `octocode-awareness`, `octocode-research`. |
| Pi `skills.md` prompt + `EXPECTED_OCTOCODE_SKILLS` | List only the two kept skills (plus non-Octocode entries like `browser-agent` only if still shipped elsewhere). |

### Docs blast radius (must update)

- Root: `AGENTS.md`, `README.md`
- Package READMEs that embed the skill table (same block appears in multiple packages — treat as one content family)
- Awareness: `docs/SKILLS.md`, `README.md`, `docs/HARNESS.md`, `docs/VERIFY.md`, `docs/REFLECTION.md`, skill `SKILL.md` / references that point at `octocode-skills`
- Pi: `README.md`, prompt sections, subagent system prompts
- Benchmark README skill index
- Release notes / guides that say “9 skills” or name retired folders

### Capability loss that needs an explicit replacement policy

Removing `octocode-skills` deletes `skill-review.mjs` / `skill-sync.mjs` used in Awareness harness/verify docs (`docs/HARNESS.md` L89–90, `docs/VERIFY.md` L129). **Decision:** drop those doc gates; do not re-home the full skill-lifecycle skill in this RFC. Awareness skill edits are reviewed via Research + package tests + human review.

## Drawbacks and Pre-mortem

| Risk | Failure trigger | Mitigation |
|---|---|---|
| Orphan references break CI | Tests assert retired skill names/paths | Grep-driven update pass; awareness + pi-extension + octocode skill tests |
| Agents still invoke retired skills from host caches | User/global skill dirs | Document uninstall; prompts stop advertising names |
| Lost skill-review gate | Authors skip quality check | Package tests + Research review; optional future script in awareness package only if needed |
| Roast kept accidentally | Ambiguous user list | Confirm on Accept; default = remove |
| External skills.sh / marketing still lists 9 | Public index drift | Update root README + note external index refresh as follow-up |

## Rationale and Alternatives

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| A. Delete listed skills + roast; keep Awareness + Research only | Matches KEEP list; smallest long-term surface | Loses roast/critique skill | **Recommend** |
| B. Delete only the six named; keep roast | Preserves critique workflow | Contradicts “KEEP only two”; still a third skill to document | Reject unless user insists |
| C. Mark retired in docs but keep folders | Easy rollback | Docs/code still ship unused weight | Reject |
| D. Do nothing | Zero churn | Continues advertising skills product no longer wants | Reject |

## Prior Art

Awareness already has a `retiredSkills` set for `octocode-agent-communication` and `octocode-reflection` (`build.mjs` L158) and prompts redirect those names to Awareness (`skills.md` L15). Same pattern applies: delete folders, purge mirrors, update prompts, keep install CLI generic.

## Unresolved Questions

- [x] Is roast in scope for removal? — **Default yes** to match KEEP = only Awareness + Research. Override on Accept if roast must stay.
- [x] What replaces `octocode-skills` review scripts in Awareness verify docs? — **Drop the gate**; no re-home in this RFC.
- [ ] Should host-side copies under `.agents/skills/` / user skill dirs be deleted in-repo only, or also document a one-shot cleanup command? — Defer: in-repo `.agents/skills` is regenerated by awareness build; user dirs = docs only.

## Future Possibilities

- Thin “critique” or “RFC” checklists inside Research references (not separate skills).
- Re-publish retired skills as optional community folders outside the monorepo.
