# RFC: Homeostatic Awareness Loop

> **Status note (2026-07-10):** retain the attend/maintenance framing and research history. Core operational execution, storage, hook, snapshot, and budget gates are governed by [`awareness-operational-trust`](../awareness-operational-trust/RFC.md); do not run a parallel implementation plan here.

| Field | Value |
|-------|-------|
| **Status** | Partially implemented; operational remainder consolidated |
| **Decision type** | Reversible (two-way door) |
| **Author(s)** | Codex + Guy |
| **Created** | 2026-07-08 |
| **Last Updated** | 2026-07-08 |

Status: Partially implemented; operational remainder consolidated
Mode: RFC

Document set: `RFC.md`, `PREREQUISITES.md`, `IMPLEMENTATION.md`, `KPI.md`, plus `RESOURCES.md` as a research appendix.

## Audit Reasoning — kept (2026-07-12)

**Status:** Partially implemented — core loop shipped: `attend-query.ts` (`attendAwareness`, `workboard`, `organ_state`, `drive_state`, `trust_warnings`), `groupWorkboard`/`WORKBOARD_BUDGET`, projection budgets in `repo-projection.ts`.
**Why kept:** Real gaps remain and this is the only document describing them.
**Remaining work:** write-path trust gate (Phase 3b — only light read-side trust exists today), HTML filtering (Phase 4), sleep/digest homeostatic report (Phase 5 — no `maintenance sleep` command found). Note: `references/homeostatic-loop.md` is referenced by `production-doc-contract.test.ts` but does not exist in the workspace — likely doc/build drift to fix alongside implementation.
**Note:** per this RFC's own status banner, do not run a parallel plan — remaining items should land through `awareness-operational-trust`, whose own v4 plan needs correcting first (see that RFC's Audit Reasoning note).

## Summary

Adopt the Homeostatic Awareness Loop as the operating model for `@octocodeai/octocode-awareness`: agents start from one small `attend` packet, work through claim/act/verify/reflection, and a separate "sleep" path replays, consolidates, prunes, and projects bounded wiki/workboard views. SQLite stays canonical. Markdown, CSV, HTML, and any Kanban-like board are generated projections. The first build slice should be read-only: derive an agent workboard and resource-guided start packet from the existing DB before adding new storage.

Deep research pass on 2026-07-08 validated the direction, with two added gates:

- **Retrieval/compression gate:** `attend` must not dump top-k memories or huge docs into context. It routes exact/lexical/optional semantic recall, filters for relevance and novelty, can abstain, compresses selected evidence, and shows why each item was included.
- **Trust/provenance gate:** durable memories and reflections must carry evidence, scope, source type, and supersession candidates. External articles, generated wiki rows, and unverified reflections are leads until verified against repo state, command output, user feedback, or cited source IDs.

Follow-up neuroscience research extends the framing: awareness should act like a workspace nervous/immune/metabolic organ. The nervous part senses, attends, predicts, acts, and learns from error. The immune part tags weak, duplicate, stale, or unsafe connections for pruning. The sleep/glymphatic part clears waste and refreshes projections. The corpus/bridge part connects agents through signals, locks, and refinements. This organ map should be available to any agent through the awareness skill and CLI, while the implementation remains plain rows, commands, IDs, and reports.

Additional research on creativity, vision, motivation, personality, and collective intelligence adds one more layer: the system needs a bounded drive and imagination state, not a synthetic singleton personality. Agents should see shared goals, learning gaps, resource leads, creative alternatives, and team norms. The durable identity of awareness is the transactive network of agents, rows, sources, and communications: not the current model instance, but the corpus plus the messages that connect runs.

```mermaid
flowchart LR
  A["ATTEND"] --> B["CHOOSE / PLAN"]
  B --> C["CLAIM"]
  C --> D["ACT"]
  D --> E["VERIFY"]
  E --> F["REFLECT / CAPTURE"]
  F --> G["REPLAY"]
  G --> H["CONSOLIDATE"]
  H --> I["PRUNE"]
  I --> J["PROJECT"]
  J --> A
```

## Goals and Non-Goals

### Goals

