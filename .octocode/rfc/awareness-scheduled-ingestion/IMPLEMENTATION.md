# Implementation: Scheduled Connector Ingestion for Octocode Awareness

> Decision: `RFC.md` §Summary / §Rationale

## Resolved Questions
| RFC open question (§) | Resolution or explicit deferral | Evidence | Confidence |
|---|---|---|---|
| Headless Pi via `--mode json` viability | Deferred — explicit Phase 0 spike, not assumed | `json.md:1-7` documents the flag; `PiContext.mode` is a real type field (`types.ts:170`); no local smoke test run yet | Moderate, pending spike |
| Default cadence/topic list | Deferred to operator config at install time; ship with an empty default (no topics) so nothing runs until configured | Product decision, not evidence-gated | N/A |
| `memory record --tag`/`--importance` exact flags | Deferred to Phase 0 `--help` check before connector/prompt code is written | `memory-recall.md:18` (doc-level) | Moderate, pending CLI confirmation |
| Which package owns the capability | Resolved: `@octocodeai/pi-extension` owns all connector/prompt/state content; `octocode-agent` owns only a convenience CLI subcommand; no new package | `octocode-agent/bin/launcher.mjs:163-176` (existing reserved-subcommand pattern), `pi-extension/package.json` (no `octocode-agent` dependency) | High |

## Approach
Ship Option A from `RFC.md` §Rationale: connector/prompt/state content lives in
`@octocodeai/pi-extension`, gated by an `OCTOCODE_INGESTION_MODE` env var resolved the same way
`OCTOCODE_PROMPT_MODE` already is; `octocode-agent` adds one reserved subcommand as a convenience
wrapper around an invocation any plain Pi install can already perform; Awareness gets one additive
review-lane line, no schema change.

## Steps
### Phase 0: Spike (de-risk before building)
- [ ] Run `pi --mode json "reply with OK"` in a non-interactive shell (no TTY) via `spawnSync`; confirm exit 0 and parseable JSON lines — closes Unresolved Question 1 — `node_modules/@earendil-works/pi-coding-agent/docs/json.md:1-7`
- [ ] Run `<awareness-cli> memory record --help` and `schema json-schema get_memory`; confirm `--tag` (repeatable) and an importance field exist under those exact names — closes Unresolved Question 3 — `skills/octocode-awareness/references/memory-recall.md:18`

### Phase 1: Awareness-side additive change
- [ ] Add one line to the `reviewReasons` array: `tags.includes('unattended-write') ? 'unattended_write' : null` — `packages/octocode-awareness/src/repo-workboard.ts:152-157` — RFC §Reference-Level Explanation
- [ ] Add a focused unit test asserting: (a) a memory tagged `unattended-write` produces the new reason, (b) all 4 existing reasons still fire unchanged on their existing fixtures
- [ ] `yarn workspace @octocodeai/octocode-awareness test:quiet` — confirm schema fingerprint tests (`tests/schema.test.ts`) are unaffected

### Phase 2: Ingestion content in `octocode-pi-extension` (no new package)
- [ ] `src/connectors/web-search.ts` importing `skills/octocode-brainstorming/scripts/lib/web-search-common.mjs` (reuse, not fork) — `packages/octocode-pi-extension/src/` — RFC §Reference-Level Explanation
- [ ] `src/schedule-state.ts` — own local state file under `$OCTOCODE_MEMORY_HOME`, distinct filename from `awareness.sqlite3`, storing `{connector: {last_run_at}}`
- [ ] Add `OCTOCODE_INGESTION_MODE` resolution mirroring `resolvePromptMode`'s option > env > default precedence (`src/prompt.ts:45-51`) — never require `OCTOCODE_AGENT`

### Phase 3: Ingestion prompt + tool restriction (still `octocode-pi-extension`)
- [ ] Fixed ingestion prompt wired via `before_agent_start` in `wireOctocodePiExtension`, active only when `OCTOCODE_INGESTION_MODE=1` or `ctx.mode === 'json'` with a connector flag set — `src/index.ts`
- [ ] Instructs the model to call `memory record` only for genuinely durable findings, always with `--tag unattended-write --agent-id "ingestion-agent:<connector>"`, self-clamping `--importance` to 5 or below
- [ ] Client-side clamp as a second guardrail: reject/downgrade any tool-call payload requesting `importance > 5` before it reaches the CLI (defense in depth, not trust in the prompt alone)

### Phase 4: `octocode-agent` convenience subcommand only
- [ ] `ingest --connector <name>` row in `parseInvocation()` (`launcher.mjs:163-176`), same shape as the existing `update`/`update core` rows — sets `OCTOCODE_INGESTION_MODE=1` + connector name in the spawned env, then calls the existing `launchAgent()` with `['--mode', 'json', <prompt>]` appended — no new domain logic here
- [ ] Guard every `run`/`ingest` invocation on `OCTOCODE_ALLOW_INGESTION=1` being set, mirroring `OCTOCODE_ALLOW_HARNESS_APPLY` (`docs/HARNESS.md:76-78`); exit non-zero with a clear message otherwise
- [ ] Install docs (README) showing a cron/launchd example that sets the flag only inside the job's own environment, never globally

### Phase 4b: Standalone-contract regression test (new, required)
- [ ] Add a test asserting `packages/octocode-pi-extension/package.json` dependencies never include `octocode-agent` (grep/JSON-based guard, same style as the `check:no-workspace` scripts already in both packages)
- [ ] Add a manual/CI check: run `pi -e <pi-extension path> --mode json "<ingestion prompt>"` directly, with `OCTOCODE_INGESTION_MODE=1` set by hand (no `octocode-agent` binary invoked at all) — confirms the capability isn't secretly coupled to the launcher

