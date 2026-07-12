# BOUNTY-8: Silent Telemetry Data Exfiltration

## Classification

| Field | Value |
|-------|-------|
| ID | BOUNTY-8 |
| Severity | **LOW-MEDIUM** |
| Confidence | confirmed |
| CWE | CWE-359 (Exposure of Private Information), CWE-223 (Omission of Security-relevant Information) |
| Category | Privacy Violation / Silent Data Collection |
| Target | Cursor.app v3.0.12 — main.js (Sentry integration + UploadIssueTrace) |

---

## Summary

Cursor silently uploads SQLite performance trace data to its servers via `UploadIssueTrace` when slow database operations trigger Sentry events with attachments. The upload happens automatically with no user notification and failures are silently swallowed (`.catch(() => {})`). Additionally, Sentry is enabled by default with a 100% logger sample rate, meaning all log-level events are captured.

---

## Evidence

### Silent upload handler (`main.js:467100`):
```javascript
// Triggered when Sentry captures a slow SQLite event with attachments:
if (i.attachments && i.attachments.length > 0) {
  const r = new TextDecoder().decode(i.attachments[0].data);
  const s = `slow_sqlite_${i.tags?.storage_name ?? "unknown"}`;
  fetch("https://api2.cursor.sh/aiserver.v1.AnalyticsService/UploadIssueTrace", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      token: s,              // Storage identifier
      payload: r,            // FULL attachment data — may contain paths, queries
      payloadHash: String(Mr(r))
    })
  }).catch(() => {})         // ← Failures silently swallowed
}
```

### Sentry default configuration (`main.js:99800`):
```javascript
globalThis._CURSOR_SENTRY = {
  buffer: [],
  enabled: true,                        // ON by default for ALL users
  allowCrashReportsWhenDisabled: false,
  loggerSampleRate: 1,                   // 100% of logger events captured
  tracesSampleRate: 0.01,               // 1% of performance traces
  trace2SampleRate: 0.01                 // 1% of v2 traces
}
```

### gRPC protocol for trace upload (`workbench.desktop.main.js:37857200`):
```javascript
// UploadIssueTraceRequest fields:
{ no: 1, name: "token", kind: "scalar", T: 9 },     // String identifier
{ no: 2, name: "payload", kind: "scalar", T: 9 },   // Full trace data
{ no: 3, name: "payload_hash", kind: "scalar", T: 9 } // Hash for dedup

// DownloadIssueTracesRequest — traces can also be retrieved:
{ no: 1, name: "token", kind: "scalar", T: 9 },
{ no: 2, name: "limit", kind: "scalar", T: 5 }       // Integer limit
```

---

## What Data Is Sent

SQLite performance traces can contain:
- **Workspace paths** — reveals project structure and directory names
- **Database query patterns** — reveals what operations are being performed
- **Storage names** — identifies which SQLite database triggered the issue
- **Timing data** — reveals performance characteristics of the user's machine

---

## Impact

- Users have no notification that telemetry data is being uploaded
- `.catch(() => {})` means network failures are invisible — no retry, no error, no log
- 100% logger sample rate means every log event is captured
- `DownloadIssueTracesRequest` exists — suggesting traces are stored server-side and retrievable
- Sentry is enabled by default — users must opt out (if mechanism exists)

---

## Mitigation

1. Make Sentry **opt-in** with clear disclosure of what data is collected
2. Remove `.catch(() => {})` — log failures so users can see what's happening
3. Show a notification the first time telemetry data is uploaded
4. Reduce `loggerSampleRate` from 1.0 (100%) to a reasonable production level
5. Sanitize SQLite trace payloads to remove file paths before upload
6. Add a clear telemetry settings page showing all data collection endpoints
