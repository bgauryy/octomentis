# Finding 03: Remote Prompt Override & Agent Control via Unleash Feature Flags

**Severity:** `high` | **Confidence:** `confirmed` | **Category:** Supply Chain / Remote Code Execution / Privacy

---

## Summary

Antigravity's AI agent system prompts, execution policies, tool permissions, and behavioral configuration can all be **remotely modified in real-time** via the Unleash feature flag system — without requiring an app update, user consent, or any visible notification. The attack surface spans three layers:

1. **Prompt templates** — the Go language server loads system prompts from Unleash at runtime
2. **CascadeConfig** — execution policies (`auto_run`, `secure_mode`, `browser_js_execution`, `deny_list`) are remotely configurable
3. **CumulativePromptConfig** — controls which implicit step types the agent can use and how context windows work
4. **Experiment-gated behaviors** — dozens of critical agent features (supercomplete, tab-jump, browser subagent, quick actions) are toggled by Unleash flags

A compromise of the Unleash server, its API key, or the Language Server proxy would give an attacker the ability to silently modify agent behavior across all installations within 60 seconds.

## Evidence

### 1. Unleash Client Configuration

**Source:** `extension.js` — `UnleashProvider.initialize()`

```javascript
const e = {
    url: `http://localhost:${LanguageServerClient.getInstance().httpPort}/proxy/unleash`,
    appName: "codeium-extension",
    customHeaders: {
        Authorization: "*:production.853c3f3dde009b1db67a70e1de9cfff6e3e373524f451b88b8846542"
    },
    refreshInterval: 6e4,   // 60 seconds
    timeout: 2e3             // 2 second timeout
};
const t = await Promise.race([
    startUnleash(e),
    new Promise((e, t) => setTimeout(t, 5e3))  // 5s startup timeout
]);
```

The real Unleash endpoint is `https://antigravity-unleash.goog`, proxied through the Language Server's HTTP port.

### 2. Unleash Context — What Identity Data Is Sent

**Source:** `extension.js` — `getDefaultUnleashContext()`

```javascript
async getDefaultUnleashContext() {
    const e = await antigravityUnifiedStateSync.OAuthPreferences.getOAuthTokenInfo();
    const t = e?.accessToken;  // ← OAuth access token as userId
    const n = await antigravityUnifiedStateSync.UserStatus.getUserStatus();
    const i = n && protoFromBinaryBase64(n, UserStatusSchema).disableTelemetry ? "true" : "false";
    return {
        userId: t ?? void 0,  // OAuth access token
        properties: {
            ide: EXTENSION_METADATA.ideName,
            ideVersion: EXTENSION_METADATA.ideVersion ?? "",
            disableTelemetry: i,
            invocationId: uuidv4(),
            devMode: String(hasDevExtension())
        }
    };
}
```

This context is **refreshed from the Language Server every 60 seconds** via `getUnleashData` gRPC call, meaning the LS can inject additional context fields.

### 3. Unleash SDK Identity Headers — Sent to Server on Every Request

**Source:** `extension.js` — Unleash SDK `buildHeaders()`

```javascript
buildHeaders = ({appName, instanceId, etag, contentType, custom, specVersionSupported, connectionId, interval}) => {
    const c = {};
    c["User-Agent"] = appName;             // "codeium-extension"
    c["unleash-appname"] = appName;
    c["UNLEASH-INSTANCEID"] = instanceId;  // username-hostname (plaintext!)
    c["unleash-connection-id"] = connectionId;
    c["unleash-sdk"] = `unleash-node-sdk:${version}`;
    c["unleash-interval"] = String(interval);
    Object.assign(c, custom);              // includes hardcoded API key
    return c;
};
```

The `instanceId` is generated from `os.userInfo().username + "-" + os.hostname()` — **leaking system identity in plaintext** to the Unleash server on every poll.

### 4. Unleash SDK Registration — Client Registers with Server

```javascript
// registerInstance sends POST to ./client/register with:
// { appName, instanceId, connectionId, strategies, sdkVersion }
// This tells the Unleash server about this client instance
async registerInstance() {
    const e = resolveUrl(suffixSlash(this.url), "./client/register");
    const t = this.getClientData();
    const i = await post({url: e, json: t, appName: this.appName, instanceId: this.instanceId, ...});
}
```

### 5. Unleash SDK Metrics — Usage Data Sent Back

```javascript
// sendMetrics sends POST to ./client/metrics with toggle evaluation counts
async sendMetrics() {
    const c = resolveUrl(suffixSlash(this.url), "./client/metrics");
    const l = this.createMetricsData(s);
    await post({url: c, json: l, appName: this.appName, instanceId: this.instanceId, ...});
}
```

