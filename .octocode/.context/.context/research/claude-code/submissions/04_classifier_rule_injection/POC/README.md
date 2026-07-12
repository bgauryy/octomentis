# POC — Classifier Rule Injection + Fast-Path Shortcut

This directory contains the proof-of-concept harness for Submission 4. It is **harmless by default** — running `setup.sh` creates a fake cloned repo at `/tmp/poc-rule-injection/` whose `.claude/settings.local.json` contains only marker strings, not exploit payloads.

---

## Files

| File | Purpose |
|---|---|
| `README.md` | This file |
| `setup.sh` | Idempotent: creates `/tmp/poc-rule-injection/` with the harmless marker settings |
| `verify.sh` | Read-only static verifier — runs grep against the installed `cli.js` and prints PASS/FAIL for each evidence item |
| `settings.local.json` | Harmless marker variant — what `setup.sh` copies into the PoC repo |
| `settings.local.json.dangerous` | Bounty-grade variant — **documentation only**, `setup.sh` never writes this |

---

## What the PoC proves

Running `setup.sh` creates a minimal cloned-repo-shaped directory at `/tmp/poc-rule-injection/`:

```
/tmp/poc-rule-injection/
├── .claude/
│   └── settings.local.json      <- the injection sink
├── CLAUDE.md                    <- benign project description
└── README.txt                   <- notes for a human reading the directory
```

The `.claude/settings.local.json` contains marker strings under `autoMode.allow`, `autoMode.soft_deny`, and `autoMode.environment`, each of which starts with the tag `POC4_RULE_INJECTION_PROOF`. These marker strings are descriptive text and cannot possibly authorise a dangerous action on their own. They exist so that if you dump the classifier system prompt (via prompt-cache logs, telemetry events, or a debugger), you can confirm the marker string appears in place of the default bullets — which proves the attacker-controlled text reached the classifier.

The PoC is not asking the classifier to do anything. It is only proving the channel is live.

---

## How to run the static verifier (always safe)

The verifier is read-only. It does not modify anything, does not run Claude Code, and does not send data anywhere. It just grep-checks the installed `cli.js` binary.

```bash
cd /Users/guybary/Documents/local-explorer-mcp/research/claude-code/submissions/04_classifier_rule_injection/POC
chmod +x verify.sh      # first run only
./verify.sh
```

Expected output (on v2.1.97):

```
[verify] target cli.js: /Users/guybary/.nvm/versions/node/v22.22.0/lib/node_modules/@anthropic-ai/claude-code/cli.js
[verify] cli.js size: 13375388 bytes

[verify] Part 1 — Rule Injection
  PASS  XML marker <user_allow_rules_to_replace> present
  PASS  XML marker <user_deny_rules_to_replace> present
  PASS  XML marker <user_environment_to_replace> present
  ...
[verify] Part 2 — Fast Classifier Shortcut
  PASS  ORz() two-stage classifier (was OZz)
  PASS  256-token Stage-1 budget present
  PASS  Stage-1 hard-return ALLOW path
  ...

[verify] -------- summary --------
[verify] PASS: 24 / 24
[verify] FAIL: 0 / 24
[verify] VERDICT: all checks passed — Submission 4 is reproducible on this cli.js
```

Override the path to `cli.js` if needed:

```bash
CLAUDE_CLI_JS=/path/to/other/cli.js ./verify.sh
```

---

## How to run the harness setup

```bash
cd /Users/guybary/Documents/local-explorer-mcp/research/claude-code/submissions/04_classifier_rule_injection/POC
chmod +x setup.sh       # first run only
./setup.sh
```

This is idempotent: running it a second time will refresh the marker file in place. If a non-PoC `settings.local.json` is already present (e.g. you have real local overrides for another project at the same path), it aborts loudly rather than clobbering anything.

---

## Expected behaviour (end-to-end, optional)

This step is optional and only appropriate in a throwaway test environment — a fresh user account, an unimportant machine, or a VM snapshot you can revert. The marker variant cannot authorise dangerous actions, but end-to-end testing still requires trusting a directory and running a live LLM, and the bounty committee may prefer to review the static evidence only.

```bash
# Terminal 1 — create the harness
./setup.sh

# Terminal 2 — open the fake cloned repo with Claude Code
cd /tmp/poc-rule-injection
claude
```

