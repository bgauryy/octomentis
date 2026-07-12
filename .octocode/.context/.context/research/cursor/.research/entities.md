# Entities — Cursor v3.0.16

## Extensions (Cursor-specific business objects)

### cursor-agent
- **Role:** Cursor agent extension — core agent framework
- **Activation:** `*` (immediate)
- **API proposals:** `control`, `cursor`, `cursorTracing`
- **Key:** Houses Claude Agent SDK (cli.js, WASM binaries, ripgrep)

### cursor-agent-exec
- **Role:** Agent execution capabilities — commands, files, tools with user permissions
- **Activation:** `*` (immediate)
- **API proposals:** `control`, `cursor`, `cursorTracing`
- **Key:** Canvas runtime for agent-authored UI, agent-sdk TypeScript declarations

### cursor-always-local
- **Role:** Experimentation features, feature flags, client-side AI operations
- **Activation:** `onStartupFinished`, `onResolveRemoteAuthority:background-composer`
- **API proposals:** `cursor`, `control`, `externalUriOpener`, `contribSourceControlInputBoxMenu`
- **Contributes:** Git commit message generation command, environment.json schema validation

### cursor-retrieval
- **Role:** Code indexing and retrieval (codebase search, grep client)
- **Activation:** `onStartupFinished`
- **API proposals:** `control`, `cursor`, `cursorTracing`, `textSearchProvider2`
- **Contributes:** grep debug, codebase snapshot commands, `.cursorignore` / `.cursorindexingignore` language support, GitHub login for retrieval augmentation

### cursor-mcp
- **Role:** Model Context Protocol handler
- **Activation:** `onStartupFinished`, `onUri`
- **API proposals:** `control`, `cursor`, `cursorTracing`

### cursor-commits
- **Role:** Request and commit tracking for online metrics
- **Activation:** `onStartupFinished`
- **Kind:** `workspace`
- **Depends on:** `vscode.git`

### cursor-browser-automation
- **Role:** MCP server for browser automation
- **Activation:** `onStartupFinished`
- **Kind:** `ui`
- **API proposals:** `control`, `cursor`, `cursorTracing`

### cursor-shadow-workspace
- **Role:** Shadow workspace for background AI operations
- **Activation:** `onStartupFinished`
- **Kind:** `workspace`

### cursor-deeplink
- **Role:** Deep-link URI handler
- **Activation:** `onStartupFinished`
- **Contributes:** Debug arbitrary deeplink command

### cursor-resolver + cursor-resolver-helper
- **Role:** Background composer remote authority resolution + connection tokens
- **Activation:** `onResolveRemoteAuthority:background-composer`
- **Key:** Handles `background-composer+*` remote authority scheme, cloud-agent workspace labeling

### cursor-socket
- **Role:** TCP/TLS socket provider for extensions
- **Activation:** `onResolveRemoteAuthority:background-composer`, `onStartupFinished`

### cursor-ndjson-ingest
- **Role:** HTTP server for ingesting NDJSON logs to `.cursor/debug.log`
- **Activation:** On-demand commands
- **Config:** Port (7242-7942 range), bind address (default 127.0.0.1)

### cursor-explorer
- **Role:** Workspace explorer extension
- **Kind:** `workspace`

### cursor-checkout
- **Role:** Checkout provider for branch migration operations

### cursor-file-service
- **Role:** Stub for indexing/retrieval (367 bytes, likely delegated to cursor-retrieval)

### cursor-polyfills-remote
- **Role:** Polyfills for workspace extension host

### cursor-worktree-textmate
- **Role:** TextMate-only syntax highlighting for `.cursor/worktrees` files
- **Languages:** 27 worktree-prefixed language variants (TS, JS, Python, Go, Rust, etc.)

## AI Chain-of-Thought Entities (from extension host)
- `opus2ChainPlan` — Planning chain
- `opus2ChainApplyPlan` — Plan application chain
- `opus2ChainReflect` — Reflection chain
- `opusChainGetFilePaths` — File path retrieval chain
- `opusChainGetPlan` — Plan generation chain
- `opusChainGetFileInstruction` — File instruction chain
- `opusChainReflect` — Single reflection chain
- `claude_code_hooks_enabled` — Feature flag for Claude Code hooks
- `claude_plugins_root_scan` — Plugin root scanning

## Product Configuration Entities (from product.json)
- `statsigClientKey` — Client-side feature flag key
- `statsigLogEventProxyUrl` — `https://api3.cursor.sh/tev1/v1`
- `extensionReplacementMapForImports` — Maps MS extensions to Anysphere forks
- `extensionMaxVersions` — Version constraints for specific extensions
- `aiConfig.ariaKey` — `control-key` (Application Insights)
