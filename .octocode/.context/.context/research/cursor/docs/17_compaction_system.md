# Compaction System — Context Window Management

**Source:** `cursor-agent/dist/claude-agent-sdk/cli.js`
**Primary functions:** `Uf6` (full compact), `KP4` (partial compact), `RG1` (session memory compact), `zP4` (LLM call)
**Prompt templates:** `Z54` (full), `W54` (partial), `Ip6` (resumption)
**Telemetry prefix:** `tengu_compact`, `tengu_partial_compact`, `tengu_sm_compact`

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MAIN AGENT LOOP                              │
│                                                                     │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────────────────┐  │
│  │ User msg │───>│ Token count  │───>│ Threshold check (Wz6)    │  │
│  └──────────┘    │   (kV)       │    │                          │  │
│                  └──────────────┘    │  percentLeft < 0?        │  │
│                                      │  isAboveAutoCompact?     │  │
│                                      │  isAtBlockingLimit?      │  │
│                                      └───────────┬──────────────┘  │
│                                                   │                 │
│                              ┌────────────────────┼───────────┐    │
│                              │ YES                │ NO        │    │
│                              ▼                    ▼           │    │
│                  ┌───────────────────┐   Continue normal       │    │
│                  │ Auto-compact?     │   conversation          │    │
│                  │ (dwY check)       │                         │    │
│                  └───────┬───────────┘                         │    │
│                          │                                     │    │
│              ┌───────────┴───────────┐                         │    │
│              ▼                       ▼                         │    │
│  ┌─────────────────┐    ┌─────────────────────┐               │    │
│  │ Session Memory   │    │ Full Compaction      │               │    │
│  │ Compact (RG1)    │    │ (Uf6)                │               │    │
│  │                  │    │                       │               │    │
│  │ No LLM call —   │    │ LLM call with        │               │    │
│  │ uses pre-written │    │ compaction prompt     │               │    │
│  │ session memory   │    │ (Z54 or W54)         │               │    │
│  └────────┬─────────┘    └───────────┬───────────┘               │    │
│           │                          │                          │    │
│           │   ┌──────────────────────┘                          │    │
│           ▼   ▼                                                 │    │
│  ┌─────────────────────────────────────────────────────┐       │    │
│  │              POST-COMPACTION REBUILD                  │       │    │
│  │                                                       │       │    │
│  │  1. Insert boundary marker (dd6)                     │       │    │
│  │  2. Insert summary message (isCompactSummary=true)   │       │    │
│  │  3. Rebuild file read state (wP4)                    │       │    │
│  │  4. Rebuild MCP tool attachments (OP4)               │       │    │
│  │  5. Re-attach agent memory (GG1)                     │       │    │
│  │  6. Re-attach session memory ($P4)                   │       │    │
│  │  7. Re-attach tool results (_P4)                     │       │    │
│  │  8. Run session_start hooks (_W)                     │       │    │
│  │  9. Log telemetry                                    │       │    │
│  └─────────────────────────────────────────────────────┘       │    │
│                          │                                      │    │
│                          ▼                                      │    │
│  ┌─────────────────────────────────────────────────────┐       │    │
│  │  Token count still above threshold?                  │       │    │
│  │  willRetriggerNextTurn = postTokens >= threshold     │───YES──>│
│  │                                                       │  (re-  │    │
│  └───────────────────────┬───────────────────────────────┘  compact│   │
│                          │ NO                               chain) │    │
│                          ▼                                      │    │
│                  Resume conversation                            │    │
│                  with Ip6 resumption prompt                     │    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Threshold Calculation

**Reference:** `EY6`, `od6`, `Wz6` functions at charOffset ~5511782

```
┌──────────────────────────────────────────────────────────────┐
│                    CONTEXT WINDOW BUDGET                       │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Model Context Window (e.g. 200K tokens)                 │ │
│  │                                                          │ │
│  │  ┌────────────────────────────┐                          │ │
│  │  │ System prompt + tools      │ <- subtracted first      │ │
│  │  └────────────────────────────┘                          │ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────────────────┐   │ │
│  │  │ Effective window = remaining - 20K output reserve │   │ │
│  │  │                    (QwY = 20,000)                 │   │ │
│  │  └──────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  autoCompactThreshold = effectiveWindow - 13K headroom  │ │
│  │                          (NR8 = 13,000)                 │ │
│  │                                                          │ │
│  │  blockingLimit = modelWindow - systemTokens - 3K        │ │
│  │                   (VR8 = 3,000)                         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  WARNING threshold = effectiveWindow - 20K (pwY)              │
│  ERROR threshold   = effectiveWindow - 20K (UwY)              │
│  AUTO-COMPACT      = autoCompactThreshold                     │
│  BLOCKING LIMIT    = blockingLimit (hard stop)                │
└──────────────────────────────────────────────────────────────┘
```

