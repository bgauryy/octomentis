# Agent Context Management — Best Practices

> Derived from: whitehat audit of `@anthropic-ai/claude-code` v2.1.197 internals +
> Pi agent harness patterns. These are evidence-backed decisions, not opinions.

---

## Core Principle

**Context is a budget, not a log.** Every token you keep in context has a cost at inference time and a risk of crowding out relevant working memory. The goal is to carry exactly what is needed for the current phase and nothing more.

---

## 1. The Three Context Tools

| Tool | When to use |
|---|---|
| `compact_context` | Same task continues but context is getting long. Preserves goal; discards working memory. |
| `clear_context` | Task is done OR next task is unrelated AND nothing current is worth carrying. Full reset. |
| `handoff_context(summary, kickoff?)` | Delegating to a fresh sub-agent. Produces a seeded new context. Parent context continues independently. |

**Never ask the user to manage context.** These are autonomous decisions.

---

## 2. Proactive Compaction — Act Before Forced

The worst time to compact is when forced. By then, the model is already degraded.

**Trigger compaction proactively when:**
- Context ≥ 60% full **AND** the next task is large (multi-file, multi-step, or research + execution).
- Research phase is complete and execution phase begins → write findings to file, then compact.
- A new unrelated topic arrives mid-session → evaluate fork before accumulating noise.
- A plan is written and validated → compact; the plan file is the full state.

**Rule:** If PLAN.md cannot be executed without the research context that preceded it, the plan is incomplete. Fix the plan, then compact.

---

## 3. Fork vs Inline — The Decision Tree

Make this decision **before starting**, not mid-task.

```
Is the sub-task self-contained?
(it does not need current thread's reasoning to proceed)
         │
         ├── NO  → stay inline
         │
         └── YES
              │
              Is the context unrelated?
              (current history would add noise, not signal)
                       │
                       ├── NO  → stay inline
                       │
                       └── YES
                            │
                            Is it parallelizable or independent?
                            (result is not an immediate input to next step)
                                     │
                                     ├── NO  → stay inline
                                     │
                                     └── YES → fork (handoff_context)
```

**Always stay inline for:**
- ≤2 tool calls (fork overhead not justified)
- Sub-task result feeds back immediately
- Sub-task requires current findings or open decisions

---

## 4. Writing Self-Contained Handoff Prompts

A bad handoff prompt forces the sub-agent to come back and ask. That defeats the purpose.

**Include every one of these:**

| Element | Why |
|---|---|
| Full goal (not a reference to it) | Sub-agent has no history |
| All relevant file paths and values | No implicit knowledge |
| What "done" looks like | Prevents scope drift |
| What NOT to do | Prevents over-reach |
| Enough context for judgment calls | Agent shouldn't need to ask |

**Bad:**
```
"Continue the auth refactor we discussed."
```

**Good:**
```
"Refactor `packages/octocode-tools-core/src/auth/provider.ts` to extract
the token-refresh logic into a separate `refreshToken(token: Token): Promise<Token>`
function. Do not change callers yet. Write the new function with full JSDoc.
Return the diff only — do not commit."
```

**Anti-nesting rule:** If you are already executing as a delegated sub-task, do NOT fork further. Complete the task with available tools and return results to the caller. Unbounded nesting loses the thread and wastes context at every level.

---

## 5. The Research → Plan → Compact → Execute Flow

This is the single most effective pattern for non-trivial multi-step work. Claude Code uses it internally for all orchestrated agent work.

```
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 1: RESEARCH                                               │
│                                                                 │
│ - Use Octocode for all discovery (search → symbols → exact)     │
│ - Do NOT write code during research                             │
│ - Write findings to RESEARCH.md or directly into PLAN.md        │
│ - Stop when: blast radius known, every changed file named,      │
│   each change describable in one sentence                       │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 2: PLAN                                                   │
│                                                                 │
│ Write PLAN.md:                                                  │
│   ## Goal                                                       │
│   ## Blast Radius (files/modules affected)                      │
│   ## Steps (numbered, each independently verifiable)            │
│   ## Decisions & Rationale                                      │
│   ## Risks & Rollback                                           │
│   ## Out of Scope                                               │
│                                                                 │
│ Mark parallel-capable, context-independent steps [PARALLEL]     │
│ Each step must be independently executable — no "do 3-7 together"│
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 3: COMPACT                                                │
│                                                                 │
│ - compact_context after PLAN.md is validated                    │
│ - The plan file IS the full state                               │
│ - Fresh context reads PLAN.md — no memory of research needed    │
│ - If fresh context can't execute from PLAN.md alone → fix plan  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│ PHASE 4: EXECUTE                                                │
│                                                                 │
│ - Read PLAN.md. Execute steps in order. Check off each step.    │
│ - After each step: verify (test / lint / exact read of output)  │
│   Never advance on "probably works"                             │
│                                                                 │
│   [PARALLEL] steps:                                             │
│     → Evaluate fork decision (section 3)                       │
│     → If fork: handoff_context with self-contained prompt       │
│     → If inline: execute directly                               │
│                                                                 │
│ - On unexpected divergence: stop, update PLAN.md, then continue │
│   Do not silently absorb scope changes                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Parallel Isolation Rule

When two independent tasks both mutate files, they **must not** share a context.

**Why:** Parallel edits in the same context will produce conflicting diffs. One will clobber the other.

**Pattern:**
```
Task A (mutates files X, Y)    Task B (mutates files P, Q)
         │                              │
    handoff_context              handoff_context
    (self-contained)             (self-contained)
         │                              │
     complete                       complete
         │                              │
         └──────── merge sequentially ──┘
                   (verify after each)
