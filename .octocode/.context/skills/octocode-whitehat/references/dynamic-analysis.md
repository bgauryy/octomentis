# Dynamic Analysis

Load when static analysis hits a wall: obfuscated/minified code whose real behavior only surfaces at runtime, or when you need to prove a network call / data exfiltration actually happens.

**Fix for:** Puppeteer/CDP was mentioned only in a tool-ratings footnote. No actionable guidance existed for runtime interception, network capture, or behavior verification.

---

## When to Use Dynamic Analysis

- Static AST search found `eval` / `fetch` / `http.request` but the arguments are decoded at runtime (opaque string)
- You need to **prove** the decoded payload is a live C2 URL, not a test string
- Code checks `process.env.CI` or `NODE_ENV` before executing the payload (sandbox evasion)
- You found a suspicious npm package and want to observe its install-time behavior

**Safety rule:** run in a **disposable, network-isolated container** (no real credentials, no real network). Never run suspected malicious code on a host with access to production secrets.

---

## Node.js / npm Package — Install-Time Observation

```bash
# Create an isolated environment
docker run --rm -it --network=none node:20-alpine sh

# Inside container: instrument and install
npm install --ignore-scripts   # first check static analysis
npm install                    # then observe with scripts enabled, in isolation
```

**Intercept at the Node level (before running):**
```bash
# Patch require to log all modules loaded at install time
node -e "
const orig = Module._resolveFilename;
Module._resolveFilename = function(req, parent, isMain, opts) {
  console.log('[REQUIRE]', req);
  return orig.call(this, req, parent, isMain, opts);
};
" -r ./patch.js   # pre-require hook
```

---

## Browser JavaScript — Puppeteer / CDP

### Hook before page code runs

| Hook target | What it captures | How |
| ----------- | ---------------- | --- |
| `window.fetch` | All fetch calls with URL + body | Wrap before navigation |
| `XMLHttpRequest.open` | All XHR requests with method + URL | Wrap before navigation |
| `window.eval` | Eval'd code (first 200 chars) | Wrap before navigation |
| CDP `Network.requestWillBeSent` | Every network request including redirects + POST body | CDP session |
| `page.on('console')` | Console output (catches logged secrets) | Puppeteer event |

```javascript
const puppeteer = require('puppeteer');
const browser = await puppeteer.launch({ headless: true });
const page = await browser.newPage();

// Intercept BEFORE any page JS executes
await page.evaluateOnNewDocument(() => {
  // Log all fetch calls
  const origFetch = window.fetch;
  window.fetch = function(...args) {
    console.log('[FETCH]', JSON.stringify(args[0]), JSON.stringify(args[1]));
    return origFetch.apply(this, args);
  };

  // Log all XHR calls
  const origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url) {
    console.log('[XHR]', method, url);
    return origOpen.apply(this, arguments);
  };

  // Log eval calls
  const origEval = window.eval;
  window.eval = function(code) {
    console.log('[EVAL]', code.slice(0, 200));
    return origEval.call(this, code);
  };
});

// Capture network requests at CDP level (catches everything including redirects)
await page.setRequestInterception(true);
page.on('request', req => {
  if (!req.url().startsWith('data:')) {
    console.log('[NET]', req.method(), req.url());
  }
  req.continue();
});

page.on('console', msg => console.log('[CONSOLE]', msg.text()));
await page.goto('file://' + targetFile);
```

### CDP Network capture (lower level)

```javascript
const client = await page.target().createCDPSession();
await client.send('Network.enable');
client.on('Network.requestWillBeSent', event => {
  console.log('[REQUEST]', event.request.method, event.request.url);
  if (event.request.postData) {
    console.log('[POST BODY]', event.request.postData.slice(0, 500));
  }
});
```

---

## Frida — Native / Mobile Instrumentation

For native binaries (`.node`, `.so`, `.dylib`), Electron, and React Native when Puppeteer is insufficient:

```bash
# Install
pip install frida frida-tools

# Hook a function by name
frida -n "Electron Helper" -e "
  Interceptor.attach(Module.findExportByName(null, 'send'), {
    onEnter(args) { console.log('send:', Memory.readUtf8String(args[1])); }
  });
"
```

---

## Integration with Octocode Static Findings

Dynamic analysis confirms what static analysis suspects:

| Static finding | Dynamic verification |
| -------------- | -------------------- |
| `eval(atob(<opaque>))` found | Log decoded string at runtime |
| `fetch(<variable>)` to unknown URL | CDP `Network.requestWillBeSent` captures actual URL |
| `process.env.CI` check before network call | Set `CI=false` in container env and re-run |
| `postinstall` script found | Run in isolated container, capture all child processes |
| Native `.node` module with suspicious symbols | Frida hook the exported function |

**Evidence chain:** static `--pattern 'eval($$$ARGS)'` (structural) → dynamic log shows decoded C2 URL → `confirmed`, `critical`.