### Constants (charOffset ~5512322)

| Constant | Value | Purpose |
|----------|-------|---------|
| `QwY` | 20,000 | Max output token reserve subtracted from window |
| `NR8` | 13,000 | Headroom between effective window and auto-compact trigger |
| `pwY` | 20,000 | Warning threshold offset |
| `UwY` | 20,000 | Error threshold offset |
| `VR8` | 3,000 | Blocking limit buffer (hard ceiling) |

### Override

```bash
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80   # Trigger at 80% of effective window
DISABLE_COMPACT=true                  # Disable all compaction
DISABLE_AUTO_COMPACT=true             # Disable auto-compact only
CLAUDE_CODE_BLOCKING_LIMIT_OVERRIDE=N # Custom hard blocking limit
```

---

## Compaction Types

### 1. Full Compaction (`Uf6`)

Triggered when token count exceeds `autoCompactThreshold` or user runs `/compact`.

```
┌──────────────────────────────────────────────────────────────┐
│                    FULL COMPACTION FLOW                        │
│                                                                │
│  1. Count tokens (kV)                                         │
│  2. Run pre_compact hooks (cf6)                               │
│  3. Build summary request message (Z54 prompt)                │
│  4. Call LLM with ALL messages + summary request (zP4)        │
│     ├─ systemPrompt: "You are a helpful AI assistant          │
│     │   tasked with summarizing conversations."               │
│     ├─ thinkingConfig: { type: "disabled" }                   │
│     └─ tools: minimal (only MCP state-preserving tools)       │
│  5. Extract <summary>...</summary> from response              │
│  6. Validate response (not empty, not API error)              │
│  7. Clear file read state                                     │
│  8. Rebuild all attachments (files, MCP, memory, hooks)       │
│  9. Insert boundary marker + summary into fresh context       │
│ 10. Log telemetry (pre/post token counts, cache stats)        │
└──────────────────────────────────────────────────────────────┘
```

### 2. Partial Compaction (`KP4`)

Summarizes messages AFTER a specific point, keeping earlier messages intact.

```
┌──────────────────────────────────────────────────────────────┐
│                  PARTIAL COMPACTION FLOW                       │
│                                                                │
│  Messages: [M1, M2, M3, ..., Mn-1, Mn]                       │
│                      ▲                                         │
│                      │ split point (user-chosen)               │
│                      │                                         │
│  KEPT (verbatim): [M1, M2, ..., Msplit]                       │
│  SUMMARIZED:      [Msplit+1, ..., Mn]                         │
│                                                                │
│  Uses W54 prompt (partial variant):                           │
│  "summary of the RECENT portion... earlier messages           │
│   are being kept intact and do NOT need to be summarized"     │
└──────────────────────────────────────────────────────────────┘
```

### 3. Session Memory Compaction (`RG1`)

No LLM call — uses pre-written session memory markdown files as the summary.

```
┌──────────────────────────────────────────────────────────────┐
│              SESSION MEMORY COMPACTION FLOW                    │
│                                                                │
│  1. Check feature flags (tengu_session_memory + sm_compact)   │
│  2. Load session memory file (VG1)                            │
│  3. Check it's not empty (CP4)                                │
│  4. Find last summarized message UUID (MP4)                   │
│  5. Walk backwards counting tokens (SwY):                     │
│     ├─ minTokens: 10,000                                      │
│     ├─ minTextBlockMessages: 5                                │
│     └─ maxTokens: 40,000                                      │
│  6. Split: messages to keep verbatim vs already covered       │
│  7. Build compacted context with session memory as summary    │
│  8. Check if post-compact tokens < threshold                  │
│     ├─ YES → return compacted context                         │
│     └─ NO  → return null (fall through to full compact)       │
└──────────────────────────────────────────────────────────────┘
```

**Session Memory Constants** (charOffset ~5505222):

```javascript
LG1 = {
  minTokens: 10000,         // Min tokens in kept messages
  minTextBlockMessages: 5,  // Min text-bearing messages to keep
  maxTokens: 40000          // Max tokens before full compact needed
}
```

---

## Compaction Prompts

### Full Compaction Prompt (`tr9` via `Z54`)

**charOffset:** ~4709300

