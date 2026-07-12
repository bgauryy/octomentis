# Search Tools — Grep / Glob / SemanticSearch Internals

**Confidence:** `confirmed` — protobuf types, system prompt descriptions, Claude Agent SDK vendor binaries, retrieval extension

---

## Tool Family Overview

| Tool | Protobuf Types | Backend | Purpose |
|------|---------------|---------|---------|
| **Grep** | GrepArgs, GrepResult, GrepToolCall | Bundled ripgrep binary | Regex pattern search in file contents |
| **Glob** | GlobToolArgs, GlobToolResult, GlobToolCall | Node.js glob library | Find files by name pattern |
| **SemanticSearch** | (not in protobuf — server-side) | cursor-retrieval index | Meaning-based code search |
| **WebSearch** | WebSearchArgs, WebSearchResult, WebSearchToolCall | Server-side API | Web search |
| **WebFetch** | WebFetchArgs, WebFetchResult, WebFetchToolCall | Server-side proxy | Fetch URL content |

## Grep Tool (ripgrep)

### Architecture

Cursor bundles its own ripgrep binary inside the Claude Agent SDK:

```
extensions/cursor-agent/dist/claude-agent-sdk/
├── cli.js                           (11 MB — main SDK bundle)
├── vendor/
│   ├── rg-arm64-darwin              (ripgrep for Apple Silicon)
│   ├── rg-x64-darwin               (ripgrep for Intel Mac)
│   ├── tree-sitter-bash.wasm       (bash parser)
│   ├── tree-sitter.wasm            (tree-sitter runtime)
│   └── resvg.wasm                  (SVG renderer)
```

The bundled ripgrep is the SAME binary used by the `_search.runRipgrepRaw` internal command.

### How It Works

```
LLM emits: Grep { pattern, path?, glob?, type?, output_mode?, ... }
  │
  ├─ cursor-agent-exec receives GrepArgs
  │    │
  │    ├─ Constructs ripgrep command:
  │    │   rg <pattern> [--glob <glob>] [--type <type>]
  │    │      [-A <after>] [-B <before>] [-C <context>]
  │    │      [-i] [--multiline] [--multiline-dotall]
  │    │      [-- <path>]
  │    │
  │    ├─ Executes bundled ripgrep binary directly
  │    │   (NOT through shell — direct process spawn)
  │    │
  │    ├─ Parses ripgrep output
  │    │
  │    ├─ Applies output_mode:
  │    │   ├─ "content"            → matching lines with context
  │    │   ├─ "files_with_matches" → file paths only
  │    │   └─ "count"             → match counts per file
  │    │
  │    ├─ Applies head_limit/offset for pagination
  │    │
  │    ├─ Caps output at ~several thousand lines
  │    │   (reports "at least" counts when truncated)
  │    │
  │    └─ Returns GrepResult
  │
  └─ Key parameters:
       ├─ pattern: ripgrep regex (NOT grep — e.g., literal braces need escaping)
       ├─ glob: filter files (e.g., "*.js", "*.{ts,tsx}")
       ├─ type: file type shortcut (e.g., "js", "py", "rust")
       ├─ multiline: enables . matching newlines + cross-line patterns
       ├─ -A/-B/-C: context lines after/before/around matches
       ├─ -i: case insensitive
       ├─ head_limit: max matches/files returned
       └─ offset: skip first N results (pagination)
```

### Output Format

Follows ripgrep output format closely:
- `-` prefix for context lines
- `:` prefix for match lines
- Results grouped by file
- When truncated: "at least N matches found"

### Important Behavioral Detail

The system prompt warns:
> "ALWAYS USE ripgrep at rg first" — the Grep tool IS ripgrep, not GNU grep

Pattern syntax differences from grep:
- Uses Rust regex syntax
- Literal braces need escaping: `interface\{\}` to find `interface{}`
- Multiline requires explicit opt-in flag

## Glob Tool

### How It Works

```
LLM emits: Glob { glob_pattern, target_directory? }
  │
  ├─ cursor-agent-exec receives GlobToolArgs
  │    │
  │    ├─ Pattern auto-prepend:
  │    │   If pattern doesn't start with "**/" → prepend "**/"
  │    │   e.g., "*.js" becomes "**/*.js" for recursive search
  │    │
  │    ├─ Executes glob matching
  │    │   (likely via fast-glob or similar Node.js library)
  │    │
  │    ├─ Sorts results by modification time
  │    │   (most recently modified first)
  │    │
  │    └─ Returns GlobToolResult with matching file paths
  │
  └─ Examples:
       "*.js"              → finds all .js files recursively
       "**/node_modules/**" → finds all node_modules
       "**/test/**/test_*.ts" → finds test files in test dirs
```

### Key Design Choice: mtime Sorting

