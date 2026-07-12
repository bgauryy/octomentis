# Antigravity Prompt System

## Template Engine

Prompts are Go templates (`.tmpl`) stored at:
```
google3/third_party/jetski/prompt/template_provider/templates/
```

## System Prompt Templates

| Template Path | Purpose |
|--------------|---------|
| `system_prompts/identity.tmpl` | Core agent identity/persona |
| `system_prompts/function_call.tmpl` | Tool calling instructions and schemas |
| `system_prompts/planning_mode.tmpl` | Planning mode (think-before-act) |
| `system_prompts/planning_mode_artifacts.tmpl` | Planning with artifact creation |
| `system_prompts/communication_style.tmpl` | Response formatting and tone |
| `system_prompts/plugins.tmpl` | Plugin integration prompts |
| `system_prompts/test_funcmap.tmpl` | Test function map |

## Step String Templates

| Template Path | Purpose |
|--------------|---------|
| `step_strings/helpers/` | Step output formatting helpers |
| `step_strings/helpers/default_status_output_string.tmpl` | Default step status output |

## Helper Templates

| Template Path | Purpose |
|--------------|---------|
| `helpers/errors.tmpl` | Error message formatting |

## Prompt Fragments (extracted from binary)

### Agent Instructions
```
"4. After receiving approval, begin execution. Create and update the task artifact as you work."
```

```
"Review them carefully and always take them into account when you generate responses and code:"
```

```
"You should **NEVER** give up fixing the issue if the regression is related to your changes."
```

```
"Make sure you test your solution after major modifications and before using the finish tool."
```

```
"However, you do not have internet access so please do not try to install any new libraries."
```

### Tool Usage Instructions
```
"Use ripgrep to find exact pattern matches within files or directories."
```

```
"Use the manage_task tool to interact with them (e.g. to kill them or check their status)."
```

```
"send_message should not be used to provide input to tasks; 
use the manage_task tool with action 'send_input' instead"
```

```
"Wait for a specified duration before continuing execution. The maximum duration is 60 seconds."
```

### Workflow Integration
```
"<WORKFLOW>The user mentioned the (%s) workflow. Here are its contents:"
```

### UI/Design Guidance
```
"Draw inspiration from modern, beautiful, and dynamic web designs"
```

### Context Management
```
"The following were user requests from the truncated conversation in chronological order:"
```

```
"The article at %s contains the following chunks with associated positions and summaries:"
```

### Error Handling
```
"Could not apply since file was edited while the changes were being generated."
```

```
"We did our best to apply changes despite some inaccuracies. Double check if the edit applied is what you intended."
```

```
"The model API is currently overloaded and may experience intermittent errors."
```

```
"model output must contain either output text or tool calls, these cannot both be empty"
```

### Terminal Integration
```
"Help me explain or answer this comment or question about my terminal output, called @terminal:"
```

### Knowledge Base
```
"The article at %s contains the following chunks with associated positions and summaries:"
```

### Git Integration  
```
"main branch has uncommitted changes; please commit or stash your changes before checking out the worktree"
```

### Naming Conflicts
```
"The following names are already taken, you MUST pick a different name: %s"
```

## Additional System Prompt Templates (Deep Extraction)

| Template Path | Purpose |
|--------------|---------|
| `system_prompts/artifacts.tmpl` | Artifact creation and management rules |
| `system_prompts/ephemeral_message.tmpl` | Ephemeral/temporary message formatting |
| `system_prompts/persistent_context.tmpl` | Persistent context injection |
| `system_prompts/skills.tmpl` | Agent skills integration |
| `system_prompts/guidelines.tmpl` | Agent behavioral guidelines |

## Step String Templates (Deep Extraction)

| Template Path | Purpose |
|--------------|---------|
| `step_strings/run_command.tmpl` | Terminal command execution formatting |
| `step_strings/send_command_input.tmpl` | Command input formatting |
| `step_strings/helpers/default_status_output_string.tmpl` | Default step status output |

## Additional Prompt Fragments (Deep Extraction)

### Agent Behavioral Rules
```
"After receiving approval, begin execution. Create and update the task artifact as you work."
```

```
"The user has automatically approved the artifact through their review policy. Proceed to execution."
```

```
"As a reminder, the following tool calls did not succeed since the last planner response:"
```

```
"Do not take action based on this information. You should only use it to inform your plan."
```

### Browser Agent Instructions
```
"The Agent is not allowed to interact with this page."
```

```
"IMPORTANT: You MUST view the guides at %s before attempting any tasks on these webpages"
```

```
"This is the click feedback screenshot. This screenshot includes %s at the clicked location."
```

```
"Started running the browser subagent from previous subagent ID=%s with the new task %s"
```

