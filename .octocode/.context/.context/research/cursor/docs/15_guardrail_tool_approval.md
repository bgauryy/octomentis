# Guardrail: Tool Approval & Permission System

**Source:** `workbench.desktop.main.js` at charOffset ~31714400
**Service:** `ComposerDecisionService` / `AutorunSettings`

---

## Permission Denial Reason Codes

### Shell/Terminal Tool Denials

| Reason Code | Internal Name | Meaning |
|-------------|---------------|---------|
| `shell.needs_approval` | (default) | Command not in allowlist, needs user approval |
| `shell.not_allowlisted` | `notInAllowlist` | Command explicitly not in allowlist |
| `shell.delete_protection` | `deleteProtection` | Delete operation blocked by `yoloDeleteFileDisabled` |
| `shell.readonly_mode` | `readonlyMode` | Agent is in read-only mode |
| `shell.blocked_by_hook` | `hookBlocked` | Pre-execution hook rejected the command |

### MCP Tool Denials

| Reason Code | Internal Name | Meaning |
|-------------|---------------|---------|
| `mcp.tool_not_allowlisted` | `notInAllowlist` | MCP tool not in allowlist |
| `mcp.browser_protection` | `playwrightProtection` | Browser automation tool blocked |
| `mcp.tools_protection` | `mcpToolsProtection` | MCP tools auto-run disabled |
| `mcp.readonly_mode` | `readonlyMode` | Read-only mode active |
| `mcp.blocked_by_hook` | `hookBlocked` | Hook rejected the tool call |

### File Edit Denials

| Reason Code | Internal Name | Meaning |
|-------------|---------------|---------|
| `write.needs_approval` | (default) | Write needs approval |
| `write.out_of_workspace` | `outOfWorkspace` | File is outside workspace boundaries |
| `write.restricted_file` | `restrictedFile` | File is in restricted path |
| `write.cursor_ignore` | `cursorIgnore` | File matches `.cursorignore` pattern |
| `write.admin_block` | `adminBlock` | Team admin blocked this operation |

## Approval Modes

```javascript
{
  ASK_EVERY_TIME: "ask_every_time",
  YOLO: "yolo",
  FULL_YOLO: "full_yolo"
}
```

## Default Disabled State (strictest)

```javascript
{
  isAdminControlled: false,
  isDisabledByAdmin: true,
  browserFeatures: false,
  allowedCommands: [],
  blockedCommands: [],
  deleteFileProtection: true,
  outsideWorkspaceProtection: true,
  enableRunEverything: false,
  mcpAllowedTools: [],
  mcpToolsProtection: true,
  playwrightProtection: false
}
```

## Smart Allowlist

When `smartAllowlistEnabled: true`, Cursor uses an AI-based classification to determine if a command is safe to run automatically. The `smartAllowlistDenylist` array contains patterns that override the smart classification.

## Team Admin Controls

Admin-enforced settings fetched via `getTeamAdminSettings()`:

| Control | Field |
|---------|-------|
| Auto-run commands | `autoRunControls.allowed[]` / `autoRunControls.blocked[]` |
| Run everything | `autoRunControls.enableRunEverything` |
| MCP tool allowlist | `autoRunControls.mcpToolAllowlist[]` |
| Delete protection | `autoRunControls.deleteFileProtection` |
| Browser protection | `autoRunControls.browserProtection` |
| MCP auto-run | `autoRunControls.disableMcpAutoRun` |
| Sandboxing | `autoRunControls.sandboxingControls` |
| Workspace trust | `workspaceTrustControls.enabled` |
| Extension signing | `extensionSigningSettings.verificationEnabled` |
| Cursor ignore | `cursorIgnoreControls.hierarchicalEnabled` |
| Allowed extensions | `allowedExtensions` (JSON object) |

Admin settings are cached locally and re-fetched every 5 minutes.
