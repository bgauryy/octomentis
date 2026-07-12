# Antigravity — Deep Security Analysis

**Date:** 2026-04-14
**Analyst:** JS WhiteHat skill / Reverse Engineering
**Verdict:** `review recommended` — No confirmed malicious behavior, but significant privacy/security surface

---

## Individual Finding Reports

| # | Finding | Severity | Doc |
|---|---------|----------|-----|
| 01 | Device Fingerprinting via Auto-Updater | `medium` | [findings/01](./findings/01_hostname_fingerprint_auto_updater.md) |
| 02 | Dual Telemetry — Clearcut + VS Code | `medium` | [findings/02](./findings/02_clearcut_dual_telemetry.md) |
| 03 | Remote Prompt Override via Unleash | `medium` | [findings/03](./findings/03_remote_prompt_override_unleash.md) |
| 04 | Agent Blast Radius & Prompt Injection | `high` | [findings/04](./findings/04_agent_blast_radius_prompt_injection.md) |
| 05 | Browser JavaScript Execution via CDP | `high` | [findings/05](./findings/05_browser_javascript_execution.md) |
| 06 | OAuth Token Lifecycle & Exposure | `medium` | [findings/06](./findings/06_oauth_token_handling.md) |

---

## Executive Summary

Antigravity is a legitimate Google product (VS Code fork + AI agent). It is **not malware**. However, the security surface is large and several architectural decisions warrant scrutiny:

1. **Hostname SHA256 sent as update URL parameter** — device fingerprinting via auto-updater
2. **Dual telemetry pipelines** — VS Code telemetry + Google Clearcut to `play.googleapis.com/log`
3. **`NSAllowsArbitraryLoads: true`** — disables App Transport Security entirely
4. **Embedded localhost TLS cert** — self-signed, enables HTTP/2 for local gRPC but increases MITM risk
5. **Unleash feature flags with hardcoded API key** — experiment configurations fetched at runtime
6. **Agent has full terminal + browser + file access** — large blast radius if prompt-injected
7. **Google internal URLs leaked in external build** — `.corp.google.com` endpoints still present
8. **Codeium codebase lineage** — significant code from Codeium/Windsurf (state IDs, proto files, extension names)

---

## Finding 1: Hostname Hash in Auto-Update URL

**Severity:** `medium` | **Confidence:** `confirmed`

### Evidence

From `main.js` (auto-updater flow):
```javascript
const n = kxi.hostname() || "no_hostname";
const a = Bxi.createHash("sha256").update(n).digest("hex");
return `https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/${e}/${t}/${r.commit}/${a}`
```

The SHA256 hash of the machine's hostname is appended to every update check URL. For insider builds, it fetches a secret from `https://dl.google.com/antigravity/insider_secret` and includes that too.

### Impact
- Server-side can correlate update requests to specific machines
- Hostname hash is a stable device fingerprint (persists across sessions)
- Combined with other telemetry data, enables cross-session user tracking
- Update URL goes to Google Cloud Run (`974169037036.us-central1.run.app`)

### Benign Alternative
Standard practice for update analytics, but atypical to hash the hostname itself rather than a random installation ID.

---

## Finding 2: Dual Telemetry — Clearcut + VS Code

**Severity:** `medium` | **Confidence:** `confirmed`

### Evidence

