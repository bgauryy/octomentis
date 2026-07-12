# Session Memory — Persistent Cross-Turn Knowledge

**Source:** `cursor-agent/dist/claude-agent-sdk/cli.js`
**Primary functions:** `USz` (update orchestrator), `QSz` (init/read), `FSz` (trigger check), `hP4` (prompt builder), `RG1` (SM compaction), `VG1` (load), `dSz` (tool policy)
**File path:** `~/.cursor/projects/<projectHash>/<sessionId>/session-memory/summary.md`
**Template path:** `~/.cursor/projects/<projectHash>/<sessionId>/session-memory/config/template.md`
**Custom prompt path:** `~/.cursor/projects/<projectHash>/<sessionId>/session-memory/config/prompt.md`
**Feature flags:** `tengu_session_memory`, `tengu_sm_compact`, `tengu_sm_config`, `tengu_sm_compact_config`
**Telemetry prefix:** `tengu_session_memory_*`, `tengu_sm_compact_*`

---

## Overview

Session Memory is a persistent note-taking system that runs as a **background forked LLM call** alongside the main conversation. It maintains a structured markdown file (`summary.md`) that captures the evolving state of a coding session — what the user is working on, what files matter, what errors were hit, and what was learned.

Unlike compaction (which summarizes and discards messages), session memory **persists independently** on disk and survives across compaction boundaries, session resumptions, and even new conversations in the same project.

Session memory serves three purposes:
1. **Cross-compaction continuity** — replaces the LLM-generated summary during compaction (zero-cost compaction)
2. **Skill generation** — provides session context to the `/skillify` flow
3. **Nested memory attachment** — re-read and re-attached to context when the file changes

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      MAIN CONVERSATION                           │
│                                                                   │
│  User msg → Assistant response → Tool calls → ...                │
│                                                                   │
│  After each LLM turn, the system checks:                        │
│  ┌────────────────────────────────────────────────────────┐     │
│  │              TRIGGER CHECK (FSz)                        │     │
│  │                                                         │     │
│  │  1. Feature flag enabled? (tengu_session_memory)        │     │
│  │  2. Enough tokens processed? (≥ 10K to init)           │     │
│  │  3. Enough tokens since last update? (≥ 5K)            │     │
│  │  4. Enough tool calls since last update? (≥ 3)         │     │
│  │  5. Last assistant turn had tool use? (OR no tool use   │     │
│  │     but token threshold still met)                      │     │
│  └────────────────────────┬───────────────────────────────┘     │
│                           │ YES (all conditions met)             │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────┐     │
│  │          FORKED UPDATE CALL (USz via dS)                │     │
│  │                                                         │     │
│  │  1. Set update lock (DP4 — timestamp-based)            │     │
│  │  2. Clone tool use context (Ni6)                       │     │
│  │  3. Init/read session memory file (QSz)                │     │
│  │  4. Build update prompt with current notes (hP4)       │     │
│  │  5. Fork LLM call with:                                │     │
│  │     - promptMessages: [update instruction]             │     │
│  │     - canUseTool: ONLY Edit on summary.md (dSz)        │     │
│  │     - querySource: "session_memory"                    │     │
│  │     - forkLabel: "session_memory"                      │     │
│  │  6. Log telemetry (token usage, config values)         │     │
│  │  7. Record token count at update time (GP4)            │     │
│  │  8. Track last summarized message UUID (cSz)           │     │
│  │  9. Release update lock (XP4)                          │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
│  The forked call runs in the BACKGROUND — it does not block      │
│  the main conversation. The agent sees the full conversation     │
│  history and writes updates to summary.md via Edit tool.         │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure

### Directory Layout

```
~/.cursor/projects/<projectHash>/<sessionId>/
└── session-memory/
    ├── summary.md                    # The session memory file
    └── config/
        ├── template.md               # Custom template (optional override)
        └── prompt.md                 # Custom update prompt (optional override)
```

### Default Template (`EP4`)

**charOffset:** ~5499380

The default template defines 9 mandatory sections. Each section has a header and an italic description line that must never be modified:

