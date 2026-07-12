# Cursor.app Security Findings

## F01 — Hardcoded Statsig SDK Key

**Severity:** medium | **Confidence:** confirmed

**Evidence:**
```
charOffset: 4223979 in workbench.desktop.main.js
Value: KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB
```

**Context:** Statsig client SDK key embedded in production code. While client-side SDK keys are designed to be semi-public, this reveals:
- Feature flagging infrastructure details
- Allows enumeration of feature gates and experiments
- Statsig endpoints: `api.statsigcdn.com`, `featureassets.org`, `prodregistryv2.org`

**Impact:** An attacker could enumerate all feature flags, A/B tests, and experimental features. Combined with Statsig's API, this could reveal unreleased features, internal rollout percentages, and user segmentation logic.

**Benign alternative:** Standard practice for client-side SDKs. Statsig keys are designed for client exposure. Low real-world risk unless Statsig gates control security-sensitive features.

---

## F02 — Hardcoded Sentry DSNs (3 instances)

**Severity:** medium | **Confidence:** confirmed

**Evidence:**
```
1. Cursor Metrics: https://80ec2259ebfad12d8aa2afe6eb4f6dd5@metrics.cursor.sh/4508016051945472
   charOffset: ~99800 (main.js), ~564100 (workbench)

2. Sentry US: https://0a7b82d23ca5f4635708bc8e9957e4bd@o4504648565915648.ingest.us.sentry.io/4509635758522369
   charOffset: ~99800 (main.js), ~564100 (workbench)

3. Sentry Browser Check: https://o447951.ingest.sentry.io/api/4509632503087104/envelope/
   Key: c1dfb07d783ad5325c245c1fd3725390
   charOffset: 36682000 (workbench)
```

**Context:** Three Sentry DSNs with public auth tokens. Reveals Sentry organization IDs (`o4504648565915648`, `o447951`), project IDs, and the `metrics.cursor.sh` custom Sentry relay.

**Impact:** An attacker could:
- Send fake error reports to pollute Cursor's error tracking
- Enumerate project structure from DSN format
- Potentially discover Sentry org details through API enumeration

**Benign alternative:** Sentry DSNs are intentionally client-side. Standard Electron/web practice.

---

## F03 — Silent SQLite Trace Upload

**Severity:** medium | **Confidence:** confirmed

**Evidence:**
```
charOffset: 467100 in main.js

Code:
fetch("https://api2.cursor.sh/aiserver.v1.AnalyticsService/UploadIssueTrace", {
  method: "POST",
  headers: {"Content-Type": "application/json"},
  body: JSON.stringify({
    token: `slow_sqlite_${storage_name}`,
    payload: r,          // TextDecoder-decoded Sentry attachment data
    payloadHash: String(Mr(r))
  })
}).catch(() => {})       // Failures silently swallowed
```

**Context:** When a slow SQLite operation triggers a Sentry event with attachments, the full attachment payload is decoded and silently POSTed to Cursor's AnalyticsService. The `.catch(() => {})` means the user gets no indication of success or failure.

**Impact:**
- SQLite performance traces may contain workspace paths, file names, or query patterns
- The upload happens automatically with no explicit user consent at the point of transmission
- Silent failure swallowing means network errors are invisible

**Benign alternative:** Performance monitoring for product improvement. The `slow_sqlite_` prefix suggests this targets SQLite performance issues specifically.

---

## F04 — Internal Notion Developer Link Leaked

**Severity:** low | **Confidence:** confirmed

**Evidence:**
```
charOffset: 30035609 in workbench.desktop.main.js
URL: https://www.notion.so/cursorai/Ryo-s-Journal-161da74ef045007ac1bf36660e08e4a4
```

**Context:** A Cursor developer's personal Notion journal URL is hardcoded in the MCP notification flow for the Notion integration. This appears to be a test/debug URL that was not cleaned up before release.

**Impact:**
- Reveals internal Notion workspace organization (`cursorai`)
- Exposes a specific developer's journal page UUID
- If the page has public access, could reveal internal development notes

**Benign alternative:** Likely a debug/test artifact. Low security impact but reveals internal development practices.

---

## F05 — In-App Advertisement System

**Severity:** info | **Confidence:** confirmed

**Evidence:**
```
charOffset: 38634800 in workbench.desktop.main.js

Service: aiserver.v1.InAppAdService
Methods: HasSeenAd, MarkAdAsSeen, ResetUserAdViews
Triggers: IN_APP_AD_TRIGGER_MOUNT, IN_APP_AD_TRIGGER_FIND_ISSUES, IN_APP_AD_TRIGGER_GIT_PUSH
Message types: AdContent, AdHeader, AdSection, AdButton
Display: ModalDisplayConfig with background gradients
```

**Context:** A server-controlled in-app advertisement system that can display modal ads triggered by workspace mount, issue finding, or git push events.

**Impact:** Server-side control over ad content means Cursor can push arbitrary modal content to users at key workflow moments. No user opt-out mechanism was found in the gRPC schema.

---

## F06 — Full Repository Upload Capability

**Severity:** info | **Confidence:** confirmed

