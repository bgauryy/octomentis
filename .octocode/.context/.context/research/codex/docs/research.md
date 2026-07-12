# Codex.app Security Audit — Executive Summary

**Target:** OpenAI Codex Desktop (`com.openai.codex`) v26.325.31654 (build 1272)
**Type:** Electron app (macOS arm64) with Vite-bundled JS
**Date:** 2026-04-09
**Verdict:** `review recommended`

---

## Architecture Overview

| Component | File | Size | Role |
|-----------|------|------|------|
| Bootstrap | `.vite/build/bootstrap.js` | 1.9KB | Entry point, loads main |
| Main Process | `.vite/build/main-8X_hBwW2.js` | 518KB | Window management, IPC, automations |
| Shared Library | `.vite/build/product-name-CswjKXkf.js` | 4.8MB | Core logic, app-server, git, telemetry |
| Worker | `.vite/build/worker.js` | 999KB | Background tasks, git operations |
| Preload | `.vite/build/preload.js` | 1.9KB | Context bridge to renderer |
| Webview UI | `webview/assets/index--dL9tGqL.js` | 3.9MB | React frontend |
| WebView HTML | `webview/index.html` | 16.6KB | Entry HTML with CSP |

**Native modules:** `node-pty` (terminal emulation), `better-sqlite3` (local DB), `sparkle.node` (auto-updater)

**Bundler:** Vite + Rollup (minified, not obfuscated — standard identifier shortening)

---

## Key Findings

### FINDING 1: App Transport Security Disabled (Medium)
- **Evidence:** `Info.plist` → `NSAllowsArbitraryLoads: true`
- **Impact:** Main process can make plain HTTP connections to any host. While CSP restricts the renderer, the main process Node.js code is unrestricted.
- **Benign alternative:** Needed for localhost dev server (`http://localhost:8000/api`) and potentially SSH tunneling.
- **Confidence:** confirmed

### FINDING 2: `danger-full-access` Sandbox Mode (High)
- **Evidence:** `main-8X_hBwW2.js` → `sandbox:h.sandboxPolicy.type==='dangerFullAccess'?'danger-full-access'`
- **Impact:** When users select this mode, the AI agent gets unrestricted filesystem access — read/write anywhere on disk, no sandbox boundaries. Combined with shell execution, this is effectively full system access.
- **Benign alternative:** This is a user-opted power mode. The app defaults to safer modes (`read-only`, `workspace-write`).
- **Confidence:** confirmed

### FINDING 3: Shell Execution & AppleScript (Medium)
- **Evidence:** `main-8X_hBwW2.js:33750` → `exec "$login_shell" -il`, `osascript [-e ...]`
- **Impact:** The app spawns full login shells and executes AppleScript for terminal/editor integration. AppleScript can control other applications.
- **Benign alternative:** Required for terminal integration and opening files in external editors (Ghostty, etc).
- **Confidence:** confirmed

### FINDING 4: SOCKS5 Proxy Tunnel for SSH Remote Connections (Medium)
- **Evidence:** `product-name-CswjKXkf.js:545581` → `SocksProxyAgent('socks5h://127.0.0.1:...')`
- **Impact:** WebSocket connections to remote app-servers are tunneled through a local SOCKS5 proxy (SSH tunnel). The proxy runs on localhost.
- **Benign alternative:** Standard pattern for SSH-forwarded connections to remote development hosts.
- **Confidence:** confirmed

### FINDING 5: CSP Present But With Broad Allowances (Low)
- **Evidence:** `webview/index.html` → `<meta http-equiv="Content-Security-Policy">`
- **CSP Policy:**
  - `default-src 'none'` ✓ (good baseline)
  - `script-src 'self' 'sha256-...' 'wasm-unsafe-eval'` — `wasm-unsafe-eval` allows WASM execution
  - `img-src 'self' app: blob: data: https:` — allows any HTTPS image (potential tracking pixel vector)
  - `connect-src 'self' https://ab.chatgpt.com https://cdn.openai.com` — restricted to OpenAI (good)
  - `style-src 'self' 'unsafe-inline'` — allows inline styles (XSS style injection vector)
- **Confidence:** confirmed

### FINDING 6: Telemetry & Monitoring Stack (Info)
- **Sentry:** Error tracking with DSN, sends crash reports and traces
- **Datadog:** Logging integration (`datadogLogger`)
- **Statsig:** Feature flags and A/B testing (`statsig` module)
- **OpenAI analytics:** `https://ab.chatgpt.com` in CSP connect-src (A/B testing endpoint)
- **Confidence:** confirmed

### FINDING 7: API Endpoints Hardcoded (Info)
- **Production:** `https://chatgpt.com/backend-api`
- **Development:** `http://localhost:8000/api`
- **Analytics:** `https://ab.chatgpt.com`
- **CDN:** `https://cdn.openai.com`
- **Evidence:** `main-8X_hBwW2.js` string literals
- **Confidence:** confirmed

### FINDING 8: Sparkle Auto-Update with Public Key (Info)
- **Evidence:** `Info.plist` → `SUPublicEDKey: rhcBvttuqDFriyNqwTQJR3L4UT1WjIK4QxtwtwusVic=`
- **Impact:** Uses Sparkle framework with Ed25519 public key for update signature verification. This is standard practice.
- **Confidence:** confirmed

### FINDING 9: Custom URL Scheme Handler (Low)
- **Evidence:** `Info.plist` → `CFBundleURLSchemes: ["codex"]`
- **Impact:** Registers `codex://` URL scheme. If not properly validated, external websites could trigger actions via deep links.
- **Confidence:** likely (need to verify handler validation)

### FINDING 10: SQLite Database with Automation State (Info)
- **Evidence:** `product-name-CswjKXkf.js:318739` → CREATE TABLE automations, automation_runs, inbox_items
- **Impact:** Stores automation configs, run history, and inbox items in local SQLite. No encryption observed on the database.
- **Confidence:** confirmed

---

## Security Positives

| Check | Status |
|-------|--------|
| Context isolation | ✅ Uses `contextBridge.exposeInMainWorld` properly |
| IPC namespacing | ✅ All channels prefixed `codex_desktop:` |
| CSP present | ✅ Restrictive policy with `default-src 'none'` |
| No `eval()` in app code | ✅ No dynamic code execution patterns found |
| No hardcoded secrets | ✅ No API keys/tokens in source |
| Preload bridge minimal | ✅ Only exposes necessary APIs |
| Update signature verification | ✅ Ed25519 key for Sparkle updates |
| Process monitoring | ✅ Parent PID watchdog for dev instances |

---

## Detection Matrix Coverage

| Category | Checked | Status |
|----------|---------|--------|
| Bootstrap & execution model | ✅ | Clean — standard Vite/Electron bootstrap |
| Dynamic execution & loading | ✅ | No `eval`, `Function()`, or dynamic `require` in app code |
| Network & listener behavior | ✅ | Connects to chatgpt.com backend, Sentry, Datadog, Statsig |
| File system & path reach | ✅ | SQLite in appData, `danger-full-access` mode is user-opted |
| Secrets, auth, session | ✅ | No hardcoded secrets; auth handled via app-server connection |
| Obfuscation & anti-analysis | ✅ | Standard minification only (Vite/Rollup), no obfuscation |
| High-impact abuse outcomes | ⚠️ | Full shell access in `danger-full-access` mode |
| Change-first anomalies | N/A | First audit — no baseline |

---

## References

- `overview.md` — Bundle structure details
- `findings.md` — Detailed finding entries with charOffset evidence
- `strings.md` — High-signal strings and endpoints
