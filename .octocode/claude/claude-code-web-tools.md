# Claude Code — WebFetch & WebSearch Implementation

## TL;DR — How WebFetch Works

When Claude Code runs `WebFetch(url)`, it does the following:

1. **Validates the URL** — must be parseable, no embedded credentials, ≥2-part hostname.
2. **Checks an in-memory cache** — returns immediately if already fetched this session.
3. **Chooses a transport mode** — **all three conditions must be true** to use the CCR proxy, otherwise direct fetch is used:
   - **CCR proxy** — requires: (a) running as a `firstParty` client (not Bedrock/Vertex/Foundry), AND (b) `CLAUDE_CODE_WEBFETCH_USE_CCR_PROXY` env var is set, AND (c) `CLAUDE_CODE_SESSION_ID` starts with `cse_` or `session_`. When active, sends a `POST` to `https://api.anthropic.com/v1/code/sessions/<id>/worker/web-fetch` with `{url}` as body. The proxy enforces a *provenance rule* server-side — it only fetches URLs that already appeared in the conversation.
   - **Direct fetch** (default, used whenever any CCR condition fails): Claude Code itself makes the HTTP request via `axios`.
4. **Direct-fetch path only — domain blocklist check** (skipped by `skipWebFetchPreflight`): calls `GET https://api.anthropic.com/api/web/domain_info?domain=<host>`. If the domain is blocked, the tool errors immediately.
5. **Fetches with axios** using `Accept: text/markdown, text/html, */*` and a Claude Code `User-Agent`. Follows redirects *only within the same host* (different-host redirects are returned to the model as a message, not followed automatically).
6. **Converts HTML → Markdown** using the [Turndown](https://github.com/mixmark-io/turndown) library. Input is capped before conversion; if truncated, `[Content truncated due to length...]` is appended.
7. **Caches and returns** the markdown string (plus raw bytes, status code, content-type).

> **WebSearch is different** — it is *not* implemented locally. It is Anthropic's server-side API tool (`WebSearchTool20260209`). Claude Code only handles opt-in bookkeeping and request counting; the actual search runs on Anthropic's infrastructure.

---


> Reverse-engineered from `@anthropic-ai/claude-code` v2.1.197  
> Binary: 217MB Bun SEA (`darwin-arm64`)  
> Method: `strings` extraction from bundled JS bytecode

---

## Binary Structure

```
@anthropic-ai/claude-code (npm wrapper)
└── node_modules/@anthropic-ai/claude-code-darwin-arm64/
    └── claude          ← 217MB Mach-O arm64 Bun SEA
```

The `cli-wrapper.cjs` wrapper spawns the platform-specific native binary. The binary is a **Bun Single Executable Application** — not Node.js SEA — embedding all JS as Bun bytecode. Function names are preserved as export symbols; bodies are minified (e.g. `xJn` = `getURLMarkdownContent`).

---

## 1. WebFetch — Client-Side Tool

**Entry function**: `xJn` → exported as `getURLMarkdownContent`  
**Module export map** (`$_l`):

```
validateURL          → B_l
isPreapprovedUrl     → wJn
isPermittedRedirect  → YIo
getWithPermittedRedirects → JIo
getURLMarkdownContent     → xJn
convertHtmlToMarkdown     → s7t
clearWebFetchCache        → vgm
checkDomainBlocklist      → U_l
applyPromptToMarkdown     → i7t
WebFetchTransportError    → o7t
MAX_MARKDOWN_LENGTH       → $Tt
```

### Full Flow

```
URL input
  │
  ├─ validateURL (B_l)
  │    • length ≤ kgm
  │    • parseable as URL
  │    • no credentials (username/password)
  │    • hostname has ≥2 parts
  │
  ├─ in-memory LRU cache hit? → return cached result
  │
  ├─ CCR proxy active? (ffl() / CLAUDE_CODE_WEBFETCH_USE_CCR_PROXY env)
  │    ├─ upgrade http:// → https://
  │    ├─ call hfl() → sends to "web-fetch-ccr-proxy" CCR endpoint
  │    ├─ provenance check: URL must have appeared in a prior user message
  │    │   or prior web_fetch result (enforced server-side by CCR)
  │    ├─ on redirect: isPermittedRedirect (same protocol/host/port)
  │    └─ on redirect to different host: returns { type: "redirect", redirectUrl }
  │        → caller must make a new WebFetch call with the new URL
  │
  └─ direct fetch (no CCR)
       ├─ upgrade http:// → https://
       │
       ├─ domain blocklist check (skipped if skipWebFetchPreflight):
       │   GET https://api.anthropic.com/api/web/domain_info?domain=<host>
       │   timeout: Dgm ms
       │   → { can_fetch: true }  → "allowed"  (cached in zIo)
       │   → { can_fetch: false } → "blocked"  → throw VIo (DomainBlockedError)
       │   → non-200 / network err → "check_failed" → throw KIo
       │
       ├─ JIo (getWithPermittedRedirects) — manual redirect loop, up to L_l hops
       │   axios options:
       │     method: GET
       │     headers:
       │       Accept:     "text/markdown, text/html, */*"
       │       User-Agent: fKr()   ← getWebFetchUserAgent()
       │     timeout:          Igm ms
       │     maxRedirects:     0   (handled manually)
       │     responseType:     "arraybuffer"
       │     maxContentLength: Hgm bytes
       │     validateStatus:   () => true   (no throw on 4xx/5xx)
       │
       │   redirect logic (30x responses in Pgm set):
       │     • read Location header
       │     • isPermittedRedirect(originalUrl, redirectUrl):
       │         same protocol + same port + same hostname (www. stripped)
       │       ✓ same host → follow recursively
       │       ✗ different host → return { type: "redirect", redirectUrl }
       │                           (caller must show redirect URL to user)
       │     • 403 + x-proxy-error: blocked-by-allowlist → throw N_l
       │
       ├─ binary/file responses (ofo(contentType)):
       │   save to temp file via rWe(); returns { persistedPath, persistedSize }
       │
       ├─ HTML response (contentType includes "text/html"):
       │   convertHtmlToMarkdown (s7t) via Turndown:
       │     1. strip style/script/noscript/iframe nodes first
       │     2. input capped to M_l chars before Turndown
       │     3. if truncated: append "\n[Content truncated due to length...]"
       │     4. Turndown rules: emphasis, bold, code, images, links, tables
       │     5. fallback: if Turndown throws → return raw HTML + log error
       │
       ├─ non-HTML response: use raw string as-is
       │
       └─ cache result (LRU, size = max(1, markdown byte length))
            returned shape:
              { bytes, code, codeText, content, contentType,
                persistedPath?, persistedSize? }
```

---

## Full Implementation (Reconstructed from Binary)

Below is the exact logic extracted from the Bun SEA binary via `strings`. Variable names are minified originals.

### Transport Mode Guard — `ffl()`

```js
// Returns the active CCR session ID, or undefined
function NKt() {
  const id = process.env.CLAUDE_CODE_SESSION_ID;
  if (id && (id.startsWith("cse_") || id.startsWith("session_")))
    return id;
}

// Returns true only when ALL THREE conditions hold:
function ffl() {
  if (_r() !== "firstParty") return false;         // ① must be first-party client
  if (!process.env.CLAUDE_CODE_WEBFETCH_USE_CCR_PROXY) return false; // ② env var set
  return !!NKt();                                  // ③ valid session ID present
}
```

> `_r()` returns the client type — `"firstParty"` | `"bedrock"` | `"vertex"` | `"foundry"`.  
> CCR proxy is **never used** on Bedrock, Vertex, or Foundry regardless of env vars.

---

### CCR Proxy Path — `hfl(url, signal)`

```js
// Builds proxy endpoint URL
function pmm() {
  const base = (process.env.ANTHROPIC_BASE_URL || "https://api.anthropic.com").replace(/\/+$/, "");
  return `${base}/v1/code/sessions/${encodeURIComponent(NKt())}/worker/web-fetch`;
}

// CCR proxy response schema (zod)
const ccrResponseSchema = z.object({
  url:             z.string().optional().default(""),
  destination_url: z.string().nullable().optional(),
  title:           z.string().optional().default(""),
  text:            z.string().optional().default(""),
  content_type:    z.string().nullable().optional(),
  error: z.object({
    error_type:    z.string(),
    error_message: z.string(),
  }).nullable().optional(),
});

async function hfl(url, signal) {
  const authHeaders = J0e(); // Anthropic auth headers
  let response;
  try {
    response = await axios.post(
      pmm(),
      { url },
      {
        signal,
        timeout: 40_000,           // 40 s
        maxContentLength: 12_582_912, // 12 MB
        headers: {
          ...authHeaders,
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        validateStatus: () => true,
      }
    );
  } catch (err) {
    if (isAbortError(err)) throw new AbortError();
    const code = err?.code ? String(err.code) : undefined;
    return {
      ok: false, source: "proxy", statusCode: 502,
      errorType: "PROXY_TRANSPORT",
      errorMessage: `Request to the WebFetch proxy failed (${code ?? "transport error"}).`,
    };
  }

  if (response.status !== 200) {
    const msg = typeof response.data?.message === "string"
      ? response.data.message.slice(0, 200) : undefined;
    return {
      ok: false, source: "proxy", statusCode: response.status,
      errorType: "PROXY_REJECTED",
      errorMessage: `The WebFetch proxy rejected the request (HTTP ${response.status}${msg ? `: ${msg}` : ""}).`,
    };
  }

  const parsed = ccrResponseSchema.safeParse(response.data);
  if (!parsed.success)
    return { ok: false, source: "proxy", statusCode: 502,
      errorType: "PROXY_BAD_RESPONSE",
      errorMessage: "The WebFetch proxy returned a malformed response." };

  if (parsed.data.error)
    return { ok: false, source: "target", statusCode: 502,
      errorType: parsed.data.error.error_type,
      errorMessage: parsed.data.error.error_message };

  return {
    ok: true,
    content: parsed.data.text,
    contentType: parsed.data.content_type || "text/plain",
    destinationUrl: parsed.data.destination_url || undefined,
  };
}
```

---

### Direct Fetch — `JIo(url, signal, isPermittedRedirect, depth)` 

```js
const REDIRECT_CODES = new Set([301, 302, 303, 307, 308]); // Pgm
const MAX_REDIRECTS = 3;  // L_l (confirmed by error message text)

// isPermittedRedirect (YIo): same-host check
function isPermittedRedirect(originalUrl, redirectUrl) {
  try {
    const orig = new URL(originalUrl);
    const redir = new URL(redirectUrl);
    if (redir.protocol !== orig.protocol) return false;   // must match http/https
    if (redir.port     !== orig.port)     return false;   // must match port
    if (redir.username || redir.password) return false;   // no credentials in redirect
    const strip = (h) => h.replace(/^www\./, "");        // ignore www. prefix
    return strip(orig.hostname) === strip(redir.hostname);
  } catch {
    return false;
  }
}

async function getWithPermittedRedirects(url, signal, checkRedirect, depth = 0) {
  if (depth > MAX_REDIRECTS) throw new TooManyRedirectsError(MAX_REDIRECTS);

  let response;
  try {
    response = await axios.get(url, {
      signal,
      timeout: /* Igm */ 30_000,
      maxRedirects: 0,                    // manual redirect handling
      responseType: "arraybuffer",
      maxContentLength: /* Hgm */ 10_485_760, // ~10 MB
      validateStatus: () => true,         // never throw on HTTP status
      headers: {
        Accept: "text/markdown, text/html, */*",
        "User-Agent": getWebFetchUserAgent(),
      },
    });
  } catch (err) {
    if (axios.isAxiosError(err) && !axios.isCancel(err))
      throw new WebFetchTransportError(err.message, err.code);
    throw err;
  }

  const { status, headers } = response;

  // 2xx — success
  if (status >= 200 && status < 300) return response;

  // 3xx — redirect
  if (REDIRECT_CODES.has(status)) {
    const location = headers.location;
    if (typeof location !== "string" || location.trim() === "")
      return { type: "http_error", statusCode: status };

    const redirectUrl = new URL(location, url).toString();

    if (checkRedirect(url, redirectUrl))
      return getWithPermittedRedirects(redirectUrl, signal, checkRedirect, depth + 1);

    // cross-host redirect: return to caller, DO NOT follow
    return { type: "redirect", originalUrl: url, redirectUrl, statusCode: status };
  }

  // 403 blocked by proxy allowlist
  if (status === 403 && headers["x-proxy-error"] === "blocked-by-allowlist")
    throw new DomainBlockedError(new URL(url).hostname);

  // other 4xx/5xx
  const retryAfter = headers["retry-after"];
  return {
    type: "http_error",
    statusCode: status,
    ...(typeof retryAfter === "string" && /^[0-9]{1,6}$/.test(retryAfter)
      && { retryAfter }),
  };
}
```

---

### Domain Blocklist Check — `U_l(hostname)`

```js
const domainAllowCache = new Map(); // zIo — cleared by clearWebFetchCache()

async function checkDomainBlocklist(hostname) {
  if (domainAllowCache.has(hostname)) return { status: "allowed" };
  try {
    const res = await axios.get(
      `https://api.anthropic.com/api/web/domain_info?domain=${encodeURIComponent(hostname)}`,
      { timeout: /* Dgm */ 5_000 }
    );
    if (res.status === 200) {
      if (res.data.can_fetch === true) {
        domainAllowCache.set(hostname, true);
        return { status: "allowed" };
      }
      return { status: "blocked" };
    }
    return { status: "check_failed", error: new Error(`Domain check returned status ${res.status}`) };
  } catch (err) {
    return { status: "check_failed", error: err };
  }
}
```

---

### Pre-approved Domains — `wJn(hostname, pathname)` / `isPreapprovedUrl`

These domains **bypass the blocklist API call entirely** (they are hardcoded in the binary as always-allowed):

```
platform.claude.com, code.claude.com, modelcontextprotocol.io, github.com/anthropics,
agentskills.io, docs.python.org, en.cppreference.com, docs.oracle.com, learn.microsoft.com,
developer.mozilla.org, go.dev, pkg.go.dev, www.php.net, docs.swift.org, kotlinlang.org,
ruby-doc.org, doc.rust-lang.org, www.typescriptlang.org, react.dev, angular.io, vuejs.org,
nextjs.org, expressjs.com, nodejs.org, bun.sh, jquery.com, getbootstrap.com, tailwindcss.com,
d3js.org, threejs.org, redux.js.org, webpack.js.org, jestjs.io, reactrouter.com,
docs.djangoproject.com, flask.palletsprojects.com, fastapi.tiangolo.com, pandas.pydata.org,
numpy.org, www.tensorflow.org, pytorch.org, scikit-learn.org, matplotlib.org,
requests.readthedocs.io, jupyter.org, laravel.com, symfony.com, wordpress.org/documentation,
docs.spring.io, hibernate.org, tomcat.apache.org, gradle.org, maven.apache.org,
asp.net, dotnet.microsoft.com, blazor.net, reactnative.dev, docs.flutter.dev,
developer.apple.com, developer.android.com, keras.io, spark.apache.org,
huggingface.co/docs, www.kaggle.com/docs, www.mongodb.com, redis.io,
www.postgresql.org, dev.mysql.com, www.sqlite.org, graphql.org, prisma.io,
docs.getdbt.com, docs.aws.amazon.com, cloud.google.com, kubernetes.io,
www.docker.com, www.terraform.io, www.ansible.com, vercel.com/docs, docs.stripe.com,
docs.netlify.com, devcenter.heroku.com, dev.wix.com/docs, cypress.io, selenium.dev,
docs.unity.com, docs.unrealengine.com, git-scm.com, nginx.org, httpd.apache.org
```

> Path-prefix entries (e.g. `github.com/anthropics`) only allow that prefix — `github.com/other` still hits the blocklist API.  
> Path-traversal bypass is blocked: URLs with `%2f`, `%5c`, `%2e` (encoded slashes/dots) in the path **do not** get the pre-approved exemption.

---

### HTML → Markdown — `s7t(html)`

```js
async function convertHtmlToMarkdown(html) {
  try {
    // Lazy-init Turndown, stripping noisy tags first
    const td = await getTurndown(); // removes style/script/noscript/iframe
    const truncated = html.slice(0, /* M_l */ 500_000); // cap input before Turndown
    let md = td.turndown(truncated);
    if (html.length > /* M_l */ 500_000)
      md += "\n[Content truncated due to length...]";
    return md;
  } catch (err) {
    // Fallback: return raw HTML if Turndown throws
    console.error(`Turndown failed, falling back to raw HTML: ${err.message}`);
    return html;
  }
}
```

---

### Main Entry Point — `xJn(url, toolContext)` / `getURLMarkdownContent`

```js
async function getURLMarkdownContent(url, toolContext) {
  // 1. Validate
  if (!validateURL(url))
    throw new ToolError("Invalid URL", "web-fetch-invalid-url");

  // 2. Cache hit
  const cached = fetchCache.get(url);
  if (cached) return { ...cached };

  // 3. CCR proxy path
  if (ffl()) {
    const httpsUrl = url.replace(/^http:\/\//i, "https://");
    const result = await hfl(httpsUrl, toolContext.signal);

    if (!result.ok) {
      if (result.source === "target" && result.errorType === "PROVENANCE_REQUIRED")
        return { type: "provenance_denied", url: httpsUrl, errorMessage: result.errorMessage };
      throw new ToolError(JSON.stringify({ error_type: result.errorType, source: result.source,
        message: result.errorMessage }), "web-fetch-ccr-proxy");
    }
    if (result.destinationUrl && !isPermittedRedirect(httpsUrl, result.destinationUrl))
      return { type: "redirect", originalUrl: httpsUrl,
        redirectUrl: result.destinationUrl, statusCode: 302 };

    const bytes = Buffer.byteLength(result.content, "utf8");
    const entry = { content: result.content, bytes, code: 200, codeText: "OK",
      contentType: result.contentType };
    fetchCache.set(url, entry, { size: Math.max(1, bytes) });
    return entry;
  }

  // 4. Direct fetch path
  let parsedUrl, finalUrl = url;
  try {
    parsedUrl = new URL(url);
    if (parsedUrl.protocol === "http:") {
      parsedUrl.protocol = "https:";
      finalUrl = parsedUrl.toString();
    }
    const hostname = parsedUrl.hostname;
    if (!getSettings().skipWebFetchPreflight) {
      const check = await checkDomainBlocklist(hostname);
      if (check.status === "blocked")     throw new DomainBlockedError(hostname);
      if (check.status === "check_failed") throw new DomainCheckFailedError(hostname);
    }
  } catch (err) {
    if (err instanceof DomainBlockedError || err instanceof DomainCheckFailedError) throw err;
    logError(err); // URL parsing edge case, swallow and continue with original
  }

  const httpResponse = await getWithPermittedRedirects(finalUrl, toolContext.signal, isPermittedRedirect);

  // Propagate redirect / http_error objects back to the tool runner unchanged
  if (isRedirectResult(httpResponse) || isHttpErrorResult(httpResponse))
    return httpResponse;

  // 5. Parse body
  const bodyBuffer = Buffer.from(httpResponse.data);
  httpResponse.data = null; // release memory
  const contentType = String(httpResponse.headers["content-type"] ?? "");

  // Persist binary/file types to disk
  let persistedPath, persistedSize;
  if (isBinaryContentType(contentType)) {
    const name = `webfetch-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
    const saved = await saveFileToDisk(bodyBuffer, contentType, name);
    if (!("error" in saved)) { persistedPath = saved.filepath; persistedSize = saved.size; }
  }

  const rawBytes = bodyBuffer.length;
  const rawText  = bodyBuffer.toString("utf-8");
  let content, contentBytes;
  if (contentType.includes("text/html")) {
    content      = await convertHtmlToMarkdown(rawText);
    contentBytes = Buffer.byteLength(content);
  } else {
    content      = rawText;
    contentBytes = rawBytes;
  }

  // 6. Cache and return
  const entry = {
    bytes: rawBytes,
    code: httpResponse.status,
    codeText: httpResponse.statusText,
    content,
    contentType,
    persistedPath,
    persistedSize,
  };
  fetchCache.set(url, entry, { size: Math.max(1, contentBytes) });
  return entry;
}
```

---

### Error Classes


| Class | Symbol | Condition |
|---|---|---|
| `WebFetchTransportError` | `o7t` | axios network/timeout error |
| Domain blocked | `VIo` | blocklist API says `can_fetch: false` |
| Domain check failed | `KIo` | blocklist API unreachable / non-200 |
| CCR allowlist blocked | `N_l` | HTTP 403 + `x-proxy-error: blocked-by-allowlist` |
| Too many redirects | `F_l` | exceeded `L_l` redirect hops |
| Invalid URL | `Ss("Invalid URL", "web-fetch-invalid-url")` | validateURL returns false |
| Provenance denied | `{ type: "provenance_denied" }` | CCR rejects non-provenance URL |

### Environment Variables / Settings

| Name | Effect |
|---|---|
| `CLAUDE_CODE_WEBFETCH_USE_CCR_PROXY` | Route all WebFetch through CCR proxy |
| `CLAUDE_CODE_WEBSEARCH_USE_CCR_PROXY` | Route WebSearch through CCR proxy |
| `skipWebFetchPreflight` | Skip domain blocklist API call (enterprise bypass) |

### Provenance Guard (CCR mode only)

```
URL not in provenance set. web_fetch can only retrieve URLs that appeared
in a user message or a prior web_fetch result. Ask the user to include
the URL in a message first.
```

Enforced server-side by CCR; **not** checked locally in direct-fetch mode.

### Cache

```js
vgm()  // clearWebFetchCache — clears both vJn (fetch cache) and zIo (domain blocklist cache)
```

Two separate LRU caches:
- `vJn` — full fetch results, keyed by URL
- `zIo` — domain blocklist results, `Map<hostname, true>`

---

## 2. WebSearch — API-Side Tool

**Not implemented locally.** The `web_search` tool is Anthropic's server-side built-in, registered with the API at call time.

### Tool Variants

| Tool | Models | Optional Parameters |
|---|---|---|
| `WebSearchTool20260209` | Opus 4.8, 4.7, 4.6 · Sonnet 4.6 | `AllowedDomains`, `BlockedDomains`, `MaxUses`, `UserLocation` |
| `WebSearchTool20250305` | Older models, Vertex AI | — |

### Claude Code's Role (Local Bookkeeping Only)

| Symbol | Purpose |
|---|---|
| `setSearchToolsOptIn` / `getSearchToolsOptIn` | Track whether user/org has opted in; tool only offered when enabled |
| `webSearchRequests` / `getTotalWebSearchRequests` | Count searches in the current session |
| `lastTotalWebSearchRequests` | Prior-session count for delta display |
| `enforce_web_search_mcp_isolation` | Feature flag: prevent `web_search` from running alongside arbitrary MCP servers |
| `CLAUDE_CODE_WEBSEARCH_USE_CCR_PROXY` | Route search calls through CCR proxy |

### Result Content Types

```
web_search_tool_result    ← standard Anthropic beta content block
tool_search_tool_result   ← tool-search variant
search_result             ← inner block type
```

### Failure Messages (surfaced in binary)

```
"web search is not enabled for this organization"
"is not enabled for (this|your) organization"
"server-side web search is not available in this environment"   ← Foundry/Vertex
"[ToolSearch:optimistic] disabled: Vertex AI does not accept the tool-search beta header.
 Set ENABLE_TOOL_SEARCH=true to override."
```

---

## 3. Architecture Summary

```
Claude Code CLI binary (Bun SEA)
│
├── WebFetch (client-side — fully local)
│    │
│    ├── Mode A: Direct fetch
│    │    ├── Domain blocklist: GET api.anthropic.com/api/web/domain_info
│    │    ├── HTTP via axios (Accept: text/html, User-Agent: claude-code)
│    │    ├── Manual redirect following (same-host only)
│    │    └── HTML → Markdown via Turndown
│    │
│    └── Mode B: CCR proxy (CLAUDE_CODE_WEBFETCH_USE_CCR_PROXY)
│         ├── Endpoint: "web-fetch-ccr-proxy"
│         ├── Provenance enforcement (server-side)
│         └── Skips local domain blocklist check
│
└── WebSearch (API-side — Anthropic servers)
     ├── Claude Code only: opt-in bookkeeping, request counting, CCR routing
     ├── WebSearchTool20260209 (current, dynamic filtering)
     └── WebSearchTool20250305 (legacy/Vertex)
```

---

## 4. Key Endpoints

| Purpose | URL |
|---|---|
| Domain blocklist check | `https://api.anthropic.com/api/web/domain_info?domain=<host>` |
| CCR session | `/v2/ccr-sessions/-/chat-project` |
| CCR webfetch proxy | `web-fetch-ccr-proxy` (internal CCR route) |
| OAuth metadata | `https://claude.ai/oauth/claude-code-client-metadata` |
| Anthropic MCP design | `https://api.anthropic.com/v1/design/mcp` |

---

*Source: `@anthropic-ai/claude-code` v2.1.197 · binary `strings` extraction · 2026-07-01*