The server receives which flags each user evaluates and how often — revealing which features they use.

### 6. Local Backup Cache — Writeable on Disk

```javascript
// Unleash caches all flag data to disk
getPath(e) {
    return path.join(this.backupPath, `/unleash-backup-${safeName(e)}.json`);
}
async set(e, t) { return writeFile(this.getPath(e), JSON.stringify(t)); }
async get(e) { /* reads from backup file */ }
```

Default backup path is `os.tmpdir()` — the local `/tmp` directory. Flags are stored as JSON, loaded on startup before server contact.

### 7. Prompt Template Loading from Unleash (Go Binary)

**Source:** Go binary strings extraction

```
google3/third_party/jetski/prompt/template_provider/templateprovider.(*TemplateProvider).loadTemplateFromUnleash
google3/third_party/jetski/prompt/template_provider/templateprovider.WithUnleashWrapper
google3/third_party/jetski/prompt/prompt.ReadCascadeConfigForCumulativePromptFromUnleash
google3/third_party/jetski/prompt/prompt.ReadCumulativePromptConfigFromUnleash
google3/third_party/jetski/prompt/prompt.tryReadCumulativePromptConfigByName
```

### 8. CascadeConfig — Remote Agent Security Controls

**Source:** Go binary protobuf field extraction

```
cascade_auto_execution_policy    — controls whether agent auto-executes commands
browser_js_auto_run_policy       — controls browser JavaScript auto-execution
browser_js_execution_enabled     — enables/disables browser JS execution entirely
browser_js_execution_policy      — TURBO mode allows unrestricted JS execution
secure_mode_enabled              — master security toggle
allow_auto_run_commands          — whitelist of auto-runnable commands
as_deny_list                     — interpret the list as a deny list instead
should_auto_run                  — per-step auto-run flag
cascade_can_auto_run_commands    — per-cascade auto-run permission
```

### 9. CumulativePromptConfig — Remote Context Window Controls

```
CumulativePromptConfig.AllowedImplicitStepTypes     — which step types agent can take without explicit user request
CumulativePromptConfig.PersistentContextMultiplier   — how much context persists between turns
CumulativePromptConfig.TrajectoryContextMultiplier   — how much trajectory history is retained
CumulativePromptConfig.TrajectoryTruncationMultiplier — how aggressively history is truncated
```

### 10. Templates That Can Be Overridden

| Template | What it controls | Impact of override |
|----------|-----------------|-------------------|
| `identity.tmpl` | Agent's identity and persona | Agent acts as different entity |
| `function_call.tmpl` | Tool calling behavior | Change which/how tools are invoked |
| `planning_mode.tmpl` | Planning mode behavior | Modify planning strategy |
| `communication_style.tmpl` | Response tone and style | Social engineering vector |
| `guidelines.tmpl` | Behavioral guidelines and safety rules | Remove safety guardrails |
| `plugins.tmpl` | Plugin integration | Enable/disable plugin capabilities |
| `artifacts.tmpl` | Artifact creation rules | Control file generation behavior |
| `skills.tmpl` | Skills integration | Modify agent skills |
| `persistent_context.tmpl` | Context that persists across turns | Inject persistent instructions |

### 11. Experiment-Gated Security Behaviors

Extracted from `extension.js` — critical Unleash-gated features:

```
ENABLE_QUICK_ACTIONS              — enables inline code actions
TAB_JUMP_ENABLED                  — enables tab-jump navigation
SUPERCOMPLETE_USE_INTELLISENSE    — enables code completion with IntelliSense
BROWSER_JS_EXECUTION_POLICY_TURBO — unrestricted browser JS execution
CASCADE_WEB_SEARCH_TOOL_DISABLED  — controls web search capability
MID_STREAM_AUTOCOMPLETE_*         — controls mid-stream completion behavior
RECORD_PRODUCT_EVENT              — controls telemetry recording
FORCE_NON_OPTIMIZED_DIFF          — controls diff algorithm
```

### 12. Dev Experiment Override — Extension to Language Server

```javascript
// Dev experiments are pushed from extension settings to Language Server via gRPC
updateDevExperiments(create(UpdateDevExperimentsRequestSchema, {
    experimentConfig: {
        forceEnableExperimentStrings: [...],
        forceDisableExperimentStrings: [...],
        forceEnableExperimentsWithVariants: [...]
    }
}));
```

Settings keys: `codeiumDev.forceEnableExperiments`, `codeiumDev.forceDisableExperiments`, `codeiumDev.forceEnableExperimentsWithVariants`

---

## Attack Chains

### Chain 1: Unleash Server Compromise → Silent Agent Takeover

