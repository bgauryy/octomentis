# Cursor.app v3.0.16 — Master Research Document

**Target:** `/Applications/Cursor.app` → extracted to `research/cursor/`
**Version:** 3.0.16 (Anysphere, Inc.) — based on VSCode 1.105.1
**Date:** 2026-04-14
**Method:** Full file extraction + static analysis of minified JS bundles

## Executive Summary

Cursor is an Electron app forked from VSCode with a proprietary AI layer. The app consists of:
- A **54 MB main workbench bundle** (webpack-bundled, minified, no obfuscation)
- **18 cursor-specific extensions** providing agent execution, MCP, retrieval, commits, and browser automation
- An embedded **Claude Agent SDK** (`@anthropic-ai/claude-agent-sdk@0.2.70`) with its own bundled ripgrep, tree-sitter, and resvg
- A **Canvas runtime** (React-based) for agent-authored UI canvases
- Extensive gRPC API surface for AI server communication

No obfuscation was detected — standard webpack minification + Terser throughout.

## Key Findings

### Architecture
| Component | Path (relative to research/cursor/) | Size |
|-----------|-------------------------------------|------|
| Workbench (main UI) | `core/out/vs/workbench/workbench.desktop.main.js` | 54 MB |
| Main process (Electron) | `core/out/main.js` | 1.3 MB |
| CLI | `core/out/cli.js` | 210 KB |
| Extension host (Node) | `core/out/vs/workbench/api/node/extensionHostProcess.js` | 4.8 MB |
| Extension host (Worker) | `core/out/vs/workbench/api/worker/extensionHostWorkerMain.js` | 4.5 MB |
| Shared process | `core/out/vs/code/electron-utility/sharedProcess/sharedProcessMain.js` | 1.0 MB |
| Claude Agent SDK | `extensions/cursor-agent/dist/claude-agent-sdk/cli.js` | 11 MB |
| cursor-agent-exec | `extensions/cursor-agent-exec/dist/main.js` | 4.8 MB |
| cursor-retrieval | `extensions/cursor-retrieval/dist/main.js` | 4.6 MB |
| cursor-agent | `extensions/cursor-agent/dist/main.js` | 4.1 MB |
| cursor-always-local | `extensions/cursor-always-local/dist/main.js` | 4.1 MB |
| cursor-mcp | `extensions/cursor-mcp/dist/main.js` | 2.8 MB |
| cursor-resolver-helper | `extensions/cursor-resolver-helper/dist/main.js` | 2.7 MB |
| cursor-commits | `extensions/cursor-commits/dist/main.js` | 2.4 MB |
| cursor-browser-automation | `extensions/cursor-browser-automation/dist/extension.js` | 1.6 MB |
| cursor-shadow-workspace | `extensions/cursor-shadow-workspace/dist/extension.js` | 1.2 MB |
| cursor-deeplink | `extensions/cursor-deeplink/dist/main.js` | 898 KB |

### Bundler & Obfuscation
- **Bundler:** Webpack (only `workbench.desktop.main.js` uses `__webpack_require__`)
- **Extensions:** esbuild/webpack bundles, standard minification
- **Obfuscation:** None detected — no `_0x` arrays, no control-flow flattening, no eval packing
- **Source maps:** None shipped (no `sourceMappingURL` references)

### AI Model References (from workbench bundle)
- Claude 3 family: `claude-3-haiku-20240307`, `claude-3-opus-20240229`, `claude-3-sonnet-20240229`
- Claude 3.5/3.7: `claude-3.5-sonnet`, `claude-3.7-sonnet`, `claude-3.7-sonnet-finetuned-cursor-20250514-v1`
- Claude 4 family: `claude-4-sonnet`, `claude-4-opus`, `claude-4-5-sonnet-20250929`, `claude-4.5-haiku`, `claude-4.5-sonnet`, `claude-4.5-opus-high`, `claude-4.5-opus-high-thinking`, `claude-4.6-opus-high-fast`
- GPT references: `gpt`, `gpt4Requests`, `gpt5`
- Chain-of-thought: `opus2ChainPlan`, `opus2ChainApplyPlan`, `opus2ChainReflect`, `opusChainGetFilePaths`, `opusChainGetPlan`

### Cursor API Endpoints
- `https://api2.cursor.sh` — Main API server (gRPC, analytics)
- `https://api3.cursor.sh` — Telemetry/stats proxy
- `https://marketplace.cursor.sh/` — Extension marketplace
- `https://marketplace.cursorapi.com/` — Fallback marketplace
- `https://staging-marketplace.cursor.sh/` — Staging marketplace
- `https://cursor.com/privacy` — Privacy policy
- `https://cursor.com/security` — Security page
- `https://cursor.blob.core.windows.net/` — Update/download CDN

### Claude Agent SDK
- Package: `@anthropic-ai/claude-agent-sdk@0.2.70`
- Claude Code Version: `2.1.70`
- CLI bundle: 11 MB webpack bundle
- Vendor binaries: ripgrep (arm64-darwin + x64-darwin), tree-sitter-bash.wasm, tree-sitter.wasm, resvg.wasm
- Peer dependency: `zod@^4.0.0`

### Canvas System (cursor-agent-exec)
- Agent SDK package: `cursor` (private, v0.0.0)
- Exports: `./canvas` with TypeScript declarations
- Types: `canvas-tokens.d.ts`, `chart-primitives.d.ts`, `ui-primitives.d.ts`, `theme.d.ts`
- Canvas runtime: ESM bundle for agent-authored React UI canvases

## Feature Map

| Feature | Primary Location | Docs |
|---------|-----------------|------|
| AI Chat/Compose | `workbench.desktop.main.js` | `overview.md#composer` |
| Agent Execution | `cursor-agent/dist/main.js`, `cursor-agent-exec/dist/main.js` | |
| Claude Code Integration | `cursor-agent/dist/claude-agent-sdk/cli.js` | |
| MCP (Model Context Protocol) | `cursor-mcp/dist/main.js` | |
| Code Retrieval/Indexing | `cursor-retrieval/dist/main.js` | |
| Git Commit Tracking | `cursor-commits/dist/main.js` | |
| Browser Automation | `cursor-browser-automation/dist/extension.js` | |
| Shadow Workspace | `cursor-shadow-workspace/dist/extension.js` | |
| Deeplinks | `cursor-deeplink/dist/main.js` | |
| Remote Resolution | `cursor-resolver/dist/main.js`, `cursor-resolver-helper/dist/main.js` | |
| Experimentation | `cursor-always-local/dist/main.js` | |
| Worktree Syntax | `cursor-worktree-textmate/syntaxes/` | |
| System Prompts | `prompts/` (13 extracted) | `prompts/README.md` |
| Canvas (Agent UI) | `cursor-agent-exec/dist/canvas-runtime/`, `agent-sdk/cursor/canvas/` | |

## References

- [overview.md](overview.md) — Bundle structure, entry points
- [flows.md](flows.md) — Execution flows, call traces
- [strings.md](strings.md) — URLs, tokens, high-signal strings
- [entities.md](entities.md) — Business objects, globals
- [paths.md](paths.md) — Explored regions, reflections
- `../docs/` — Prior security audit (v3.0.12)
- `../prompts/` — Extracted system prompts (13 files)
