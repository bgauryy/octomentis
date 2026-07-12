# RFC: Octocode-on-Pi — extension-first harness

| Field | Value |
|-------|-------|
| **Status** | In Review |
| **Decision type** | Reversible per-feature (two-way door); the *no-fork* stance is a one-way commitment for this cycle |
| **Author(s)** | bgauryy |
| **Created** | 2026-07-01 |
| **Last Updated** | 2026-07-01 |
| **Package** | `packages/octocode-pi-extension` (`@octocodeai/pi-extension`) — enhance in place, **no new package, no fork** |
| **Supersedes** | `.octocode/rfc/RFC-octocode-agent-cli.md` (flat v2); this folder is the SSOT |

> Full 3-file folder chosen deliberately: the change is cross-package (extension ↔ Pi host), touches a public contract (`@octocodeai/pi-extension` default export + published npm), and adds security-sensitive surface (arbitrary-shell hooks, `.env` → `process.env`, SSRF-exposed `web_fetch`). See `IMPLEMENTATION.md` for the build plan and `KPI.md` for success/verification.

---

## Audit Reasoning — kept (2026-07-12)

**Status:** Partially implemented — factory/prompt modes (`createOctocodePiExtension`, `composeSystemPrompt` with `append`/`octocode-first`/`replace`), lean tool disabling, the `web` tool with SSRF guard, and env propagation (`src/env.ts`, `propagateOctocodeEnv`) are all shipped and tested.
**Why kept:** The RFC's stated differentiator — config-driven, Claude-Code-style lifecycle hooks over Pi's event bus — has not shipped; the awareness bridge is still hardcoded in `index.ts` rather than a generic hooks engine.
**Remaining work:** Phase 7 hooks engine (no `hooks.json` loader), Phase 5 command surface (`/octocode` umbrella + native `/clear`; today only discrete `octocode-status`/`octocode-harness`/`octocode-setup`/`octocode-skills-update` exist), Phase 6 G7 scoped script env (awareness still runs via `createPiAwarenessBridge`, not a scoped-env wrapper).

---

## Summary

Everything the earlier "fork Pi into a standalone `octocode-agent` CLI" proposal wanted — a single authored system prompt, a lean tool surface, web tools, Octocode slash commands, and lifecycle hooks — is reachable from the **existing** `@octocodeai/pi-extension` over Pi's public `ExtensionAPI`. We therefore **enhance the extension in place** rather than fork. The only capability that genuinely needs to own the app shell is startup-banner suppression (`quietStartup`), which is cosmetic and deferred upstream. The differentiator we add is **config-driven, Claude-Code-compatible lifecycle hooks** over Pi's event bus — a new capability, not a re-skin. All Pi-internal claims in this RFC were verified against `@earendil-works/pi-coding-agent@0.79.4` (ships unminified with `.d.ts`).

---

## Goals and Non-Goals

### Goals — all as a pure Pi extension over the public `ExtensionAPI`

1. **G1 — Single authored prompt.** Optionally *replace* Pi's default persona/tools/guidelines with our harness (opt-in `promptMode:'replace'`), instead of only appending after it.
2. **G2 — Lean tool surface.** Active tools = `read, bash, edit, write` + `web_search`, `web_fetch`; `grep`/`find`/`ls` inactive (discovery steered through Octocode; `bash` still available).
3. **G3 — Web tools.** `web_search` (no API key) + `web_fetch` with a *correct* SSRF guard (DNS-resolved IP checks + per-redirect re-validation).
4. **G4 — Octocode slash commands.** `/octocode <sub>` umbrella + a top-level `/clear` alias (Pi's native equivalent is `/new`) + `/octocode compact`.
5. **G5 — Config-driven hooks.** Claude/Codex-style lifecycle hooks over Pi's event bus (generalizes today's hardcoded awareness bridge). **The differentiator.**
6. **G6 — Env propagation.** `.octocode/agent/.env` (project) over `~/.octocode/agent/.env` (global), applied at `session_start` so every tool/hook/bash spawn inherits it (trust-gated).
7. **G7 — Scoped script env.** Extension-invoked scripts (awareness, future helpers) run with a minimal allowlist + octocode `.env` instead of the full `process.env`.
8. **G8 — One package, two consumption paths, one update path** — bring-your-own-`pi` (append mode) and an optional thin `octocode-agent` launcher (replace mode), both refreshing the same core.

