# File Tools — Read / Write / Edit (StrReplace) / Delete Internals

**Confidence:** `confirmed` — protobuf types, tool_limits_config, system prompt descriptions, ApplyAgentDiff

---

## Tool Family Overview

| Tool | Protobuf Types | Direction | Description |
|------|---------------|-----------|-------------|
| **Read** | ReadArgs, ReadResult, ReadToolCall | Read | Read file content with optional line range |
| **Write** | WriteArgs, WriteResult | Write | Create or overwrite entire file |
| **Edit** (StrReplace) | EditArgs, EditResult, EditToolCall | Write | Exact string replacement in existing file |
| **Delete** | DeleteArgs, DeleteResult, DeleteToolCall | Write | Remove a file |
| **ListDir** | ListDirArgs, ListDirResult, ListDirToolCall | Read | List directory contents |
| **ApplyAgentDiff** | ApplyAgentDiffArgs, ApplyAgentDiffResult | Write | Apply structured diffs |
| **Diagnostics** | DiagnosticsArgs, DiagnosticsResult | Read | Read linter errors |

## Read Tool

### How It Works

```
LLM emits: Read { path, offset?, limit? }
  │
  ├─ cursor-agent-exec receives ReadArgs
  │    │
  │    ├─ Validates path exists and is within workspace
  │    │   (workspace boundary enforcement)
  │    │
  │    ├─ Checks file size against limits:
  │    │   ├─ readFilesToolMaxFileSizeInBytes: 2,000,000 (2 MB)
  │    │   └─ readFileV2ToolMaxFileSizeInBytes: 200,000,000 (200 MB) for binary
  │    │
  │    ├─ Reads file via VSCode FileSystem API
  │    │   ├─ If offset/limit specified: read line range
  │    │   └─ If not: read entire file
  │    │
  │    ├─ Formats output with line numbers:
  │    │   "     1|first line content"
  │    │   "     2|second line content"
  │    │   (LINE_NUMBER is right-aligned, padded to 6 chars)
  │    │
  │    └─ Returns ReadResult with formatted content
  │
  └─ Supports: text files, images (jpeg/jpg, png, gif, webp), PDFs (auto-converted to text)
```

### Size Limits (from tool_limits_config)

| Limit | Value | Purpose |
|-------|-------|---------|
| `readFilesToolMaxFileSizeInBytes` | 2,000,000 (2 MB) | Standard text file read |
| `readFileV2ToolMaxFileSizeInBytes` | 200,000,000 (200 MB) | Binary/large file read |
| `fileSearchToolMaxResults` | 10 | Max search results |
| `listDirV2ClientSideCharacterBudget` | 1,000 | ListDir output truncation |

### Line Number Format

The output format `LINE_NUMBER|LINE_CONTENT` is metadata-only:
- LINE_NUMBER is 1-indexed
- Right-aligned, padded with spaces to 6 characters
- The `|` separator is NOT part of the file content
- The LLM is instructed to treat the prefix as metadata

### Image and PDF Support

Read can handle binary content:
- **Images:** jpeg/jpg, png, gif, webp — rendered as image content blocks
- **PDFs:** Auto-converted to text (subject to same character limits)
- **Empty files:** Returns "File is empty."

## Write Tool

### How It Works

```
LLM emits: Write { path, contents }
  │
  ├─ cursor-agent-exec receives WriteArgs
  │    │
  │    ├─ Path validation:
  │    │   ├─ Must be within workspace boundaries
  │    │   └─ Creates parent directories if needed
  │    │
  │    ├─ Writes file via VSCode FileSystem API
  │    │   └─ OVERWRITES entire file if it exists
  │    │
  │    └─ Returns WriteResult (success/failure)
  │
  └─ System prompt guardrails:
       ├─ "NEVER create files unless absolutely necessary"
       ├─ "ALWAYS prefer editing existing files"
       └─ "NEVER proactively create documentation files (*.md)"
```

Write is the bluntest tool — it replaces the entire file. The system prompt heavily discourages its use for editing (preferring StrReplace/Edit).

## Edit / StrReplace Tool

### How It Works

```
LLM emits: StrReplace { path, old_string, new_string, replace_all? }
  │
  ├─ cursor-agent-exec receives EditArgs
  │    │
  │    ├─ Validates file exists
  │    │
  │    ├─ Checks file size:
  │    │   └─ editFileToolMaxFileSizeInChars: 150,000
  │    │
  │    ├─ Searches for old_string in file content
  │    │   ├─ If NOT found → FAIL (error returned)
  │    │   ├─ If found MULTIPLE times and replace_all=false → FAIL
  │    │   │   (uniqueness requirement)
  │    │   ├─ If found once → replace with new_string
  │    │   └─ If replace_all=true → replace ALL occurrences
  │    │
  │    ├─ Applies the replacement
  │    │
  │    ├─ Computes diff:
  │    │   └─ composerDiffMaxComputationTimeMs: 2,000
  │    │       (diff computation is time-bounded!)
  │    │
  │    └─ Returns EditResult
  │
  └─ Key constraint: old_string must be EXACT match including whitespace/indentation
```

