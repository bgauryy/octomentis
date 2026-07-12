# Minification & Obfuscation

## JS minification, bundling & obfuscation — reference for analysis agents

Pair with [Security Investigation Reference](./security-investigation-reference.md) for threat hunting search packs, [Advanced Threat Patterns](./advanced-threat-patterns.md) for deep obfuscation detection signatures (string array rotation, eval chains, anti-analysis), and [AST Reference](./ast-reference.md) for structural proof after deobfuscation.

**Depth relationship:** This guide covers classification and identification (which bundler/obfuscator). For attack-specific detection regex on the same obfuscation techniques, escalate to [Advanced Threat Patterns](./advanced-threat-patterns.md) §1.

Use regex/substring search for first-pass detection. Use targeted extraction (charOffset/matchString) to examine matches. Each pattern appears once below — this is the single source of truth.

---

### 1. Vocabulary

| Term | Definition |
|------|-----------|
| **Minification** | Whitespace removal, identifier shortening, dead code elimination, property mangling. Tools: Terser, UglifyJS, Closure, esbuild, SWC |
| **Obfuscation** | String arrays + decoder, control-flow flattening, opaque predicates, eval/Function wrappers, encoding (JSFuck/aaencode/jjencode), anti-analysis |
| **Bundling** | Modules → runtime + module table. Classic: webpack, rollup, parcel, esbuild, browserify, vite. Modern: Turbopack, Rspack, Metro, Bun. Meta: tsup, unbuild, WMR, Snowpack |
| **Module systems** | CJS (`require`/`module.exports`), AMD, UMD, ESM (`import`/`export`), webpack (`__webpack_require__`), Turbopack (`__turbopack_require__`), Metro (`__d`/`__r`), parcel/browserify wrappers |
| **Anti-analysis** | Debugger traps, timing detection, anti-tampering, domain locking, environment fingerprinting |
| **WASM glue** | JS wrappers from Emscripten, wasm-bindgen, AssemblyScript bridging JS↔WebAssembly |
| **Platform bundles** | Non-browser targets: Electron, React Native/Hermes, Tauri, Capacitor/Cordova, Service Workers, Web Workers, Chrome extensions, userscripts |

**Minification vs obfuscation heuristic:** Short systematic identifiers (`a,b,c`) + compact formatting + no runtime decoding = minified. Hex identifiers (`_0x...`) + string table + decoder function + `while(true)/switch` = obfuscated.

---

### 2. Detection order (most specific first)

Check in this sequence. Stop at first confident match.

#### 2a. Pre-checks

| Check | Signal | Action |
|-------|--------|--------|
| Source map | `//# sourceMappingURL=` | Use it — reconstruct and stop |
| Non-JS binary | `.jsc` (Bytenode), `.hbc` (Hermes), `.wasm` | Not text — different analysis path |
| Encoding obfuscation | JSFuck (`[]()!+` only), aaencode (Japanese `ﾟΘﾟ`), jjencode (`$=~[];$={`) | Decode first before any other analysis |

#### 2b. Bundler detection

| Bundler | Unique markers | Notes |
|---------|---------------|-------|
| **Turbopack** | `__turbopack_require__`, `__turbopack_context__`, `__turbopack_load__`, `__turbopack_dynamic__` | Next.js. Context shortcuts: `.r`=require `.f`=context `.m`=module `.l`=load `.j`=dynamic |
| **Rspack** | `__webpack_require__` + `rv`/`ruid`/`__rspack_missing_module` | Webpack-compatible but has `rv` (RSPACK_VERSION), `ruid` (RSPACK_UNIQUE_ID). `__webpack_require__` alone ≠ webpack |
| **Webpack** | `__webpack_require__`, `webpackJsonp`, `__webpack_modules__`, `__webpack_exports__` (without Rspack markers) | Module table: `{0:function(...),1:function(...)}` or `__webpack_modules__[id]=function` |
| **Module Federation** | `container`, `remoteEntry`, shared scopes | Webpack 5 micro-frontends |
| **Metro** | `__d(function`, `__r(`, `__registerSegment` | React Native. Define: `__d(function(...),id,deps,...)` |
| **Parcel/Browserify** | `parcelRequire` or top-level `function(require,module,exports)` + module map | |
| **Rollup/ESM/UMD** | UMD checks, `exports.__esModule`, `export {` | Also: unbuild, WMR, Snowpack prod, Vite prod |
| **esbuild family** | Modern ESM, no framework runtime. `__export`, `__require` | Also: Bun (`bun:wrap` internal), tsup (thin esbuild wrapper) |
| **SystemJS** | `System.register()`, `System.import()` | Registry-based dynamic loader |
| **Closure ADVANCED** | No bundler runtime + `$jscomp$` helpers + property flattening (`a$b$c`) | Negative detection — absence of standard runtimes |