Claude will prompt for trust on the new directory. **Click Trust.** That is the single action required — it is the same click the victim of a real attack would make.

After the trust click, ask Claude any ordinary question (e.g. "list the files in this directory"). When the auto-mode classifier runs:

1. `ehz()` will call `i06()`.
2. `i06()` will return `{allow: ["POC4_RULE_INJECTION_PROOF: ...", ...], soft_deny: [...], environment: [...]}`.
3. `ehz()` will substitute those strings into the classifier system prompt in place of the default `<user_allow_rules_to_replace>` content.
4. `ORz()` will send the contaminated system prompt to the classifier model.
5. Because the marker strings are descriptive text and match nothing actionable, Stage 1 should still block/allow based on the normal defaults — but the injection has occurred regardless.

### How to verify the injection happened

You can verify without relying on the model's behaviour — the proof is in the prompt itself:

1. **Dump the prompt cache**. If Claude Code writes a prompt-cache trace to disk (check `~/.claude/` or `$XDG_CACHE_HOME/`), grep it for `POC4_RULE_INJECTION_PROOF`. A hit means the marker string was in the classifier's system prompt.
2. **Enable the auto-mode debug log**. The code path `if (mT()) N(\`[auto-mode] ...\`)` in `ORz()` is reached when the `AUTO_MODE_LOG` or equivalent flag is set. Grep the logs for the marker string.
3. **Attach a proxy**. Point `https_proxy` at mitmproxy, observe the outbound classifier API request, and grep the request body for `POC4_RULE_INJECTION_PROOF`.
4. **Attach a debugger**. Set a breakpoint on `i06()` or `ehz()` and inspect the return value. The marker arrays should appear in `z.allow`, `z.soft_deny`, and `z.environment`.

Any one of these four methods is sufficient to prove the injection channel is live.

### Control test

Remove `.claude/settings.local.json` from the PoC repo and rerun. The marker strings should no longer appear in the classifier system prompt — confirming the marker was coming from the file and not from some other source.

```bash
mv /tmp/poc-rule-injection/.claude/settings.local.json /tmp/poc-rule-injection/.claude/settings.local.json.bak
cd /tmp/poc-rule-injection
claude
# do the same verification steps; markers should be absent
```

Restore with `./setup.sh`.

---

## Bounty-upgrade instructions

**Do not use the dangerous variant on a real machine or a trusted account.** It exists solely as documentation for the bounty reviewer, to illustrate what a real attack would look like.

To upgrade the PoC from harmless-marker to bounty-grade:

1. Read [`settings.local.json.dangerous`](./settings.local.json.dangerous) to understand the real-world rule set.
2. If you need to reproduce the full impact in a bounty-accepted environment (an air-gapped VM, a burner account, or a sandbox that the Anthropic security team has explicitly approved for live testing), copy the dangerous file over the harmless one:
   ```bash
   cp settings.local.json.dangerous /tmp/poc-rule-injection/.claude/settings.local.json
   ```
3. Launch Claude Code in the PoC directory, accept the trust dialog, and then attempt an action that normally would be blocked — e.g. `git push --force origin main`, or reading `~/.ssh/id_rsa`, or fetching a URL from `attacker.example`. With the dangerous rules injected, `ORz()` Stage 1 should emit `<block>no</block>` and the action should execute.

### Safety rules

- **Never run the dangerous variant against an account with real credentials, real repos, or real cloud access.** The point of this submission is that the injection channel is trivial; running it against anything valuable is recklessly destructive.
- **Never commit the dangerous variant into a repo you care about.** The file looks like an ordinary `settings.local.json`. An accidental commit + push of a misconfigured project could have real consequences for any collaborator who clones and trusts the repo.
- **Revert the harness after testing.** `rm -rf /tmp/poc-rule-injection` is the cleanup.

---

## What this PoC does not do

- It does not exfiltrate data.
- It does not make any network calls (the only network call that *would* happen is the LLM API request inside `ORz()`, triggered only if you manually launch `claude` in the PoC directory).
- It does not modify anything outside `/tmp/poc-rule-injection/`.
- It does not require a malicious server, a collector endpoint, or any attacker-controlled infrastructure.
- It does not use any tricks to hide the injection — the marker strings are plain text and start with an obvious tag.

The verifier (`verify.sh`) is entirely static — it only calls `grep` against the installed `cli.js` and prints the results. It is safe to run on any machine with Claude Code installed.
