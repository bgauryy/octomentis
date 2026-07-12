# Access Control Attacks

> How attackers find and exploit authorization failures in JS systems. Every pattern here is a finding category — look for the JS fingerprint, then prove the exploit path.

Pair with [Advanced Threat Patterns](./advanced-threat-patterns.md) for deeper SSRF/command injection/path traversal detection regex, [Security Investigation Reference](./security-investigation-reference.md) for search packs (especially Pack E for secrets and Pack G for high-impact outcomes), and [Attacker Profiles](./attacker-profiles.md) for threat actor context.

---

## 1. The Core Problem: Authorization Is Enforced in Two Places

```
CLIENT-SIDE   →  shows/hides UI, suggests permissions, fast feedback
SERVER-SIDE   →  the only enforcement that matters
```

**Attacker's rule**: If authorization exists only in JS, it does not exist. Find client-side permission checks → hit the backend directly.

---

## 2. Client-Side Permission Checks (Always Bypassable)

### 2.1 Role-Based UI Gating

```javascript
// Pattern: user role in localStorage/cookie → UI decision
if (user.role === 'admin') { renderAdminPanel(); }
if (currentUser.permissions.includes('delete')) { showDeleteButton(); }
if (store.getState().auth.isAdmin) { /* admin route */ }

// Pattern: JWT decoded client-side for authorization
const payload = JSON.parse(atob(token.split('.')[1]));
if (payload.role === 'admin') { /* privilege check in frontend only */ }
```

**Detection regex:**
```
/\.role\s*===?\s*['"]admin['"]/
/\.permissions\.includes\(/
/isAdmin\s*[=:]/
/atob\(.*\.split\('\.'\)/   # JWT decode without verification
```

**Exploit**: Find the role check in JS → find the API endpoint it guards → call it directly with a regular user token. The backend often trusts the client.

### 2.2 Feature Flag / Permission Flag Manipulation

```javascript
// Feature flags stored client-side
window.__FEATURE_FLAGS__ = { adminDashboard: false, billing: false };
if (window.featureFlags.billing) { /* locked behind flag */ }

// LaunchDarkly / Split.io client-side only evaluation
if (ldClient.variation('admin-feature', false)) { /* bypassed by modifying SDK */ }
```

**Detection:**
```
/__FEATURE_FLAGS__/
/featureFlags\[/
/ldClient\.variation/
/\.variation\s*\(/
```

**Exploit**: Override flag via browser console or intercept the flag response → feature unlocks even though user shouldn't have access.

### 2.3 Disabled Route Still Exists

```javascript
// React Router / Vue Router — route defined but "hidden"
const routes = [
  { path: '/admin', component: AdminPanel, meta: { requiresAdmin: true } },
  { path: '/billing/internal', component: InternalBilling } // no guard
];

// Guard only on navigation, not on direct access
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAdmin && !store.state.user.isAdmin) next('/');
  else next(); // route exists, just not navigated to
});
```

**Detection:**
```
/meta:\s*\{.*requiresAdmin/
/router\.beforeEach/
/canActivate.*AuthGuard/    # Angular guard
/navigate\(\[.*admin/
```

**Exploit**: Navigate directly to `/admin` or `/billing/internal` — route guard fires on navigation but underlying component renders if backend doesn't re-check.

---

## 3. IDOR — Insecure Direct Object References

### 3.1 Object IDs Exposed in JS

```javascript
// IDs embedded in JS state
const user = { id: 12345, accountId: 'acc_abc123' };
fetch(`/api/users/${userId}/profile`);
fetch(`/api/documents/${docId}/download`);
fetch(`/api/invoices/${invoiceId}`);

// ID patterns in API calls
axios.get(`/v1/accounts/${this.accountId}/settings`);
```

