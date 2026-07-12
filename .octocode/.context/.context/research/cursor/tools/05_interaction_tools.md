# Interaction Tools — SwitchMode / AskQuestion / TodoWrite / EditNotebook

**Confidence:** `confirmed` — protobuf types, system prompt descriptions

---

## Tool Family Overview

| Tool | Protobuf Types | Direction | Purpose |
|------|---------------|-----------|---------|
| **SwitchMode** | SwitchModeArgs, SwitchModeResult, SwitchModeToolCall | Control | Change interaction mode |
| **AskQuestion** | AskQuestionArgs, AskQuestionResult, AskQuestionToolCall | UI → User | Structured multiple-choice input |
| **TodoWrite** (UpdateTodos) | UpdateTodosArgs, UpdateTodosResult | State | Task list management |
| **EditNotebook** | (notebook-specific) | Write | Jupyter notebook cell editing |
| **CreatePlan** | CreatePlanArgs, CreatePlanResult, CreatePlanToolCall | State | Structured planning |
| **BlameByFilePath** | BlameByFilePathArgs, BlameByFilePathResult | Read | Git blame lookup |

## SwitchMode Tool

### How It Works

```
LLM emits: SwitchMode { target_mode_id, explanation? }
  │
  ├─ cursor-agent-exec receives SwitchModeArgs
  │    │
  │    ├─ Valid modes:
  │    │   ├─ "agent" — full access to all tools (default)
  │    │   ├─ "plan"  — read-only collaborative planning
  │    │   ├─ "debug" — systematic troubleshooting (cannot switch TO)
  │    │   └─ "ask"   — read-only exploration (cannot switch TO)
  │    │
  │    ├─ Mode switch REQUIRES user approval
  │    │   └─ UI presents: "Agent wants to switch to Plan mode because: <explanation>"
  │    │
  │    └─ On approval:
  │         ├─ Tool availability changes server-side
  │         ├─ System prompt changes to mode-specific instructions
  │         └─ Returns SwitchModeResult
```

### Mode Architecture

Modes are NOT just UI states — they change the **server-side tool availability and system prompt**:

```
Agent Mode:
  ├─ Tools: ALL (Shell, Read, Write, Edit, Delete, Grep, Glob, etc.)
  ├─ System prompt: Full agent instructions
  └─ Behavior: Autonomous implementation

Plan Mode:
  ├─ Tools: Read-only (Read, Grep, Glob, SemanticSearch)
  ├─ System prompt: Planning/architecture focus
  └─ Behavior: Design before code

Debug Mode (cannot switch to — system-assigned):
  ├─ Tools: Diagnostic focus (Shell, Read, Diagnostics)
  ├─ System prompt: Systematic troubleshooting
  └─ Behavior: Evidence-based investigation

Ask Mode (cannot switch to — system-assigned):
  ├─ Tools: Read-only
  ├─ System prompt: Exploration focus
  └─ Behavior: Answer questions without modifications
```

### Critical Detail: Asymmetric Mode Switching

