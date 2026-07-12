# Implementation: Homeostatic Awareness Loop

> Decision: see `RFC.md` sections "Summary" and "Rationale and Alternatives". This file does not restate goals or scope; it closes RFC questions and lays out the build path.

## Resolved Questions (were open in RFC.md)

| Open question (RFC section) | Resolution | Evidence (`octocode-research`) | Confidence |
|---|---|---|---|
| Q1: Can the MVP avoid DB migrations and derive `attend`/workboard from existing rows? | Yes. Build `query workboard` and `attend` as derived read surfaces first. Existing `repo-profile`, `activity`, tasks, locks, refinements, signals, memories, gotchas, lessons, CSV, and HTML formats are already implemented. | `packages/octocode-awareness/src/repo-context.ts:14`, `packages/octocode-awareness/src/repo-context.ts:642`, `packages/octocode-awareness/src/repo-context.ts:677`, `packages/octocode-awareness/src/repo-context.ts:794` | confirmed |
| Q2: Should tasks become Kanban cards, or stay verification-debt rows with a derived board? | Keep tasks as verification-debt/audit rows. Derive Kanban-like columns from tasks, locks, signals, refinements, and memories. | `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:49`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:58` | confirmed |
| Q3: Where should resource docs live so they help agents without bloating the default briefing? | Put design-time resources in this RFC folder, add a concise source-skill reference only if implementing, and project only short links into `.octocode/references/`. Do not dump literature into `.octocode/AGENTS.md`. | `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:23`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:62` | likely |
| Q4: What are the initial projection budgets for Markdown, CSV, HTML, and start packets? | Start with conservative defaults: `attend --compact` target <= 120 lines or <= 8 KB JSON; `.octocode/AGENTS.md` <= 80 lines; `MEMORY.md`, `GOTCHAS.md`, `LEARN.md` <= 200 lines each; workboard <= 10 rows per column; CSV/HTML row caps remain explicit and configurable. | Current line-count baseline observed 2026-07-08; generated projections already support caps via `queryParams.limit` in `repo inject` at `packages/octocode-awareness/src/repo-context.ts:875` | likely |
| Q5: Should sleep/digest run automatically, or remain explicit/dry-run first? | Keep explicit and dry-run first for MVP. Add automatic scheduling only after the report is stable and the user opts in. | Existing digest supports dry-run counts before mutation at `packages/octocode-awareness/src/maintenance.ts:661`; current dry-run had all `would_*` counts 0, showing cleanup policy must be richer than age thresholds | confirmed |
| Q6: How should duplicate task rows be grouped without hiding audit evidence? | Group only in derived workboard output. Preserve task IDs and drill-down refs. Group by normalized status, files, rationale/test plan, agent, and recency bucket. Do not mutate raw `tasks`. | Tasks are audit/verification rows in `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:49`; current task query showed repeated PENDING hook rows for the same file | likely |
| Q7: Should awareness eventually sync to an external project board? | Deferred. External board export can be a later sink for selected refinements, not the local source of truth. | Current source-of-truth rule is SQLite plus generated projections, not external boards (`packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7`) | deferred |
| Q8: Should semantic embeddings become mandatory for memory navigation? | No. Keep lexical/salience recall as default; semantic recall remains optional when a host provides embeddings. | `packages/octocode-awareness/skills/octocode-awareness/SKILL.md:23`; `.octocode/MEMORY_NAVIGATION.md:83` | confirmed |
| Q9: How does the organ intuition reach every agent without bloating default context? | Add a concise source-skill reference and link it from `SKILL.md`; later expose the same map as optional `organ_state` or `--explain-organ` output in `attend`/sleep packets. | `packages/octocode-awareness/skills/octocode-awareness/references/homeostatic-loop.md`; RFC research sources in `RESOURCES.md` | likely |
| Q10: How should creativity, motivation, resources, and personality map into awareness? | Add a derived `drive_state`/collective-identity layer: goal, explore/exploit mode, learning gaps, resource leads, alternatives, team norms, and transactive map. Do not store a persistent persona. | Creativity network coupling, SDT, learning-progress curiosity, growth mindset, collective intelligence, team personality, information foraging, and transactive-memory sources in `RESOURCES.md` | likely |

