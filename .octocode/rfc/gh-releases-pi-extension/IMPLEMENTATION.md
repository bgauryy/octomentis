# Implementation: GitHub Releases for @octocodeai/pi-extension

> Decision: see `RFC.md` §Summary and §Rationale. This file does not restate goals — it references them.

---

## Resolved Questions (were open in RFC.md)

| Open question (RFC §) | Resolution | Evidence | Confidence |
|---|---|---|---|
| **OQ-1** — Does `pi install <local-path>` copy files or store a reference? | **Stores a reference.** Pi adds the absolute path to `settings.json` without copying. If the source path is deleted (e.g., `mktemp` cleanup), the install breaks. Bootstrap script MUST copy `dist/` to a persistent dir before calling `pi install`. | `packages.md`: "Local paths point to files or directories on disk and are **added to settings without copying**." — `/Users/guybary/.nvm/.../pi-coding-agent/docs/packages.md` | confirmed |
| **OQ-2** — Is `NODE_AUTH_TOKEN` / `NPM_TOKEN` a configured GitHub secret? | **Not configured.** The workflows README explicitly states: "npm publishing… are manual." No existing workflow contains `NODE_AUTH_TOKEN` or `npm publish`. Must be added to repo secrets before the release workflow can publish. | `.github/workflows/README.md:L11`: "npm publishing, Homebrew tap updates, and standalone binary uploads are manual." | confirmed |
| **OQ-3** — CHANGELOG.md in repo vs GitHub Release UI only? | GitHub Release UI (`--generate-notes`) is sufficient for this project. No `CHANGELOG.md` is maintained today; adding one is a separate concern. Deferred. | Absence of `CHANGELOG.md` in repo root confirmed by `ls`. | confirmed |
| **OQ-4** — Is manual version bump acceptable or should `release:bump` be added? | Manual version bump is acceptable for Phase 1. A `release:bump` script (using `npm version patch|minor|major`) can be added in Phase 2 without changing the workflow. | Design decision — risk is low; version bump is infrequent and already human-gated. | likely |

---

## Approach

Implement RFC.md §Rationale "Why This Design?": a tag-triggered GitHub Actions workflow (`release.yml`) that builds → zips `dist/` → creates a GitHub Release with artifact → publishes npm. Complement with a bootstrap script that installs from the release asset without npm. Implementation is pure additions (new workflow file, new script) with no changes to existing code paths.

---

## Steps (dependency-ordered)

### Phase 1 — Release pipeline (G1, G2, G4)

#### Step 1.1 — Add `NPM_TOKEN` to GitHub repository secrets

**Manual action** (done by repo admin, not code):

1. Go to `npmjs.com` → account → Access Tokens → Generate New Token → Automation type.
2. Copy the token.
3. Go to `github.com/bgauryy/octocode-mcp` → Settings → Secrets and variables → Actions → New repository secret.
4. Name: `NPM_TOKEN`, value: token from step 2.

**Verify**: `gh secret list --repo bgauryy/octocode-mcp` shows `NPM_TOKEN`.

#### Step 1.2 — Create `.github/workflows/release.yml`

New file (does not exist today — `.github/workflows/` contains only `ci.yml`):

```yaml
name: Release — pi-extension

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write   # needed to create GitHub Release and attach assets

jobs:
  release:
    name: Build, Release, Publish
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v5

      - name: Setup Node.js
        uses: actions/setup-node@v5
        with:
          node-version: '20'
          cache: 'yarn'
          registry-url: 'https://registry.npmjs.org'

      - name: Enable Corepack
        run: corepack enable

      - name: Install dependencies
        run: yarn install --immutable

      - name: Validate tag matches package.json version
        run: |
          TAG="${{ github.ref_name }}"
          PKG_VERSION="v$(node -p "require('./packages/octocode-pi-extension/package.json').version")"
          if [ "$TAG" != "$PKG_VERSION" ]; then
            echo "❌ Tag $TAG does not match package.json version $PKG_VERSION" >&2
            exit 1
          fi
          echo "✓ Tag $TAG matches package.json version"

      - name: Build extension
        run: yarn workspace @octocodeai/pi-extension build

      - name: Create release zip
        run: |
          TAG="${{ github.ref_name }}"
          cd packages/octocode-pi-extension
          zip -r "../../pi-extension-${TAG}.zip" dist/
          echo "ASSET_NAME=pi-extension-${TAG}.zip" >> $GITHUB_ENV

      - name: Create GitHub Release and attach artifact
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh release create "${{ github.ref_name }}" \
            "pi-extension-${{ github.ref_name }}.zip" \
            --title "${{ github.ref_name }}" \
            --generate-notes

      - name: Publish to npm
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
        run: yarn workspace @octocodeai/pi-extension npm publish
```