The LLM can request switching to `agent` or `plan`, but CANNOT switch to `debug` or `ask`. Those modes are assigned by the system based on user intent classification (see conversation categorization prompt #03).

## AskQuestion Tool

### How It Works

```
LLM emits: AskQuestion {
  title?: string,
  questions: [
    {
      id: "q1",
      prompt: "Which approach do you prefer?",
      options: [
        { id: "opt1", label: "Option A" },
        { id: "opt2", label: "Option B" }
      ],
      allow_multiple?: boolean
    }
  ]
}
  │
  ├─ cursor-agent-exec receives AskQuestionArgs
  │    │
  │    ├─ Renders structured UI in the chat:
  │    │   ┌─────────────────────────────┐
  │    │   │ Which approach do you prefer?│
  │    │   │  ○ Option A                  │
  │    │   │  ○ Option B                  │
  │    │   └─────────────────────────────┘
  │    │
  │    ├─ Blocks until user selects option(s)
  │    │
  │    └─ Returns AskQuestionResult with selected option IDs
  │
  └─ Constraints:
       ├─ Minimum 1 question
       ├─ Minimum 2 options per question
       ├─ allow_multiple: false → single select (default)
       └─ allow_multiple: true → multi-select checkboxes
```

### UI Integration

AskQuestion creates an interactive widget inline in the chat. This is NOT a text prompt — it's a structured form rendered by the Electron UI. The user clicks/selects, and the selected IDs are returned to the LLM.

## TodoWrite (UpdateTodos) Tool

### How It Works

```
LLM emits: TodoWrite {
  merge: boolean,
  todos: [
    { id: "1", content: "Implement feature X", status: "in_progress" },
    { id: "2", content: "Write tests", status: "pending" }
  ]
}
  │
  ├─ cursor-agent-exec receives UpdateTodosArgs
  │    │
  │    ├─ If merge=false: REPLACE all existing todos
  │    ├─ If merge=true:  MERGE by id (update matching, keep others)
  │    │
  │    ├─ Status values:
  │    │   ├─ "pending"     — not started
  │    │   ├─ "in_progress" — currently working
  │    │   ├─ "completed"   — finished
  │    │   └─ "cancelled"   — no longer needed
  │    │
  │    ├─ Renders as task list in chat UI:
  │    │   ☐ Implement feature X (in progress)
  │    │   ☐ Write tests (pending)
  │    │
  │    └─ Returns UpdateTodosResult
  │
  └─ Key rule: minimum 2 items required per call
```

### State Persistence

Todo state persists across the conversation. The LLM can:
- Create todos, mark them complete, cancel them
- Use `merge=true` to update individual items without touching others
- Have only ONE task `in_progress` at a time (by convention)

## EditNotebook Tool

### How It Works

```
LLM emits: EditNotebook {
  target_notebook: "path/to/notebook.ipynb",
  cell_idx: 3,
  is_new_cell: false,
  cell_language: "python",
  old_string: "existing cell content",
  new_string: "replacement cell content"
}
  │
  ├─ cursor-agent-exec receives notebook edit request
  │    │
  │    ├─ If is_new_cell=true:
  │    │   └─ Creates new cell at cell_idx with new_string content
  │    │
  │    ├─ If is_new_cell=false:
  │    │   ├─ Finds cell at cell_idx
  │    │   ├─ Searches for old_string in cell content
  │    │   ├─ Replaces ONE occurrence with new_string
  │    │   └─ old_string must be unique within the cell
  │    │
  │    ├─ Supported languages:
  │    │   python, markdown, javascript, typescript, r, sql, shell, raw, other
  │    │
  │    └─ Returns result
  │
  └─ Key details:
       ├─ Cell indices are 0-based
       ├─ Cannot DELETE cells (can only empty them)
       ├─ old_string/new_string are raw cell content, NOT JSON
       ├─ May save markdown cells as "raw" (known behavior)
       └─ Arguments MUST be in exact order: target_notebook, cell_idx, is_new_cell, cell_language, old_string, new_string
```

## CreatePlan Tool

### How It Works

From the protobuf types `CreatePlanArgs`, `CreatePlanResult`, `CreatePlanToolCall`:

This tool creates structured implementation plans. It's distinct from TodoWrite — plans are likely hierarchical with dependencies, while todos are flat task lists.

Limited evidence on exact schema, but it pairs with the Plan agent subtype for architecture-first workflows.

## BlameByFilePath Tool

### How It Works

```
LLM emits: BlameByFilePath { path }
  │
  ├─ Runs git blame on the specified file
  │    │
  │    ├─ Returns blame data (author, date, commit per line)
  │    │
  │    └─ Used for:
  │         ├─ Understanding code history
  │         ├─ Finding who changed what
  │         └─ Cursor Blame feature (attributing changes to agent conversations)
```

This connects to the "Cursor Blame" system (prompt #15) which attributes code changes to specific agent conversations.

## AiAttribution Tool

```
AiAttributionArgs → AiAttributionResult
```

Tracks which code was written by AI vs human. Used for:
- Cursor Blame feature
- Commit tracking (cursor-commits extension)
- Usage analytics

## Interaction Model Summary

```
                    ┌─────────────┐
                    │   User      │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐ ┌────▼─────┐ ┌──────▼──────┐
     │ AskQuestion │ │ SwitchMode│ │ Chat Text   │
     │ (structured │ │ (mode    │ │ (free-form  │
     │  selection) │ │  change) │ │  response)  │
     └──────┬──────┘ └────┬─────┘ └──────┬──────┘
            │              │              │
            └──────────────┼──────────────┘
                           │
                    ┌──────▼──────┐
                    │   LLM      │
                    │   (next    │
                    │    turn)   │
                    └──────┬──────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐ ┌────▼─────┐ ┌──────▼──────┐
     │  TodoWrite  │ │CreatePlan│ │ Tool Calls  │
     │ (state mgmt)│ │ (design) │ │ (execution) │
     └─────────────┘ └──────────┘ └─────────────┘
```

## Security Observations

| Finding | Severity | Confidence |
|---------|----------|------------|
| SwitchMode requires user approval — prevents silent mode escalation | `info` | `confirmed` |
| AskQuestion blocks agent execution until user responds — cannot be bypassed | `info` | `confirmed` |
| AiAttribution tracks all AI-written code — privacy consideration for shared repos | `low` | `likely` |
| TodoWrite has no access control — any agent turn can modify the task list | `info` | `confirmed` |

---

*Evidence: system prompt tool descriptions, protobuf types (SwitchModeArgs, AskQuestionArgs, UpdateTodosArgs, CreatePlanArgs, BlameByFilePathArgs, AiAttributionArgs), conversation categorization prompt*