**Detection regex:**
```
/\/api\/[^/]+\/\$\{/          # template literal in API path
/\/v\d\/[^/]+\/\$\{/
/fetch\(`[^`]*\$\{[^}]+Id/    # dynamic ID in fetch URL
```

**Exploit**: Enumerate other user IDs in the same endpoint. If server returns data without ownership check → IDOR. Look for sequential IDs or UUIDs in JS bundles.

### 3.2 Predictable ID Patterns in Bundles

Look for:
- Sequential integers: `userId: 1001`, `userId: 1002` in JS state snapshots
- UUIDs that appear in multiple API calls (suggesting stable user IDs, not session tokens)
- Base64-encoded IDs: `dXNlcjoxMjM0NQ==` = `user:12345` (GraphQL cursor pattern)

```javascript
// GraphQL IDOR via node ID
fetch('/graphql', {
  method: 'POST',
  body: JSON.stringify({
    query: `{ node(id: "dXNlcjoxMjM0NQ==") { ... on User { email, role } } }`
  })
});
```

### 3.3 Mass Assignment via JS Payload Construction

```javascript
// Object spread from user input → server update
const updatePayload = { ...userInput, userId: currentUser.id };
fetch('/api/profile/update', { method: 'PUT', body: JSON.stringify(updatePayload) });

// If server accepts all fields including 'role', 'isAdmin', 'plan'
```

**Detection:**
```
/\.\.\.\s*\w*(input|data|params|body|form)/i
/Object\.assign\(\s*\{\}/
/JSON\.stringify\(.*\.\.\./
```

**Exploit**: Add `role: "admin"` or `isAdmin: true` or `plan: "enterprise"` to the spread input. If server trusts client-provided fields → privilege escalation.

---

## 4. JWT Attacks via JS Analysis

### 4.1 JWT Secret Exposure

```javascript
// Hardcoded JWT secret
const token = jwt.sign(payload, 'my-super-secret-key-123');
const token = jwt.sign(payload, process.env.JWT_SECRET || 'fallback-secret');

// Weak secret / default secret
jwt.verify(token, 'secret');
jwt.verify(token, 'password');
```

**Detection:**
```
/jwt\.sign\(.*,\s*['"][^'"]{4,}['"]/    # hardcoded secret
/jwt\.verify\(.*,\s*['"](?:secret|password|key|test)['"]/
/process\.env\.JWT_SECRET\s*\|\|\s*['"]/  # fallback secret
```

**Exploit**: Found secret → forge any JWT with any role/userId.

### 4.2 Algorithm Confusion (alg:none / RS→HS)

```javascript
// Accepting 'none' algorithm
jwt.verify(token, secret, { algorithms: ['HS256', 'none'] });

// Not specifying algorithm → accepts RS256 public key as HS256 secret
jwt.verify(token, publicKey);  // if public key is known, sign with HS256 using it
```

**Detection:**
```
/algorithms:\s*\[.*['"]none['"]/
/jwt\.verify\([^,]+,\s*[^,]+\)(?!\s*,)/   # missing options = accepts any alg
```

### 4.3 JWT Payload Decoded Client-Side for Access Control

```javascript
// Only client decodes → server never re-validates role
function isAdmin() {
  const payload = jwtDecode(localStorage.getItem('token'));
  return payload.role === 'admin';
}
```

If the server sets `role` in the JWT but doesn't verify the JWT on admin endpoints → modify localStorage token (re-encode with modified payload, no signature verification on server).

---

## 5. OAuth / SSO Abuse

### 5.1 State Parameter Missing (CSRF on OAuth Flow)

```javascript
// OAuth initiation without state
window.location = `https://auth.provider.com/oauth/authorize?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code`;
// Missing: &state=${csrfToken}
```

**Detection:**
```
/oauth\/authorize\?/
/response_type=code/
```

Look for `&state=` in the redirect URL. If absent → OAuth CSRF.

### 5.2 Redirect URI Open Redirect

```javascript
// User-controlled redirect_uri
const redirectUri = new URLSearchParams(window.location.search).get('redirect_uri');
window.location = `https://auth.provider.com/authorize?redirect_uri=${redirectUri}`;
```

**Detection:**
```
/redirect_uri.*URLSearchParams/
/redirect_uri.*location\.search/
/redirect_uri.*\bget\b\(/
```

### 5.3 Access Token in URL / JS Variable

```javascript
// Token leaks to Referer header, browser history, logs
window.location = `https://app.com/callback#access_token=${token}`;
const token = window.location.hash.split('access_token=')[1];
// Token now in JS, accessible to any script on page
```

**Detection:**
```
/access_token.*location\.hash/
/location\.hash.*access_token/
/#access_token=/
```

---

## 6. API Authorization Bypass Patterns

### 6.1 Verb Tampering

```javascript
// Server checks authorization on POST but not GET, PUT, PATCH
fetch('/api/admin/users', { method: 'GET' });  // authorized
fetch('/api/admin/users', { method: 'POST' }); // unauthorized? try GET or HEAD
fetch('/api/admin/users/123', { method: 'DELETE' }); // try PATCH with same data
```

Find every admin/protected API endpoint in JS bundles → enumerate HTTP methods against each.

### 6.2 Path Traversal in API Calls

```javascript
// User-controlled segment in API path
const file = req.query.file;
fetch(`/api/files/${file}/content`);
// Try: /api/files/../../etc/passwd/content
// Try: /api/files/%2F..%2F..%2Fetc%2Fpasswd/content
```

**Detection:**
```
/\/\$\{[^}]+\}\/content/
/\/\$\{[^}]+\}\/download/
/\$\{.*path.*\}/
/\$\{.*file.*\}/
```

### 6.3 Parameter Pollution

```javascript
// API builds query from user input
fetch(`/api/search?category=${category}&userId=${userId}`);
// Inject: category=books&userId=victim_id (overrides userId)
// Or: category=books%26userId%3Dother_user
```

### 6.4 Hidden Admin Endpoints in JS Bundles

Enumerate all API paths in the bundle:

```bash
# Grep for API path patterns
/\/api\/[a-zA-Z0-9/_-]+/g
/\/v\d\/[a-zA-Z0-9/_-]+/g
/\/admin\//
/\/internal\//
/\/management\//
/\/debug\//
/\/superuser\//
```

Backend may expose admin routes without requiring admin role — the UI just doesn't show them.

---

## 7. GraphQL Authorization Failures

### 7.1 Introspection Enabled in Production

```javascript
// GraphQL endpoint — try introspection
fetch('/graphql', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query: '{ __schema { types { name fields { name } } } }' })
});
```

If introspection works → full schema dump → discover hidden mutations (deleteUser, promoteToAdmin, etc.)

### 7.2 Missing Field-Level Authorization

```javascript
// Query returns more than it should
`query { user(id: "123") { email, role, passwordHash, internalNotes } }`
// Field resolvers may lack per-field authorization
```

### 7.3 Batching Attack / Query Complexity

```javascript
// Batch login brute force
const queries = passwords.map((p, i) =>
  `query q${i} { login(username: "admin", password: "${p}") { token } }`
).join('\n');
// Send in one request → bypasses per-request rate limits
```

---

## 8. SSRF via JS-Controlled URLs

### 8.1 User-Controlled URL in Server Request

```javascript
// User supplies URL → server fetches it
fetch('/api/proxy?url=' + userSuppliedUrl);
fetch('/api/webhook/test', { body: JSON.stringify({ url: userInput }) });
fetch('/api/screenshot?target=' + encodeURIComponent(targetUrl));
```

**Detection:**
```
/proxy\?url=/
/webhook.*url.*userInput/i
/screenshot.*target=/
/fetch.*url.*param/i
```

**Exploit payloads**:
- `http://169.254.169.254/latest/meta-data/` (AWS metadata)
- `http://localhost:8080/admin`
- `file:///etc/passwd`
- `http://10.0.0.1/internal-api`

