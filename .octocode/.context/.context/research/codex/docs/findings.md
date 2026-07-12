# Codex.app — Detailed Security Findings

## F1: App Transport Security Disabled

| Field | Value |
|-------|-------|
| Severity | medium |
| Confidence | confirmed |
| Artifact | `/Applications/Codex.app/Contents/Info.plist` |
| Evidence | `<key>NSAllowsArbitraryLoads</key><true/>` |

**Detail:** ATS is fully disabled, allowing the main process to make HTTP (non-TLS) network requests. The webview CSP restricts `connect-src` to HTTPS, but Node.js code in the main process is unrestricted.

**Impact:** MITM attacks possible on any non-TLS connection from the main process. The dev API endpoint `http://localhost:8000/api` uses plain HTTP.

**Benign alternative:** Required for local development server and SSH tunnel connections.

---

## F2: `danger-full-access` Sandbox Bypass

| Field | Value |
|-------|-------|
| Severity | high |
| Confidence | confirmed |
| Artifact | `main-8X_hBwW2.js` |
| charOffset | ~6639 (Se function) |

**Detail:** The app supports three sandbox modes:
- `read-only` — agent can only read
- `workspace-write` — agent writes within workspace
- `danger-full-access` — agent has unrestricted filesystem access

When combined with shell access (via `codex app-server`), this gives the AI agent effective root-level access to the user's system.

**Impact:** If an agent is instructed (or prompt-injected) to perform malicious actions in `danger-full-access` mode, it has full system access including reading SSH keys, browser cookies, and other sensitive files.

**Mitigation:** User must explicitly opt into this mode. Default appears to be safer modes.

---

## F3: Shell Execution & AppleScript Injection

| Field | Value |
|-------|-------|
| Severity | medium |
| Confidence | confirmed |
| Artifact | `main-8X_hBwW2.js:33750` |
| Evidence | `exec "$login_shell" -il`, `osascript [-e ...]` |

**Detail:**
- Login shell spawning: `exec "$login_shell" -il` — sources the user's full shell profile
- AppleScript execution: `await si('osascript',['-e', i])` — used for terminal/editor integration
- SSH command construction: `[ssh, -o, BatchMode=yes, -o, ConnectTimeout=10, ...n, t, Xt()]`

**Impact:** Shell commands inherit the user's full environment and permissions. AppleScript can control any macOS application. If user-controlled input reaches these functions without sanitization, command injection is possible.

**Benign alternative:** Standard pattern for IDE terminal integration.

---

## F4: SOCKS5 Proxy for Remote Connections

| Field | Value |
|-------|-------|
| Severity | medium |
| Confidence | confirmed |
| Artifact | `product-name-CswjKXkf.js:545581` |
| Evidence | `SocksProxyAgent('socks5h://127.0.0.1:...')` |

**Detail:** Remote app-server connections use WebSocket over a SOCKS5 proxy (SSH tunnel). The proxy binds to localhost.

**Impact:** If the proxy port is predictable and doesn't require authentication, other local processes could potentially piggyback on the SSH tunnel.

---

## F5: CSP Weaknesses

| Field | Value |
|-------|-------|
| Severity | low |
| Confidence | confirmed |
| Artifact | `webview/index.html:217` |

**CSP Policy Analysis:**
```
default-src 'none';
img-src 'self' app: blob: data: https:;     ← any HTTPS image
script-src 'self' 'sha256-...' 'wasm-unsafe-eval';  ← WASM exec allowed
style-src 'self' 'unsafe-inline';           ← inline styles (XSS vector)
connect-src 'self' https://ab.chatgpt.com https://cdn.openai.com;  ← tight (good)
```

**Issues:**
1. `img-src https:` allows loading images from any HTTPS source (tracking pixels, SSRF probes)
2. `style-src 'unsafe-inline'` allows style injection which can be used for data exfiltration via CSS
3. `wasm-unsafe-eval` allows WebAssembly compilation and execution

---

## F6: Custom URL Scheme Without Visible Validation

| Field | Value |
|-------|-------|
| Severity | low |
| Confidence | likely |
| Artifact | `Info.plist` |
| Evidence | `CFBundleURLSchemes: ["codex"]` |

**Detail:** The app registers the `codex://` URL scheme. Websites can craft links that trigger the app to open and potentially execute actions.

**Impact:** Without strict validation, a malicious website could craft `codex://` links to trigger unintended app behavior.

---

## F7: Unencrypted Local SQLite Database

| Field | Value |
|-------|-------|
| Severity | low |
| Confidence | confirmed |
| Artifact | `product-name-CswjKXkf.js:318739` |

**Detail:** The app uses `better-sqlite3` to store automations, inbox items, and run history. No encryption at rest was observed.

**Tables:** `automations`, `automation_runs`, `inbox_items`
**Location:** `~/Library/Application Support/Codex/`

**Impact:** Any process on the system can read the SQLite database, which may contain automation prompts, thread titles, and run history.

---

## F8: Broad Microphone, Camera, and Bluetooth Permissions

| Field | Value |
|-------|-------|
| Severity | info |
| Confidence | confirmed |
| Artifact | `Info.plist` |

**Detail:** The app declares usage descriptions for:
- `NSMicrophoneUsageDescription` — "voice input"
- `NSCameraUsageDescription` — "needs access to the camera"
- `NSBluetoothPeripheralUsageDescription` — "needs access to Bluetooth"

Camera and Bluetooth usage descriptions seem overly broad for a coding assistant. These may be inherited from the Electron framework boilerplate.
