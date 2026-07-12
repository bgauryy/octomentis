# Cursor API Prompt Flow — Full Investigation

**Date:** 2026-04-14
**Target:** Cursor v3.0.16 workbench.desktop.main.js (54 MB)
**Method:** Binary search of minified bundles via Octocode MCP + ripgrep

---

## Executive Summary

Cursor uses **bufbuild/connect** (gRPC-web) to communicate with `api2.cursor.sh`. The client constructs protobuf messages using generated stubs and streams them over HTTP/2.

**Key finding:** Prompts are NOT sent as simple text. They are structured protobuf messages containing:
- User message text + rich text (Lexical editor JSON)
- Context attachments (files, selections, images, MCP data)
- Conversation state (checkpoint IDs, blob entries)
- Model configuration (model name, max mode flag)
- Custom system prompts (via `PrewarmRequest.custom_system_prompt`)
- Subagent type and credentials
- Lineage headers (`x-parent-request-id`, `x-root-parent-request-id`)

---

## Transport Layer

**Protocol:** bufbuild/connect (gRPC-web over HTTP/2)
**Endpoints:** `api2.cursor.sh` (primary), `cursorapi.com` (backup)
**Auth:** Bearer token in headers
**Code location:** `out-build/external/bufbuild/connect/code.js` in workbench bundle

Connect status codes found:
```
Canceled=1, Unknown=2, InvalidArgument=3, DeadlineExceeded=4,
NotFound=5, AlreadyExists=6, PermissionDenied=7, ResourceExhausted=8,
FailedPrecondition=9, Aborted=10, OutOfRange=11, Unimplemented=12,
Internal=13, Unavailable=14, DataLoss=15, Unauthenticated=16
```

---

## All Streaming AI Endpoints (34 total)

These are the server-streaming gRPC methods that send prompts and receive AI responses:

### Chat / Conversation
| Endpoint | Purpose |
|----------|---------|
| `StreamConversationRequest` | Main conversation streaming (chat) |
| `StreamUnifiedChatRequest` | Unified chat interface |
| `StreamReplayChatRequest` | Chat replay |
| `StreamChatContextRequest` | Context-aware chat |
| `StreamChatDeepContextRequest` | Deep context chat |
| `StreamChatToolformerContinueRequest` | Tool-former continuation |

### Composer / Agent
| Endpoint | Purpose |
|----------|---------|
| `StreamComposerContextRequest` | Composer context streaming |
| `StreamEditRequest` | Inline edit streaming |
| `StreamFastEditRequest` | Fast edit streaming |
| `StreamGenerateRequest` | Code generation |
| `StreamCmdKRequest` | Cmd+K command palette AI |
| `StreamTerminalCmdKRequest` | Terminal Cmd+K |
| `StreamHypermodeRequest` | Hypermode streaming |
| `StreamPriomptPromptRequest` | Priompt prompt streaming |
| `StreamPseudocodeGeneratorRequest` | Pseudocode generation |
| `StreamPseudocodeMapperRequest` | Pseudocode mapping |
| `StreamNewRuleRequest` | New rule generation |

### Autocomplete / Prediction
| Endpoint | Purpose |
|----------|---------|
| `StreamInlineLongCompletionRequest` | Long inline completion |
| `StreamCppRequest` | Cursor++ prediction |
| `StreamHoldCppRequest` | Hold Cursor++ prediction |
| `StreamCursorMotionRequest` | Cursor motion prediction |
| `StreamNextCursorPredictionRequest` | Next cursor prediction |
| `StreamTerminalAutocompleteRequest` | Terminal autocomplete |

### Background Agent / Bug Bot
| Endpoint | Purpose |
|----------|---------|
| `StreamBackgroundComposerArtifactRequest` | Background composer artifacts |
| `StreamBugBotRequest` | Bug bot analysis |
| `StreamBugBotLinterRequest` | Bug bot linting |
| `StreamBugFindingRequest` | Bug finding |
| `StreamAiLintBugRequest` | AI lint bug detection |
| `StreamAiPreviewsRequest` | AI previews |
| `StreamUiBestOfNJudgeStartRequest` | Best-of-N judging |

### Help / Tutorial
| Endpoint | Purpose |
|----------|---------|
| `StreamAiCursorHelpRequest` | AI help |
| `StreamCursorTutorRequest` | Cursor tutor |
| `StreamLintRequest` | Lint streaming |
| `StreamInterfaceAgentStatusRequest` | Interface agent status |

---

## Non-Streaming AI Request Types (selected)

