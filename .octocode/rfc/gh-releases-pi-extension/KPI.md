# Success & Verification: GitHub Releases for @octocodeai/pi-extension

> Verifies `RFC.md` §Goals and the `IMPLEMENTATION.md` build. Goals are referenced, not restated.

---

## User Stories to Check

- **As a** maintainer, **I want** to push a git tag and have the build, GitHub Release, and npm publish happen automatically, **so that** I cannot accidentally publish a stale build and I always have a release artifact as proof. (→ `RFC.md` §Goals G1, G4)
- **As a** user on a restricted network without npm access, **I want** to run a single `curl | bash` command to install the extension, **so that** I don't need npm to get started. (→ `RFC.md` §Goals G3)
- **As a** user who installed the extension months ago, **I want** to discover that a newer version exists, **so that** I can upgrade without manually checking npm. (→ `RFC.md` §Goals G5 — Phase 3)
- **As a** contributor reviewing a past release, **I want** a per-version download URL and auto-generated changelog on GitHub, **so that** I can trace what shipped when. (→ `RFC.md` §Goals G2, G4)

---

## Acceptance Criteria (Gherkin)

```gherkin
Feature: Automated Release Pipeline

  Scenario: Happy-path release — tag matches package.json version
    Given a maintainer has bumped version in packages/octocode-pi-extension/package.json to "1.0.3"
    When they push tag "v1.0.3" to the main repo
    Then the release workflow completes successfully
    And a GitHub Release "v1.0.3" exists at github.com/bgauryy/octocode-mcp/releases/tag/v1.0.3
    And the release has an attached asset named "pi-extension-v1.0.3.zip"
    And the zip extracts to a valid dist/ directory containing index.js
    And npm shows "@octocodeai/pi-extension@1.0.3" at registry.npmjs.org
    And the GitHub Release notes are non-empty (auto-generated from merged PRs)

  Scenario: Tag-version mismatch guard
    Given package.json version is "1.0.3"
    When a maintainer pushes tag "v1.0.4"
    Then the release workflow fails at the validation step with a clear error message
    And no GitHub Release is created
    And no npm publish occurs

  Scenario: NPM publish only after artifact confirmed
    Given the GitHub Release and zip artifact are successfully created
    When the npm publish step runs
    Then "@octocodeai/pi-extension@<version>" appears on npm
    And the release workflow exits zero

  Scenario: NPM publish cannot precede artifact creation
    Given "gh release create" fails (e.g., duplicate tag)
    Then the npm publish step never executes
    And the workflow exits non-zero

Feature: Bootstrap Install Script

  Scenario: Successful install without npm
    Given the user has "pi" in PATH and no npm access
    And at least one GitHub Release exists
    When they run: curl -fsSL <install.sh URL> | bash
    Then the script downloads the latest release zip
    And copies dist/ to ~/.octocode/extensions/pi-extension/
    And runs: pi install ~/.octocode/extensions/pi-extension/index.js
    And prints "✓ @octocodeai/pi-extension <version> installed"

  Scenario: Persistent install survives temp dir cleanup
    Given the bootstrap script has completed successfully
    When the system cleans /tmp (mktemp dirs removed)
    Then starting a new pi session still loads the extension
    And /octocode-status confirms the extension is active

  Scenario: Missing pi binary — clear error
    Given "pi" is not in PATH
    When the bootstrap script runs
    Then it prints "❌ 'pi' is not in PATH" and exits non-zero
    And no download or install occurs

  Scenario: GitHub API returns no tag (rate limited or network error)
    Given the GitHub API returns an empty or malformed response
    When the bootstrap script runs
    Then it prints "❌ Could not determine latest release tag" and exits non-zero

Feature: Release Changelog

  Scenario: GitHub Release notes reflect merged PRs
    Given PRs were merged to main since the previous tag
    When a new tag is pushed and the release workflow completes
    Then the GitHub Release notes list those PRs by title
```

---

## Definition of Done

