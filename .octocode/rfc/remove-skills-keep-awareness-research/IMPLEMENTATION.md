# Implementation: Keep only Awareness + Research skills

> Decision: `RFC.md` §Summary / §Rationale (Option A)

## Resolved Questions

| RFC open question (§) | Resolution or explicit deferral | Evidence | Confidence |
|---|---|---|---|
| Roast in scope? | Default **remove**; override only if Accept says keep | KEEP list names only awareness + research | likely |
| Replace skill-review scripts? | **Drop** gates from HARNESS/VERIFY/REFLECTION; no re-home | RFC §Capability loss | confirmed |
| User-global skill cleanup? | Docs-only; do not delete `~` paths from this change | RFC unresolved | deferred |

## Approach

Delete retired skill directories, tighten hardcoded catalogs/prompts/tests to the two keepers, rebuild Awareness + Pi so mirrors match, then sweep docs until discovery search for retired names is empty outside git history / this RFC.

## Steps

### Phase 1: Delete canonical skill trees

- [ ] Delete `skills/octocode-brainstorming`, `octocode-eval`, `octocode-subagent`, `octocode-rfc-generator`, `octocode-prompt-optimizer`, `octocode-skills`, `octocode-roast` (and roast only if Accept confirms default).
- [ ] Inspect `skills/scripts/`; keep only if still used by Awareness/Research/sync; otherwise delete or relocate.
- [ ] Add retired names to `retiredSkills` in `packages/octocode-awareness/build.mjs` L158 so stale `.agents/skills/<name>` mirrors are purged on build.

### Phase 2: Contracts and packaging

- [ ] Set `KNOWN_OCTOCODE_SKILLS` to `['octocode-awareness','octocode-research']` — `packages/octocode/src/cli/commands/skill/types.ts` L48–58.
- [ ] Update CLI/UI copy that describes “research, planning & review” multi-skill installs (`packages/octocode/src/ui/menu/main-menu-items.ts`).
- [ ] Fix Awareness help: remove “octocode-awareness and octocode-skills” / “+octocode-skills required” — `bin/cli-help-data.ts` L14, L20.
- [ ] Set `AWARENESS_SKILLS = ['octocode-awareness']` — `packages/octocode-pi-extension/scripts/build.mjs` L73.
- [ ] Rewrite `src/prompts/sections/skills.md` to Awareness + Research only (keep `browser-agent` only if still a real bundled non-repo skill).
- [ ] Update `EXPECTED_OCTOCODE_SKILLS` and any sorted equality asserts — `packages/octocode-pi-extension/tests/package.test.ts`.
- [ ] Fix Awareness tests that `existsSync(skills/octocode-skills/...)` — e.g. `tests/skill-routing-boundaries.test.ts`, help tests expecting `octocode-skills` string.

### Phase 3: Docs (all catalogs)

- [ ] `AGENTS.md` Skills row: two skills only.
- [ ] Root `README.md` skill table + prose (“9 skills”, workflow contracts naming Brainstorming/Prompt Optimizer).
- [ ] Same table family in package READMEs (mcp, tools-core, engine, config, vscode, octocode, benchmark, etc.).
- [ ] Awareness `docs/SKILLS.md`, `README.md`, `HARNESS.md`, `VERIFY.md`, `REFLECTION.md`, and `skills/octocode-awareness/**` references to `octocode-skills` / sibling skills.
- [ ] Pi `README.md`, subagent `SYSTEM_PROMPT.md` references, agent docs if any.
- [ ] `release/RELEASE_GUIDE.md` if it names the multi-skill bundle beyond Awareness.
- [ ] Kept skill cross-links: Research/Awareness `SKILL.md` / references that route to removed skills → point to Research or drop.

### Phase 4: Rebuild and verify

- [ ] `yarn workspace @octocodeai/octocode-awareness build` — confirm `out/skills/` has only the two keepers.
- [ ] Rebuild pi-extension assets as package requires.
- [ ] `yarn workspace octocode test` (skill command tests), awareness tests, pi-extension package tests.
- [ ] Discovery search for retired skill ids under repo (exclude this RFC folder and intentional history notes): expect zero product refs.

## Files, APIs, and Contracts

| Surface | Change | Blast-radius evidence | Compatibility |
|---|---|---|---|
| `skills/*` | Delete 7 trees | directory listing | breaking for consumers of those skill names |
| `KNOWN_OCTOCODE_SKILLS` | 2 names | types.ts | `--install-all` installs only two |
| Awareness `out/skills` | Auto from scan + retired purge | build.mjs | npm package ships two skills |
| Pi prompts | Catalog shrink | skills.md | agents stop loading retired workflows |
| Docs | Catalog shrink | AGENTS/README family | public messaging |

## Risk Mitigations

| RFC risk/pre-mortem | Preventive action | Detection |
|---|---|---|
| CI assert on old names | Update tests in same PR | test failures |
| Stale `.agents/skills` mirrors | `retiredSkills` purge on build | `ls .agents/skills` |
| skill-review gone | Remove doc commands; don’t leave broken paths | doc link / script path check |
| Host caches | README migration note | manual |

## Test and Verification Plan

| Type | Scope | Approach | Command |
|---|---|---|---|
| Unit | CLI known list | assert length/names | `yarn workspace octocode test` (skill tests) |
| Unit | Awareness help/routing | no octocode-skills required pairing | awareness test suite |
| Package | Pi expected skills | equality on two names | pi-extension package tests |
| Integration | Build mirrors | only two under out/skills | awareness build + `ls` |
| Docs | Stale names | search discovery | Octocode `localSearchCode` retired-name regex |

## Rollout, Migration, and Rollback

- Sequence: delete trees → update contracts/tests → rebuild → doc sweep → verify search clean.
- Proceed signal: builds green; `out/skills` contains only `octocode-awareness` and `octocode-research`; docs/KPIs pass.
- Rollback: restore deleted skill trees from git; revert catalog commits; rebuild.
- Operator note: uninstall retired skills from host skill directories; reinstall Awareness + Research.
