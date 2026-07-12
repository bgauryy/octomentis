# Security Investigation Reference

Use this reference when the target is suspicious, newly installed, recently modified, or likely to hide risky behavior.

Pair with [Minification Guide](./minification-guide.md) for bundler classification, [Advanced Threat Patterns](./advanced-threat-patterns.md) for deep detection regex beyond these search packs, and [AST Reference](./ast-reference.md) for structural proof after triage.

**Depth relationship:** These search packs (Packs A–G) are for fast triage. For deep detection signatures on the same categories, escalate to [Advanced Threat Patterns](./advanced-threat-patterns.md).

---

## 1. Search-First Packs

Start with the smallest pack that matches your suspicion. Expand only after the first round of evidence.

### Pack A - Runtime / Bootstrap / Install

Use when you still do not know how the target starts or loads.

Patterns:

- `preinstall|install|postinstall|prepare`
- `__webpack_require__|__turbopack_require__|parcelRequire|System\\.register|__d\\(|__r\\(`
- `remoteEntry|container|import\\(|require\\.ensure`
- `new Worker|importScripts|serviceWorker|chrome\\.runtime|browser\\.runtime`
- `ipcRenderer|ipcMain|contextBridge|process\\.versions\\.electron`

Questions:

- what runs first?
- is this runtime code or custom logic?
- is there install-time execution separate from import-time execution?

### Pack B - Dynamic Execution / Loading

Use when the code may execute hidden payloads or load code indirectly.

Patterns:

- `\\beval\\s*\\(`
- `new\\s+Function\\s*\\(`
- `vm\\.runIn(Context|NewContext)|new\\s+vm\\.Script`
- `require\\s*\\(` and `import\\s*\\(`
- `setTimeout\\s*\\(\\s*['"]|setInterval\\s*\\(\\s*['"]`
- `Buffer\\.from\\([^\\n]{0,200}base64|atob\\(|String\\.fromCharCode`

Questions:

- what controls the executed string or module path?
- is a decoder or loader feeding the sink?
- can input, env, network, or files reach the executed payload?

### Pack C - Network / Listeners / Pivoting

Use when you need to understand egress, telemetry, C2-like behavior, or local backdoors.

Patterns:

- `fetch\\(`
- `axios|XMLHttpRequest`
- `http\\.request|https\\.request`
- `new\\s+WebSocket`
- `dns\\.(lookup|resolve)`
- `net\\.(connect|createConnection|createServer)`
- `server\\.listen\\(|listen\\(`
- `169\\.254\\.169\\.254|localhost|127\\.0\\.0\\.1|0\\.0\\.0\\.0`

Questions:

- what destination is contacted?
- what data is sent?
- are localhost, metadata, or RFC1918 targets involved?
- is the target opening a port unexpectedly?

### Pack D - File System / Weird Paths / Persistence

Use when the code might read sensitive files, modify startup locations, or escape its working area.

Patterns:

- `fs\\.(readFile|readFileSync|writeFile|writeFileSync|appendFile|appendFileSync|unlink|rm|rmdir|mkdir)`
- `path\\.join|path\\.resolve`
- `\\.ssh|id_rsa|\\.npmrc|\\.env|/etc/|/proc/|/var/run/`
- `LaunchAgents|systemctl|crontab|AppData|Startup|reg add`
- `os\\.homedir\\(|os\\.tmpdir\\(|process\\.cwd\\(|process\\.chdir\\(`
- `\\.bashrc|\\.zshrc|\\.profile|\\.config`

Questions:

- does the path leave the module/project scope?
- is the write creating persistence or modifying startup behavior?
- are sensitive files being collected or rewritten?

### Pack E - Secrets / Auth / Session / Crypto

Use when the target touches login state, tokens, cookies, or encrypted payloads.

Patterns:

- `Authorization|Bearer|token|jwt|refresh|session|cookie`
- `localStorage|sessionStorage|document\\.cookie`
- `process\\.env`
- `crypto\\.(createCipher|createCipheriv|createDecipher|createDecipheriv|createHash|createHmac)`
- `encrypt|decrypt|nonce|iv|aes|rsa|sha`
- `apiKey|secret|password`

