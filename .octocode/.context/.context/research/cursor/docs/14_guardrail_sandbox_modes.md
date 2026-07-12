# Guardrail: Sandbox Mode Prompts

**Source:** `workbench.desktop.main.js` at charOffset ~28762401
**Variable:** `n0n` (sandbox mode descriptions shown to users)

---

## Sandbox Mode Descriptions (shown in UI)

### SANDBOX_MODE (Default)
```
Commands run in a protected sandbox that limits access to your files, network, and git. You can allowlist specific commands to run with full access when needed. Be cautious of potential prompt injection risks.
```

### ALLOWLIST_MODE
```
Only commands you've added to your allowlist will run automatically. Other commands will require user approval. Be cautious of potential prompt injection risks from external sources. Use at your own risk.
```

### RUN_EVERYTHING_MODE (Full YOLO)
```
All commands will run automatically. Be cautious of potential prompt injection risks from external sources. Use at your own risk.
```

## Sandbox Network Policy

**Config key:** `sandboxNetworkDefault`

| Storage Value | Mapped Policy |
|---------------|---------------|
| `"ask"` | `user_config_with_defaults` |
| `"enabled"` | `allow_all` |
| `"user_config_only"` | `user_config_only` |
| `"user_config_with_defaults"` | `user_config_with_defaults` (default) |
| `"allow_all"` | `allow_all` |

### One-Click Escalation

At charOffset 42896400, `allow_all` can be set programmatically:
```javascript
dg(e.storageService, "sandboxNetworkDefault").set("allow_all", void 0)
```

## YOLO Mode Defaults

```javascript
{
  yoloCommandAllowlist: [],
  yoloCommandDenylist: [],
  smartAllowlistEnabled: false,
  smartAllowlistDenylist: [],
  yoloMcpToolsDisabled: false,
  yoloDeleteFileDisabled: false,
  yoloOutsideWorkspaceDisabled: true,   // Protected by default
  yoloEnableRunEverything: false,
  isWebSearchToolEnabled: true,
  autoAcceptWebSearchTool: false,
  autoAcceptGenerateImageTool: false,
  autoApprovedModeTransitions: [],
  autoRejectedModeTransitions: []
}
```
