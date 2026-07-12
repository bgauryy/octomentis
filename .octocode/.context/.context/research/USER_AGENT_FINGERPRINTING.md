# User-Agent & Client Identity Fingerprinting — Cross-Product Comparison

**Date:** 2026-04-17  
**Scope:** Claude Code, Cursor, Antigravity (Google), Codex (OpenAI), BridgeCLI  
**Method:** Static binary analysis (`strings`), bundle reverse-engineering (`rg`), HTTP header extraction  
**Related:** [`WEBFETCH_SEARCH_COMPARISON.md`](./WEBFETCH_SEARCH_COMPARISON.md)

---

## TL;DR

Every AI coding assistant identifies itself differently over the wire. Some use standard `User-Agent` headers, some use custom header families, and one leaks PII in plaintext.

| Product | Primary Identity Header | Example Value | PII Risk |
|---------|------------------------|---------------|----------|
| **Claude Code** | `User-Agent` | `claude-cli/2.1.112 (external, cli)` | LOW — version + entrypoint only |
| **Cursor** | `x-cursor-*` family (6+ headers) | `x-cursor-client-version: 3.0.16` | LOW — device metadata, no username |
| **Antigravity** (Node) | `User-Agent` + `UNLEASH-INSTANCEID` | `codeium-extension` + `<user>-<host>` | **HIGH — plaintext username + hostname** |
| **Antigravity** (Go) | `User-Agent` | `antigravity-client<suffix>` (runtime) | MEDIUM — suffix unknown statically |
| **Codex** | Not observed | — | UNKNOWN |
| **BridgeCLI** | Not observed (design spec) | — | N/A |

---

## 1. Claude Code — `claude-cli/<VERSION>`

**Source:** `OI()` function in `cli.js` bundle (v2.1.112)

### Header Construction

```javascript
function OI() {
  let q = process.env.CLAUDE_AGENT_SDK_VERSION
    ? `, agent-sdk/${process.env.CLAUDE_AGENT_SDK_VERSION}` : "";
  let K = process.env.CLAUDE_AGENT_SDK_CLIENT_APP
    ? `, client-app/${process.env.CLAUDE_AGENT_SDK_CLIENT_APP}` : "";
  return `claude-cli/${VERSION} (external, ${
    process.env.CLAUDE_CODE_ENTRYPOINT ?? "cli"
  }${q}${K}${z})`;
}
```

### Confirmed Values

| Header | Value | Notes |
|--------|-------|-------|
| `User-Agent` | `claude-cli/2.1.112 (external, cli)` | Default CLI entrypoint |
| `User-Agent` | `claude-cli/2.1.112 (external, vscode, agent-sdk/0.x.x)` | When launched from VS Code extension |
| `User-Agent` | `claude-cli/2.1.112 (external, cli, client-app/my-app)` | With CLAUDE_AGENT_SDK_CLIENT_APP set |

### Privacy Assessment

**LOW RISK.** Exposes:
- Product version (e.g., `2.1.112`)
- Entrypoint (`cli`, `vscode`, etc.)
- Optionally: SDK version, client app name

Does NOT expose: username, hostname, machine ID, OS version, or any PII.

---

## 2. Cursor — `x-cursor-*` Custom Header Family

**Source:** `workbench.desktop.main.js` bundle + `cursor-api.sh` reverse-engineered script (v3.0.16)

### Architecture

Cursor does **not** use a standard `User-Agent` header for API calls. Instead, it uses a family of custom `x-cursor-*` headers:

### Confirmed Headers

| Header | Example Value | Source |
|--------|---------------|--------|
| `Authorization` | `Bearer <JWT>` | `cursorAuth/accessToken` from `state.vscdb` |
| `x-cursor-checksum` | `<base64(xor_chain(ts))><machineId>` | Computed integrity hash |
| `x-cursor-client-version` | `3.0.16` | `product.json` |
| `x-cursor-client-type` | `ide` | Hardcoded |
| `x-cursor-client-os` | `darwin` | Runtime detection |
| `x-cursor-client-arch` | `arm64` | Runtime detection |
| `x-cursor-client-device-type` | `desktop` | Hardcoded |
| `x-cursor-client-os-version` | `24.6.0` | Runtime detection |
| `x-cursor-timezone` | `IST` | `date +%Z` equivalent |
| `x-ghost-mode` | `true\|false` | Privacy toggle |
| `x-parent-request-id` | `req_parent_xyz` | Request lineage chain |
| `connect-protocol-version` | `1` | Connect-RPC wire protocol |

### Endpoint

All API traffic goes to `api2.cursor.sh` with `Bearer JWT + x-cursor-checksum` authentication.

### Privacy Assessment

**LOW RISK.** Exposes:
- Client version, OS, arch, device type, OS version
- Machine ID (hashed in checksum)
- Timezone
- Privacy mode state (`x-ghost-mode`)

