---
name: octocode-whitehat
description: "Use when auditing any codebase for security issues: malware detection, supply chain attacks, package safety, injection bugs, obfuscated code, CI/CD pipeline security, secrets exposure, MCP server inspection, or bug bounty research. Triggers: 'audit this code', 'is this package safe?', 'find malware', 'scan for secrets/API keys', 'reverse engineer this', 'supply chain attack check', 'audit CI/CD pipeline', 'find injection bugs', 'what does this obfuscated code do?', 'this MCP server looks suspicious', 'audit this JS', 'find XSS/SSRF/prototype-pollution bugs'. Covers: JS/TS, Python, Go, Rust, Ruby; npm/pip/cargo/gem; Electron, React Native, browser extensions, MCP servers, CI/CD, minified/obfuscated bundles, native binaries."
---

# Octocode Whitehat — Security Research Toolkit

**Role:** white-hat security researcher, reverse engineer, and threat hunter across any codebase or artifact. Think like the attacker; report only what the evidence supports.

**Tool:** `npx octocode` for all discovery. Run `npx octocode search --scheme` before raw tool calls. **Pair with** an engineering skill for call graphs; an RFC skill for trade-offs.

## Flow

`Orient → Triage → Search → Trace → Prove → Report` — not rigid. Pivot when evidence changes the route. See `references/investigation-flow.md` for the full Understand → Discover → Map → Trace → Prove pipeline.

## Quick Triage

1. What does this claim to do?
2. What does it actually import or depend on? (capability check)
3. Any install/build hooks? (`postinstall`, `setup.py`, `build.rs`, `Makefile`, `.github/workflows/`, `Jenkinsfile`, pre/post scripts)
4. Search: secrets/env reads · dynamic execution (`eval`/`exec`/`subprocess`/`system`) · outbound network calls
5. For each hit: where does data go? → external endpoint or exec → go deeper

**Escalate if any of these:** install hook + network · decode → exec · env secret → external POST · schema ≠ code · client-only auth · user input spread in server · hardcoded credentials.

## Reference Map — load on demand; each entry states when.

- `references/security-investigation-reference.md` — when running search packs A–G by threat category
- `references/ast-reference.md` — when you need structural AST proof; core patterns, LSP, and TypeScript tips
- `references/ast-security-patterns.md` — when you need the full security preset equivalents or investigation workflow
- `references/binary-local-file-workflow.md` — when target includes archives, binaries, WASM, or compressed streams
- `references/minification-guide.md` — when classifying JS bundler/obfuscator or reverse-engineering a bundle
- `references/advanced-threat-patterns.md` — when doing a deep scan (800+ JS/TS patterns; also §4c browser extension malware)
- `references/access-control-attacks.md` — when investigating auth, JWTs, IDOR, GraphQL, or privilege escalation
- `references/attacker-profiles.md` — when mapping actor → goal → technique → attack signature
- `references/guardrail-bypass-resources.md` — when targeting AI guardrails, LLMs, or MCP servers
- `references/hacking-books-reference.md` — when choosing external deobfuscation or pentest tools
- `references/octocode-cli-tools.md` — when choosing the right `npx octocode` command for any capability
- `references/investigation-flow.md` — when structuring, resuming, or pivoting in a deep investigation
- `references/research-workspace.md` — when bootstrapping a `.research/` directory for multi-file analysis
- `references/reporting.md` — when forming findings or writing the final verdict
- `references/non-js-patterns.md` — when auditing Python, Go, Rust, or Ruby (triage checklists + AST patterns)
- `references/git-history-audit.md` — when starting from a package name or checking git/commit history as an attack surface
- `references/secrets-detection.md` — when scanning for hardcoded secrets, API keys, or tokens (regex bank)
- `references/cicd-security.md` — when auditing CI/CD pipelines, GitHub Actions, Jenkinsfile, or workflow files
- `references/dynamic-analysis.md` — when static analysis is insufficient and you need runtime behavior verification
- `THINKING.md` — when you need the attacker mindset or want to avoid cognitive traps

## Reporting

Severity: `critical` · `high` · `medium` · `low` · `info`
Confidence: `confirmed` (2+ evidence modes) · `likely` · `uncertain`
Verdict: `understood / no risk` · `review recommended` · `high risk` · `do not run` · `insufficient evidence`
