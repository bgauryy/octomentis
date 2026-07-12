# Success & Verification: Octocode-on-Pi — extension-first harness

> Verifies `RFC.md` §Goals and the `IMPLEMENTATION.md` build. Goals (G1–G8) are referenced by number, not restated. Build steps referenced by `IMPLEMENTATION.md` phase.

## User Stories to Check

- **As a harness maintainer**, I want one extension package (no fork) that both a BYO-`pi` user and a branded launcher consume, so that I track Pi releases once. (→ `RFC.md` §Goals G8)
- **As a BYO-`pi` user**, I want the default install to behave exactly as today (append-mode, single-arg export), so that upgrading is zero-risk. (→ G1, backward-compat)
- **As a launcher user**, I want a single authored prompt that still honors my `.pi/APPEND_SYSTEM.md` and project context, so that nothing Pi would have injected is silently lost. (→ G1)
- **As a coding agent**, I want a lean tool surface (`read/bash/edit/write` + web) so discovery is steered through Octocode. (→ G2)
- **As a user researching from the agent**, I want `web_search`/`web_fetch` that can't be turned into an SSRF pivot. (→ G3)
- **As a power user**, I want to drop a Claude-Code-shaped `hooks.json` and have my existing hook scripts run — or be told clearly when an event isn't supported. (→ G5)
- **As a project owner**, I want `.octocode/agent/.env` to flow to tools/hooks — but only when the project is trusted, and never masquerading as a secret vault. (→ G6, G7)

## Acceptance Criteria (Gherkin)

```gherkin
Feature: Backward-compatible default export (G1)
  Scenario: Existing pi-package users upgrade
    Given @octocodeai/pi-extension is imported by a user's own pi
    When Pi calls the default export with the pi host object
    Then it wires up append-mode exactly as v0.3.0 did
    And the default export is a single-argument function

Feature: Faithful replace-mode prompt (G1)
  Scenario: User APPEND_SYSTEM.md is preserved under replace
    Given promptMode is "replace" and the user has a .pi/APPEND_SYSTEM.md and project context
    When composeSystemPrompt runs on the turn's systemPromptOptions
    Then the output contains the appendSystemPrompt text and the <project_context> wrapper
    And it byte-matches the golden snapshot of Pi 0.79.4's own assembly

Feature: Lean tool surface (G2)
  Scenario: Discovery tools hidden before first turn
    Given a fresh session
    When session_start completes
    Then getActiveTools() equals [read, bash, edit, write, web_search, web_fetch]
    And grep, find, ls are inactive

Feature: SSRF-safe web_fetch (G3)
  Scenario: DNS rebinding to a private IP is blocked
    Given a hostname that resolves to 127.0.0.1 or 169.254.169.254
    When web_fetch is called
    Then it returns {error} and performs no request to the private IP
  Scenario: Redirect into a private host is blocked
    Given a public URL that 302-redirects to a private host
    When web_fetch follows the redirect
    Then it re-validates the new host and aborts before fetching it

Feature: Portable, honest hooks (G5)
  Scenario: A PreToolUse hook blocks a write
    Given a trusted project with hooks.json { PreToolUse: matcher "write", command exits 2 }
    When the model calls the write tool
    Then the tool call is blocked and stderr is surfaced as the reason
  Scenario: Unsupported event is rejected loudly
    Given hooks.json references PermissionRequest
    When the config loads
    Then a clear warning is emitted and the event is not silently dropped

Feature: Trust-gated env propagation (G6)
  Scenario: Project env flows only when trusted
    Given .octocode/agent/.env sets API_BASE and the project is trusted
    When session_start runs
    Then bash sees API_BASE in its environment
    And a protected key (PATH/HOME/token) in that file is skipped with a warning
    And no env value is written to any log
```

## Definition of Done

- [ ] All acceptance scenarios pass.
- [ ] `IMPLEMENTATION.md` V&V table green (`yarn verify` + `node --test`).
- [ ] Docs updated (hooks reference, `.env` reference incl. "not a vault", `octocode-status` fields).
- [ ] Rolled out per `IMPLEMENTATION.md` §Rollout; 0.3.0 published before version-check wiring.
- [ ] No-fork stance accepted (`RFC.md` §Unresolved Questions).

## Success Metrics

Never a single metric — pair a system signal with a perceptual one and name what must not regress.

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| Feature capabilities shipped over `ExtensionAPI` with **no fork** (G1–G8) | lagging (did it work) | 0 (append-only) | 8/8, fork not created | end of Phase 9 | phase V&V rows + repo (no `octocode-agent` fork package) |
| Golden-snapshot test survives Pi patch bumps without silent prompt divergence | leading (predicts drift) | n/a | 100% of bumps caught by CI, 0 silent divergences | rolling, per Pi bump | `node --test` golden snapshot in CI |
| SSRF guard: private-IP + redirect-to-private requests blocked | leading (security) | n/a (no `web_fetch`) | 100% blocked in test matrix | per release | SSRF unit tests |
| Backward compatibility of the default export | counter-metric (must not regress) | works (v0.3.0 append) | append-mode behavior unchanged; export stays 1-arg | every release | export-shape test + BYO-`pi` smoke |
| Awareness bridge parity after migration onto the hooks engine | counter-metric (must not regress) | file-lock/release works (hardcoded) | identical behavior via `PreToolUse`/`PostToolUse` | Phase 7 | awareness integration test |
| Env values leaked to logs | counter-metric (must not regress) | 0 | 0 | every release | log inspection in env tests |

_Delivery health:_ change-fail rate must not degrade — each phase is additive and independently revertible (`IMPLEMENTATION.md` §Rollback).

## Decision Rule

- **Success if** 8/8 goals ship over `ExtensionAPI` with no fork **and** all counter-metrics hold (backward compat, awareness parity, zero env-log leakage, 100% SSRF block) within the phase windows.
- **Roll back / iterate if** the golden snapshot diverges after a Pi bump, an SSRF test regresses, a hook escapes the trust-gate, or the version-check points backward — revert the offending (additive) phase or pin back the extension version. Mirrors `IMPLEMENTATION.md` §Rollback trigger.

## Traceability Matrix

Every `RFC.md` requirement mapped forward to a check and a post-ship status.

| RFC requirement (§) | User story | Acceptance criteria | Verification method | Post-ship status |
|---|---|---|---|---|
| G1 single prompt / backward compat | maintainer, BYO-user, launcher user | "Backward-compatible default export" + "Faithful replace-mode prompt" | export-shape unit test + golden snapshot | pending |
| G2 lean tools | coding agent | "Lean tool surface" | `getActiveTools()` smoke test | pending |
| G3 web tools | researching user | "SSRF-safe web_fetch" | SSRF unit tests (rebinding + redirect) | pending |
| G4 slash commands | BYO-user | (`/clear` fresh-session smoke) | manual smoke incl. `withSession` + `{cancelled}` | pending |
| G5 hooks | power user | "Portable, honest hooks" (block + reject) | hooks integration test + load-time warning test | pending |
| G6 env propagation | project owner | "Trust-gated env propagation" | env smoke: trusted-visible, protected-skipped, no log | pending |
| G7 scoped script env | maintainer | (awareness runner off `env: process.env`) | awareness parity integration test | pending |
| G8 one package / update path | maintainer | (no fork; one update path) | repo check (no fork pkg) + version-check test | pending |

> Naming note: file is `KPI.md`; H1 is "Success & Verification". Keep the traceability matrix current or mark rows `pending` — a stale KPI asserting untracked targets is worse than none.