## Approach

Implement the recommendation from `RFC.md` as a phased, reversible read-first plan:

1. define the homeostatic loop vocabulary, organ map, and resource map,
2. add drive/collective-identity vocabulary without persistent persona state,
3. add a derived workboard view,
4. add retrieval/compression and trust/provenance gates,
5. add `attend` as one compact agent start packet,
6. budget `.octocode` projections,
7. add report-first sleep/digest improvements,
8. validate with snapshot fixtures and bloat metrics.

## Steps (dependency-ordered)

### Phase 1: Vocabulary and Resources

- [x] Add or maintain a concise source-skill reference, `packages/octocode-awareness/skills/octocode-awareness/references/homeostatic-loop.md`, explaining the loop, organs, budgets, and resource routing.
- [x] Include the drive layer in that reference: vision, curiosity, imagination, team temperament, and transactive memory as command/state concepts.
- [x] Link that reference from `packages/octocode-awareness/skills/octocode-awareness/SKILL.md` for memory/wiki/task/reflection bloat, workboards, `attend`, or digest policy.
- [x] Keep deep research in RFC/resource docs, not default agent briefings.
- [x] Regenerate mirrors with `yarn workspace @octocodeai/octocode-awareness build` if source skill files change.

### Phase 2: Derived Workboard View

- [x] Extend `AWARENESS_QUERY_VIEWS` in `packages/octocode-awareness/src/repo-context.ts` with `workboard`, or add a new read function called by `attend` if keeping query views simpler.
- [x] Implement a pure function that groups rows into columns: Inbox, Verify, Ready, Claimed, Recent Done, Memory Review, Projection Health.
- [x] Preserve raw IDs in grouped rows: `task_id`, `lock_id`, `signal_id`, `refinement_id`, `memory_id`, plus count/representative fields.
- [ ] Add remaining board-tuning parameters: `limit_per_column`, `include_done_since`, and explicit `group_tasks`; current slice reuses existing scope/query/file/limit plumbing.
- [x] Expose CSV/table/JSON/Markdown output through the existing formatter path.

### Phase 3: `attend` Start Packet

- [x] Add a read-only library planner, likely `src/attend.ts`, that calls in-process functions rather than shelling out.
- [x] Inputs: workspace scope, artifact/repo/ref, free-text query, files, limit, compact flag; labels remain a later filter.
- [x] Trace core read steps: `repo_profile`, `workboard`, `memory_recall`, and `projection_health`; explicit `workspace_status`/gotchas/lessons trace lanes remain a later expansion.
- [x] Route recall through exact/file/ref matching, lexical search, optional semantic search, and simple rerank/scoring. Keep lexical as the portable baseline.
- [x] Add a selective augmentation step that can abstain when recall is weak, compress selected evidence, and include `why_selected`, raw IDs, and source refs.
- [x] Return `profile`, `organ_state`, `workboard`, `evidence`, `gaps`, `bloat_warnings`, `verification_targets`, `trust_warnings`, and `next`.
- [x] Return optional `drive_state`: `goal`, `mode`, `learning_gaps`, `resource_leads`, `alternatives`, `team_norms`, and `transactive_map`.
- [x] Keep `organ_state` compact: senses, attention, memory, error signals, pruning candidates, cleanup needs, bridge/coordination, drive/identity, projection health.
- [x] Add CLI command `attend` with JSON default and compact output.
- [x] Consider `attend --explain-organ` or `schema example attend` output that shows the organ map for first-time agents without adding it to every packet.
- [x] Add schema/examples for `attend` so agents can discover it through `schema commands --compact`.

### Phase 3c: Drive and Resource Routing

- [x] Add a pure derived helper that computes `drive_state` from the user query, plan/RFC/KPI refs, workboard pressure, recall gaps, failed checks, resource refs, signals, and refinements.
- [x] Set `mode` to `explore`, `exploit`, or `mixed` using evidence strength and uncertainty. Example: weak evidence plus open design question -> explore; clear pending verification -> exploit.
- [x] Emit at most a few `resource_leads`, each with source, why useful, cost/freshness, and verification status.
- [x] Emit at most a few `alternatives`, each linked to evidence or explicit uncertainty.
- [x] Derive `team_norms` from source skill policy and repo guidance, not chat style. Norms are things like evidence-first, non-destructive, bounded, cooperative, and concise.
- [x] Represent collective identity through `transactive_map`: memory IDs, source refs, files, agent IDs, signals, refinements, and freshness. Do not store a fictional self or enduring personality.
- [x] Keep this read-only in the first slice. Add resource tables only after traces show existing refs/projections cannot answer "where should I learn next?"

