# Success and Verification: Full Removal of Binary/Archive Tooling

> Verifies `RFC.md` §Goals and the `IMPLEMENTATION.md` build.

## User Stories

- As a repo maintainer, I want `localBinaryInspect`, CLI `unzip`, and OQL `target:artifacts` fully deleted from code, schemas, docs, and skills, so that the tool surface matches the explicit directive with no dangling references. → RFC goals #1-#4
- As an agent following `skills/octocode-research`, I want the binary/archive routing guidance removed rather than pointing at a dead tool, so that I never recommend a call that will fail. → RFC goal on skill removal
- As a user of `localGetFileContent` on a binary file, I want a clear refusal message that doesn't suggest a tool that no longer exists, so that I'm not sent down a dead end. → RFC goal on `binaryFileUnsupported` rewording
- As a release engineer, I want the native `.node` module to rebuild cleanly and pass platform checks after the Rust `binary` module and `goblin` dependency are removed, so that the shipped artifact isn't broken on any platform. → RFC goal #4 / Unresolved Question (native rebuild)

## Acceptance Criteria

```gherkin
Feature: Binary/archive tooling is fully removed
  Scenario: MCP and CLI tool listing no longer includes localBinaryInspect
    Given the monorepo is built with `yarn workspace octocode build:dev`
    When I run `node packages/octocode/out/octocode.js tools`
    Then the output lists exactly 12 always-on tools
    And no tool named "localBinaryInspect" appears

  Scenario: CLI unzip command is gone
    Given the monorepo is built
    When I run `node packages/octocode/out/octocode.js --help`
    Then no "unzip" quick command is listed
    And running `node packages/octocode/out/octocode.js unzip x.zip` fails as an unknown command

  Scenario: OQL target:artifacts is rejected, not crashing
    Given the monorepo is built
    When I run `node packages/octocode/out/octocode.js search app.zip --target artifacts`
    Then the command fails with a clean "unsupported target" style error
    And the process does not throw an unhandled exception

  Scenario: Binary file read error no longer names a deleted tool
    Given a binary file is passed to localGetFileContent
    When the tool returns its BINARY_FILE_UNSUPPORTED error
    Then the message does not contain "localBinaryInspect"
    And the message still suggests "localSearchCode" for grepping embedded strings

  Scenario: Native module rebuilds and passes platform checks
    Given the Rust `binary` module and `goblin` dependency are deleted
    When I run `yarn build:native:all` followed by `yarn platforms:check`
    Then both commands succeed with no missing-symbol errors

  Scenario: No dangling references remain in docs or skills
    Given all phases in IMPLEMENTATION.md are complete
    When I search the repo for "localBinaryInspect", "target:artifacts", and CLI "unzip" outside git history
    Then zero matches remain in docs/, skills/octocode-research/, AGENTS.md, and README.md
```

## Definition of Done

- [ ] Acceptance scenarios pass (manual CLI runs per `IMPLEMENTATION.md` Phase 9, not compile-only — per `AGENTS.md` "never claim done from compile alone")
- [ ] `yarn build && yarn test && yarn lint && yarn typecheck` all pass with zero skipped/pending tests introduced by this change
- [ ] `yarn workspace @octocodeai/octocode-engine test:rust` passes
- [ ] Documentation and `skills/octocode-research` updated per `IMPLEMENTATION.md` Phases 6-7 (verified by final grep sweep showing zero hits)
- [ ] Rollout completed per `IMPLEMENTATION.md` §Rollout — single logical change, native rebuild confirmed before merge

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|---|---|---|---|---|---|
| Always-on default tool count | lagging | 13 (`ALL_TOOLS.length`, includes `localBinaryInspect`) | 12 | At merge | `packages/octocode-tools-core/src/tools/toolConfig.ts:340-355` via `node packages/octocode/out/octocode.js tools` |
| Repo-wide hit count for `localBinaryInspect`\|`target:artifacts`\|CLI `unzip` outside `.git/` | leading | ~95 files (per research-time grep, see `RESOURCES.md`) | 0 | At merge | repo-wide grep, run as the last step of Phase 9 |
| Full test suite pass rate (`yarn test` across all workspaces) | guardrail | 100% (must be reconfirmed at Phase 0, not assumed) | 100% (no regressions introduced) | Continuous through implementation | CI / `yarn test` |
| `yarn platforms:check` result | guardrail | Passing (native module before removal) | Passing (native module after removal) | At merge | `yarn build:native:all && yarn platforms:check` |

## Decision Rule

- Success if the leading metric (repo-wide reference count) reaches 0 and both guardrails (full test pass rate, `platforms:check`) hold at merge.
- Roll back (per `IMPLEMENTATION.md` §Rollout rollback trigger) if `yarn platforms:check` fails post-native-rebuild and cannot be fixed within the same change, or if the full test suite guardrail regresses and the fix would require reintroducing deleted code (a sign the removal was not actually isolated, contradicting the `PREREQUISITES.md` evidence — in that case, treat as new evidence and revise the RFC rather than force the merge).

## Traceability

| RFC requirement (§) | Story | Acceptance check | Verification | Post-ship status |
|---|---|---|---|---|
| Goal: `localBinaryInspect` removed from MCP+CLI | Maintainer story | Scenario "MCP and CLI tool listing..." | `IMPLEMENTATION.md` Phase 3, 5, 9 | Pending |
| Goal: CLI `unzip` removed | Maintainer story | Scenario "CLI unzip command is gone" | `IMPLEMENTATION.md` Phase 5, 9 | Pending |
| Goal: OQL `target:artifacts` removed | Maintainer story | Scenario "OQL target:artifacts is rejected..." | `IMPLEMENTATION.md` Phase 4, 9 | Pending |
| Goal: Rust `binary` module + `goblin` removed, native rebuild clean | Release engineer story | Scenario "Native module rebuilds..." | `IMPLEMENTATION.md` Phase 1, 9 | Pending |
| Goal: security allowlist (13 commands) removed | Maintainer story | Covered by full test suite guardrail (`commandValidator.test.ts` updated) | `IMPLEMENTATION.md` Phase 2 | Pending |
| Goal: `binaryFileUnsupported` reworded, not left dangling | End-user story | Scenario "Binary file read error no longer names a deleted tool" | `IMPLEMENTATION.md` Phase 3 | Pending |
| Goal: docs/skill mentions removed | Agent-user story | Scenario "No dangling references remain..." | `IMPLEMENTATION.md` Phase 6, 7, 8, 9 | Pending |
| Non-goal preserved: `localSearchCode`, clone/materialize paths untouched functionally | Maintainer story | Full test suite guardrail — no unrelated test regressions | `IMPLEMENTATION.md` Phase 3 (comment-only edit), Phase 9 | Pending |