### Phase 5: End-to-end smoke
- [ ] Manual run against a scratch workspace via both entry points (`octocode-agent ingest --connector web-search` and the raw `pi -e ...` invocation) → confirm a tagged memory lands in `query workboard` under `MemoryReview` with reason `unattended_write` in both cases
- [ ] Confirm a normal (non-ingestion) memory record is unaffected — no reason fires, no behavior change

## Files, APIs, and Contracts
| Surface | Change | Blast-radius evidence | Compatibility |
|---|---|---|---|
| `packages/octocode-awareness/src/repo-workboard.ts` | +1 line, additive reason | No DDL touched; existing tests must stay green | Backward compatible |
| `packages/octocode-pi-extension/src/connectors/*`, `src/schedule-state.ts` | New files, gated behind `OCTOCODE_INGESTION_MODE` | Inert when the mode is off (default) | Backward compatible |
| `packages/octocode-pi-extension/src/prompt.ts` (or sibling) | New mode-resolution function, same pattern as `resolvePromptMode` | Additive, no change to existing prompt-mode behavior | Backward compatible |
| `packages/octocode-agent/bin/launcher.mjs` | +1 reserved subcommand in `parseInvocation` | Existing `update`/`version`/`run` paths unchanged | Backward compatible |
| Awareness CLI (`memory record`) | No change — reused as-is | Zero | Fully compatible |
| Awareness SQLite schema | No change | Zero | Fully compatible |

## Risk Mitigations
| RFC risk/pre-mortem | Preventive action | Detection |
|---|---|---|
| Headless Pi doesn't behave without a TTY | Phase 0 spike before any other code is written | Spike fails → RFC reopens Alternatives (fall back to a non-Pi heuristic filter for v1) |
| Over-recording / review-lane noise | `importance <= 5` double-clamp (prompt + code) + empty default topic list until configured | `workboard` `MemoryReview` count growth tracked in KPI.md |
| Secret leakage into a memory row | Ingestion code never passes raw key material into the recorded payload; code review checklist item | Test asserting no configured key substring appears in any test-fixture memory payload |
| `pi-extension` silently becomes exclusive to `octocode-agent` | Standalone invariant stated explicitly in RFC + enforced by Phase 4b | Dependency-list assertion test fails CI if violated |
| Silent schema drift | Any accidental DDL touch is caught by existing fingerprint tests | `tests/schema.test.ts` fails CI |

## Test and Verification Plan
| Type | Scope | Approach | Command |
|---|---|---|---|
| Unit | `repo-workboard.ts` new reason | fixture-based | `yarn workspace @octocodeai/octocode-awareness test:quiet` |
| Unit | `pi-extension` connectors/state/clamp/mode-resolution logic | new/extended vitest suite | `yarn workspace @octocodeai/pi-extension test` |
| Unit | `octocode-agent` `parseInvocation` new `ingest` row | extend existing launcher tests | `yarn workspace octocode-agent test` |
| Guardrail | standalone dependency contract | dependency-list assertion | Phase 4b test |
| Integration/spike | headless Pi invocation | manual, captured as evidence in this doc | `pi --mode json "..."` |
| Smoke | end-to-end ingestion → review lane, via both entry points | scratch workspace | `octocode-agent ingest --connector web-search`; raw `pi -e ...` |
| Regression | existing MemoryReview reasons and prompt-mode behavior unaffected | existing awareness + pi-extension test suites | `yarn workspace @octocodeai/octocode-awareness verify` |

## Rollout, Migration, and Rollback
- Sequence: Phase 0 spike → Phase 1 (Awareness-side, land independently, zero behavior change until any row uses the tag) → Phases 2-3 (pi-extension content, ships inert until the env var is set) → Phase 4 (`octocode-agent` convenience subcommand) → Phase 4b (standalone guardrail test, required before merge) → Phase 5 smoke on a scratch workspace before any real cron install.
- Flags/canary: `OCTOCODE_ALLOW_INGESTION=1` (agent-side) and `OCTOCODE_INGESTION_MODE=1` (extension-side) are the on/off switches; both default off. Roll out to one operator's own machine first.
- Rollback trigger: `MemoryReview` `unattended_write` backlog grows without review for >7 days, or review reveals systematically low-quality rows → remove the cron entry (instant stop); Phase 1's one-line change stays (harmless, additive) unless explicitly reverted.
- Owner/approver: maintainer who owns `packages/octocode-awareness` approves Phase 1; `pi-extension` owner approves Phases 2-3 and 4b; `octocode-agent` owner approves Phase 4.

## Critical References
- `packages/octocode-awareness/docs/DB.md:84-86` — DDL-as-contract rule constrains Phase 1 to a code-only, non-schema change.
- `packages/octocode-awareness/docs/HARNESS.md:76-78` — existing gate pattern reused for `OCTOCODE_ALLOW_INGESTION`.
- `packages/octocode-agent/bin/launcher.mjs:163-176` — reserved-subcommand pattern Phase 4 extends.
- `packages/octocode-pi-extension/src/prompt.ts:45-51` — mode-resolution pattern Phase 2 mirrors.
- `packages/octocode-pi-extension/package.json` — standalone dependency contract Phase 4b guards.
- `node_modules/@earendil-works/pi-coding-agent/docs/json.md` — headless invocation contract Phase 0 must verify.
