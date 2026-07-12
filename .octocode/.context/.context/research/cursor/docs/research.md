# Cursor.app Security Audit — Executive Summary

**Target:** Cursor.app v3.0.12 (Anysphere, Inc.)
**Location:** `/Applications/Cursor.app/Contents/Resources/app/`
**Date:** 2026-04-09
**Method:** Static analysis of minified JS bundles using js-whitehat toolkit

## Verdict: `review recommended`

Cursor is a production-grade Electron application built on VSCode with extensive server-side AI integration. No malicious behavior was found, but the application has a **very large attack surface** (955 gRPC request types, 70+ services), **hardcoded secrets/keys**, **always-on telemetry**, and **silent data uploads** that users should understand.

## Key Metrics

| Metric | Value |
|--------|-------|
| Main bundle (workbench) | 54 MB minified |
| Main process (main.js) | 1.3 MB |
| Extension host | 4.8 MB |
| Cursor-specific extensions | 19 bundled |
| gRPC services | 70+ |
| gRPC request message types | 955 |
| node_modules packages | 337 |
| Network endpoints (Cursor-specific) | 15+ domains |
| Sentry DSNs (hardcoded) | 3 |
| Statsig SDK key (hardcoded) | 1 |

## Top Findings

| # | Severity | Confidence | Finding | Details |
|---|----------|------------|---------|---------|
| F01 | medium | confirmed | Hardcoded Statsig SDK key | `KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB` at charOffset 4223979 |
| F02 | medium | confirmed | Hardcoded Sentry DSNs (3) | See findings.md for all DSNs |
| F03 | medium | confirmed | Silent SQLite trace upload | `UploadIssueTrace` sends attachment data without user notification |
| F04 | low | confirmed | Internal Notion developer link leaked | `notion.so/cursorai/Ryo-s-Journal-*` in production code |
| F05 | info | confirmed | In-app advertisement system | Triggered on mount, find_issues, git_push |
| F06 | info | confirmed | Full codebase upload capability | `UploadRepoRequest`, `UploadFileRequest`, `CodebaseSnapshot` |
| F07 | info | confirmed | Google-style internal shortlinks | `go/debugdata`, `go/sourcemap` in production |
| F08 | info | confirmed | Edit history with file content sent to server | `EditHistoryAppendChangesRequest` with privacyMode field |
| F09 | low | confirmed | Sentry enabled by default, 100% logger sample rate | `loggerSampleRate: 1` in production |
| F10 | info | confirmed | 955 gRPC request types = massive API surface | See overview.md for full service list |

## Positive Security Findings

- Electron sandbox properly enabled (`sandbox: true`)
- Context isolation enabled (`contextIsolation: true`)
- Node integration disabled (`nodeIntegration: false`)
- Privacy mode exists as a team-level control (`SwitchTeamPrivacyModeRequest`)
- Diagnostic network domains clearly documented in code

## References

- [BOUNTY.md](BOUNTY.md) — Exploitable vulnerabilities with attack chains
- [findings.md](findings.md) — Detailed per-finding evidence
- [overview.md](overview.md) — Architecture, entry points, services
- [strings.md](strings.md) — All extracted URLs, keys, endpoints
