# Success & Verification: Homeostatic Awareness Loop

> Verifies `RFC.md` goals and the `IMPLEMENTATION.md` build. Goals are referenced, not restated.

## User Stories to Check

- **As an agent starting work,** I want one compact `attend` packet so that I can see relevant memories, verification debt, signals, refinements, and bloat warnings without reading huge docs. (-> `RFC.md` Goal G1)
- **As an agent editing files,** I want tasks and locks to show as verification debt, not a fake project backlog, so that I clear checks before finishing. (-> `RFC.md` Goal G4)
- **As a human maintainer,** I want CSV/HTML row views plus small Markdown summaries so that I can sort/filter details without making giant docs canonical. (-> `RFC.md` Goals G2, G3, G7)
- **As a future agent,** I want generated wiki pages to stay concise and traceable so that they help rather than bury the next decision. (-> `RFC.md` Goals G3, G6)
- **As an awareness maintainer,** I want sleep/digest to report consolidation and pruning opportunities before destructive actions so that cleanup is safe. (-> `RFC.md` Goal G5)
- **As a skill author,** I want deep brain/nature resources available but not loaded by default so that research helps design without bloating everyday context. (-> `RFC.md` Goal G8)
- **As any agent using the awareness skill or CLI,** I want a compact organ map so that I understand which command senses, attends, learns, prunes, cleans, bridges, or projects without reading the whole wiki. (-> `RFC.md` Goal G9)
- **As several agents sharing a workspace,** I want vision, curiosity, resource leads, creative options, and team norms represented as compact derived state so that we improve together without inventing one persistent personality. (-> `RFC.md` Goal G10)

## Acceptance Criteria (Gherkin)

```gherkin
Feature: Agent attend packet
  Scenario: Start packet remains compact
    Given a workspace with hundreds of memories and tasks
    When an agent runs "awareness attend --workspace $PWD --query current-task --compact"
    Then the output includes profile counts, workboard columns, evidence, gaps, and next action
    And the compact output stays within the configured size budget
    And every memory or generated-doc claim is marked as a lead to verify

  Scenario: Verification debt is visible
    Given pending task rows and no active locks
    When an agent runs "awareness query workboard --workspace $PWD --format json"
    Then pending tasks appear in the Verify column
    And raw task IDs remain available for drill-down

  Scenario: Duplicate task noise is grouped
    Given multiple recent PENDING hook task rows for the same file and rationale
    When the workboard is generated with grouping enabled
    Then the workboard shows one grouped row with a count
    And the grouped row preserves child task IDs

  Scenario: Wiki projection is bounded
    Given generated awareness docs exceed the configured line budget
    When "repo inject" runs with projection budgets enabled
    Then Markdown docs stay within their configured caps
    And CSV/HTML/query paths expose the omitted rows
    And manifest records counts, caps, and generation time

  Scenario: Sleep is report-first
    Given memories, refinements, tasks, and generated docs
    When an agent runs the sleep/digest report in dry-run mode
    Then no DB rows are deleted or changed
    And the report lists cleanup, consolidation, projection, and verification recommendations

  Scenario: Deep resources do not bloat default briefing
    Given the Homeostatic Awareness Loop resources exist
    When an agent reads normal awareness startup guidance
    Then it sees only the compact routing note
    And it can open the RFC/resources only when the task needs loop design or bloat policy

  Scenario: Retrieval is selective
    Given many memories, generated docs, and irrelevant rows
    When an agent runs "awareness attend --workspace $PWD --query current-risk --compact"
    Then selected evidence includes why-selected notes and raw IDs
    And weak or irrelevant recall can be omitted with a gap warning
    And the packet stays within budget

  Scenario: Durable memory is gated
    Given a candidate memory from raw chat or an external article
    When the trust/provenance gate evaluates it
    Then missing evidence, missing scope, duplicate active memories, and policy-promotion risk are reported
    And the memory is not treated as policy until verified by user, code, command output, or cited source IDs

  Scenario: Awareness organ map is available to agents
    Given an agent has installed or loaded the octocode-awareness skill
    When it opens the skill reference map or future "attend --explain-organ"
    Then it sees the compact mapping from senses, attention, memory, error signal, immune pruning, sleep cleanup, corpus bridge, and projection to concrete CLI commands
    And the map states that SQLite is canonical and generated wiki/CSV/HTML projections are not authority

  Scenario: Drive state is useful but not a persona
    Given multiple agents have left memories, signals, refinements, resource refs, and verification results
    When an agent runs "awareness attend --workspace $PWD --query current-design --compact"
    Then the output may include drive_state with goal, mode, learning_gaps, resource_leads, alternatives, team_norms, and transactive_map
    And every resource lead or alternative includes why it was selected
    And the packet does not store or claim a permanent agent personality

  Scenario: Resource leads reduce uncertainty
    Given a design question with weak local evidence
    When drive_state chooses explore or mixed mode
    Then resource_leads point to local docs, RFC resources, source URLs, or code refs
    And each lead is marked as a lead to verify, not an authority
```

## Definition of Done