### 8.2 URL in Webhook Configuration

```javascript
// Webhook URL stored and later fetched server-side
fetch('/api/integrations/webhook', {
  method: 'POST',
  body: JSON.stringify({ url: webhookUrl, events: ['payment.success'] })
});
```

If `webhookUrl` is not validated → SSRF on every triggered event.

---

## 9. Insecure Storage of Auth Tokens

### 9.1 Tokens in localStorage (XSS Accessible)

```javascript
localStorage.setItem('authToken', token);
localStorage.setItem('jwt', response.data.token);
sessionStorage.setItem('accessToken', token);
```

**Detection:**
```
/localStorage\.setItem\(.*[Tt]oken/
/localStorage\.setItem\(.*jwt/i
/sessionStorage\.setItem\(.*[Tt]oken/
```

If there is any XSS on the domain → token stolen. **HttpOnly cookie is the safe alternative.**

### 9.2 Sensitive Data in URL Parameters

```javascript
window.location = `/dashboard?token=${authToken}`;
history.pushState({}, '', `/reset?code=${resetCode}`);
```

**Detection:**
```
/location.*token=/
/location.*code=/
/pushState.*token=/
```

Tokens in URLs → Referer leakage, server logs, browser history.

### 9.3 Token Logging

```javascript
console.log('User logged in:', user.token);
console.log('Auth header:', headers.Authorization);
Sentry.captureException(error, { extra: { token: currentToken } });
```

