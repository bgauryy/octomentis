# Antigravity Backend Services (gRPC/ConnectRPC)

## Service Architecture

All services use **ConnectRPC** (gRPC-compatible) with protobuf serialization.
Backend platform is called **"Exa"**.

## Language Server Service
**Proto:** `exa.language_server_pb.LanguageServerService`

### Agent Operations
- `SendCascadeRequest` — Start/continue agent conversation
- `CancelCascadeRequest` — Cancel running agent
- `SendAgentMessage` — Send message to agent
- `ForkConversation` — Fork a conversation
- `SmartFocusConversation` — Auto-focus conversation
- `GetAllCustomAgentConfigs` — Get custom agent definitions
- `StreamAgentStateUpdates` — Real-time agent state stream
- `StreamCascadePanelReactiveUpdates` — UI panel updates
- `StreamCascadeReactiveUpdates` — Cascade state updates
- `StreamCascadeSummariesReactiveUpdates` — Summary updates
- `StreamUserTrajectoryReactiveUpdates` — Trajectory updates
- `UpdateCascadeMemory` — Update conversation memory
- `UpdateConversationAnnotations` — Update annotations

### File & Workspace
- `WriteFile` — Write file
- `WatchDirectory` — Watch directory for changes
- `GetMatchingContextScopeItems` — Context matching
- `WellSupportedLanguages` — Language support info

### Git & VCS
- `CheckoutWorktree` — Git worktree checkout
- `GetRevertPreview` — Preview revert
- `UpdatePRForWorktree` — Update PR

### Models
- `GetModelResponse` — Get model response
- `GetModelStatuses` — Model availability
- `GetTranscription` — Audio transcription

### MCP
- `ListMcpResources` — List MCP resources
- `CompleteMcpOAuth` — Complete MCP OAuth flow

### Customization
- `UpdateCustomization` — Update customization settings
- `UpdateCustomizationPathsFile` — Update paths file
- `UpdateDevExperiments` — Dev experiments

### Terminal
- `StreamTerminalShellCommand` — Stream terminal command

### Other
- `ReconnectExtensionServer` — Reconnect
- `SmartOpenBrowser` — Smart browser open
- `ImportFromCursor` — Import Cursor settings
- `JetboxWriteState` — Jetbox state write

## Extension Server Service
**Proto:** `exa.extension_server_pb.ExtensionServerService`

### Command Execution
- `ExecuteCommand` — Execute shell command (streaming chunks)
- `TerminateCommand` — Kill running command
- `ReadTerminal` — Read terminal output
- `SendTerminalInput` — Send input to terminal
- `OpenTerminal` — Open new terminal
- `ShowTerminal` — Show terminal panel
- `CheckTerminalShellSupport` — Check shell compatibility
- `TerminalResearchResult` — Terminal research output

### File Editing
- `WriteCascadeEdit` — Write agent edit
- `OpenDiffZones` — Show diff zones
- `SaveDocument` — Save file
- `OpenFilePointer` — Open file at position
- `OpenVirtualFile` — Open virtual file

### Browser
- `LaunchBrowser` — Launch built-in browser
- `GetChromeDevtoolsMcpUrl` — Get CDP URL
- `GetBrowserOnboardingPort` — Browser setup

### LSP
- `GetDefinition` — Go to definition
- `FindAllReferences` — Find all references
- `GetLintErrors` — Get lint diagnostics

### Notebook
- `EditNotebook` — Edit notebook cell
- `ReadNotebook` — Read notebook
- `ExecuteNotebook` — Execute notebook

### Audio
- `StartAudioRecording` — Start recording
- `EndAudioRecording` — End recording
- `GetCurrentAudioRecording` — Get current recording
- `PlaySound` — Play audio feedback

### UI
- `InsertCodeAtCursor` — Insert code
- `OpenExternalUrl` — Open external URL
- `OpenSetting` — Open settings
- `ShowConversationPicker` — Show conversation picker
- `OpenConversationWorkspaceQuickPick` — Workspace picker
- `OpenPluginPage` / `OpenPluginConfigModal` / `OpenConfigurePluginsPage` — Plugin management
- `OpenAntigravityRulesFile` — Open rules file
- `FocusIDEWindow` — Focus window
- `HandleProposeCodeExtensionVerification` — Code verification
- `UpdateDetailedViewWithCascadeInput` — Update detailed view
- `UpdateCascadeTrajectorySummaries` — Update summaries

