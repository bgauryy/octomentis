# MCP Tools — Model Context Protocol Integration Internals

**Confidence:** `confirmed` — protobuf types, MCP extension manifest, server config, auth status prompts

---

## Architecture Overview

MCP (Model Context Protocol) is Cursor's extensibility layer — it allows external tool servers to register tools that the LLM can invoke.

```
┌────────────────────────────────────────────────────────────────┐
│  Cursor IDE                                                     │
│  ┌──────────────────┐    ┌───────────────────────────────────┐ │
│  │  cursor-mcp      │    │  cursor-agent-exec                │ │
│  │  extension        │    │                                   │ │
│  │  ├─ MCP registry  │◄──┤  Dispatches CallMcpTool           │ │
│  │  ├─ Auth manager  │    │  Dispatches GetMcpTools           │ │
│  │  ├─ Health probes │    │  Dispatches FetchMcpResource      │ │
│  │  └─ Tool schemas  │    └───────────────────────────────────┘ │
│  └────────┬─────────┘                                           │
│           │                                                      │
│  ┌────────▼─────────────────────────────────────────────────┐   │
│  │  MCP Servers (external processes)                         │   │
│  │  ├─ cursor-browser-automation (built-in, Playwright)      │   │
│  │  ├─ user-installed MCP servers                            │   │
│  │  │   ├─ Each has tool descriptors (JSON schema)           │   │
│  │  │   ├─ Each may have resources (read-only data)          │   │
│  │  │   └─ Each may require authentication                   │   │
│  │  └─ Communication: stdio or HTTP                          │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

## How MCP Tools Are Registered

### Discovery Flow

```
1. cursor-mcp extension activates (onStartupFinished + onUri)
2. Reads MCP server configurations from:
   ├─ .cursor/mcp.json (workspace-level)
   └─ ~/.cursor/mcp.json (user-level)
3. For each configured server:
   ├─ Starts the server process (stdio) or connects (HTTP)
   ├─ Fetches tool schemas (JSON descriptors)
   ├─ Registers tools in the MCP registry
   └─ Writes descriptor files to: ~/.cursor/projects/<hash>/mcps/<server>/tools/<tool>.json
4. Tool descriptors are injected into the system prompt via $getMcpLeasePrompts()
```

### Tool Descriptor Format

Each MCP tool has a JSON descriptor containing:
- Tool name
- Description
- Parameter schema (JSON Schema format)
- Server identifier

These descriptors are stored on disk at:
```
~/.cursor/projects/<project-hash>/mcps/<server-name>/
├── tools/
│   ├── tool-name-1.json
│   ├── tool-name-2.json
│   └── ...
└── resources/
    ├── resource-name-1.json
    └── ...
```

### System Prompt Injection

MCP tools are injected into the system prompt via the `<mcp_file_system>` XML block:

```xml
<mcp_file_system>
  <mcp_file_system_servers>
    <mcp_file_system_server
      name="server-name"
      folderPath="/path/to/descriptors"
      serverUseInstructions="...">
      server-name
    </mcp_file_system_server>
  </mcp_file_system_servers>
</mcp_file_system>
```

The `serverUseInstructions` field contains the server's usage prompt — this is where MCP servers inject their guidance into the LLM context.

## How CallMcpTool Works

```
LLM emits: CallMcpTool { server, toolName, arguments }
  │
  ├─ cursor-agent-exec receives the call
  │    │
  │    ├─ Resolves the MCP server by identifier
  │    │
  │    ├─ Validates arguments against the tool's JSON schema
  │    │
  │    ├─ Routes the call to the MCP server process:
  │    │   ├─ stdio: writes JSON-RPC message to stdin, reads from stdout
  │    │   └─ HTTP: sends POST request to server endpoint
  │    │
  │    ├─ Receives result from MCP server
  │    │
  │    └─ Returns result to LLM
  │
  └─ Error handling:
       ├─ Server not running → error message
       ├─ Auth required → auth status message
       └─ Tool not found → error message
```

## How FetchMcpResource Works

```
LLM emits: FetchMcpResource { server, uri, downloadPath? }
  │
  ├─ cursor-agent-exec receives the call
  │    │
  │    ├─ Resolves the MCP server
  │    │
  │    ├─ Sends resource fetch request
  │    │
  │    ├─ If downloadPath provided:
  │    │   └─ Saves to disk, does NOT return content to LLM
  │    │
  │    ├─ If downloadPath NOT provided:
  │    │   └─ Returns content to LLM
  │    │
  │    └─ Resources are read-only
