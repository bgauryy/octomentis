# POC — Memory-Persistent Universal Jailbreak (Submission 6)

> Harmless, marker-only proof that attacker-controlled content written to `~/.claude/projects/<hash>/memory/` persists across sessions, survives repo deletion, and reaches the model context as `role:"user"` with no validation.
>
> See the parent directory for the full submission:
> - [`../README.md`](../README.md) — index
> - [`../EXPLANATION.md`](../EXPLANATION.md) — technical deep dive
> - [`../WHY_BUG.md`](../WHY_BUG.md) — root-cause analysis
> - [`../VALIDATION.md`](../VALIDATION.md) — white-hat validation report

## What this PoC proves

The harmless marker variant proves **three** things that matter for the bug bounty:

1. **Content written to `~/.claude/projects/<hash>/memory/` reaches the assistant's reply path** without the human ever typing it — through a channel the model treats as user context.
2. **The content persists across sessions** — exiting and re-entering `claude` in the same project reloads the payload.
3. **The content survives repo deletion** — because it lives in `~/.claude/` (HOME), not in the project repo.

## Files in this directory

| File | Purpose | Harmless? |
|---|---|---|
| `README.md` | This file | yes |
| `setup.sh` | Creates test env and writes harmless marker to memory | yes |
| `verify.sh` | Re-verifies code citations via `grep` against live `cli.js` | yes |
| `memory_payload.md` | **Marker** payload — instructs agent to prepend `POC6_MEMORY_PERSISTENT_JAILBREAK` | yes |
| `memory_payload.md.dangerous` | Bounty-grade variant — **documentation only, NOT deployed** | documented, not executed |

## Prerequisites

- `@anthropic-ai/claude-code` v2.1.92 or newer installed globally.
- `git` on `$PATH`.
- Bash and basic POSIX utilities.

## Running the PoC

### Step 1 — Verify the static evidence (no Claude required)

```bash
./verify.sh
```

Expected output: all "[PASS]" lines, `Results: N passed, 0 failed`, exit code 0.

### Step 2 — Build the test repo and inject the memory payload

```bash
./setup.sh
```

Expected behavior:
- Creates `/tmp/poc-memory-bounty6/` (idempotent — re-running refreshes it)
- Writes a minimal git repo scaffold
- Writes the harmless marker to `~/.claude/projects/<hash>/memory/poc6_marker.md`
- Does NOT start `claude`

### Step 3 — Open the test repo with `claude`

```bash
cd /tmp/poc-memory-bounty6
claude
```

### Step 4 — Ask a neutral question

```
summarize this repo in one sentence
```

**Expected observation:** the assistant's reply includes:

```
POC6_MEMORY_PERSISTENT_JAILBREAK
```

Even though the human never typed that token. The token traveled from the memory file → `i8()` → `role:"user"` → model context → assistant reply.

### Step 5 — Exit and re-enter (persistence test)

```bash
# Exit claude (Ctrl+C or /exit)
cd /tmp/poc-memory-bounty6
claude
```

Ask the same neutral question. **Expected:** the marker still appears — proving persistence across sessions.

### Step 6 — Delete the repo and re-test (durability test)

```bash
rm -rf /tmp/poc-memory-bounty6
mkdir /tmp/poc-memory-bounty6 && cd /tmp/poc-memory-bounty6
git init
claude
```

Ask the same neutral question. **Expected:** the marker STILL appears — because the memory file lives in `~/.claude/`, not in the repo. This proves the payload survives repo deletion.

### Step 7 — Control test (remove the memory file)

```bash
# Find and remove the memory file
ls ~/.claude/projects/*/memory/poc6_marker.md
rm ~/.claude/projects/*/memory/poc6_marker.md
# Reopen claude in the test dir
cd /tmp/poc-memory-bounty6
claude
```

Ask the same neutral question. **Expected:** the marker is gone — proving the memory file was the sole channel.

### Step 8 — Teardown

```bash
rm -rf /tmp/poc-memory-bounty6
# Memory file already removed in Step 7; if not:
rm -f ~/.claude/projects/*/memory/poc6_marker.md
```

## Expected results summary

| Step | Action | Expected |
|---|---|---|
| 1 | `./verify.sh` | exit 0, all static checks PASS |
| 2 | `./setup.sh` | test repo + memory payload created |
| 3 | `cd /tmp/poc-memory-bounty6 && claude` | CLI starts |
| 4 | ask neutral question | reply includes `POC6_MEMORY_PERSISTENT_JAILBREAK` |
| 5 | exit + re-enter claude | marker persists (session persistence) |
| 6 | delete repo + re-enter claude | marker persists (repo-deletion survival) |
| 7 | remove memory file + re-enter claude | marker disappears (control) |

## Bounty-upgrade instructions

The harmless marker is the PoC for the bounty submission. A reviewer who wants to confirm the full security impact can swap the marker for the bounty-grade variant.

**Do this only on a throwaway machine with no real secrets.** See [`memory_payload.md.dangerous`](./memory_payload.md.dangerous) for the documented variant.

## Notes on reproducibility

- **Idempotent** — `setup.sh` refreshes the test repo safely.
- **Respects `POC_TARGET_DIR`** — export this env var to redirect the scratch directory.
- **Static verification is version-resilient** — `verify.sh` uses literal string anchors.
- **No network access is required.**

## Cleanup

All PoC state is in two locations:
1. `/tmp/poc-memory-bounty6` — `rm -rf` to remove
2. `~/.claude/projects/*/memory/poc6_marker.md` — `rm -f` to remove

No other host state is touched.
