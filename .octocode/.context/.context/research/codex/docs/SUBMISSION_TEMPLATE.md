# Bug Bounty Submission Template

> All fields are **required** unless marked *(optional)*.

---

## Submission Title

<!-- A concise summary title that captures what the vulnerability is about. -->
<!-- Example: "Automation Memory File Poisoning — Local Privilege Escalation to Unsupervised Agent Execution" -->

**Title:**

---

## Target

<!-- Select the vulnerable target. Targets not explicitly in scope may not be eligible. -->

| Field | Value |
|-------|-------|
| Target | <!-- e.g. `com.openai.codex` v26.325.31654 — Codex Desktop (Electron) --> |
| Platform | <!-- e.g. Electron (macOS arm64) --> |
| Version | <!-- e.g. v26.325.31654 (build 1272) --> |

---

## Technical Severity

<!-- Use the Vulnerability Rating Taxonomy (VRT) as the baseline guide. -->
<!-- A severity suggested by the VRT is not guaranteed to be the one applied. -->

| Field | Value |
|-------|-------|
| Severity | <!-- CRITICAL / HIGH / MEDIUM / LOW --> |
| VRT Category | <!-- e.g. Server-Side Injection > Command Injection --> |
| CWEs | <!-- e.g. CWE-74 (Injection), CWE-732 (Incorrect Permission Assignment) --> |

---

## URL / Location of Vulnerability *(optional)*

<!-- Where the vulnerability lives — file path, URL, function name, byte offset, etc. -->
<!-- Example: main-8X_hBwW2.js charOffset ~3727, function De -->

---

## Description

<!-- Describe the vulnerability and its impact. Maximum 25,000 characters. -->
<!-- Structure your description with the sections below. -->

### What Is the Vulnerability?

<!-- Clear explanation of what the bug is and where it lives in the codebase. -->

### Why Is This Dangerous?

<!-- Explain the security impact — what can an attacker achieve? -->

### Attack Surface / Entry Vectors

<!-- How can an attacker reach this vulnerability? -->

| Entry Vector | How |
|---|---|
| <!-- e.g. Malicious npm package --> | <!-- e.g. postinstall script writes to predictable path --> |
| <!-- ... --> | <!-- ... --> |

### Impact

<!-- Concrete consequences: data exfiltration, persistence, lateral movement, supply chain, etc. -->

---

## Steps To Reproduce

<!-- Proof of concept or step-by-step replication instructions. -->

1. <!-- Step 1 -->
1. <!-- Step 2 -->
1. <!-- Step 3 -->
1. <!-- Step 4 — verify the exploit worked -->
1. <!-- Control test — prove the vulnerability is the cause -->

---

## Supporting Material / References

<!-- Code evidence, file paths, byte offsets, function names, screenshots, PoC scripts, etc. -->

- <!-- e.g. Agent memory instruction: `main-8X_hBwW2.js` charOffset ~3727 -->
- <!-- e.g. POC script: [POC/README.md](./POC/README.md) -->
- <!-- ... -->

---

## Recommended Fixes *(optional)*

<!-- Suggested mitigations or fixes. -->

1. <!-- e.g. Sign memory.md with an HMAC; verify before reading -->
2. <!-- ... -->
