# Implementation: Octocode-on-Pi — extension-first harness

> Decision, goals, and scope: see `RFC.md` §Summary / §Goals and Non-Goals / §Rationale and Alternatives. This file does not restate them — it references them and lays out the build. Success signals live in `KPI.md`.

All Pi-internal citations are against `@earendil-works/pi-coding-agent@0.79.4` (verified unminified, `.d.ts` shipped; paths relative to `dist/`). Local citations are `packages/octocode-pi-extension/...`.

## Resolved Questions (were open in the v2 flat RFC)

Every prior open question, closed with a verified Octocode citation. Nothing here stays `uncertain`.

| Open question (RFC §) | Resolution | Evidence (verified 0.79.4 / local) | Confidence |
|---|---|---|---|
| Hooks config location (§Reference-Level G5) | `.octocode/agent/hooks.json` (project) over `~/.octocode/agent/hooks.json` (global) — octocode namespace, not Pi's `.pi/` | Pi loads no external hooks/settings for this: no `dotenv`, no `.env`/hooks parse in `dist`; reads only `PI_*` flags — so a fresh namespace is free of collisions | confirmed |
| Hook schema (§G5) | Adopt Claude Code's names/contract; implement only the Pi-emittable subset; reject the rest at load | Pi event bus emits `tool_call`/`tool_result`/`before_agent_start`/`session_start`/`agent_end`/`session_before_compact` (mapped in RFC §G5 table); no bus events for `PermissionRequest`/`SubagentStart`/etc. | confirmed |
| `promptMode` rollout (§G1) | Keep `append` default; `replace` opt-in until the golden snapshot survives one Pi bump | Replace must reconstruct `core/system-prompt.js:19-42` (customPrompt branch) + skills append `:112-113`; barrel export `formatSkillsForPrompt` at `index.d.ts:19` | confirmed |
| `/clear` command (§G4) | Register top-level `/clear` → `ctx.newSession()`; `/octocode compact` → `ctx.compact()` | `/clear` is **not** among the 22 built-ins (`core/slash-commands.js:2-25`); `/new`→`handleClearCommand`→`newSession()` (`interactive-mode.js:2119`→`:4652`→`:4659`); `ExtensionCommandContext.newSession` (`types.d.ts:246`,`:252`), `ExtensionContext.compact` (`:238`); stale-ctx throw `agent-session.js:483`; `newSession` returns `{cancelled}` (`:256-258`), `withSession` (`:255`) | confirmed |
| Env propagation (§G6) | `.octocode/agent/.env` (project) over global, assigned into `process.env` at `session_start`; picked up live by `getShellEnv()` | `getShellEnv()` spreads `...process.env` on every call (`utils/shell.js:96-107`, spread `:104`); `bash` uses it (`core/tools/bash.js:41`); `session_start.reason` = `startup|reload|new|resume|fork` (`types.d.ts:405-409`, field `:408`), so `/clear` re-enters and vars persist; `ctx.isProjectTrusted()` (`types.d.ts:226`) | confirmed |
| Isolated skill execution (§G7) | Not offered as stated; instead scope the env of extension-invoked scripts | Skills are prompt-injected text, not processes (`core/skills.js` `formatSkillsForPrompt` → `<available_skills>`; appended `system-prompt.js:112-113`); a skill's script runs via the model's `bash` tool with full `process.env` — no boundary to sandbox while `bash` is active | confirmed |
| Does Pi re-prompt on `agent_end` `decision:"block"` (Stop hook)? | **Deferred to a smoke test in Phase 6** — capability asserted from the event mapping but not runtime-proven | `agent_end` event exists on the bus; re-prompt behavior not confirmed by static reading | likely |

## Approach

Implement `RFC.md` §Rationale Alternative C (extension now, launcher later). Refactor the single-arg default export (`src/index.js:396`) into a factory that **returns** the `(pi)=>{…}` wiring function so `export default createOctocodePiExtension()` stays call-compatible with Pi's `default(pi)` convention. All new capabilities are additive and gated; append-mode is byte-for-byte unchanged.

## Steps (dependency-ordered)

Ordered so each step is shippable and validated cheaply; foundational/riskiest pieces land where a test can catch regressions. No time estimates.