**Family tree:**
```
webpack ─┬─ Rspack (+rv/ruid)    esbuild ─┬─ Bun        Rollup ─┬─ unbuild/WMR/Snowpack
         └─ Turbopack            ├─ tsup           └─ Vite (prod)
                                           └─ Vite (dev:ESM)
Metro ── standalone    Closure ── standalone
```

**SWC note:** No stable `__swc_*` runtime — output shape depends on integration (webpack/Rollup-like). Use toolchain metadata over body fingerprinting.

#### 2c. Modern ESM signals

`import.meta.url` (assets), `import.meta.hot` (HMR), `import.meta.glob` (Vite), `import.meta.env`

#### 2d. Bundler features

| Feature | Markers |
|---------|---------|
| HMR | `module.hot.accept` (webpack), `import.meta.hot` (Vite) |
| Tree shaking | `/*#__PURE__*/`, `"sideEffects"` |
| Code splitting | `import('...')`, `require.ensure(...)` |
| Glob imports | `import.meta.glob(...)` (Vite) |
| Asset URLs | `new URL(..., import.meta.url)` |

#### 2e. Platform detection

| Platform | Markers |
|----------|---------|
| **Electron** | `require('electron')`, `ipcRenderer`/`ipcMain`, `contextBridge`, `process.versions.electron` |
| **React Native/Hermes** | `__d(function`, `.hbc` bytecode, `global.nativeFabricUIManager`, `__turboModuleProxy`, `HermesInternal` |
| **Tauri** | `window.__TAURI__`, `__TAURI_INTERNALS__`, `@tauri-apps/api` |
| **Capacitor** | `Capacitor.Plugins`, `registerPlugin(`, `@capacitor/core` |
| **Cordova** | `cordova.exec(success,fail,'Service','action',[args])`, `deviceready` |
| **Service Worker** | `self.addEventListener('fetch')`, `skipWaiting`, `clients.claim`, `workbox` |
| **Web Worker** | `postMessage`, `onmessage`, `importScripts`. Inline: `new Worker(URL.createObjectURL(new Blob([...])))` |
| **Chrome Extension** | `chrome.runtime`, `chrome.storage`, `browser.runtime` |
| **Userscript** | `// ==UserScript==`, `@grant`, `GM_*` functions, `unsafeWindow` |

#### 2f. WASM glue

| Compiler | Markers |
|----------|---------|
| **Emscripten** (C/C++) | `Module[`, `wasmBinary`, `HEAP8`/`HEAP16`/`HEAP32`/`HEAPU8`/`HEAPF32`/`HEAPF64`, `ENVIRONMENT_IS_`, `wasmMemory` |
| **wasm-bindgen** (Rust) | `__wbindgen_*`, `__wbg_*`, `imports.wbg`, `__wbindgen_throw` |
| **AssemblyScript** (TS) | `@assemblyscript`, `~lib/` paths, `env.abort`. Weak alone — pair with config |
| **Generic** | `WebAssembly.instantiate`, `WebAssembly.instantiateStreaming`, `WebAssembly.compile` |

#### 2g. Framework compiler output (NOT obfuscation)

