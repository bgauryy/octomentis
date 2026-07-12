# RFC / Implementation Plan: Make octocode-engine LSP semantics work in production

- **Status:** Phase 0/1 + platformized discovery + security hardening SHIPPED (engine, 182 tests green); downloader + CLI command designed, gated pending SHA pinning.
- **Date:** 2026-06-27
- **Mode:** Plan (with RFC framing — this is an architecture decision)
- **Owner:** octocode-engine
- **Related:** brainstorm 2026-06-27; design review 2026-06-27 (2 agents); full guide → `docs/context/LSP_GUIDE.md` Part II.

---

## Audit Reasoning — kept (2026-07-12)

**Status:** Partially implemented — Phases 0–2 shipped (resolution ladder, SHA-gated downloader, `octocode lsp-server` CLI).
**Why kept:** Phase 3/4 roadmap items are real and unclaimed anywhere else in the repo.
**Evidence:** `resolveServerForFile`/`BUNDLED_JS_SERVERS` (`config.ts`), `serverProvisioner.ts` SHA gate, `serverManifest.json` (rust-analyzer + clangd pinned `sha256`), `validateLSPServerPath` wired into `client.ts` before spawn, `packages/octocode/src/cli/commands/lsp-server.ts` (list/status/install/uninstall/clean).
**Remaining work:** Phase 3 — expand the manifest to the full portable server set (taplo, marksman, lua, terraform, etc.). Phase 4 — IDE `execute*Provider` bridge in `octocode-vscode` (not started).

---

## Update — after build + 2-agent design review

**Shipped & verified** (engine TS tier; `yarn build:ts`, 182/183 tests pass):
- Resolution ladder `resolveServerForFile()` with provenance (`config.ts`); generalized JS bundling
  (TS/JS, Python→pyright by language, YAML, JSON/HTML/CSS) — deps added + installed.
- Cross-platform discovery `serverDiscovery.ts`; `platform.ts` (platformId + musl); `ideContext.ts`.
- Download `serverManifest.json` (7 portable servers) + read-only cache lookup with `.ok`-marker
  integrity + `OCTOCODE_LSP_CACHE_DIR` override (`serverManifest.ts`).
- Honest status: `LspStatusResult.serverSource` + per-language `unavailableHintFor` (`manager.ts`).
- **Security fix**: the `validateLSPServerPath` gate (shell-wrapper/nonexistent/non-executable) was
  exported but had **zero callers on the spawn path** — now wired into `LSPClient.start()` (`client.ts`).

**Design decisions locked by the review:**
- CLI surface = **`octocode lsp-server <list|status|install|uninstall|clean>`** (`install` is taken by
  the MCP installer; the old `lsp` query command was removed). Logic lives in the **engine**, CLI renders.
- `install` runs the ladder L0–L3 first and **skips if already resolvable** (prints where); `--force`
  writes only octocode's own cache. `--all [--platform]` = sandbox pre-warm.
- Downloader scope: **gz/raw-first, zero new deps** (covers rust-analyzer, taplo, marksman); add `fflate`
  later for zip/tar (clangd, lua, terraform); **xz/zls never auto-download**; toolchain servers exit 2 + instruct.
- Auto-download stays **off by default**, never fires in CI/sandbox, refuses while `sha256` is null.

**Resolved open questions:** Q2 → manifest committed in-repo (auditable). Q3 → portable-binary viability
table done (7 yes, 4 toolchain-coupled); gopls/jdtls/elixir-ls/gdscript stay detect-and-instruct.
**Remaining before the downloader ships:** pin per-asset SHA-256s in a reviewed commit; add the
extractor (`fflate`) + zip-slip guards + per-target install lock.

---

## Delivery Summary