### Phase 1: Factory & backward compat (foundation)
- [ ] Wrap current wiring in `createOctocodePiExtension({promptMode='append'}={})` returning `async function octocodePiExtension(pi)` — `src/index.js:396` (traces to `RFC.md` §Reference-Level "Factory & backward compatibility").
- [ ] `export default createOctocodePiExtension()`; add a test asserting `typeof default === 'function'` and `default.length === 1` (Pi calls `default(pi)`).
- [ ] **Exact-pin** Pi in the extension/launcher toolchain: `"@earendil-works/pi-coding-agent": "0.79.4"` (no caret) — `RFC.md` §Drawbacks (coupling).

### Phase 2: Single prompt — replace mode (G1)
- [ ] `composeSystemPrompt(opts)` faithfully mirroring `core/system-prompt.js:19-42` incl. `appendSystemPrompt` **and** the `<project_context>` wrapper; skills via barrel `formatSkillsForPrompt` (`index.d.ts:19`).
- [ ] Load `OCTOCODE_CORE_PROMPT` from the bundled `system/APPEND_SYSTEM.md` (`getAssetPaths().systemPrompt`, `src/index.js:20`) — single source of truth; add the harness-naming opening line in `docs/PI/APPEND_SYSTEM.md` (currently opens `<system_prompt>`, `APPEND_SYSTEM.md:1`).
- [ ] Branch `before_agent_start` (`src/index.js:409`) on `promptMode`: `replace` → `{systemPrompt: composeSystemPrompt(e.systemPromptOptions)}`; `append` unchanged.
- [ ] **Golden-snapshot test** diffing `composeSystemPrompt(sampleOptions)` vs Pi's real assembly (§Test Plan).

### Phase 3: Lean tools (G2)
- [ ] `session_start` → `pi.setActiveTools(['read','bash','edit','write','web_search','web_fetch'])` (`agent-session.js:1770`) — new; not currently called.
- [ ] Smoke-test `getActiveTools()` shows the pruned set before the first turn (races the first turn — `RFC.md` §Pre-mortem).

### Phase 4: Web tools (G3) — DONE (unified into ONE `web` tool)
> **Divergence from plan:** shipped as a **single `web` tool** (`web({url})` reads a page as clean text; `web({query})` searches), not two tools — per product directive "one tool so the agent can go to the web and see like an agent". Implemented in `src/index.js` (`web` registration) + `src/web.js` (guard + fetch + search + HTML→text); bundled via `scripts/build.mjs` (`extensionModules`). `defineTool`/`registerTool` mirror the `compact_context` pattern.
- [x] `web({query})` — DuckDuckGo HTML, `{title,url,snippet}[]`, `maxResults`; failures `{error}`, honors `signal`. (No `type: web|news` split — single search mode.)
- [x] `web({url})` with **hardened SSRF guard**: DNS-resolve → check every IP vs private/loopback/link-local/ULA/CGNAT/IPv4-mapped/metadata; `redirect:'manual'` + re-validate host+IPs per hop; http/https only; size cap + `signal` timeout. Residual: pure DNS-rebinding race (public@check→private@connect) needs connection pinning — follow-up.
- [x] SSRF unit tests (`tests/web.test.mjs`): DNS-rebinding (`attacker.com → 127.0.0.1`), literal metadata `169.254.169.254`, redirect-to-private, plus live smoke (fetch example.com, real search, localhost/metadata blocked). 8 tests green.

### Phase 5: Commands — `/octocode` umbrella, `/clear`, `/octocode compact` (G4)
- [ ] `pi.registerCommand('octocode', {getArgumentCompletions, handler})` routing non-interactive subs → capture stdout → `ctx.ui.notify`; interactive → hand off `! npx octocode login`.
- [ ] `pi.registerCommand('clear', …)` → `ctx.newSession({withSession: fresh => fresh.ui?.notify(...)})`; honor `{cancelled}`; **all post-reset work inside `withSession`** (stale-ctx throw `agent-session.js:483`).
- [ ] `/octocode compact` → `ctx.compact()` (`types.d.ts:238`).