| Framework | Markers |
|-----------|---------|
| **Babel** | `_classCallCheck`, `_createClass`, `_inherits`, `_asyncToGenerator` |
| **TypeScript NS** | `(function(X){...})(X\|\|(X={}))` pattern |
| **CoffeeScript** | `__hasProp`, `__extends`, `__slice`, `__bind` |
| **Svelte 4** | `$$invalidate`, `flush()` |
| **Svelte 5** | `$.effect`, `$.template_effect`, `$.derived` |
| **Vue SFC** | `__vue_component__`, `_sfc_main`, `_openBlock`, `_createElementBlock` |
| **Angular Ivy** | `ɵɵdefineComponent`, `ɵɵelementStart`, `ɵɵdirectiveInject` |
| **Solid.js** | `createSignal`, `createEffect`, `onCleanup`, `untrack` |
| **Qwik** | `qrl(`, `inlinedQrl`, `__qwik_reg_symbols` |

---

### 3. Obfuscation techniques & detection

#### 3a. Common techniques

| Technique | What it does | Detection |
|-----------|-------------|-----------|
| Identifier renaming | `a,b,c` or `_0x12ab` | Short systematic = minifier. Hex = obfuscator |
| String array + decoder | Literals replaced with `_0x1234(idx)` lookups | `var _0x[a-f0-9]+=\[` + decoder function |
| String array rotation | Push/shift shuffles array at init | IIFE + `while(true)` + `push(shift())` + comparison value |
| Control-flow flattening | `while(true){switch(state){...}}` state machine | `while\s*\(true\)\s*\{.*switch` |
| Opaque predicates | Always-true/false conditions hiding real flow | Constant branches with complex expressions |
| Eval/Function packing | Source encoded then `eval()`'d | `eval(`, `Function("...")`, base64/hex literals |
| Property mangling | `obj.x` → `obj['encoded']` via computed access | Bracket notation on string literals |
| Virtualization/bytecode | Rare; commercial obfuscators | Custom interpreter loop + bytecode array |

#### 3b. Encoding obfuscators (entire source rewritten)

| Encoder | Character set | Detection regex | Difficulty |
|---------|--------------|----------------|------------|
| **JSFuck** | `[]()!+` only | `^[\[\]\(\)!+\s]{200,}$` | Easy-medium |
| **aaencode** | Japanese emoticons | `ﾟΘﾟ\|ﾟωﾟ\|ﾟДﾟ` | Medium |
| **jjencode** | `$` + digit building | `\$=~\[\];\$=\{` | Medium |
| **Dean Edwards** | eval wrapper | `eval\(function\(p,a,c,k,e,d\)` | Easy |

#### 3c. Commercial obfuscators

| Tool | Detection approach |
|------|-------------------|
| **JScrambler** | Polymorphic — no single fingerprint. Detect via: heavy control-flow + literal encryption, environment checks, anti-tamper integrity blobs, runtime attestation. Hard |
| **Bytenode** | `.jsc` binary (not JS text). Detect loader: `require('bytenode')`, `loadBytecode`. Hard |
| **PrePack** | Partially folded constants, flattened sequences. No unique pattern. Rare |

#### 3d. javascript-obfuscator signatures

**Self-defending** (ReDoS probe detecting prettify/tampering):
`\(\(\(\.\+\)\+\)\+\)\+\)\$` — `.toString().search('(((.+)+)+)+$')`

**Debug protection** (split debugger keyword):
`constructor('debu'+'gger').call('action')` — detect: `debu['"]?\s*\+\s*['"]?gger`

**Domain lock** (charCode probes + suffix matching):
detect: `isNameVariant`, `documentLocationHostName`, `domainLockRedirectUrl`

---

### 4. Anti-analysis patterns

| Category | Techniques | Detection |
|----------|-----------|-----------|
| **Debugger traps** | `debugger` in loops/setInterval, `Function('debugger')()`, split `'debu'+'gger'` | `\bdebugger\b`, `constructor\(.*debu.*gger` |
| **Timing detection** | `performance.now()`/`Date.now()` deltas, `SharedArrayBuffer`+`Atomics.wait` spin | `performance\.now\|Date\.now` in loops |
| **DevTools detection** | `outerWidth-innerWidth` dimension check, `console.log` getter traps | `outerWidth\s*-\s*innerWidth` |
| **Anti-tampering** | `Function.prototype.toString` + hash, `script.textContent` checksums | Crypto literals + slice/compare on source |
| **Domain locking** | `location.hostname`/`document.domain` whitelist + redirect | `location\.hostname\|document\.domain` + array comparison |
| **Environment probes** | `navigator.webdriver`, `plugins.length===0`, `callPhantom`, `__nightmare`, WebGL renderer | `navigator\.(webdriver\|plugins)`, `callPhantom` |
| **Proxy/trap** | `new Proxy(target, {get:decode})` intercepts all access | `new Proxy\(` with handler traps |
| **Tagged template** | `_0xTag\`encoded\`` decoder on quasi-literals | Random-tag on high-entropy templates |
| **Symbol-based** | `obj[Symbol.for('x')]` — invisible to enumeration | `Symbol\(` in computed property access |
| **WeakRef timing** | GC-based analysis environment detection | `new WeakRef\(\|new FinalizationRegistry\(` + timing |