### State Sync
- `PushUnifiedStateSyncUpdate` — Push state update
- `SubscribeToUnifiedStateSyncTopic` — Subscribe to state

### Other
- `RunExtensionCode` — Run extension code
- `GetSecretValue` / `StoreSecretValue` — Secret management
- `RecordError` — Error recording
- `LogEvent` — Event logging
- `Heartbeat` — Health check
- `LanguageServerStarted` — LS ready signal
- `IsAgentManagerEnabled` — Agent manager check
- `RestartUserStatusUpdater` — Status updater
- `BroadcastConversationDeletion` — Delete conversation
- `HandleAsyncPostMessage` — Async messaging

## API Server Service
**Proto:** `exa.api_server_pb.ApiServerService`

### AI & Generation
- `GetWebSearchResults` / `GetWebSearchRedirect` — Web search
- `GetEmbeddings` — Generate embeddings
- `GetImageGeneration` — Generate images
- `GetTranscription` — Audio transcription
- `RunCodeAlignment` — Code alignment

### Configuration
- `GetCascadeModelConfigs` — Cascade model configurations
- `GetCommandModelConfigs` — Command model configurations
- `GetModelInfos` / `GetModelStatuses` — Model information
- `GetDefaultWorkflowTemplates` — Workflow templates
- `GetMcpServerTemplates` — MCP server templates
- `GetDeploymentConfig` — Deployment configuration
- `GetCascadeNuxes` — New user experiences
- `GetUnleashContextFields` — Feature flag context

### Analytics & Telemetry
- `RecordCortexTrajectory` / `RecordCortexTrajectoryStep` — Trajectory telemetry
- `RecordCortexStep` / `RecordCortexError` — Step telemetry
- `RecordCortexFeedback` / `RecordCortexCodingStepFeedback` — Feedback
- `RecordCortexGeneratorMetadata` / `RecordCortexExecutionMetadata` — Execution data
- `RecordCortexCodingPlan` / `RecordCortexCodingStep` — Coding telemetry
- `RecordCompletions` / `BatchRecordCompletions` — Completion telemetry
- `RecordChat` / `RecordChatFeedback` — Chat telemetry
- `RecordEvent` / `RecordAsyncTelemetry` — Generic events
- `RecordContextToPrompt` / `RecordContextRefresh` — Context telemetry
- `RecordFullTrajectoryAnalytics` — Full trajectory analysis

### User & Teams
- `WhoAmI` — Current user
- `ValidateEmail` / `ValidateRegistrationCode` — Validation
- `Subscribe` / `SubscribeToBlog` — Subscriptions
- `ProvideFeedback` — User feedback
- `ContactForm` — Contact support
- `JoinWaitlist` — Waitlist

### Content
- `GetWebDocsOptions` — Documentation
- `GetCompletionExamples` — Completion examples
- `GenerateSyntheticRule` — Generate rules
- `ApplyTrajectoryHeuristics` — Apply heuristics

### Enterprise
- `GetAllowlist` / `InsertAllowlist` / `DeleteAllowlist` — Allowlists
- `GetUserAllowlist` — User allowlists
- `CheckHybridDeploymentStatus` — Hybrid deployment
- `CreateHybridDeploymentInternal` / `RegisterHybridDeployment` / `RemoveHybridDeploymentInternal` — Hybrid management
- `GetTeamOrganizationalControls` / `UpsertTeamOrganizationalControls` — Org controls
- `IsConversationSharingBlocked` — Sharing controls

### Sharing
- `FetchTrajectoryShareByUser` / `DeleteTrajectoryShare` — Share trajectories

## Plugin Service
**Proto:** `exa.cascade_plugins_pb.CascadePluginsService`

- `GetAvailableCascadePlugins` — List plugins
- `GetCascadePluginById` — Get plugin details
- `InstallCascadePlugin` — Install plugin

## Seat Management Service
**Proto:** `exa.seat_management_pb.SeatManagementService`

Full user/team management: registration, authentication, roles, billing, GitHub/Netlify integration, SSO, API keys, team configuration.

## Knowledge Base Service
**Proto:** `exa.opensearch_clients_pb.KnowledgeBaseService`

Integrations:
- GitHub (users, data)
- Slack (webhooks, payload ingestion)
- Jira (data ingestion, payload handling)
- Google Drive (data ingestion)
- Generic connectors

Operations: search, connect, disconnect, ingest, cancel jobs.

## Code Index Service
**Proto:** `exa.opensearch_clients_pb.CodeIndexService`

