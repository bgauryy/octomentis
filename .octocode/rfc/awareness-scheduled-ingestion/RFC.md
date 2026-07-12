# RFC: Scheduled Connector Ingestion for Octocode Awareness

Status: Draft
Decision type: Reversible
Author(s): (agent-drafted, pending human review)
Created / Updated: 2026-07-11

## Audit Reasoning — kept (2026-07-12)

**Status:** Not implemented — 0% shipped. No `unattended_write`/`unattended-write` tag, no `OCTOCODE_INGESTION_MODE`, no `connectors/` in `packages/octocode-pi-extension`, no `ingest` subcommand in `packages/octocode-agent`.
**Why kept:** The problem statement (zero scheduled/background ingestion) is still accurate, and the scope is deliberately narrow (one connector, no daemon, no schema change) — cheap to keep as a scoped TODO.
**Remaining work:** the entire RFC — Phase 0 spike has not started.

## Summary
Add "proactive, scheduled memory" — the capability OpenWiki Brains' Personal Brain popularizes —
without adding a daemon or new schema to Octocode Awareness. An external OS-level scheduler
triggers a headless `pi`/`octocode-agent` session that pulls from one connector (web search,
reusing existing scripts), judges what's durable, and writes candidate memories through
Awareness's existing `memory record` CLI, landing in a new, additive `unattended_write` review
lane rather than as trusted `ACTIVE` memory. The capability itself lives in
`@octocodeai/pi-extension` (the standalone Pi core); `octocode-agent` only adds a convenience
CLI subcommand around an invocation any plain Pi install can already perform on its own.

## Goals and Non-Goals
- Goal: deliver scheduled/proactive memory without turning Awareness into a background daemon.
- Goal: unattended writes are provably distinguishable from human/agent-attended writes and
  require explicit promotion before being trusted at full weight.
- Goal: ship with exactly one connector (web search) using credentials/scripts that already exist.
- Goal: the ingestion capability is reachable by any plain `pi install` user with zero
  `octocode-agent` involvement — `octocode-agent`'s subcommand is a convenience, never a gate.
- Non-goal: Gmail, Notion, Twitter/X, or Hacker News connectors — each needs its own OAuth/API
  design and is out of scope for this decision.
- Non-goal: any change to Awareness's canonical SQLite schema (`db-schema.ts`), hook contract, or
  homeostatic no-daemon invariant.
- Non-goal: a new package. This RFC deliberately does not create `packages/octocode-ingestion` —
  the capability splits across two existing packages instead (see Reference-Level Explanation).
- Non-goal: making ingested content authoritative — it stays a lead like every other memory row.

## Motivation and Current State
A prior review of `packages/octocode-awareness` against LangChain's OpenWiki Brains announcement
(this thread) found Awareness materially ahead on retrieval, coordination, and verification, but
confirmed a real, deliberate gap: zero scheduled/background ingestion. `THESIS.md` states this
outright — "Optional hooks are reflexes around host events, not an autonomous agent" and "There is
no `sleep` command" (`packages/octocode-awareness/docs/THESIS.md:82-83,78`). A repo-wide search for
`cron|setInterval|scheduler|daemon` under `packages/` returned zero matches — there is no
scheduling primitive anywhere in this monorepo today.

Meanwhile the building blocks for *what* to ingest and *how to invoke a judging agent* already
exist and are idle outside one skill:
- `skills/octocode-brainstorming/scripts/{serper,tavily,exa}-search.mjs` +
  `lib/web-search-common.mjs` — working, multi-engine web search, credentialed via
  `@octocodeai/config`'s `tokens/envTokens.ts`.
- `@octocodeai/pi-extension`'s tool/prompt/Awareness-bridge wiring in `src/index.ts` — already
  registers a `web` tool with an SSRF-hardened Tavily→Serper→DuckDuckGo ladder
  (`packages/octocode-agent/docs/PI_INTEGRATION.md:171-180`).
- `pi --mode json "<prompt>"` — non-interactive, one-shot, scriptable invocation
  (`node_modules/@earendil-works/pi-coding-agent/docs/json.md:1-7`); `PiContext.mode` is a
  documented field the extension itself can read (`packages/octocode-pi-extension/src/types.ts:170`).

Cost of doing nothing: the gap stays real. Any comparison to "proactive memory" framing sees a
capability we could ship cheaply by wiring existing parts together, not a fundamental
architecture hole.

## Guide-Level Explanation
An operator installs one OS-level scheduled job (cron/launchd/Task Scheduler) that runs, on a
cadence they choose:

```bash
pi -e <path-to-@octocodeai/pi-extension> --mode json "<fixed ingestion prompt>"
# with OCTOCODE_INGESTION_MODE=1 and a connector name set in the job's own environment
```

Or, as a documented convenience that does the same thing:

```bash
octocode-agent ingest --connector web-search
```