---

### 5. Regex detection bank

Single consolidated bank. Use with ripgrep or substring search.

```regex
// SOURCE MAP
//# sourceMappingURL=.*

// BUNDLERS — check most specific first
__turbopack_require__|__turbopack_context__|__turbopack_load__|__turbopack_dynamic__
__rspack_missing_module|\.rv\b|\.ruid\b
__webpack_require__|webpackJsonp|__webpack_modules__|__webpack_exports__
\{?\s*\d+\s*:\s*function\s*\(|__webpack_modules__\s*=\s*\{
__webpack_modules__|container|remoteEntry
\b__d\(function|\b__r\(|\b__registerSegment\b
function\s*\(\s*require\s*,\s*module\s*,\s*exports\s*\)|parcelRequire
typeof\s+exports\s*===\s*['"]object['"].*typeof\s+define\s*===\s*['"]function['"]
System\.register\(|System\.import\(
\$jscomp\$|\$jscomp\.

// BUNDLER FEATURES
module\.hot\.accept|import\.meta\.hot
\/\*#__PURE__\*\/|"sideEffects"
import\(\s*['"][^'"]+['"]\s*\)|require\.ensure\(
import\.meta\.glob\(
new\s+URL\([^,]+,\s*import\.meta\.url\)

// OBFUSCATION
var\s+_0x[a-f0-9]+\s*=\s*\[(['"][^'"]+['"],?)+\]
stringArray\['push'\]\(stringArray\['shift'\]\(\)\)
while\s*\(true\)\s*\{.*switch\s*\(
eval\(function\(p,a,c,k,e,d\)
^[\[\]\(\)!+\s]{200,}$
\$=~\[\];\$=\{
ﾟΘﾟ|ﾟωﾟ|ﾟДﾟ
\(\(\(\.\+\)\+\)\+\)\+\)\$
constructor\(\s*['"]debu['"]\s*\+\s*['"]gger['"]
isNameVariant|documentLocationHostName|domainLockRedirectUrl

// ANTI-ANALYSIS
\bdebugger\b
performance\.now\(\)|Date\.now\(\)
outerWidth\s*-\s*innerWidth|outerHeight\s*-\s*innerHeight
navigator\.webdriver|__nightmare|callPhantom|domAutomation
new\s+Proxy\(

// WASM
\bwasmBinary\b|HEAP(?:8|16|32|U8|F32|F64)\b|ENVIRONMENT_IS_
__wbindgen_|__wbg_|wasm_bindgen
WebAssembly\.instantiate(?:Streaming)?|WebAssembly\.compile(?:Streaming)?

// PLATFORM
require\(['"]electron['"]\)|ipcRenderer|ipcMain|contextBridge
__TAURI__|__TAURI_INTERNALS__
Capacitor\.Plugins|cordova\.exec
self\.addEventListener\(['"]fetch['"]\)|skipWaiting|clients\.claim|workbox
chrome\.runtime|chrome\.storage|browser\.runtime
==UserScript==|GM_xmlhttpRequest|GM_setValue|unsafeWindow
require\(['"]bytenode['"]\)|loadBytecode

// FRAMEWORK COMPILER OUTPUT
_classCallCheck|_createClass|_inherits|_asyncToGenerator
\)\(\w+\s*\|\|\s*\(\w+\s*=\s*\{\}\)\)
\$\$invalidate
\$\.(effect|template_effect|derived)
__vue_component__|_sfc_main|_openBlock|_createElementBlock
ɵɵdefineComponent|ɵɵelementStart|ɵɵdirectiveInject
\bqrl\s*\(|inlinedQrl|__qwik_reg_symbols
\bcreateSignal\b|\bcreateEffect\b|\bonCleanup\b
```