---

## 10. Privilege Escalation via Insecure Deserialization

### 10.1 JSON Object with Privilege Fields Trusted Client-Side

```javascript
// User-modifiable object passed back to server
const userData = JSON.parse(localStorage.getItem('user'));
fetch('/api/update-profile', {
  body: JSON.stringify({ ...userData, displayName: newName })
});
// userData may contain: role, isAdmin, plan, permissions
```

### 10.2 node-serialize RCE Pattern

```javascript
// _$$ND_FUNC$$_ in serialized JSON
const data = serialize.unserialize(userInput);
// {"rce":"_$$ND_FUNC$$_function(){require('child_process').exec('id')}()"}
```

**Detection:**
```
/_\$\$ND_FUNC\$\$_/
/serialize\.unserialize/
/node-serialize/
```

### 10.3 Prototype Pollution → Privilege Escalation Gadget

```javascript
// Source: user input merged into object
_.merge(options, JSON.parse(userInput));

// Payload: {"__proto__": {"isAdmin": true}}
// Gadget: if ({}.isAdmin) { /* admin path */ }

// More dangerous gadget:
// {"__proto__": {"NODE_OPTIONS": "--require /tmp/pwn.js"}}
```

**Detection (source):**
```
/_.merge\s*\(/
/Object\.assign\s*\(\s*\{\}/
/jQuery\.extend\s*\(\s*true/
/deepMerge\s*\(/
```

**Detection (gadget):**
```
/\{\}\.isAdmin/
/Object\.prototype\.isAdmin/
/opts\.shell/          # child_process gadget
/spawnArgs\[0\]/
```

---

## 11. CORS Misconfiguration

```javascript
// Server reflects Origin header without validation
// Look in JS for cross-origin requests to sensitive endpoints
fetch('https://api.victim.com/user/data', { credentials: 'include' });

// If CORS allows any origin with credentials:
// Access-Control-Allow-Origin: *  (+ credentials) = data theft
// Access-Control-Allow-Origin: null (+ credentials) = sandboxed iframe attack
```

**Detection (client):**
```
/credentials:\s*['"]include['"]/
/withCredentials:\s*true/
/XMLHttpRequest.*withCredentials/
```

**Test**: Does the server's `Access-Control-Allow-Origin` reflect the request's `Origin`? If yes + `credentials: include` → full auth bypass from any attacker-controlled origin.

---

## 12. Path Traversal in File Operations

```javascript
// User-supplied filename → file read
const filePath = path.join(__dirname, 'uploads', userFilename);
fs.readFile(filePath, callback);

// Bypass: userFilename = '../../etc/passwd'
// path.join('/app/uploads', '../../etc/passwd') = '/etc/passwd'

// Safe: path.resolve + check startsWith
const resolved = path.resolve('/app/uploads', userFilename);
if (!resolved.startsWith('/app/uploads/')) throw new Error('Traversal');
```