| Request | Purpose |
|---------|---------|
| `GetComposerChatRequest` | Get composer chat |
| `GetChatRequest` | Get chat |
| `GetCompletionRequest` | Get tab completion |
| `GetTerminalCompletionRequest` | Terminal completion |
| `GetChatSuggestionsRequest` | Chat suggestions |
| `GetChatTitleRequest` | Chat title generation |
| `GetSimplePromptRequest` | Simple prompt |
| `GetPassthroughPromptRequest` | Passthrough prompt |
| `GetEvaluationPromptRequest` | Evaluation prompt |
| `GetComposerAutocompleteRequest` | Composer autocomplete |
| `GetAtSymbolSuggestionsRequest` | @-symbol suggestions |
| `ComposerEnhancerRequest` | Composer enhancer |
| `ComposerCapabilityRequest` | Composer capability check |
| `IntentPredictionRequest` | Intent prediction |
| `BuilderCompletionRequest` | Builder completion |
| `InferenceStreamRequest` | Raw inference streaming |
| `SchedulerStreamRequest` | Scheduler streaming |
| `ReviewChatRequest` | Review chat |
| `EvaluatePromptHookRequest` | Prompt hook evaluation |
| `PotentiallyGenerateMemoryRequest` | Memory generation |
| `WarmChatCacheRequest` | Cache warming |
| `KeepComposerCacheWarmRequest` | Keep cache warm |
| `AgentFollowupCategorizationRequest` | Agent followup categorization |
| `GenerateTldrRequest` | TLDR generation |
| `IngestConversationRequest` | Conversation ingestion |

---

## Agent (agent.v1) Protocol — Bidirectional Streaming

The agent protocol uses bidirectional streaming with multiplexed message types:

### AgentClientMessage (client → server)
| Field | Type | Purpose |
|-------|------|---------|
| `run_request` | `AgentRunRequest` | Start agent run |
| `exec_client_message` | `ExecClientMessage` | Tool execution messages |
| `exec_client_control_message` | `ExecClientControlMessage` | Control messages |
| `kv_client_message` | KV message | Key-value store |
| `conversation_action` | `ConversationAction` | Conversation control |
| `interaction_response` | `InteractionResponse` | Respond to queries |
| `client_heartbeat` | `ClientHeartbeat` | Keep-alive |
| `prewarm_request` | `PrewarmRequest` | **Pre-warm with system prompt** |

### AgentServerMessage (server → client)
| Field | Type | Purpose |
|-------|------|---------|
| `interaction_update` | `InteractionUpdate` | AI response streaming |
| `exec_server_message` | `ExecServerMessage` | Tool execution responses |
| `exec_server_control_message` | `ExecServerControlMessage` | Server control |
| `conversation_checkpoint_update` | `ConversationState` | Checkpoint |
| `kv_server_message` | KV message | Key-value responses |
| `interaction_query` | `InteractionQuery` | Server queries client |

### PrewarmRequest Fields (custom system prompt injection)
| Field | Name | Type | Purpose |
|-------|------|------|---------|
| 1 | `model_details` | `ModelDetails` | Model configuration |
| 9 | `requested_model` | `ModelSelector` | Model selection |
| 2 | `conversation_id` | string | Conversation ID |
| 3 | `conversation_state` | `ConversationState` | Full state |
| 4 | `mcp_tools` | `McpTools` | MCP tool definitions |
| 5 | `mcp_file_system_options` | `McpFileSystemOptions` | MCP filesystem |
| 6 | `best_of_n_group_id` | string | Best-of-N group |
| 7 | `try_use_best_of_n_promotion` | bool | Best-of-N promotion |
| **8** | **`custom_system_prompt`** | **string** | **Custom system prompt** |
| 10 | `suggest_next_prompt` | bool | Suggest next |
| 11 | `subagent_type_name` | string | Subagent type |
| 12 | `exclude_workspace_context` | bool | Exclude workspace |
| 13 | `harness` | string | Test harness |
| 14 | `selected_subagent_models` | `ModelSelector[]` | Subagent models |
| 15 | `selected_subagent_model_details` | `ModelDetails[]` | Subagent details |

---

## Context Stripping (what gets stripped from transcripts)

From `agent-transcript/src/context-stripping.ts`:

```
"user_info", "project_layout", "rules",
"always_applied_workspace_rules", "agent_requestable_workspace_rules",
"user_rules", "agent_skills", "available_skills",
"cloud_instructions", "cloud_task_instructions",
"open_and_recently_viewed_files", "system_reminder", "system-reminder",
"mcp_instructions", "mcp_file_system", ...
```

These tags are **stripped from conversation transcripts** before sharing/storing, meaning they are present in the live prompt but removed for privacy in stored transcripts.

