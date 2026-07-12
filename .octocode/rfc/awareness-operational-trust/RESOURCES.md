# Resources and Evidence: Octocode Awareness Operational Trust

Original evidence date: 2026-07-09 at `debb3de0`

Revalidated: 2026-07-10 at `a4383dec`

Decision authority: [RFC.md](./RFC.md)

## Claim Ledger

| Claim | Evidence | Confidence | State / use | Remaining gap |
| --- | --- | --- | --- | --- |
| Workboard exact totals were capped in the original baseline | `debb3de0` probe 500/550; fixed at `src/repo-context.ts:1419`–`:1432` | confirmed | fixed in interim v3; G1 regression | prove every other view uses exact totals |
| Repo-profile still presents capped file rows as totals | `src/repo-context.ts:945`–`:1006`, `:1045`–`:1058`; live 500 tracked/243 missing | confirmed | open; G1 | shared snapshot envelope |
| Audit sees stale work omitted by attend | isolated probe: attend Verify 0, audit 1; `src/verify.ts` vs workboard selection | confirmed | open; G1/G2 | snapshot identity-set parity |
| Plan status once failed to gate claims | fixed at `src/tasks.ts:279`–`:304`, `:324`–`:333` | confirmed | fixed in interim v3; G3 regression | v4 service invariant |
| Hook fallback amplifies runs per edit | `bin/hook-runner.ts:545`, `:609`; `src/pi-hooks.ts:400`–`:421`; 1,265 pending | confirmed | open; G5 | host capability/policy experiment |
| Session IDs lack final immutable ownership semantics | v3 session/run paths; provisional v4 active-identity index needs amendment | confirmed | open; G3/G8 | resume/collision/service tests |
| Lock release and verification still have separate lifecycle owners | `src/intents.ts`, `src/verify.ts` | confirmed | open; G3 | v4 atomic finish |
| CLI command facts are duplicated | `bin/awareness.ts` routes/help/dispatch; `scripts/schema.mjs`; 68 indexed routes | confirmed | open; G7 | route manifest/dispatcher |
| v3 now rejects future/foreign stores before mutation | `src/db.ts:81`–`:125`; byte-preservation tests | confirmed | fixed in interim v3; G8 regression | exact-v4 production path |
| Refinements duplicate backlog/communication/learning | 90 open/ongoing, 81 handoffs; 16 exact duplicate groups | confirmed | open; cutover disposition | zero unreviewed actionable rows |
| Package root exports nearly every internal helper | `src/index.ts`; Pi direct imports | confirmed | open; G7 | in-repo consumer migration |
| Provisional v4 memory DDL drops fields current code uses | v3 `db.ts` memory columns; `memory.ts`/`maintenance.ts`/`repo-context.ts` usage; `src/v4/schema.ts:228`–`:267` | confirmed | blocks P6a/schema freeze | lossless parity or explicit replacement |
| Incremental itemized context can resist full-context rewriting but may increase raw tokens | ACE §2–§4 and Appendix A.5 | likely; agent-context evidence, not workspace coordination | core token guardrail; follow-on curation | reproduce on Awareness fixtures |
| Provenance-linked drill-down can improve evidence use | NapMem §3–§4 | likely for its user-memory tasks; transfer uncertain | core exact-fetch; follow-on learned routing | deterministic local navigation eval |
| Surprise can beat recency in a bounded model KV cache | HOLA §3.3, §4.4–§4.5 | uncertain transfer; model-level/single-seed limitation | follow-on only | local surprise/recency ablation |
| Self-generated judges risk length bias/reward hacking | Self-Rewarding LM limitations | likely warning by analogy | follow-on boundary | external/held-out evaluator |
| Stable reference data constrains iterative self-play | SPIN method/limitations | likely within model training | follow-on boundary | no direct harness evidence |
| Verifier-grounded bounded harness edits can improve a fixed task suite | Self-Harness; Weng secondary synthesis | likely, limited task/model coverage | follow-on only | separate RFC and stronger gates |
| Pi package cannot publish current runtime protocols | `package.json` has two `workspace:*`; `check:no-workspace` fails | confirmed | open; P4/G7 | pin/bundle/delegate + clean tarball |
| Awareness package release can ignore declaration failure | `build.mjs:101`–`:115`; verifier omits explicit types assertion | confirmed | open; P4 | fail closed + TS consumer |
| Concurrent WAL versions need runtime guard | official SQLite WAL docs; Node release; `src/v4/runtime.ts` | confirmed | isolated v4 slice implemented | supported runtime matrix/doctor |

