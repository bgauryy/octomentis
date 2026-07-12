# BOUNTY-7: Hardcoded Secrets Enabling Infrastructure Reconnaissance

## Classification

| Field | Value |
|-------|-------|
| ID | BOUNTY-7 |
| Severity | **LOW-MEDIUM** |
| Confidence | confirmed |
| CWE | CWE-798 (Use of Hard-coded Credentials), CWE-200 (Information Exposure) |
| Category | Information Disclosure |
| Target | Cursor.app v3.0.12 — workbench.desktop.main.js, main.js |

---

## Summary

Multiple API keys, Sentry DSNs, internal URLs, and service endpoints are hardcoded in the production JavaScript bundles. While some (like Sentry DSNs and Statsig client keys) are expected to be client-side, the combination enables significant infrastructure reconnaissance and potential service abuse.

---

## Evidence

### Statsig SDK Key
```
Value: KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB
Location: workbench.desktop.main.js, charOffset 4223979
```
Enables enumeration of all feature flags, A/B experiments, rollout percentages, and user segmentation logic via Statsig's public API.

### Sentry DSNs (3 instances)

| DSN | Org/Project | Location |
|-----|-------------|----------|
| `80ec2259ebfad12d8aa2afe6eb4f6dd5@metrics.cursor.sh/4508016051945472` | Cursor-hosted relay | main.js:99800 |
| `0a7b82d23ca5f4635708bc8e9957e4bd@o4504648565915648.ingest.us.sentry.io/4509635758522369` | Sentry US org | main.js:99800 |
| `c1dfb07d783ad5325c245c1fd3725390` at org `o447951` / project `4509632503087104` | Sentry browser | workbench:36682000 |

Enables fake error injection, monitoring pollution, and org structure enumeration.

### Internal Notion Developer Link
```
URL: https://www.notion.so/cursorai/Ryo-s-Journal-161da74ef045007ac1bf36660e08e4a4
Location: workbench.desktop.main.js, charOffset 30035609
```
Reveals Notion workspace organization (`cursorai`) and specific developer's journal page UUID.

### Google-style Internal Shortlinks
```
http://go/debugdata          (main.js, line 135)
http://go/sourcemap/sourcemaps/a80ff7df.../core/main.js.map  (main.js, line 317)
```
Reveals internal tooling infrastructure and specific build commit hashes.

### Full API Infrastructure (15+ domains)
See `strings.md` for complete endpoint inventory including regional GCP agent endpoints, staging servers, and authentication domains.

---

## Impact

- **Feature flag enumeration**: Statsig key → discover unreleased features, internal A/B tests
- **Error injection**: Sentry DSNs → pollute error monitoring with fake reports
- **Internal recon**: Notion link + shortlinks → organizational structure, developer identities
- **Staging discovery**: Staging endpoints exposed for potential testing

---

## Mitigation

1. Proxy Statsig through a backend endpoint instead of embedding client key
2. Implement Sentry rate limiting and origin checks
3. Remove internal Notion links and `go/` shortlinks from production builds
4. Add build-time linting to catch internal URLs before shipping