### Non-Goals

- Forking Pi / owning the app shell / a new npm package.
- Removing Pi's startup chrome (`quietStartup` — needs the shell; file upstream).
- Removing Pi's built-in slash commands (no `removeCommand`; built-ins are matched first — see §Reference-Level).
- Replacing the `octocode` research CLI — this extension *drives* it.
- **Sandboxed skill execution.** Pi skills are prompt-injected context, not processes; true isolated execution is shell-owned. We only scope the env of scripts *we* launch (G7).

---

## Motivation

- **Problem.** The harness (prompt core, skills, awareness bridge, Octocode commands) is today an *append-only* Pi extension. We want a coherent, brandable, single-prompt coding harness with web tools and user-extensible hooks — and v1 assumed that required forking Pi's app shell.
- **Current state.** `@octocodeai/pi-extension` v0.3.0 already registers `resources_discover` (`src/index.js:403`), an **append**-mode `before_agent_start` (`src/index.js:409`, addendum builder `:67`), the awareness bridge on `tool_call`/`tool_result` (`:426`/`:427`, runner `runAwareness` `:256`), three model-facing tools via `pi.registerTool` (`compact_context` `:435`, `clear_context` `:458`, `handoff_context` `:473`), and five `octocode-*` commands (`:512`–`:583`). The default export is a single-arg function `export default async function octocodePiExtension(pi)` (`src/index.js:396`) — **not** a factory, and it does **not** call `setActiveTools`.
- **Evidence the fork was over-engineered.** Verification against Pi 0.79.4 confirms the extension can replace the prompt, prune tools, register tools/commands/providers, and rewrite tool calls/results — all over the public `ExtensionAPI` (see §Reference-Level capability table). The only shell-only gap is cosmetic (`quietStartup`).
- **Impact.** Affects harness maintainers (one code path vs. a fork to keep in sync with Pi), bring-your-own-`pi` users (installable pi-package), and future octocode-agent launcher users.
- **Use cases.** A user runs their own `pi` and installs `@octocodeai/pi-extension` (append). A team ships a branded `octocode-agent` launcher (replace). A project drops a `.octocode/agent/hooks.json` to run `prettier` after every write or block edits to protected paths.

---

## Guide-Level Explanation

To an engineer using it:

- **Install into your own Pi** — the package's `pi.extensions`/`pi.skills` fields make it installable. Default export stays append-mode, so it coexists with your Pi setup.
- **Or run the branded launcher (later)** — `octocode-agent` imports the factory with `promptMode:'replace'` and owns the launch, giving a single authored prompt and octocode chrome.
- **Lean tools** — you see `read, bash, edit, write, web_search, web_fetch`. `grep`/`find`/`ls` are hidden to steer discovery through Octocode; `bash` still reaches `rg`/`find` when you need them.
- **Hooks** — drop `.octocode/agent/hooks.json` (project) or `~/.octocode/agent/hooks.json` (global), Claude-Code-shaped:

  ```jsonc
  { "hooks": {
      "PreToolUse":  [{ "matcher": "write|edit", "command": "./scripts/guard.sh" }],
      "PostToolUse": [{ "matcher": "write",       "command": "prettier --write $TOOL_FILE" }]
  } }
  ```

  Existing Claude/Codex/Gemini hook scripts port over: same event names, JSON-on-stdin, `exit 2` blocks with stderr as the reason. Events Pi's bus can't emit are **rejected loudly at load**, never silently dropped.
- **Env** — declare project env in `.octocode/agent/.env`; it flows to every tool/hook/bash spawn (trust-gated; documented as *tool config, not a secret vault*).
- **Commands** — `/octocode status|stats|context|search|install|login …`, `/clear` (fresh session), `/octocode compact` (soft token reset).

---

## Reference-Level Explanation