## Local Code References

### Data model and plans

- `packages/octocode-awareness/src/db.ts:291` — plans and lead agent.
- `packages/octocode-awareness/src/db.ts:322` — tasks belong to plans.
- `packages/octocode-awareness/src/db.ts:337` — multiple task paths.
- `packages/octocode-awareness/src/db.ts:353` — runs with TASK/WORK/HOOK origins.
- `packages/octocode-awareness/src/db.ts:391`, `:419`, `:496` — separate task/run/edit event logs.
- `packages/octocode-awareness/src/plans.ts:78` — timestamped plan directory naming.
- `packages/octocode-awareness/src/plans.ts:98`–`:140` — `.octocode/plan/<timestamp>-<slug>` creation and primary/manifest docs.
- `packages/octocode-awareness/src/tasks.ts:173` — task creation validates parent plan existence/status.
- `packages/octocode-awareness/src/tasks.ts:279`–`:304` and `:324`–`:333` — interim v3 plan-status readiness/claim gates.

### Snapshot and verification

- `packages/octocode-awareness/src/repo-context.ts:1419`–`:1432` — exact interim v3 workboard totals.
- `packages/octocode-awareness/src/repo-context.ts:945`–`:1006`, `:1045`–`:1058` — capped repo-profile file rows reused as totals.
- `packages/octocode-awareness/src/attend.ts:484`–`:504` — current verification next-action and total extraction.
- `packages/octocode-awareness/src/verify.ts:234` — abandon returns pre-mutation arrays.
- `packages/octocode-awareness/src/verify.ts:248` — stale active detection.
- `packages/octocode-awareness/src/maintenance.ts:732`–`:850` — digest/prune coverage and refinement retention.

### Hooks, sessions, locks

- `packages/octocode-awareness/bin/hook-runner.ts:191`–`:196` — filesystem correlation state constants.
- `packages/octocode-awareness/bin/hook-runner.ts:545` — shell pre-edit HOOK fallback run.
- `packages/octocode-awareness/bin/hook-runner.ts:609` — shell post-edit pending transition.
- `packages/octocode-awareness/src/pi-hooks.ts:400`–`:421` — Pi HOOK fallback run.
- `packages/octocode-awareness/src/intents.ts:176` — lock release lifecycle coupling.
- `packages/octocode-awareness/src/work.ts:158` — work run reuse excludes HOOK fallback.
- `packages/octocode-awareness/src/v4/schema.ts:272`–`:290` — provisional host/session and active-run uniqueness indexes requiring Amendment 1 tests.

### CLI, skill, packaging

- `packages/octocode-awareness/bin/awareness.ts:175`–`:183` — noun-level allowed-flag unions.
- `packages/octocode-awareness/bin/awareness.ts:239`–`:309` — command routes.
- `packages/octocode-awareness/bin/awareness.ts:2061` — production v3 direct CLI dispatcher.
- `packages/octocode-awareness/scripts/schema.mjs:1084` — command catalog/examples.
- `packages/octocode-awareness/skills/octocode-awareness/SKILL.md:14`–`:38` — 49-line compact lobby and conditional reference routing.
- `packages/octocode-awareness/build.mjs` — canonical skill bundling/mirroring.
- `packages/octocode-awareness/src/index.ts:12` — broad package-root internal exports.
- `packages/octocode-awareness/src/tool-operations.ts:1` — second application dispatcher.
- `packages/octocode-awareness/build.mjs:101`–`:115` — declaration emit is fail-open unless an environment override is set.
- `packages/octocode-awareness/scripts/verify-package.mjs:31`–`:64` — dry-pack plus copied local build; no explicit declared-types consumer test.
- `packages/octocode-pi-extension/package.json:42` — Pi runtime dependency requiring clean-package resolution proof.

