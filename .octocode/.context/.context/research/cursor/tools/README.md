# Cursor v3.0.16 — Tool Internals Deep Dive

**Date:** 2026-04-14
**Source:** Static analysis of Cursor.app bundles + live API reverse engineering
**Evidence base:** `research/cursor/.research/`, `research/cursor/content/`, `research/cursor/prompts/`

---

## Architecture Overview

Cursor's tool system operates across a **three-layer architecture**:

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: LLM (server-side)                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │ Priompt templating → system prompt assembly       │  │
│  │ Model routes tool_call JSON to client             │  │
│  │ Streams: TextDelta, ThinkingDelta, ToolCallDelta  │  │
│  └───────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Agent Protocol (bidirectional gRPC)           │
│  ┌───────────────────────────────────────────────────┐  │
│  │ agent.v1.AgentClientMessage ↔ AgentServerMessage  │  │
│  │ Transport: bufbuild/connect over HTTP/2            │  │
│  │ Endpoint: api2.cursor.sh (primary)                 │  │
│  │ Auth: Bearer JWT + x-cursor-checksum               │  │
│  │ Lineage: x-parent-request-id chain                 │  │
│  └───────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Client Execution (Electron + Extensions)      │
│  ┌───────────────────────────────────────────────────┐  │
│  │ cursor-agent-exec handles ExecServerMessage        │  │
│  │ Dispatches to VSCode APIs (filesystem, terminal)   │  │
│  │ Enforces permissions, workspace boundaries         │  │
│  │ Returns ExecClientMessage with results             │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## How a Tool Call Actually Works

```
1. Server streams ToolCallDelta with tool name + args JSON
2. cursor-agent receives via agent.v1 bidirectional stream
3. cursor-agent-exec dispatches based on tool type:
   - File ops → VSCode FileSystem API
   - Shell    → VSCode Terminal API + pty
   - Search   → bundled ripgrep / glob / semantic index
   - Task     → spawns child agent session (new gRPC stream)
   - MCP      → routes to registered MCP server
4. Result serialized as ExecClientMessage → sent back on stream
5. Server feeds result into next LLM turn
```

## Tool Inventory (from agent.v1 protobuf)

| Tool | Protobuf Types | Deep Dive |
|------|---------------|-----------|
| **Task** (subagent) | TaskArgs, TaskResult, SubagentArgs | [01_task_tool.md](01_task_tool.md) |
| **Shell** | ShellArgs, ShellResult, WriteShellStdinArgs | [02_shell_tool.md](02_shell_tool.md) |
| **Read/Write/Edit/Delete** | ReadArgs, WriteArgs, EditArgs, DeleteArgs | [03_file_tools.md](03_file_tools.md) |
| **Grep/Glob/SemanticSearch** | GrepArgs, GlobToolArgs | [04_search_tools.md](04_search_tools.md) |
| **SwitchMode/AskQuestion/TodoWrite** | SwitchModeArgs, AskQuestionArgs, UpdateTodosArgs | [05_interaction_tools.md](05_interaction_tools.md) |
| **MCP** | GetMcpTools, CallMcpTool | [06_mcp_tools.md](06_mcp_tools.md) |
| **Advanced** | Canvas, ComputerUse, GenerateImage, Grind | [07_advanced_tools.md](07_advanced_tools.md) |

## Key Numbers

| Metric | Value |
|--------|-------|
| Total protobuf types (agent.v1) | 688 |
| Total protobuf types (aiserver.v1) | 918 |
| Streaming AI endpoints | 34 |
| Non-streaming AI endpoints | 26+ |
| Registered tool types | 25+ |
| Subagent types | 10 |
| Usable models | 83 |
| Max MCP tools per session | 100 |
| Full context token limit | 30,000 |
| Max rule file length | 100,000 chars |
| ReadFile max size | 2 MB |
| EditFile max chars | 150,000 |

## Security Notes

See [08_security_findings.md](08_security_findings.md) for full analysis.

---

*Generated from Cursor v3.0.16 static analysis + API reverse engineering*
