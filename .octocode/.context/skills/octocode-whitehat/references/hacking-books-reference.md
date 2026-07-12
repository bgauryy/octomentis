# Hacking & JS Security Resources Reference

Methodology, tools, and payload databases for security analysis, bug bounty, reverse engineering, and supply chain auditing across any codebase.

Pair with [Guardrail Bypass Resources](./guardrail-bypass-resources.md) for AI/LLM security, [Advanced Threat Patterns](./advanced-threat-patterns.md) for detection regex/AST signatures, and [Security Investigation Reference](./security-investigation-reference.md) for search packs.

---

## Bug Bounty Methodology

Use when starting a security engagement, building recon checklists, or hunting specific vuln classes.

| Resource | When to use | Key JS techniques |
|----------|-------------|-------------------|
| [nahamsec/Resources-for-Beginner-Bug-Bounty-Hunters](https://github.com/nahamsec/Resources-for-Beginner-Bug-Bounty-Hunters) | Core recon methodology, JS file enumeration | JS file discovery, DevTools XHR interception, source map exploitation, hidden endpoint discovery via bundle analysis |
| [KathanP19/HowToHunt](https://github.com/KathanP19/HowToHunt) | Per-vulnerability hunting checklists | JWT hunting in client code, API key exposure patterns, IDOR through JS business logic |
| [daffainfo/AllAboutBugBounty](https://github.com/daffainfo/AllAboutBugBounty) | Real-world XSS, IDOR, auth bypass, API key exposure | XSS sink/source enumeration, client-side auth bypass patterns, GraphQL schema discovery via JS |
| [EdOverflow/bugbounty-cheatsheet](https://github.com/EdOverflow/bugbounty-cheatsheet) | Quick payload reference during testing | XSS, SSRF, open redirect payloads |
| [jhaddix/tbhm](https://github.com/jhaddix/tbhm) | Full recon-to-exploit methodology (The Bug Hunter's Methodology) | JS analysis as part of comprehensive recon workflow |

---

## Web Security & XSS

Use when hunting DOM-based vulnerabilities, testing WAF bypasses, or analyzing browser-side attack surfaces.

| Resource | When to use | Key techniques |
|----------|-------------|---------------|
| [OWASP Web Security Testing Guide](https://github.com/OWASP/www-project-web-security-testing-guide) | Gold-standard web/JS security testing methodology | DOM XSS sink/source enumeration, CSP bypass, `eval`/`innerHTML`/`document.write` injection, client-side template injection, SRI bypass, testing obfuscated client code |
| [s0md3v/AwesomeXSS](https://github.com/s0md3v/AwesomeXSS) | Deep XSS research, WAF evasion, obfuscated payload analysis | JSFuck/aaencode obfuscation, unicode normalization bypass, template literal exploitation, mutation XSS (mXSS), DOM clobbering, CSP bypass via JSONP/angular gadgets, `String.fromCharCode` / `eval(atob(...))` patterns |
| [qazbnm456/awesome-web-security](https://github.com/qazbnm456/awesome-web-security) | Broad web security with JS/browser exploitation focus | Prototype pollution chains, V8/SpiderMonkey engine vulns, browser extension security, WebAssembly as obfuscation vector, sandbox escapes, npm hijacking |

---

## Reverse Engineering & Deobfuscation

### Understanding Obfuscation

| Resource | When to use | What you get |
|----------|-------------|-------------|
| [wtsxDev/reverse-engineering](https://github.com/wtsxDev/reverse-engineering) | RE tools and techniques for packed/obfuscated JS | AST-based deobfuscation (Babel), Chrome DevTools Protocol dynamic analysis, UglifyJS/Webpack/Rollup unpackers, `eval()` hook injection, memory snapshot analysis |
| [javascript-obfuscator/javascript-obfuscator](https://github.com/javascript-obfuscator/javascript-obfuscator) | Know your enemy — most widely deployed JS obfuscator | Detection: `/_0x[a-f0-9]{4,6}/` vars, large string arrays, `parseInt` + XOR keys, `atob`/`charCodeAt` combos, `rotateStringArray` patterns |

### Deobfuscation Toolkit

Work top-to-bottom — try `webcrack` first, fall back to specialized tools.

| Tool | When to use |
|------|-------------|
| [j4k0xb/webcrack](https://github.com/j4k0xb/webcrack) | **Try first.** Handles obfuscator.io, webpack/browserify unpacking, and unminification in one pass. AST-based, actively maintained |
| [lelinhtinh/de4js](https://github.com/lelinhtinh/de4js) | Quick browser-based deobfuscation when CLI unavailable. Multiple packer formats, offline web UI |
| [relative/synchrony](https://github.com/relative/synchrony) | Specifically reversing `javascript-obfuscator` output — control-flow flattening, string rotation, dead code |
| [ben-sb/javascript-deobfuscator](https://github.com/ben-sb/javascript-deobfuscator) | General fallback when `webcrack` doesn't fully resolve non-standard obfuscation |
| [kuizuo/js-deobfuscator](https://github.com/kuizuo/js-deobfuscator) | Babel AST deobfuscation with online playground + CLI + API |
| [ben-sb/obfuscator-io-deobfuscator](https://github.com/ben-sb/obfuscator-io-deobfuscator) | Confirmed obfuscator.io target — more targeted than general tools |
| [HumanSecurity/restringer](https://github.com/HumanSecurity/restringer) | Malware-grade obfuscation that resists simpler tools (production-grade from Human Security) |
| [vicnaum/bun-demincer](https://github.com/vicnaum/bun-demincer) | Decompiling Bun-compiled standalone JS binaries |

---

## Malware & Threat Intelligence

Use when analyzing suspicious JS samples, building detection signatures, or studying exfiltration patterns.

| Resource | When to use | Key JS patterns |
|----------|-------------|----------------|
| [ytisf/theZoo](https://github.com/ytisf/theZoo) | Live malware samples for signature extraction and behavioral analysis | JS dropper patterns (XHR + eval, blob URL exec), browser exploit kit structure, steganographic payload delivery, Magecart-style skimmers, `navigator.sendBeacon`/`Image()` exfiltration |

---

## Supply Chain & npm Security

Use when auditing packages, investigating suspected supply chain compromises, or hardening npm workflows.

| Tool | When to use | What you get |
|------|-------------|-------------|
| [socketdev/socket-cli-js](https://github.com/socketdev/socket-cli-js) | Detecting malicious npm packages | `postinstall`/`preinstall` hook analysis, typosquatting detection, network egress in install scripts, `child_process.exec`/`eval` in package scripts, dependency confusion patterns |
| [lirantal/is-website-vulnerable](https://github.com/lirantal/is-website-vulnerable) | Detecting vulnerable JS libraries on live websites | CDN fingerprinting, npm advisory database correlation |
| [bodadotsh/npm-security-best-practices](https://github.com/bodadotsh/npm-security-best-practices) | Defensive npm hygiene before publishing or auditing lockfiles | Lockfile pinning, lifecycle script risks, `.npmrc` hardening, registry scoping, audit workflows |

---

## OWASP Top 10 in JavaScript

Quick reference for how standard vulnerability classes manifest in JS code.

| OWASP Category | JS Manifestation | Detection Approach |
|---|---|---|
| A01: Broken Access Control | Client-side auth checks, hidden admin routes in bundles | Grep `role`, `isAdmin`, `hasPermission` |
| A02: Cryptographic Failures | Hardcoded keys, weak crypto, secrets in bundles | Secret pattern library, crypto API analysis |
| A03: Injection | XSS sinks, eval injection, template injection | DOM sink analysis, eval pattern detection |
| A05: Security Misconfiguration | Source maps in production, debug endpoints | Source map presence check, debug route enumeration |
| A06: Vulnerable Components | Outdated JS libraries with known CVEs | Retire.js patterns, version fingerprinting |
| A08: Software Integrity Failures | Supply chain attacks, malicious npm packages | Lifecycle script analysis, behavior scanning |
| A09: Logging Failures | Silent error swallowing in malware | Empty catch block detection |

---

## Vulnerability Research

| Resource | When to use | What you get |
|----------|-------------|-------------|
| [Kirill89/prototype-pollution-explained](https://github.com/Kirill89/prototype-pollution-explained) | Before hunting prototype pollution in Node.js/Express/lodash | `__proto__` and `constructor.prototype` overwrite walkthrough, exploitation paths, gadget chains |

---

## Vulnerable-by-Design Labs

Use for practicing exploitation in safe environments or validating scanner accuracy.

| Lab | When to use | What you get |
|-----|-------------|-------------|
| [sethsec/Nodejs-SSRF-App](https://github.com/sethsec/Nodejs-SSRF-App) | Practicing SSRF exploitation in Node.js | Internal service access, cloud metadata theft, port scanning via server |
| [owtf/owtf](https://github.com/owtf/owtf) | Full OWASP methodology automated web pentests | Combines multiple pentest tools under one workflow, covers OWASP Testing Guide categories |

---

## Pentest Scanners

Use for active testing against authorized targets or validating static analysis findings.

| Tool | When to use | What you get |
|------|-------------|-------------|
| [Arachni/arachni](https://github.com/Arachni/arachni) | JS-heavy web apps — injection, XSS, DOM-based vulns | Web scanner with DOM analysis and JS execution context, modular custom checks |
| [DontPanicO/jwtXploiter](https://github.com/DontPanicO/jwtXploiter) | Node.js APIs using JWT auth | `alg:none`, key confusion, JKU/X5U injection, weak secret cracking, algorithm switching |

---

## Curated Security Lists

Use when starting a new audit, onboarding onto a target ecosystem, or building a toolchain.

| List | When to use |
|------|-------------|
| [lirantal/awesome-nodejs-security](https://github.com/lirantal/awesome-nodejs-security) | First stop for any Node.js security task — OWASP coverage, pentest tools, vulnerability databases, defensive patterns |
| [vavkamil/awesome-bugbounty-tools](https://github.com/vavkamil/awesome-bugbounty-tools) | Before a bug bounty engagement — scanners, fuzzers, recon tools, exploitation aids per target type |
| [Hack-with-Github/Awesome-Hacking](https://github.com/Hack-with-Github/Awesome-Hacking) | Gateway to specialized security toolsets — bug bounty, RE, fuzzing, pentesting |
| [A-poc/RedTeam-Tools](https://github.com/A-poc/RedTeam-Tools) | Red team tools by attack phase — recon → initial access → persistence → privilege escalation |