### The Uniqueness Requirement

This is a critical design choice:
- `old_string` must uniquely identify the target location
- If it appears more than once, the edit FAILS
- The LLM must include enough surrounding context to make it unique
- `replace_all=true` bypasses this for bulk renaming

### ApplyAgentDiff — The Structured Alternative

A separate tool `ApplyAgentDiff` (ApplyAgentDiffArgs/ApplyAgentDiffResult) exists for applying structured diffs. This is likely used for:
- Multi-hunk edits within a single file
- Computed diffs from the diff algorithm
- Background agent changes

### Diff Computation

The `composerDiffMaxComputationTimeMs: 2,000` limit means:
- After an edit, the system computes a diff for the UI
- If diff computation takes >2 seconds, it's aborted
- This prevents UI freezes on large file edits

## Delete Tool

### How It Works

```
LLM emits: Delete { path }
  │
  ├─ cursor-agent-exec receives DeleteArgs
  │    │
  │    ├─ Path validation (workspace boundaries)
  │    │
  │    ├─ Graceful failure handling:
  │    │   ├─ File doesn't exist → no error
  │    │   ├─ Security rejection → no error
  │    │   └─ Cannot delete → no error
  │    │
  │    └─ Returns DeleteResult
```

Delete is intentionally designed to fail silently — it "fails gracefully" in all error cases.

## ListDir Tool

### How It Works

```
LLM emits: ListDir { path }
  │
  ├─ cursor-agent-exec receives ListDirArgs
  │    │
  │    ├─ Lists directory contents
  │    │
  │    ├─ Client-side truncation:
  │    │   └─ listDirV2ClientSideCharacterBudget: 1,000 chars
  │    │
  │    ├─ Predefined ignore globs:
  │    │   ├─ **/node_modules/*
  │    │   ├─ **/__pycache__/*
  │    │   └─ **/.*
  │    │
  │    └─ Returns ListDirResult (truncated to budget)
```

The 1,000 character budget is aggressive — for large directories, most entries are hidden. The ignore globs filter out noise automatically.

## Diagnostics Tool (ReadLints)

### How It Works

```
LLM emits: Diagnostics { paths? }
  │
  ├─ cursor-agent-exec receives DiagnosticsArgs
  │    │
  │    ├─ If paths provided → get diagnostics for those files
  │    ├─ If directory → get diagnostics for all files in directory
  │    └─ If empty → get diagnostics for ALL workspace files
  │    │
  │    ├─ Reads from VSCode's diagnostic collection
  │    │   (TypeScript errors, ESLint, etc.)
  │    │
  │    └─ Returns DiagnosticsResult
  │
  └─ Warning: "can return linter errors that were already present before your edits"
```

## File Operation Pipeline (Combined)

```
                    ┌─────────────┐
                    │ Path Input  │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Workspace  │ ← Are we inside workspace boundaries?
                    │  Boundary   │
                    │  Check      │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Size/Limit │ ← 2MB read, 150K edit, 1K listdir
                    │  Validation │
                    └──────┬──────┘
                           │
               ┌───────────┼───────────┐
               │           │           │
        ┌──────▼──┐  ┌─────▼────┐ ┌───▼────┐
        │  Read   │  │  Write/  │ │ Delete │
        │ (VSCode │  │  Edit    │ │ (soft  │
        │  FS API)│  │  (VSCode │ │  fail) │
        └────┬────┘  │  FS API) │ └───┬────┘
             │       └────┬─────┘     │
             │            │           │
        ┌────▼────┐  ┌────▼─────┐    │
        │ Format  │  │  Diff    │    │
        │ (line   │  │  Compute │    │
        │ numbers)│  │  (≤2s)   │    │
        └────┬────┘  └────┬─────┘    │
             │            │           │
             └────────────┼───────────┘
                          │
                   ┌──────▼──────┐
                   │   Result    │
                   │  (to LLM)  │
                   └─────────────┘
```

## Security Observations

| Finding | Severity | Confidence |
|---------|----------|------------|
| Workspace boundary enforcement is the primary security layer for file ops | `info` | `confirmed` |
| 150K char edit limit prevents memory bombs but still allows large modifications | `low` | `confirmed` |
| Delete tool's silent failure mode means the LLM may not know a delete failed | `low` | `confirmed` |
| No content-based validation — any file content can be written (secrets, scripts, etc.) | `medium` | `likely` |
| ListDir's 1K char budget heavily truncates output — may cause LLM to miss important files | `info` | `confirmed` |

---

*Evidence: tool_limits_config (Statsig), system prompt tool descriptions, protobuf types (ReadArgs, WriteArgs, EditArgs, DeleteArgs, ListDirArgs, DiagnosticsArgs, ApplyAgentDiffArgs), chatConfig (listDirV2PredefinedIgnoreGlobs)*