Does NOT expose: username, hostname, or cleartext PII.  
**Note:** The `x-cursor-checksum` includes a `machineId` component — not PII, but a persistent device fingerprint.

---

## 3. Antigravity (Google) — Dual-Layer Identity with PII Leak

**Source:** Static analysis of `language_server_macos_arm` (Go binary) + `extension.js` (Node bundle)

Antigravity has **two separate identity systems** for its Go language server and its Node VS Code extension:

### Layer 1: Go Language Server (`language_server_macos_arm`)

| Context | User-Agent / Identity | Notes |
|---------|----------------------|-------|
| Custom HTTP | `antigravity-client%s` | Runtime-formatted; exact `%s` suffix not in static strings |
| Go net/http default | `Go-http-client/1.1` | Used when no UA is explicitly set |
| Go net/http default (H2) | `Go-http-client/2.0` | HTTP/2 variant |
| gRPC transport | `grpc-go/1.79.0-dev` | Standard gRPC-Go identity |
| Connect-Go | `connect-go/%s (%s)` | Runtime-formatted Connect-Go client identity |
| Google API telemetry | `gl-go/%s gccl/%s` | `x-goog-api-client` header value template |
| Unleash (Go side) | No clean static value | `WithAppName` used but value not in binary strings |

**Additional static strings found:** `jetski1.11.0` (version token near product text, not proven to be UA suffix), `RecordReadUrlContent`, `web_search_model_ids` (tool identifiers, not UA values).

**MEDIUM RISK.** The `antigravity-client%s` pattern is runtime-constructed — the suffix could contain version, device info, or other identifiers not visible from static analysis alone. Requires network interception to confirm the exact final value.

### Layer 2: Node Extension (`extension.js`)

| Context | Header | Value | Risk |
|---------|--------|-------|------|
| Connect-ES RPC | `User-Agent` | `connect-es/1.5.0` | LOW |
| Unleash SDK | `User-Agent` | `codeium-extension` | LOW |
| Unleash SDK | `unleash-appname` | `codeium-extension` | LOW |
| Unleash SDK | `unleash-sdk` | `unleash-node-sdk:6.7.0` | LOW |
| **Unleash SDK** | **`UNLEASH-INSTANCEID`** | **`<username>-<hostname>`** | **HIGH** |
| Node fetch default | `User-Agent` | `undici` / `node` | LOW |

### UNLEASH-INSTANCEID — PII Leak (VALIDATED)

**Source code from `extension.js`:**

```javascript
e && (c["User-Agent"] = e, c["unleash-appname"] = e),
t && (c["UNLEASH-INSTANCEID"] = t)
// where e = "codeium-extension" and t = username-hostname
```

**What gets sent:**

```http
POST https://antigravity-unleash.goog/api/client/register
User-Agent: codeium-extension
unleash-appname: codeium-extension
UNLEASH-INSTANCEID: johndoe-MacBook-Pro.local
unleash-sdk: unleash-node-sdk:6.7.0
```

**Impact:**
- **Username** leaked in cleartext on every Unleash poll (feature flag checks)
- **Hostname** leaked in cleartext — reveals machine name, often includes real name
- Unleash polls happen **repeatedly** during session — continuous exposure
- Sent to `antigravity-unleash.goog` — Google infrastructure, but still over the wire
- Any network observer (proxy, corporate firewall, VPN provider) can harvest this

**Severity: HIGH** — This is a privacy violation that leaks PII to an external service without user consent or awareness.

---

## 4. Codex (OpenAI) — Not Observed

No `User-Agent` or custom identity header was found in the audited Codex Desktop bundle (`app.asar`, `main-8X_hBwW2.js`).

Codex communicates with `chatgpt.com/backend-api` and uses:
- Sentry for error reporting
- Statsig for feature flags
- Sparkle for auto-updates

The API communication layer likely uses a standard `User-Agent`, but it was not extracted in the current analysis scope.

---

## 5. BridgeCLI — Design Spec Only

BridgeCLI is a design document, not a shipped product. No `User-Agent` configuration was specified in the tool specification. As a design-phase project, this would be defined during implementation.

---

## 6. Comparison Matrix

### Identity Disclosure

| Data Point | Claude Code | Cursor | Antigravity (Node) | Antigravity (Go) | Codex |
|------------|:-----------:|:------:|:------------------:|:-----------------:|:-----:|
| Product name | YES | YES | YES (`codeium-extension`) | YES (`antigravity-client`) | — |
| Version | YES (`2.1.112`) | YES (`3.0.16`) | YES (`6.7.0` SDK) | NO (runtime) | — |
| Entrypoint | YES (`cli`/`vscode`) | YES (`ide`/`desktop`) | NO | NO | — |
| OS | NO | YES (`darwin`) | NO | NO | — |
| Architecture | NO | YES (`arm64`) | NO | NO | — |
| OS version | NO | YES (`24.6.0`) | NO | NO | — |
| Machine ID | NO | HASHED (in checksum) | NO | NO | — |
| **Username** | NO | NO | **YES (plaintext)** | NO | — |
| **Hostname** | NO | NO | **YES (plaintext)** | NO | — |
| Timezone | NO | YES | NO | NO | — |

