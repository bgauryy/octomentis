# Antigravity — Google's AI Code Editor (Reverse Engineering Research)

**Date:** 2026-04-14
**Artifact:** `Antigravity.dmg` (bzip2, 204MB → 694MB disk image)
**SHA256:** `86644c8c7ce06e40733595c20c35ffececfe67193058f20ab7118cc943efa7a5`
**Version:** 1.22.2 (package version 1.107.0)
**Bundle ID:** `com.google.antigravity`
**Copyright:** "Copyright (C) 2025 Google LLC. All rights reserved"

## TL;DR

Antigravity is **Google's unreleased AI-native code editor** — a full VS Code fork (Electron 39.2.3) with a **Go-based language server** running a multi-agent system internally codenamed **"Jetski"** with an agentic framework called **"Cortex"**. It competes directly with Cursor, Windsurf, and GitHub Copilot. The AI agent ("Cascade") has 25+ tools including browser automation, file editing, terminal execution, web search, subagent delegation, and MCP integration.

## Identity & Lineage

| Property | Value |
|----------|-------|
| App Name | Antigravity |
| CLI Alias | `agy` |
| Data Folder | `~/.antigravity` |
| URL Scheme | `antigravity://` |
| Publisher | Google (`com.google.antigravity`) |
| VS Code Base | Fork (Help books reference "VS Code HelpBook") |
| Principal Class | `AtomApplication` (Atom/VS Code lineage) |
| Electron Version | 39.2.3 |
| Node.js | 22.20.0 |
| Extension Marketplace | Open VSX (`https://open-vsx.org/vscode/gallery`) |
| Docs URL | `https://antigravity.google/docs` |
| Pricing URL | `https://one.google.com/ai?utm_source=antigravity` |
| Internal Flag | `isGoogleInternal: false` (external release) |

## Internal Codenames