---

### 6. Reverse-engineering workflow

**A. Static (non-executing, safest)**

**Step 0 — source map check (do this before anything else)**

```bash
# 1. Detect: search the bundle for the trailing comment
rg 'sourceMappingURL' bundle.min.js

# 2a. Separate .map file → fetch it
curl -sS -o bundle.js.map "https://cdn.example.com/bundle.js.map"

# 2b. Inline map (data URL) → extract and decode
node -e "
  const fs = require('fs');
  const src = fs.readFileSync('bundle.min.js', 'utf8');
  const m = src.match(/sourceMappingURL=data:application\/json;base64,([A-Za-z0-9+/=]+)/);
  if (m) fs.writeFileSync('bundle.js.map', Buffer.from(m[1], 'base64').toString('utf8'));
"

# 3. Reconstruct original source files (needs sourcesContent in the map)
npm install -g shuji
shuji bundle.js.map -o ./reconstructed -p   # -p preserves path layout

# 4. Quick audit without full reconstruction: check what sources exist
jq '.sources, (.sourcesContent | length)' bundle.js.map

# 5. Attribution map (tree of which bundle bytes came from which source)
npm install -g source-map-explorer
source-map-explorer bundle.min.js --json | jq '.files | keys'
```

**Source map scenarios:**
- `sourcesContent` present → `shuji` reconstructs full files → treat as source code.
- `nosources-*` build (webpack `devtool: nosource-source-map`) → positions map but no text → only reveals file paths.
- 404 on CDN → check alternate hosts, error-tracker endpoints, older deploy paths, sibling `.map` files.
- No `sourceMappingURL` → proceed with static analysis below.

**Steps 1–5 (when no source map)**
1. Find module table (webpack/browserify/parcel) → split into individual modules
2. Prettify per module (`js-beautify`, `prettier`)
3. Parse AST (acorn/espree/babel) → build dep graph from `require`/`import`/`__webpack_require__`
4. Flag business modules: large bodies, many locals/strings, network/DOM/crypto usage

**B. Deobfuscation (when obfuscation detected)**

Pick the right tool for the obfuscation type — running the wrong tool wastes time and can silently corrupt semantics.

| Obfuscation type / input | Best tool | Install | Key command |
|--------------------------|-----------|---------|-------------|
| **Webpack/browserify bundle** + any obfuscation | **webcrack** | `npm i -g webcrack` (Node 22/24) | `webcrack bundle.js -o out/` |
| **javascript-obfuscator** / obfuscator.io output (string array rotation, CFF, self-defending) | **synchrony** | `npm i -g deobfuscator` (GPL-3.0) | `synchrony deobfuscate file.js` → `file.cleaned.js` |
| **obfuscator.io** specifically | **obfuscator-io-deobfuscator** | `npm i -g obfuscator-io-deobfuscator` | `obfuscator-io-deobfuscator -o out.js`; or use https://obf-io.deobfuscate.io |
| Generic: string arrays, proxy wrappers, dead branches, constant folding | **js-deobfuscator** | `npm i -g js-deobfuscator` | `js-deobfuscator -i in.js -o out.js`; or use https://deobfuscate.io |

**webcrack flags** (most useful for investigation):

```bash
webcrack input.js                     # auto-detect: unpack + deobfuscate + unminify
webcrack bundle.js -o output/          # extract modules to directory
webcrack bundle.js --no-unpack         # deobfuscate only (single-file malware)
webcrack bundle.js --no-deobfuscate    # unminify only (test if deobfuscation broke semantics)
webcrack bundle.js > deobfuscated.js   # stdout mode
curl https://cdn.example.com/evil.js | webcrack   # stdin
```