Questions:

- what secret is accessed?
- is data stored, decrypted, logged, or transmitted?
- is crypto protecting data or hiding behavior?

### Pack F - Obfuscation / Anti-Analysis / Hidden Intent

Use when the code looks intentionally hard to inspect.

Patterns:

- `var\\s+_0x[a-f0-9]+\\s*=\\s*\\[`
- `while\\s*\\(true\\)\\s*\\{.*switch`
- `eval\\(function\\(p,a,c,k,e,d\\)`
- `\\x[0-9a-f]{2}|\\u[0-9a-f]{4}`
- `debugger|debu['"]?\\s*\\+\\s*['"]?gger`
- `performance\\.now\\(|Date\\.now\\(`
- `navigator\\.webdriver|callPhantom|__nightmare`
- `location\\.hostname|document\\.domain`

Questions:

- is this normal minified output or deliberate concealment?
- is the decoder feeding a sink?
- are there anti-tamper or environment checks hiding behavior?

### Pack G - High-Impact Outcome Hints

Use when you need to judge whether the code could support meaningful abuse.

Patterns:

- `child_process|exec\\(|execSync\\(|spawn\\(|spawnSync\\(|execFile\\(`
- `sudo |chmod 777|chown |powershell -enc|bash -c|osascript`
- `cookies|session|Authorization|seed phrase|wallet`
- `ignore previous|system prompt|developer mode|jailbreak`
- `verify account|reset password|login`

Questions:

- could this support OS takeover?
- could it steal account/session material?
- could it generate or forward phishing content?
- could it propagate prompt injection or unsafe AI instructions?

---

## 2. Change-First Triage

Before full scanning, prioritize:

1. newly added files
2. recently modified files
3. install/runtime scripts
4. new executable or script-like files
5. new bins and entry points
6. suspicious direct and transitive dependencies

High-signal anomalies:

- new network calls
- new `postinstall` / `preinstall`
- new obfuscated code outside `dist` / `build`
- new dynamic loading or command execution
- sudden dependency-count spikes
- new files touching startup paths, credentials, or local listeners

---

## 3. Threat Outcomes To Explicitly Consider

Do not claim these unless code flow evidence supports them:

- **OS takeover**: command execution, persistence, host profiling, privilege manipulation
- **Account takeover**: token/session theft, auth-header capture, credential reads, browser storage theft
- **Phishing delivery**: generation or transport of deceptive login/wallet/reset flows
- **Prompt-injection propagation**: unsafe system/developer prompt forwarding, jailbreak strings, instruction laundering
- **Internal pivoting**: localhost or metadata probing, unexpected listeners, internal service access
- **Stealth / concealment**: anti-analysis, decoders, delayed execution, hidden loaders

---

## 4. Version-Delta and Dependency Guidance

When the target is an upgraded module or changed script:

1. identify what is new first
2. compare entry points, install scripts, bins, and direct dependencies
3. spot-check suspicious transitive dependencies up to a practical depth
4. treat new suspicious transitive behavior as first-class evidence

For dependencies, prioritize:

- names that look off or unexpectedly similar to popular packages
- packages with install scripts
- packages with network + exec combinations
- packages with obfuscation outside normal distribution artifacts
- packages that recently appeared with executable helpers

---

## 5. External Vulnerability Intel

Use this only when external lookups are allowed and useful. Start with active exploitation, then package advisories, then general enrichment.

Priority order:

1. **CISA KEV**
   - [Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)
   - [JSON feed](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json)
2. **EPSS**
   - [FIRST EPSS API](https://api.first.org/data/v1/epss)
3. **OSV**
   - [OSV.dev](https://osv.dev/)
   - [OSV API docs](https://osv.dev/docs/)
4. **NVD**
   - [NVD search](https://nvd.nist.gov/vuln/search)
5. **GitHub Advisory Database**
   - [github/advisory-database](https://github.com/github/advisory-database)

Best use:

- verify whether a package/version is already known-bad
- then confirm exploitability in local code with real evidence

Do not replace local code proof with advisory metadata alone.