**Key design points:**
- `permissions: contents: write` is required for `gh release create`.
- Tag-version validation runs **before** the build — fail fast if the human forgot to bump `package.json`.
- npm publish runs **after** `gh release create` — the release artifact is the gate. A publish without an artifact cannot happen.
- `--generate-notes` produces a changelog from PR titles merged since the previous tag.
- No Rust toolchain step — `@octocodeai/pi-extension` is pure JS. (cf. `ci.yml` which needs Rust for `octocode-engine`.)
- `registry-url` in `setup-node` writes a `.npmrc` that wires `NODE_AUTH_TOKEN` → auth automatically.

#### Step 1.3 — Update `.github/workflows/README.md`

Change the "Manual Releases" section to document the new automated flow:

```diff
-## Manual Releases
-npm publishing, Homebrew tap updates, and standalone binary uploads are manual.
-Use the Release Guide for the current release order and verification checklist.
+## Releases
+
+| Workflow | Trigger | Purpose |
+|---|---|---|
+| `release.yml` | Push `v*` tag | Build pi-extension, create GitHub Release, attach zip, publish npm |
+
+### pi-extension release flow
+1. Bump `version` in `packages/octocode-pi-extension/package.json`.
+2. Commit and push. Then:
+   ```bash
+   git tag v<version>
+   git push origin v<version>
+   ```
+3. The workflow validates tag == package.json version, builds, creates the GitHub Release, and publishes npm.
+
+Other releases (Homebrew tap, standalone binaries) remain manual — see the Release Guide.
```

---

### Phase 2 — Bootstrap script (G3) — depends on Phase 1 (release asset must exist)

#### Step 2.1 — Create `packages/octocode-pi-extension/scripts/install.sh`

**Critical constraint from OQ-1**: Pi stores local paths as references. The script MUST copy `dist/` to a persistent directory (`~/.octocode/extensions/pi-extension/`) before calling `pi install`, or the extension will break if the temp dir is cleaned.

```bash
#!/usr/bin/env bash
# install.sh — install @octocodeai/pi-extension from the latest GitHub Release
# Usage: curl -fsSL https://raw.githubusercontent.com/bgauryy/octocode-mcp/main/packages/octocode-pi-extension/scripts/install.sh | bash

set -euo pipefail

REPO="bgauryy/octocode-mcp"
ASSET_PREFIX="pi-extension-"
INSTALL_DIR="${HOME}/.octocode/extensions/pi-extension"

# -- Prerequisites --
if ! command -v pi &>/dev/null; then
  echo "❌ 'pi' is not in PATH. Install it first: https://pi.dev" >&2
  exit 1
fi
if ! command -v curl &>/dev/null; then
  echo "❌ 'curl' is required." >&2
  exit 1
fi
if ! command -v unzip &>/dev/null; then
  echo "❌ 'unzip' is required." >&2
  exit 1
fi

# -- Fetch latest tag --
echo "→ Fetching latest release..."
LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\(.*\)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "❌ Could not determine latest release tag (API rate limit or network error)." >&2
  exit 1
fi
echo "  Latest: $LATEST"

# -- Download zip --
TMPDIR_DL=$(mktemp -d)
trap 'rm -rf "$TMPDIR_DL"' EXIT

ZIP_URL="https://github.com/${REPO}/releases/download/${LATEST}/${ASSET_PREFIX}${LATEST}.zip"
echo "→ Downloading $ZIP_URL..."
curl -fsSL -o "$TMPDIR_DL/pi-extension.zip" "$ZIP_URL"

# -- Extract --
echo "→ Extracting..."
unzip -q "$TMPDIR_DL/pi-extension.zip" -d "$TMPDIR_DL"

# -- Copy to persistent location (OQ-1: pi stores local paths as references, never copies) --
echo "→ Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"
cp -r "$TMPDIR_DL/dist" "$INSTALL_DIR"

# -- Register with Pi --
pi install "$INSTALL_DIR/index.js"

echo ""
echo "✓ @octocodeai/pi-extension $LATEST installed"
echo "  Persistent dir: $INSTALL_DIR"
echo "  Run /octocode-status in pi to verify."
```

**Verify**: `bash packages/octocode-pi-extension/scripts/install.sh` on macOS and Ubuntu.

#### Step 2.2 — Add bootstrap one-liner to README.md

In `packages/octocode-pi-extension/README.md`, update the Setup section to add the npm-free path:

```diff
 ## Setup

 ```bash
 pi install npm:@octocodeai/pi-extension
+# or, without npm:
+curl -fsSL https://raw.githubusercontent.com/bgauryy/octocode-mcp/main/packages/octocode-pi-extension/scripts/install.sh | bash
 ```
```

---

### Phase 3 — Update checker (G5) — depends on Phase 1 (≥2 release tags required)

Defer until at least two release tags exist in the wild. Design is captured in `RFC.md §Reference-Level Explanation`.