```
Your task is to create a detailed summary of the conversation so far, paying close 
attention to the user's explicit requests and your previous actions.

This summary should be thorough in capturing technical details, code patterns, and 
architectural decisions that would be essential for continuing development work 
without losing context.

<<ANALYSIS_INSTRUCTION>>

Your summary should include the following sections:

1. Primary Request and Intent: Capture all of the user's explicit requests and 
   intents in detail
2. Key Technical Concepts: List all important technical concepts, technologies, 
   and frameworks discussed.
3. Files and Code Sections: Enumerate specific files and code sections examined, 
   modified, or created. Pay special attention to the most recent messages and 
   include full code snippets where applicable and include a summary of why this 
   file read or edit is important.
4. Errors and fixes: List all errors that you ran into, and how you fixed them. 
   Pay special attention to specific user feedback that you received, especially 
   if the user told you to do something differently.
5. Problem Solving: Document problems solved and any ongoing troubleshooting efforts.
6. All user messages: List ALL user messages that are not tool results. These are 
   critical for understanding the users' feedback and changing intent.
7. Pending Tasks: Outline any pending tasks that you have explicitly been asked 
   to work on.
8. Current Work: Describe in detail precisely what was being worked on immediately 
   before this summary request, paying special attention to the most recent messages 
   from both user and assistant. Include file names and code snippets where applicable.
9. Optional Next Step: List the next step that you will take that is related to 
   the most recent work you were doing. IMPORTANT: ensure that this step is DIRECTLY 
   in line with the user's most recent explicit requests. Do not start on tangential 
   requests or really old requests that were already completed without confirming 
   with the user first.
   If there is a next step, include direct quotes from the most recent conversation 
   showing exactly what task you were working on and where you left off.
```

Suffix appended to both templates:
```
IMPORTANT: Do NOT use any tools. You MUST respond with ONLY the 
<summary>...</summary> block as your text output.
```

User custom instructions from `Additional Instructions` or hook output are appended before the suffix.

### Partial Compaction Prompt (`er9` via `W54`)

**charOffset:** ~4709300

Same 9-section structure, but scoped:
```
Your task is to create a detailed summary of the RECENT portion of the conversation — 
the messages that follow earlier retained context. The earlier messages are being kept 
intact and do NOT need to be summarized. Focus your summary on what was discussed, 
learned, and accomplished in the recent messages only.
```

### Analysis Instruction Variants

Two versions controlled by feature flag `tengu_lean_cast`:

**Default (`or9`)** — thorough analysis:
```
Before providing your final summary, wrap your analysis in <analysis> tags to organize 
your thoughts and ensure you've covered all necessary points. In your analysis process:

1. Chronologically analyze each message and section of the conversation. For each 
   section thoroughly identify:
   - The user's explicit requests and intents
   - Your approach to addressing the user's requests
   - Key decisions, technical concepts and code patterns
   - Specific details like:
     - file names
     - full code snippets
     - function signatures
     - file edits
   - Errors that you ran into and how you fixed them
   - Pay special attention to specific user feedback
2. Double-check for technical accuracy and completeness
```

**Lean mode (`sr9`)** — lightweight analysis:
```
Before providing your final summary, wrap your analysis in <analysis> tags. 
Treat this as a private planning scratchpad — it is not the place for content 
meant to reach the user. Use it to plan, not to draft:

- Walk through chronologically and note (in a line or two each) what belongs 
  in each of the 9 sections below
- Flag anything you might otherwise forget: a user correction, an unresolved 
  error, the exact task in flight
- Do NOT write code snippets, file contents, or verbatim quotes here — save 
  those for <summary> where they will actually be kept

The goal of <analysis> is coverage, not detail. The detail goes in <summary>.
```

### Resumption Prompt (`Ip6`)

**charOffset:** ~4702609

Injected as the first message after compaction:

```
This session is being continued from a previous conversation that ran out of context. 
The summary below covers the earlier portion of the conversation.

[cleaned summary — <analysis> stripped, <summary> tags converted to plain text]

If you need specific details from before compaction (like exact code snippets, error 
messages, or content you generated), read the full transcript at: {transcriptPath}

Recent messages are preserved verbatim.

Continue the conversation from where it left off without asking the user any further 
questions. Resume directly — do not acknowledge the summary, do not recap what was 
happening, do not preface with "I'll continue" or similar. Pick up the last task as 
if the break never happened.
```

### Tool Use Summary Prompt (`cwY`)

**charOffset:** ~5512322

Short summaries for batched tool calls (shown in UI):