```
"List all open pages in Jetski Browser and their metadata (page_id, url, title, viewport size, etc.)."
```

### Code Quality Rules
```
"Never submit unverified code without passing tests. Use the full power of your shell environment."
```

```
"If there is a regression, be rigorous and fix it. Also update existing tests if necessary."
```

```
"You should run in non-interactive mode so that the user doesn't need to input anything"
```

### Artifact Rules
```
"you may not create the file diffs artifact, the system will update it automatically"
```

```
"Please fix these issues in your next edit to ensure the artifact is properly formatted."
```

```
"cannot create new artifact, KI %s already has %d artifacts. Consolidate artifacts first."
```

### Knowledge Base Integration
```
"Use the knowledge retrieval tools to access these KIs if they are relevant to your current task."
```

```
"The following knowledge items reference the listed resources you accessed in the last turn:"
```

```
"This information may or may not be relevant to the coding task, it is up for you to decide."
```

### Subagent System
```
"Subagent %q defined successfully. It can now be invoked via invoke_subagent."
```

```
"send_message should not be used to provide input to tasks; use the manage_task tool with action 'send_input' instead"
```

### Web/Design Guidance
```
"Semantic HTML: Use appropriate HTML5 semantic elements"
```

```
"Meta Descriptions: Add compelling meta descriptions that accurately summarize page content"
```

```
"Unique IDs: Ensure all interactive elements have unique, descriptive IDs for browser testing"
```

```
"Core: Use HTML for structure and Javascript for logic."
```

### Image Generation
```
"Generating image using prompt: %s and images at paths: %s"
```

```
"Your image generation quota has been exceeded. Please try again later."
```

### Git Commit
```
"Generate a commit message that summarizes the changes in the following files:"
```

### LOAS Auth (Google Internal)
```
"Use LOAS auth instead of OAuth browser flow. Only for use in Standalone + internal mode."
```

## Prompt Template Engine Details

### Dynamic Loading
Prompts can be loaded from three sources:
1. **Embedded templates** — compiled into the Go binary at build time
2. **Unleash overrides** — remotely loaded via feature flag system (`loadTemplateFromUnleash`)
3. **Workspace customization** — user `.agent/rules/**/*.md` files

### Cumulative Prompt Handler
The system uses a sophisticated cumulative prompt construction:
```
CumulativePromptHandler
├── ConstructCumulativePrompt        — Build full prompt from trajectory
├── FetchCachedContextAndRefreshDecision — Cache management
├── SetPersistentCachedContext       — Long-term context caching
├── getNewPersistentChatMessagePrompts — New message extraction
└── setLastCacheControlToEphemeral   — Cache control management
```

### Prompt Functions (from Go binary)
```
BuildCommandIntentInfo          — Command intent parsing
BuildSelectionWithCursor        — Selection context building
BuildTrajectoryFromContext      — Trajectory construction
ComputeTopKDiagnostics          — Top-K diagnostic selection
ConstructChatMessagesForChatCompletion — Chat completion formatting
DefaultCascadeConfigForCumulativePrompt — Default config
GetChatCompletionTokensSoftLimit — Token limit management
MaybeTruncatePrompt             — Prompt truncation
ShrinkPromptComponentsForTelemetry — Telemetry-safe shrinking
ShrinkTrajectoryToMinimalSteps  — Trajectory compression
```

### Autonomous Eval Mode
The template system includes an `IsAutonomousEvalMode` check, suggesting an evaluation/benchmarking mode where the agent runs without human interaction.

## Prompt Architecture

### Protobuf Types
- `HeuristicPrompt` — Dynamic prompts based on context heuristics
- `PromptFormat` — Template formatting configuration
- `PromptLength` — Prompt size tracking
- `PromptTokens` — Token counting
- `PromptSection` — Structured prompt sections
- `McpPromptSpec` — MCP-provided prompts

### Context Pipeline
```
User Input
    ↓
Scope Items (PathScopeItem, ContextScopeItem)
    ↓
Embedding Generation (GetEmbeddings)
    ↓
Knowledge Base Search (KnowledgeBaseSearch)
    ↓
Context Refresh (RecordContextRefresh)
    ↓
Cumulative Prompt Construction
    ↓
Cache Decision (CacheRefreshDecision)
    ↓
Model API Call
```

### Trajectory System
The conversation history is managed as a "trajectory":
- `TrajectoryScope` — Scope of the conversation
- `CortexTrajectory` — Full conversation record
- `CortexTrajectoryStep` — Individual steps
- `TrajectorySummaries` — Conversation summaries
- `ImplicitTrajectory` — Background/implicit context
- Trajectory has max length: "Trajectory has exceeded max length, clearing %d steps"
