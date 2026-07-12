# Bundle Overview — Cursor v3.0.16

## Identification

| Property | Value |
|----------|-------|
| App name | Cursor |
| Version | 3.0.16 |
| Distro hash | d5c0e77a0214208f36b56d42e8e787de88d02ea4 |
| VSCode base | 1.105.1 |
| Author | Anysphere, Inc. |
| Main entry | `./out/main.js` (ES module) |
| Electron app | macOS `.app` bundle |
| Package manager | npm 1.10.4 |

## Execution Model

### Entry Points
1. **Main process** → `core/out/main.js` (1.3 MB) — Electron main, window management, gRPC client
2. **Workbench** → `core/out/vs/workbench/workbench.desktop.main.js` (54 MB) — Full UI, webpack bundle with `__webpack_require__`
3. **Extension Host (Node)** → `core/out/vs/workbench/api/node/extensionHostProcess.js` (4.8 MB) — Runs extensions server-side
4. **Extension Host (Worker)** → `core/out/vs/workbench/api/worker/extensionHostWorkerMain.js` (4.5 MB) — Runs extensions in web worker
5. **Shared Process** → `core/out/vs/code/electron-utility/sharedProcess/sharedProcessMain.js` (1.0 MB) — Background services
6. **CLI** → `core/out/cli.js` (210 KB) — Command-line interface
7. **Bootstrap** → `core/out/bootstrap-fork.js` (19 KB) — Process forking utility

### Runtime Markers
- Webpack bootstrap: Only in `workbench.desktop.main.js`
- ES Modules: `"type": "module"` in package.json
- No parcel/browserify/systemjs markers detected

## Structure

### Core (`core/`)
```
core/
├── bin/                          # Shell scripts
│   ├── code                      # VSCode CLI entry
│   ├── cursor                    # Cursor CLI entry
│   └── cursor-tunnel             # Remote tunnel binary
├── out/
│   ├── main.js                   # Electron main process (1.3 MB)
│   ├── cli.js                    # CLI process (210 KB)
│   ├── bootstrap-fork.js         # Process forking (19 KB)
│   ├── nls.keys.json             # NLS translation keys (463 KB)
│   ├── nls.messages.json         # NLS translation strings (724 KB)
│   ├── media/                    # Icons, fonts, images
│   ├── vscode-dts/               # API type definitions (vscode.d.ts)
│   └── vs/
│       ├── workbench/
│       │   ├── workbench.desktop.main.js    # MAIN BUNDLE (54 MB)
│       │   ├── workbench.desktop.main.css   # Styles
│       │   ├── api/node/extensionHostProcess.js  # Extension host (4.8 MB)
│       │   ├── api/worker/extensionHostWorkerMain.js  # Worker host (4.5 MB)
│       │   └── contrib/                     # Feature contributions
│       ├── code/
│       │   ├── electron-sandbox/workbench/  # Workbench HTML loader
│       │   ├── electron-utility/sharedProcess/  # Shared process
│       │   └── node/cliProcessMain.js       # CLI main
│       ├── editor/                          # Editor services
│       ├── platform/                        # Platform services (terminal, files, profiling)
│       └── base/                            # Sandbox preloads
```

### Extensions (`extensions/`)

| Extension | Size | Role |
|-----------|------|------|
| cursor-agent | 40 MB | Agent framework + Claude Agent SDK (11 MB cli.js + WASM binaries) |
| cursor-agent-exec | 4.8 MB | Agent execution (commands, files, tools) + Canvas runtime |
| cursor-retrieval | 4.6 MB | Code indexing and retrieval (codebase search) |
| cursor-always-local | 4.1 MB | Experimentation, feature flags, client-side AI |
| cursor-mcp | 2.8 MB | MCP (Model Context Protocol) integration |
| cursor-resolver-helper | 2.7 MB | Connection token provider for remote authority |
| cursor-commits | 2.4 MB | Git commit tracking, online metrics |
| cursor-browser-automation | 1.6 MB | MCP server for browser automation (Playwright) |
| cursor-shadow-workspace | 1.2 MB | Shadow workspace for background operations |
| cursor-deeplink | 898 KB | URI deep-link handler |
| cursor-polyfills-remote | 101 KB | Workspace polyfills |
| cursor-resolver | 98 KB | Background composer remote authority resolver |
| cursor-ndjson-ingest | 18 KB | NDJSON log ingestion server |
| cursor-explorer | 16 KB | Workspace explorer |
| cursor-socket | 11 KB | TCP/TLS socket provider |
| cursor-checkout | 9 KB | Branch migration checkout provider |
| cursor-file-service | 367 B | Indexing/retrieval stub |
| cursor-worktree-textmate | N/A | TextMate syntax for worktree files (27 grammars) |

### Config (`config/`)
- `package.json` — App identity
- `product.json` — Product configuration (57 KB) — URLs, extension mappings, API keys
- `policies/` — macOS MDM policy templates

## Enabled API Proposals (Cursor-specific)
From extension manifests:
- `cursor` — Core Cursor API (most extensions)
- `cursorNoDeps` — Cursor API without dependencies
- `cursorPublic` — Public Cursor API
- `cursorTracing` — Cursor tracing/telemetry API
- `control` — Extension control API
- `resolvers` — Remote resolver API
- `externalUriOpener` — External URI handler
- `contribSourceControlInputBoxMenu` — SCM input box menu
- `textSearchProvider2` — Custom text search provider

## Dependencies / Vendor
- Claude Agent SDK `@anthropic-ai/claude-agent-sdk@0.2.70` (Claude Code v2.1.70)
- Bundled ripgrep (arm64-darwin, x64-darwin)
- Tree-sitter WASM (bash parser)
- resvg WASM (SVG rendering)
- Canvas runtime (React-based)
- `@apm-js-collab/code-transformer` (3.3 MB) — code transformation WASM

## Obfuscation Assessment
- **None.** Standard minification only.
- No string arrays, no eval packing, no control-flow flattening
- Short identifiers from Terser/esbuild minification
- All readable with standard JS beautification