The existing extension is extended; the zero-cost default path is preserved. All Pi citations are against `@earendil-works/pi-coding-agent@0.79.4` (unminified; paths relative to `dist/`).

### What the extension can and cannot do (verified)

| Capability | Mechanism (public `ExtensionAPI`) | Status |
|---|---|---|
| Replace the system prompt | `before_agent_start` → `{ systemPrompt }` (doc "Replace…chained", `core/extensions/types.d.ts:760-764`); read `event.systemPromptOptions: BuildSystemPromptOptions` (iface `:491`, field `:500`) | ✅ |
| Prune active tools | `pi.setActiveTools([...])` (`core/agent-session.js:1770`; delegates to `setActiveToolsByName` `:543`) | ✅ |
| Add custom tools | `pi.registerTool(defineTool({...}))` (`defineTool` `types.d.ts:375`, `registerTool` `:840`, `execute(id,params,signal,onUpdate,ctx)` `:361`) — **already used** by `compact_context`/`clear_context`/`handoff_context` | ✅ |
| Block/modify tool calls | `tool_call` → `{ block?, reason? }` + mutate `event.input` in place | ✅ |
| Rewrite tool results | `tool_result` → `{ content?, details?, isError? }` | ✅ |
| Inject context / replace messages | `context` → `{ messages }`; `message_end` → `{ message }` | ✅ |
| Slash commands | `registerCommand(name, {description, handler, getArgumentCompletions?})` (`types.d.ts:842`; `RegisteredCommand` `:793-799`) | ✅ |
| Providers/flags | `registerProvider`, `registerFlag` | ✅ |
| Skill/context discovery | `resources_discover` → `{ skillPaths }` (already used, `src/index.js:403`) | ✅ |
| **Suppress startup chrome** | `settingsManager.applyOverrides({ quietStartup })` — `ExtensionContext` has no writable settingsManager | ❌ shell-only |
| **Remove built-in slash commands** | no `removeCommand`; built-ins hardcoded before extensions | ❌ impossible |
| **Delete builtins from the registry** | `setActiveTools` makes them *inactive*; `bash` re-exposes `rg`/`find` anyway | ⚠️ inactive-only |

### Factory & backward compatibility

Refactor the default export into a factory whose **return value preserves the current call convention** — Pi calls `default(pi)`, so `createOctocodePiExtension(opts)` must return the `(pi) => {…}` wiring function:

```js
export function createOctocodePiExtension({ promptMode = 'append' } = {}) {
  return async function octocodePiExtension(pi) { /* current wiring + new features */ };
}
export default createOctocodePiExtension();            // today's behavior unchanged (append)
// launcher opts in: createOctocodePiExtension({ promptMode: 'replace' })
```

### Single prompt — replace, faithfully (G1)

In `before_agent_start`, when `promptMode === 'replace'`, return a fully-composed prompt that mirrors Pi's own `customPrompt` branch (`core/system-prompt.js:19-42`, skills append `:112-113`) **exactly**, so nothing Pi would have injected is lost — critically `appendSystemPrompt` and the `<project_context>` wrapper (both dropped in v1's sketch), so a user's `.pi/APPEND_SYSTEM.md` is honored. `OCTOCODE_CORE_PROMPT` stays the **single source of truth** = the bundled `system/APPEND_SYSTEM.md` (loaded via `getAssetPaths().systemPrompt`, `src/index.js:20`; source in `docs/PI/APPEND_SYSTEM.md`), so append- and replace-mode never diverge. Import only the barrel export `formatSkillsForPrompt` (`index.d.ts:19`) — never a deep `dist/core/...` path. **Coupling guard:** exact-pin Pi (`"0.79.4"`, no caret) + a golden-snapshot test diffing `composeSystemPrompt(sampleOptions)` against Pi's real assembly; a Pi bump is a reviewed migration step. Compatibility: `replace` is opt-in; the default export is byte-for-byte backward compatible.

### Lean tools (G2)

`session_start` → `pi.setActiveTools(['read','bash','edit','write','web_search','web_fetch'])`. `grep`/`find`/`ls` become inactive (not shown to the model); `bash` remains, so `rg`/`find` are reachable — a steer, not a hard boundary. Smoke-test that pruning applies before the first turn.