**Workflow:**
1. Preserve original → `sha256sum bundle.js > bundle.sha256`
2. Check for bundler markers (§2b) → if webpack/browserify → `webcrack -o out/` first
3. Check for obfuscator markers (§3) → pick tool from table above
4. Run: redirect stderr to file (`2>tool.log`); Synchrony maintainers ask for full terminal output when filing issues
5. Verify: re-run `rg 'eval\|fetch\|XMLHttpRequest\|child_process' out/` on result
6. If semantics look broken: isolate stages with `--no-deobfuscate` or `--no-unpack`
7. **Partial result** is valid evidence: record what decoded + what remained opaque

**Pitfalls:**
- webcrack requires **Node 22 or 24** — version mismatch causes silent failures
- synchrony is **version-locked** to specific `javascript-obfuscator` output versions; older samples may need `npm i -g deobfuscator@<older>` 
- `node:vm` is **not a sandbox** — never use it as a security boundary for untrusted code
- Deobfuscated output that still contains `eval()` is **not resolved** — treat as needing dynamic phase

**C. Dynamic (when static stalls)**

Use when: strings/logic hidden behind runtime packing, env-dependent branching, `eval` decoding remote config, or WebSocket/SW-mediated channels. See **§13** for full toolkit.

**Minimum viable setup:**
```js
// Inject before bundle loads (Puppeteer page.evaluateOnNewDocument / Playwright addInitScript):

// 1. Intercept eval
const origEval = window.eval;
window.eval = function(code) {
  console.log('[eval]', String(code).slice(0, 3000));
  return origEval.apply(this, arguments);
};
// Also patch new Function (many loaders use this instead of eval)
const origFunction = Function;
Function = new Proxy(origFunction, {
  construct(target, args) {
    console.log('[Function]', args.slice(-1)[0]?.slice(0, 2000));
    return new target(...args);
  }
});

// 2. Log fetch
const origFetch = window.fetch;
window.fetch = function(...args) {
  console.log('[fetch]', args[0], args[1]?.method ?? 'GET');
  return origFetch.apply(this, args);
};

// 3. Log __webpack_require__ module IDs (after runtime loads)
const hookedWR = window.__webpack_require__;
if (hookedWR) {
  Object.assign(window.__webpack_require__, hookedWR); // preserve properties
}
```

Capture with **CDP `Fetch`** for network-level intercept (bypasses in-page patching):
```js
const client = await page.target().createCDPSession();
await client.send('Fetch.enable', { patterns: [{ requestStage: 'Response' }] });
client.on('Fetch.requestPaused', async ({ requestId, request }) => {
  console.log('[network]', request.method, request.url);
  await client.send('Fetch.continueRequest', { requestId });
});
```

Capture `eval`-produced scripts (anonymous scripts show as `debugger://VM...`):
```js
await page.coverage.startJSCoverage({ reportAnonymousScripts: true });
```

---

### 7. Business logic heuristics

Rank modules by these signals (highest first):
- **Size** >100KB
- **String density** — unique literals: messages, URLs, selectors
- **API usage** — fetch, axios, XMLHttpRequest, ws, localStorage, DOM listeners
- **Crypto/encoding** — encrypt, decrypt, sha, aes, nonce
- **Network endpoints** — literal URLs or paths
- **Entry points** — early-required modules, top-level exports

Per module: compute size + unique strings + network/DOM/export counts + functions > N lines → sort → inspect top N.

---

### 8. Module resolution patterns

| Pattern | Example |
|---------|---------|
| Static CJS | `require('...')` |
| Static ESM | `import ... from '...'` |
| Webpack modules | `__webpack_require__(id)`, numeric IDs in object/array |
| Dynamic/chunked | `require.ensure(...)`, `import('...')` |
| Module boundaries | `module.exports`, `exports.*` |
| Obfuscated requires | `require(_0x1a2(0x12))` — decode string table first |

When you find a module table, extract each function value and treat as separate files.

---

### 9. Deobfuscation transforms

**Tool matrix** (see §6.B for install commands and full workflow):

