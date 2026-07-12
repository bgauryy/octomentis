# Codex.app — Bundle Overview

## Identification

| Field | Value |
|-------|-------|
| Path | `/Applications/Codex.app` |
| Bundle ID | `com.openai.codex` |
| Version | 26.325.31654 (build 1272) |
| asar size | 40MB |
| asar SHA256 | `6744a67925299872f539233eab9a361abcccfd25a26a4d662e34e648efa0f91f` |
| Electron | Yes (Electron Framework.framework) |
| Bundler | Vite + Rollup |
| Minification | Standard (Terser-like identifier shortening, no obfuscation) |
| Platform | macOS arm64, min macOS 12.0 |

## Execution Model

```
Codex (native) → bootstrap.js → product-name-CswjKXkf.js (shared lib)
                                 ↓
                              main-8X_hBwW2.js (main process: windows, IPC, automations)
                              worker.js (worker thread: git ops, background tasks)
                                 ↓
                              preload.js → webview/index.html → webview/assets/*.js (renderer)
```

## Entry Points

1. **bootstrap.js** (charOffset 0) — Loads product-name lib, sets app name/paths, requests single-instance lock, initializes Sparkle, imports main
2. **main-8X_hBwW2.js** (loaded dynamically) — `runMainAppStartup()` — window creation, IPC handlers, automation scheduler
3. **worker.js** — Worker thread for git operations, app-server communication
4. **preload.js** — Minimal bridge: `electronBridge` object with IPC wrappers

## Native Modules

| Module | Purpose | Binary |
|--------|---------|--------|
| `node-pty` | Terminal emulation (PTY) | `pty.node` (Mach-O arm64) |
| `better-sqlite3` | Local SQLite database | `better_sqlite3.node` |
| `sparkle.node` | Sparkle auto-updater (macOS) | Mach-O arm64 |

## Frameworks

| Framework | Purpose |
|-----------|---------|
| Electron Framework | Chromium + Node.js runtime |
| Sparkle.framework | macOS auto-update (with Ed25519 signing) |
| Squirrel.framework | App lifecycle / update support |
| ReactiveObjC.framework | Reactive extensions |
| Mantle.framework | Model framework |

## Network Endpoints

| Endpoint | Purpose |
|----------|---------|
| `https://chatgpt.com/backend-api` | Production API |
| `http://localhost:8000/api` | Development API |
| `https://ab.chatgpt.com` | A/B testing / analytics |
| `https://cdn.openai.com` | CDN assets |
| Sentry ingest (DSN in code) | Error/crash reporting |
| Datadog (via logger) | Logging/monitoring |
| Statsig | Feature flags |

## IPC Channels

| Channel | Direction | Purpose |
|---------|-----------|---------|
| `codex_desktop:message-from-view` | renderer→main | General messages |
| `codex_desktop:message-for-view` | main→renderer | General messages |
| `codex_desktop:show-context-menu` | renderer→main | Context menu |
| `codex_desktop:show-application-menu` | renderer→main | App menu |
| `codex_desktop:get-sentry-init-options` | renderer→main | Sentry config |
| `codex_desktop:get-build-flavor` | renderer→main | Build info |
| `codex_desktop:get-system-theme-variant` | renderer→main | Theme |
| `codex_desktop:get-fast-mode-rollout-metrics` | renderer→main | Rollout data |
| `codex_desktop:trigger-sentry-test` | renderer→main | Sentry test |
| `codex_desktop:worker:*:from-view` | renderer→worker | Worker messages |
| `codex_desktop:worker:*:for-view` | worker→renderer | Worker messages |