### Phase 6: Env propagation + scoped script env (G6, G7) — G6 DONE
> Shipped as `src/env.js` + a `session_start` handler in `src/index.js`; see RFC `.octocode/rfc/octocode-web-search` (env propagation is its prerequisite) and `docs/CONFIGURATION.md`. Config location unified: `<octocode-home>/.env` (global) + `<project>/.octocode/.env` (project) — the SAME home every Octocode surface uses.
- [x] `loadOctocodeEnv({home,cwd,trusted})` — global-then-project merge, strict `KEY=VALUE` parser (ported from the brainstorming scripts), no shell expansion; project trust-gated & overrides global.
- [x] `session_start` handler → `propagateOctocodeEnv` assigns non-protected, non-already-set keys into `process.env`; global always, project only when `ctx.isProjectTrusted()`. Picked up live by Pi `getShellEnv()`, the bundled `octocode` CLI (`execFile` inherits), awareness runner, and the `web` tool. Runtime-verified.
- [x] Protected-key allowlist (`PATH`,`HOME`,`SHELL`,`USER`,`LOGNAME`,`PWD`,`TMPDIR`,`NODE_OPTIONS`,`PYTHON`,`OCTOCODE_TOKEN`,`GH_TOKEN`,`GITHUB_TOKEN`) → warn-and-skip; values never logged (metadata = names only). Tests in `tests/env.test.mjs`.
- [ ] **G7 still open:** `scopedScriptEnv(cwd)` (minimal allowlist + octocode `.env`) to replace the awareness runner's `env: {...process.env}` (`src/index.js`). Currently awareness inherits full `process.env`.

### Phase 7: Hooks engine (G5, the differentiator)
- [ ] Config load/merge (`.octocode/agent/hooks.json` project over global); reject non-emittable events with a clear warning at load.
- [ ] Event mapping per `RFC.md` §G5 table; JSON-on-stdin contract; `exit 2` blocks (stderr→reason); `hookSpecificOutput.{additionalContext,updatedInput,updatedToolOutput}`; Claude matcher rules.
- [ ] Trust-gate (`isProjectTrusted()`) + per-hook timeout (reuse awareness ~15–20s, `src/index.js:266`) + `command` path resolution; hook subprocesses inherit the Phase-6 env.
- [ ] **Migrate the awareness bridge** (`tool_call` `:426` / `tool_result` `:427`) to run as built-in `PreToolUse`/`PostToolUse` hooks through this engine.
- [ ] **Smoke-test the deferred Stop-hook question:** confirm Pi re-prompts on `agent_end` `decision:"block"`.