---

## Prompt Construction Flow

```
User types message in Composer
  → Rich text (Lexical JSON) + context mentions (@file, @symbol)
  → composerChatService.submitChatMaybeAbortCurrent()
    → Build context: files, selections, images, MCP tools
    → Build lineage headers (x-parent-request-id, x-root-parent-request-id)
    → Construct protobuf request (StreamConversationRequest or agent.v1.AgentClientMessage)
    → bufbuild/connect transport → HTTP/2 to api2.cursor.sh
    → Server streams back InteractionUpdate messages
      → TextDelta, ThinkingDelta, ToolCallDelta, StepCompleted
    → Client renders streaming response in UI
```

---

## API Scale Summary

| Category | Count |
|----------|-------|
| `agent.v1` protobuf types | 688 unique |
| `aiserver.v1` request types | 918 unique |
| Streaming AI endpoints | 34 |
| Non-streaming AI endpoints | 26+ |
| Background composer endpoints | 30+ |
| Total gRPC surface | **1,606+ message types** |

---

## Tool Calls (agent.v1)

All tools the agent can invoke (from protobuf types):

| Tool | Args/Result Types |
|------|------------------|
| `Shell` | ShellArgs, ShellResult, ShellToolCall |
| `Edit` | EditArgs, EditResult, EditToolCall |
| `Write` | WriteArgs, WriteResult |
| `Delete` | DeleteArgs, DeleteResult, DeleteToolCall |
| `Read` | ReadArgs, ReadResult, ReadToolCall |
| `ListDir` | ListDirArgs, ListDirResult, ListDirToolCall |
| `Grep` | GrepArgs, GrepResult, GrepToolCall |
| `Glob` | GlobToolArgs, GlobToolResult, GlobToolCall |
| `Fetch` | FetchArgs, FetchResult, FetchToolCall |
| `WebFetch` | WebFetchArgs, WebFetchResult, WebFetchToolCall |
| `WebSearch` | WebSearchArgs, WebSearchResult, WebSearchToolCall |
| `Task` (subagent) | TaskArgs, TaskResult, TaskToolCall |
| `AskQuestion` | AskQuestionArgs, AskQuestionResult, AskQuestionToolCall |
| `SwitchMode` | SwitchModeArgs, SwitchModeResult, SwitchModeToolCall |
| `CreatePlan` | CreatePlanArgs, CreatePlanResult, CreatePlanToolCall |
| `UpdateTodos` | UpdateTodosArgs, UpdateTodosResult, UpdateTodosToolCall |
| `Diagnostics` | DiagnosticsArgs, DiagnosticsResult |
| `AiAttribution` | AiAttributionArgs, AiAttributionResult |
| `ApplyAgentDiff` | ApplyAgentDiffArgs, ApplyAgentDiffResult |
| `BlameByFilePath` | BlameByFilePathArgs, BlameByFilePathResult |
| `ComputerUse` | ComputerUseArgs, ComputerUseResult |
| `GenerateImage` | GenerateImageArgs, GenerateImageResult |
| `GetMcpTools` | GetMcpToolsArgs |
| `WriteShellStdin` | WriteShellStdinArgs, WriteShellStdinResult |
| `StartGrindPlanning` | StartGrindPlanningArgs |
| `StartGrindExecution` | StartGrindExecutionArgs |
| `Canvas` | CanvasRegisterArgs, CanvasDestroyArgs, CanvasGetUrlArgs |
| `Await` | AwaitArgs, AwaitResult |
| `Subagent` | SubagentArgs, SubagentResult |

### Subagent Types
- `SubagentTypeBash`
- `SubagentTypeBrowserUse`
- `SubagentTypeComputerUse`
- `SubagentTypeCursorGuide`
- `SubagentTypeCustom`
- `SubagentTypeDebug`
- `SubagentTypeExplore`
- `SubagentTypeMediaReview`
- `SubagentTypeShell`
- `SubagentTypeVmSetupHelper`

---

## Security Observations

1. **Custom system prompt field** (`PrewarmRequest.custom_system_prompt`) allows client-specified system prompts — potential prompt injection vector if not server-validated
2. **Lineage tracking headers** sent on every request enable server-side conversation tree reconstruction
3. **Context stripping** is client-side — the full prompt with all context is sent to the server, only stripped in transcripts
4. **918 request types** = massive API surface for any authenticated user
5. **No rate limiting evidence** in client code — server-side only
6. **`InferenceStreamRequest`** and **`GetPassthroughPromptRequest`** suggest raw LLM access endpoints
