# RFC: GitHub Releases for @octocodeai/pi-extension

| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Decision type** | Reversible (two-way door) — CI changes are revocable; npm publish continues independently |
| **Author(s)** | Guy Bary |
| **Created** | 2026-07-02 |
| **Last Updated** | 2026-07-02 |

---

## Audit Reasoning — kept (2026-07-12)

**Status:** Not implemented — 0% shipped. No `.github/workflows/release.yml` (only `ci.yml` exists), no `packages/octocode-pi-extension/scripts/install.sh`, no update checker.
**Why kept:** Still-valid, low-risk automation gap; nothing conflicts with or has superseded it.
**Remaining work:** Phase 1 (release workflow + `NPM_TOKEN` + docs), Phase 2 (`install.sh` + README one-liner); Phase 3 (update checker) is explicitly deferred in the RFC itself.

---

## Summary

Add a GitHub Actions release workflow that, on every `v*` tag, builds the extension, zips `dist/`, attaches the artifact to a GitHub Release (with auto-generated notes), and then publishes to npm — replacing the current fully manual publish process. A companion bootstrap script lets users install directly from the release asset without npm. An optional lightweight update-checker in `src/index.js` surfaces stale installs.

---

## Goals and Non-Goals

**Goals**

- G1 — Automate the build → artifact → npm publish pipeline: a single `git tag v*` triggers the full release. No human manually runs `yarn build && npm publish`.
- G2 — Attach a versioned `dist/` zip to every GitHub Release: provides a stable, npm-independent download URL per version.
- G3 — Ship a bootstrap script (`scripts/install.sh`) that downloads the latest release zip, extracts it, and installs via `pi install /path/to/dist/index.js` — zero npm dependency for end users.
- G4 — Auto-generate a per-release changelog from merged PRs/commits via GitHub's `--generate-notes` flag.
- G5 — (Follow-on, not in Phase 1) Fire-and-forget update checker in the extension that notifies users when a newer release exists.

**Non-Goals**

- NG1 — Replacing npm as the primary install path. `pi install npm:@octocodeai/pi-extension` stays canonical; GitHub Releases are supplemental.
- NG2 — Splitting skills into per-skill release assets (incremental skill updates). The monolithic `dist/` zip is sufficient at 2.4 MB.
- NG3 — GitHub Packages as an npm registry mirror. Redundant with npmjs.
- NG4 — Native binary cross-compilation per-platform. The extension is pure JS — no Rust/napi in this package.
- NG5 — Pi marketplace integration. Speculative; no evidence Pi is building this.

---

## Motivation

**Problem:** Releasing `@octocodeai/pi-extension` is a manual, error-prone, two-step operation with no artifact trail and no changelog.

**Current state:**
- Only one CI workflow exists: `.github/workflows/ci.yml`, triggered on PRs only (`packages/octocode-pi-extension/package.json:scripts` confirms build is `node scripts/build.mjs`).
- npm publish is a human-run `yarn workspace @octocodeai/pi-extension npm publish` with no CI gate and no build verification before publish.
- There is no GitHub Release for any prior version — no changelogs, no downloadable artifacts, no stable per-version URLs.
- The `pi` field in `package.json` points to `./dist/index.js`; `dist/` is gitignored, so npm publish requires a local `yarn build` first — a build-drift risk.

**Evidence:**
- `.github/workflows/` contains only `ci.yml` — no `release.yml` or `publish.yml` (`confirmed`).
- `README.md:L8`: install is `pi install npm:@octocodeai/pi-extension` — Pi has an npm resolver, meaning users currently depend entirely on npm.
- `dist/` breakdown: 2.4 MB total — 1.4 MB `bin/chunks/` (bundled octocode CLI), 584 KB skills, 380 KB awareness scripts.

**Impact:**
- Any contributor can publish a broken build to npm by forgetting to run `yarn build` first.
- Users on restricted networks (no npm access) cannot install the extension.
- Users who installed months ago have no signal that a newer version exists.
- There is no human-readable release history linked to the GitHub repo.