```

**Never:** `NEVER run parallel edits on the same files.`

---

## 7. Handoff Summary Format

Use this exact format — every field is load-bearing for the receiving agent.

```markdown
## Goal: [what to accomplish — complete sentence, no references]
## Constraints: [hard requirements — things that cannot be violated]
## Progress: [x] done · [ ] in-progress/blocked
## Key Decisions: [decision: rationale — one line each]
## Next Steps: [numbered, ordered, independently executable]
## Critical Context: [paths, values, facts — everything the agent needs]
```

Missing fields = the sub-agent either asks or guesses. Both are worse than writing it out.

---

## 8. Context Hygiene Checklist

Before starting any substantial task:

- [ ] Is there a PLAN.md or equivalent? If not, write one before touching code.
- [ ] Is context ≥60% full? If so, compact before starting.
- [ ] Are there parallel-capable steps? Mark them [PARALLEL] in the plan.
- [ ] Does any step depend on a file that doesn't exist yet? Note the dependency.
- [ ] Is any step a fork candidate? Verify it meets all 3 fork criteria.

After completing a phase:

- [ ] Were findings written to a file (not just in conversation)? Files survive compaction; conversation doesn't.
- [ ] Is the next phase self-sufficient from what's on disk? If yes, compact.
- [ ] Did any scope change happen? Update PLAN.md before continuing.

---

## 9. What Claude Code Does Internally (Evidence Basis)

These patterns are extracted from the `@anthropic-ai/claude-code` v2.1.197 binary (Bun SEA, 227MB), confirmed via strings extraction.

**Coordinator pattern:** The orchestrator writes self-contained worker prompts — workers receive no coordinator context, only their task. This is why worker prompts must include all necessary context explicitly.

**Compact prompt:** When Claude Code compacts, it uses:
```
REMINDER: Do NOT call any tools. Respond with plain text only —
an <analysis> block followed by a <summary> block.
```
The output is a structured summary, not a flat dump. This keeps the summary navigable.

**Subagent restriction injection:** Every sub-agent receives:
```
Do NOT spawn subagents. The "default to forking" guidance is for the parent;
you ARE the fork, execute directly.
```
This enforces the anti-nesting rule at the protocol level.

**Compact triggering:** Claude Code precomputes compaction in the background (`precomputeCompactionEnabled`) before it's needed. The equivalent in Pi is proactive compaction at 60% — don't wait for the warning.

**Worker prompt guideline (verbatim from binary):**
> Give enough context about the surrounding problem that the agent can make
> judgment calls rather than just following a narrow instruction.

This is the single most important rule for writing handoff prompts. A narrow instruction produces a narrow result. A well-contextualized instruction produces a result that survives contact with the real codebase.

---

## 10. Quick Reference Card

```
COMPACT when:      context ≥60% AND next task is large
                   research done AND execution begins
                   plan written AND validated

CLEAR when:        task done AND next task fully unrelated

FORK when:         self-contained + unrelated context + parallelizable
                   (ALL three must be true)

INLINE when:       ≤2 tool calls
                   result feeds back immediately
                   depends on current context/decisions

PLAN.md must:      be executable without research context
                   have numbered independently-verifiable steps
                   mark [PARALLEL] candidates explicitly

HANDOFF must:      include full goal (no references)
                   include all paths and values
                   define "done"
                   define "do not do"

ANTI-NESTING:      if you are already a forked sub-task → do NOT fork further
PARALLEL SAFETY:   two tasks mutating same files → fork both, merge sequentially
```
