# Execution Flows — Cursor v3.0.16

## Application Startup Flow

```
Cursor.app binary (MacOS/Cursor)
  → Electron main process
    → core/out/main.js (ES module entry)
      → Window creation
      → workbench.html loads workbench.js
        → workbench.desktop.main.js (54 MB webpack bundle)
      → Extension host process fork
        → extensionHostProcess.js (4.8 MB)
          → Activates cursor-* extensions
      → Shared process
        → sharedProcessMain.js
```

## Extension Activation Flow

All `cursor-*` extensions with `activationEvents: ["*"]` are activated immediately:
1. `cursor-agent` — Agent framework
2. `cursor-agent-exec` — Agent execution
3. `cursor-polyfills-remote` — Polyfills
4. `cursor-checkout` — Branch migration

Extensions with `onStartupFinished`:
5. `cursor-always-local` — Experimentation
6. `cursor-browser-automation` — Browser MCP
7. `cursor-commits` — Commit tracking
8. `cursor-deeplink` — URI handling
9. `cursor-explorer` — Workspace explorer
10. `cursor-mcp` — MCP protocol
11. `cursor-retrieval` — Code indexing
12. `cursor-resolver-helper` — Connection tokens
13. `cursor-shadow-workspace` — Shadow workspace
14. `cursor-socket` — TCP/TLS sockets

On-demand activation:
15. `cursor-ndjson-ingest` — On specific commands only

Background composer authority:
16. `cursor-resolver` — On remote authority resolution
17. `cursor-resolver-helper` — On remote authority resolution
18. `cursor-socket` — On remote authority resolution

## Agent Execution Flow

```
User prompt (chat/composer)
  → workbench.desktop.main.js (AI chat UI)
    → gRPC to api2.cursor.sh
    → Response with tool calls
      → cursor-agent processes agent messages
        → cursor-agent-exec handles execution
          → File operations (read/write/edit)
          → Command execution (with user approval)
          → Tool invocation
          → Canvas rendering (React components)
```

## Claude Agent SDK Flow (cursor-agent)

```
cursor-agent extension
  → Loads @anthropic-ai/claude-agent-sdk@0.2.70
    → cli.js (11 MB)
    → Vendor: ripgrep, tree-sitter, resvg
  → Provides agent primitives
    → File reading/writing
    → Command execution
    → Tool use (with MCP)
    → Canvas creation
```

## Chain-of-Thought Flows (from extension host)

### Plan → Apply → Reflect
```
opusChainGetPlan → opus2ChainPlan
  → opusChainGetFilePaths
    → opusChainGetFileInstruction
      → opus2ChainApplyPlan
        → opus2ChainReflect / opusChainReflect
```

## MCP Flow

```
cursor-mcp extension
  → MCP server implementation
  → Handles onUri activation
  → Provides tool definitions to agents
  → cursor-browser-automation registers as MCP server
```

## Remote Resolution Flow (Background Composer)

```
Remote authority: background-composer+*
  → cursor-resolver resolves authority
  → cursor-resolver-helper provides connection tokens
  → cursor-socket provides TCP/TLS transport
  → Workspace labeled as "cloud-agent"
```

## Retrieval/Indexing Flow

```
cursor-retrieval
  → Code indexing on startup
  → .cursorignore / .cursorindexingignore support
  → Grep client for code search
  → GitHub login augmentation (optional)
  → Codebase snapshot capability
```

## Commit Tracking Flow

```
cursor-commits
  → Depends on vscode.git
  → Tracks requests and commits
  → Reports to online metrics
  → Worker: extensions/cursor-commits/worker/dist/main.js
```