Implementation when triggered:
- Add `PACKAGE_VERSION` injection to `scripts/build.mjs` (write current `package.json` version into `dist/index.js` as a constant at build time).
- Add `checkForUpdate()` fire-and-forget call in `src/index.js` `resources_discover` handler.
- Cache result to `~/.octocode/pi-extension-update-check.json` (24h TTL) to respect GitHub's 60 req/hour unauthenticated rate limit.

---

## Files / APIs / Contracts Touched

| File | Change | Blast radius |
|---|---|---|
| `.github/workflows/release.yml` | New file | Triggers only on `v*` tags — no effect on PR CI |
| `.github/workflows/README.md` | Update Manual Releases section | Documentation only |
| `packages/octocode-pi-extension/scripts/install.sh` | New file | No callers; user-invoked script |
| `packages/octocode-pi-extension/README.md` | Add one-liner to Setup section | Documentation only |
| `packages/octocode-pi-extension/package.json` | No change in Phase 1-2 | — |
| `packages/octocode-pi-extension/src/index.js` | Phase 3 only: add `checkForUpdate()` | Additive; fire-and-forget; never blocks |

No existing tool runners, extension handlers, or npm-published contracts change in Phase 1–2.

---

## Risk Mitigations

Traces to `RFC.md §Drawbacks / §Pre-mortem`:

| Risk | Mitigation |
|---|---|
| NPM_TOKEN expired; release succeeds but npm publish fails | GH Release artifact exists as proof of build. Re-trigger by re-pushing the tag after rotating the secret. Workflow step exits non-zero visibly. |
| Tag pushed without bumping package.json | Step 1.2 includes explicit tag-version validation before build — fails fast with a clear error message. |
| Pi loses bootstrap install path (temp dir) | OQ-1 resolved: script copies to `~/.octocode/extensions/pi-extension/` before `pi install`. |
| Duplicate tag pushed (re-run) | `gh release create` fails on duplicate tag with a non-zero exit — the workflow stops before npm publish. Resolve by deleting and recreating the tag. |
| GitHub API rate limit in bootstrap script | Script exits with a clear error message. Users can retry or install via `pi install npm:@octocodeai/pi-extension`. |

---

## Test and Verification Plan (V&V)

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Manual — workflow | Tag-version validation | Push a tag where tag ≠ package.json version; assert workflow fails at validation step | `git tag v99.99.99 && git push origin v99.99.99` |
| Manual — workflow | Happy path | Bump version, push tag matching package.json; assert GitHub Release appears with zip asset and npm shows new version | Full release run |
| Manual — bootstrap | OQ-1 compliance | Run `install.sh`, then delete `~/.octocode/extensions/pi-extension/`; restart pi; confirm extension fails to load (then re-install) | `bash scripts/install.sh` |
| Manual — bootstrap | Persistent install | Run `install.sh`, start new pi session, run `/octocode-status`; confirm extension loaded | Interactive |
| Automated — existing | No regression to ci.yml | Existing `yarn test` and `yarn lint` unchanged | `yarn workspace @octocodeai/pi-extension test` |

---

## Rollout / Migration / Rollback

**Sequencing:**
1. Add `NPM_TOKEN` secret (Step 1.1) — prerequisite, no code change.
2. Merge `release.yml` (Step 1.2) to `main` — workflow is inert until a `v*` tag is pushed.
3. Merge README and workflow docs update (Step 1.3).
4. Cut the first automated release: bump `package.json` version, push tag. Observe workflow.
5. Merge `install.sh` (Step 2.1) after first release exists (asset URL must exist for the script to work).
6. Merge README one-liner (Step 2.2).

**Flags / gating:** None. The workflow only fires on `v*` tags. `main`-branch pushes are unaffected.

**Rollback trigger:** If npm publish produces a broken package, run `npm deprecate @octocodeai/pi-extension@<version> "bad release"` manually and cut a patch release.

**Rollback of workflow:** Delete or rename `release.yml`; revert to manual publish. Zero user impact — npm continues working.

**Owner / approver:** Guy Bary (repo maintainer).

---

## References

- `packages/octocode-pi-extension/package.json` — version field, `pi` manifest, `scripts.build`
- `.github/workflows/ci.yml` — existing workflow pattern (setup-node, corepack, yarn install --immutable)
- `.github/workflows/README.md:L11` — confirms npm publish is currently manual (OQ-2 resolution)
- `/Users/guybary/.nvm/.../pi-coding-agent/docs/packages.md` — "Local paths… added to settings without copying" (OQ-1 resolution)
- `packages/octocode-pi-extension/scripts/build.mjs` — confirms `node scripts/build.mjs` is the build entrypoint
- `packages/octocode-pi-extension/README.md:L8` — confirms `pi install npm:@octocodeai/pi-extension` is the canonical install command