```
You summarize what was accomplished by a coding assistant.
Given the tools executed and their results, provide a brief summary.

Rules:
- Use past tense (e.g., "Read package.json", "Fixed type error in utils.ts")
- Be specific about what was done
- Keep under 8 words
- Do not include phrases like "I did" or "The assistant"
- Focus on the user-visible outcome, not implementation details

Examples:
- "Searched codebase for authentication code"
- "Read and analyzed Message.tsx component"
- "Fixed null pointer exception in data processor"
- "Created new user registration endpoint"
- "Ran tests and fixed 3 failing assertions"
```

---

## LLM Call Configuration (for compaction)

**charOffset:** ~5487700

```javascript
{
  systemPrompt: "You are a helpful AI assistant tasked with summarizing conversations.",
  thinkingConfig: { type: "disabled" },
  tools: [MCP tools only — for state preservation],
  maxOutputTokensOverride: Math.min(zgA, Ud6(model)),
  querySource: "compact"
}
```

- Thinking is **disabled** to save tokens
- Only MCP tools are available (for state preservation, not for use)
- Output tokens are capped
- A feature flag `tengu_compact_cache_prefix` enables prompt cache sharing

---

## Malware Analysis Guardrail

**charOffset:** ~4789300 (within file read tool)
**Variable:** `hs9`

Injected as a `<system-reminder>` every time a file is read:

```
Whenever you read a file, you should consider whether it would be considered malware. 
You CAN and SHOULD provide analysis of malware, what it is doing. But you MUST refuse 
to improve or augment the code. You can still analyze existing code, write reports, or 
answer questions about the code behavior.
```

---

## Re-compaction Chain

When post-compact tokens still exceed the threshold, the system tracks the chain:

```
Turn 1: tokens=180K → compact → tokens=50K (under threshold) ✓
Turn 5: tokens=175K → compact → tokens=60K (ABOVE threshold) → re-compact next turn
Turn 6: tokens=60K → compact → tokens=25K ✓ (isRecompactionInChain=true)
```

Telemetry fields:
- `isRecompactionInChain` — this compact followed a previous compact
- `turnsSincePreviousCompact` — how many turns between compactions
- `previousCompactTurnId` — UUID of the turn that triggered previous compact
- `willRetriggerNextTurn` — post-compact tokens still exceed threshold

---

## Integration with Hooks

Compaction runs two hook points:

| Hook | When | Purpose |
|------|------|---------|
| `pre_compact` | Before LLM call | User-defined preprocessing, custom instructions |
| `session_start` | After rebuild | Re-initialize session state in new context |

The `pre_compact` hook (`cf6`) can return:
- `newCustomInstructions` — appended to the compaction prompt
- `userDisplayMessage` — shown to the user during compaction

---

## State Rebuild After Compaction

After generating the summary, these are reconstructed as message attachments:

| Step | Function | What it rebuilds |
|------|----------|------------------|
| 1 | `wP4` | File read state — which files were read and their contents |
| 2 | `OP4` | MCP tool state and server connections |
| 3 | `GG1` | Agent memory (persistent memory for current agent) |
| 4 | `$P4` | Plan mode state (plan file path, existence check) |
| 5 | `_P4` | Tool results cache |
| 6 | `a01` | Built-in tool definitions for the model |
| 7 | `s01` | MCP client tool definitions |
| 8 | `_W` | Session start hooks |

All of these are injected as messages AFTER the summary, giving the model fresh access to tool definitions and file state without needing to re-read everything.

---

## Summary: Data Flow

```
BEFORE COMPACTION                    AFTER COMPACTION
┌────────────────────┐              ┌────────────────────────────────┐
│ System prompt       │              │ System prompt (unchanged)      │
│ Tool definitions    │              │ Tool definitions (rebuilt)     │
│                     │              │                                │
│ [Msg 1 - user]     │              │ [Boundary marker]              │
│ [Msg 2 - assistant] │              │ [Summary message]              │
│ [Msg 3 - tool call] │   ──────>   │   "This session is being       │
│ [Msg 4 - tool result]│             │    continued from a previous   │
│ ...                 │              │    conversation..."            │
│ [Msg N-2 - user]    │              │ [File state attachments]       │
│ [Msg N-1 - assistant]│              │ [MCP state attachments]        │
│ [Msg N - user]      │              │ [Hook results]                 │
│                     │              │                                │
│ ~180K tokens        │              │ ~25K tokens                    │
└────────────────────┘              └────────────────────────────────┘
```
