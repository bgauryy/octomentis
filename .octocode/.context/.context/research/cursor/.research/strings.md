# High-Signal Strings — Cursor v3.0.16

## Cursor API Endpoints

| URL | Location | Purpose |
|-----|----------|---------|
| `https://api2.cursor.sh` | main.js | Main API server |
| `https://api2.cursor.sh/aiserver.v1.AnalyticsService/UploadIssueTrace` | main.js | Issue trace upload |
| `https://api3.cursor.sh` | product.json | Stats/telemetry proxy |
| `https://api3.cursor.sh/tev1/v1` | product.json | Statsig log event proxy |
| `https://marketplace.cursor.sh/` | main.js | Extension marketplace |
| `https://marketplace.cursorapi.com/` | main.js | Fallback marketplace |
| `https://staging-marketplace.cursor.sh/` | main.js | Staging marketplace |
| `https://cursor.blob.core.windows.net/remote-releases/` | product.json | Remote server CDN |
| `https://cursor.com/privacy` | main.js, cliProcessMain.js | Privacy policy |
| `https://cursor.com/security` | main.js | Security page |
| `https://cursor.com/downloads` | product.json | Download page |
| `https://cursor.com/license.txt` | product.json | License |
| `http://cursorapi.com/updates` | product.json | Backup update URL |

## GitHub Endpoints
| URL | Purpose |
|-----|---------|
| `https://github.com/getcursor/cursor/` | Main repo |
| `https://github.com/getcursor/cursor/issues/new` | Issue reporting |
| `https://github.com/anthropics/claude-agent-sdk-typescript` | Claude Agent SDK repo |
| `https://raw.githubusercontent.com/microsoft/vscode/main/src/vscode-dts/vscode.proposed.cursor.d.ts` | Cursor API proposals |
| `https://raw.githubusercontent.com/microsoft/vscode/main/src/vscode-dts/vscode.proposed.cursorNoDeps.d.ts` | Cursor NoDeps API |
| `https://raw.githubusercontent.com/microsoft/vscode/main/src/vscode-dts/vscode.proposed.cursorPublic.d.ts` | Cursor Public API |
| `https://raw.githubusercontent.com/microsoft/vscode/main/src/vscode-dts/vscode.proposed.cursorTracing.d.ts` | Cursor Tracing API |

## API Keys / Secrets
| Key | Value | Location |
|-----|-------|----------|
| Statsig client key | `client-Bm4HJ0aDjXHQVsoACMREyLNxm5p6zzuzhO50MgtoT5D` | product.json |
| AI config aria key | `control-key` | product.json |

## AI Model IDs (from workbench.desktop.main.js)

### Claude 3 Family
- `claude-3-haiku-20240307`
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-sonnet-20240229-v1`

### Claude 3.5/3.7 Family
- `claude-3.5-sonnet`
- `claude-3.7-sonnet`
- `claude-3.7-sonnet-finetuned-cursor-20250514-v1`
- `claude-3-5-haiku-20241022-v1`

### Claude 4 Family
- `claude-4-sonnet`
- `claude-4-opus`
- `claude-4-5-sonnet-20250929`
- `claude-4.5-haiku`
- `claude-4.5-sonnet`
- `claude-4.5-opus-high`
- `claude-4.5-opus-high-thinking`
- `claude-4.6-opus-high-fast`
- `claude-haiku-4-5-20251001-v1`
- `claude-opus-4-1-20250805-v1`
- `claude-opus-4-20250514-v1`

### Other References
- `gpt4Requests`, `gpt4_requests`, `gpt4MaxRequests`, `gpt4_max_requests`
- `gpt5`
- `claude-code`
- `claude-desktop`

## Chain-of-Thought Identifiers
- `opus2ChainPlan`
- `opus2ChainApplyPlan`
- `opus2ChainReflect`
- `opusChainGetFilePaths`
- `opusChainGetPlan`
- `opusChainGetFileInstruction`
- `opusChainReflect`

## Feature Flags
- `claude_code_hooks_enabled`
- `claude_plugins_root_scan`

## Application Identity
- App ID (win32x64): `{D7D7D7D7-7D7D-7D7D-7D7D-7D7D7D7D7D7D}`
- Server app name: `cursor-server`
- Server data folder: `.cursor-server`
- Tunnel app name: `cursor-tunnel`
- ToDesktop ID: `230313mzl4w4u92`