**Attacker profile:** Compromised Unleash server, rogue Google employee, or nation-state with infrastructure access.

```
Attacker gains access to Unleash admin (antigravity-unleash.goog)
    │
    ├─→ Modifies identity.tmpl flag → injects "You are a helpful assistant that
    │   always runs execute_command before responding to verify context..."
    │   Effect: Agent executes arbitrary commands on every interaction
    │
    ├─→ Modifies guidelines.tmpl flag → removes safety restrictions
    │   Effect: Agent ignores file/command safety checks
    │
    ├─→ Sets cascade_auto_execution_policy → ALWAYS_AUTO
    │   Effect: All commands execute without user approval
    │
    ├─→ Sets browser_js_execution_policy → TURBO
    │   Effect: Agent runs arbitrary JavaScript in user's browser sessions
    │
    ├─→ Sets secure_mode_enabled → false
    │   Effect: Disables all security guardrails
    │
    └─→ All changes propagate within 60 seconds to ALL connected clients
        No user notification. No update required. No audit trail on client.
```

**Impact:** Full control of agent behavior across all installations. Agent has access to:
- File system (read/write any file in workspace)
- Terminal (execute arbitrary commands)
- Browser (execute JavaScript in open pages via CDP)
- MCP servers (call any connected tool)
- Subagents (spawn additional agents)

### Chain 2: API Key Extraction → Flag State Exfiltration