```
Decision: Add a layered LSP server-resolution ladder behind the existing ./lsp exports.
          Do NOT build "our own LSP" — our grammars are tree-sitter (syntax), not semantic servers.
Why:      Today only typescript-language-server is bundled; every other language relies on `which`
          finding a server on PATH (client.rs:87), so non-TS semantics silently fail in production.
          Serena/multilspy/Codex/pi all solve this with bundle-JS + download-native + detect-toolchain.
Alternatives: 5 (do-nothing, build-own-LSP[rejected], bundle-everything[rejected],
               IDE-reuse-only, full layered ladder[chosen]).
Risk:     Medium — net-new download capability (security-sensitive); mitigated by opt-in gate,
          pinned versions, SHA256 + host allowlist, and preferring local/bundled servers first.
Next step: Phase 0 (honest status) + Phase 1 (generalize JS bundling) — zero download risk, immediate value.
```

---

## Goal

Make `lspGetSemantics` (definition / references / hover / call hierarchy / workspace symbols / diagnostics)
return real results in production for the languages octocode advertises — without requiring every end user
to pre-install and path-configure a language server, and **without** changing the public `./lsp` contract
that `octocode-tools-core` depends on.

Non-goals:
- Reimplementing semantic analysis from tree-sitter grammars (category error — see Alternatives).
- Bundling large native binaries (gopls/rust-analyzer/clangd) inside the npm tarball.
- Solving toolchain-coupled servers (Go, C/C++, Java) fully automatically — those stay detect-and-instruct.

---

## Evidence Summary

### Current-state facts (this repo)

| Fact | Evidence |
|---|---|
| Engine **spawns each LSP server as a child process over stdio** | `src/lsp/client.rs:87` `tokio::process::Command::new(&self.config.command)` + `stdin/stdout/stderr piped` |
| Server command is resolved from a **static extension→spec table**, found via `which` | `src/lsp/config.rs:158` `spec_for_extension`, `:115` `is_command_available` (uses `which::which`) |
| **Only `typescript-language-server` is bundled** as a real npm dep | `package.json` deps: `typescript-language-server ^4.4.0`, `typescript ^5.9.3` |
| The **JS-bundle fallback pattern already exists** but is TS-only | `src/lsp/config.ts:25` `withPackageLocalTypescriptServer` → `requireFromPackage.resolve('typescript-language-server/lib/cli.mjs')` |
| Resolution order today: env override → user JSON config → PATH | `config.rs:84` `resolve_spec_invocation`, `:364` `user_server_for_extension`, `:395` `user_config_paths` |
| **No IDE/editor detection or reuse anywhere** | grep of `src/lsp` for `VSCODE`/`TERM_PROGRAM`/`jetbrains` → only the *binary names* `vscode-json-language-server` etc., no host detection |
| Engine has **no HTTP client** (Rust or Node) | `Cargo.toml` has no `reqwest`/`ureq`/`hyper`; no `fetch`/`https.get`/`createWriteStream` in `src/**/*.ts` |
| **Security hooks already present** | native `validateLspServerPath` (`validation.ts`), `is_rejected_shell` + `is_executable_path` (`commands.rs:13,33`) |
| Public contract `tools-core` consumes | `src/lsp/index.ts` exports `getLanguageServerForFile`, `acquirePooledClient`, `getLspStatus`, `isLanguageServerAvailable`; consumed by `octocode-tools-core/src/tools/lsp/*` (e.g. `semantic_content/execution.ts`) and `local_ripgrep/lspBoost.ts` |
| octocode **already ships a VSCode extension** (currently only an MCP installer/auth bridge) | `packages/octocode-vscode/src/extension.ts` — spawns `npx octocode-mcp@latest`, injects GitHub token; no language providers |
| "Many grammars" = **tree-sitter**, used for fuzzy positioning + structural search | `src/lsp/resolver.rs:96` `resolve_position_with_grammar` (tree-sitter `parser.parse`); `src/lsp/grammar.rs` |

### External prior art