**Detection:**
```
/path\.join\(.*user/i
/readFile\(.*req\.(params|query|body)/
/readFileSync\(.*\+/
/createReadStream\(.*param/
```

---

## 13. Authorization Bypass Quick-Reference

| Vulnerability | JS Fingerprint | Exploit |
|---|---|---|
| Client-side role check | `user.role === 'admin'` in frontend | Call guarded API endpoint directly |
| IDOR | `fetch('/api/item/${id}')` with user-controlled id | Enumerate other users' IDs |
| JWT secret exposed | `jwt.sign(payload, 'hardcoded')` | Forge any token with any claims |
| JWT alg:none | `algorithms: ['none']` in verify | Strip signature, modify claims |
| Mass assignment | `{...userInput}` in PUT/PATCH body | Add `role:"admin"` to spread |
| Feature flag client-only | `featureFlags.adminPanel` in JS | Override flag in browser |
| OAuth CSRF | `authorize?` without `&state=` | Force victim OAuth flow |
| SSRF | `fetch('/proxy?url='+input)` | Point to internal metadata service |
| GraphQL IDOR | `node(id: base64)` query | Change base64 ID to another user |
| Prototype pollution | `_.merge({}, userInput)` | `{"__proto__":{"isAdmin":true}}` |
| Path traversal | `readFile(join(dir, userParam))` | `../../etc/passwd` |
| Token in localStorage | `localStorage.setItem('jwt',...)` | XSS → steal token |

---

## 14. Bug Bounty Hunting Checklist for Authorization

```
[ ] Every API endpoint found in JS — test directly with low-priv token
[ ] Admin/internal routes in bundle — force-browse them
[ ] JWT: decode payload, check algorithm, look for hardcoded secrets
[ ] Client-side role checks — list them, hit the guarded API directly
[ ] Object spread in mutations — add privilege fields
[ ] GraphQL: run introspection, enumerate mutations, check field-level auth
[ ] Feature flags: list them, force-enable via override
[ ] CORS: test with credentials:include, check if origin is reflected
[ ] OAuth: check for missing state, open redirect_uri, token in URL
[ ] SSRF: find proxy/webhook/screenshot endpoints, point at metadata
[ ] localStorage tokens: XSS anywhere on domain = auth bypass
[ ] Path traversal: user-controlled filename in fs operations
```

---

## 15. Detection Strategy for Authorization Issues

### Step 1 — Find All API Endpoints in the Bundle

```
localSearchCode: /\/api\/[a-zA-Z0-9\/_-]{3,}/
localSearchCode: /\/v\d\/[a-zA-Z0-9\/_-]{3,}/
localSearchCode: /(admin|internal|management|superuser|debug)/
```

### Step 2 — Find All Role/Permission Checks

```
localSearchCode: /(\.role|\.permissions|isAdmin|isSuperUser|hasPermission|canAccess)/
localSearchCode: /(featureFlags|ldClient\.variation|splitClient\.getTreatment)/
```

### Step 3 — Find All Auth Token Handling

```
localSearchCode: /(localStorage|sessionStorage)\.(setItem|getItem).*[Tt]oken/
localSearchCode: /jwt\.(sign|verify|decode)/
localSearchCode: /Bearer.*\$\{/
```

### Step 4 — Find All User-Controlled Data in Sensitive Operations

```
localSearchCode: /\.\.\.(req\.(body|query|params)|userInput|formData)/
localSearchCode: /(_.merge|Object\.assign|deepMerge).*req\./
localSearchCode: /path\.(join|resolve).*req\./
localSearchCode: /readFile.*req\./
```

### Step 5 — Trace Each Hit

1. Where does the value come from? (user input? JWT? localStorage?)
2. Is it validated/sanitized before use?
3. What does the server do with it? (is there server-side re-authorization?)
4. What's the worst-case abuse?