**Use cases:**
- Team member cuts a release: today they `yarn build` locally → `npm publish` → done (no verification, no artifact, no changelog).
- New user on an airgapped machine: can't `pi install npm:…` — currently stuck.
- User running v1.0.0 in January, doesn't know v1.2.0 shipped in March — no notification path.

---

## Guide-Level Explanation

After this RFC ships, the release flow is:

```bash
# bump version in package.json, commit, push
git tag v1.0.3
git push origin v1.0.3
# → GitHub Actions builds dist/, zips it, creates GitHub Release, publishes npm
```

A GitHub Release page appears at `github.com/bgauryy/octocode-mcp/releases/tag/v1.0.3` with:
- Auto-generated changelog from merged PRs
- Attached artifact: `pi-extension-v1.0.3.zip` (the full `dist/`)
- The stable download URL: `github.com/bgauryy/octocode-mcp/releases/download/v1.0.3/pi-extension-v1.0.3.zip`

A new user can bootstrap without npm:

```bash
curl -fsSL https://raw.githubusercontent.com/bgauryy/octocode-mcp/main/packages/octocode-pi-extension/scripts/install.sh | bash
# → downloads latest release zip, extracts, runs: pi install /tmp/pi-extension-dist/index.js
```

npm install remains unchanged and continues to be the canonical path:

```bash
pi install npm:@octocodeai/pi-extension
```

---

## Reference-Level Explanation

### Release workflow design

```
git push v* tag
    │
    ▼
.github/workflows/release.yml
    │
    ├─ checkout + setup Node 20 + corepack + yarn install --immutable
    ├─ yarn workspace @octocodeai/pi-extension build       ← builds dist/
    ├─ cd packages/octocode-pi-extension && zip -r ../../pi-extension-$TAG.zip dist/
    ├─ gh release create $TAG pi-extension-$TAG.zip \
    │    --title "v$TAG" --generate-notes               ← attaches artifact, generates changelog
    └─ yarn workspace @octocodeai/pi-extension npm publish ← npm publish AFTER artifact confirmed
```

Key properties:
- npm publish only fires if `gh release create` succeeds — artifact existence is the gate.
- The zip contains only `dist/` (already self-contained: extension entrypoint, bundled CLI chunks, skills, awareness scripts, system prompt).
- `NODE_AUTH_TOKEN` and `GH_TOKEN` are existing secrets in the repo (CI already uses them for checkout/publish).
- No Rust build step needed — `@octocodeai/pi-extension` is pure JS; the bundled `octocode.js` CLI is already pre-built during `yarn build`.

### Bootstrap script design (`scripts/install.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

