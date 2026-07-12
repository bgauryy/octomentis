# Cursor.app Architecture Overview

## Identity

- **Name:** Cursor
- **Version:** 3.0.12
- **Publisher:** Anysphere, Inc.
- **Distro hash:** d5c0e77a0214208f36b56d42e8e787de88d02ea4
- **Base:** VSCode (Electron)
- **Entry:** `out/main.js` (ESM)
- **Type:** module

## Bundle Map

| File | Size | Purpose |
|------|------|---------|
| `out/main.js` | 1.3 MB | Electron main process |
| `out/vs/workbench/workbench.desktop.main.js` | 54 MB | Workbench (UI + all features) |
| `out/vs/workbench/api/node/extensionHostProcess.js` | 4.8 MB | Extension host (Node) |
| `out/vs/workbench/api/worker/extensionHostWorkerMain.js` | 4.4 MB | Extension host (Worker) |
| `out/vs/code/electron-utility/sharedProcess/sharedProcessMain.js` | 1.0 MB | Shared process |
| `out/cli.js` | 206 KB | CLI |
| `out/bootstrap-fork.js` | 19 KB | Process fork bootstrap |

## Bundler / Runtime

- Rollup-style bundler (VSCode custom build pipeline)
- Module format: Wrapped IIFE modules with `we()` factory pattern
- Path convention: `out-build/` prefixed module IDs
- No source maps shipped
- Terser minification with mangled identifiers

## Cursor-Specific Extensions (19)

| Extension | Description |
|-----------|-------------|
| `cursor-agent` | Agent core (11MB Claude SDK bundled) |
| `cursor-agent-exec` | Agent command execution with user approval |
| `cursor-always-local` | Experimentation features |
| `cursor-browser-automation` | MCP server for browser automation |
| `cursor-checkout` | Branch migration |
| `cursor-commits` | Online metrics tracking |
| `cursor-deeplink` | URI deep linking |
| `cursor-explorer` | Workspace explorer |
| `cursor-file-service` | File service |
| `cursor-mcp` | MCP integration |
| `cursor-ndjson-ingest` | NDJSON ingestion |
| `cursor-polyfills-remote` | Remote polyfills |
| `cursor-resolver` | Remote resolver |
| `cursor-resolver-helper` | Resolver helper |
| `cursor-retrieval` | Codebase retrieval (4.4MB + 224KB worker) |
| `cursor-shadow-workspace` | Shadow workspace |
| `cursor-socket` | Socket communication |
| `cursor-worktree-textmate` | TextMate grammar for worktrees |
| `theme-cursor` | Cursor theme |

## AI Model Configuration

```
Default models by feature:
- composer: "default" (bestOfN: composer-1, claude-4.5-opus-high, gpt-5.1-codex)
- cmdK: "default"
- backgroundComposer: "default"
- planExecution: "default"
- spec: "default"
- deepSearch: "default"
- quickAgent: "default"
```

## Electron Security Configuration

| Setting | Value | Assessment |
|---------|-------|------------|
| sandbox | true | GOOD |
| contextIsolation | true | GOOD |
| nodeIntegration | false | GOOD |
| webviewTag | false | GOOD |
| enablePreferredSizeMode | false | GOOD |
| enableWebSQL | false | GOOD |

## Node Dependencies

- 337 packages in `node_modules/`
- Key scoped packages: `@anysphere`, `@sentry`, `@opentelemetry`, `@bufbuild`, `@connectrpc`
- Notable: `@sentry/browser`, `@sentry/core`, `@sentry/electron`, `@sentry/node`, `@sentry/node-core`
- gRPC via `@bufbuild` and `@connectrpc` (Connect protocol)

## gRPC Services (70+)

See findings.md F10 for complete service list.
