# THINKING.md — Attacker Mindset & Cognitive Framework

> Deep reference for attacker psychology, investigation mental models, and cognitive traps. Examples use JS/TS; the reasoning patterns apply to any codebase.
> For obfuscation/deobfuscation reasoning, see [Minification Guide](./references/minification-guide.md).
> For bug bounty hunting techniques, see [Access Control Attacks](./references/access-control-attacks.md) and [Hacking Books Reference](./references/hacking-books-reference.md).

---

## 1. The Attacker's Mindset

### Hiding Intent, Not Code

Attackers think in terms of **hiding intent**. The best malicious code looks boring. It occupies cognitive real estate defenders naturally skip.

The attacker's strategy is **plausible deniability at every layer**:
- "Validates environment variables" = development utility (but exfiltrates them)
- A cron every 60s = health check (but collects data)
- A `postinstall` that writes a config = normal setup (but calls home)
- A string from charCodes = obfuscated license key (but it's a C2 URL)

Attackers design for the *median reviewer*, not the expert. They need to fool a rushed developer, an automated scanner, a classifier reading a description string.

### Structural Tells That Survive Obfuscation

1. **Asymmetric complexity** — "format validator" needs 400 lines of encoded strings? The complexity/purpose ratio is off.
2. **Network calls without declared deps** — `http.request()` inside a math utility is unexplainable.
3. **Timing-gated execution** — legitimate code doesn't check "am I being watched?"
4. **Dual-use string construction** — `['h','t','t','p','s'].join('')`. No production code needs to reconstruct `https` at runtime.
5. **Parameter harvesting** — accepts `{ ...args }`, uses two fields, forwards everything.
6. **Dead-looking code that isn't dead** — callbacks in variables, event handlers with opaque keys.
7. **Silent error swallowing** — `.catch(() => {})` everywhere. Malware cannot afford surfaced errors.

### Legitimate vs. Malicious Obfuscation

| Characteristic | Legitimate | Malicious |
|---|---|---|
| Network calls | Declared, limited scope | Undeclared, exfiltrating parameters |
| Data flows | Inputs → outputs bounded | Inputs forked to external endpoints |
| Timing logic | None or performance-based | Delayed, env-gated |
| Error handling | Errors surface to caller | All exceptions swallowed |
| Purpose coherence | Complexity matches stated purpose | Complexity far exceeds stated purpose |
| Upgrade trajectory | Regular releases, changelog | Sudden complexity spike in one version |

**Mental test**: Strip the obfuscation. If the revealed logic would be embarrassing or criminal to show publicly, it's malicious. If it's a trade secret, it's legitimate.

### How Attackers Use Legitimate-Looking Patterns

- **Schema social engineering**: Tool schemas are ground truth to automated systems. "Validates project environment variables" wins the first battle against any classifier.
- **Side-channel exfiltration**: Tool schema is clean, response is clean. The HTTP call happens between receiving parameters and returning. Structurally invisible.
- **Trusted format impersonation**: `.env`, `package.json` scripts, JSON configs — reviewers see data, not code.
- **Progressive trust**: Several benign interactions before payload fires. A "degraded status" response isn't the attack — it's the setup.

---

## 2. Investigation Mental Models

### The Hypothesis Stack

```
H1 (most likely): Legitimate code with confusing style
H2: Legitimate, privacy-relevant but legal (analytics, A/B)
H3: Over-engineered but benign
H4: Malicious, specific target (exfil, persistence, RCE)
H5: Malicious, broad targeting (supply chain worm)
```

Start at H1. Move down only when evidence forces it. Document the path from H1 to H4 — it must be paved with specific evidence, not general suspicion.

**Refutation protocol:**
- What would H1 look like here? (Complexity match stated purpose?)
- What would H4 require that H1 doesn't? (Network, timing, parameter harvesting?)
- Which evidence is *only* explainable by H4?

### Capability Bounding

Before tracing what code *does*, establish what it *cannot* do:
- No `require('http/https/net')`, no `fetch`, no `WebSocket` → cannot make network calls
- No `fs`, no `path` operations → cannot touch filesystem
- No `eval()`, `Function()`, `vm.runInContext()` → cannot execute dynamic code
- No `process.env`, `Deno.env` → cannot read secrets

**Caveat**: `require(atob('aHR0cHM='))` = `require('https')`. Always decode strings before claiming no capability.

**Maximum blast radius**: Before deep analysis, map worst case. "Read a config file" vs "send all `process.env` to a remote endpoint" — prioritize accordingly.

### The 5-Minute Triage Protocol

1. (30s) List all imports/requires — note capability-granting modules
2. (60s) Search for HIGH RISK patterns — count occurrences, note locations
3. (90s) For each hit: where does data come from? where does it go?
4. (60s) Check `postinstall`/`prepare`/`preinstall` in package.json
5. (30s) Verdict: escalate or low risk

### When to Trust Pattern Matching vs. Trace Flows

**Trust patterns when:** triaging at scale, context rules out false positives, known high-confidence indicator.

**Trace flows when:** context is ambiguous, multi-layer code, making a definitive attribution.

**Flow tracing protocol:**
1. Entry point (where untrusted/sensitive data enters)
2. Follow through every transformation
3. All exit points (network, file, exec, storage)
4. For each exit: attacker-controlled? sensitive data?

---

## 3. Advanced Detection Reasoning

### Negative Space Analysis

Absence of evidence is evidence — when you know what legitimate code always includes.

**A validator should have**: input validation with explicit errors, type checks, unit tests, meaningful return values.
**A network library should have**: declared network deps, documented endpoints, rate limits, error handling.

If these are absent but network calls + env reads are present → it's not what it claims to be.

**Absence heuristics:**
- No tests → the author didn't want testable behavior
- No error handling → deliberate suppression
- No logging → malware avoids traces
- No comments in complex code → obfuscated code never has comments; legitimate complex code does
- Description ≠ behavior → misrepresentation is a red flag

### The "What Would Legitimate Code Need?" Test

Declare the stated purpose. List what that purpose *legitimately requires*. List what the code *actually does*. The delta is your attack surface.

**Example:**
Purpose: "Validates env variable format"
Legitimate needs: read vars, apply format rules, return pass/fail
Actual: reads vars + HTTP POST to external URL + returns `{ allValid: true }` regardless
Delta: undeclared exfiltration + fake validation = malicious

### Behavioral Fingerprinting

These behavioral patterns survive any amount of obfuscation:
1. **Read secret → transmit over network** (any form)
2. **Receive code from network → execute code** (any decode-exec chain)
3. **Check if being observed → behave differently** (any env probe before payload)
4. **Establish persistence → survive restart** (any startup hook modification)

Draw the capability graph. The arrows between nodes are the attack.

### Cross-Validation — Two-Source Rule

Never escalate to `high`/`critical` without two independent evidence modes agreeing:

| Evidence Mode | Alone | Combined |
|---|---|---|
| String pattern match | Lead | + Flow trace = finding |
| AST structural match | Lead | + LSP call chain = finding |
| Version delta anomaly | Lead | + Behavior diff = finding |
| Missing legitimacy signals | Lead | + Suspicious behavior = finding |

---

## 4. Common Cognitive Traps

### Trap 1: Anchoring on Obfuscation
Obfuscation draws attention. The actual payload may be in a small, plain-text `postinstall.js`.
**Fix**: Scan ALL files first. Map every network call and exec across ALL files, obfuscated or not, before decoding anything.

### Trap 2: False Positives from Legitimate Tools
Webpack, Sentry, anti-bot (Cloudflare/DataDome), Electron, React Native Metro — all look like malware.
**Fix**: Check npm registry, GitHub, download count. If 10M+ weekly downloads, escalate very carefully.

### Trap 3: Signature Fixation
Novel attacks match zero signatures. The MCP classifier bypass in this research matches zero malware signatures — no eval, no obfuscation, no postinstall.
**Fix**: After signatures, ask: "What would a *novel* attack in this context look like?"

### Trap 4: Confirmation Bias
After finding one issue, everything else looks suspicious.
**Fix — adversarial hypothesis test**: Explicitly argue the opposite case. Write both headlines: "CONFIRMED: malicious" and "FALSE ALARM: wrongly flagged." Which is more embarrassing? Which is more likely?

### Trap 5: Missing Transitive Deps
Malice is often 3 levels deep in `package-lock.json`.
**Fix**: Check `package-lock.json` for recently added transitive deps with `postinstall` scripts.

### Trap 6: MCP/Tool Opacity Blind Spot
Agents can't see what happens inside a tool server between receiving parameters and returning.
**Fix**: For any tool-shaped artifact, check: implementation ≠ description? HTTP calls not in schema? Params forwarded anywhere?

---

## 5. Quick-Reference Triage Heuristics

### First 5 Questions Before Reading Code
1. What does this **claim** to do?
2. What capabilities does it **actually have**? (imports/requires/APIs)
3. What **changed recently**? (version delta, new files, new deps)
4. **When** does it execute? (install, import, runtime, scheduled)
5. **Worst case**: what's the most damaging thing it could do?

### Attacker's 5 Questions About Any Target
1. Where is authentication checked? (client-side only = bypass)
2. Where is sensitive data? (JWTs, API keys in localStorage/cookies)
3. Where does user input reach dangerous sinks? (innerHTML, eval, exec, SQL)
4. Which server endpoints exist? (client code reveals the API surface)
5. What changes with different roles/permissions? (hidden routes, feature flags)

### Red Flags That Always Warrant Escalation
1. `process.env` forwarded in HTTP request body
2. `eval()` or `Function()` with runtime-decoded string
3. `postinstall` with network request
4. Tool schema description ≠ code behavior
5. `require()` with dynamically constructed string decoding to network module
6. Silent exception handling around the only meaningful code path
7. `process.env.CI` / `NODE_ENV` check before sensitive logic
8. HTTP endpoint constructed only at runtime (never appears as literal)
9. Function serializes `os.userInfo()`, hostname, or `process.env` into a payload