| Source | Finding | Confidence | URL |
|---|---|---|---|
| **oraios/serena** (`solidlsp`) | 40+ langs; auto-downloads portable binaries with **SHA256 + host allowlist** (`src/solidlsp/ls_utils.py:225` `download_file_verified`); detect-and-instruct for gopls/clangd; reuses IDE via JetBrains backend | strong | https://github.com/oraios/serena |
| **microsoft/multilspy** | Per-server `runtime_dependencies.json` mapping `platformId → GitHub-release URL`; first-run download + on-disk cache; **no checksum** (the weakness to fix) | strong | https://github.com/microsoft/multilspy |
| **isaacphi/mcp-language-server** (1559★) | Category leader still **requires manual install + hard-coded server path** per language → confirms the gap is unsolved at the top | strong | https://github.com/isaacphi/mcp-language-server |
| **mason-registry** | Reusable purl-based (`pkg:github/...`, `pkg:npm/...`) install index per server, published as a release artifact — borrow the **data** | strong | https://github.com/mason-org/mason-registry |
| **openai/codex#8745**, **pi-lsp-adapter** | Agent consensus: per-user managed cache, **pinned + checksum-verified**, **prefer project-local/on-PATH first**, **prompt-before-download** | moderate | https://github.com/openai/codex/issues/8745 · https://pi.dev/packages/pi-lsp-adapter |
| **VSCode built-in commands** | `vscode.execute{Definition,Reference,Hover,WorkspaceSymbol}Provider` "execute **all** providers" — aggregates LSP-backed extensions, **but only in-process from inside an extension** (no external socket) | strong | https://code.visualstudio.com/api/references/commands |
| **Claude Code #5495** | Proposed exactly this VSCode-LSP reuse; **closed as not-planned** — counterpoint: even a major agent didn't ship the cross-process bridge | moderate | https://github.com/anthropics/claude-code/issues/5495 |

---

## Current State

`lspGetSemantics` → `tools-core/.../lsp/semantic_content/execution.ts` → `acquirePooledClient(workspaceRoot, filePath)`
(`manager.ts:86`) → pool factory (`manager.ts:60`) calls `getLanguageServerForFile` (`config.ts:14` → native
`config.rs:default_server_for_file`) → builds a `LanguageServerConfig {command, args, ...}` → `new LSPClient(cfg).start()`
→ `client.rs:87` spawns `command`.

The single point of failure: **`command` is whatever the static table names, resolved only via `which`.**
On a production machine without `gopls`/`rust-analyzer`/`pylsp`/`clangd` installed, `isLanguageServerAvailable`
(`manager.ts:7`) returns `false` and the user gets the generic `LSP_UNAVAILABLE_HINT` (`manager.ts:19`).
TS/JS works because of the bundled dep + `withPackageLocalTypescriptServer` (`config.ts:25`).

---

## Proposed Approach — a layered server-resolution ladder

Keep the Rust spec table as the source of truth for *what* server a language needs (id, args). Move *provisioning*
(finding/bundling/downloading/verifying the actual executable) into a new **TS module**, where the download
capability and lifecycle naturally live (consistent with `ARCHITECTURE.md`: process/stateful orchestration → TS tier).

**Resolution order (first hit wins):**

| Layer | Source | Status | New work |
|---|---|---|---|
| **L0** | Explicit override: `OCTOCODE_*_SERVER_PATH` env / `.octocode/lsp-servers.json` | ✅ exists (`config.rs:84,364`) | none |
| **L1** | Project-local `node_modules/.bin` + on-`PATH` (`which`) | ⚠️ TS-only today | generalize to all langs |
| **L2** | **Bundled JS servers** (npm deps) | ⚠️ TS-only (`config.ts:25`) | add pyright, vscode-langservers-extracted, yaml-language-server, bash-language-server; generalize helper |
| **L3** | **Host-IDE provider bridge** (when running under `octocode-vscode`) | ❌ none | optional, gated by usage data |
| **L4** | **octocode-managed verified download cache** (`~/.octocode/lsp/`) | ❌ none | the core new capability |
| **L5** | **Detect-and-instruct** per-language (toolchain-coupled servers) | ⚠️ generic hint only (`manager.ts:19`) | per-language actionable guidance |
| **L6** | **Tree-sitter structural/positional fallback** | ✅ exists (`resolver.rs`, structural search) | surface explicitly in status |