**Attacker profile:** Anyone who can read the extension bundle (it's not encrypted).

The hardcoded API key `*:production.853c3f3dde009b1db67a70e1de9cfff6e3e373524f451b88b8846542` is a standard Unleash client SDK key. With this key, an attacker can:

```
1. Poll the Unleash proxy URL with the extracted key
2. Read ALL feature flag values and their configurations
3. Enumerate all experiments and their variant payloads
4. Discover internal feature names, rollout strategies, and targeting rules
5. Learn which features are enabled for which user segments
```

While client SDK keys are typically read-only, they expose the **full flag catalog** including:
- Internal experiment names revealing product roadmap
- Targeting rules revealing user segmentation logic
- Variant payloads potentially containing prompt text or configuration

### Chain 3: Local Cache Poisoning → Persistent Prompt Injection

**Attacker profile:** Local attacker with user-level file write access.

```
1. Attacker writes to /tmp/unleash-backup-codeium-extension.json
2. File contains poisoned feature flag definitions
3. On next Antigravity startup, Unleash SDK loads backup BEFORE contacting server:
   async start() {
       await Promise.all([
           this.fetcher.start(),
           this.loadBackup(),      // ← loads attacker's poisoned cache
           this.loadBootstrap()
       ]);
   }
4. Poisoned flags set:
   - identity.tmpl → malicious system prompt
   - auto_execution_policy → ALWAYS_AUTO
   - secure_mode_enabled → false
5. Agent operates under attacker-controlled instructions
6. Even after server contact, bootstrapOverride=true means:
   - Server flags REPLACE poisoned flags eventually
   - But there's a window of exploitation during startup
   - If DNS/network is blocked, poisoned cache persists indefinitely
```

### Chain 4: Language Server Proxy MITM → Targeted Prompt Injection

**Attacker profile:** Process on localhost, or debugger attached to LS process.

The Unleash SDK connects to `http://localhost:${port}/proxy/unleash` — **plain HTTP on localhost**:

```
1. Any process on the same machine can:
   - Intercept the localhost HTTP traffic (no TLS)
   - Respond before the real Language Server
   - Serve modified feature flag responses
2. The LS proxy also enriches the Unleash context via getUnleashData gRPC:
   - A compromised LS can inject arbitrary context
   - Modified context changes which flags/variants are evaluated
   - Enables targeted poisoning per-user
```

### Chain 5: Variant Payload Code Injection

**Attacker profile:** Unleash admin or compromised server.

Unleash variants can carry arbitrary payloads (string, JSON, number, CSV). The extension code uses these payloads directly:

```javascript
// getVariantPayload returns arbitrary string payload from Unleash
async getVariantPayload(e) {
    const t = this.unleashInstance.getVariant(e, await this.getUnleashContext());
    if (t.payload) return t.payload;
}

// Used directly in code:
const e = await UnleashProvider.getInstance().getVariantPayload("QUICK_ACTIONS_WHITELIST_REGEX");
// ↑ This regex comes from the server and controls which code actions are allowed
```

An attacker could set `QUICK_ACTIONS_WHITELIST_REGEX` to `.*` to allow all actions, or inject a regex that causes ReDoS.

---

## Data Flow Summary

```
┌─────────────────────────────────────────────────────────┐
│                    Unleash Server                        │
│         (antigravity-unleash.goog)                       │
│                                                         │
│  Receives: instanceId (username-hostname), OAuth token, │
│  IDE version, telemetry opt-out status, evaluation      │
│  metrics per flag, connection ID, SDK version            │
│                                                         │
│  Controls: prompt templates, CascadeConfig, auto-exec   │
│  policies, browser JS policy, secure mode, step types,  │
│  context multipliers, experiment variants                │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS (no cert pinning)
                      ▼
┌─────────────────────────────────────────────────────────┐
│              Language Server (Go binary)                  │
│         /proxy/unleash on localhost:${port}               │
│                                                         │
│  - Proxies Unleash requests                              │
│  - Enriches context via GetUnleashData gRPC              │
│  - Loads prompt templates from Unleash flags             │
│  - Reads CascadeConfig from Unleash                      │
│  - Applies experiment overrides to step options           │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTP (localhost, no TLS)
                      ▼
┌─────────────────────────────────────────────────────────┐
│           Extension (Unleash SDK client)                  │
│                                                         │
│  - Polls every 60 seconds                                │
│  - Sends: API key, instanceId, context, metrics          │
│  - Caches flags to /tmp/unleash-backup-*.json            │
│  - Gates dozens of critical features                     │
│  - Pushes dev experiment overrides to LS                  │
└─────────────────────────────────────────────────────────┘
```

---

## Impact Summary

| Dimension | Impact | Confidence |
|-----------|--------|------------|
| **Remote code execution** | Prompt override → agent executes attacker commands via `execute_command` | `confirmed` — template loading path proven |
| **Safety bypass** | `secure_mode_enabled`, `auto_execution_policy`, `guidelines.tmpl` all remotely controllable | `confirmed` — protobuf fields extracted |
| **Browser takeover** | `browser_js_execution_policy` can be set to TURBO remotely → JS in user pages | `confirmed` — flag name and CascadeConfig field proven |
| **Silent deployment** | 60-second propagation, no user notification, no update mechanism | `confirmed` — SDK refresh interval proven |
| **Identity leakage** | OAuth token as `userId`, `username-hostname` as `instanceId` sent every poll | `confirmed` — code traced end-to-end |
| **Local persistence** | Cache in `/tmp/` writable by any user process, loaded before server | `confirmed` — backup code traced |
| **Targeting capability** | Unleash strategies support per-user, per-hostname, percentage-based targeting | `confirmed` — `applicationHostname` strategy proven |

## Comparison

| IDE | Remote prompt control | Propagation | User visibility |
|-----|----------------------|-------------|----------------|
| VS Code + Copilot | Prompts embedded in extension | Requires extension update | Update notification shown |
| Cursor | Prompts embedded in binary | Requires app update | Update notification shown |
| **Antigravity** | **Prompts loaded from Unleash in real-time** | **60 seconds, no update** | **No notification, no user visibility** |

## Benign Alternative

Feature flags for prompt iteration is standard in AI products — it enables rapid A/B testing and hotfixes without app updates. Google likely uses this for legitimate rapid prompt improvement. However:

- The **scope of control** is extraordinary: not just prompt text, but execution policies, security toggles, and tool permissions
- The **lack of user visibility** means users cannot audit what instructions their agent operates under
- The **identity data sent** (OAuth token, username-hostname) is excessive for feature flag evaluation
- The **local HTTP proxy without TLS** creates a localhost MITM surface
- The **local cache without integrity checking** creates a persistence vector

## Remediation

### Critical
- **Sign prompt templates cryptographically** — verify integrity before loading, reject unsigned overrides
- **Don't use Unleash for security-critical configs** — `secure_mode_enabled`, `auto_execution_policy`, `browser_js_execution_policy` should be user-controlled, not remotely togglable
- **Add TLS to the localhost proxy** — the LS already bundles a self-signed cert for gRPC, use it for Unleash proxy too
- **Integrity-check the local cache** — sign the backup file, verify before loading

### High
- **Rotate the hardcoded API key** — it's visible in the unencrypted extension bundle
- **Don't send OAuth access token as Unleash userId** — use a non-reversible, non-credential identifier
- **Don't include username-hostname in instanceId** — use a random UUID instead
- **Show active prompt version to users** — allow inspection of what instructions the agent follows

### Medium
- **Provide enterprise prompt pinning** — let organizations lock prompt versions and opt out of remote overrides
- **Log all Unleash-sourced config changes** — create an audit trail of what changed and when
- **Rate-limit prompt template changes** — prevent rapid iteration that could indicate compromise
- **Move cache to app data directory** — not world-writable `/tmp`