- [ ] All Gherkin scenarios pass (manually verified for the first release, then considered regression-tested by the tag-version validation guard in CI)
- [ ] `release.yml` is merged to `main` and listed in `.github/workflows/README.md`
- [ ] `NPM_TOKEN` secret is configured in the repo (`gh secret list` confirms)
- [ ] First automated release (`v1.0.3` or next version) appears on GitHub Releases with attached zip
- [ ] `pi-extension-v*.zip` extracts to a valid `dist/` with `index.js` at root
- [ ] `install.sh` is merged and the README Setup section links to it
- [ ] `install.sh` tested manually on macOS — persistent install survives new pi session

---

## Success Metrics

| Metric | Type | Baseline | Target | Window | Source |
|--------|------|----------|--------|--------|--------|
| Build-drift incidents (npm publish without fresh build) | Lagging — did it eliminate the risk? | Unknown (0 releases automated so far) | 0 occurrences | Per-release forever | Workflow enforces `yarn build` before publish; this becomes structurally impossible |
| Release artifact availability | Leading — is the zip present on every GitHub Release? | 0/0 (no releases yet) | 100% of `v*` tags have a `.zip` asset | Per-release | GitHub Releases API: `gh release list --repo bgauryy/octocode-mcp` |
| Bootstrap install success rate | Lagging — does the script work? | N/A | Script exits 0 on macOS + Ubuntu with `pi` in PATH | First two releases | Manual test runs per Step 2.1 V&V |
| Guardrail — existing CI green rate | Counter-metric (must not regress) | ~100% (CI passes on all PRs today) | ≥ 100% — no new failures on `ci.yml` | Ongoing | GitHub Actions CI badge |
| Guardrail — npm install success | Counter-metric (must not regress) | `pi install npm:@octocodeai/pi-extension` works today | Continues to work on every release | Per-release | Smoke test: `pi install npm:@octocodeai/pi-extension` after each publish |

---

## Decision Rule

- **Success if** the first automated release produces a GitHub Release with a `.zip` asset AND `@octocodeai/pi-extension@<version>` appears on npm, both triggered by a single `git tag` push, within the first release attempt.
- **Partial success if** the GitHub Release and zip are created but npm publish fails — acceptable since the artifact exists; fix `NPM_TOKEN` and re-trigger.
- **Roll back / iterate if** the workflow produces a broken npm package (bad build in dist) — run `npm deprecate` manually, fix the build, cut a patch release. The tag-version guard prevents version skew; the build step runs the same `yarn build` used locally.

---

## Traceability Matrix

| RFC requirement (§) | User story | Acceptance criteria | Verification method | Post-ship status |
|---|---|---|---|---|
| G1 — Automate build → artifact → npm publish pipeline | Maintainer: push tag → full release | Happy-path scenario; Tag-mismatch guard | Workflow run in GitHub Actions; `gh release list`; `npm show @octocodeai/pi-extension version` | pending |
| G2 — Attach versioned zip to every GitHub Release | Contributor: per-version download URL | Happy-path scenario: zip asset present | `gh release view v<version> --json assets` | pending |
| G3 — Bootstrap script for npm-free install | User without npm: `curl \| bash` installs | Bootstrap install + persistent install scenarios | Manual test on macOS; `pi session` shows extension loaded | pending |
| G4 — Auto-generated changelog per release | Contributor: PR titles in release notes | Release notes non-empty scenario | GitHub Release UI; `gh release view v<version> --json body` | pending |
| G5 — Update checker (Phase 3, deferred) | User: discover newer version | — (deferred until ≥2 tags) | Deferred — revisit after second release | deferred |
| RFC §Drawbacks: NPM_TOKEN expiry → no silent corruption | — | "NPM publish cannot precede artifact" scenario | Workflow step ordering in `release.yml` | pending |
| RFC §Pre-mortem: tag-version mismatch caught pre-build | — | Tag-version mismatch guard scenario | Validation step in `release.yml` (Step 1.2) | pending |
| RFC §Pre-mortem: OQ-1 persistent path | — | Persistent install survives temp cleanup | Manual: delete tmp, restart pi | pending |