- `HybridSearch` — Hybrid code search
- `GraphSearch` — Graph-based code search
- `OpenSearchAddRepository` — Index repository
- `OpenSearchGetIndex` — Get index info

## Model Management Service
**Proto:** `exa.model_management_pb.ModelManagementService`

Local model support:
- `ListModels` / `DeleteModel` — Model CRUD
- `StartInferenceServer` / `StopInferenceServer` — Local inference
- `ListInferenceServers` — List servers
- `PollInferenceServerMemory` / `UpdateInferenceServerMemory` — Memory management
- `AddModelCount` — Usage tracking

## Additional Language Server Endpoints (Deep Extraction)

### Git & Worktree
- `GetWorktreeDiff` — Get worktree diff
- `RegisterGdmUser` — GDM user registration

### User & Settings
- `GetUserSettings` / `SetUserSettings` — User preferences
- `ResetOnboarding` — Reset onboarding state
- `GetUserMemories` — User memories (persistent context)

### Workflows & Agents
- `GetAllWorkflows` — List workflows
- `GetAgentScripts` — Get agent scripts
- `CopyBuiltinWorkflowToWorkspace` — Copy builtin workflow

### MCP Extended
- `GetMcpServerTemplates` — MCP server templates
- `DeleteFileOrDirectory` — File/directory deletion

### Background Research
- `ForceBackgroundResearchRefresh` — Force research refresh

### Debugging
- `SimulateSegFault` — Simulate crash (debug tool)

### Nux (New User Experience)
- `GetCascadeNuxes` — New user experience states

## Additional Extension Server Endpoints (Deep Extraction)

- `GetSecretValue` / `StoreSecretValue` — Credential/secret management
- `SmartFocusConversation` — Smart conversation focus
- `RunExtensionCode` — Execute arbitrary extension code (with auto-run decision)

## Additional API Server Endpoints (Deep Extraction)

- `ExchangeOidcCode` / `RefreshOidcToken` — OIDC authentication flow
- `RecordTrajectorySegmentAnalytics` — Segment-level analytics
- `FetchTrajectoryShareByUser` — Trajectory sharing

## Additional Seat Management Endpoints (Deep Extraction)

- `AddUserRole` — Role management
- `GetTeamInfo` / `GetMucsInfo` — Team information
- `UpdateProfileVisibility` — Privacy settings
- `DisconnectGithubAccount` — GitHub disconnection
- `GetNetlifyAccountStatus` — Netlify integration
- `ListTeamDomainsInternal` — Internal domain listing
- `BulkEditUserApprovalsInternal` — Bulk approval management
- `UpdateCascadeWebSearchEnabled` — Web search toggle per team

## Analytics Service
**Proto:** `exa.analytics_pb.AnalyticsService`

- `RecordCompletionsCheckpoint` — Completion checkpoint
- `RecordCortexTrajectoryStep` — Trajectory step recording

## Remoting Service
**Proto:** `exa.remoting.RemotingService`

- `DisconnectRemote` — Remote disconnection

## Google Cloud APIs

### Cloud Code Service
- `google.internal.cloud.code.v1internal.CloudCode/ListCloudAICompanionProjects`
- `google.internal.cloud.code.v1internal.CloudCode/TransformCode`
- `google.internal.cloud.code.v1internal.CloudCode/GenerateCode`
- `google.internal.cloud.code.v1internal.CloudCode/CompleteCode`
- `google.internal.cloud.code.v1internal.CloudCode/GenerateChat`

### Jetski Service
- `google.internal.cloud.code.v1internal.JetskiService/GetHealth`

### Prediction Service
- `google.internal.cloud.code.v1internal.PredictionService/FetchAvailableModels`

### Vertex AI
- `google.cloud.aiplatform.master.PredictionService/AsyncGenerateContent`
- `google.cloud.aiplatform.master.PredictionService/CompleteCode`
- `google.cloud.aiplatform.master.PredictionService/EmbedContent`
- `google.cloud.aiplatform.master.PredictionService/CountTokens`
- `google.cloud.aiplatform.master.PredictionService/GetResponse`

### BigQuery
- `google.cloud.bigquery.storage.v1.BigQueryWrite/FlushRows`

## Cloud Code Environments

Three API environments detected:
```
Production:  https://cloudcode-pa.googleapis.com
Daily:       https://daily-cloudcode-pa.googleapis.com
Autopush:    https://autopush-cloudcode-pa.sandbox.googleapis.com
```

Selection logic uses environment flags and internal/external build detection.