### Phase 3b: Memory Trust Gate

- [ ] Add a read-only trust/provenance assessment helper for candidate memories/reflections before changing write paths.
- [ ] Score or label evidence presence, source type, verification state, scope specificity, similar active memories, and prompt-injection risk.
- [ ] Show supersession candidates before recording another durable memory.
- [ ] Keep memory writes allowed, but warn when a candidate is unverified, unscoped, duplicate, or sourced only from generated projections/raw chat.
- [ ] Do not allow retrieved external text, generated docs, or unverified reflections to change policy, hooks, harness behavior, or skills without code/user verification.

### Phase 4: Projection Budgets

- [x] Add explicit projection-budget defaults to the repo context renderer or inject params.
- [x] Write budget metadata to `.octocode/awareness/manifest.json`: total rows, projected rows, caps, generated_at, workspace, mode, source DB path warning.
- [x] Keep generated Markdown summary-first and push full row browsing to CSV/HTML/query.
- [x] Add a short "Projection Health" section to `.octocode/AGENTS.md`, not a long dump.
- [ ] Improve `.octocode/awareness/index.html` with client-side filtering/sorting if current static table is too flat for human inspection.

### Phase 5: Sleep/Digest Report

- [ ] Add a read-only `maintenance sleep --dry-run` alias or `maintenance digest --report homeostatic` mode that combines digest counts, projection health, low-novelty memories, stale refinements, duplicate task clusters, and docs staleness.
- [ ] Report immune-style tags such as `duplicate`, `stale`, `unverified`, `unsafe_source`, `low_novelty`, and `supersession_candidate` without deleting by default.
- [ ] Report glymphatic-style cleanup lanes: expired locks, stale signals, stale projections, old superseded memories, duplicate task clusters, and FTS/index rebuild status.
- [ ] Keep destructive cleanup behind existing digest/prune/forget commands or explicit new flags.
- [ ] Surface consolidation candidates from novelty/similar memory data without automatically superseding.
- [ ] Add recommended commands in the report, such as `memory forget --superseded`, `repo inject`, or `verify audit`.

### Phase 6: Verification and Rollout

- [x] Add unit tests for workboard grouping using in-memory SQLite fixtures.
- [x] Add CLI snapshot tests for `query workboard --format json|table|csv`.
- [ ] Add remaining `attend` tests for broad architecture query, recurring failure, empty recall, and bloat warning; current slice covers file scope, open signal, pending verification, evidence, drive state, and organ map.
- [x] Add projection tests asserting Markdown budgets and manifest cap metadata.
- [ ] Add digest/sleep dry-run tests asserting no mutation.
- [ ] Update skill/reference docs and run `yarn workspace @octocodeai/octocode-awareness test`.
- [ ] Run broader checks from root as appropriate: `yarn lint`, `yarn typecheck`, or `yarn verify`.

## Files / APIs / Contracts Touched

- `packages/octocode-awareness/src/repo-context.ts:14` - add a workboard view or reuse existing view plumbing.
- `packages/octocode-awareness/src/repo-context.ts:642` - use repo-profile metrics for bloat warnings.
- `packages/octocode-awareness/src/repo-context.ts:677` - reuse activity-style row aggregation for workboard feed.
- `packages/octocode-awareness/src/repo-context.ts:794` - reuse format dispatch for JSON/table/CSV/Markdown/HTML.
- `packages/octocode-awareness/src/repo-context.ts:855` - add projection budgets and manifest fields in repo injection.
- `packages/octocode-awareness/src/maintenance.ts:642` - build sleep/digest report around existing cleanup semantics.
- `packages/octocode-awareness/src/memory.ts:567` - reuse novelty/similarity data for consolidation candidates.
- `packages/octocode-awareness/bin/awareness.ts` - add CLI command wiring after library functions exist.
- `packages/octocode-awareness/scripts/schema.mjs` - add command schema/examples for discoverability.
- `packages/octocode-awareness/skills/octocode-awareness/references/` - add concise loop reference.
- `.octocode/` generated projections - changed only by `repo inject`, not hand-edited as canonical data.

