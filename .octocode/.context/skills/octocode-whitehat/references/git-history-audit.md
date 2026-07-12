# Git History & Package Audit

Load when: (a) starting a security investigation from a **package name** rather than local files, or (b) using **git/PR history** as a threat-hunting surface.

**Fix for:** skill had no entry path for "is this package safe?" starting point, and no guidance on commit history as an attack surface (secrets committed and deleted, malicious code added then reverted).

---

## A. Package Audit Entry Path

When starting from a package name (npm, pip, cargo, gem) rather than local source:

```bash
# Step 1: resolve package → source repo + metadata
npx octocode search <package-name> --target packages
# → returns: source repo (owner/repo), version, description, dependencies, weekly downloads

# Step 2: orient the repo structure
npx octocode search <owner/repo> --tree --depth 1

# Step 3: check install hooks in package manifest
npx octocode search <owner/repo>/package.json --content-view exact   # npm
npx octocode search <owner/repo>/setup.py --content-view exact        # pip
npx octocode search <owner/repo>/build.rs --content-view exact        # cargo
npx octocode search <owner/repo>/Gemfile --content-view exact         # gem

# Step 4: search for dangerous patterns in source
npx octocode search "eval|exec|subprocess|fetch|http.request" <owner/repo>

# Step 5: check recent commits for suspicious changes
npx octocode search <owner/repo> --target commits --limit 20

# Step 6: clone locally for deep analysis
npx octocode tools ghCloneRepo --queries '{"repo":"<owner/repo>"}'
# → then run local analysis on returned localPath
```

**Red flags in package metadata:** very new package with high download counts; name similar to a popular package (typosquatting); maintainer with <5 public repos; version bump with no changelog.

---

## B. Git History as an Attack Surface

Attackers frequently commit malicious code then revert it to hide it from the final diff. Secrets committed and deleted still exist in git history. Always check history for high-risk targets.

### Recent commit scan

```bash
# View recent commits on a repo
npx octocode search <owner/repo> --target commits --limit 50

# Narrow to commits touching sensitive paths
npx octocode search <owner/repo>/src --target commits --since 2024-01-01T00:00:00Z

# Read a specific commit's diff
npx octocode search <owner/repo>@<sha> --target diff
```

### PR history (supply chain signal)

```bash
# Recent PRs — look for: external contributor + postinstall change, dependency bump without review
npx octocode search <owner/repo> --target pullRequests --limit 30

# Read a specific PR's full diff
npx octocode search <owner/repo>#<N> --target pullRequests --comments
```

### What to look for in commit history

| Signal | What it means |
| ------ | ------------- |
| Secret added in commit X, deleted in commit X+1 | Secret still in history; may still be valid |
| `postinstall` / `setup.py` changes | Possible supply chain insertion point |
| Binary blob added (`.node`, `.wasm`, `.zip`) | Suspicious — binaries don't belong in most repos |
| Dependency version pinned to exact hash then unpinned | Could be a lockfile poisoning attempt |
| Maintainer changed (`package.json` `author` field modified) | Account compromise or hostile takeover |
| Large code deletion followed by "cleanup" commit | Could be covering tracks |

### Comparing Two Package Versions

When a new version of a dependency looks suspicious:

```bash
# Step 1: diff two versions of a file
npx octocode search <owner/repo>/package.json@v1.2.3 <owner/repo>/package.json@v1.2.4 --target diff

# Step 2: look for new install scripts, new network calls, new binary blobs in the diff

# Step 3: compare dependency lists
npx octocode search <owner/repo>/package-lock.json --content-view exact --match-string "postinstall"

# Step 4: search the new version for patterns not in the prior version
npx octocode search "eval|exec|fetch|http" <owner/repo>@v1.2.4
```

**Key delta indicators:** new `postinstall`/`prepare` script not in previous version; new `dependencies` entry that itself has install scripts; new binary file not present before; network endpoint that didn't appear in previous version.
