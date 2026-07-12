# Entities

## Core Entities

### MCP Trust Boundary
- `mcp add` transport command flow
  - Role: MCP server onboarding and trust-boundary setup
  - Anchors: `cli.js:12998618`, `cli.js:13002275`
- `m46()` — enterprise MCP server filter (splits allowed/blocked)
- `g46()` — enterprise MCP config presence check
- `Qb4()` — dynamic config merge validator
- `SSETransport` — remote streaming transport for MCP servers

### Permission System
- `pK7(...)` — permission mode resolver (CLI inputs → runtime mode)
  - Anchor: `cli.js:13175733`
- `m0K(...)` — tool permission evaluator (deny/ask/passthrough)
  - Anchor: `cli.js:9923142`
- `yJY` — interactive resolver (auto-allows in bypass mode)
- `ig8(...)` — always-deny rules (wins over bypass)
- `disableBypassPermissionsMode` — policy key to block bypass at org level
  - Anchor: `cli.js:1089201`

### Sandbox System
- `Zx` — sandbox eligibility check function
- `dangerouslyDisableSandbox` — BashInput schema field
  - Anchor: `cli.js:9451634`
- `areUnsandboxedCommandsAllowed()` — policy gate for sandbox disable
  - Anchor: `cli.js:9438643`
- `isSandboxingEnabled()` — global sandbox toggle
- `apply-seccomp` — Linux seccomp binary in `vendor/seccomp/`
  - Anchor: `cli.js:4416327`
- `bwrap` / `seatbelt` — Linux bubblewrap and macOS sandbox profiles

### Audio/Voice System
- `HDK` — `startRecording()` main entry function
  - Anchor: `cli.js:9269000`
- `Bg8()` — lazy initializer for audio-capture native addon
- `YDK` — native binding wrapper (startNativeRecording/stopNativeRecording/isNativeRecordingActive)
- `mg8` — `connectVoiceStream()` WebSocket STT connection
- `AUDIO_CAPTURE_NODE_PATH` — env override for native addon path
- `voiceEnabled` — settings toggle for voice feature
- `requestMicrophonePermission()` — OS mic permission gate

### Telemetry System
- `Ca8()` — OTEL provider check (gated by `CLAUDE_CODE_ENABLE_TELEMETRY`)
- `com.anthropic.claude_code` — OTEL meter name
  - Anchor: `cli.js:7911658`
- `Ia` — Prometheus exporter class (port 9464, endpoint `/metrics`)
  - Anchor: `cli.js:7893712`
- `d("tengu_*", {})` — internal analytics dispatch function
  - No dedicated opt-out identified
- `Qgz()` — telemetry flush function

### Credential System
- `FY6` — keychain service identifier
- `a3()` — credential store selector (keychain on macOS, plaintext otherwise)
- `FN1` — plaintext credential store
- `Xuq` — macOS keychain store
- `bJ()` — auth header builder
- `ua` — OAuth flow handler

### Enterprise Policy
- `policySettings` — enterprise managed settings source
- `c66()` / `_f6()` / `Iw8()` / `_x7()` — settings source label functions
- Enterprise settings override user/project settings

### Scheduled Task System (NEW)
- `wS4(cron, prompt, recurring, durable, agentId)` — cron job creation function
  - Anchor: `cli.js:6621431`
- `zy6()` — reads `.claude/scheduled_tasks.json`
- `kF1()` — writes `.claude/scheduled_tasks.json`
- `Ks8()` — in-memory session-only job store
- `CronCreate` / `CronDelete` / `CronList` — tool names
  - Anchor: `cli.js:6627029`
- `XS4` — timeout constant (300000ms = 5 min)
- `.claude/scheduled_tasks.json` — durable persistence file

### .mcp.json and Plugin System (NEW)
- `.mcp.json` — repo-level MCP configuration file
- `wB()` — plugin registry accessor
- `xC6()` — plugin uninstall function
- `k4()` — plugin name/marketplace parser
- `pv()` — plugin entry resolver
- `ySK()` — scope resolver for plugin installations

### Network Proxy / Allowlist (NEW)
- `q.filter(port, hostname, socket)` — network allowlist check function
  - Anchor: `cli.js:4355314`
- `hr6()` — parent proxy bypass check
- `Rr6()` — parent proxy routing
- `Nb1()` — tunnel connection creator
- `su_()` — MITM socket connect
- `vm()` — hostname normalization for allowlist comparison

### child_process Execution
- `child_process` execution wrappers
  - Role: command execution via `execSync` and spawn
  - Anchors: `cli.js:892377`, `cli.js:953087`