**Clearcut Pipeline** (Google's analytics system):
```javascript
pWt = "https://play.googleapis.com/log"
Mke = 5 * 60 * 1e3  // 5 minute flush interval
bwa = 1e4            // max 10,000 events per batch
Rwa = 44             // log source ID
Awa = 2747           // product ID

// Sends binary protobuf via POST
fetch(pWt, {
    method: "POST",
    headers: {"Content-Type": "application/octet-stream"},
    body: a,
    redirect: "follow"
})
```

Events are buffered locally in `antigravityAnalytics.clearcutBuffer` (persisted to storage) and flushed every 5 minutes to `play.googleapis.com/log`. Uses OAuth token from `uss-oauth` for authentication.

**VS Code Telemetry** (inherited):
```
telemetry.machineId       — MAC address SHA256
telemetry.sqmId           — Software Quality Metrics ID
telemetry.devDeviceId     — Device ID
telemetry.firstSessionDate — First session timestamp
common.platform           — OS platform
common.nodeArch           — CPU architecture
common.platformVersion    — OS version
common.msftInternal       — Microsoft internal flag (inherited from VS Code)
```

### Data Fields Collected
- Machine ID (MAC address hash)
- Device ID
- Session ID (per-session unique)
- Platform, architecture, OS version
- Commit hash, app version
- First/current/last session dates
- SQM ID (inherited from VS Code telemetry)

### Impact
- Two separate telemetry pipelines: Google Clearcut (binary protobuf) AND VS Code telemetry
- Telemetry levels: NONE, CRASH, ERROR, USAGE — user can reduce but not fully disable at network level
- Clearcut batches up to 10,000 events and retries on failure
- Clearcut buffer persists across sessions (survives restart)
- OAuth-authenticated telemetry means events are tied to Google account

### Benign Alternative
Standard product analytics. Clearcut is Google's standard analytics pipeline. However, the dual pipeline (VS Code + Clearcut) may surprise users expecting only VS Code-style telemetry settings to apply.

---

## Finding 3: NSAllowsArbitraryLoads Enabled

**Severity:** `medium` | **Confidence:** `confirmed`

### Evidence

From `Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Impact
- Disables Apple's App Transport Security entirely
- All HTTP (non-TLS) connections allowed
- No certificate pinning enforced at OS level
- Any network request from the app can go to any endpoint over HTTP
- Combined with the extensive network access (language server, telemetry, updates, unleash), this is a wide surface

### Benign Alternative
Common for Electron apps that need to connect to arbitrary user-specified servers (MCP servers, local dev servers). VS Code itself does this too. But combined with the agent's `web_search` and browser tools, the attack surface is wider than typical.

---

## Finding 4: Embedded Self-Signed Localhost Certificate

**Severity:** `low` | **Confidence:** `confirmed`

### Evidence

From `extensions/antigravity/dist/languageServer/cert.pem`:
```
Issuer: CN=localhost, O=ENABLES HTTP2, OU=bundled on purpose
Validity: Sep 4 2025 — Sep 4 2026
Subject: CN=localhost
SAN: localhost, 127.0.0.1
Key: RSA 2048-bit
```

### Impact
- Self-signed cert enables HTTP/2 for local gRPC communication between extension and language server
- Certificate is bundled with the app (not generated per-install)
- All Antigravity installations share the same private key
- Theoretically, any process on localhost that obtains this cert could impersonate the language server
- Expires September 2026 — will need rotation

### Benign Alternative
This is explicitly labeled "ENABLES HTTP2" and "bundled on purpose". HTTP/2 requires TLS. Using a shared cert for localhost is a pragmatic choice — gRPC performance is significantly better over HTTP/2. Risk is limited to local attack surface.

---

## Finding 5: Hardcoded Unleash Feature Flag Key

**Severity:** `low` | **Confidence:** `confirmed`

### Evidence

From `extension.js`:
```javascript
{
    url: `http://localhost:${port}/proxy/unleash`,
    appName: "codeium-extension",
    customHeaders: {
        Authorization: "*:production.853c3f3dde009b1db67a70e1de9cfff6e3e373524f451b88b8846542"
    },
    refreshInterval: 6e4,  // 60 seconds
    timeout: 2e3
}
```

### Impact
- Production Unleash API key embedded in client code
- Feature flags proxied through the language server (`localhost:PORT/proxy/unleash`)
- Real Unleash endpoint: `https://antigravity-unleash.goog`
- App name is `"codeium-extension"` — confirming Codeium lineage
- Flags can remotely enable/disable features, change prompts, alter agent behavior
- Prompt templates can be overridden via Unleash: `loadTemplateFromUnleash`
- Cascade config read from Unleash: `ReadCascadeConfigForCumulativePromptFromUnleash`

### Benign Alternative
Feature flags are standard. The hardcoded key is a read-only client key (standard Unleash pattern). But the ability to remotely modify prompt templates via feature flags is a powerful server-side control.

---

## Finding 6: Agent Blast Radius / Command Execution

**Severity:** `high` | **Confidence:** `confirmed`

### Evidence

The agent has access to:
- **File system:** read, write, create, delete files in workspace (and potentially outside with `allowAgentAccessNonWorkspaceFiles`)
- **Terminal:** `execute_command` with allowlist/denylist (`cascadeAllowedCommands`/`cascadeDeniedCommands`)
- **Browser:** 30+ CDP tools including `browser_javascript` (execute arbitrary JS in pages)
- **Subagents:** `define_subagent` + `invoke_subagent` — spawn new agents with custom specs
- **MCP:** `mcp_tool` — call any configured MCP server tool
- **Network:** `web_search`, `read_url_content`
- **Git:** Worktree management, PR creation

Config keys controlling safety:
```
CASCADE_AUTO_EXECUTION_POLICY: "cascadeAutoExecutionPolicy"
ALLOW_AGENT_ACCESS_NON_WORKSPACE_FILES: "allowAgentAccessNonWorkspaceFiles"
ALLOW_CASCADE_ACCESS_GITIGNORE_FILES: "allowCascadeAccessGitignoreFiles"
SECURE_MODE_ENABLED: "secureModeEnabled"
BROWSER_JS_EXECUTION_POLICY: "browserJsExecutionPolicy"
BROWSER_ALLOWLIST: "browserAllowlist"
```

**Sandbox wrapper** (`sandbox-wrapper.sh`):
- Uses macOS Seatbelt sandbox (`sandbox-exec`)
- Restricts file writes to workspace + `/tmp`
- Optional network blocking (`--allow-network` flag)
- Processes `.gitignore` and `.agyignore` for deny rules
- Only applies to sandboxed executions — **not the language server itself**

### Impact
- Prompt injection via repository content (malicious `.md` files, README, code comments) could trigger:
  - File writes (malware installation)
  - Command execution (reverse shells, data exfil)
  - Browser actions (credential theft via CDP)
  - Subagent spawning (persistence, complexity hiding)
- Sandbox only covers `execute_command` when explicitly sandboxed — the Go language server runs unsandboxed
- `ALLOW_AGENT_ACCESS_NON_WORKSPACE_FILES` and `BROWSER_JS_EXECUTION_POLICY` can be toggled by users, weakening boundaries
- Browser tool can read console logs, network requests, and execute arbitrary JavaScript

### Benign Alternative
All AI code editors have this attack surface. The allowlist/denylist and sandbox are positive mitigations. The sandbox-wrapper.sh is well-designed (Seatbelt profiles, gitignore integration). But the surface area is exceptionally large.

---

## Finding 7: Google Internal URLs in External Build

**Severity:** `low` | **Confidence:** `confirmed`

### Evidence

URLs that reference Google's internal network found in the JS bundles:

```
https://agent-marketplace.corp.google.com
https://dashboards.corp.google.com/view/_71383517_d858_4c8f_808b_6548d3ef3b92
https://flyway.corp.google.com/trajectory/conversation/gc
https://g3doc.corp.google.com/devtools/cider/g3doc/ai-features/gemini-coder/terminal-autorun.md
https://g3doc.corp.google.com/devtools/jetski/g3doc/features/agent/agent-custom-agents.md
https://goto.google.com/jetski-skills
https://sites.google.com/corp/google.com/spec-site/projects/lri
https://wf-boring-coyote.corp.google.com/
```

Internal paths in Go binary:
```
google3/third_party/jetski/cortex/
google3/third_party/jetski/prompt/
google3/google/internal/cloud/code/v1internal/
```

### Impact
- Information leak: reveals internal Google project names, dashboard URLs, documentation paths
- `.corp.google.com` URLs are only reachable inside Google's network — dead links for external users
- Reveals the internal agent marketplace URL
- `goto.google.com/jetski-skills` reveals the internal skills documentation URL
- `wf-boring-coyote` appears to be an internal workflow tool

### Benign Alternative
Artifact of building from Google's internal monorepo (google3). Strings not cleaned during external release build. Common in large org software releases. No direct security risk, but reveals internal project structure.

---

## Finding 8: Codeium/Windsurf Codebase Lineage

**Severity:** `info` | **Confidence:** `confirmed`

### Evidence

Multiple indicators that Antigravity's codebase derives from Codeium/Windsurf:

1. **State IDs:** `"codeium.snoozeEndTimeKey"`, `"codeium.installationId"`, `"codeium.hasOneTimeUpdatedUnspecifiedMode"`
2. **App name in Unleash:** `appName: "codeium-extension"`
3. **Proto files:** `file_exa_codeium_common_pb_codeium_common`
4. **Environment variable:** `process.env.CODEIUM_LANGUAGE_SERVER_BIN`
5. **State migration:** `"ANTIGRAVITY_TAB_UPSELL_KILL_SWITCH"` alongside codeium keys
6. **CodeiumState:** `CodeiumState.WARNING` enum still present in extension
7. **DevExtension:** `"codeium_dev.updateTabJumpDetailedView"` command
8. **Config migration:** Code merges `antigravity.`, `codeium.`, and `codeiumDev.` prefixed settings

### Impact
- Confirms Google acquired/integrated Codeium technology into Antigravity
- Legacy Codeium identifiers still active in production code
- Settings migration handles codeium→antigravity namespace transition
- Not a security risk per se, but reveals the product's technical lineage

---

## Finding 9: NODE_TLS_REJECT_UNAUTHORIZED Check

**Severity:** `low` | **Confidence:** `confirmed`

### Evidence

From `extension.js`:
```javascript
rejectUnauthorized: "0" !== process.env.NODE_TLS_REJECT_UNAUTHORIZED
```

### Impact
- If `NODE_TLS_REJECT_UNAUTHORIZED=0` is set, TLS certificate validation is disabled
- Combined with `NSAllowsArbitraryLoads`, makes MITM attacks trivial
- Standard Node.js behavior, but risky for an app handling authentication tokens and code

### Benign Alternative
This is standard Node.js TLS handling inherited from npm ecosystem. The check is actually correct (rejects unauthorized unless explicitly disabled). Present in virtually all Node.js apps.

---

## Finding 10: Remote Prompt Template Override via Unleash

**Severity:** `medium` | **Confidence:** `likely`

### Evidence

From Go binary function paths:
```
google3/third_party/jetski/prompt/template_provider/templateprovider.(*TemplateProvider).loadTemplateFromUnleash
google3/third_party/jetski/prompt/prompt.ReadCascadeConfigForCumulativePromptFromUnleash
google3/third_party/jetski/prompt/prompt.ReadCumulativePromptConfigFromUnleash
```

### Impact
- System prompt templates can be loaded from Unleash feature flag system
- This means Google can remotely modify the agent's identity, behavior, and instructions
- Changes apply without user consent or app update
- Cascade config (auto-execution policies, planner settings) also read from Unleash
- Combined with the broad tool access, remote prompt modification could alter agent behavior significantly

### Benign Alternative
Allows rapid iteration on prompts without shipping app updates. Standard practice for AI products. But means the agent's behavior can change at any time server-side.

---

## Finding 11: Broad macOS Permissions

**Severity:** `low` | **Confidence:** `confirmed`

### Evidence

From `Info.plist`:
```
NSCameraUsageDescription: "An application in Antigravity wants to use the Camera."
NSMicrophoneUsageDescription: "An application in Antigravity wants to use the Microphone."
NSBluetoothAlwaysUsageDescription: "An application in Antigravity wants to use Bluetooth."
NSAppleEventsUsageDescription: "An application in Antigravity wants access to control other applications."
```

Plus audio recording endpoints:
```
StartAudioRecording / EndAudioRecording — Audio input via extension server
GetTranscription — Audio transcription
```

### Impact
- Camera, microphone, Bluetooth, and AppleScript automation access declared
- Audio recording and transcription capabilities built into the language server
- AppleScript access enables controlling other applications
- These are permission *declarations* — macOS still prompts user before granting

### Benign Alternative
Camera/Mic for voice-to-code features. Bluetooth for device connectivity. AppleScript for IDE automation. All require user consent on macOS. Standard for feature-rich IDEs.

---

## Sandbox Analysis

The `sandbox-wrapper.sh` is a **well-designed** security boundary:

### Positive
- Uses macOS Seatbelt (`sandbox-exec`) — kernel-level enforcement
- Default deny for file writes (allow only workspace + `/tmp`)
- Optional network isolation (`--allow-network` flag defaults to `false`)
- Processes `.gitignore` and `.agyignore` for additional restrictions
- Specific Mach service allowlist (not wildcard)
- Specific sysctl read allowlist
- IOKit restricted to specific device classes

### Gaps
- Sandbox only covers `execute_command` — not the language server itself
- `(allow default)` at the start means anything not explicitly denied is allowed
- File reads not restricted (only writes are denied outside workspace)
- The Go language server runs outside the sandbox with full access
- Network blocking is opt-in per command, not default
- `.gitignore` pattern conversion has known limitations (directory-only patterns skipped)

---

## Outbound Network Endpoints Summary

| Endpoint | Purpose | Data Sent |
|----------|---------|-----------|
| `play.googleapis.com/log` | Clearcut analytics | Binary protobuf events, OAuth-authenticated |
| `cloudcode-pa.googleapis.com` | Cloud Code API | Model requests, code context |
| `antigravity-auto-updater-*.run.app` | Auto-updates | Platform, channel, commit, hostname hash |
| `dl.google.com/antigravity/insider_secret` | Insider build auth | HTTP GET (no auth) |
| `antigravity-unleash.goog` | Feature flags | User context for experiment targeting |
| `feedback-pa.googleapis.com` | User feedback | Feedback submissions |
| `fonts.googleapis.com` | Web fonts | Standard font requests |
| `npms.io/search` | npm package search | Package names |
| `main.vscode-cdn.net` | Source maps | Source map downloads |
| `localhost:PORT` | Language server | All gRPC traffic (local only) |

---

## Detection Matrix Coverage

| Category | Status | Notes |
|----------|--------|-------|
| Bootstrap and execution model | Checked | Electron + Go LS + gRPC + MCP |
| Dynamic execution and loading | Checked | No eval/Function in extension.js; spawn for LS process |
| Network and listener behavior | Checked | Dual telemetry, update fingerprinting, feature flags |
| File system and path reach | Checked | Sandbox for commands; LS unrestricted |
| Secrets, auth, session, crypto | Checked | OAuth, Unleash key hardcoded, shared localhost cert |
| Obfuscation and anti-analysis | Checked | Standard webpack minification, not obfuscated |
| High-impact abuse outcomes | Checked | Large blast radius via agent tools |
| Change-first anomalies | N/A | First analysis |

---

## Final Verdict

**`review recommended`**

Antigravity is a legitimate AI code editor from Google. No confirmed malicious behavior was found. However:

1. **Privacy-conscious users** should be aware of the dual telemetry pipelines and hostname fingerprinting
2. **Security-conscious organizations** should evaluate the agent's blast radius, especially browser_javascript and execute_command tools
3. **The remote prompt override capability** via Unleash means Google can modify agent behavior without app updates
4. **The shared localhost certificate** means all installations have the same TLS private key for local communication
5. **The Codeium lineage** is interesting from a business intelligence perspective but not a security concern

No evidence of:
- Malware or backdoors
- Credential exfiltration
- Hidden command-and-control
- Supply chain compromise
- Intentional security bypass