The contract surface (`getLanguageServerForFile`, `acquirePooledClient`, `getLspStatus`, `isLanguageServerAvailable`)
**does not change shape** — only the resolution behind it gets richer, plus additive fields on `LspStatusResult`.

### New module: `src/lsp/serverProvision.ts`

```ts
// Pure-TS provisioning, called from manager.ts pool factory (manager.ts:60) and getLspStatus (manager.ts:125).
export type ProvisionMode = 'off' | 'prompt' | 'auto';        // OCTOCODE_LSP_AUTO_INSTALL, default 'prompt'
export type ProvisionedServer = {
  command: string;
  args: string[];
  source: 'override' | 'project-local' | 'bundled' | 'ide-bridge' | 'downloaded' | 'unavailable';
};

export async function provisionServer(
  spec: LanguageServerConfig,        // from native getLanguageServerForFile (id + default command + args)
  languageId: string,
  workspaceRoot: string,
  mode: ProvisionMode
): Promise<ProvisionedServer>;
```

`provisionServer` walks L0→L4 in order and returns the first hit (or `source:'unavailable'`). The pool factory
uses the returned `command`/`args`; everything downstream (`LSPClient`, `client.rs` spawn) is unchanged.

### Download manifest (octocode-owned, multilspy-shaped + checksum)

`src/lsp/serverManifest.json` (committed, version-pinned; data borrowed from mason-registry purls):

```jsonc
{
  "rust-analyzer": {
    "languageId": "rust",
    "version": "2024-12-09",                       // pinned upstream release tag, bumped by Renovate
    "platforms": {
      "darwin-arm64": { "url": "https://github.com/rust-lang/rust-analyzer/releases/download/2024-12-09/rust-analyzer-aarch64-apple-darwin.gz", "archive": "gz", "bin": "rust-analyzer", "sha256": "<pinned>" },
      "darwin-x64":   { "url": "...x86_64-apple-darwin.gz",  "archive": "gz", "bin": "rust-analyzer", "sha256": "<pinned>" },
      "linux-x64":    { "url": "...x86_64-unknown-linux-gnu.gz", "archive": "gz", "bin": "rust-analyzer", "sha256": "<pinned>" },
      "linux-arm64":  { "url": "...aarch64-unknown-linux-gnu.gz", "archive": "gz", "bin": "rust-analyzer", "sha256": "<pinned>" },
      "win32-x64":    { "url": "...x86_64-pc-windows-msvc.zip", "archive": "zip", "bin": "rust-analyzer.exe", "sha256": "<pinned>" }
    }
  }
}
```

Cache layout: `~/.octocode/lsp/<server>/<version>/<bin>` (consistent with `~/.octocode/tmp/*`, `~/.octocode/memory/`).
Download → temp file → **verify SHA256** → verify final redirect host ∈ allowlist (`github.com`,
`objects.githubusercontent.com`) → extract (`node:zlib`/unzip) → `chmod 0o755` → atomic rename into cache.
Already-cached + SHA-matching binary is reused with no network.

### Security model (must-haves before any download ships)