Either invocation:
1. Checks a small local state file (not Awareness's DB) for whether the connector is due.
2. If due, calls the existing web-search script(s) for a configured query/topic list.
3. Runs headlessly with only a restricted tool set active, instructed to record only genuinely
   durable, reusable findings.
4. Writes via `bash` → `node $OCTOCODE_AWARENESS_CLI memory record ... --tag unattended-write
   --agent-id "ingestion-agent:web-search" --importance <=5` — the same CLI surface any
   human-driven agent already uses, per Awareness's own documented "the agent reaches awareness
   state through the CLI, not an in-process tool" design
   (`packages/octocode-pi-extension/src/index.ts:619-624`).
5. A human or attended agent later runs `attend`/`workboard`, sees the new `unattended_write`
   MemoryReview reason, and explicitly promotes (re-records without the tag) or archives each row.

Nothing here changes how Awareness itself runs. If the cron job is removed, ingestion stops;
Awareness's live state, hooks, and CLI are untouched. If `octocode-agent` is never installed,
ingestion still works for any plain Pi user.

## Reference-Level Explanation
**`@octocodeai/pi-extension` (owns the actual capability — no new package):**
- `src/connectors/web-search.ts` — thin wrapper importing
  `skills/octocode-brainstorming/scripts/lib/web-search-common.mjs` (reuse, not fork).
- `src/schedule-state.ts` — its own tiny local state (JSON or a private file under
  `$OCTOCODE_MEMORY_HOME`, **not** `awareness.sqlite3` — keeps Awareness's OCT1 fingerprint
  contract, `packages/octocode-awareness/docs/DB.md:70-86`, completely untouched) tracking
  `last_run_at` per connector.
- An `OCTOCODE_INGESTION_MODE` resolution added the same way `resolvePromptMode` already resolves
  `OCTOCODE_PROMPT_MODE` — option > env > default (`src/prompt.ts:45-51`). The extension may also
  branch on `ctx.mode === 'json'` (`src/types.ts:170`) to recognize a headless run.
- A fixed ingestion prompt wired via `before_agent_start`, active only when ingestion mode is on,
  restricting active tools and instructing the model to record only durable findings.

**`octocode-agent` (convenience invocation only, `bin/launcher.mjs`):**
- Add a reserved subcommand `ingest --connector <name>` to `parseInvocation()` (same shape as the
  existing `update`/`update core` rows, `launcher.mjs:163-176`), which sets
  `OCTOCODE_INGESTION_MODE=1` + the connector name in the spawned env, builds
  `['--mode', 'json', <fixed prompt>]`, and forwards through the existing `launchAgent()`/
  `buildPiArgs()` unchanged (`launcher.mjs:252-286`). No domain logic lives here.
- `OCTOCODE_ALLOW_INGESTION=1` guard checked before `launchAgent` is called, mirroring the existing
  `OCTOCODE_ALLOW_HARNESS_APPLY=1` gate for harness self-edits (`docs/HARNESS.md:76-78`).

**Standalone invariant (explicit, tested):**
- `packages/octocode-pi-extension/package.json` must never add `octocode-agent` as a dependency —
  verified today: its dependencies are only `@octocodeai/octocode-awareness`,
  `@octocodeai/octocode-core`, `@octocodeai/octocode-engine`, `@octocodeai/octocode-tools-core`.
- Every ingestion-mode behavior must be reachable by a plain `pi install` user with zero
  `octocode-agent` involved — their own cron entry running `pi -e <path> --mode json "<prompt>"`
  with `OCTOCODE_INGESTION_MODE=1` set directly works identically.
- No new code path may treat `octocode-agent`'s own env markers (`OCTOCODE_AGENT=1`) as a
  *requirement* for ingestion to run — those stay optional/informational, matching how
  `OCTOCODE_PROMPT_MODE` already works (settable by anyone, not just the launcher).

**Awareness-side change (the only edit to `packages/octocode-awareness`):** one additive line in
`repo-workboard.ts`'s existing `reviewReasons` array (`repo-workboard.ts:152-157`):
`tags.includes('unattended-write') ? 'unattended_write' : null`. No DDL, no CHECK-constraint
change, no fingerprint break — `tags_json` already exists on every memory row
(`db-schema.ts:37`).

**Trust model:** unattended rows are ordinary `ACTIVE` memories (no new `state` value — avoids the
CHECK-constraint/DDL problem entirely, since `memories.state` only allows `ACTIVE`/`SUPERSEDED`,
`db-schema.ts:34`) but are: (a) tagged `unattended-write`, (b) namespaced under `agent_id` prefix
`ingestion-agent:`, (c) capped at `importance <= 5` by convention plus a client-side clamp, and (d)
surfaced every time via the new `unattended_write` `MemoryReview` reason until a human/agent
explicitly re-records or archives.

**Credentials:** the web-search connector reuses `@octocodeai/config`'s existing token loading
(`tokens/envTokens.ts`) — no new secret-storage mechanism. Per `AGENTS.md:39-40`'s "store no
secrets in Awareness rows or projections," the ingestion code never writes a credential into
Awareness; only its own connector config touches keys, exactly like the brainstorming skill today.

**Compatibility:** fully additive and reversible. Uninstall = remove the cron entry; the one-line
`repo-workboard.ts` change is inert if no row ever carries the tag; removing `octocode-agent`
entirely leaves the capability fully intact for direct Pi users.

## Drawbacks and Pre-mortem
- **Cost/complexity:** new content in an existing package plus one small `octocode-agent`
  subcommand — no new package, no new database, no daemon process to keep alive.
- **Operational:** headless Pi (`--mode json`) is documented but **not yet verified against our
  own `octocode-agent` launcher** in this exact non-interactive form — flagged as an open
  question, closed in `IMPLEMENTATION.md` Phase 0.
- **Noise risk:** if the ingestion prompt over-records, `MemoryReview` fills with low-value rows.
  Mitigated by the `importance <= 5` clamp and requiring a human/agent pass before promotion —
  never auto-trusted.
- **Coupling risk:** without the standalone invariant, this capability could silently become
  exclusive to `octocode-agent` users, contradicting `pi-extension`'s own "no divergent code path"
  design (`packages/octocode-agent/docs/PI_INTEGRATION.md:46-47`). Mitigated by an explicit test
  (Phase 4b) asserting `octocode-agent` never appears as a `pi-extension` dependency.
- **Failure trigger for rollback:** if `unattended_write` rows are never being reviewed (workboard
  pressure grows unbounded) or if review reveals systematically low-quality output, disable the
  cron job — zero code rollback needed.
- **Blast radius:** capped to whatever `memory record` already allows any agent to do today; no
  new privilege is granted.

## Rationale and Alternatives
| Option | Fit | Complexity | Data/Security | Maturity | Reversibility |
|---|---|---|---|---|---|
| **A. External OS scheduler + connector/prompt content in `octocode-pi-extension` + a convenience reserved subcommand in `octocode-agent` (recommended)** | Matches the no-daemon invariant **and** preserves `pi-extension`'s standalone contract — any plain Pi install can trigger ingestion without `octocode-agent` | Low–Medium (no new package; reuses 3 already-shipped subsystems) | No schema change, no new secret store, capped/tagged writes | Reuses working code end to end | High — remove cron job, or just don't set the env var |
| B. In-process Awareness daemon/scheduler | Would deliver "always-on" ingestion | High (new long-running process, new failure modes) | Contradicts `THESIS.md`'s explicit no-daemon claim (`THESIS.md:82-83`) | None of this exists today | Low — redefines the product's core positioning |
| C. Lazy "check-on-session-start" hook only (no external process) | Fully event-driven, zero new process | Very low | No schema change | Could reuse existing `UserPromptSubmit`/`SessionStart` hook slots | High, but weak: only "scheduled" between sessions a human happens to start |
| D. Do-nothing | Zero cost | None | None | N/A | N/A — status quo |
| E. New standalone `packages/octocode-ingestion` (superseded — original design) | Would also avoid the daemon issue | Medium-High (third package, duplicate dependency surface on both awareness and pi/agent) | Same as A | Would re-implement subprocess launch logic `octocode-agent` already has | High, but strictly worse than A |

**A wins.** It's the only option that delivers real scheduling without contradicting the documented
no-daemon architecture invariant, reuses working code instead of building new orchestration
(superseding the original single-new-package design, Option E, once code inspection showed
`octocode-agent`'s launcher already had the exact reserved-subcommand plug point and
`pi-extension` already owned all prompt/tool content), and explicitly preserves `pi-extension`'s
standalone contract. **C is worth keeping as a cheap complement**, not a replacement, once A is
proven. **B is rejected outright** — a product-philosophy reversal needing its own RFC and
explicit maintainer sign-off.

## Prior Art
See `RESOURCES.md`. Headline lesson: OpenWiki Brains' own post admits real-time retrieval
(full-text/semantic/MCP) is still "exploring," so this RFC does not need to out-build OpenWiki's
retrieval — it only needs the ingestion trigger OpenWiki already ships, layered onto retrieval we
already have. A pre-existing, differently-scoped `RFC-octocode-ingest.md` in this repo's RFC
directory covers an unrelated concept (a local SQLite code-graph for OQL) — no overlap, noted here
only to avoid name confusion.

## Unresolved Questions
- [ ] Does `pi --mode json` work correctly when launched via `octocode-agent`'s `-e <coreRoot>`
  subprocess wrapper with no TTY? — Owner: implementer; next proof: run
  `octocode-agent -- --mode json "test"` in a non-TTY shell and inspect exit code + JSON stream.
- [ ] What is the right default cadence and query/topic list for the first (web-search) connector?
  — Owner: product decision; next proof: user input, deferred to `IMPLEMENTATION.md` as a config
  default with no hardcoded topics.
- [ ] Confirm `memory record` actually accepts repeatable `--tag` and an `--importance` cap as
  documented in `memory-recall.md:18` — Owner: implementer; next proof: `<cli> memory record
  --help` / `schema json-schema get_memory`.

## Future Possibilities
- Additional connectors (Notion, Gmail, git-activity, Hacker News) once each has its own
  auth-model decision.
- Promote Option C (lazy check) as a low-cost complement once Option A is proven in production.
- A dedicated "ingestion digest" preview command (mirroring `maintenance digest`'s preview-first
  pattern) summarizing pending `unattended_write` rows before a human reviews them individually.
