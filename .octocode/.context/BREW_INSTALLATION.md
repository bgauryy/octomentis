# Homebrew Release Runbook — `octocode`

How to ship the `octocode` CLI via Homebrew. **Released — `octocode@1.5.0` is live** (npm +
tap published and verified 2026-06-03). The steps below are now the reference for the next
release; see the [Status](#status) table for the current state.

End-user install (once published):

```sh
brew install bgauryy/octocode/octocode    # resolves to repo bgauryy/homebrew-octocode
octocode --version                        # → octocode v1.5.0
```

---

## Status

| Item | State |
|------|-------|
| `package.json` `bin` → `{ "octocode": "./out/octocode-cli.js" }` | ✅ done |
| Command renamed `octocode-cli` → `octocode` (CLI, help, version, docs) | ✅ done |
| Tap repo `bgauryy/homebrew-octocode` + local clone `~/Documents/homebrew-octocode` | ✅ created |
| `Formula/octocode.rb` + `README.md` + `scripts/update-formula.sh` | ✅ committed (1 commit ahead) |
| Install mechanics (offline `brew install` + symlink + `brew test`) | ✅ validated — see [Appendix](#appendix--why-this-works) |
| **1. Publish to npm** | ✅ done — `octocode-cli@1.5.0` live on npm |
| **2. Fill sha256 + push tap** | ✅ done — `bgauryy/homebrew-octocode@de08bd0`, sha256 `c530d380…47a6` |
| **3. Verified live** | ✅ `brew install bgauryy/octocode/octocode` + `brew test` pass, `octocode v1.5.0` (2026-06-03) |

---

## Release steps

The formula installs from the **npm registry tarball**, so npm must be published first.

### 1. Publish to npm (as `bgauryy`)

```sh
cd packages/octocode-cli
yarn verify          # lint + typecheck + tests + registry/skills validation
yarn build           # bundles out/
npm whoami           # expect: bgauryy
npm publish
```

### 2. Fill sha256 + push the tap

> `gh` here is `guybary-wix` (READ-only on the tap). Pushing needs `bgauryy` push access —
> switch account or use a `bgauryy` token/SSH key.

```sh
cd ~/Documents/homebrew-octocode
./scripts/update-formula.sh 1.5.0    # fetches the published tarball, writes url + real sha256
brew style Formula/octocode.rb       # clean once the real sha256 is in place
git commit -am "octocode 1.5.0"
git push
```

### 3. Verify the live release

```sh
brew update
brew install bgauryy/octocode/octocode
brew test octocode
octocode --version                   # → octocode v1.5.0
```

---

## Formula (`Formula/octocode.rb`)

```ruby
require "language/node"

class Octocode < Formula
  desc "Interactive CLI installer for octocode-mcp — MCP server & skills setup"
  homepage "https://octocode.ai"
  url "https://registry.npmjs.org/octocode-cli/-/octocode-cli-1.5.0.tgz"
  sha256 "REPLACE_WITH_PUBLISHED_TARBALL_SHA256"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]   # exposes the `octocode` command
  end

  test do
    assert_match "octocode v#{version}", shell_output("#{bin}/octocode --version")
  end
end
```

- **Each release:** bump `url` (version in the filename) + `sha256`. Nothing else.
- **Do not add a `version` line** — Homebrew parses it from the URL; an explicit one trips
  `brew audit` as "redundant".

---

## Optional: re-validate locally before publishing

Reproduces the offline end-to-end install without touching npm (uses a local tarball):

```sh
# build + pack the local CLI
cd packages/octocode-cli && yarn build
TGZ="$PWD/$(npm pack | tail -1)"
SHA=$(shasum -a 256 "$TGZ" | awk '{print $1}')

# tap the local clone, then point the TAPPED copy at the local tarball:
brew tap bgauryy/octocode ~/Documents/homebrew-octocode
#   edit /opt/homebrew/Library/Taps/bgauryy/homebrew-octocode/Formula/octocode.rb:
#   set  url "file://$TGZ" , add  version "1.5.0" , set sha256 "$SHA"
brew install --build-from-source bgauryy/octocode/octocode
octocode --version && brew test octocode

# cleanup
brew uninstall octocode
brew untap bgauryy/octocode
git -C ~/Documents/homebrew-octocode checkout -- Formula/octocode.rb
rm -f octocode-cli-*.tgz
```

> For the local `file://` formula you must add an explicit `version "1.5.0"` (no version is
> parseable from a `file://` path) — the **published** formula must not have one.

---

## Appendix — why this works

Validated three independent ways. **Confidence: high.**

**1. Real offline install (2026-06-03).** Built local 1.5.0 → `npm pack` → `file://` formula
→ `brew install`. Confirmed: installs with no network (zero runtime deps), symlinks
`/opt/homebrew/bin/octocode` → `libexec/bin/octocode` (npm package lands at
`node_modules/octocode-cli/`, **command is `octocode`**), `--version`/`--help`/real tool exec
work, and `brew test` passes.

**2. Matches 273 homebrew-core formulae** using `std_npm_args` + `registry.npmjs.org` +
`bin.install_symlink`:

| Formula | Why it matters |
|---------|----------------|
| [`openskills.rb`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/o/openskills.rb) | **Byte-identical** line: `bin.install_symlink Dir["#{libexec}/bin/*"]` |
| [`prettier.rb`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/p/prettier.rb) | Reference model — bundled npm CLI, `depends_on "node"`, no `version`, functional test |
| [`basedpyright.rb`](https://github.com/Homebrew/homebrew-core/blob/master/Formula/b/basedpyright.rb) | Proves command renaming via `… => "basedpyright"` |
| [`iflow-ai/iflow-cli`](https://github.com/iflow-ai/iflow-cli/blob/main/Formula/iflow-cli.rb) · [`0Chord/homebrew-cbit`](https://github.com/0Chord/homebrew-cbit) | Personal-tap templates (cbit = single-formula tap, our shape) |

**3. Conforms to the Homebrew docs**, checked against our build:

| Requirement | Our setup |
|---|---|
| Deps **must** be bundled in the tarball (else the sandboxed `npm install` hits the network → fails) | esbuild bundle, `dependencies: NONE` ✅ |
| `package.json` `bin` must exist or nothing symlinks | `bin: {"octocode": …}` ✅ |
| `depends_on "node"` as a **runtime** dep (not `:build`) | yes ✅ |
| No `version` line / no `bottle do` for a personal tap | neither present ✅ |
| Repo `homebrew-octocode`, `Formula/octocode.rb`, `class Octocode` | all correct ✅ |
| `brew audit --strict/--online` only gates homebrew-core, not personal taps | tap just needs install + test ✅ |

**Risks to keep true**
1. **The published tarball must stay bundled with zero unbundled `dependencies`** — this is *the*
   failure mode for `language/node` formulae. True today; **re-confirm after any dependency change.**
2. The only untested delta is registry-URL vs `file://` fetch — identical install mechanics,
   proven by the 273 core formulae. Low risk.
3. Pure-JS bundle (no native addons) → resilient to Node major-version churn.

**Sources:** [Node for Formula Authors](https://docs.brew.sh/Node-for-Formula-Authors) ·
[Formula Cookbook](https://docs.brew.sh/Formula-Cookbook) ·
[How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
