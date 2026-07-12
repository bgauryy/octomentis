# Finding 02: Dual Telemetry Pipeline — Clearcut + VS Code

**Severity:** `medium` | **Confidence:** `confirmed` | **Category:** Privacy / Data Collection

---

## Summary

Antigravity runs **two independent telemetry pipelines** simultaneously:
1. VS Code's inherited telemetry system (machine ID, session data, usage events)
2. Google's **Clearcut** analytics system — binary protobuf POSTs to `play.googleapis.com/log`, OAuth-authenticated, batching up to 10,000 events, with persistent local buffer that survives app restarts

## Evidence

### Clearcut Analytics Service

**Source:** `main.js` — `out-build/vs/platform/telemetry/common/telemetryService.js`

```javascript
const pWt = "https://play.googleapis.com/log";   // Clearcut endpoint
const Mke = 5 * 60 * 1e3;     // 5-minute flush interval
const bwa = 1e4;               // Max 10,000 events per batch
const ywa = 2e4;               // Max 20,000 buffered events
const Rwa = 44;                // Log source ID
const Awa = 2747;              // Product ID
const gWt = "antigravityAnalytics.clearcutBuffer";    // Persistent storage key
const mWt = "antigravityAnalytics.lastUploadTime";    // Last upload timestamp
```

### fireEvent Implementation

Every Clearcut event includes these base fields:

```javascript
async fireEvent(t, r) {
    const n = Object.entries(r?.extra || {}).map(([u, d]) => mr(ev, {key: u, value: d}));
    
    // Always attached to every event:
    n.push(mr(ev, {key: "ideName",    value: oA.ideName}));
    n.push(mr(ev, {key: "ideVersion", value: oA.ideVersion}));
    n.push(mr(ev, {key: "os",         value: this.t()}));
    n.push(mr(ev, {key: "osVersion",  value: vws()}));
    n.push(mr(ev, {key: "osArch",     value: mwa()}));
    
    // Machine ID (MAC address SHA256) if available:
    const a = this.n.getItem(V2e);  // "telemetry.machineId"
    a && n.push(mr(ev, {key: "machineId", value: a}));
    
    // Duration if provided:
    r?.durationMs && n.push(mr(ev, {key: "durationMs", value: r.durationMs.toString()}));
    
    // Active experiments:
    const i = Object.entries(r?.experiments || {}).map(([u, d]) => mr(EIr, {key: u, enabled: d}));
    
    // Wrap in protobuf and queue
    const s = mr(bIr, {eventType: t, extra: n, experiments: i});
    const o = this.w(this.u({case: "analyticsEventMetadata", value: s}));
    this.y(o);  // Add to buffer
}
```

### Data Fields Per Event

| Field | Value | Source |
|-------|-------|--------|
| `ideName` | "Antigravity" | Product constant |
| `ideVersion` | "1.22.2" | App version |
| `os` | "darwin" / "linux" / "win32" | `process.platform` |
| `osVersion` | "24.6.0" | OS kernel version |
| `osArch` | "x64" / "arm64" | `process.arch` |
| `machineId` | SHA256(MAC address) | Persistent device ID |
| `durationMs` | Event duration | Per-event timing |
| `experiments` | Active A/B tests | Unleash flag states |
| `extra.*` | Event-specific metadata | Varies by event type |

### Upload Flow

```javascript
// HTTP POST with binary protobuf
fetch(pWt, {
    method: "POST",
    headers: {"Content-Type": "application/octet-stream"},
    body: a,           // Serialized protobuf
    redirect: "follow"
})

// If OAuth token available, uses authenticated request instead:
Pke(o, this.q).request({
    url: pWt,
    method: "POST",
    headers: {"Content-Type": "application/octet-stream"},
    body: a,
    responseType: "arraybuffer"
})
```

### Error Handling & Retry

```javascript
// 401 → retry later (token refresh)
// 4xx → drop events (client error, no retry)
// 5xx → retry later (server error)
// Response includes nextRequestWaitMillis for server-controlled backoff
```

### Shutdown Behavior

```javascript
// On app shutdown, flush remaining events (500ms timeout)
async L() {
    this.J();  // Clear periodic timer
    try {
        await Promise.race([
            this.G(),  // Flush buffer
            new Promise((t, r) => setTimeout(() => r(new Error("Flush timeout")), 500))
        ]);
    } catch (t) {
        console.error("Failed to flush on shutdown:", t);
    }
}
```

### Known Event Names (from main.js)

| Event | Context |
|-------|---------|
| `extension_installed` | Extension installs (ID, UUID, version, publisher) |
| `OPENVSX_API_CALL` | Extension marketplace API metrics |
| `process_perf_stats` | Process CPU/memory stats |
| `agent_window_unresponsive` | Window hang detection |
| `agent_window_responsive` | Window recovery |
| `KEYBOARD_SHORTCUT` | Keyboard shortcut usage |
| `settings_page_viewed` | Settings page views |

### Additional Telemetry Methods

```javascript
// Error traces (with stack traces)
async recordError(t, r = false) {
    const n = $tt(dIr, t);
    // ... wraps in errorTraceMetadata protobuf, queues for upload
}

// Observability data (has sensitive/non-sensitive split)
async logObservabilityData(t) {
    const r = Object.entries(t.nonSensitiveData || {}).map(...);
    const n = Object.entries(t.sensitiveData || {}).map(...);
    // Sensitive data is stripped before logging in some codepaths
}
```

### VS Code Telemetry (second pipeline)

Standard VS Code telemetry running simultaneously:

```javascript
p["common.machineId"] = i;          // MAC address SHA256
p["common.sqmId"] = s;              // SQM ID
p["common.devDeviceId"] = o;        // Device ID
p.sessionID = bd() + Date.now();    // Session-unique
p.commitHash = n;                   // Build commit
p.version = a;                      // App version
p["common.releaseDate"] = d;        // Build date
p["common.platformVersion"] = ...;  // OS version
p["common.platform"] = ...;         // OS type
p["common.nodeArch"] = r;           // CPU arch
p["common.product"] = "desktop";
p["common.msftInternal"] = u;       // (inherited from VS Code!)
```

### Telemetry Levels

Users can reduce telemetry:
```
NONE = 0    // No telemetry
CRASH = 1   // Crash reports only
ERROR = 2   // Errors + crashes
USAGE = 3   // Full usage telemetry (default)
```

## Impact

1. **Two independent pipelines** — User may disable one without knowing about the other
2. **Persistent buffer** — Events survive app restarts via `antigravityAnalytics.clearcutBuffer`
3. **OAuth-authenticated** — Events tied to Google account when logged in
4. **Binary protobuf** — Not human-readable in network inspection tools
5. **Machine ID correlation** — Same `machineId` sent to both Google Clearcut AND VS Code telemetry
6. **10K event batches** — High volume data collection
7. **Server-controlled backoff** — `nextRequestWaitMillis` allows server to control polling frequency

## Benign Alternative

Product analytics is standard. Clearcut is Google's standard analytics system (also used by YouTube, Google Play, etc.). The dual pipeline is likely because Antigravity inherited VS Code's telemetry system and added Google's own. However, users expect the VS Code telemetry settings to be the single control point.