1. **Opt-in by default** — `OCTOCODE_LSP_AUTO_INSTALL=prompt` (never silently download+exec). `auto` for power users/CI-with-consent, `off` to disable entirely.
2. **Pinned versions + pinned SHA256** in the committed manifest — no "latest", no unverified bytes (fixes multilspy's gap).
3. **Host allowlist** on both request URL and final post-redirect URL.
4. Run the downloaded path through native `validateLspServerPath` (`validation.ts`) and `is_executable_path` before spawn; `is_rejected_shell` already blocks shell wrappers.
5. Downloaded binaries live under the user's `~/.octocode` (already inside the HOME-bounded access model), never inside the package or workspace.

---

## Alternatives Considered

| # | Alternative | Verdict | Why |
|---|---|---|---|
| 1 | **Do nothing** (require pre-install, like isaacphi) | Rejected | Leaves the production gap open; silent no-semantics is the current pain. |
| 2 | **Build our own LSP from tree-sitter grammars** | Rejected | Category error: tree-sitter = syntax, not cross-file type/reference resolution. Zero prior art; years of per-language work. |
| 3 | **Bundle every server in the npm tarball** | Rejected | gopls/rust-analyzer/clangd × 5 platforms = hundreds of MB dead weight per install; nobody does this. Bundle only the *JS* servers (L2). |
| 4 | **IDE-reuse only** (VSCode `execute*Provider` bridge) | Rejected as *primary* | Only works in-IDE; useless for headless CLI/Claude Desktop/CI (most octocode usage). Kept as optional L3. Even Claude Code closed #5495 as not-planned. |
| 5 | **Full layered ladder (L0–L6)** | **Chosen** | Each layer covers a context the others can't; matches Serena/Codex/pi consensus; reuses octocode's existing assets (bundled tsls, tree-sitter, the VSCode extension). |

---

## Step-by-Step Implementation (ordered by dependency)

### Phase 0 — Honest status + per-language guidance (no download; ship first)
1. Add per-language install guidance table in `manager.ts` (replace the single `LSP_UNAVAILABLE_HINT` with a lookup: e.g. rust → "install via `rustup component add rust-analyzer` or enable `OCTOCODE_LSP_AUTO_INSTALL`").
2. Extend `LspStatusResult` (`manager.ts:114`) with **additive** field `serverSource?: ProvisionedServer['source']` so callers can see *which layer* answered (bundled/downloaded/ide-bridge/unavailable). Non-breaking.
3. Make the tree-sitter fallback (L6) explicit in status when no server resolves.

### Phase 1 — Generalize JS-server bundling (no download)
4. Add npm deps: `pyright` (python), `vscode-langservers-extracted` (json/html/css/eslint), `yaml-language-server`, `bash-language-server`.
5. Generalize `withPackageLocalTypescriptServer` (`config.ts:25`) → `withBundledServer(config)`: a small map `{command → npm cli entry}`; when the native command isn't on PATH, resolve the bundled CLI via `createRequire(import.meta.url).resolve(...)` and rewrite to `process.execPath <cli> <args>` (same trick already proven for tsls).
6. Update `spec_for_extension` python entry to prefer `pyright-langserver --stdio` when bundled (keep `pylsp` as override target).

### Phase 2 — Managed download cache, prototype with rust-analyzer only
7. Create `src/lsp/serverProvision.ts` (L0→L4 ladder) + `src/lsp/serverManifest.json` with **only rust-analyzer**.
8. Implement TS downloader (`node:fetch` + `node:crypto` createHash + `node:zlib`) with SHA256 + host allowlist + atomic cache write to `~/.octocode/lsp/`.
9. Wire `provisionServer` into the pool factory (`manager.ts:60`) and `getLspStatus` (`manager.ts:125`); gate on `OCTOCODE_LSP_AUTO_INSTALL` (default `prompt`).
10. Add the `prompt` UX path (surface a one-line consent hint via the status/hint channel; `auto` downloads, `off` skips).

### Phase 3 — Generalize the manifest
11. Expand `serverManifest.json` to the portable-binary set that ships single-file GitHub-release assets: clangd, terraform-ls, lua-language-server, zls, taplo, gopls *(note: gopls normally needs Go — keep detect-and-instruct unless a portable binary is viable)*. Borrow URLs/versions from mason-registry purls.
12. Add a manifest-validation unit test + a Renovate rule to bump pinned versions + SHAs.

### Phase 4 — (Optional) Host-IDE provider bridge — gated by measured in-IDE usage
13. In `octocode-vscode/src/extension.ts`, register a command that calls `vscode.commands.executeCommand('vscode.execute{Definition,Reference,Hover,WorkspaceSymbol}Provider', uri, position)` and returns the aggregated results.
14. Add an `ide-bridge` source to `provisionServer` L3 that, when an env handshake signals the extension host is present, routes semantic requests to the extension instead of spawning a server.
15. Decision gate: only build Phase 4 after Phase 0's `serverSource` telemetry shows meaningful in-IDE usage.

---

## Files / APIs / Contracts Touched

- **New:** `src/lsp/serverProvision.ts`, `src/lsp/serverManifest.json`, `src/lsp/serverDownload.ts` (downloader+verify).
- **Modified:** `src/lsp/manager.ts` (pool factory, `getLspStatus`, status type, per-language hints), `src/lsp/config.ts` (`withBundledServer`), `src/lsp/config.rs` (python spec default), `package.json` (4 JS-server deps), `src/lsp/index.ts` (export new types if needed).
- **Optional:** `packages/octocode-vscode/src/extension.ts` (Phase 4 bridge).
- **Contract:** `getLanguageServerForFile` / `acquirePooledClient` / `getLspStatus` / `isLanguageServerAvailable` keep signatures; `LspStatusResult` gains additive optional fields only. Consumers in `octocode-tools-core/src/tools/lsp/*` need no change.

---

## Test and Verification Plan

- **Unit (Rust):** existing `config.rs` tests stay green; add python-prefers-pyright spec test.
- **Unit (TS):** `serverProvision` ladder order (override > project-local > bundled > downloaded); downloader rejects bad SHA, rejects off-allowlist host, reuses cache without network (mock fetch); `getLspStatus.serverSource` correctness per layer.
- **Integration:** on a clean container with **no servers on PATH**, assert: (a) Phase 1 — `lspGetSemantics` for a `.ts`/`.py`/`.yaml` file returns real results from bundled servers; (b) Phase 2 — with `OCTOCODE_LSP_AUTO_INSTALL=auto`, a `.rs` file triggers one download then a definition/hover result; second run hits cache (no network).
- **Security:** verify a tampered manifest SHA aborts before chmod/spawn; verify `is_rejected_shell` still blocks a shell command in user config.
- **Regression:** `octocode-tools-core` full suite + `octocode-mcp` typecheck + CLI suite (the real signal per project memory; the orphaned mcp vitest corpus is not).

---

## Rollout / Migration / Rollback

- **Rollout:** Phase 0 + 1 are behavior-only improvements (bundled JS servers, better hints) — safe to ship together. Phase 2 ships **disabled-by-default** (`prompt`); auto-download is opt-in.
- **Migration:** none for consumers — contract unchanged. Existing `OCTOCODE_*_SERVER_PATH` / `.octocode/lsp-servers.json` overrides keep working (L0 still first).
- **Rollback:** set `OCTOCODE_LSP_AUTO_INSTALL=off` to disable downloads at runtime; revert the 4 npm deps to drop bundling; the ladder degrades to today's PATH-only behavior. Cache is a disposable `~/.octocode/lsp/` dir.

---

## Risks and Open Questions

- **R1 (security):** downloading + executing binaries is a trust event. *Mitigation:* opt-in default, pinned SHA256, host allowlist, `validateLspServerPath`. **Hard requirement before Phase 2 ships.**
- **R2 (cold start):** first-run download + server indexing (rust-analyzer/jdtls 30–120s; already bounded by `SERVER_READY_TIMEOUT_MS` in `manager.ts:44`). *Mitigation:* surface progress via hints; cache after first run.
- **R3 (toolchain tail):** Go/C++/Java never fully auto. *Accepted:* detect-and-instruct (L5) — even Serena leaves these manual.
- **R4 (size of JS deps):** pyright + langservers-extracted add a few MB to the package. *Accepted:* JS bundling is the one case all prior art agrees on.
- **Q1:** What share of octocode LSP usage is in-IDE vs. headless? → decides Phase 4 investment. Resolve with Phase 0 `serverSource` telemetry before building the bridge.
- **Q2:** Should the manifest be committed in-repo or fetched from a published octocode index (mason-style)? → start committed (simpler, auditable); revisit if churn is high.
- **Q3:** Is a portable gopls binary viable, or is Go-toolchain detection the only honest option? → research per-release before adding gopls to the manifest.
