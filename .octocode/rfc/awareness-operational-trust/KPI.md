# Success and Verification: Octocode Awareness Operational Trust

Scope authority: [RFC goals and non-goals](./RFC.md#goals-and-non-goals)

Implementation sequence: [IMPLEMENTATION.md](./IMPLEMENTATION.md)

## User Stories to Check

- **U1:** As an agent entering a workspace, I see exact, current, actor-relevant work and one safe next action.
- **U2:** As two agents editing one file, we see each other's reason without being forced into exclusivity.
- **U3:** As an agent touching sensitive files, I can make my Task/Work attempt exclusive without a separate lock lifecycle.
- **U4:** As a plan lead, I own durable plan docs/status while contributors atomically choose valid tasks.
- **U5:** As an agent finishing work, I record the result and test evidence once; no synthetic verification queue remains.
- **U6:** As an operator, I can diagnose schema/runtime/store identity and stale attempts without losing audit evidence.
- **U7:** As a maintainer, I change a route once and runtime, help, schemas, examples, hooks, and packages agree.
- **U8:** As an agent recalling existing knowledge after cutover, I get equivalent results and exact references without synthetic/test rows becoming more trusted or real knowledge disappearing.

## Acceptance Criteria

```gherkin
Feature: Truthful workspace state
  Scenario: More rows than a display cap
    Given 550 ready tasks in active plans
    When attend and workboard return one displayed row
    Then total_count is 550, returned_count is 1, omitted_count is 549, and exact is true

  Scenario: Stale attempt
    Given an expired active work attempt
    When the actor runs attend and doctor
    Then both identify the same run as stale and neither calls it successful

  Scenario: Actor-safe next action
    Given only another agent has stale work
    When the current agent runs attend
    Then next_action does not propose mutating the other agent's attempt
```

```gherkin
Feature: Work awareness before edit
  Scenario: Ordinary uncovered edit with stable goal
    Given a supported host session has no active Task or Work and has a stable current goal
    When pre-edit receives an ordinary file mutation under session-work policy
    Then one visible WORK/SESSION attempt is created and reused for the session
    And the file is attached with the session goal as rationale

  Scenario: Sensitive uncovered edit
    Given a supported host session has no explicit exclusive Task or Work
    When pre-edit receives a sensitive or self-modifying file mutation
    Then the mutation is blocked before the file changes
    And the response contains one exact compact remediation command

  Scenario: Declared edit
    Given the session has one active work attempt
    When pre-edit receives a new file mutation
    Then the file is attached as advisory presence with the attempt's rationale
    And post-edit appends one deduplicated EDIT activity event
```

```gherkin
Feature: Plan and task integrity
  Scenario Outline: Non-active plan blocks claims
    Given a plan is <status> with an open task
    When an agent lists ready tasks or claims the task
    Then the task is not ready and the claim is rejected
    Examples:
      | status    |
      | PAUSED    |
      | COMPLETED |
      | CANCELLED |

  Scenario: Complete plan with unfinished child
    Given an active plan has a child not DONE or CANCELLED
    When the lead completes the plan
    Then completion is rejected with child identifiers

  Scenario: Reopen failed work
    Given a failed task and its plan lead
    When the lead reopens it with a reason
    Then the task is OPEN and an immutable event records the reason
```

```gherkin
Feature: Advisory presence and optional exclusivity
  Scenario: Shared advisory file
    Given two sessions have active attempts on the same file
    When either views the workspace
    Then both agents and rationales are visible and neither attempt is rejected

  Scenario: Sensitive exclusive attempt
    Given one attempt holds an unexpired exclusive file lease
    When another session attempts that file
    Then pre-edit blocks with owner and expiry

  Scenario: Finish exclusive work
    Given an exclusive active attempt
    When its owner finishes with result and evidence
    Then run, file presence, exclusivity, activity event, and task state commit atomically
```

```gherkin
Feature: Evidence-bearing finish
  Scenario: Successful task
    Given an active task attempt and completed checks
    When its owner finishes with result SUCCESS, evidence, and evidence kind
    Then the run is SUCCESS, the task is DONE, and no pending verification row exists

  Scenario: Missing evidence
    Given an active attempt
    When finish omits result, evidence, or evidence kind
    Then it fails without changing run, file, or task state

  Scenario: Session dies
    Given a session ends with active work
    When shutdown reconciliation runs
    Then the run is ABANDONED, presence/exclusivity ends, and success is never inferred
```

```gherkin
Feature: Lossless memory cutover
  Scenario: Representative recall parity
    Given the sanitized migration corpus contains lexical, semantic, validity, failure-cluster, scoped, unreferenced, and embedded memories
    When the v3 and proposed v4 readers run the frozen query set
    Then IDs, expected hits, references, visibility, and scope decisions reconcile within the approved parity manifest

  Scenario: Unproven legacy memory
    Given a legacy ACTIVE memory has no resolvable evidence
    When import classifies it
    Then it does not become more trusted and does not silently disappear from the default migration-compatible recall path

  Scenario: Forget without ghosts
    Given a memory is eligible for explicit forget or retirement
    When the operation commits
    Then it is absent from FTS, projections, navigation, and delivery output
    And immutable operational evidence remains available
```

```gherkin
Feature: Final schema and local cutover
  Scenario: Fresh store
    Given an empty database
    When the final runtime opens it concurrently
    Then one exact v4 schema is created and every opener succeeds

  Scenario: Unsupported store
    Given any non-empty schema version other than v4 or a wrong application id
    When the runtime opens it
    Then it hard-errors before DDL or writes

  Scenario: Local v3 cutover
    Given the audited v3 store
    When the one-time cutover runs
    Then a consistent immutable archive exists
    And the approved memory fields, references, FTS entries, embeddings, visibility, and representative recall results reconcile
    And runtime debt is summarized but not imported or relabeled
    And foreign-key, integrity, schema-fingerprint, and recall checks pass before swap

  Scenario: Active/actionable state blocks cutover
    Given any live mutator, nonterminal plan/task/run, or unreviewed actionable signal/refinement exists
    When cutover is requested
    Then it refuses before archive swap and returns the exact disposition rows
```

```gherkin
Feature: Amendment 1 invariants
  Scenario: Resume an ended host conversation
    Given an ended internal session for a host session and scope
    When the host conversation resumes
    Then a new immutable internal session is created
    And two non-ended instances for the same host session and scope cannot coexist

  Scenario: Same relative plan directory in two workspaces
    Given two workspaces independently create the same relative plan directory
    When both plans persist
    Then both succeed and uniqueness remains scoped by workspace and artifact

  Scenario: Abandoned attempt has no result receipt
    Given an active attempt whose session ends or lease expires
    When reconciliation marks it ABANDONED
    Then result evidence and evidence kind are null
    And no live file presence or exclusivity remains

  Scenario: Cross-scope run is refused
    Given a session, task, and plan do not share agent, workspace, or artifact scope
    When a run transition is attempted
    Then the transaction fails without inserting or mutating lifecycle rows

  Scenario: Broadcast reads are independent
    Given one broadcast signal and two agents
    When the first agent reads it
    Then the signal remains visible and unread for the second agent
    And its audience remains BROADCAST

  Scenario: Empty snapshot lane with null artifact
    Given a workspace with null artifact and no rows in one lane
    When the snapshot is read
    Then the lane envelope returns empty rows and exact zero counts
    And every row/count query uses the same null-artifact scope
```

```gherkin
Feature: One public contract
  Scenario: Irrelevant flag
    Given a known flag invalid for a route
    When the route receives it
    Then it exits nonzero and help shows only valid flags

  Scenario: Removed command
    Given a v3 alias, lock, verify, refinement, or notification command
    When it is executed
    Then it fails with the compact final route inventory and no compatibility shim

  Scenario: Clean TypeScript package consumer
    Given the real Awareness tarball in an empty project without ancestor node_modules
    When its declared types entrypoint is resolved and a consumer compiles
    Then declaration emit and import succeed without workspace or file dependency protocols
```

## Definition of Done

- Required prerequisite gates are closed with evidence.
- Exact v4 DDL/fingerprint and lifecycle transition tables are tested.
- The one-time local cutover is completed or proven on an exact disposable copy before the canonical swap, with zero live mutators and zero unreviewed actionable rows.
- Every acceptance scenario has automated coverage plus packed-artifact journeys for public behavior.
- Package test, typecheck, build, isolated tarball tests, lint, and repository verification pass.
- Canonical skill and generated destinations have zero unexplained drift.
- Awareness and Pi tarballs contain one skill tree and resolve all runtime imports without workspace links.
- All docs/help/examples use only the final 37 public routes.
- Real tarballs contain the declared TypeScript entrypoints and a clean TS consumer compiles.
- Old migration/alias/refinement/verify/lock/fallback code and generated duplication are absent.
- Earlier overlapping RFCs contain clear supersession notes.

## Success Metrics

| Metric | Baseline | Ship target / guardrail | Window / sample | Source / owner |
| --- | ---: | ---: | --- | --- |
| Snapshot total accuracy | workboard fixed; repo-profile still caps at 500 | 100% identity/count equality at 0, 550, 10k, 100k across all primary views | every CI run | fixture/direct SQL · snapshot owner |
| Stale-attempt discoverability | expired WORK absent from attend | 100% identity-set equality between attend and doctor | every CI run | snapshot diff · snapshot owner |
| Cross-agent unsafe next actions | possible | 0 | actor matrix, every CI run | scenario tests · snapshot owner |
| Plan integrity violations | fixed in interim v3 | 0 | transition matrix, every CI run | invariant audit · lifecycle owner |
| Terminal residue | multiple lifecycle owners | 0 terminal runs with live presence/exclusivity | every finish/abandon property run | invariant audit · lifecycle owner |
| Sensitive undeclared edits | fallback currently permits advisory HOOK work | 100% blocked before mutation on supported hosts | shell/Pi parity, every CI run | host tests · hook owner |
| Ordinary unattributed edits | per-edit fallback lacks real task goal | 0 on supported hosts; cooperative hosts visibly diagnosed | shell/Pi parity, every CI run | host journeys · hook owner |
| Ordinary policy false blocks/bypass | not measured | 0 supported-host unattributed edits; 0 sensitive bypass; ≤5% ordinary false blocks; ≤5% abandoned session Work; no task-quality regression | ≥100 scripted + ≥20 dogfood journeys per policy across shell/Pi | strict/session experiment · hook owner |
| Synthetic fallback runs | 1,265 pending HOOK in workspace | 0 HOOK; run kinds TASK/WORK and sources EXPLICIT/SESSION | schema + host journeys, every CI run | schema/journey · hook owner |
| Finish command count | finish + verify/audit common | 1 evidence-bearing finish; standard journey ≤3 Awareness commands | ≥100 scripted journeys | usability suite · product owner |
| Named logical relations incl. FTS | 23 | 16 exact relations (15 tables + 1 virtual table), no dead application tables | every schema build/open | fingerprint test · storage owner |
| Public routes | 68 indexed | 37, all used and documented | every generated-contract build | route manifest · CLI owner |
| Route contract drift | accepted-unused flags; 32/68 help omissions | 0 accepted-unused/documented-rejected/schema mismatches | exhaustive route matrix, every CI run | parity test · CLI owner |
| Compatibility surface | aliases, replacement map, `--compat-coerce` | 0 | every release candidate | source/CLI scan · CLI owner |
| Initial instruction payload | old flow about 11.4 KB | lobby + compact attend ≤4 KB; lobby ≤3 KB | cold/warm, every release | byte/token fixture · skill owner |
| Compact attend | ~0.5 KB | p95 ≤2 KB | 0/10k/100k fixtures | benchmark · snapshot owner |
| Compact workboard | up to 3.9 KB at 550 tasks | p95 ≤8 KB | 0/10k/100k fixtures | benchmark · snapshot owner |
| Compact project result | 4.0–4.6 KB | p95 ≤1 KB | projection fixture, every release | benchmark · projection owner |
| Attend latency | ~70 ms at 550 tasks | p95 ≤100 ms at 10k; ≤250 ms at 100k | ≥30 runs per fixture | benchmark · snapshot owner |
| Exact-v4 warm DB open | v3 migration inspection/write every open | p95 ≤10 ms; no DDL/write | ≥100 warm opens per runtime | trace benchmark · storage owner |
| Local cutover disposition | currently 1 ACTIVE plan/task/run; 34 OPEN signals; 90 open/ongoing refinements | 0 live mutators and 0 unreviewed actionable rows at swap | immediately before swap | disposition manifest · plan lead |
| Local cutover reconciliation | not applicable | 100% approved memory fields/IDs/refs/FTS/embeddings and representative recall parity; 0 integrity/FK failures | disposable rehearsal + canonical swap | migration manifest · migration owner |
| Pi duplicated skill paths | original baseline 163 | 0 | every release candidate | tarball scan · release owner |
| Clean tarball install | Pi has two `workspace:*` runtime specs | 100% supported-runtime matrix; strict declaration emit; TS consumer passes | every release candidate | clean install · release owner |
| Memory recall preservation | no frozen representative corpus | freeze corpus/baselines first; no approved query loses required IDs/scope/refs/default visibility | before schema freeze and cutover | parity evaluator · memory owner |
| Memory forgetting ghosts | not measured | 0 FTS/projection/navigation/delivery ghosts; immutable operational evidence retained | every forget/retire test | no-ghost suite · memory owner |
| Raw/uncached context cost | old prescribed flow ~11.4 KB; current lobby 49 lines | lobby ≤3 KB; lobby + compact attend ≤4 KB; no hidden cache assumption | cold and warm runs, every release | byte/token fixture · skill owner |
| First-run completion | not measured | ≥95% without docs intervention | ≥100 scripted first-run journeys | usability suite · product owner |

Correctness and data-safety metrics are hard gates. Payload/latency are guardrails: a phase does not ship above budget without owner review.

## Verification Matrix

| Layer | Required coverage |
| --- | --- |
| Unit | exact count predicates, next-action policy, transition tables, route discrimination, memory migration/forget metadata |
| Property/invariant | one active run/session/task, terminal residue, count arithmetic, plan/task states, schema fingerprint |
| Integration | two-process claims/exclusivity, session identity, atomic finish/release, signal fan-out, activity event dedupe |
| Host parity | shell and Pi session work, sensitive refusal, attachment, heartbeat, post-edit event, shutdown ABANDONED |
| Performance | 10k/100k snapshot, exact-v4 opens, compact payload, projection subprocess count |
| Packaging | generated parity, duplicate scan, real `.tgz` install, public route journeys |
| Migration/recovery | WAL-safe archive, live/actionable refusal, failed cutover leaves canonical untouched, memory field/ref/FTS/embedding/recall parity, file-swap rollback |
| Usability | empty workspace, ready task, standalone work, shared advisory file, sensitive exclusive attempt |

## Decision Rule

- **Ship a phase** only when its traceability row is complete and no P0/P1 correctness, data-loss, identity, or package-resolution defect remains.
- **Hold** if views disagree, sensitive undeclared edits pass, the ordinary hook policy misses its guardrails, memory parity fails or import increases trust/hides knowledge, lifecycle can leave residue, wrong schemas are mutated, or tarballs cannot install.
- **Roll back before meaningful v4 writes** by atomically restoring the archived v3 store and old code.
- **Fix forward after meaningful v4 writes**; never downgrade/reopen v4 with v3.
- **Do not enable terminal hard deletion** in this RFC.

## Traceability Matrix

| RFC goal | User stories | Acceptance/metric | Implementation phase | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| R-A1 session instances | U1, U6 | resume-ended-session scenario | 0, 1, 4 | `v4-session` unit/integration + Pi/shell parity | blocked on Amendment TDD |
| R-A2 plan-document scope | U4 | two-workspace same-directory scenario | 0, 1 | schema/service invariant test | blocked on Amendment TDD |
| R-A3 run truth | U5, U6 | ABANDONED-null + cross-scope scenarios | 0, 1, 4 | property/concurrency tests | blocked on Amendment TDD |
| R-A4 signal audience | U1, U6 | independent broadcast-read scenario | 0, 1, 4 | signal fan-out integration | blocked on Amendment TDD |
| R-A5 memory preservation | U8 | parity/no-trust/no-ghost scenarios | 0, 2 | P6a corpus + P6b migration suite | blocked on P6a/P6b |
| R-A6 snapshot envelope | U1, U6 | empty/null-artifact + all-view count parity | 0, 3 | frozen response fixture/hash + 0/550/10k/100k tests | blocked on Amendment TDD |
| R-A7 journal policy | U6 | unsafe→DELETE, safe→WAL, doctor reports choice | 0, 6 | runtime classifier/matrix + doctor test | partial; classifier passes |
| G1 truthful state | U1, U6 | exact totals, stale identity | 3 | unit + integration + performance | pending |
| G2 useful next | U1 | actor-safe next | 3 | scenario matrix | pending |
| G3 coherent lifecycle | U3–U6 | transitions, session, finish, residue | 1, 4 | property + concurrency | pending |
| G4 awareness without lock pressure | U2, U3 | advisory overlap/exclusivity | 4 | two-agent host tests | pending |
| G5 no per-edit debt | U5 | sensitive block; session reuse; zero HOOK; atomic finish | 1, 4 | host/schema/journey | pending |
| G6 low-cost UX | U1, U5 | ≤3 commands and context budgets | 3, 5 | journeys + byte tests | pending |
| G7 one small contract | U7 | 37 routes; zero drift/aliases; one skill tree | 1, 5, 6 | exhaustive parity + tarball | pending |
| G8 safe local operation | U6 | exact v4, cutover, runtime/store diagnosis | 0–2, 6 | migration/recovery matrix | pending |
| G9 lossless knowledge cutover | U8 | field/ref/FTS/embedding/recall parity; no trust escalation; no ghosts | 0, 2 | migration + parity + no-ghost eval | blocked on P6a/P6b |