```markdown
# Session Title
_A short and distinctive 5-10 word descriptive title for the session. Super info dense, no filler_

# Current State
_What is actively being worked on right now? Pending tasks not yet completed. Immediate next steps._

# Task specification
_What did the user ask to build? Any design decisions or other explanatory context_

# Files and Functions
_What are the important files? In short, what do they contain and why are they relevant?_

# Workflow
_What bash commands are usually run and in what order? How to interpret their output if not obvious?_

# Errors & Corrections
_Errors encountered and how they were fixed. What did the user correct? What approaches failed and should not be tried again?_

# Codebase and System Documentation
_What are the important system components? How do they work/fit together?_

# Learnings
_What has worked well? What has not? What to avoid? Do not duplicate items from other sections_

# Key results
_If the user asked a specific output such as an answer to a question, a table, or other document, repeat the exact result here_

# Worklog
_Step by step, what was attempted, done? Very terse summary for each step_
```

### Custom Template Override

Users can place a custom `template.md` at:
```
~/.cursor/projects/<projectHash>/<sessionId>/session-memory/config/template.md
```

The system reads it via `$R8()` and falls back to the built-in `EP4` if the file doesn't exist.

### Custom Prompt Override

Users can place a custom `prompt.md` at:
```
~/.cursor/projects/<projectHash>/<sessionId>/session-memory/config/prompt.md
```

Read via `GwY()`, falling back to the built-in `LP4()` prompt.

---

## Update Trigger Logic

### Configuration Constants (`cd6`)

**charOffset:** ~5492893

| Constant | Default | Purpose |
|----------|---------|---------|
| `minimumMessageTokensToInit` | 10,000 | Min total tokens before first update |
| `minimumTokensBetweenUpdate` | 5,000 | Min token delta between updates |
| `toolCallsBetweenUpdates` | 3 | Min tool calls between updates |

These are overridable via Statsig dynamic config `tengu_sm_config`.

### Trigger Decision Flow (`FSz`)

**charOffset:** ~10588394

```
Is this the main thread? (querySource === "repl_main_thread")
  │ NO → skip
  │ YES ↓
Is tengu_session_memory enabled?
  │ NO → skip
  │ YES ↓
Load config from Statsig (pSz — one-time lazy init)
  │
Has initialization threshold been reached? (total tokens ≥ 10K)
  │ NO → skip (NP4 returns false)
  │ YES ↓ (TP4 sets initialized flag)
Has enough token delta passed? (current − lastUpdate ≥ 5K)
  │ NO → check tool count fallback
  │ YES ↓
Have enough tool calls occurred? (≥ 3 since last update)
  │ YES → TRIGGER UPDATE
  │ NO  → check: did last assistant turn NOT use tools?
          │ YES (no tool use) AND token threshold met → TRIGGER UPDATE
          │ NO → skip
```

The `wo6` function checks whether the last assistant message contained tool use. This allows updates to fire when the conversation is text-heavy (no tool calls) but still accumulating tokens.

### Concurrency Lock

- `DP4()` — sets `NG1 = Date.now()` (lock timestamp)
- `XP4()` — clears `NG1 = undefined` (release lock)
- `PP4()` — async wait loop: polls every 1s, gives up after 15s (`WwY`), or if lock held > 60s (`ZwY`)
- Before a new SM compaction, `PP4()` waits for any in-progress update to finish

---

## Update Prompt

### Full Prompt (`LP4`)

**charOffset:** ~5493753

The update prompt is injected as the last message in a forked LLM call. It includes:

```
IMPORTANT: This message and these instructions are NOT part of the actual user 
conversation. Do NOT include any references to "note-taking", "session notes 
extraction", or these update instructions in the notes content.

Based on the user conversation above (EXCLUDING this note-taking instruction message 
as well as system prompt, claude.md entries, or any past session summaries), update 
the session notes file.

The file {{notesPath}} has already been read for you. Here are its current contents:
<current_notes_content>
{{currentNotes}}
</current_notes_content>

Your ONLY task is to use the Edit tool to update the notes file, then stop. You can 
make multiple edits (update every section as needed) - make all Edit tool calls in 
parallel in a single message. Do not call any other tools.

CRITICAL RULES FOR EDITING:
- The file must maintain its exact structure with all sections, headers, and italic 
  descriptions intact
- NEVER modify, delete, or add section headers (lines starting with '#')
- NEVER modify or delete the italic _section description_ lines
- The italic _section descriptions_ are TEMPLATE INSTRUCTIONS that must be preserved 
  exactly as-is
- ONLY update the actual content that appears BELOW the italic _section descriptions_
- Do NOT add any new sections, summaries, or information outside the existing structure
- Do NOT reference this note-taking process or instructions
- It's OK to skip updating a section if there are no substantial new insights to add
- Write DETAILED, INFO-DENSE content for each section
- For "Key results", include the complete, exact output the user requested
- Do not include information that's already in the CLAUDE.md files
- Keep each section under ~${vG1} tokens/words  [vG1 = 2000]
- Focus on actionable, specific information
- IMPORTANT: Always update "Current State" to reflect the most recent work

Use the Edit tool with file_path: {{notesPath}}

STRUCTURE PRESERVATION REMINDER:
Each section has TWO parts that must be preserved:
1. The section header (line starting with #)
2. The italic description line (_italicized text_ after the header)
You ONLY update the actual content that comes AFTER these two preserved lines.

REMEMBER: Use the Edit tool in parallel and stop.
```