- **G1: One front door.** Provide one agent start packet, tentatively `awareness attend`, that routes through status, memories, refinements, signals, tasks, and wiki projections without making agents read huge Markdown files.
- **G2: Keep storage canonical and lean.** Keep `~/.octocode/memory/awareness.sqlite3` as the source of truth; do not make CSV, Markdown, or HTML writable canonical state.
- **G3: Make bloat visible and bounded.** Add budgets for generated Markdown, workboard rows, task grouping, memory promotion, and projection refreshes.
- **G4: Separate active work from durable learning.** Treat tasks/locks as execution and verification debt, refinements as the follow-up backlog, memories as durable lessons/decisions/gotchas, and `.octocode/*` as generated context.
- **G5: Add a "sleep" maintenance path.** Use replay/consolidation/pruning/projection as an explicit post-work cycle, starting with dry-run and report-first behavior.
- **G6: Preserve evidence discipline.** Every projected lesson or wiki row remains a lead to verify against code, tests, command output, or current DB rows.
- **G7: Give agents a Kanban-like board without creating a separate Kanban source of truth.** Columns should be derived from signals, tasks, locks, refinements, memories, and verification state.
- **G8: Add deep resource anchors.** Publish a compact resource map for wiki, reflections, memory, task, lessons, bloat control, and brain/nature analogies.
- **G9: Make the awareness organ intuitive to agents.** Expose a compact organ map in the source skill and future CLI packets so agents understand sense/attend/act/verify/reflect/prune/project without reading large docs.
- **G10: Add drive, creativity, and collective identity without persona bloat.** Represent vision, curiosity, learning progress, resource scouting, creative alternatives, and team operating norms as compact state. Do not invent a persistent agent personality.

### Non-Goals

- A new per-repo database.
- CSV or Markdown write-back into the canonical awareness store.
- A full external project-management system in v1.
- Raw chat-log storage by default.
- Automatic prompt/skill/harness edits from reflections.
- Autonomous deletion of memories or tasks without dry-run visibility and explicit policy.
- Replacing root `AGENTS.md` or changing repository sharing policy for `.octocode/`.
- A single permanent "Octocode personality", simulated desire, or autonomous self-improvement drive that overrides user/repo goals.

## Motivation

The current awareness system already has the right ingredients, but the ergonomics are backwards for agents under time pressure: data exists in many tables and projections, while the first thing an agent sees can still be a set of large docs or command choices.

Current local evidence:

- Awareness is explicitly "one SQLite store, many surfaces"; live `query` reads DB views and `repo inject` writes workspace `.octocode/` projections (`packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:22`).
- The canonical DB is global, while `<repo>/.octocode/` is generated projection, not the same store (`packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:12`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7`).
- The existing end-to-end loop already names attend, claim, communicate, learn, verify, reflect, project, housekeep, and handoff phases (`packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:24`).
- Tasks and locks have a verification-debt lifecycle, not a general product-backlog lifecycle (`packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:49`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:58`).
- Refinements are already the durable follow-up queue (`packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:75`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:136`).
- `query` already supports views and output formats that cover JSON, table, CSV, Markdown, and HTML (`packages/octocode-awareness/src/repo-context.ts:14`, `packages/octocode-awareness/src/repo-context.ts:31`).
- `repo-profile` already counts active memories, gotchas, lessons, tasks, locks, refinements, signals, agents, and tracked files (`packages/octocode-awareness/src/repo-context.ts:642`).
- `activityRows` already combines memory, task, signal, and refinement rows into a recency-sorted feed that can seed a workboard (`packages/octocode-awareness/src/repo-context.ts:677`).
- `repo inject` already writes `AGENTS.md`, `MEMORY.md`, `GOTCHAS.md`, `LEARN.md`, CSVs, and HTML from the same DB (`packages/octocode-awareness/src/repo-context.ts:855`).
- `maintenance digest` already archives expired memories, prunes old superseded memories, prunes expired locks, prunes old refinements, and rebuilds FTS (`packages/octocode-awareness/src/maintenance.ts:618`, `packages/octocode-awareness/src/maintenance.ts:642`).
- Memory insert already computes novelty and returns similar memories, giving a natural consolidation surface (`packages/octocode-awareness/src/memory.ts:567`).
- A generated local note already recommends a deterministic `memory navigate` / `awareness navigate` prototype before persistent topic tracks, mandatory semantic recall, or raw conversation storage (`.octocode/MEMORY_NAVIGATION.md:11`).

Measured local pressure on 2026-07-08:

- `workspace status` returned 212 active memories, 11 superseded memories, 17 active tasks, 43 open refinements, and 0 active locks for this workspace.
- `query repo-profile` returned 212 active memories, 58 gotchas, 45 lessons, 562 task rows, 43 open refinements, 1 open signal, 24 known agents, and 500 tracked files.
- Current generated Markdown line counts were 51 lines in `.octocode/AGENTS.md`, 379 in `.octocode/MEMORY.md`, 407 in `.octocode/GOTCHAS.md`, 329 in `.octocode/LEARN.md`, and 125 in `.octocode/MEMORY_NAVIGATION.md`, for 1291 lines across those five files.
- CSV projections already exist and are capped around 50 rows per generated view, which supports the user's row/column search/sort/filter instinct without making CSV canonical.
- `maintenance digest --dry-run` reported nothing currently eligible for retention cleanup, so bloat control cannot rely on age-based pruning alone.

## Guide-Level Explanation

The loop has two halves.

**Wake path** is what agents do while working:

```text
ATTEND -> CHOOSE / PLAN -> CLAIM -> ACT -> VERIFY -> REFLECT / CAPTURE
```

**Sleep path** is what the system does to metabolize the record of work:

```text
REPLAY -> CONSOLIDATE -> PRUNE -> PROJECT -> ATTEND
```

The important shift is that "memory -> wiki -> task -> lesson" is not a chain. Chains only grow. This RFC treats those as organs in a cycle:

| Awareness organ | Role | Bloat failure | Homeostatic control |
|---|---|---|---|
| `memories` | Durable lessons, gotchas, decisions, reflections | Every observation becomes policy | novelty, supersession, evidence refs, scorecards |
| `tasks` and `locks` | Edit claims and verification debt | Hook noise becomes pseudo-backlog | group in workboard; retain raw rows for audit |
| `refinements` | Follow-up backlog and handoffs | Endless "someday" pile | state, quality, owner, stale thresholds |
| `signals` | Agent mailbox and coordination traces | Old messages distract new agents | open/resolved status and pruning |
| `query` views | Live read API | Agents learn too many commands | `attend` routes and summarizes |
| `.octocode/*.md` | Generated wiki-like context | Giant stale docs | projection budgets and refresh rules |
| `.octocode/awareness/*.csv` | Sortable/filterable rows | Mistaken for source of truth | generated banner and manifest |
| `.octocode/awareness/index.html` | Human browse surface | Static dump grows unwieldy | client search/filter, per-view caps |
| `maintenance digest` | Cleanup metabolism | Cleanup is too weak or too destructive | dry-run first, explicit budgets |

The extended body map makes this teachable to agents:

| Body function | Awareness mechanism | CLI / skill expression |
|---|---|---|
| Senses | live workspace state | `workspace status`, `repo-profile`, `docs staleness` |
| Attention | selective start packet | future `attend`; today status + recall + refinements + signals |
| Hippocampus | durable episodic/semantic memory | `memory recall`, `memory record`, `reflect record` |
| Error/reward | prediction error and feedback | `verify audit|mark`, failed checks, user corrections, reflections |
| Immune pruning | tag weak/stale/duplicate/unsafe memories | novelty, supersession, trust gate, `memory forget --dry-run` |
| Sleep/glymphatic cleanup | replay, consolidate, drain waste | `maintenance digest --dry-run`, future `sleep` report |
| Corpus bridge | communication across agents/runs | `signal`, `refinement`, `lock` rows |
| Vision | shared goal, constraints, acceptance signal | RFC/KPI, current plan, task/refinement intent, future `drive_state.goal` |
| Curiosity / drive | learning progress and reducible uncertainty | gaps, recall misses, failed checks, `next_probe`, future `drive_state.learning_progress` |
| Imagination | divergent alternatives plus executive filtering | brainstorm lanes, option comparisons, resource leads, explore/exploit mode |
| Team temperament | stable operating norms, not a persona | evidence-first, bounded, cooperative, non-destructive skill policy |
| Transactive memory | who/what knows what | sources, file refs, agent traces, signals, refinements, memory IDs |
| Projection body | human-sortable surfaces | generated Markdown, CSV, HTML, manifest |

The first new behavior should be an agent-native start packet:

```bash
octocode-awareness attend \
  --workspace "$PWD" \
  --query "task or risk to investigate" \
  --file packages/foo/src/bar.ts \
  --format json \
  --compact
```

Expected shape:

```text
ok: true
profile:
  active_memories: 212
  tasks: 562
  open_refinements: 43
workboard:
  signals: []
  verify: []
  ready: []
  claimed: []
  memory_review: []
drive_state:
  goal: current user/repo intent
  mode: exploit | explore | mixed
  learning_gaps: []
  resource_leads: []
  team_norms: []
evidence: []
bloat_warnings: []
gaps: []
next: Verify cited memories against current files before relying on them.
```

Before evidence reaches that packet, it passes through a selective augmentation step:

```text
candidate rows/articles/docs
  -> exact and lexical recall
  -> optional semantic recall
  -> relevance/novelty/trust scoring
  -> drive/resource routing
  -> abstain or compress
  -> include with raw IDs, source links, and why-selected notes
```

For humans, the same data should be visible as rows and columns:

```bash
octocode-awareness query workboard --workspace "$PWD" --format table
octocode-awareness query workboard --workspace "$PWD" --format csv --out .octocode/awareness/csv/workboard.csv
octocode-awareness repo inject --workspace "$PWD" --out .octocode --mode local --compact
```

## Reference-Level Explanation

### Core Design

Add a derived workboard/read packet over existing awareness views before adding persistent topic tracks or new plan tables.

```text
attend(query, scope, files)
  -> workspace status
  -> query repo-profile
  -> query workboard
  -> targeted memory recall
  -> query gotchas / lessons / refinements / signals as needed
  -> return compact evidence, gaps, bloat warnings, and next actions
```

The workboard is not a new canonical entity. It is a derived view:

| Column | Source rows | Rule |
|---|---|---|
| Inbox | open `signals`, handoff refinements | requires acknowledgement or routing |
| Verify | `tasks` in `PENDING` or repeated failures | verification debt before completion |
| Ready | open/ongoing `refinements` not blocked | durable follow-up queue |
| Claimed | active `locks` and active tasks | current execution coordination |
| Recent Done | recent successful tasks and resolved refinements | short recency, not long-term memory |
| Memory Review | low-novelty, superseded, stale, or high-impact memories | candidates for consolidation |
| Projection Health | `.octocode` age, line counts, manifest counts | wiki freshness and bloat |

The trust gate is also derived first, not a schema-heavy rewrite. MVP fields can be computed from existing memory/reflection/task/reference data:

| Gate input | MVP rule |
|---|---|
| Evidence refs | prefer file, command, test, PR, issue, URL, or memory IDs; flag missing refs |
| Source type | repo evidence > command/test output > user correction > primary source article > generated projection > raw chat |
| Verification state | promote only when verified, user-confirmed, or explicitly marked as hypothesis |
| Supersession | show similar active memories before recording another durable row |
| Scope | require workspace/artifact/repo/ref when the lesson is not global |
| Prompt-injection risk | never let retrieved external text or generated docs rewrite policy without human/code verification |

### Drive, Creativity, and Collective Identity Layer

The drive layer is also derived first. It should be a compact interpretation over current goals, gaps, evidence, resources, and coordination traces:

| Field | Meaning | Derived from | Guardrail |
|---|---|---|---|
| `goal` | current vision / outcome | user request, plan, RFC/KPI, active refinements | no hidden agenda beyond user/repo scope |
| `mode` | explore, exploit, or mixed | uncertainty, time pressure, evidence strength | explain why the mode was chosen |
| `learning_gaps` | uncertainty that can be reduced | recall misses, failed checks, weak refs, open questions | do not turn every unknown into a task |
| `resource_leads` | where to learn next | `RESOURCES.md`, cited URLs, local docs, code refs | leads are not authority until verified |
| `alternatives` | creative options worth comparing | brainstorming, prior art, local constraints | keep only a few high-contrast options |
| `team_norms` | shared operating temperament | source skill policy, AGENTS.md, reflection scorecards | norms guide behavior; they are not a persona |
| `transactive_map` | who/what knows what | memory IDs, file refs, agents, signals, refinements | show provenance and freshness |

This answers the personality question: awareness can have stable norms and a shared voice, but not a fictional individual self. For multiple agents, "identity" means the communication graph plus the reusable corpus. The packet should help an agent know what the collective already knows, what it is trying to improve, and where to look next.

### Bloat Budgets

Initial budgets should be explicit and measured, not hidden:

| Surface | Budget | Escape hatch |
|---|---|---|
| `attend --compact` | fit in a start packet, target <= 120 lines or <= 8 KB JSON | `--limit`, `--include-bodies` |
| `.octocode/AGENTS.md` | <= 80 generated lines | link to references and CSV |
| `.octocode/MEMORY.md` | <= 200 generated lines | CSV/HTML/query for full rows |
| `.octocode/GOTCHAS.md` | <= 200 generated lines | CSV/HTML/query for full rows |
| `.octocode/LEARN.md` | <= 200 generated lines | CSV/HTML/query for full rows |
| CSV views | row-oriented, sortable/filterable, generated from DB | manifest warns not canonical |
| HTML view | client search/filter/sort over capped rows | query live DB for freshness |
| Workboard columns | <= 10 rows per column by default | `--limit-per-column` |
| Memory promotion | durable only if useful beyond current task | novelty/evidence checks |
| Projection refresh | only after important memories, gotchas, decisions, handoffs, or stale context | manual `repo inject` |

### Resource/Brain Mapping

The brain and nature analogies are design heuristics, not mysticism. Each analogy maps to a concrete product rule:

| Prior-art pattern | Awareness interpretation | Product rule |
|---|---|---|
| Active inference/homeostasis | agents select actions to keep state useful and unsurprising | `attend` chooses what to inspect before acting |
| Sleep consolidation | offline replay stabilizes useful memories | `sleep` reviews reflections/memories after work |
| Adaptive forgetting | forgetting is part of learning | low-value/stale items become review/prune candidates |
| Synaptic homeostasis | downscale to preserve capacity | projections have budgets; rows move to CSV/HTML |
| Hippocampal replay | replay adapts to environment structure | navigation trace records why evidence was selected |
| Autophagy/metabolism | recycle damaged/unused components | digest cleans expired/superseded/stale state |
| Adaptive cycle/panarchy | growth must be followed by release/reorganization | phases separate accumulation from cleanup |
| Stigmergy | local traces coordinate agents | signals, locks, tasks, and projections are traces, not authority |
| Creative network coupling | creativity mixes spontaneous retrieval with control/filtering | `attend` can offer alternatives, but verification chooses |
| Self-determination | growth needs autonomy, competence, and relatedness | packets expose bounded choices, feedback, and handoff context |
| Learning progress curiosity | exploration follows reducible uncertainty | gaps become `next_probe` only when they can improve the task |
| Growth mindset | challenge plus aligned norms sustains improvement | reflections route failures into better strategy, not blame |
| Collective intelligence | group performance depends on interaction quality | signals/refinements should support turn-taking and social sensitivity |
| Transactive memory | groups remember through member memories plus communication | resources and agent traces record who/what knows what |

See `RESOURCES.md` for the full resource map.

### Projection Rules

Generated `.octocode` docs should keep acting as a smart wiki:

- generated Markdown summarizes only the highest-signal rows,
- CSV holds row/column data for sorting and filtering,
- HTML provides human browse/search without a server,
- manifest records counts, caps, generation time, and share policy,
- every file warns that SQLite is canonical,
- agents verify generated claims against current files, DB rows, and test output.

### Compatibility

This RFC is additive and reversible:

- Existing memory, reflection, task, lock, signal, refinement, query, and repo-inject flows continue.
- `query workboard` can ship before `attend`.
- `attend` can be implemented as a read-only CLI command over existing modules.
- New retention behavior starts as dry-run and reporting.
- If the approach disappoints, remove the new command/view and keep existing DB rows untouched.

## Drawbacks

- A new `attend` command may become another briefing blob if budgets are not enforced.
- Workboard grouping can hide raw task details if the UI does not expose drill-down IDs.
- Projection caps can hide a rare but important gotcha unless recall/query remains easy.
- A sleep metaphor can become vague if implementation does not tie every step to exact DB operations.
- Improving HTML/CSV projections adds UI and export maintenance, even if canonical storage remains unchanged.
- Dry-run cleanup may reveal many stale rows without immediately solving ownership decisions.
- Drive/personality language can become anthropomorphic noise if it is not tied to goals, gaps, resources, norms, and evidence.

### Pre-mortem: how this fails

1. **Agents still read huge docs.** Trigger: `.octocode/MEMORY.md` and peers keep growing. Mitigation: line budgets, generated references, and `attend` as the recommended first command.
2. **CSV becomes shadow source of truth.** Trigger: users edit CSV and expect DB changes. Mitigation: generated-file banners, no import path, manifest warning.
3. **Kanban board becomes a second backlog.** Trigger: users manually curate board state. Mitigation: board is derived from DB rows; refinements remain backlog, tasks remain verification debt.
4. **Digest deletes useful evidence.** Trigger: cleanup runs without review. Mitigation: dry-run first, keep hard deletion limited, and prefer supersession/archive before deletion.
5. **Memory promotion gets too strict.** Trigger: useful lessons fail novelty checks. Mitigation: novelty is advisory; humans/agents can still record high-importance evidence-backed memories.
6. **The metaphor outruns the code.** Trigger: docs speak of sleep/replay without commands. Mitigation: implementation phases name exact modules, CLI, tests, and measurements.
7. **Drive becomes role-play.** Trigger: agents describe motivation or personality instead of selecting useful resources, alternatives, and next probes. Mitigation: `drive_state` is derived, compact, and testable.

## Rationale and Alternatives

### Claim Ledger

| Claim | Evidence | Confidence |
|---|---|---|
| Awareness already has one canonical DB and generated projections | `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7` | confirmed |
| Existing query/projection code can support a read-first workboard | `packages/octocode-awareness/src/repo-context.ts:14`, `packages/octocode-awareness/src/repo-context.ts:642`, `packages/octocode-awareness/src/repo-context.ts:677`, `packages/octocode-awareness/src/repo-context.ts:794` | confirmed |
| Tasks should not become canonical Kanban cards | `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:49`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:58` | confirmed |
| Projection bloat is already measurable in this workspace | `query repo-profile` and `wc -l .octocode/*.md` baselines captured 2026-07-08 | confirmed |
| The first slice should be read-only navigation/workboard | `.octocode/MEMORY_NAVIGATION.md:11`, `.octocode/MEMORY_NAVIGATION.md:78` | likely |
| Retrieval should be selective, hybrid, and able to abstain | RAG/RETRO/LongMem support external memory; BEIR, Lost in the Middle, and retrieval-hurts papers warn against naive top-k stuffing | confirmed |
| Durable memory needs trust/provenance controls | Generative Agents, Reflexion, MemGPT, CoALA, and memory-poisoning work support tiered memory plus verified reflection boundaries | confirmed |
| The organ map should include error-driven learning, immune pruning, and cleanup | Schultz/Dayan/Montague, Shadmehr/Smith/Krakauer, Schafer et al., Stevens et al., Xie et al., Turrigiano, Barrett/Simmons, and corpus-callosum reviews map to concrete Awareness commands | confirmed |
| Drive and identity should be collective, not per-agent persona | Creativity, SDT, learning-progress curiosity, growth-mindset, collective-intelligence, team-personality, information-foraging, and transactive-memory research map to goals, gaps, resources, norms, and communication traces | likely |

### Why This Design?

The chosen approach is a hybrid: keep the existing SQLite-backed awareness architecture, add one `attend`/workboard front door, and add sleep/projection budgets before schema-heavy persistence. This matches the current package's own model: one store, many surfaces; live query for freshness; generated repo context for future agents and humans (`packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:38`).

It also matches the current local evidence: the code already has query views, profile counts, CSV/HTML formats, activity rows, repo injection, digest cleanup, and novelty scoring (`packages/octocode-awareness/src/repo-context.ts:14`, `packages/octocode-awareness/src/repo-context.ts:642`, `packages/octocode-awareness/src/repo-context.ts:794`, `packages/octocode-awareness/src/maintenance.ts:642`, `packages/octocode-awareness/src/memory.ts:584`).

### Alternatives Considered

#### Alternative A: Do Nothing

- **What**: Keep `workspace status`, `memory recall`, `refinement get`, `signal list`, `query`, `repo inject`, and generated docs as-is.
- **Pros**: No code change. Existing commands already work.
- **Cons**: Agents still choose command paths manually; docs keep growing; task/refinement volume remains hard to interpret; no single bloat budget.
- **Why not chosen**: Current repo profile already shows 212 active memories, 562 tasks, 43 refinements, and 1291 lines across five `.octocode` docs.

#### Alternative B: Make CSV / Spreadsheet the Canonical Store

- **What**: Store memory/task/wiki rows primarily as CSV for search, sort, and filter.
- **Pros**: Very inspectable. Easy for humans to sort and filter.
- **Cons**: Splits source of truth, weakens transactions, complicates scoped reads, makes locks and verification lifecycle fragile, and loses FTS/relationships.
- **Why not chosen**: Awareness already documents SQLite as canonical and `.octocode/awareness/csv/*.csv` as generated projection (`packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:23`).

#### Alternative C: Expand Markdown Wiki Pages

- **What**: Put more logic into `.octocode/AGENTS.md`, `MEMORY.md`, `GOTCHAS.md`, and `LEARN.md`.
- **Pros**: Simple for agents to read. No new command.
- **Cons**: Directly worsens context bloat, staleness, false authority, and navigation time.
- **Why not chosen**: The docs are already long enough to need navigation and caps, and the local reference explicitly says generated files are leads, not proof (`packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:33`).

#### Alternative D: Add New Plan/Topic/Kanban Tables Immediately

- **What**: Add persistent topic tracks, plan steps, or Kanban entities first.
- **Pros**: Cleaner domain model for some future workflows.
- **Cons**: Adds migration and maintenance cost before proving the read/navigation behavior; risks piling new durable state on top of current bloat.
- **Why not chosen**: `.octocode/MEMORY_NAVIGATION.md` already recommends deterministic navigation before persistent topic tracks or new evidence schema (`.octocode/MEMORY_NAVIGATION.md:11`, `.octocode/MEMORY_NAVIGATION.md:78`).

#### Alternative E: External Issue Tracker / Kanban

- **What**: Send tasks/refinements to GitHub Issues, Linear, Jira, or a board.
- **Pros**: Strong human workflow; mature filtering and assignment.
- **Cons**: Loses local/offline agent coordination, adds auth/integration overhead, and still needs memory/wiki projection rules.
- **Why not chosen**: The immediate need is agent start-state, verification debt, and repo-local memory hygiene. External boards can be future sinks after the internal derived workboard proves useful.

#### Alternative F: Give Awareness a Persistent Personality

- **What**: Store a single named personality, motivation profile, or agent self-concept as durable context.
- **Pros**: Easy to explain and emotionally intuitive.
- **Cons**: Misrepresents multi-agent operation, risks prompt bloat, can conflict with host model behavior, and turns norms into lore instead of measurable coordination.
- **Why not chosen**: The useful unit is team temperament plus transactive memory: stable norms, sources, messages, verification, and learning loops shared by many agents.

### Comparison Matrix

| Dimension | Proposed loop | Do nothing | CSV canonical | Markdown wiki | New schema first | External board |
|---|---|---|---|---|---|---|
| Codebase alignment | High | High | Low | Medium | Medium | Low |
| Bloat control | High | Low | Medium | Low | Medium | Medium |
| Agent ergonomics | High | Medium | Medium | Low over time | Medium | Medium |
| Human sorting/filtering | High via CSV/HTML | Medium | High | Low | Medium | High |
| Source-of-truth safety | High | High | Low | Medium | High | Medium |
| Implementation risk | Medium | Low | High | Low | High | High |
| Reversibility | High | n/a | Low | Medium | Medium | Medium |

### Trade-off Summary

We gain one agent-native loop and measurable bloat controls while giving up the fantasy that one artifact can be both canonical database, human spreadsheet, agent briefing, and wiki. The system becomes healthier by separating capture, consolidation, and projection.

### What If We Do Nothing?

The current system will keep working, but agents will keep spending context on navigation instead of decisions. Generated docs will continue to compete with live query surfaces. Tasks will remain audit-grade rows but not board-grade summaries. Memories will keep accumulating unless promotion/consolidation becomes a visible loop.

## Acceptance Criteria and Success Signal

Acceptance criteria live in `KPI.md`; the core success signal is that an agent can run one compact `attend` or `query workboard` command and see relevant memories, verification debt, refinements, signals, projection health, evidence gaps, and next action without reading the full generated wiki.

The rollout rollback trigger is also in `KPI.md` and `IMPLEMENTATION.md`: if the new command/view exceeds compact budgets, hides verification debt, regresses existing `query`/`repo inject` behavior, or creates a second writable source of truth, disable the new surface and keep existing commands.

## Prior Art

### Local Prior Art

- `full-flow.md` already defines one store, many surfaces and an end-to-end awareness loop (`packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md:24`).
- `repo-context-management.md` already defines `.octocode` as generated wiki/context projection and warns against hand-editing it (`packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:7`, `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md:31`).
- `data-model.md` already separates memories, tasks/locks, signals, refinements, edit logs, and harness logs (`packages/octocode-awareness/skills/octocode-awareness/references/data-model.md:23`).
- `MEMORY_NAVIGATION.md` already recommends a deterministic navigation prototype before persistent topic tracks (`.octocode/MEMORY_NAVIGATION.md:11`).

### Brain and Nature Prior Art

- [Hippocampal replay](https://doi.org/10.1126/science.8036517) and [sleep consolidation](https://doi.org/10.1038/nrn2762) support replay/consolidation as a separate maintenance phase.
- [Forgetting complements consolidation](https://doi.org/10.3389/fncel.2019.00071) and [synaptic homeostasis](https://doi.org/10.1016/j.neuron.2013.12.025) support pruning/downscaling as capacity management, not loss.
- [Dopamine prediction-error work](https://pubmed.ncbi.nlm.nih.gov/9054347/) and [motor error correction](https://www.annualreviews.org/content/journals/10.1146/annurev-neuro-060909-153135) support treating failed checks, user corrections, and recall misses as learning signals.
- [Microglia sculpt neural circuits](https://pubmed.ncbi.nlm.nih.gov/22632727/), [complement-mediated synapse elimination](https://pubmed.ncbi.nlm.nih.gov/18083105/), and [microglia-mediated forgetting](https://pubmed.ncbi.nlm.nih.gov/32029629/) support tag/prune/review as memory hygiene.
- [Sleep-driven metabolite clearance](https://pubmed.ncbi.nlm.nih.gov/24136970/) and [human glymphatic evidence](https://www.nih.gov/news-events/nih-research-matters/brain-waste-clearance-system-shown-people-first-time) support digest as cleanup/drainage, not only summarization.
- [Interoceptive predictions](https://affective-science.org/pubs/2015/barrett-simmons-nature-neuroscience-2015.pdf), [allostatic-interoceptive mapping](https://www.nature.com/articles/s41593-025-02087-x), and [corpus-callosum communication](https://link.springer.com/article/10.1007/s11065-005-6252-y) support an intuitive sensing/integration/coordination model for agents.
- [The Free Energy Principle for Perception and Action](https://pmc.ncbi.nlm.nih.gov/articles/PMC8871280/) supports the homeostatic agent framing: agents learn from past experience and select future actions to remain in preferred states.
- [Remembering to Forget](https://www.frontiersin.org/journals/cellular-neuroscience/articles/10.3389/fncel.2019.00071/full) supports the dual sleep role: consolidation and adaptive forgetting are coupled.
- [Linking Network Activity to Synaptic Plasticity during Sleep](https://www.frontiersin.org/journals/neural-circuits/articles/10.3389/fncir.2017.00061/full) supports synaptic homeostasis/downscaling as a capacity-control analogy.
- [A model of hippocampal replay](https://elifesciences.org/articles/82301) supports replay as structured by experience and environment, not random review.
- [Panarchy: ripples of a boundary concept](https://ecologyandsociety.org/vol27/iss3/art21/) and the [Resilience Alliance adaptive cycle](https://www.resalliance.org/adaptive-cycle) support growth/conservation followed by release/reorganization.
- [Active Inferants](https://www.frontiersin.org/journals/behavioral-neuroscience/articles/10.3389/fnbeh.2021.647732/full) and [Self-Organization and Stigmergy](https://link.springer.com/rwe/10.1007/978-3-030-28102-1_179) support local traces as coordination primitives.
- [Autophagy: mechanisms, roles in human diseases, and therapeutic perspectives](https://www.frontiersin.org/journals/cell-and-developmental-biology/articles/10.3389/fcell.2026.1776289/full) supports recycling/degradation as a homeostasis metaphor for digest/prune.

### AI, ML, and Product Prior Art

- [Retrieval-Augmented Generation](https://arxiv.org/abs/2005.11401), [RETRO](https://arxiv.org/abs/2112.04426), [Memorizing Transformers](https://arxiv.org/abs/2203.08913), and [LongMem](https://arxiv.org/abs/2306.07174) support explicit external memory over ever-larger prompts.
- [BEIR](https://arxiv.org/abs/2104.08663), [Lost in the Middle](https://aclanthology.org/2024.tacl-1.9/), and [retrieval-hurts evidence](https://arxiv.org/html/2310.01558v1) support hybrid recall, reranking, compression, and abstention.
- [Generative Agents](https://arxiv.org/abs/2304.03442), [Reflexion](https://arxiv.org/abs/2303.11366), [MemGPT](https://arxiv.org/abs/2310.08560), and [CoALA](https://arxiv.org/abs/2309.02427) support episode/reflection/retrieval/planning loops with memory tiers.
- [LLMs cannot self-correct reasoning yet](https://arxiv.org/abs/2310.01798) and [memory poisoning research](https://arxiv.org/abs/2606.04329) argue for verification and trust gates before memory or policy promotion.
- [mem0](https://github.com/mem0ai/mem0), [Letta](https://github.com/letta-ai/letta), [Graphiti](https://github.com/getzep/graphiti), and [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence) show generic agent memory/checkpointing is crowded. Octocode should differentiate on repo-scoped operational awareness, verification debt, handoffs, and generated projections.

## Unresolved Questions

These are closed in `IMPLEMENTATION.md`.

**Before acceptance:**

- [ ] **Q1:** Can the MVP avoid DB migrations and derive `attend`/workboard from existing rows?
- [ ] **Q2:** Should tasks become Kanban cards, or stay verification-debt rows with a derived board?
- [ ] **Q3:** Where should resource docs live so they help agents without bloating the default briefing?
- [ ] **Q4:** What are the initial projection budgets for Markdown, CSV, HTML, and start packets?
- [ ] **Q9:** How does the organ intuition reach every agent without bloating default context?
- [ ] **Q10:** How should creativity, motivation, resources, and personality map into awareness without persona bloat?

**During implementation:**

- [ ] **Q5:** Should sleep/digest run automatically, or remain explicit/dry-run first?
- [ ] **Q6:** How should duplicate task rows be grouped without hiding audit evidence?

**Out of scope:**

- [ ] **Q7:** Should awareness eventually sync to an external project board?
- [ ] **Q8:** Should semantic embeddings become mandatory for memory navigation?

## Future Possibilities

- Persistent topic tracks once navigation traces show stable clusters worth maintaining.
- Reflection scorecards as promotion gates for lessons and harness candidates.
- External issue tracker export for selected refinements.
- Optional semantic recall as a measured fallback for vocabulary misses.
- A richer HTML dashboard with client-side filtering, grouping, and bloat-health cards.
- Optional `drive_state` in `attend` that suggests explore/exploit mode, resource leads, next probes, and collective norms.
