# Investigation Flow

Load when structuring, resuming, or pivoting in a deep investigation.

## Flow: Understand → Discover → Map → Trace → Prove

**Understand** what you're looking at. Read the README, package.json, tool schema. Form a hypothesis: "this is probably X, doing Y." If complexity doesn't match stated purpose, that mismatch is your first lead.

If minified or bundled: identify the bundler family first (see `minification-guide.md`), then create `.research/{{timestamp}}-{{research-name}}/` if extraction, decoding, prettifying, or AST proof will help. Source maps? Use them and skip the hard part.

**Discover** what's there. Run `npx octocode search <path> --tree --depth 1` and `npx octocode tools localFindFiles`. Run `npx octocode search "<term>" <path> --files-only` using the smallest search pack that matches your suspicion (see `security-investigation-reference.md` for packs A–G). Prioritize new/changed files. For non-text artifacts, see `binary-local-file-workflow.md`.

**Map** what you found. For deep work, write `research-metadata.md`, `overview.md`, `research.md`, and `search-playbook.md` early: stated intent vs actual capabilities, entry points, module layout, extraction decisions, and how to rediscover evidence. See `research-workspace.md` for the full directory structure.

**Trace** the interesting hits:

- `npx octocode search "<term>" <path>` — find the anchor, get file + line
- `npx octocode search <file> --target artifacts --inspect` — identify binary/WASM/native artifacts
- `npx octocode search <file> --target artifacts --decompress` or `--list` → `--extract <entry>` — compressed streams or archive members
- `npx octocode search <file> --match-string "<anchor>" --content-view exact` — smallest useful window
- `npx octocode search <file> --op documentSymbols` — get exact line for an anchor symbol
- `npx octocode search <file> --op definition --symbol <name> --line <n>` — resolve a wrapper/decoder
- `npx octocode search <file> --op callHierarchy --symbol <name> --line <n>` — prove call chain
- Update `flows.md` or `mapping/flow-map.md` when the chain is non-trivial

**Prove** with structural evidence. Pattern matching finds leads; LSP proves call chains; AST proves code shapes. A finding at `confirmed` requires 2+ evidence modes or an end-to-end trace.

## Suspicious Diff Investigation

When a dependency update or new commit looks suspicious, use a focused diff-first approach.

| Step | Focus | How |
| ---- | ----- | --- |
| Locate the change | Get recent commits or diff two refs | `search <owner/repo> --target commits --limit 20` or `search <a> <b> --target diff` |
| Scan the diff | New install scripts, network calls, binary blobs, `eval`/`exec`, new deps with hooks | Read diff output; flag any silent addition not in PR description |
| Confirm intent | Silent change = suspicious; check maintainer account age and recent activity | PR description + `--target pullRequests` |
| Trace forward | Apply Trace → Prove only to changed code | Normal pipeline on the delta |

Full commands and signals: `git-history-audit.md`.

## When to Pivot

- **High-risk hit** → drop everything, trace it fully
- **Vendor/framework noise** → label it, skip it, move on
- **Pattern without flow proof** → `uncertain` lead, not `confirmed` finding
- **New codebase area** → re-read `paths.md` to avoid redundant work
- **Stuck or unsure** → read `THINKING.md` for attacker mindset and cognitive trap avoidance

## Detection Matrix (Coverage Guide)

Use as a checklist — explicitly check or rule out each category on deep audits:

1. **Bootstrap & execution model** — entry points, bundle/runtime family, module registries, install hooks, startup paths
2. **Dynamic execution & loading** — `eval`, `Function`, `vm`, dynamic `require`/`import`, decode-then-exec, plugin loaders
3. **Network & listener behavior** — outbound HTTP/WebSocket/DNS/TCP, telemetry, localhost/metadata access, unexpected listeners
4. **File system & path reach** — reads/writes outside expected scope, traversal, home directory, temp, credential files
5. **Secrets, auth, session & crypto** — token handling, cookies, env secrets, RBAC bypass, IDOR, JWT tampering, mass assignment
6. **Obfuscation & anti-analysis** — string arrays, decoders, rotation, control-flow flattening, debugger traps
7. **High-impact abuse outcomes** — OS takeover, account takeover, phishing, prompt-injection, persistence, pivoting
8. **Change-first anomalies** — new/modified files, new install scripts, new bins, dependency spikes, suspicious transitive packages

## Reference Routing

Load on demand when you hit something unfamiliar:

| You're seeing… | Read | Teaches |
| -------------- | ---- | ------- |
| Hex var names, string arrays, `while(true)/switch` | `minification-guide.md` | Identify bundler/obfuscator and how to extract |
| Unknown `.bin`/`.wasm`/`.node`/`.zip` artifacts | `binary-local-file-workflow.md` | Per-family inspection chains |
| Suspicious patterns, need systematic search | `security-investigation-reference.md` | Pre-built search packs A–G |
| Deep obfuscation, WASM, steganography | `advanced-threat-patterns.md` | 800+ detection regex + AST signatures |
| Auth, JWTs, IDOR, privilege escalation | `access-control-attacks.md` | How authz failures manifest in JS |
| Need to think like a specific attacker | `attacker-profiles.md` | Actor → goal → technique → attack signature |
| AI guardrails, MCP red-teaming | `guardrail-bypass-resources.md` | Bypass techniques and external tools |
| Need deobfuscation or pentest tools | `hacking-books-reference.md` | Which external tool to reach for |
| Parseable code, need structural proof | `ast-reference.md` | Structural patterns via `npx octocode --pattern` |
| Auditing Python, Go, Rust, or Ruby | `non-js-patterns.md` | Language-specific triage checklists + AST patterns |
| Starting from a package name or checking git history | `git-history-audit.md` | Package audit entry path + commit/PR history as attack surface |
| Hardcoded secrets, API keys, or tokens | `secrets-detection.md` | Format-specific regex bank + systematic detection flow |
| CI/CD pipelines, GitHub Actions, Jenkinsfile | `cicd-security.md` | Pipeline injection + supply chain via actions |
| Need runtime proof or behavior verification | `dynamic-analysis.md` | Puppeteer/CDP interception + Frida + static-to-dynamic chain |
| Novel attack, cognitive traps | `THINKING.md` | Attacker psychology, hypothesis testing |