### Size Overflow Handling (`TwY`)

**charOffset:** ~5498509

When sections exceed limits, additional instructions are appended:

| Condition | Message appended |
|-----------|-----------------|
| Total file > `kP4` (12,000 tokens) | `CRITICAL: The session memory file is currently ~N tokens, which exceeds the maximum of 12000 tokens. You MUST condense the file...` |
| Any section > `vG1` (2,000 tokens) | Lists oversized sections with `"SECTION" is ~N tokens (limit: 2000)` |

### Template Substitution

`NwY` replaces `{{placeholder}}` patterns:
- `{{notesPath}}` → absolute path to `summary.md`
- `{{currentNotes}}` → current file contents

---

## Size Limits and Truncation

### Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `vG1` | 2,000 | Per-section token limit (soft — generates warning) |
| `kP4` | 12,000 | Total file token limit (generates CRITICAL warning) |

### Section Truncation (`IP4`)

**charOffset:** ~5499200

When session memory is used for compaction, sections exceeding `4 × vG1` (8,000 chars) are truncated:

```
function IP4(content) {
  for each section:
    if section.length > 4 * vG1:
      truncate and append "\n[... section truncated for length ...]"
  return { truncatedContent, wasTruncated }
}
```

If any section was truncated, the compaction resumption message appends:
```
Some session memory sections were truncated for length. 
The full session memory can be viewed at: <path>
```

---

## Tool Policy During Update

### Edit-Only Policy (`dSz`)

**charOffset:** ~10589186

The forked LLM call is restricted to a **single tool**: the Edit tool (`bq`), and only on the specific `summary.md` path:

```javascript
function dSz(memoryPath) {
  return async (toolName, toolInput) => {
    if (toolName === EditTool && toolInput.file_path === memoryPath) {
      return { behavior: "allow" };
    }
    return { 
      behavior: "deny", 
      message: `only Edit on ${memoryPath} is allowed` 
    };
  };
}
```

This prevents the session memory agent from reading files, running commands, or making any changes outside the memory file.

---

## Session Memory Compaction (`RG1`)

**charOffset:** ~5504091

When the context window fills up and auto-compaction triggers, the system first attempts **session memory compaction** — a zero-LLM-cost alternative to full compaction.

### Flow

```
┌──────────────────────────────────────────────────────────────┐
│           SESSION MEMORY COMPACTION (RG1)                      │
│                                                                │
│  1. Check feature flags:                                      │
│     - tengu_session_memory = true                             │
│     - tengu_sm_compact = true                                 │
│     (yG1 function, also checks env vars)                      │
│                                                                │
│  2. Wait for any in-progress update (PP4)                     │
│                                                                │
│  3. Find last summarized message UUID (MP4)                   │
│                                                                │
│  4. Load session memory file (VG1 → reads summary.md)         │
│     ├─ null → return null (no session memory, fall to full)   │
│     └─ matches template → return null (empty, fall to full)   │
│                                                                │
│  5. Load SM compact config from Statsig                       │
│     (tengu_sm_compact_config)                                 │
│                                                                │
│  6. Calculate split point (SwY):                              │
│     Walk backwards from last summarized message,              │
│     counting tokens and text-bearing messages:                │
│     ├─ minTokens: 10,000                                     │
│     ├─ minTextBlockMessages: 5                                │
│     └─ maxTokens: 40,000                                     │
│     Adjust split to respect tool-use boundaries (JR8)         │
│                                                                │
│  7. Build compacted context (CwY):                            │
│     ├─ Truncate oversized sections (IP4)                      │
│     ├─ Generate resumption message (Ip6) with                 │
│     │   session memory as summary content                     │
│     ├─ Insert boundary marker (dd6)                           │
│     ├─ Re-attach agent memory (GG1)                           │
│     └─ Keep recent messages verbatim                          │
│                                                                │
│  8. Check post-compact token count:                           │
│     ├─ Under threshold → return compacted context ✓           │
│     └─ Over threshold → return null (fall to full compact)    │
│                                                                │
│  KEY: No LLM call is made. Session memory IS the summary.     │
└──────────────────────────────────────────────────────────────┘
```