Results are sorted by **modification time** (newest first), not alphabetically. This is intentional for agent workflows — recently changed files are more likely to be relevant.

## SemanticSearch

### Architecture

SemanticSearch is backed by the `cursor-retrieval` extension:

```
cursor-retrieval extension
  ├─ Code indexing on startup
  │   ├─ Respects .cursorignore / .cursorindexingignore
  │   ├─ Max files: 250,000 (absoluteMaxNumberFiles)
  │   ├─ Indexing period: every 307 seconds
  │   └─ Incremental indexing enabled
  │
  ├─ Builds semantic vector index
  │   ├─ Encryption keys for paths:
  │   │   user: "A4fghm4YFBGZbbQLv9CJqMy7uYkm4MkyAxpHIeHHCnc"
  │   │   team: "2TcEvyI9TK9PZYvesg3g6fXuo6jkIvKb37OyyfAG_0Y"
  │   │
  │   └─ Uploads to server for indexing:
  │       maxConcurrentUploads: 64
  │       maxBatchBytes: 2,097,152 (2 MB)
  │       maxBatchNumRequests: 20
  │
  └─ Provides text search via textSearchProvider2 API proposal
```

### How It Works

```
LLM emits: SemanticSearch { query, target_directories?, num_results? }
  │
  ├─ NOT a simple text search — this is EMBEDDING-BASED
  │    │
  │    ├─ Query is a natural language question:
  │    │   "How does user authentication work?"
  │    │   "Where are websocket connections handled?"
  │    │
  │    ├─ target_directories: single path or [] for whole repo
  │    │   NO globs, NO multiple paths
  │    │
  │    ├─ Server-side:
  │    │   ├─ Embeds the query text
  │    │   ├─ Searches the semantic index built by cursor-retrieval
  │    │   ├─ Returns ranked chunks with relevance scores
  │    │   └─ num_results capped at 15
  │    │
  │    └─ Returns chunk contents or chunk signatures
  │         ├─ Full chunks: actual code content
  │         └─ Signatures: class/function signatures (compact form)
```

### Indexing Pipeline

```
Workspace files
  → cursor-retrieval scans on startup
  → Filters: .cursorignore, .cursorindexingignore, size limits
  → Path encryption (user/team keys)
  → Batch upload to api2.cursor.sh
  → Server builds vector index
  → Incremental sync every 307 seconds
  → Git indexing: DISABLED (gitIndexingConfig.enabled: false)
```

### The Indexing Budget

| Limit | Value |
|-------|-------|
| Max files indexed | 250,000 |
| Max concurrent uploads | 64 |
| Max batch size | 2 MB |
| Sync period | 307 seconds |
| Copy timeout | 3,600 seconds |
| Max file retries | 30 |

## WebFetch Tool

### How It Works

```
LLM emits: WebFetch { url }
  │
  ├─ cursor-agent-exec receives WebFetchArgs
  │    │
  │    ├─ Validates URL:
  │    │   ├─ Must be fully-formed, valid URL
  │    │   ├─ No localhost / private IPs (runs from isolated server)
  │    │   ├─ No authentication support
  │    │   ├─ No binary content (no media/PDFs)
  │    │   └─ Must return 200 status
  │    │
  │    ├─ Fetches via server-side proxy (NOT from client)
  │    │   └─ May return cached content
  │    │
  │    ├─ Converts HTML → markdown
  │    │
  │    └─ Returns WebFetchResult
```

### Key Detail: Server-Side Execution

WebFetch runs from an **isolated server**, not the user's machine:
- localhost and private IPs don't work
- User's network/cookies/auth are NOT available
- Content may be cached

## Search Strategy from System Prompt

The system prompt instructs specific search strategies:

```
Search tool preference order:
1. Grep — when you know exact symbols/strings
2. Glob — when you need files by name pattern
3. SemanticSearch — when searching by meaning, not text
4. Shell (rg) — NEVER use shell grep; use Grep tool instead
5. Shell (find) — NEVER use shell find; use Glob tool instead
```

## Security Observations

| Finding | Severity | Confidence |
|---------|----------|------------|
| Codebase is uploaded to Cursor servers for semantic indexing with path encryption | `medium` | `confirmed` |
| Path encryption keys are hardcoded in server config (shared across users?) | `medium` | `confirmed` |
| WebFetch runs from isolated server — prevents SSRF against local network | `info` | `confirmed` |
| Ripgrep executes as direct process spawn, not through shell — prevents injection | `info` | `confirmed` |
| 250K file indexing limit + 2MB batch size = bounded upload surface | `low` | `confirmed` |

---

*Evidence: Claude Agent SDK vendor directory (ripgrep binaries), cursor-retrieval extension manifest, server_config.json (indexingConfig), system prompt tool descriptions, protobuf types (GrepArgs, GlobToolArgs, WebFetchArgs, WebSearchArgs)*
