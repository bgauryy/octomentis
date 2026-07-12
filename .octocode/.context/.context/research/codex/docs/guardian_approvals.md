# Guardian Approvals System

**Source:** `external-agent-config-utils-BkNZ8A_e.js`, `vscode-api-BtEtzXmw.js`, `config-queries-Bj2dEPP6.js`
**Codex Version:** 26.325.31654 (build 1272)

---

## Overview

Guardian is Codex's approval subagent system. It acts as a secondary reviewer for elevated/dangerous operations when the user runs in sandboxed mode. It is **not a standalone prompt** — it's an architectural feature that uses a `guardian_subagent` approvals reviewer.

## How It Works

Guardian is a permissions mode between `auto` (sandboxed) and `full-access`. When enabled:

1. Codex runs commands in a sandbox (default behavior)
2. When Codex needs elevated permissions (outside sandbox), Guardian reviews the request
3. Guardian decides whether to approve or deny the elevated operation

## Configuration

### Agent Modes (Permissions Dropdown)

| Mode | Description |
|------|-------------|
| `read-only` | Read-only access |
| `auto` | Default sandboxed execution |
| `guardian-approvals` | Sandbox + Guardian subagent reviews elevated requests |
| `full-access` | Full system access (danger mode) |
| `custom` | User-defined via `config.toml` |

### Config Fields

| Field | Description |
|-------|-------------|
| `approval_policy` | The approval mode: `untrusted`, `on-failure`, `on-request`, `never` |
| `approvals_reviewer` | Set to `guardian_subagent` when Guardian mode is active |
| `sandbox_mode` | Sandbox policy type |
| `sandbox_workspace_write` | Whether sandbox allows workspace writes |

### Activation Logic

```
Guardian is available when:
  - Statsig feature flag enables it (via `isGuardianApprovalEnabledByStatsig`)
  - `auto` mode is in the list of available modes
  - Platform supports it

Guardian is active when:
  - config sandbox mode is `auto`
  - approvals_reviewer is `guardian_subagent`
```

## UI Strings

### Guardian Approval Tooltip (enabled)
```
Codex automatically runs commands
in a sandbox and uses Guardian
approvals for elevated requests
```

### Guardian Approval Tooltip (disabled)
```
Guardian approvals requires default sandboxed permissions
to be available in this workspace.
```

### Full Access Tooltip
```
Codex has full access over your
computer (elevated risk)
```

### Custom Mode Tooltip
```
Codex uses the permission defined in config.toml.
```

### Requirements Lock
```
Permissions are locked by requirements.toml
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `Ue()` | Computes available agent modes, Guardian availability, and current config |
| `Ve(mode, modes, isGuardianAvailable)` | Checks if a mode is valid (Guardian needs statsig flag) |
| `He(mode, modes, isGuardianAvailable)` | Validates preferred mode against available modes |
| `qe()` | Resolves the active non-full-access mode, factoring in Guardian preference |
| `We(mode, modes, custom)` | Determines if a mode allows Guardian/full-access/custom selection |

## Architecture Note

The Guardian subagent's **actual system prompt and decision logic** are server-side — they are **not** present in the Codex desktop client bundle. The client only:
1. Sends `approvals_reviewer: "guardian_subagent"` to the backend
2. Renders approval request/response UI
3. Manages the permissions dropdown state

The Guardian prompt/instructions live on the OpenAI backend (`chatgpt.com/backend-api`) and are not extractable from the Electron app.