- [ ] Acceptance scenarios pass.
- [x] `query workboard` or equivalent derived workboard exists and is read-only.
- [x] `attend` exists or the RFC explicitly accepts `query workboard` as the first shipped slice.
- [x] Existing awareness commands and tests remain green.
- [x] Projection budgets and manifest counts are implemented before claiming bloat control.
- [x] Retrieval/compression gate exists before `attend` becomes the recommended first command.
- [ ] Trust/provenance gate exists before durable memory promotion becomes more automatic.
- [x] The source awareness skill includes a compact organ-map reference and future CLI examples can expose it without bloating every run.
- [x] `drive_state` or its accepted precursor is derived and compact; it exposes goals, gaps, resources, alternatives, norms, and transactive refs without persistent persona storage.
- [ ] Sleep/digest changes are dry-run/report-first.
- [x] Docs clarify SQLite canonical state vs. generated projections.
- [x] Deep resources are linked from an opt-in reference, not pasted into default startup docs.

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| Compact attend size | primary outcome | no `attend`; agents read multiple commands/docs | <= 120 lines or <= 8 KB JSON for default compact output | first release + weekly sample | CLI output snapshot |
| Markdown projection size | primary outcome | 1291 lines across five `.octocode` docs on 2026-07-08 | <= 700 lines across `AGENTS.md`, `MEMORY.md`, `GOTCHAS.md`, `LEARN.md`, and loop/navigation pointer docs, excluding CSV/HTML | first release + after each `repo inject` | `wc -l` |
| Workboard duplication reduction | driver | recent task query showed repeated PENDING rows for the same file | >= 80% of duplicate task clusters grouped in workboard output while preserving IDs | first release | fixture tests + live smoke |
| Verification debt visibility | driver | pending tasks require manual query/audit | 100% of PENDING tasks represented in Verify column or explicit omitted count | first release | workboard tests |
| Projection freshness clarity | driver | generated docs exist but freshness must be inspected manually | manifest includes generated_at, row counts, caps, workspace, and mode on every inject | first release | projection tests |
| Retrieval selectivity | driver | recall can return relevant rows but has no explicit abstain/compress gate | every `attend` evidence item has ID/ref/why-selected, and weak recall produces gaps instead of stuffing | first release | attend snapshots |
| Memory promotion hygiene | driver | memory record supports novelty/supersession but no explicit trust packet | candidate durable memories report evidence, scope, duplicate, and verification status | first release | trust-gate tests |
| Organ-map discoverability | driver | agents currently see a command checklist but not the body-like mechanism | source skill links one compact organ map; future `attend`/schema examples expose the same map on demand | first release | docs review + CLI snapshot |
| Drive-state usefulness | driver | no compact shared view of vision, curiosity, resources, alternatives, or team norms | >= 80% of sampled design/start packets include actionable goal/gap/resource/next-probe fields when uncertainty exists | first release + weekly sample | attend snapshots + reflection review |
| Resource lead precision | driver | resources live in docs or external search, not routed by task | >= 70% of accepted resource leads are used, cited, or explicitly rejected with reason | first release + monthly review | reflection scorecards + RFC/resource refs |
| Persona-bloat prevention | guardrail | team norms are implicit in skills/docs | zero durable memories or default packets that define a fictional permanent agent self as authority | every review | grep/docs review + memory trust gate |
| Cleanup safety | guardrail | digest dry-run available | destructive sleep cleanup remains opt-in; dry-run changes 0 rows | every release | dry-run tests |
| Existing command compatibility | guardrail | current query/repo inject/memory/verify commands work | no regressions in awareness test suite | every release | `yarn workspace @octocodeai/octocode-awareness test` |
| Source-of-truth drift | guardrail | SQLite canonical, projections generated | no CSV/Markdown import path added by this RFC | every review | code review |

## Decision Rule

- **Success if** `attend` or `query workboard` gives agents a compact, traceable start packet; generated Markdown stays within budget; and existing awareness tests pass without changing canonical storage semantics.
- **Iterate if** agents still need to read full `MEMORY.md`/`GOTCHAS.md` for ordinary startup, workboard grouping hides raw verification IDs, or docs exceed budgets after normal `repo inject`.
- **Roll back if** the new view/command regresses existing query/repo inject behavior or creates a second writable source of truth.

## Traceability Matrix

| RFC requirement | User story | Acceptance criteria | Verification method | Post-ship status |
|---|---|---|---|---|
| G1: one front door | Agent starting work | Agent attend packet | CLI snapshot + fixture test | implemented first slice |
| G2: canonical storage stays SQLite | Human maintainer | CSV/HTML are generated; no import path | code review + docs check | implemented |
| G3: bloat visible and bounded | Future agent | Wiki projection is bounded | `wc -l`, projection tests, manifest inspection | partial: manifest budgets and Projection Health shipped; stricter cap enforcement remains |
| G4: active work vs. durable learning separated | Agent editing files | Verification debt is visible | workboard fixture tests | implemented first slice |
| G5: sleep maintenance report-first | Awareness maintainer | Sleep is report-first | dry-run mutation test | pending |
| G6: evidence discipline | Future agent | Memory/doc claims marked as leads | output snapshot + docs check | pending |
| G7: Kanban-like board without new truth | Human maintainer | Duplicate task noise is grouped | grouping tests + live smoke | implemented first slice |
| G8: deep resources available without default bloat | Skill author | Deep resources do not bloat default briefing | docs review | implemented |
| G9: intuitive awareness organ | Any agent using skill/CLI | Awareness organ map is available to agents | docs review + future `attend --explain-organ` snapshot | implemented first slice |
| G10: drive, creativity, and collective identity without persona bloat | Several agents sharing a workspace | Drive state is useful but not a persona; Resource leads reduce uncertainty | docs review + attend snapshots + memory trust gate | partial: derived drive state shipped; trust gate remains |
| Research addendum: selective retrieval | Agent starting work | Retrieval is selective | attend snapshot + irrelevant-retrieval fixture | implemented first slice |
| Research addendum: memory trust | Future agent | Durable memory is gated | trust-gate fixture + docs review | pending |
