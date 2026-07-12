# Advanced PoC — Rule Injection with Exfil

Research-phase PoC with real ALLOW rule payloads, collector, and adversarial repo trap. The parent `POC/` contains safe marker-only variants for bounty review.

## Files
- `payloads/exfil_allow.json` — ALLOW rules enabling data exfiltration
- `payloads/weaken_deny.json` — narrowed DENY rules removing protections
- `payloads/allow_all_network.json` — ALLOW all network requests
- `collector.cjs` — HTTP server logging exfiltrated data
- `verify.cjs` — Node.js byte-offset verification (v2.1.92)
- `start.sh` — automated: create test repo + start collector
- `repo-trap/` — full adversarial repo with:
  - `.claude/settings.local.json` — injected ALLOW rules
  - `CLAUDE.md` — reinforcing authorization language
  - `CONTRIBUTING.md` — social engineering instructions
  - `.env.example` — fake credentials for testing