## Risk Mitigations

| Risk | Mitigation |
|---|---|
| `attend` becomes too verbose | Hard compact budget, default row caps, bloat test fixtures |
| `drive_state` becomes anthropomorphic | Derived fields only; no persona storage; tests assert goal/gap/resource/norm outputs |
| Workboard hides important audit rows | Preserve raw IDs and counts; provide drill-down query refs |
| Projection caps hide useful context | Include gap counts and point to query/CSV/HTML for full rows |
| Cleanup deletes useful evidence | Report-first sleep; destructive cleanup remains explicit |
| New docs create more bloat | Put deep resources in RFC/appendix; source skill reference stays compact |
| Users confuse CSV with DB | Generated-file banner, manifest warning, no CSV import |
| Agents trust stale wiki | Include generation time/scope and "leads, not proof" banner |
| Retrieval injects noise | Hybrid recall, rerank/compress, abstain, show why-selected diagnostics |
| Persistent memory gets poisoned | Trust/provenance gate, scoped writes, source refs, human/code verification before policy promotion |

## Test and Verification Plan (V&V)

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Unit | workboard grouping | In-memory DB fixtures for duplicate tasks, open signals, refinements, pending verification | `yarn workspace @octocodeai/octocode-awareness test` |
| Unit | attend planner | Mock or fixture DB rows, assert trace/evidence/gaps/budgets | `yarn workspace @octocodeai/octocode-awareness test` |
| Unit | retrieval gate | Fixture rows with exact hit, lexical hit, weak hit, stale generated projection, and irrelevant top-k noise | `yarn workspace @octocodeai/octocode-awareness test` |
| Unit | trust gate | Candidate memories with missing refs, duplicate/superseded refs, verified command refs, and external-source-only refs | `yarn workspace @octocodeai/octocode-awareness test` |
| Unit | organ state | Fixture workspace maps counts and risks into senses/attention/memory/error/pruning/cleanup/bridge/projection lanes | `yarn workspace @octocodeai/octocode-awareness test` |
| Unit | drive state | Fixture query maps goals, gaps, resource leads, alternatives, team norms, and transactive refs without persistent persona fields | `yarn workspace @octocodeai/octocode-awareness test` |
| CLI | query workboard | Snapshot JSON/table/CSV output | `yarn workspace @octocodeai/octocode-awareness test` |
| CLI | attend | Run against fixture DB and current workspace smoke | `node packages/octocode-awareness/dist/bin/awareness.js attend --workspace "$PWD" --query "..." --compact` |
| Projection | repo inject budgets | Assert Markdown line/row caps and manifest cap metadata | `yarn workspace @octocodeai/octocode-awareness test` |
| Safety | sleep/digest | Assert dry-run does not mutate counts | `node packages/octocode-awareness/dist/bin/awareness.js maintenance digest --workspace "$PWD" --dry-run --compact` |
| Regression | existing commands | Existing memory/lock/verify/signal/refinement/query tests remain green | `yarn workspace @octocodeai/octocode-awareness test` |

## Rollout / Migration / Rollback

- **Sequencing:** ship read-only `query workboard` first, then `attend`, then projection budgets, then sleep/digest report.
- **Flags / gating:** keep any destructive sleep behavior disabled by default; only read/report commands ship initially.
- **Rollback trigger:** if `attend --compact` exceeds budget, hides verification debt, or regresses existing query/repo inject behavior, disable the new command/view and keep existing commands.
- **Owner / approver:** Awareness package maintainer and user review before automatic cleanup or generated-doc policy changes.

## References

- `RFC.md` - goals, scope, alternatives, and decision.
- `RESOURCES.md` - deep local/external resource map.
- `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:7` - one store, many surfaces.
- `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:23` - table roles.
- `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7` - generated projection model.
- `.octocode/MEMORY_NAVIGATION.md:11` - deterministic navigation prototype recommendation.