```

## Authentication System

MCP servers can require authentication. The flow:

```
1. Agent discovers server needs auth (via STATUS.md or tool error)
2. Auth status message injected:
   "The MCP server needs authentication. Authenticate it by calling
    the `{authToolName}` tool for server "{serverIdentifier}"
    through your MCP tool-calling interface using an empty arguments object."
3. LLM calls: CallMcpTool { server, toolName: "mcp_auth", arguments: {} }
4. MCP server handles auth (OAuth flow, API key prompt, etc.)
5. On success, tools become available
```

### Auth Retry Configuration (from server config)

| Setting | Value | Purpose |
|---------|-------|---------|
| `fastRetryBaseDelayMs` | 5,000 | Initial retry delay |
| `fastRetryMaxDelayMs` | 60,000 | Max retry delay |
| `fastRetryMaxAttempts` | 5 | Max fast retries |
| `periodicRetryBaseDelayMs` | 300,000 (5 min) | Periodic health check |
| `periodicRetryMaxDelayMs` | 1,800,000 (30 min) | Max periodic delay |
| `focusRetryCooldownMs` | 300,000 (5 min) | Retry on window focus |
| `healthProbeTimeoutMs` | 10,000 | Health check timeout |
| `degradedProbeDelayMs` | 30,000 | Degraded state check |
| `maxDegradedProbeFailures` | 3 | Max failures before degraded |
| `keepaliveProbeDelayMs` | 300,000 (5 min) | Keepalive interval |
| `stabilityThresholdMs` | 30,000 | Time before stable |

## MCP Limits

From server config:

| Limit | Value | Source |
|-------|-------|--------|
| `maxMcpTools` | 100 | chatConfig |
| `warnMcpTools` | 80 | chatConfig (warning threshold) |

When MCP tools exceed 80, the system warns. At 100, additional tools are blocked.

## Built-in MCP Server: Browser Automation

```
cursor-browser-automation extension
  ├─ Role: MCP server for browser automation
  ├─ Activation: onStartupFinished
  ├─ Kind: ui
  ├─ Backend: Playwright
  └─ Registered as MCP server within the cursor-mcp framework
```

This is Cursor's built-in browser automation, exposed as an MCP tool that the LLM can invoke for:
- Page navigation
- Element interaction
- Screenshot capture
- Form filling

## MCP in the Agent Protocol

The `PrewarmRequest` carries MCP configuration to subagents:

```protobuf
PrewarmRequest {
  mcp_tools: McpTools         ← which MCP tools are available
  mcp_file_system_options: McpFileSystemOptions  ← filesystem config
}
```

This means:
- Subagents can have DIFFERENT MCP tool access than their parent
- MCP tools can be selectively passed or withheld per subagent
- The `mcp_file_system_options` controls how the MCP filesystem layer works

## Deep Link Installation

MCP servers can be installed via deep links:
```
Command: "mcp.deeplinkInstall" (in agentLayoutPolicy.allowedActionIds)
```

The `cursor-deeplink` extension handles URI-based MCP server installation, with the blocklist validation (prompt #05) applied to prevent malicious deep links.

## Security Observations

| Finding | Severity | Confidence |
|---------|----------|------------|
| MCP `serverUseInstructions` is injected directly into system prompt — prompt injection surface | `high` | `confirmed` |
| 100 MCP tools limit prevents unbounded tool explosion but is still large | `medium` | `confirmed` |
| MCP server processes run with user's permissions, no sandboxing | `medium` | `confirmed` |
| Deep link MCP installation + weak blocklist = potential for malicious server installation | `high` | `confirmed` |
| `custom_system_prompt` in PrewarmRequest could override MCP safety instructions | `medium` | `likely` |
| Auth retry with exponential backoff prevents auth brute-force but 5 fast retries is generous | `low` | `confirmed` |

---

*Evidence: cursor-mcp extension manifest, mcp_auth_status_copy_config, agentLayoutPolicy (mcp.deeplinkInstall), chatConfig (maxMcpTools, warnMcpTools), PrewarmRequest fields (mcp_tools, mcp_file_system_options), deep link blocklist (prompt #05)*
