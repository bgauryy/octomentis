# Flows

## Security Flows

### 1) MCP Remote Server Onboarding Flow

- Entry: CLI `mcp add` command options and examples include HTTP transport.
- Anchors:
  - `cli.js:12998618-31`
  - `cli.js:12998721-31`
  - `cli.js:13002275-31`
- Enterprise gate: `cli.js:4968393` — `m46()` splits allowed vs blocked, `g46()` checks enterprise presence
- Interpretation:
  - User can add remote MCP servers over HTTP/SSE.
  - Enterprise config: blocks dynamic MCP addition with `process.exit(1)`.
  - Without enterprise: no server blocking; trust is entirely config-driven.

### 2) Permission Mode Resolution Flow

- Entry: CLI options produce permission mode inputs.
- Anchor: `cli.js:13175733-26`
- Observed snippet: `pK7({permissionModeCli:k,dangerouslySkipPermissions:W})`
- Downstream: `yJY` auto-allows when `mode === "bypassPermissions"`, after `ig8()` always-deny check.
- Policy control: `cli.js:1089201` — `disableBypassPermissionsMode` in schema can block bypass at org level.

### 3) Tool Permission Decision Flow

- Entry: runtime tool permission evaluator.
- Anchor: `cli.js:9923142-17`
- Observed behavior pattern:
  - `ig8()` always-deny check → immediate deny (always wins)
  - Rule deny → immediate deny
  - Rule ask → prompt/ask path
  - Mode check: if `bypassPermissions` → allow without prompt
  - else passthrough

### 4) Sandbox Disable Flow

- Entry: Bash tool invocation.
- Anchors:
  - `cli.js:9451634` — `dangerouslyDisableSandbox` on BashInput schema
  - `cli.js:9438643` — `isSandboxingEnabled()` and `areUnsandboxedCommandsAllowed()` gating
  - `cli.js:4416327` — seccomp `apply-seccomp` via `/proc/self/fd/`
  - `cli.js:4379922` — Linux sandbox `--ro-bind` / write path processing
  - `cli.js:8783475` — Enterprise sandbox requirement: "Enterprise policy requires sandboxing, but sandboxing is not available on native Windows"
- Flow:
  1. `Zx` checks if sandboxing is enabled globally
  2. If `dangerouslyDisableSandbox` is set AND `areUnsandboxedCommandsAllowed()` → skip sandbox
  3. Excluded command patterns from settings can also skip sandbox
  4. Enterprise policy can enforce sandboxing requirement

### 5) Audio Capture / Voice Flow

- Entry: user enables voice mode via `/voice` command or settings toggle.
- Anchors:
  - `cli.js:11376468` — mic permission check, `voiceEnabled` toggle
  - `cli.js:9269000` — `HDK` (startRecording) function entry
  - `cli.js:10875177` — voice WebSocket STT connection
- Native addon: `Bg8()` loads `vendor/audio-capture/{arch}-{platform}/audio-capture.node`
- Environment override: `AUDIO_CAPTURE_NODE_PATH` can redirect which binary loads
- Flow:
  1. `checkRecordingAvailability()` + `checkVoiceDependencies()`
  2. `requestMicrophonePermission()` → OS permission gate (hard fail on deny)
  3. `isVoiceStreamAvailable()` → requires OAuth session
  4. `HDK` (startRecording):
     - If native available → `startNativeRecording(callback)` via loaded addon
     - Linux fallback: `arecord` (ALSA)
     - macOS/other fallback: `rec` (SoX)
     - Windows: no fallback if native unavailable
  5. PCM chunks → WebSocket to `{BASE_API_URL}/api/ws/speech_to_text/voice_stream`
     - Authorization: Bearer {OAuth token}
     - Provider: Deepgram (in query params)

### 6) Telemetry Dispatch Flow

- OTEL path:
  - Anchor: `cli.js:7911558` — gated by `CLAUDE_CODE_ENABLE_TELEMETRY` env var
  - Anchor: `cli.js:7903301` — exporter init (OTLP gRPC/HTTP, Prometheus port 9464)
  - Meter: `com.anthropic.claude_code` at `cli.js:7911658`
- tengu analytics path:
  - Dispatch via `d("tengu_*", {})` function calls
  - Anchor: `cli.js:3516317` — `tengu_api_key_saved_to_keychain`
  - Anchor: `cli.js:7976067` — `tengu_oauth_success`
  - Anchor: `cli.js:7976371` — `tengu_oauth_flow_start`
  - No dedicated opt-out found for `tengu_*` events

### 7) Process Execution Capability Flow

- Entry: `child_process` imports and wrappers.
- Anchors:
  - `cli.js:892377-11`
  - `cli.js:953087-24`