### Web tools — `web_search` + hardened `web_fetch` (G3)

Register via `pi.registerTool(defineTool({...}))` (TypeBox `Type.Object`; `typebox` is already imported dynamically at `src/index.js:433`). Port scraping/format logic from `octoflow-tools/{websearch,web-url}.ts`, but **do not port the SSRF guard verbatim** — octoflow's only validates the literal hostname string. Required hardening: (1) resolve the hostname and check **every resolved IP** against private/loopback/link-local/ULA/IPv4-mapped ranges (blocks `attacker.com → 169.254.169.254` / `→ 127.0.0.1`); (2) **re-validate after each redirect** (`redirect:'manual'`, re-check `Location` host+IPs per hop); (3) http/https only, optional host allowlist, size cap + timeout via `signal`. Failures return `{error}`, never throw; honor `signal`.

### Octocode slash commands (G4)

`login`/`logout`/`clone` collide with Pi built-ins (which win and hide colliding extension commands). Use a collision-free `/octocode` umbrella. Non-interactive subs (`status`,`stats`,`context`) → capture stdout → `ctx.ui.notify`; interactive OAuth (`login`) → hand the user `! npx octocode login` (Pi's `!` user-bash has a real TTY) or rely on `OCTOCODE_TOKEN`/`GH_TOKEN`/`GITHUB_TOKEN`.

**`/clear` + `/octocode compact`.** Pi has **no `/clear` built-in** (22 built-ins in `core/slash-commands.js:2-25`; none is `clear`), so the name is free for an extension command. Pi's native "wipe conversation" is `/new` → `handleClearCommand()` (`interactive-mode.js:2119`→`:4652`) → `runtimeHost.newSession()` (`:4659`). Register a top-level `/clear` alias → command-context `newSession()`; add `/octocode compact` → inherited `compact()`. Verified API: handlers get an `ExtensionCommandContext` (interface `types.d.ts:246`) exposing `newSession(options)` (`:252`); `ExtensionContext` (`:208`) exposes `compact(options)` (`:238`) and `isProjectTrusted()` (`:226`). **Stale-ctx caveat:** after `newSession()`/`fork()`/`switchSession()` the captured `ctx`/`pi` are invalid — Pi throws "ctx is stale after session replacement" (`agent-session.js:483`). Post-reset work **must** run inside the `withSession(freshCtx=>…)` callback (`types.d.ts:255`); `newSession` returns `{cancelled}` (`:256-258`) — treat `cancelled:true` as a no-op.

### Hooks — config-driven lifecycle hooks (G5, the differentiator)

Pi has **no native hooks config** but its event bus exposes every point Claude/Codex hooks need; the awareness bridge is already a hardcoded hook we generalize into a user-configurable layer.

- **Config:** `.octocode/agent/hooks.json` (project) merged over `~/.octocode/agent/hooks.json` (global), project wins — under the existing octocode namespace (`~/.octocode/memory`, `.octocode/scan`), not Pi's `.pi/`. `agent/` mirrors Pi's `~/.pi/agent/`.
- **Schema:** adopt Claude Code's (event names, JSON-on-stdin, `exit 2` blocks with stderr reason, `hookSpecificOutput`, matcher rules) — verified as the cross-ecosystem de-facto standard (Codex + Gemini CLI cloned it). Implement only the subset Pi's bus emits; **reject** unsupported events with a clear warning at load.

  | Claude event | Pi event | Capability |
  |---|---|---|
  | `PreToolUse` | `tool_call` | block (`exit 2`/`decision:"block"`) + modify input (`updatedInput` → mutate `event.input`) |
  | `PostToolUse` | `tool_result` | rewrite result (`updatedToolOutput` → `{content,isError}`); post-hoc block |
  | `UserPromptSubmit` | `before_agent_start` | inject `additionalContext` / block |
  | `SessionStart` | `session_start` | `additionalContext` (observe/setup) |
  | `Stop` | `agent_end` | `decision:"block"` to keep going (verify re-prompt in smoke test) |
  | `PreCompact` | `session_before_compact` | block/observe |
  | `Notification` | `ctx.ui.notify` | fire-and-forget |

  Unsupported (Pi's bus does not emit): `PermissionRequest`, `SubagentStart/Stop`, `WorktreeCreate/Remove`, `SessionEnd`, `PostCompact`, etc.
- **Security (non-negotiable — hooks run arbitrary shell):** off unless a hooks config exists **and** the project is trusted (`ctx.isProjectTrusted()`); resolve `command` paths; timeout every hook (reuse awareness's ~15–20s); never run hooks from untrusted `contextFiles`. Refactor the awareness bridge to run **as a built-in `PreToolUse`/`PostToolUse` hook** through this engine — one code path.

### The extension IS the core — one package, one update path (G8)

`@octocodeai/pi-extension` is the single source of the harness. Consumed two ways: (1) in a user's own `pi` (`promptMode:'append'`, default export); (2) via a thin `octocode-agent` launcher (later) that pins the extension as a dependency and passes `promptMode:'replace'`. Self-update: `octocode-agent --update` self-updates the launcher npm package (Pi is an internal detail; implements its own install-method detection because Pi's `getSelfUpdateCommand()`/`detectInstallMethod()` are in `config.js:246`/`:35` and **not** barrel-exported); bring-your-own-`pi` uses `pi update @octocodeai/pi-extension`. Version awareness reuses Pi's barrel-agnostic `isNewerPackageVersion()`/`comparePackageVersions()` (`utils/version-check.js:13`/`:5`) on `session_start`, timeout-guarded and non-blocking. Rename in-session `octocode-skills-update` (`src/index.js:583`) → `octocode-update`.

### Env propagation — `.octocode/agent/.env` → tools & hooks (G6)

Pi loads **no `.env`** (no `dotenv`, reads only its own `PI_*` flags). The extension parses the `.env` files once at `session_start` and assigns into `process.env`; every subsequent spawn inherits them because `getShellEnv()` spreads `...process.env` **live on every call** (`utils/shell.js:96-107`, spread at `:104`; `bash` uses it at `core/tools/bash.js:41`). `session_start` fires with `reason: "startup"|"reload"|"new"|"resume"|"fork"` (`types.d.ts:405-409`, field `:408`), so `/clear` re-enters this path and vars persist. Precedence: `.octocode/agent/.env` (project) over `~/.octocode/agent/.env` (global). **Security:** trust-gated (`isProjectTrusted()`); documented as *tool/hook config, not a secret vault* (the model can `bash: env`); **protected-key allowlist** blocks `PATH`/`HOME`/`SHELL`/tokens/`PYTHON` (warn-and-skip); strict `KEY=VALUE` only (no shell expansion); values never logged (`octocode-status` reports keys + source file, never values).

### Skill execution & env scoping — the honest version (G7)

Skills are **prompt-injected context, not executed units**: Pi injects an `<available_skills>` block (`core/skills.js` `formatSkillsForPrompt`, appended `system-prompt.js:112-113`); a skill's script is run by **the model** via the ordinary `bash` tool (`core/tools/bash.js`), inheriting full `process.env`. There is no skill process/sandbox/env boundary to scope while `bash` stays active (G2). True isolated skill execution is shell-owned → file upstream. What we ship instead: **scoped env for extension-invoked scripts.** Today the awareness bridge runs its script with `env: process.env` (`src/index.js:265`). Replace with `scopedScriptEnv` = minimal allowlist (`PATH`,`HOME`,`LANG`,`SHELL`,`PYTHON`) + the octocode `.env` (G6), so extension-run helpers see only what they need.

### Branding & UX (supports G8)

`ctx.ui` (`ExtensionUIContext`, `types.d.ts:67`) works from a plain extension: `setStatus` (`:79`), `setWorkingIndicator` (`:92`), `setWorkingMessage` (`:81`, rotating octocode-usage tips, transient), `setHiddenThinkingLabel` (`:94`), `setFooter` (`:106`), `notify` (`:75`). Only the header banner (`setHeader` `:110`) paired with suppressing Pi's own logo needs `quietStartup` (agent-only). Ship `themes/octocode.json` via `pi.themes` + `resources_discover → { themePaths }`. Tips are transient (never persisted to transcript), varied deterministically by `turnIndex` (no `Math.random`).

### Compatibility summary

Backward-compatible: the default export stays append-mode and single-arg-callable; `replace`, hooks, `.env`, and web tools are additive/opt-in. Un-adoptable later: yes — remove the extension or revert to append. Adopters need the new published version (see `IMPLEMENTATION.md` §Rollout).

---

## Drawbacks

- **Reconstruction coupling.** `composeSystemPrompt` mirrors Pi's internal `customPrompt`-branch layout; a Pi upgrade can silently drift the assembly. Mitigated by barrel-only imports, exact pin, and a golden-snapshot test — but it is real maintenance cost.
- **Hooks = arbitrary code execution.** A powerful, security-sensitive surface. Mitigated by trust-gate + config-required + timeouts + path resolution, but the blast radius of a bad hook is the user's shell.
- **`.env` → `process.env` is code-adjacent.** Anything in `.octocode/agent/.env` is exfiltration-reachable by the model; users may over-trust it as a secret store despite docs.
- **`web_fetch` is an SSRF magnet.** Getting the guard wrong exposes cloud-metadata endpoints; correctness rests on our DNS+redirect checks, not a library.
- **Two prompt paths** (append vs replace) can diverge if the single-source-of-truth discipline slips.
- **Simpler alternative exists** (stay append-only, no hooks): less power, far less risk. We are choosing more surface deliberately (G5).

### Pre-mortem — how this fails

| Failure | Trigger | Mitigation (baked in) |
|---|---|---|
| Replace-mode ships a prompt missing `appendSystemPrompt`/`<project_context>` → user's `.pi/APPEND_SYSTEM.md` silently ignored | Faithful-mirror bug | Golden-snapshot test vs Pi's real assembly; `replace` opt-in until it survives a Pi bump (§Reference-Level) |
| Pi 0.79.x bump moves `system-prompt.js`/`getShellEnv` internals → replace-mode or env-propagation breaks | Unpinned/renamed Pi | Exact pin `0.79.4`; Pi bump = reviewed migration; snapshot + env smoke tests catch it |
| `web_fetch` 302s into `169.254.169.254` and leaks metadata | Per-hop re-check missing | `redirect:'manual'` + re-validate host+IPs every hop (§Reference-Level G3) |
| A malicious/buggy hook wipes files or hangs the session | Untrusted project or bad script | Trust-gate + timeout + path resolution + config-required; awareness bridge runs through the same engine |
| Version-check reports "update available" pointing **backward** | npm `latest` (0.2.0) < workspace (0.3.0) | Publish 0.3.0 **before** wiring version-check (§Rollout) |
| Stale `ctx` reuse after `/clear` throws mid-command | Post-reset work outside `withSession` | All post-reset work inside `withSession(freshCtx)`; honor `{cancelled}` |
| Tool pruning races the first turn → `grep`/`find` still shown | `setActiveTools` applied too late | Prune in `session_start`; smoke-test `getActiveTools()` before first prompt |

---

## Rationale and Alternatives

### Why this design?

Three independent reviews (API-correctness, architecture, premise) converged: the fork is over-engineered for the stated motivation. Verification against Pi 0.79.4 confirms every v1 goal is reachable over the public `ExtensionAPI`; the only shell-only gap (`quietStartup`) is cosmetic. Enhancing one package gives one code path, one update path, and backward compatibility, while still enabling a branded launcher later.

### Alternatives Considered

#### Alternative A — Fork Pi's `coding-agent` bootstrap into a standalone `octocode-agent` CLI (v1)
- **What:** own the app shell; allowlist+replace tools; port octoflow's tool set.
- **Evidence:** v1 cited `octoflow-cli` — but that proves the *append* model (`noTools:'builtin'`), not an allowlist+replace fork.
- **Pros:** full control incl. `quietStartup` and default provider/theme.
- **Cons:** a fork to keep in sync with every Pi release; duplicated maintenance; no backward-compat with existing pi-package users.
- **Why not chosen:** buys only `quietStartup` (cosmetic) over the extension path, at large recurring cost.

#### Alternative B — Do nothing (stay append-only, no hooks/web/replace)
- **What:** keep v0.3.0 as-is.
- **Pros:** zero risk; zero new surface.
- **Cons:** no single authored prompt, no web tools, no user hooks — the harness stays a passive addendum.
- **Why not chosen:** forgoes the differentiator (G5) and the branded-launcher path (G8); see §What If We Do Nothing.

#### Alternative C — Hybrid: extension now, launcher later (**chosen**)
- **What:** enhance the extension over `ExtensionAPI`; ship an optional thin launcher that imports the same factory with `promptMode:'replace'`.
- **Pros:** one core, two consumption paths, backward-compatible, no fork; launcher adds branding without duplicating logic.
- **Cons:** replace-mode reconstruction coupling (mitigated); `quietStartup` still deferred.
- **Why chosen:** maximum capability per unit of maintenance and risk.

### Comparison Matrix

| Dimension | C — Extension+launcher (chosen) | A — Fork CLI | B — Do nothing |
|-----------|---|---|---|
| Codebase alignment | Extends existing package | New forked shell | Unchanged |
| Implementation complexity | Medium | High | None |
| Maintenance burden | Low (one package) | High (track Pi releases) | None |
| Backward compatibility | Full (append default) | Broken for pi-package users | Full |
| Capability ceiling | All but `quietStartup` | All incl. `quietStartup` | Append-only |
| Security surface added | Hooks + `.env` + web (gated) | Same + shell ownership | None |
| Reversibility | Per-feature two-way door | One-way (fork) | n/a |

### Trade-off Summary

We gain a single authored prompt, web tools, user hooks, and a branded-launcher path from **one** maintained package; we give up `quietStartup` (cosmetic, deferred) and take on reconstruction-coupling + security surface, both explicitly mitigated.

### What If We Do Nothing?

The harness remains an append-only addendum: no single authored prompt, no web tools, no user-configurable hooks (the awareness bridge stays bespoke and hardcoded), and no branded launcher. The differentiator (portable Claude-compatible hooks) never ships.

---

## Prior Art

- **Claude Code hooks** — event names (`PreToolUse`/`PostToolUse`/`SessionStart`/`Stop`), JSON-on-stdin, `exit 2`-blocks-with-stderr, `hookSpecificOutput`. Adopted as the schema.
- **OpenAI Codex hooks** (`developers.openai.com/codex/hooks`) and **Google Gemini CLI hooks** — both cloned Claude's contract, making it the cross-ecosystem de-facto standard (drop-in portability of users' existing hook scripts).
- **octoflow** (`octoflow-cli`, `octoflow-tools`, `extension.ts`) — proves the append model and the `ctx.ui` surface working from a plain extension; source for `web_search`/`web_fetch` scraping logic (SSRF guard rewritten).
- **Pi's own `customPrompt` branch** (`core/system-prompt.js:19-42`) — the exact assembly `composeSystemPrompt` must mirror.

---

## Unresolved Questions

_None open._ The v2 flat RFC resolved five prior open questions (hooks config location, hook schema, `promptMode` rollout, `/clear` command, env propagation, isolated skills). Each is recorded — with a now-verified Octocode citation — in `IMPLEMENTATION.md` §Resolved Questions. No recommendation in this RFC rests on an `uncertain` claim.

**Before acceptance:**
- [ ] Accept the *no-fork* stance for this cycle (the one one-way commitment).

**During implementation:** _(tracked in `IMPLEMENTATION.md`)_
- [ ] Confirm Pi re-prompts on `agent_end` `decision:"block"` (Stop-hook capability) via smoke test.
- [ ] Publish 0.3.0 before wiring the npm version-check.

---

## Future Possibilities

- File `quietStartup` (and a settings/resource-loader hook) upstream in Pi; adopt when available to complete the branded launcher.
- A Codex-style non-blocking `notify` argv hook for turn-complete callbacks (kept separate from the blocking schema).
- An octocode-owned `defineTool` runner that executes a skill's helper under `scopedScriptEnv` (still not a sandbox — see G7).