| Tool | npm / install | What it handles | Technique coverage |
|------|--------------|------------------|--------------------|
| **webcrack** | `npm i -g webcrack` (Node 22+) | Bundle unpack + deobfuscate + unminify | String arrays, CFF, dead code, webpack/browserify module extraction |
| **synchrony** | `npm i -g deobfuscator` (GPL-3.0) | javascript-obfuscator output | String array rotation, CFF, proxy indirection, simplify |
| **js-deobfuscator** | `npm i -g js-deobfuscator` | Generic obfuscation | Array unpack, proxy inlining, dead branches, constant folding, string decode |
| **obfuscator-io-deobfuscator** | `npm i -g obfuscator-io-deobfuscator` | obfuscator.io specifically | Rotation, RC4-style decoders, CFF recovery |

**Unminify transforms (webcrack):** `for`→`while` | split merged var decls | merge string concat (`'a'+'b'`→`'ab'`) | logical→if (`a&&fn()`→`if(a)fn()`) | ternary→if | computed→dot notation | Yoda reversal | `void 0`→`undefined` | `JSON.parse('...')`→object literal

**Deobfuscate transforms (js-deobfuscator / synchrony):** array unpacker (string array→values) | proxy function inlining | dead branch removal | expression simplifier (constant folding) | string decoder | `obj['key']`→`obj.key` | variable renaming from context

**Chain for maximum coverage:** `webcrack --no-unpack` (deobfuscate+unminify) → `js-deobfuscator` (clean up residuals) → re-run `rg` on result → if still opaque → §6.C dynamic phase.

---

### 10. Detection confidence

| Level | Meaning | Example |
|-------|---------|---------|
| **High** | Unique runtime global | `__turbopack_context__`, `ɵɵdefineComponent`, `__wbindgen_throw` |
| **Medium** | Shared pattern + secondary signal | `__webpack_require__` + `rv` (Rspack vs webpack) |
| **Low** | Generic, needs context | `WebAssembly.instantiate`, `eval(` |
| **Negative** | Absence of expected patterns | No bundler runtime + `$jscomp$` → Closure ADVANCED |

When signals conflict: prefer most specific. `__webpack_require__` + `__rspack_missing_module` → Rspack. `__d(function` + `__r(` → Metro.

---

### 11. Checklist (every large JS file)

1. **Source map** → `rg 'sourceMappingURL'` → fetch/decode → `shuji file.js.map -o out/` → treat as source. If 404, note and continue.
2. **Non-JS binary?** `.jsc`/`.hbc`/`.wasm` → stop here → use [Binary Workflow](./binary-local-file-workflow.md). `.hbc` → §6 of that doc (Hermes).
3. **Encoding obfuscation?** JSFuck/aaencode/jjencode → decode first before any AST tools.
4. **Platform?** Electron/Tauri/Capacitor/RN/SW/Worker/Extension → sets API context.
5. **Bundler?** (most specific first) Turbopack → Rspack → webpack → Metro → Parcel → Rollup/esbuild → Closure.
6. **WASM glue?** Emscripten/wasm-bindgen/generic.
7. **Framework output?** Angular/Svelte/Vue/Qwik/Solid/Babel.
8. **Anti-analysis?** debugger traps, self-defending, domain lock, env probes → handle before deep analysis.
9. **Split modules** → `webcrack bundle.js -o out/` (if bundled) → prettify → parse AST → dep graph.
10. **Detect obfuscation** → pick tool from §9 matrix → `webcrack`/`synchrony`/`js-deobfuscator` → re-run `rg` to verify.
11. **Score modules** (size, strings, network/DOM/crypto) → surface top N.
12. **Static stalls?** → §13 dynamic analysis toolkit. Puppet/Playwright with early injection + CDP Fetch.

---

### 12. Safety

- **`node:vm` is an unsandboxed execution environment.** The Node.js docs confirm it: prototype-chain and native-binding escapes are well-documented. Use hardware-isolated VMs or containerized sandboxes for untrusted code execution.
- Never `eval`/`require` untrusted code on host. Use hardware-isolated VMs, disposable containers, or a containerized headless browser with egress firewall.
- Obfuscated code decoding + fetching remote payloads may be malicious — treat all decoded URLs/commands as live threats, not just pattern matches.
- Record all extracted artifacts with `sha256sum` before and after deobfuscation for evidence integrity.
- For Frida hooks on Electron/Node: process isolation and code signing may block `Interceptor.attach()` — see §13.

---