# 1. Fetch latest release tag from GitHub API (unauthenticated, no token needed)
TAG=$(curl -fsSL https://api.github.com/repos/bgauryy/octocode-mcp/releases/latest \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/')

# 2. Download the release zip
TMPDIR=$(mktemp -d)
curl -fsSL -o "$TMPDIR/pi-extension.zip" \
  "https://github.com/bgauryy/octocode-mcp/releases/download/$TAG/pi-extension-$TAG.zip"

# 3. Extract
unzip -q "$TMPDIR/pi-extension.zip" -d "$TMPDIR"

# 4. Install into Pi
pi install "$TMPDIR/dist/index.js"

echo "✓ @octocodeai/pi-extension $TAG installed"
```

Constraints:
- Requires `pi` binary in PATH; script validates this before download.
- Requires `curl`, `unzip` — universally available on macOS/Linux.
- Extraction goes to a `mktemp` dir; the `pi install` command persists the reference, so cleanup of the tmp dir is safe only after pi stores the path internally (or the script copies to `~/.octocode/extensions/`).

> **Open Question OQ-1:** Does `pi install <local-path>` copy the extension files to a Pi-managed directory, or does it store the given path as a reference? If a reference, extracting to `mktemp` and then cleaning up would break subsequent Pi sessions. → **Close in IMPLEMENTATION.md.**

> **Open Question OQ-2:** Does the repo already have `NPM_TOKEN` / `NODE_AUTH_TOKEN` configured as a GitHub secret for automated npm publish? → **Close in IMPLEMENTATION.md.**

### Update checker design (G5, follow-on)

In `src/index.js`, inside the `resources_discover` handler, fire a background check:

```js
// Fire-and-forget — never blocks tool registration
checkForUpdate().catch(() => {}); 

async function checkForUpdate() {
  const cacheFile = path.join(getOctocodeHome(), 'pi-extension-update-check.json');
  const now = Date.now();
  // Read cached result; skip check if < 24h old
  try {
    const cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
    if (now - cache.checkedAt < 86_400_000) return;
  } catch {}

  const res = await fetch('https://api.github.com/repos/bgauryy/octocode-mcp/releases/latest',
    { headers: { 'User-Agent': 'octocode-pi-extension' } });
  const { tag_name } = await res.json();
  fs.writeFileSync(cacheFile, JSON.stringify({ checkedAt: now, latestTag: tag_name }));

  const latest = tag_name.replace(/^v/, '');
  const current = PACKAGE_VERSION; // injected at build from package.json
  if (semverGt(latest, current)) {
    console.error(`[octocode-pi-extension] Update available: ${current} → ${latest}\n  pi install npm:@octocodeai/pi-extension`);
  }
}
```

Rate limit: GitHub unauthenticated API is 60 req/hour; with 24h caching per machine, this is negligible.

---

## Drawbacks

1. **Secret management**: automated npm publish requires `NODE_AUTH_TOKEN` in GitHub Secrets. If the secret rotates or expires, releases silently fail at the publish step (but the GitHub Release itself succeeds, creating a discrepancy).
2. **Zip path coupling**: the bootstrap script hardcodes the zip name pattern `pi-extension-$TAG.zip`. If the filename changes in the workflow, the script breaks.
3. **`pi install <local-path>` behavior ambiguity**: if Pi stores a reference rather than copying files, the bootstrap script's `mktemp`-then-cleanup approach would break installed sessions.
4. **Version bump is still manual**: the workflow is triggered by a tag, but someone must still bump `package.json` version and push. This RFC does not add a version-bump automation (intentionally out of scope for now).
5. **2.4 MB zip on every release**: not a problem today, but if `dist/` grows significantly (e.g., more skill content), release upload times increase.

### Pre-mortem — how this fails

| Failure | Trigger | Mitigation |
|---|---|---|
| npm token expired; GitHub Release created but npm not published | Token rotation without updating secret | Workflow step fails visibly with non-zero exit; `gh release create` runs first — GitHub Release exists as proof of build. Re-trigger by re-pushing the tag after secret update. |
| Bootstrap script extracts to temp, pi loses the path after cleanup | `pi install` stores reference not copy | Detect in OQ-1 research; if reference-based, copy `dist/` to `~/.octocode/extensions/pi-extension/` before calling `pi install` |
| Tag pushed without version bump in package.json | Human error | Add a workflow validation step: assert tag matches `package.json` version field before building |
| `gh release create` fails on duplicate tag | Re-push same tag | Workflow uses `--title` not `--recreate-tag`; duplicate check: `if gh release view $TAG; then exit 1; fi` |

---

## Rationale and Alternatives

### Why This Design?

- **Atomicity**: gating npm publish on `gh release create` success means the GitHub Release is always the source of truth. An npm package without a corresponding GitHub Release cannot exist.
- **Zero new tooling**: uses existing GitHub Actions primitives (`actions/checkout`, `setup-node`, `softprops/action-gh-release` or `gh` CLI) and `yarn workspace` scripts already in the monorepo.
- **Pure JS, no matrix build**: `@octocodeai/pi-extension` has no native compilation — one runner, one artifact, no cross-platform matrix (unlike `octocode-engine`).
- **`dist/` is already self-contained**: the build script (`scripts/build.mjs`) produces a fully portable `dist/` with no external `node_modules` dependencies — zip-and-ship is safe.

### Alternatives Considered

#### Alternative A: Do nothing (npm-only, manual publish)

- **What**: Keep current flow. Human runs `yarn build && yarn workspace … npm publish` locally.
- **Pros**: Zero setup cost.
- **Cons**: Build drift risk (publish without fresh build), no artifact trail, no changelog, no offline install path, no update signal for users.
- **Why not chosen**: The risks compound with each release and become harder to retroactively fix.

#### Alternative B: GitHub Packages as npm mirror

- **What**: Publish to both `registry.npmjs.org` and `npm.pkg.github.com`.
- **Evidence**: GitHub Packages supports scoped npm packages; used by e.g. `actions/toolkit`.
- **Pros**: Keeps everything on GitHub.
- **Cons**: GitHub Packages requires auth even for public reads — users need a GitHub token in `.npmrc` to install. Breaks `pi install npm:@octocodeai/pi-extension` which uses the public npm registry. Adds maintenance burden for two registries.
- **Why not chosen**: User friction increase outweighs any benefit.

#### Alternative C: Release workflow only, no bootstrap script

- **What**: Ship only the CI/CD automation (G1–G4), defer the bootstrap script and update checker indefinitely.
- **Pros**: Smaller scope, faster to ship.
- **Cons**: Doesn't close the offline-install user story. GitHub Release artifacts exist but are undiscoverable without the script.
- **Why not chosen**: The bootstrap script is ~25 lines with no new dependencies and directly unlocks the offline-install use case. It's the artifact's main user-facing value.

### Comparison Matrix

| Dimension | Proposed (B+A) | Alt A: do-nothing | Alt B: GH Packages | Alt C: CI only |
|-----------|---------------|-------------------|-------------------|---------------|
| Automation | ✅ Full | ❌ None | ✅ Full | ✅ Full |
| Offline install | ✅ Via script | ❌ | ❌ (requires auth) | ⚠️ No script |
| Changelog | ✅ Auto-generated | ❌ | ✅ | ✅ |
| npm friction | None | None | ⬆️ auth required | None |
| Implementation cost | Low | Zero | Medium | Low |
| Maintenance | Low | Zero | Medium (2 registries) | Low |

### What If We Do Nothing?

Manual publish continues. Each release risks publishing a stale build. Users without npm access remain blocked. No changelog accumulates. The gap compounds as the project matures — harder to retroactively backfill release history.

---

## Prior Art

- `octocode-engine` uses a multi-platform matrix workflow for Rust/napi builds (`.github/workflows/ci.yml` includes `cargo audit`). This RFC's release workflow is simpler: single-platform, pure JS.
- Pi itself uses `pi install npm:<package>` as the install protocol (confirmed in `README.md:L8`), validating that npm remains the primary path.
- Standard GH Actions release pattern for npm packages: `actions/setup-node` with `registry-url: 'https://registry.npmjs.org'` + `NODE_AUTH_TOKEN`.

---

## Unresolved Questions

**Before acceptance:**
- [ ] **OQ-1**: Does `pi install <local-path>` copy files to a Pi-managed dir or store a reference? Determines bootstrap script cleanup strategy. → Close in `IMPLEMENTATION.md`.
- [ ] **OQ-2**: Is `NODE_AUTH_TOKEN` / `NPM_TOKEN` already a GitHub secret in `bgauryy/octocode-mcp`? → Close in `IMPLEMENTATION.md`.

**During implementation:**
- [ ] **OQ-3**: Should the workflow also update `CHANGELOG.md` in the repo, or is the GitHub Release UI sufficient?
- [ ] **OQ-4**: Phase 1 version bump is manual (human bumps `package.json`, tags, pushes). Is that acceptable or should a `release:bump` script be added?

**Out of scope / deferred:**
- [ ] Update checker (G5): defer until ≥2 release tags exist in the wild — needs a "latest" to compare against.

---

## Future Possibilities

- **Automated version bump**: a `yarn release:patch|minor|major` script that bumps `package.json`, commits, tags, and pushes — fully automated end-to-end.
- **Pi install from URL**: if Pi adds `pi install https://…/pi-extension-latest.zip`, the GitHub Release asset URL becomes the install target directly.
- **Update checker (G5)**: fire-and-forget background check in `src/index.js`; 24h cache to stay within GitHub API rate limits. Design is in §Reference-Level.
- **Granular skill releases**: zip individual skills as named assets for selective updates — revisit if `dist/` exceeds 10 MB or skill update frequency justifies it.