### Phase 8: Distribution / self-update (G8)
- [ ] **Publish 0.3.0 first** (workspace 0.3.0 > npm `latest` 0.2.0 — else version-check points backward, `RFC.md` §Pre-mortem).
- [ ] Rename `octocode-skills-update` (`src/index.js:583`) → `octocode-update` (BYO-pi: wraps `pi update @octocodeai/pi-extension` + `ctx.reload()`).
- [ ] Version-check on `session_start` via `isNewerPackageVersion()` (`utils/version-check.js:13`), timeout-guarded, non-blocking, skipped under `--offline`.
- [ ] (Later) thin `octocode-agent` launcher: pins the extension, passes `promptMode:'replace'`; `--update` self-updates the launcher (own install-method detection — Pi's `getSelfUpdateCommand`/`detectInstallMethod` in `config.js:246`/`:35` are not barrel-exported); `--version` prints launcher + harness version + update-available.

### Phase 9: Branding/UX + docs
- [ ] `session_start` → `ctx.ui.setStatus` (`types.d.ts:79`), octopus `setWorkingIndicator` (`:92`), `setHiddenThinkingLabel` (`:94`), `setFooter` (`:106`, branch · octocode.ai · version), welcome `notify` (`:75`); `src/tips.js` pool + `turn_start` → `setWorkingMessage` (`:81`) varied by `turnIndex`. Ship `themes/octocode.json` via `pi.themes` + `resources_discover → themePaths` (extend `src/index.js:403`). Header banner (`setHeader` `:110`) + `quietStartup` in the launcher only.
- [ ] Docs: hooks config reference; `.octocode/agent/.env` reference incl. protected-keys + "not a secret vault"; `octocode-status` reports hooks + active tools + prompt mode + env keys/source + harness version.

## Files / APIs / Contracts Touched

- `packages/octocode-pi-extension/src/index.js` — factory refactor (`:396`), `before_agent_start` replace branch (`:409`), new `session_start` handler (`setActiveTools`, env, branding), web tools via `registerTool` (pattern `:435`), new commands, awareness-runner env swap (`:265`), rename `octocode-skills-update` (`:583`). **Blast radius:** the default export is the package's **public contract** (consumed via `pi.extensions` in `package.json`) — the factory must stay `default(pi)`-callable.
- `packages/octocode-pi-extension/docs/PI/APPEND_SYSTEM.md` — harness-naming opening line (`:1`); remains the single prompt source.
- `packages/octocode-pi-extension/package.json` — exact-pin Pi in devtool/launcher; publish 0.3.0.
- New: `src/tips.js`, `themes/octocode.json`, hooks-engine module, `.octocode/agent/{hooks.json,.env}` loaders.

## Risk Mitigations

Concrete action per `RFC.md` §Drawbacks / §Pre-mortem:
- **Reconstruction drift** → barrel-only imports + exact pin `0.79.4` + golden-snapshot test; Pi bump = reviewed step.
- **Hooks arbitrary exec** → trust-gate + config-required + timeout + path resolution; awareness runs through the same engine.
- **`.env` leakage** → trust-gate + protected-key allowlist + "not a vault" docs + never-log values.
- **`web_fetch` SSRF** → DNS-resolved IP checks + per-redirect re-validation + size/time caps.
- **Backward-compat break** → Phase-1 export-shape test; `replace`/hooks/`.env`/web all additive & opt-in.
- **Version-check backward** → publish 0.3.0 before Phase-8 wiring.

## Test and Verification Plan (V&V)

Verification = built to the design. Validation = moved the `KPI.md` signals.

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Unit | export shape | `default` is a 1-arg function; `createOctocodePiExtension({promptMode})` returns wiring fn | `node --test tests/*.test.mjs` |
| Golden snapshot | replace prompt | diff `composeSystemPrompt(sampleOptions)` vs Pi 0.79.4 real assembly incl. `appendSystemPrompt`+`<project_context>` | `node --test` |
| Unit | SSRF guard | DNS-rebinding + redirect-to-private both blocked; public URL allowed | `node --test` |
| Smoke | tool pruning | `getActiveTools()` == pruned set before first turn | manual/session harness |
| Smoke | `/clear` | `newSession()` fresh ctx notify works; stale-ctx not reused; `{cancelled}` honored | manual |
| Smoke | env propagation | project `.env` key visible to `bash: env`; protected key skipped-with-warning; value never logged | manual |
| Integration | hooks | `PreToolUse exit 2` blocks a `write`; `PostToolUse` rewrites result; unsupported event rejected at load | `node --test` + manual |
| Smoke | Stop hook (deferred Q) | Pi re-prompts on `agent_end` `decision:"block"` | manual |
| Repo | package health | lint + build + tests green | `yarn verify` |

## Rollout / Migration / Rollback

- **Sequencing:** Phases 1→9 in order; each phase is independently shippable behind append-mode defaults. Observable go/no-go per phase = its row in the V&V table green.
- **Flags / gating:** `promptMode:'replace'` opt-in until the golden snapshot survives one Pi bump; hooks + `.env` off unless config exists **and** project trusted; `--offline` skips version-check.
- **Publish gate:** publish 0.3.0 **before** Phase-8 version-check wiring.
- **Rollback trigger:** any of — golden snapshot diverges after a Pi bump; SSRF test regresses; a hook escapes the trust-gate; version-check points backward. Revert the offending phase (all additive) or pin back the extension version. Mirror in `KPI.md` §Decision Rule.
- **Owner / approver:** bgauryy (author); no-fork stance requires acceptance sign-off (`RFC.md` §Unresolved Questions).

## References

- [`src/index.js:396`](packages/octocode-pi-extension/src/index.js) — current single-arg default export the factory wraps (backward-compat contract).
- [`src/index.js:265`](packages/octocode-pi-extension/src/index.js) — awareness runner `env: process.env` replaced by `scopedScriptEnv`.
- [`src/index.js:435`](packages/octocode-pi-extension/src/index.js) — existing `registerTool` pattern reused for web tools.
- `@earendil-works/pi-coding-agent@0.79.4` `dist/core/system-prompt.js:19-42` — the assembly `composeSystemPrompt` mirrors.
- `dist/utils/shell.js:96-107` — `getShellEnv()` live `process.env` spread that makes env propagation work.
- `dist/core/slash-commands.js:2-25` — 22 built-ins; confirms `/clear` is free.
- `dist/core/agent-session.js:483` / `:1770` — stale-ctx throw / `setActiveTools`.
- Claude Code hooks reference; Codex `developers.openai.com/codex/hooks`; Gemini CLI hooks — schema portability rationale (`RFC.md` §Prior Art).
