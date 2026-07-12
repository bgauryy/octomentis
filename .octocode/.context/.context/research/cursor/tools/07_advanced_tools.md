# Advanced Tools — Canvas / ComputerUse / GenerateImage / Grind

**Confidence:** `likely` — protobuf types confirm existence, limited prompt evidence for exact behavior

---

## Canvas System

### Architecture

The Canvas system allows the agent to create React-based UI components displayed inline in the chat.

```
cursor-agent-exec extension
  ├─ Canvas runtime: ESM bundle for React UI
  ├─ SDK package: "cursor" (private, v0.0.0)
  │   ├─ canvas-tokens.d.ts  ← design tokens
  │   ├─ chart-primitives.d.ts ← chart components
  │   ├─ ui-primitives.d.ts  ← UI component library
  │   └─ theme.d.ts          ← theming
  └─ Exports: ./canvas with TypeScript declarations
```

### Protobuf Types

| Type | Purpose |
|------|---------|
| `CanvasRegisterArgs` | Register a new canvas component |
| `CanvasDestroyArgs` | Destroy a canvas component |
| `CanvasGetUrlArgs` | Get the URL for a canvas component |

### How It Works

```
LLM generates React code
  → CanvasRegisterArgs: register component with the runtime
  → Canvas runtime loads the React component
  → Component renders inside the chat UI
  → User can interact with it (charts, forms, visualizations)
  → CanvasGetUrlArgs: retrieve URL for sharing/embedding
  → CanvasDestroyArgs: cleanup when done
```

The Canvas primitives include:
- **UI primitives:** buttons, inputs, layouts, cards
- **Chart primitives:** bar, line, pie, scatter charts
- **Design tokens:** colors, spacing, typography
- **Theming:** light/dark mode support

## ComputerUse Tool

### Protobuf Types

```
ComputerUseArgs → ComputerUseResult
```

### How It Works

This is Anthropic's Computer Use capability integrated into Cursor:

```
LLM emits: ComputerUse { action, coordinates?, text?, ... }
  │
  ├─ cursor-agent-exec receives ComputerUseArgs
  │    │
  │    ├─ Actions likely include:
  │    │   ├─ screenshot — capture screen state
  │    │   ├─ click — mouse click at coordinates
  │    │   ├─ type — keyboard input
  │    │   ├─ scroll — scroll action
  │    │   └─ key — specific key press
  │    │
  │    └─ Returns ComputerUseResult (screenshot + action result)
```

The `SubagentTypeComputerUse` subagent type indicates this has its own specialized agent mode.

## GenerateImage Tool

### Protobuf Types

```
GenerateImageArgs → GenerateImageResult
```

### How It Works

```
LLM emits: GenerateImage { prompt, size?, style?, ... }
  │
  ├─ Routed to an image generation API (likely DALL-E or similar)
  │
  └─ Returns GenerateImageResult with generated image
```

Limited evidence — this maps to the `SubagentTypeMediaReview` which handles media files.

## Grind System (Plan Execution)

### Protobuf Types

| Type | Purpose |
|------|---------|
| `StartGrindPlanningArgs` | Begin a Grind planning session |
| `StartGrindExecutionArgs` | Execute a Grind plan |

### How It Works

"Grind" appears to be Cursor's name for their **plan-then-execute** workflow:

```
Phase 1: Planning
  LLM emits: StartGrindPlanning { requirements, context }
    → Plan agent explores codebase
    → Generates structured implementation plan
    → Returns plan with steps, files, dependencies

Phase 2: Execution
  LLM emits: StartGrindExecution { plan, ... }
    → Executes plan step by step
    → Each step may invoke other tools (Edit, Shell, etc.)
    → Tracks progress through the plan
```

This connects to the chain-of-thought entities found in the extension host:
```
opusChainGetPlan → opus2ChainPlan
  → opusChainGetFilePaths
    → opusChainGetFileInstruction
      → opus2ChainApplyPlan
        → opus2ChainReflect
```

The `plan-execution` model setting in server config confirms Grind has its own model routing (with migrations from Sonnet 4 → 4.5 → Opus 4.5).

## Background Composer / Agent

### Architecture

Background agents run in separate Electron windows:

```
Server config:
  backgroundComposerConfig:
    windowInWindowPreloadCount: 8    ← preload 8 agent windows
    maxWindowInWindows: 10           ← max 10 concurrent
    windowInWindowPingIntervalMs: 10000  ← health check every 10s
```

### Remote Resolution

Background agents use a special remote authority scheme:

```
Remote authority: background-composer+*
  → cursor-resolver resolves the authority
  → cursor-resolver-helper provides connection tokens
  → cursor-socket provides TCP/TLS transport
  → Workspace labeled as "cloud-agent"
```

This means background agents can run on **remote infrastructure** (cloud), not just locally. The `agentUrl: "https://agentn.us.api5.cursor.sh"` confirms dedicated agent infrastructure.

### Streaming Endpoints for Background Agents

| Endpoint | Purpose |
|----------|---------|
| `StreamBackgroundComposerArtifactRequest` | Background composer output |
| `StreamBugBotRequest` | Automated bug finding |
| `StreamBugBotLinterRequest` | Linting analysis |
| `StreamBugFindingRequest` | Bug discovery |
| `StreamAiLintBugRequest` | AI-powered lint |
| `StreamAiPreviewsRequest` | Preview generation |

## BugBot System

### Configuration (from server config)

```json
{
  "bugbotConfig": {
    "bugbotPlanEnabled": true,
    "bugbotPlanType": "BUGBOT_PLAN_TYPE_TEAM"
  }
}
```

### Models (from summarization config)

| Role | Model |
|------|-------|
| Main analysis | `claude-4-5-sonnet-20250929` |
| Agentic mode | `claude-4.5-haiku` |
| Iterations | 0 (non-agentic default), 1 (agentic) |
| Context lines | 10 |

BugBot is a background system that automatically analyzes code for bugs, likely triggered on PR creation or at scheduled intervals.

## Best-of-N Judging

### Protobuf Types

```
StreamUiBestOfNJudgeStartRequest
```

### How It Works

```
1. Multiple best-of-n-runner subagents execute in parallel
   (each in isolated git worktree)
2. Each produces a solution
3. StreamUiBestOfNJudgeStartRequest triggers evaluation
4. Server compares solutions and selects the best
5. Winner is promoted (if try_use_best_of_n_promotion=true)
```

## Security Observations

| Finding | Severity | Confidence |
|---------|----------|------------|
| ComputerUse gives the agent mouse/keyboard control — highest-risk tool | `high` | `confirmed` |
| Canvas executes agent-generated React code in the Electron renderer | `high` | `confirmed` |
| Background agents on remote infra (`agentn.us.api5.cursor.sh`) expand attack surface | `medium` | `confirmed` |
| 8 preloaded + 10 max background windows = significant resource consumption | `low` | `confirmed` |
| BugBot runs autonomously with team-level access | `medium` | `likely` |
| Grind plan execution is multi-step autonomous — failure in planning propagates to execution | `medium` | `likely` |

---

*Evidence: protobuf types (Canvas*, ComputerUse*, GenerateImage*, StartGrind*), cursor-agent-exec extension (canvas runtime, SDK types), server_config.json (backgroundComposerConfig, bugbotConfig, agentUrlConfig), chain-of-thought entities, summarization model config, streaming endpoints*
