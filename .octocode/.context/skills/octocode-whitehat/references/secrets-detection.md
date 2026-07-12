# Secrets Detection

Load when scanning for hardcoded credentials, API keys, tokens, or private keys. "Scan for secrets" is in the description but was only covered by buried regex in `advanced-threat-patterns.md §10`.

**Fix for:** secrets detection was not a first-class concern with actionable commands. This reference provides a format-specific regex bank and a systematic detection flow.

---

## Detection Flow

```bash
# 1. Broad entropy/pattern sweep (files-only first)
npx octocode search 'AKIA[0-9A-Z]{16}\|ghp_[A-Za-z0-9]{36}\|sk-proj-\|sk_live_\|AIza' <path> --files-only

# 2. Full match with context
npx octocode search 'AKIA[0-9A-Z]{16}' <path>        # AWS access key
npx octocode search 'ghp_[A-Za-z0-9]{36}' <path>     # GitHub personal access token
npx octocode search 'sk-proj-[A-Za-z0-9]{48}' <path> # OpenAI project key
npx octocode search 'sk_live_[A-Za-z0-9]{24}' <path> # Stripe live key
npx octocode search 'AIza[0-9A-Za-z\-_]{35}' <path>  # Google API key

# 3. Check all env/config files for any secrets
npx octocode search <path> --search path --name '*.env*'
npx octocode search <path> --search path --name '.env'
npx octocode search <path> --search path --name 'credentials*'
npx octocode search <path> --search path --name '*secret*'
```

---

## Secret Format Regex Bank

| Secret type | Pattern | Notes |
| ----------- | ------- | ----- |
| AWS access key | `AKIA[0-9A-Z]{16}` | Also `ASIA` (temp), `AROA` (role) |
| AWS secret key | `[A-Za-z0-9/+=]{40}` near `aws_secret` | Context-dependent |
| GitHub PAT | `ghp_[A-Za-z0-9]{36}` | Also `ghs_`, `gho_`, `ghu_`, `github_pat_` |
| GitHub Actions token | `ghs_[A-Za-z0-9]{36}` | Short-lived but still dangerous in logs |
| OpenAI key | `sk-proj-[A-Za-z0-9_-]{48}` | Old format: `sk-[A-Za-z0-9]{48}` |
| Anthropic key | `sk-ant-[A-Za-z0-9_-]{95}` | |
| Stripe live key | `sk_live_[A-Za-z0-9]{24}` | Also `rk_live_` (restricted) |
| Stripe test key | `sk_test_[A-Za-z0-9]{24}` | Still reveals key format |
| Google API key | `AIza[0-9A-Za-z\-_]{35}` | |
| Slack webhook | `https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/` | |
| Slack token | `xoxb-[0-9]{11}-[0-9]{11}-[A-Za-z0-9]{24}` | Bot tokens |
| Discord bot token | `[MN][A-Za-z0-9_-]{23}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27}` | |
| Private key (PEM) | `-----BEGIN (RSA\|EC\|PRIVATE) KEY-----` | |
| JWT secret | `[A-Za-z0-9+/=]{32,}` near `jwt_secret\|JWT_SECRET` | |
| Database URL | `(postgres\|mysql\|mongodb)\|://[^:]+:[^@]+@` | Password in connection string |
| Generic high entropy | `[A-Za-z0-9+/=]{32,64}` assigned to `.*key.*\|.*secret.*\|.*token.*\|.*pass` | |

```bash
# Run the full bank in one pass (comma-separated --files-only first):
npx octocode search 'AKIA[0-9A-Z]{16}' <path> --files-only
npx octocode search 'BEGIN (RSA|EC|PRIVATE) KEY' <path>
npx octocode search '(postgres|mysql|mongodb)://[^:]+:[^@]+@' <path>
npx octocode search 'xoxb-[0-9]' <path>
npx octocode search 'hooks\.slack\.com/services' <path>
```

---

## Common Hiding Spots

| Location | Why dangerous | `npx octocode` command |
| -------- | ------------- | ---------------------- |
| `.env` files | Committed by accident | `search <path> --search path --name '.env'` |
| Config JSON/YAML | Credentials in settings | `search 'password\|secret\|api_key' <path> --include '*.json,*.yaml,*.yml'` |
| Test files | "Dummy" creds that are real | `search 'AKIA\|ghp_\|sk_live_' <path> --include '*.test.*,*.spec.*'` |
| Git history | Committed then deleted | See `git-history-audit.md` |
| Log output | `console.log(process.env)` | `search 'console\.log.*env\|print.*secret\|log\.info.*token' <path>` |
| Comments | "old key: sk-..." | `search 'sk-\|AKIA\|token:' <path>` |
| Minified bundles | Inline after bundling | `search 'AKIA\|ghp_' <path> --include '*.min.js,*.bundle.*'` |

---

## False Positive Reduction

- **Test fixtures:** prefix or suffix `_test`, `_example`, `_placeholder`, `test123` — inspect context.
- **Non-secret high-entropy strings:** base64-encoded non-credential data (image data, hashes) — check assignment variable name.
- **Expired keys:** AWS/GitHub keys can be validated against the issuer's format check API if escalating to `high` or `critical`.
- **Threshold for escalation:** a secret with a recognizable format (e.g. `AKIA...`) warrants `high` even without confirmed live status. A generic high-entropy string near `secret` warrants `likely`.