## Local Measurements

The canonical store was queried read-only at `~/.octocode/memory/awareness.sqlite3`, scoped to this workspace unless stated otherwise. Do not commit raw content or agent messages.

### Workspace snapshot

```text
runs: HOOK ACTIVE 20, HOOK FAILED 3, HOOK PENDING 1265,
      HOOK SUCCESS 558, TASK ACTIVE 1, TASK FAILED 1, TASK SUCCESS 12,
      WORK SUCCESS 16
pending older than 24 hours by julianday(updated_at): 749
active runs: 21; active older than 24 hours: 17
plans: 4 (1 ACTIVE); tasks: 13 (1 IN_PROGRESS); signals: 40 (34 open)
refinements: 137; 90 open/ongoing; 81 open handoffs; 16 exact duplicate groups
workspace memories: 113; ACTIVE 102; 51 ACTIVE without refs; 17 missing active file refs
current active plan/task/run blocks cutover
```

### Global store snapshot

```text
database bytes: 7,835,648; `integrity_check=ok`; FK check empty
global ACTIVE memories: 263; 180 without refs
legacy `agent_intents`: 115; `intent_events`: 230
```

### Synthetic/CLI probes

```text
historical 550-task workboard cap is fixed in interim v3
repo-profile currently reports capped tracked/missing totals from a 500-row source
1 expired ACTIVE WORK -> attend Verify 0, verify audit 1
historical COMPLETED-plan claim defect is fixed in interim v3
verify audit --abandon -> cleanup succeeds, same invocation exits 1 with old count
original compact payloads: attend 508 B empty; 538 B at 550 tasks
original workboard 692 B empty; 3,899 B at 550 tasks
original repo inject compact 4,020–4,574 B
original prescribed instruction flow about 11,431 B; current entry skill is 49 lines with conditional references
```

### Verification baseline

```text
Original baseline: Awareness 38 files / 654 tests; isolated artifact 130 files
Revalidation: Awareness `test:quiet` passed; typecheck passed; focused v4 29 tests passed;
isolated artifact verifier passed with 133 files
Pi build/test: 11 files / 192 passed / 2 skipped; typecheck passed
Pi publish-protocol gate: failed on two `workspace:*` runtime dependencies
large current source surfaces: repo-context.ts 2,191 lines; awareness.ts 2,197;
schema.mjs 1,303; types.ts 1,144; db.ts 1,079; tool-operations.ts 753
```

## Existing RFCs Reviewed

- [`awareness-audit-hardening`](../awareness-audit-hardening/RFC.md)
- [`awareness-cli-skill-consolidation`](../awareness-cli-skill-consolidation/RFC.md)
- [`awareness-task-persistence`](../awareness-task-persistence/RFC.md)
- [`awareness-repo-context`](../awareness-repo-context/RFC.md)
- [`homeostatic-awareness-loop`](../homeostatic-awareness-loop/RFC.md)
- [`awareness-reflection-scorecards`](../awareness-reflection-scorecards/RFC.md)
- [`hola-protected-memory`](../hola-protected-memory/RFC.md)

Current source and live probes take precedence when an older RFC describes pre-implementation behavior.

## External Primary Sources and Prior Art