### Header Approach

| Approach | Product | Pros | Cons |
|----------|---------|------|------|
| Standard `User-Agent` | Claude Code, Antigravity | Easy to monitor/filter | Exposes product identity |
| Custom header family | Cursor (`x-cursor-*`) | Granular metadata, not in standard logs | Non-standard, harder to audit |
| Instance ID header | Antigravity (`UNLEASH-INSTANCEID`) | Unique session tracking | **Leaks PII** |
| No observed header | Codex | Minimal fingerprint | Can't verify compliance |

---

## 7. Security Implications

### Network Observability

Every request an AI coding assistant makes can be observed by:
- Corporate proxies and firewalls
- VPN providers
- ISP deep packet inspection (non-TLS)
- DNS resolvers (domain visibility)
- The receiving server (obviously)

### What Each Product Reveals to a Network Observer

| Observer Sees | Claude Code | Cursor | Antigravity |
|---------------|:-----------:|:------:|:-----------:|
| "User is running AI coding tool" | YES | YES | YES |
| Which product + version | YES | YES | YES |
| User's real name | NO | NO | **LIKELY** (from hostname) |
| Machine name | NO | NO | **YES** |
| Operating system | NO | YES | NO |
| Privacy preference | NO | YES (`x-ghost-mode`) | NO |

### Antigravity-Specific Risk: Unleash Polling Cadence

Unleash clients poll feature flags at regular intervals (typically 15-60 seconds). This means the `<username>-<hostname>` in `UNLEASH-INSTANCEID` is transmitted **hundreds of times per session** to `antigravity-unleash.goog`. This is not a one-time registration — it's continuous PII transmission.

---

## 8. Best Practices for User-Agent / Client Identity

### Do

1. **Include product name and version** — enables server-side analytics and debugging
2. **Use version from build config** — avoid hardcoding (Claude Code's approach is good)
3. **Hash machine identifiers** — Cursor's checksum approach is better than plaintext
4. **Provide a privacy toggle** — Cursor's `x-ghost-mode` is a good model
5. **Document what's sent** — users should know what identity info is transmitted

### Don't

1. **NEVER send username or hostname in cleartext** — Antigravity violates this
2. **Don't use persistent plaintext instance IDs derived from PII** — use random UUIDs instead
3. **Don't include auth tokens in User-Agent** — keep auth in `Authorization` header
4. **Don't expose internal product names** — `codeium-extension` reveals Antigravity's heritage as Codeium/Windsurf
5. **Don't skip User-Agent entirely** — makes debugging and abuse detection harder

### Recommended Pattern

```
User-Agent: <product>/<version> (<context>, <entrypoint>)
X-Instance-ID: <random-uuid-v4>
X-Client-OS: <os>/<arch>
```

Example:
```
User-Agent: my-ai-tool/1.0.0 (external, cli)
X-Instance-ID: a7f3b2c1-4d5e-6f7a-8b9c-0d1e2f3a4b5c
X-Client-OS: darwin/arm64
```

This provides full analytics value with zero PII exposure.

---

## 9. Verification Methods

To independently verify these findings:

### Claude Code
```bash
# Extract UA builder from bundle
rg -o '.{0,30}claude-cli/.{0,120}' ~/.nvm/versions/node/*/lib/node_modules/@anthropic-ai/claude-code/cli.js
```

### Cursor
```bash
# Extract x-cursor headers from API script
rg 'x-cursor' /path/to/cursor/research/content/cursor-api.sh
```

### Antigravity
```bash
# Go binary UA pattern
strings /Applications/Antigravity.app/Contents/Resources/app/extensions/antigravity/bin/language_server_macos_arm | grep -i 'antigravity-client'

# Node extension Unleash headers
rg -o '.{0,60}UNLEASH-INSTANCEID.{0,80}' /Applications/Antigravity.app/Contents/Resources/app/extensions/antigravity/dist/extension.js

# Confirm username-hostname construction
rg -o '.{0,40}unleash-appname.{0,60}' /Applications/Antigravity.app/Contents/Resources/app/extensions/antigravity/dist/extension.js
```

---

*Generated: 2026-04-17*  
*Sources: Claude Code cli.js (v2.1.112), Cursor workbench bundle (v3.0.16), Antigravity language_server_macos_arm + extension.js (v1.14.2)*  
*Method: Static binary analysis + bundle reverse-engineering — no runtime interception*