### SM Compaction Constants (`LG1`)

| Constant | Value | Purpose |
|----------|-------|---------|
| `minTokens` | 10,000 | Min tokens in messages to keep verbatim |
| `minTextBlockMessages` | 5 | Min text-bearing messages to keep |
| `maxTokens` | 40,000 | Max tokens before falling through to full compact |

### Split Point Adjustment (`JR8`)

The split point is adjusted to avoid breaking tool-use pairs. If a kept message references a `tool_result` whose corresponding `tool_use` would be discarded, the split walks backwards to include the `tool_use` message. It also preserves assistant message groups that share the same `message.id`.

### Environment Variable Overrides

```bash
ENABLE_CLAUDE_CODE_SM_COMPACT=true   # Force enable
DISABLE_CLAUDE_CODE_SM_COMPACT=true  # Force disable
```

---

## Initialization Flow (`QSz`)

**charOffset:** ~10589000

When a session memory update triggers for the first time:

```
1. Get project directory (HA()) and session memory dir (WI1)
2. Create directory: mkdir(sessionMemoryDir, mode: 0700)
3. Attempt to create summary.md with flag "wx" (exclusive create):
   ├─ Success: write default template content
   └─ EEXIST: file already exists, continue
4. Read the file via FileReadTool (o9.call)
5. Return { memoryPath, currentMemory }
```

File permissions: `0600` (read/write owner only) for the summary file, `0700` for the directory.

---

## Integration Points

### 1. Nested Memory Attachment

When the session memory file is read or modified, it triggers `nestedMemoryAttachmentTriggers`. On the next turn, `I6Y` processes these triggers and re-injects the updated file content into the conversation context. This happens through the `f2("nested_memory", ...)` attachment slot.

### 2. File Type Detection

**charOffset:** ~4783799, ~6715958

Two functions classify file paths:

```javascript
// mc6: classify by resolved path
function mc6(path) {
  if (path.includes("/session-memory/") && path.endsWith(".md")) 
    return "session_memory";
  if (path.includes("/projects/") && path.endsWith(".jsonl")) 
    return "session_transcript";
  return null;
}

// zT1: classify by glob pattern
function zT1(pattern) {
  if (pattern.includes("session-memory") && (pattern.includes(".md") || pattern.endsWith("*")))
    return "session_memory";
  // ...
}
```

These are used for:
- Collapsing tool calls in the UI (`isMemoryWrite: true`)
- Access telemetry (`tengu_session_memory_accessed`)
- Permission checks for session memory file operations

### 3. Skill Generation (`/skillify`)

**charOffset:** ~10626200

The skill generation prompt (`fCz`) injects session memory content:

```
## Your Session Context

Here is the session memory summary:
<session_memory>
{{sessionMemory}}
</session_memory>

Here are the user's messages during this session...
```

### 4. Tool Call Collapsibility

Session memory writes are classified as `isMemoryWrite: true` via `mz6()`, which means they are collapsible in the UI (shown as collapsed tool calls, not expanded).

### 5. Post-Tool-Use Hooks

**charOffset:** ~8881100

After tool execution, `V3z` checks if the tool accessed session memory:

```javascript
if (classifyToolAccess(toolName, toolInput) === "session_memory") {
  telemetry("tengu_session_memory_accessed", { subagent_name });
}
```

---

## Telemetry Events

