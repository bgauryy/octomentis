## Releasing (maintainers)

Publishing a new version is two steps: publish to **npm**, then point the
**Homebrew** formula at the new tarball. The Homebrew formula installs from the
published npm tarball, so npm must go first.

### 1. Publish to npm

```bash
cd packages/octocode-cli
yarn verify          # lint + typecheck + tests + registry/skills validation
yarn build           # produces out/ (bundled CLI)
npm publish          # publish as the npm user `bgauryy`
```

> The package declares `"bin": { "octocode": "..." }`, so both
> `npm i -g octocode-cli` and Homebrew expose the command as **`octocode`**.

### 2. Publish to Homebrew

The tap lives at [`bgauryy/homebrew-octocode`](https://github.com/bgauryy/homebrew-octocode)
(local clone: `~/Documents/homebrew-octocode`). After the npm publish:

```bash
cd ~/Documents/homebrew-octocode

# Fetch the published tarball, compute its sha256, and rewrite url + sha256
# in Formula/octocode.rb. Pass the version, or omit to use npm's latest.
./scripts/update-formula.sh 1.5.0

# Validate, then commit & push (requires push access to bgauryy/homebrew-octocode)
brew style Formula/octocode.rb
git commit -am "octocode 1.5.0"
git push
```

To compute the sha256 manually instead:

```bash
curl -fsSL "https://registry.npmjs.org/octocode-cli/-/octocode-cli-1.5.0.tgz" | shasum -a 256
```

### 3. Verify the release

```bash
brew update
brew install --build-from-source bgauryy/octocode/octocode   # or: brew upgrade octocode
brew test octocode
octocode --version          # should print: octocode v1.5.0
```

> First-time tap setup only: create the public repo `bgauryy/homebrew-octocode`
> (the `homebrew-` prefix is required for `brew install bgauryy/octocode/octocode`
> to resolve), then push `Formula/octocode.rb`.