| Codename | Meaning |
|----------|---------|
| **Jetski** | The AI agent system (agent UI, language server, prompt templates) |
| **Cortex** | The agentic execution framework (steps, tools, planner, executor) |
| **Cascade** | Individual agent conversation/session (like Cursor's "chat") |
| **Exa** | The backend services platform (API server, seat management, analytics) |
| **Astro** | Onboarding mascot (asset: `astro.png`) |

## Architecture Overview

```
┌──────────────────────────────────────────────────┐
│              Antigravity App (Electron)           │
│  ┌─────────────┐  ┌──────────────────────────┐   │
│  │  VS Code    │  │  Jetski Agent UI         │   │
│  │  Core       │  │  (React/Preact/Redux)    │   │
│  │  (main.js   │  │  (jetskiAgent/main.js    │   │
│  │   11.9MB)   │  │   11.4MB)                │   │
│  └─────────────┘  └──────────────────────────┘   │
│          │                    │                    │
│          │    gRPC/ConnectRPC │                    │
│          ▼                    ▼                    │
│  ┌──────────────────────────────────────────┐    │
│  │  Language Server (Go, 92MB binary)        │    │
│  │  - Cortex Agent Framework                 │    │
│  │  - Prompt Template Engine                 │    │
│  │  - Tool Execution Layer                   │    │
│  │  - MCP Client                             │    │
│  │  - Browser Automation (CDP)               │    │
│  └──────────────────────────────────────────┘    │
│          │              │            │            │
│          ▼              ▼            ▼            │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│   │ Extension│  │  Google  │  │  Exa     │      │
│   │  Server  │  │  Cloud   │  │  Backend │      │
│   │  (gRPC)  │  │  APIs    │  │  (API)   │      │
│   └──────────┘  └──────────┘  └──────────┘      │
└──────────────────────────────────────────────────┘
```

### Key Components

1. **Electron Shell** — VS Code fork with custom branding, custom welcome, theme imports
2. **Jetski Agent UI** — React/Preact/Redux/TanStack Router frontend (11.4MB bundle)
3. **Language Server** — Go binary (92MB Mach-O x86_64), the brain of the system
4. **Extension** — `google.antigravity` VS Code extension (3.2MB webpack bundle)
5. **Code Executor** — `antigravity-code-executor` for running code in sandboxes
6. **Dev Containers** — `antigravity-dev-containers` for remote development
7. **Remote SSH** — `antigravity-remote-openssh` for SSH remote connections

## Agent Tools (25+ tools)

Extracted from the language server binary:

### Core File Operations
| Tool | Description |
|------|-------------|
| `read_file` | Read file contents |
| `write_to_file` | Write content to a file |
| `edit_file` | Edit an existing file |
| `create_file` | Create a new file |
| `delete_file` | Delete a file |
| `replace_content` | Replace content in a file |

### Search & Navigation
| Tool | Description |
|------|-------------|
| `grep_search` | "Use ripgrep to find exact pattern matches within files or directories" |
| `codebase_search` | Semantic codebase search |
| `file_search` | Search for files by name |
| `find_by_name` | Find files by name pattern |
| `list_directory` | List directory contents |

### Execution
| Tool | Description |
|------|-------------|
| `execute_command` | Execute a shell command |
| `run_command` | Run a terminal command |
| `manage_task` | Manage background tasks ("kill them or check their status") |
| `send_message` | Send messages to tasks |

### Web & Browser
| Tool | Description |
|------|-------------|
| `web_search` | Search the web |
| `read_url_content` | "Read URL content from" a webpage |
| `open_url` | Open a URL |
| `check_deploy_status` | Check deployment status |
| **Browser Tools** (30+ sub-tools) | Full browser automation via CDP |

### Browser Automation (CDP-powered)
| Tool | Purpose |
|------|---------|
| `browser_click` / `browser_click_element` | Click interactions |
| `browser_input` | Text input |
| `browser_url` | Navigate to URL |
| `browser_screenshot` | Take screenshots |
| `browser_javascript` | Execute JS in browser |
| `browser_scroll_up/down` | Scroll page |
| `browser_get_dom` | Get DOM tree |
| `browser_pages` | List open pages |
| `browser_press_key` | Keyboard input |
| `browser_select_option` | Select dropdown options |
| `browser_drag_pixel_to_pixel` | Drag & drop |
| `browser_mouse_move/down/up/wheel` | Low-level mouse |
| `browser_get_network_request` | Inspect network |
| `browser_list_network_requests` | List network traffic |
| `browser_refresh_page` | Refresh page |
| `browser_resize_window` | Resize window |
| `browser_subagent` | Spawn browser sub-agents |

### AI & Agents
| Tool | Description |
|------|-------------|
| `mcp_tool` | Call MCP server tools |
| Subagent system | `invoke_subagent`, `define_subagent` |

### Notebook
| Tool | Description |
|------|-------------|
| `notebook_edit` | Edit Jupyter notebooks |

## Prompt Templates

Extracted from the Go binary (embedded Go templates at `google3/third_party/jetski/prompt/template_provider/templates/`):

### System Prompts
| Template | Purpose |
|----------|---------|
| `system_prompts/identity.tmpl` | Agent identity and persona |
| `system_prompts/function_call.tmpl` | Function/tool calling instructions |
| `system_prompts/planning_mode.tmpl` | Planning mode behavior |
| `system_prompts/planning_mode_artifacts.tmpl` | Planning mode with artifacts |
| `system_prompts/communication_style.tmpl` | Response style and tone |
| `system_prompts/plugins.tmpl` | Plugin/extension integration |
| `system_prompts/test_funcmap.tmpl` | Testing function map |

### Step Strings
| Template | Purpose |
|----------|---------|
| `step_strings/helpers/` | Step output formatting |
| `step_strings/helpers/default_status_output_string.tmpl` | Default status messages |

### Helpers
| Template | Purpose |
|----------|---------|
| `helpers/errors.tmpl` | Error message formatting |

### Notable Prompt Fragments (from binary strings)
- "Draw inspiration from modern, beautiful, and dynamic web designs"
- "Review them carefully and always take them into account when you generate responses and code"
- "You should **NEVER** give up fixing the issue if the regression is related to your changes"
- "Make sure you test your solution after major modifications and before using the finish tool"
- "However, you do not have internet access so please do not try to install any new libraries" (sandbox mode)
- "ReplacementChunks is a required parameter. Follow the function call schema exactly."
- "TargetFile is a required parameter. Please follow the function call schema exactly."
- "you may not create the file diffs artifact, the system will update it automatically"
- "user reviewed the command and decided not to run it, check with the user to continue"
- "The following names are already taken, you MUST pick a different name"

## Cortex Agent Framework

The agent framework is called **Cortex** (`google3/third_party/jetski/cortex/`).

### Protobuf Types (from `cortex_go_proto`)
| Type | Purpose |
|------|---------|
| `AgentMessage` | Messages between agent and user |
| `AgentSetting` | Agent configuration |
| `AgentPlugins` / `AgentScripts` | Plugin and script support |
| `CascadeConfig` | Per-conversation config |
| `CascadeRunState` | Running state of a cascade |
| `CortexPlanState` | Planning state |
| `CortexStepState` / `CortexStepType` | Step execution state |
| `CodingStepState` | Code generation state |
| `CortexMemory` | Conversation memory |
| `SubagentSpec` | Subagent definitions |
| `CustomAgentSpec` | Custom agent definitions |
| `WorkflowSpec` | Workflow definitions |
| `McpServerSpec` / `McpPromptSpec` | MCP configuration |
| `HeuristicPrompt` | Dynamic prompt heuristics |
| `PermissionGrant` / `PermissionScope` | Permission management |
| `AutoRunDecision` | Auto-execution decisions |
| `FileDiff_Modify` / `FileDiff_Remove` | File diff tracking |
| `TaskSnapshot` | Task state snapshots |
| `TrajectoryScope` | Conversation trajectory |
| `SdkToolOverride` | Tool override configuration |

### Agent Architecture Modules
| Module | Purpose |
|--------|---------|
| `cortex/agent_state_component` | Agent state management, subscriptions, cost tracking |
| `cortex/tools/code` | File editing tools (ReplacementChunk) |
| `cortex/tools/browser` | Browser automation tools |
| `cortex/tools/knowledge` | Knowledge base tools |
| `cortex/tools/notebook` | Notebook editing tools |
| `cortex/tools/subagent` | Subagent management |
| `cortex/tools/tooloverrides` | Tool override system |
| `cortex/sdk` | Customization SDK (hooks, mixins, MCP) |
| `cortex/sdk/sdkprocess` | SDK process management |

### Customization System
The SDK supports extensive customization:
- `GetSystemPrompt` — Custom system prompts
- `GetToolConverters` / `GetToolOptions` — Custom tool configurations
- `GetStepHandlers` / `GetStepStringConverters` — Custom step handling
- `PreInvocationHooks` / `PostInvocationHooks` / `StopHooks` — Lifecycle hooks
- `HandlerDecorators` — Handler decoration pattern
- `TrajectoryToChatMessages` — Custom trajectory conversion

## gRPC Services

### Language Server Service (`exa.language_server_pb.LanguageServerService`)
Key endpoints:
- `SendCascadeRequest` / `CancelCascadeRequest` — Agent conversations
- `SendAgentMessage` — Agent messaging
- `ForkConversation` / `CheckoutWorktree` — Git worktree management
- `GetRevertPreview` / `UpdatePRForWorktree` — PR integration
- `WriteFile` / `WatchDirectory` — File operations
- `GetModelResponse` / `GetModelStatuses` — Model management
- `ListMcpResources` / `CompleteMcpOAuth` — MCP support
- `StreamAgentStateUpdates` — Real-time agent state
- `StreamCascadePanelReactiveUpdates` — UI updates
- `GetMatchingContextScopeItems` — Context matching
- `SmartFocusConversation` / `SmartOpenBrowser` — Smart actions
- `ImportFromCursor` — Cursor settings import
- `GetTranscription` — Audio transcription
- `GetAllCustomAgentConfigs` — Custom agent management
- `UpdateCustomization` / `UpdateCustomizationPathsFile` — Customization updates

### Extension Server Service (`exa.extension_server_pb.ExtensionServerService`)
Key endpoints:
- `ExecuteCommand` — Shell command execution
- `ReadTerminal` / `SendTerminalInput` / `TerminateCommand` — Terminal management
- `LaunchBrowser` / `GetChromeDevtoolsMcpUrl` — Browser automation
- `WriteCascadeEdit` / `OpenDiffZones` — Code editing
- `GetLintErrors` — Linting
- `GetDefinition` / `FindAllReferences` — LSP operations
- `EditNotebook` / `ReadNotebook` / `ExecuteNotebook` — Notebook support
- `StartAudioRecording` / `EndAudioRecording` — Audio input
- `RunExtensionCode` — Extension code execution
- `GetSecretValue` / `StoreSecretValue` — Secret management
- `PlaySound` — Audio feedback

### API Server Service (`exa.api_server_pb.ApiServerService`)
Key endpoints:
- `GetWebSearchResults` / `GetWebSearchRedirect` — Web search
- `GetEmbeddings` — Embedding generation
- `GetImageGeneration` — Image generation
- `GetCascadeModelConfigs` / `GetCommandModelConfigs` — Model configs
- `GetDefaultWorkflowTemplates` — Workflow templates
- `GetMcpServerTemplates` — MCP server templates
- `GenerateSyntheticRule` — Rule generation
- `RecordCortexTrajectory` / `RecordCortexTrajectoryStep` — Telemetry
- `FetchTrajectoryShareByUser` — Sharing
- `GetUnleashContextFields` — Feature flags
- `RunCodeAlignment` — Code alignment

### Other Services
- `exa.cascade_plugins_pb.CascadePluginsService` — Plugin marketplace
- `exa.seat_management_pb.SeatManagementService` — User/team management
- `exa.model_management_pb.ModelManagementService` — Local model management
- `exa.opensearch_clients_pb.KnowledgeBaseService` — Knowledge base (Slack, Jira, GitHub, Google Drive)
- `exa.opensearch_clients_pb.CodeIndexService` — Code search indexing
- `exa.remoting.RemotingService` — Remote connections
- `google.internal.cloud.code.v1internal.PredictionService` — Google Cloud AI
- `google.internal.cloud.code.v1internal.JetskiService` — Jetski health
- `google.cloud.aiplatform.master.PredictionService` — Vertex AI

## VS Code Extension Commands

Full command list extracted from the app:

### Agent Interaction
- `antigravity.prioritized.chat.open` — Open agent chat
- `antigravity.prioritized.command.open` — Open command palette
- `antigravity.prioritized.terminalCommand.open` — Terminal command
- `antigravity.prioritized.submitCodeAcknowledgement` — Accept code
- `antigravity.prioritized.agentAcceptAllInFile` / `agentRejectAllInFile` — Bulk accept/reject
- `antigravity.prioritized.agentFocusNextHunk` / `agentFocusPreviousHunk` — Navigate hunks
- `antigravity.prioritized.agentAcceptFocusedHunk` / `agentRejectFocusedHunk` — Accept/reject hunk

### Autocomplete
- `antigravity.prioritized.supercompleteAccept` — Accept completion (Tab)
- `antigravity.prioritized.supercompleteEscape` — Dismiss completion
- `antigravity.prioritized.tabJumpAccept` / `tabJumpEscape` — Tab jump

### System
- `antigravity.login` / `antigravity.cancelLogin` — Authentication
- `antigravity.generateCommitMessage` — AI commit messages
- `antigravity.restartLanguageServer` — Restart LS
- `antigravity.openBrowser` — Built-in browser
- `antigravity.openChangeLog` — Changelog
- `antigravity.downloadDiagnostics` — Diagnostics

### Import
- `antigravity.importVSCodeSettings` / `importVSCodeExtensions` — VS Code import
- `antigravity.importCursorSettings` / `importCursorExtensions` — Cursor import
- `antigravity.importWindsurfSettings` / `importWindsurfExtensions` — Windsurf import
- `antigravity.importCiderSettings` — Cider import (Google internal)

### Customization
- `antigravity.customization.customAgents` — Custom agents
- `antigravity.customization.mcp` — MCP configuration
- `antigravity.customization.skills` — Skills

## Custom Editors

### Workflow Editor
Matches: `**/.agent/workflows/**/*.md`, `**/.gemini/jetski*/global_workflows/*.md`, `**/.gemini/antigravity*/global_workflows/*.md`

### Rule Editor
Matches: `**/.agent/rules/**/*.md`, `**/_agent/rules/**/*.md`

## MCP Configuration

Schema at `schemas/mcp_config.schema.json`:
- `mcpServers` — Map of server configurations
  - `command` / `args` / `env` / `cwd` — Stdio transport
  - `serverUrl` / `headers` — HTTP transport
  - `authProviderType: "google_credentials"` — Google auth
  - `oauth: { clientId, clientSecret }` — OAuth config
  - `disabled` / `disabledTools` — Selective disable
  - `tools[name].background: "off" | "always"` — Background execution

Source path in Google3: `google3/third_party/jetski/cortex/utils/mcp/config.schema.json`

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `google-auth-library` | Google sign-in |
| `@connectrpc/connect` | gRPC to language server |
| `@bufbuild/protobuf` | Protobuf serialization |
| `@exa/proto-ts` | Internal protobuf types |
| `@exa/agent-ui-toolkit` | Agent UI components |
| `unleash-client` | Feature flags |
| `@reduxjs/toolkit` / `react-redux` | State management |
| `@tanstack/react-router` | Client-side routing |
| `@lexical/react` | Rich text editing |
| `mermaid` | Diagram rendering |
| `katex` | Math rendering |
| `highlight.js` / `lowlight` | Syntax highlighting |
| `react-markdown` / `remark-gfm` | Markdown rendering |
| `lucide-react` | Icons |
| `tailwindcss` | Styling |
| `preact` (aliased as react) | UI framework |

## Security Analysis

**Full report:** [security.md](./security.md)

**Verdict:** `review recommended` — legitimate product, significant privacy/security surface

### Key Security Findings

| # | Finding | Severity | Confidence |
|---|---------|----------|------------|
| 1 | Hostname SHA256 in auto-update URL (device fingerprinting) | `medium` | `confirmed` |
| 2 | Dual telemetry: VS Code + Google Clearcut (`play.googleapis.com/log`) | `medium` | `confirmed` |
| 3 | `NSAllowsArbitraryLoads: true` — ATS disabled | `medium` | `confirmed` |
| 4 | Shared self-signed localhost cert (same key all installs) | `low` | `confirmed` |
| 5 | Hardcoded Unleash API key + Codeium app name | `low` | `confirmed` |
| 6 | Agent blast radius: terminal + browser + file + subagent | `high` | `confirmed` |
| 7 | Google internal `.corp.google.com` URLs in external build | `low` | `confirmed` |
| 8 | Codeium/Windsurf codebase lineage (state IDs, protos) | `info` | `confirmed` |
| 9 | `NODE_TLS_REJECT_UNAUTHORIZED` environment check | `low` | `confirmed` |
| 10 | Remote prompt template override via Unleash feature flags | `medium` | `likely` |
| 11 | Broad macOS permissions (Camera, Mic, Bluetooth, AppleScript) | `low` | `confirmed` |

### Outbound Network Endpoints

| Endpoint | Purpose |
|----------|---------|
| `play.googleapis.com/log` | Clearcut analytics (binary protobuf, OAuth) |
| `cloudcode-pa.googleapis.com` | Cloud Code API (model requests) |
| `antigravity-auto-updater-*.run.app` | Auto-updates (includes hostname hash) |
| `dl.google.com/antigravity/insider_secret` | Insider build authentication |
| `antigravity-unleash.goog` | Feature flags |
| `feedback-pa.googleapis.com` | User feedback |

### Sandbox (sandbox-wrapper.sh)
- macOS Seatbelt kernel sandbox for command execution
- Default deny file writes outside workspace + `/tmp`
- Optional network isolation per command
- Processes `.gitignore` + `.agyignore`
- **Gap:** Language server itself runs unsandboxed

### Agent Config Keys
```
CASCADE_AUTO_EXECUTION_POLICY     — Auto-run policy
CASCADE_ALLOWED_COMMANDS          — Command whitelist
CASCADE_DENIED_COMMANDS           — Command blacklist
SECURE_MODE_ENABLED               — Global security toggle
ALLOW_AGENT_ACCESS_NON_WORKSPACE_FILES — File scope expansion
ALLOW_CASCADE_ACCESS_GITIGNORE_FILES   — Gitignore bypass
BROWSER_JS_EXECUTION_POLICY       — Browser JS safety
BROWSER_ALLOWLIST                 — Allowed websites
ARTIFACT_REVIEW_MODE              — Code review mode
PLANNING_MODE                     — Think-before-act mode
```

### Permissions Requested
- Camera, Microphone, Bluetooth, AppleScript access
- `NSAllowsArbitraryLoads: true` — No transport security restrictions
- Full file system access within workspace
- Shell command execution
- Browser automation (CDP)
- Audio recording and transcription

### Code Signing
- Signed app bundle with `_CodeSignature/CodeResources`
- ASAR integrity validation: `ElectronAsarIntegrity` in Info.plist

## Codeium Lineage

Evidence that Antigravity derives from Codeium/Windsurf:
- State IDs: `codeium.snoozeEndTimeKey`, `codeium.installationId`
- Unleash app name: `"codeium-extension"`
- Proto files: `exa_codeium_common_pb`
- Environment: `CODEIUM_LANGUAGE_SERVER_BIN`
- Settings namespace migration: `codeium.*` → `antigravity.*`
- Enum: `CodeiumState.WARNING` still present

## Google Internal References

The binary contains references to Google's internal infrastructure:
- `google3/third_party/jetski/` — Google3 monorepo path
- `google.internal.cloud.code.v1internal` — Internal Cloud APIs
- `Cider` — Google's internal IDE (import support)
- `CloudAICompanionProjects` — Cloud AI integration
- `buganizer` — Google's bug tracker
- `moma` — Google's internal systems
- `Cloudtop` — Google's cloud workstations
- `borg` — Google's container orchestration ("cannot run commands in borg")
- `CNS sandbox mounts` — Google's distributed file system

### Internal URLs Leaked in External Build
```
https://agent-marketplace.corp.google.com
https://dashboards.corp.google.com/view/_71383517_...
https://flyway.corp.google.com/trajectory/conversation/gc
https://g3doc.corp.google.com/devtools/jetski/g3doc/features/agent/agent-custom-agents.md
https://goto.google.com/jetski-skills
https://wf-boring-coyote.corp.google.com/
```