| Event | When | Key fields |
|-------|------|------------|
| `tengu_session_memory_loaded` | File read from disk | `content_length` |
| `tengu_session_memory_file_read` | File read during init | `content_length` |
| `tengu_session_memory_extraction` | After forked update completes | `input_tokens`, `output_tokens`, `cache_*`, config values |
| `tengu_session_memory_accessed` | Tool accesses session memory file | `subagent_name` |
| `tengu_session_file_read` | Any session file read via FileReadTool | `is_session_memory`, `is_session_transcript` |
| `tengu_sm_compact_no_session_memory` | SM compact skipped — no file | — |
| `tengu_sm_compact_empty_template` | SM compact skipped — file is default template | — |
| `tengu_sm_compact_summarized_id_not_found` | SM compact skipped — UUID not in messages | — |
| `tengu_sm_compact_resumed_session` | SM compact on resumed session (no prior UUID) | — |
| `tengu_sm_compact_threshold_exceeded` | SM compact result still too large | `postCompactTokenCount`, `autoCompactThreshold` |
| `tengu_sm_compact_error` | SM compact failed | — |

---

## Feature Flag Dependencies

| Flag | Source | Purpose |
|------|--------|---------|
| `tengu_session_memory` | Statsig gate | Master enable for session memory updates |
| `tengu_sm_compact` | Statsig gate | Enable SM-based compaction |
| `tengu_sm_config` | Statsig dynamic config | Override update trigger thresholds |
| `tengu_sm_compact_config` | Statsig dynamic config | Override compaction split thresholds |

### Environment Variable Overrides

| Variable | Effect |
|----------|--------|
| `ENABLE_CLAUDE_CODE_SM_COMPACT` | Force-enable SM compaction |
| `DISABLE_CLAUDE_CODE_SM_COMPACT` | Force-disable SM compaction |

---

## Security Model

### Path Validation

Session memory paths are validated through multiple layers:

1. **`Bc6(path)`** — checks if a path is a recognized session memory or transcript file
2. **`PC8(path)`** — checks if a path is within allowed project/session directories
3. **`Vy4(command)`** — checks if a shell command references session memory paths
4. **`mc6(path)`** / **`zT1(pattern)`** — classifies paths for telemetry and access control

### Write Restrictions

During the forked update, the LLM can **only** use the Edit tool on the specific `summary.md` path. All other tool calls are denied with a clear message. This prevents the session memory agent from:
- Reading arbitrary files
- Running shell commands
- Making network requests
- Editing any file other than the session memory

### File Permissions

- Directory: `0700` (owner rwx only)
- File: `0600` (owner rw only, created with `wx` flag for exclusive create)

---

## Data Flow Summary

```
DURING CONVERSATION                    DURING COMPACTION
┌─────────────────────┐               ┌──────────────────────────┐
│ Main LLM turn        │               │ Context window full       │
│         │            │               │         │                │
│         ▼            │               │         ▼                │
│ Trigger check (FSz)  │               │ SM compact attempt (RG1) │
│   │  (background)    │               │         │                │
│   ▼                  │               │         ▼                │
│ Fork LLM call        │               │ Read summary.md (VG1)    │
│   │                  │               │         │                │
│   ▼                  │               │         ▼                │
│ Edit summary.md      │               │ Use as resumption text   │
│   │                  │               │ (no LLM call needed)     │
│   ▼                  │               │         │                │
│ File on disk updated │────persists───│         ▼                │
│                      │               │ Rebuild context with     │
│ Nested memory attach │               │ session memory + recent  │
│ (next turn)          │               │ messages                 │
└─────────────────────┘               └──────────────────────────┘
```

---

## Relationship to Compaction System

Session memory and compaction are **complementary but independent** systems:

| Aspect | Full Compaction | Session Memory Compaction |
|--------|----------------|--------------------------|
| LLM call required | Yes (expensive) | No (zero cost) |
| Summary source | Generated by LLM from conversation | Pre-written summary.md |
| Trigger | Token count exceeds threshold | Same trigger, checked first |
| Fallback | None (is the fallback) | Falls through to full compaction |
| Message retention | Configurable (full = all summarized, partial = split) | Keeps recent messages based on token/message thresholds |
| State rebuild | Full (files, MCP, memory, hooks, tools) | Partial (boundary marker, agent memory, hooks) |
| Quality | High (purpose-built summary) | Depends on update freshness |
| Cost | ~50K–100K tokens per compaction | Zero additional tokens |

The decision flow:
```
Context window full → Try SM compaction first
  ├─ SM has content AND result fits → Use SM compaction ✓
  └─ SM empty/missing/result too large → Fall through to full compaction
```
