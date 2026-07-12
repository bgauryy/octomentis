# CI/CD Pipeline Security

Load when auditing CI/CD pipeline files: GitHub Actions, Jenkinsfile, CircleCI, GitLab CI, Bitbucket Pipelines.

**Fix for:** no prior reference covered `.github/workflows/*.yml`, `run:` command injection, or compromised third-party actions. Added to Quick Triage item 3 in SKILL.md.

---

## GitHub Actions

### Find all workflow files

```bash
npx octocode search <path> --search path --name '*.yml' --ext yml
npx octocode search <path> --tree --depth 3        # look for .github/workflows/
npx octocode search <owner/repo>/.github/workflows --tree --depth 1  # remote
```

### Critical attack patterns

**1. Expression injection in `run:` steps**
```bash
# ${{ github.event.* }} in run: = command injection from PR title/body/branch name
npx octocode search 'github\.event\.pull_request\|github\.event\.issue\|github\.event\.comment' <path>
npx octocode search 'run:.*\${{' <path>   # inline expression in shell command
```

**2. Untrusted `pull_request_target` with code checkout**
```bash
# pull_request_target has write access; checking out PR code is dangerous
npx octocode search 'pull_request_target' <path>
npx octocode search 'actions/checkout.*ref.*head' <path>   # checking out untrusted ref
```

**3. Secrets printed to logs**
```bash
npx octocode search 'echo.*\${{ secrets\.' <path>
npx octocode search 'run:.*cat.*\.env\|run:.*printenv\|run:.*env' <path>
```

**4. Third-party actions pinned by tag (not commit SHA)**
```bash
# Tag-pinned actions can be updated to point to malicious code
npx octocode search 'uses: [^@]+@v[0-9]' <path>      # @v1, @v2, @main — not a SHA
npx octocode search 'uses: [^@]+@main' <path>         # mutable branch reference
```

**5. Self-hosted runners with broad access**
```bash
npx octocode search 'runs-on: self-hosted' <path>     # check what permissions they have
```

**6. `GITHUB_TOKEN` with write permissions used in PR context**
```bash
npx octocode search 'permissions:.*write\|write-all' <path>
npx octocode search 'GITHUB_TOKEN' <path>
```

---

## Jenkinsfile / Jenkins Pipelines

```bash
# Find Jenkinsfiles
npx octocode search <path> --search path --name 'Jenkinsfile'

# Groovy eval/execute — can run arbitrary code
npx octocode search 'evaluate\|execute\|Runtime\.exec\|Process' <path> --include 'Jenkinsfile'

# Credentials fetched and possibly leaked
npx octocode search 'withCredentials\|credentialsId' <path> --include 'Jenkinsfile'

# sh/bat steps with interpolated user input
npx octocode search "sh '.*\\$\\{" <path> --include 'Jenkinsfile'
```

---

## CircleCI / GitLab CI / Bitbucket

```bash
# Find config files
npx octocode search <path> --search path --name '.circleci'
npx octocode search <path> --search path --name '.gitlab-ci.yml'
npx octocode search <path> --search path --name 'bitbucket-pipelines.yml'

# Secrets in environment variables (printed or used unsafely)
npx octocode search 'echo \$[A-Z_]+\|printenv\|env | grep' <path>

# External script fetched and executed — curl | sh pattern
npx octocode search 'curl.*\|\s*sh\|wget.*\|\s*bash\|curl.*\|\s*bash' <path>
```

---

## Supply Chain via Third-Party Actions

| Risk | Pattern | Mitigation signal |
| ---- | ------- | ----------------- |
| Mutable tag reference | `uses: actions/checkout@v3` | Pin to full SHA: `uses: actions/checkout@a81bbbf...` |
| Unverified publisher | `uses: random-user/action@main` | Look up on GitHub Marketplace; check stars/commits |
| Action with broad `env` access | Action code does `process.env` or reads `${{ secrets.* }}` | Inspect the action's source repo |
| Workflow writes to PR and reads PR content | `pull_request_target` + `github.event.pull_request` | Classic PWNED pattern |

```bash
# Check all action references in a repo
npx octocode search 'uses: ' <path> --include '*.yml' --only-matching
```

---

## Detection Matrix for CI/CD

| Attack class | Indicator |
| ------------ | --------- |
| Inject via PR content | `github.event.pull_request.*` in `run:` |
| Exfiltrate secrets | `echo ${{ secrets.* }}`, `curl` with `$SECRET` in URL/body |
| Poison the cache | Cache restore + manipulated cache key |
| Mutable action compromise | Tag/branch reference (`@v1`, `@main`) instead of full SHA |
| Self-hosted runner abuse | `runs-on: self-hosted` with access to network/credentials |
| Supply chain via deps | `npm install`/`pip install` in CI triggers malicious postinstall |