**Evidence:**
```
gRPC types at charOffsets 2772800-2800000 in workbench.desktop.main.js:

- StartUploadRepoRequest (repository)
- StartUploadRepoResponse (status, seen_files[])
- UploadFileRequest (repository, file, commit_sha, queue_id)
- UploadFileResponse (status)
- UploadRepositoryRequest / UploadRepositoryResponse
- RegisterCodebaseRequest (codebase_uuid, path, kind)
- RegisterCodebaseSnapshotRequest (codebase_uuid, commit_hash, tree_hash, reason)

Snapshot reasons: MANUAL, AGENT_REQUEST_START, AGENT_REQUEST_END
```

**Context:** The codebase indexing system (`repo42.cursor.sh`) can upload entire repository contents file-by-file. Snapshots are automatically triggered at agent request start/end.

**Impact:** Your entire codebase is uploaded to Cursor's servers for indexing. The `seen_files` response suggests incremental uploads. This is the core of Cursor's AI feature but users should understand the scope.

---

## F07 — Internal Google-style Shortlinks in Production

**Severity:** info | **Confidence:** confirmed

**Evidence:**
```
main.js line 135: http://go/debugdata
main.js line 317: http://go/sourcemap/sourcemaps/a80ff7dfcaa45d7750f6e30be457261379c29b00/core/main.js.map
```

**Context:** Internal Google-style `go/` shortlinks left in production code. These suggest Anysphere uses an internal URL shortener. The sourcemap reference includes a specific commit hash (`a80ff7dfcaa45d7750f6e30be457261379c29b00`).

---

## F08 — Edit History with File Content Sent to Server

**Severity:** info | **Confidence:** confirmed

**Evidence:**
```
charOffset: 3654700 in workbench.desktop.main.js

Message: EditHistoryAppendChangesRequest
Fields: session_id, model_uuid, starting_model_value, starting_model_version,
        relative_path, uri, client_version, changes[], sessionEvents[],
        modelChangesMayBeOutOfOrder, privacyModeStatus, events[], timeOrigin
```

**Context:** The edit history system sends file content (`starting_model_value`), paths, and change events to the server. A `privacyModeStatus` field exists but defaults to `UNSPECIFIED`.

---

## F09 — Sentry Enabled by Default with 100% Logger Sample Rate

**Severity:** low | **Confidence:** confirmed

**Evidence:**
```
charOffset: ~99800 in main.js

globalThis._CURSOR_SENTRY = {
  buffer: [],
  enabled: true,                              // ON by default
  allowCrashReportsWhenDisabled: false,
  loggerSampleRate: 1,                         // 100% of logs
  tracesSampleRate: 0.01,                      // 1% of traces
  trace2SampleRate: 0.01                       // 1% of traces
}
```

**Context:** Sentry error reporting is enabled by default for all users with 100% logger sampling. While trace sampling is 1%, all log-level events are captured.

---

## F10 — Massive gRPC API Surface (955 Request Types)

**Severity:** info | **Confidence:** confirmed

**Evidence:** 70+ gRPC services including:

**Data-heavy services:**
- `AnalyticsService` — Telemetry upload
- `ClientLoggerService` — Client log upload
- `CodebaseSnapshotService` — Codebase snapshot upload
- `FileSyncService` — File synchronization
- `GitGraphService` — Git graph data
- `GitIndexService` — Git index data
- `MetricsService` / `OnlineMetricsService` — Metrics
- `PerformanceEventService` — Performance telemetry
- `ProfilingService` / `WebProfilingService` — Profiling data
- `RepositoryService` — Repository data
- `TraceService` — Tracing
- `UploadService` — Generic uploads

**AI/Agent services:**
- `AiService`, `AiProjectService`, `AiBranchService`
- `AutopilotService`, `AutomationsService`
- `BackgroundComposerService`
- `InferenceService`
- `ShadowWorkspaceService`

**Business services:**
- `InAppAdService` — In-app advertisements
- `EnterpriseAdminService` — Enterprise management
- `MarketplaceService` — Extension marketplace
- `TeamCreditsService` — Usage/billing
- `UsageSimulationService` — Usage simulation
- `BugbotService` — Automated bug finding

---

## Supplementary: Full API Infrastructure

```
Production endpoints:
- cursor.com              — Main website
- api2.cursor.sh          — Core API (requests, extension control, updates)
- api3.cursor.sh          — Cursor Tab (code completion)
- api4.cursor.sh          — Cursor Tab (regional)
- *.api5.cursor.sh        — Agent requests (regional: US West, EU Central, AP Southeast)
- repo42.cursor.sh        — Codebase indexing
- *.authentication.cursor.sh — Authentication
- authenticator.cursor.sh — Login UI
- marketplace.cursorapi.com — Extension marketplace
- cursor-cdn.com          — CDN
- downloads.cursor.com    — Client updates
- metrics.cursor.sh       — Custom Sentry relay

Staging/Dev:
- dev-staging.cursor.sh
- staging.cursor.sh
- staging-marketplace.cursor.sh

Third-party:
- api.statsigcdn.com      — Statsig feature flags
- featureassets.org        — Statsig config
- prodregistryv2.org      — Statsig registration
- statsigapi.net          — Statsig exceptions
- sentry.io               — Error reporting
- api.openai.com          — OpenAI API
- api.github.com          — GitHub Copilot integration
```
