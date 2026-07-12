# Octocode Whitehat — Security Research Toolkit

A white-hat security skill for auditing any codebase or artifact: JS/TS, Python, Go, Rust, Ruby, and more. Covers packages (npm, pip, cargo, gem), Electron apps, browser extensions, React Native bundles, MCP servers, CLI tools, native binaries, and minified or obfuscated bundles.

## For Users

Use this skill when you need:
- Security audit of any codebase, package, or artifact (JS/TS, Python, Go, Rust, Ruby)
- Malware detection or supply chain attack analysis
- CI/CD pipeline security (GitHub Actions, Jenkinsfile, CircleCI, GitLab CI)
- Reverse-engineering minified, obfuscated, or compiled code
- Inspecting MCP servers for hidden behavior or schema/code mismatches
- Bug bounty research across any language or platform
- Scanning for hardcoded secrets, API keys, or credential leaks
- Access-control auditing: JWTs, IDOR, RBAC bypass, mass assignment
- Git/commit history threat-hunting (secrets deleted from history, malicious code reverted)
- Dynamic analysis: runtime behavior verification via Puppeteer/CDP or Frida

## Features

- **Quick triage** — 5-step protocol with instant red-flag escalation across any language
- **Structural AST search** — `npx octocode search --pattern/--rule` for code-shape proof (JS, TS, Python, Go, Rust, and more)
- **LSP semantic proof** — `--op definition/callHierarchy/references` to confirm call chains across 30+ languages
- **Binary/archive inspection** — `--target artifacts` for WASM, native `.node`/`.so`/`.dylib`, ZIP, APK, `.gz`, Hermes `.hbc`
- **Non-JS language patterns** — Python, Go, Rust, Ruby triage checklists and `--pattern` equivalents
- **Secrets detection** — format-specific regex bank (AWS, GitHub, OpenAI, Stripe, GCP, private keys, and more)
- **CI/CD security** — GitHub Actions injection, mutable action references, Jenkinsfile/CircleCI/GitLab patterns
- **Git history threat-hunting** — package audit entry path, commit/PR analysis, version-delta investigation
- **Dynamic analysis** — Puppeteer/CDP runtime interception, Frida native instrumentation
- **Obfuscation/minification classification** — JS bundler family detection and source-map recovery
- **Security search packs** — pre-built search packs A–G by threat category
- **Attacker-profile thinking** — actor → goal → technique → attack signature mapping
- **Deep detection patterns** — 800+ regex + AST signatures for JS/TS advanced threats
- **Research workspace** — auditable `.research/` directory structure for multi-file investigations
- **Structured reporting** — severity/confidence grading, finding format, final verdict

## How It Works

The skill loads from `SKILL.md` as a compact routing map. Each capability routes to a focused `references/` file loaded on demand — agents only load what the current investigation needs.

```
SKILL.md (compact map)
  ├── Quick triage + instant red flags (inline, language-agnostic)
  ├── Reference Map → 15 focused references/
  └── Reporting compact

references/
  ├── investigation-flow.md          Understand → Discover → Map → Trace → Prove
  ├── research-workspace.md          .research/ directory bootstrap + chunking
  ├── octocode-cli-tools.md          npx octocode command reference for all capabilities
  ├── ast-reference.md               Structural AST patterns + LSP proof
  ├── ast-security-patterns.md       Full security preset equivalents + investigation workflow
  ├── binary-local-file-workflow.md  Archives, WASM, native binaries, Hermes bytecode
  ├── security-investigation-reference.md  Search packs A–G by threat category
  ├── minification-guide.md          JS bundler/obfuscator classification + source-map recovery
  ├── advanced-threat-patterns.md    800+ JS/TS detection patterns + AST signatures
  ├── access-control-attacks.md      Auth, JWTs, IDOR, privilege escalation
  ├── attacker-profiles.md           Actor → goal → technique → attack signature
  ├── guardrail-bypass-resources.md  AI guardrails, LLMs, MCP red-teaming
  ├── hacking-books-reference.md     External tools + methodology
  ├── reporting.md                   Finding format + severity/confidence + verdicts
  ├── non-js-patterns.md             Python/Go/Rust/Ruby triage checklists + AST patterns
  ├── git-history-audit.md           Package audit entry path + git/commit history analysis
  ├── secrets-detection.md           Secrets regex bank + systematic detection flow
  ├── cicd-security.md               GitHub Actions, Jenkinsfile, CircleCI/GitLab patterns
  └── dynamic-analysis.md            Puppeteer/CDP + Frida + static-to-dynamic chain

THINKING.md                          Attacker psychology + cognitive trap avoidance
```

> **JS/TS depth:** `advanced-threat-patterns.md`, `ast-security-patterns.md`, `minification-guide.md` are JS/TS-focused. For other languages, load `non-js-patterns.md` for language-specific checklists; the investigation flow, binary workflow, LSP proof, and reporting methodology all apply equally.
>
> **Browser extensions:** patterns in `advanced-threat-patterns.md §4c`. Start there when auditing Chrome/Firefox extensions.

## For Developers & Maintainers

All tool commands use `npx octocode`. No scripts or local dependencies are required — the skill is self-contained.

**Tooling used:**
- `npx octocode search` — text search, file reads, AST structural search (multi-language), LSP (30+ languages), binary inspection
- `npx octocode tools localFindFiles` — file discovery by size/time/type
- `npx octocode unzip` — archive unpacking to disk
- External tools (optional, install when flagged): `shuji`, `webcrack`, `hermes-dec`, `hermes-decomp`, `brew install sevenzip`

**To update the skill:**
- `SKILL.md` — the compact routing map; keep it ≤50 lines. Add new capabilities as reference links, not inline prose.
- `references/` — each file is a focused topic; keep individual files ≤150 lines.
- Tool commands — all use `npx octocode`. Update `references/octocode-cli-tools.md` when the CLI surface changes.
- After edits, run: `node ~/.agents/skills/octocode-skill-lint.mjs .` from the skill folder.

## Installation

```bash
npx octocode skill --add bgauryy/octocode/.context/skills/octocode-whitehat
```