- Observed:
  - `execSync` and spawned subprocess wrappers are present.
  - Controlled by permission and sandbox gates (flows 2-4).

### 8) Scheduled Task Persistence Flow (UPDATED 2026-04-05 — ISB-02)

- Entry: model calls CronCreate tool with `durable: true`, OR direct file write to `.claude/scheduled_tasks.json`
- Anchors:
  - `cli.js:6621431` — `wS4()` cron job creation function — **no prompt sanitization**
  - `cli.js:6625643` — durable job documentation + `zy6()` reader (no schema validation)
  - `cli.js:6626252` — auto-resume on next launch
  - `cli.js:6627029` — CronCreate/CronDelete/CronList definitions
  - `cli.js:6999353` — Classifier DELAYED EFFECTS: "creating cronjobs"
  - `cli.js:7004485` — Classifier override: shouldBlock flip on perceived user authorization
  - `cli.js:7014268` — System prompt: "Unauthorized Persistence: ...creating cron jobs"
  - `cli.js:12519922` — `$6O` / `useScheduledTasks` — startup loader
  - `cli.js:12322625` — `a27` scheduler factory
  - `cli.js:1044447` — SendUserMessage `status:"proactive"` for scheduled tasks
- Creation Flow:
  1. Model calls `CronCreate` with cron expression, prompt, and `durable: true`
  2. Classifier evaluates: DELAYED EFFECTS rule → `shouldBlock` decision
     - Override path: classifier can flip BLOCK→ALLOW if it perceives user authorization
  3. `wS4()` generates 8-char job ID
  4. IF `durable=false`: `Ks8()` → session-only in-memory store (dies with process)
  5. IF `durable=true`: `zy6()` reads `.claude/scheduled_tasks.json` → push → `kF1()` writes back
- Resume Flow (NO RE-CLASSIFICATION):
  1. Session start → `$6O` hook → `a27()` factory creates scheduler
  2. `zy6()` reads `.claude/scheduled_tasks.json` — **no schema validation, trusts file**
  3. Durable tasks loaded into timer loop
  4. `onFire` callback: `uA({value:H, mode:"prompt", priority:"later", isMeta:!0})`
  5. Prompt injected directly into message queue — **classifier NOT consulted**
  6. Missed one-shot tasks surfaced for catch-up — also bypass re-classification
- Alternative injection (AV-01 — bypasses ALL defense layers):
  1. Direct write to `.claude/scheduled_tasks.json` via Bash/Write tool
  2. Classifier DELAYED EFFECTS only fires on CronCreate tool use, NOT file writes
  3. `zy6()` trusts any well-formed JSON array
- Remote variant: `cli.js:12713391` — CCR agents spawn in Anthropic cloud (feature-gated)
- Full attack vector analysis: see `../findings/03_ISB02_CRONCREATE_PERSISTENCE.md` (6 vectors)

### 9) .mcp.json Repo Trust Flow (NEW)

- Entry: user clones repo containing `.mcp.json`.
- Anchors:
  - `cli.js:10489880` — subagent reads `.mcp.json` during codebase survey
  - `cli.js:10509666` — "Check MCP configuration (.mcp.json) for browser automation tools"
  - `cli.js:10511560` — "Ask if they want you to add the MCP server configuration to .mcp.json"
  - `cli.js:10581635` — plugin/MCP server management
- Flow:
  1. User opens project in Claude Code
  2. Codebase survey subagent reads `.mcp.json`
  3. MCP servers defined in `.mcp.json` can be suggested/configured
  4. Plugin marketplace allows installing MCP servers with project or global scope
- Risk: malicious repo ships `.mcp.json` with attacker-controlled MCP server

### 10) Network Proxy Allowlist Flow (Defensive Control)

- Entry: Bash/tool makes HTTP or CONNECT request.
- Anchors:
  - `cli.js:4354395` — `blocked-by-allowlist` response
  - `cli.js:4355314` — proxy filter check
- Flow:
  1. HTTP request → proxy intercepts
  2. `q.filter(port, hostname, socket)` checks against allowlist
  3. IF blocked: 403 with `X-Proxy-Error: blocked-by-allowlist`
  4. IF allowed: proxy forwards (with optional MITM for SSL inspection)
  5. CONNECT tunnels follow same allowlist check
- Mitigation: confirms network egress is controllable when sandbox proxy is active

### 11) Credential / API Key Flow

- Anchor: `cli.js:3516317` — keychain save via macOS `security` CLI
- API key from `ANTHROPIC_API_KEY` env or OAuth tokens
- `x-api-key` header for API calls
- OAuth code/token exchange with localhost callback
- `flushTelemetry()` runs before logout clears auth state
