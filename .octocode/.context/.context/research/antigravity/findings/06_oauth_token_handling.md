# Finding 06: OAuth Token Lifecycle — Storage, Migration, and Exposure

**Severity:** `medium` | **Confidence:** `confirmed` | **Category:** Authentication / Credential Handling

---

## Summary

Antigravity stores Google OAuth tokens (access token, refresh token, expiry, token type) in a Unified State Sync (USS) system. The token handling includes a legacy migration path from Codeium's state storage, JSON serialization of token data, and exposure of the OAuth token to the Clearcut analytics pipeline for authenticated telemetry. The extension server also has `GetSecretValue` / `StoreSecretValue` gRPC endpoints for secret management.

## Evidence

### Token Storage Architecture

**Source:** `main.js` — `out-build/vs/platform/unifiedStateSync/`

```javascript
// USS topic for OAuth
const P8t = "uss-oauth";
const ife = "oauthTokenInfoSentinelKey";

// Token storage key
const nOt = "antigravityUnifiedStateSync.oauthToken";
```

### Token Structure

```javascript
const tokenInfo = {
    accessToken: s.accessToken,      // Google OAuth access token
    refreshToken: s.refreshToken,    // Long-lived refresh token
    expiryDateSeconds: Number(s.expiry?.seconds ?? 0),
    tokenType: s.tokenType           // "Bearer"
};
```

### Legacy Migration (Codeium → Antigravity)

```javascript
// One-time migration flag
const rOt = "antigravityUnifiedStateSync.oauthToken.hasLegacyMigrated";

function GTs(e, t, r, n) {
    if (r.getItem(rOt, false)) return;  // Already migrated
    r.setItem(rOt, true);
    
    e.info("[OAuthTokenLifecycle] Starting one-time OAuth token migration from legacy state sync");
    
    const a = t.get(Rfe, -1);  // Legacy agent manager init state
    if (!a) {
        e.info("[OAuthTokenLifecycle] No agent manager init state found, skipping migration");
        return;
    }
    
    try {
        const i = Hs(a, K9);
        const { oauthTokenInfo: s } = i;
        
        if (!s || !s.accessToken) {
            e.info("[OAuthTokenLifecycle] No legacy OAuth token found to migrate");
            return;
        }
        
        const o = {
            accessToken: s.accessToken,
            refreshToken: s.refreshToken,
            expiryDateSeconds: Number(s.expiry?.seconds ?? 0),
            tokenType: s.tokenType
        };
        
        // Store in USS
        n.data[ife] = mr(Vl, { value: JSON.stringify(o) });
        e.info("[OAuthTokenLifecycle] Successfully migrated OAuth token from legacy state sync to USS");
    } catch (i) {
        e.error("[OAuthTokenLifecycle] Error during OAuth token migration:", i);
    }
}
```

### Token Used for Clearcut Analytics

The Clearcut analytics service subscribes to OAuth tokens:
```javascript
constructor(t, r, n, a, i, s) {
    // ...
    this.g = this.q.subscribe("uss-oauth");  // Subscribes to OAuth token changes
    // ...
}
```

When uploading analytics, if OAuth token is available:
```javascript
// Authenticated Clearcut upload
u = await Pke(o, this.q).request({
    url: pWt,  // play.googleapis.com/log
    method: "POST",
    headers: {"Content-Type": "application/octet-stream"},
    body: a,
    responseType: "arraybuffer"
});
```

### Auth Service

```javascript
// AntigravityAuthMainService
this.n = this.C.subscribe("uss-oauth");
this.N().then(() => {
    this.g.info("[Auth] AntigravityAuthMainService initialized");
}).catch(f => {
    this.g.error("[Auth] Error initializing AntigravityAuthMainService:", f);
});
```

### Secret Management Endpoints

From gRPC service definitions:
```
/exa.extension_server_pb.ExtensionServerService/GetSecretValue
/exa.extension_server_pb.ExtensionServerService/StoreSecretValue
```

### Token Refresh Errors

From Go binary:
```
"Failed to persist refreshed token for %s: %v"
"Failed to save refreshed token: %v"
"failed to create token storage: %w"
"failed to read token from file: %w"
```

### OIDC Flow

```
/exa.api_server_pb.ApiServerService/ExchangeOidcCode
/exa.api_server_pb.ApiServerService/RefreshOidcToken
```

## Token Flow Diagram

```
User clicks "Login"
    ↓
Browser OAuth flow → auth code
    ↓
ExchangeOidcCode → access_token + refresh_token
    ↓
Store in USS ("uss-oauth" topic)
    ↓
Token distributed to:
├── Language Server (gRPC auth)
├── Clearcut Analytics (authenticated uploads)
├── Cloud Code API (model requests)
├── Unleash proxy (feature flags)
└── Extension Server (secret management)
```

## Impact

1. **JSON serialization** — Token stored as JSON string in USS, not encrypted at rest
2. **Refresh token persistence** — Long-lived refresh token survives app restarts
3. **Token shared with analytics** — OAuth token used to authenticate Clearcut telemetry, tying analytics to user identity
4. **Legacy migration** — Tokens from Codeium installation are migrated into Antigravity
5. **Secret management** — `GetSecretValue`/`StoreSecretValue` endpoints exist but their storage mechanism is not validated
6. **Agent access** — If the agent can call `GetSecretValue`, it could potentially read stored secrets

## Benign Alternative

OAuth token handling is necessary for the product to function (Google sign-in, API access). The USS system appears to be a reasonable state sync mechanism. The main concerns are:
- Token exposure to analytics pipeline
- JSON storage without additional encryption
- The `GetSecretValue` endpoint's access controls

## Remediation

- Encrypt tokens at rest (not just JSON serialization)
- Separate analytics authentication from user session tokens
- Ensure `GetSecretValue` is not accessible to the agent's tool system
- Audit all consumers of the `uss-oauth` topic