### 13. Dynamic Analysis Toolkit

Use after static methods stall. Required when: strings/logic hidden behind runtime packing, env-conditional branching, `eval` decoding remote config, or WebSocket/SW-mediated channels.

**Decision: static vs dynamic**

| Prefer static | Prefer dynamic |
|---------------|----------------|
| Readable after deobfuscation | Packed `eval` / remote config |
| Need diffable, repeatable IR | Behavior depends on UA, timezone, env |
| Legal/policy limits on execution | Need to prove network C2 or DOM write |
| Offline strings + imports tell the story | SW/worker-mediated logic |

**Setup: Puppeteer / Playwright**

```bash
npm i puppeteer playwright
```

Key principle: inject hooks **before** the page code wins the race.

```js
// Puppeteer
await page.evaluateOnNewDocument(hookScript);
// Playwright
await page.addInitScript(hookScript);
```

**Hook library (copy into hookScript):**

```js
// --- eval + Function interception ---
const _eval = window.eval;
window.eval = function(code) {
  console.log('[eval] ' + String(code).slice(0, 3000));
  return _eval.apply(this, arguments);
};
const _F = Function;
Function = new Proxy(_F, {
  construct(T, args) {
    console.log('[new Function] ' + args.slice(-1)[0]?.slice(0, 2000));
    return new T(...args);
  }
});

// --- fetch interception ---
const _fetch = window.fetch;
window.fetch = function(...args) {
  console.log('[fetch] ' + (args[1]?.method ?? 'GET') + ' ' + args[0]);
  return _fetch.apply(this, args);
};

// --- XHR ---
const _open = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function(method, url) {
  console.log('[XHR] ' + method + ' ' + url);
  return _open.apply(this, arguments);
};
```

**CDP-level network intercept** (cannot be bypassed by in-page overwrites):

```js
const client = await page.target().createCDPSession();
await client.send('Fetch.enable', { patterns: [{ requestStage: 'Response' }] });
client.on('Fetch.requestPaused', async ({ requestId, request }) => {
  console.log('[cdp-fetch] ' + request.method + ' ' + request.url);
  await client.send('Fetch.continueRequest', { requestId });
});
```

**Capture anonymous `eval` scripts:**

```js
await page.coverage.startJSCoverage({ reportAnonymousScripts: true });
// ... run page ...
const coverage = await page.coverage.stopJSCoverage();
// anonymous scripts appear as debugger://VM... URLs
```

**Bridge decoded strings from page → Node:**

```js
await page.exposeFunction('captureDecoded', (s) => console.log('[decoded] ' + s));
// Then in the hook, call: window.captureDecoded(decodedString);
// CDP equivalent: Runtime.addBinding + bindingCalled event
```

**Frida (Node.js / Electron — native boundaries)**

For native hooks (SSL pinning bypass, syscall tracing, `.node` addon interception):

```bash
npm i -g frida-compile   # or use frida-tools (pip install frida-tools)
frida -n Electron --runtime=v8 -l hook.js
```

Typical hook (intercept TLS for plaintext before encryption):
```js
// hook.js — runs in Frida JS runtime
Interceptor.attach(Module.getExportByName('libssl.3.dylib', 'SSL_write'), {
  onEnter(args) { console.log('[ssl_write] ' + args[1].readUtf8String(args[2].toInt32())); }
});
```

**Anti-analysis bypass checklist for dynamic sessions:**

| Evasion | Bypass |
|---------|--------|
| `navigator.webdriver === true` | `Object.defineProperty(navigator,'webdriver',{get:()=>undefined})` in initScript |
| Headless viewport fingerprint | Set realistic viewport + UA in launch options |
| Timing detection (`performance.now()`) | Use CDP `Emulation.setVirtualTimePolicy` to control clock |
| Debugger traps | Remove `debugger` statements after static deobfuscation pass |
| Service Worker intercept | `await page.setBypassCSP(true)` + CDP `ServiceWorker.enable` to inspect SW registration |
| Domain lock | Route target domain to localhost via hosts-file override or proxy |

**When dynamic reveals new IOCs:** pivot back to static — re-run `rg` with the decoded URL/command on the full codebase to find other callsites.