- [SQLite transaction documentation](https://sqlite.org/lang_transaction.html) — deferred versus immediate transactions and single-writer behavior.
- [SQLite WAL documentation](https://sqlite.org/wal.html) — WAL concurrency, checkpoint behavior, and the 2026 WAL-reset defect/fixed versions.
- [Node.js 22.22.3 release](https://nodejs.org/en/blog/release/v22.22.3) — updates bundled SQLite to 3.51.3.
- [Node.js `node:sqlite` documentation](https://nodejs.org/api/sqlite.html) — runtime API and stability status by Node line.
- [Agentic Context Engineering](https://arxiv.org/html/2510.04618) — structured incremental context deltas and deterministic merge; also reports raw-token cost and harm from unreliable feedback. Supports core token/provenance guardrails, not automated curation.
- [NapMem](https://arxiv.org/html/2607.05794v1) — provenance-linked memory levels and active navigation on user-memory benchmarks. Supports exact drill-down; learned routing remains follow-on.
- [HOLA](https://arxiv.org/html/2607.02303v1) — surprise-based bounded KV retention in a model-level cache. Follow-on hypothesis only; not a database blueprint or migration justification.
- [Self-Rewarding Language Models](https://arxiv.org/abs/2401.10020) — preliminary self-judgment gains plus length-bias, judge, reward-hacking, and capability-risk warnings.
- [SPIN](https://arxiv.org/abs/2401.01335) — iterative self-play against a stable reference/target; supports the ceiling/reference warning, not a generic judge-error claim.
- [Self-Harness](https://arxiv.org/html/2606.09498v1) — primary evidence for verifier-grounded failure clusters, bounded proposals, held-in/out gates, and logged rejects on a limited task suite; follow-on only.
- [Harness Engineering for Self-Improvement](https://lilianweng.github.io/posts/2026-07-04-harness/) — secondary synthesis for protected permission/evaluator boundaries, not independent empirical proof.
- [A Taxonomy of Self-Evolving Agents](https://lsl.zone/blog/2026/a-taxonomy-of-self-evolving-agents/) — conceptual separation of artifact, harness, and model evolution; vocabulary, not empirical proof.
- [Recursive Self-Improvement](https://www.lesswrong.com/posts/JBadX7rwdcRFzGuju/recursive-self-improvement) — conceptual vocabulary only; not product evidence.
- [Beads repository](https://github.com/gastownhall/beads) — adjacent agent-task prior art for dependency-aware ready work, atomic claiming, compact context, and durable task memory. It is not a replacement recommendation.

The supplied [arXiv:2606.12745](https://arxiv.org/abs/2606.12745) is a differential-geometry paper about horoconvex domains and is excluded as unrelated. The supplied X posts were treated as discovery pointers only; decisions cite the primary papers above.

## Search Prompts Used

- `site:sqlite.org WAL concurrent write checkpoint bug fixed 3.51.3`
- `site:nodejs.org v22 SQLite 3.51.3 release`
- `official agent task tracker atomic claim dependencies compact context repository`
- `agent memory provenance active navigation evidence hit irrelevant tool calls`
- `self improving agent harness held out regression bounded failure mining`
- local searches for `column_total`, `LIMIT 500`, `PENDING`, `user_version`, `INSERT OR IGNORE sessions`, `releaseFileLock`, command routes/flags/help/schema, and hook pre/post lifecycle.

## Evidence Gaps to Close During Prerequisites

1. Confirm every supported Node line's embedded SQLite version and establish the package support floor.
2. Choose and prove Pi's package dependency strategy; current `workspace:*` specs fail the release gate.
3. Verify every production-supported shell/Pi host's blocking/session capability; downgrade incapable hosts to cooperative-only in `doctor`.
4. Close the live-state disposition gate immediately before cutover; the current active plan/task/run already falsifies the prior empty-queue premise.
5. Freeze a representative memory migration corpus and prove field/reference/FTS/embedding/default-recall parity before finalizing DDL.
6. Define numeric ordinary-hook experiment thresholds and choose the default policy.
7. Make Awareness declaration/real-tarball/TypeScript-consumer verification fail closed.

These are decision or release gates. Items 4–7 materially changed Amendment 1 and block acceptance/cutover.
