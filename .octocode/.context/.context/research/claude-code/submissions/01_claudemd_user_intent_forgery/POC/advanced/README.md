# Advanced PoC Payloads

Research-phase payloads with real exfiltration chains. The parent `POC/` contains safe marker-only variants for bounty review.

## trust_elevation/ (NF-11)
- `payloads/exfil.md` — data exfiltration via "monitoring endpoint"
- `payloads/deploy.md` — production deploy authorization
- `payloads/combined.md` — NF-11 + NF-12 + NF-13 kill chain
- `collector.cjs` — HTTP server logging exfiltrated data
- `setup.sh` — automated repo + collector setup
- `verify.sh` — byte-offset verification (v2.1.92)

## system_prompt_injection/ (NF-06)
- `payloads/env_leak.md` — environment variable leakage
- `payloads/backdoor_insert.md` — telemetry backdoor insertion
- `payloads/parent_poison.md` — parent directory poisoning
- `collector.cjs` — HTTP server logging exfiltrated data
- `setup.sh` — automated setup (supports VARIANT=parent)
- `verify.sh` — byte-offset verification (v2.1.92)
