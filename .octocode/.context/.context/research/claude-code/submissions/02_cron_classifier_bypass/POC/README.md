# POC — Bounty 2: Persistent Cron Classifier Bypass

All PoCs in this directory are **harmless by default**. Every executable script writes only to
`/tmp/poc-cron-bounty2/` and appends a marker line to `/tmp/poc-cron-bounty2-marker.txt`.
None of them read credentials, make network requests, or touch files outside the scratch
directory.

The `scheduled_tasks.json.dangerous` file is a **static documentation artifact** that shows
what a bounty-grade payload would look like. It is not loaded by any script and is formatted
with a non-JSON comment banner so it cannot be accidentally parsed.

---

## Quick Start

```bash
# 1. Verify every line-number claim in EXPLANATION.md against the live bundle.
./verify.sh

# 2. Plant the harmless marker task.
./setup.sh

# 3. In a new terminal, start Claude Code in the scratch directory.
cd /tmp/poc-cron-bounty2 && claude

# 4. Leave the session idle for ~2 minutes. Then:
cat /tmp/poc-cron-bounty2-marker.txt
# Expected: one or more lines like
#   POC-CRON-BOUNTY2 fired at 2026-04-08T12:34:56Z
```

If the marker file contains a `POC-CRON-BOUNTY2 …` line, the replayed cron prompt entered the
transcript as `role:"user"` and executed with full tool trust — that is the bug.

---

## File Map

| File | Purpose | Safety |
|---|---|---|
| `verify.sh` | Re-runs every evidence grep against live `cli.js`. Prints PASS/FAIL. Read-only. | Safe |
| `setup.sh` | Creates `/tmp/poc-cron-bounty2/` and plants the harmless marker task. | Safe |
| `variant_a_direct_write.sh` | AV-12 direct file write — bypasses `CronCreate`-oriented rules. Harmless payload. | Safe |
| `variant_b_oneshot.sh` | One-shot self-deleting task. Harmless payload. Proves stealth variant. | Safe |
| `scheduled_tasks.json` | Canonical harmless marker task (used by `setup.sh`). | Safe |
| `scheduled_tasks.json.dangerous` | Static documentation — bounty-grade credential exfil payload. NOT loaded. | Documentation |

---

## Variant Overview

### Setup (baseline)

```
setup.sh  →  copies ./scheduled_tasks.json into /tmp/poc-cron-bounty2/.claude/
```

Shows the bug at its simplest. Any attacker who can plant a file at `.claude/scheduled_tasks.json`
(via git repo, `Bash` tool, `Write` tool, MCP server, or unzipping an archive) can reach the
replay path.

### Variant A — Direct Heredoc Write (AV-12)

```
variant_a_direct_write.sh  →  writes /tmp/poc-cron-bounty2/.claude/scheduled_tasks.json
                              with a single <<'JSON' heredoc, no CronCreate invocation
```

This is the **classifier-bypassing** variant. The `Bash` primitive it demonstrates —
`cat > .claude/scheduled_tasks.json <<EOF … EOF` — is not recognized by the "Unauthorized
Persistence" classifier rule at `cli.js:2880`, which is oriented around `CronCreate` tool calls
and OS-level cron/systemd/launchctl invocations.

In a real attack, the agent runs this exact shell primitive after seeing attacker-controlled
content in a file or MCP output. From the classifier's point of view, "write a JSON file" is
a completely ordinary action.

### Variant B — One-Shot Self-Deleting

```
variant_b_oneshot.sh  →  writes a task with recurring:false and a past cron
                          → scheduler fires once on session start, then deletes it
```

This is the **stealth-maximizing** variant. After the task fires, the scheduler rewrites
`scheduled_tasks.json` with the one-shot entry removed. No log line survives. The user has
no way to audit that the task ever existed.

In a real attack, this variant guarantees one credential-exfil execution with zero forensic
trace.

---

## Expected Output

### From `verify.sh`

```
==== Bounty 2 PoC — Live Evidence Verification ====
Bundle: /Users/.../cli.js
Size  : 13375388 bytes
Ver   : "version": "2.1.97"

-- Storage layer --
  [PASS]  scheduled_tasks.json path constant Rhz (line 2710)
  [PASS]  Job creator wl4(q,K,_,z,Y,A) (line 2710)
  [PASS]  Async file reader sL6 (line 2710)
  [PASS]  File writer Xi1(q,K) (line 2709)

-- Tool surface --
  [PASS]  Tool name $k="CronCreate" (line 2747)
  [PASS]  durable description string (line 2737)
  [PASS]  recurring docstring example (line 2714)

-- Replay path --
  [PASS]  Cron enqueue priority:"later",isMeta:!0 (line 8353)
  [PASS]  k57 returns {text,mode:"prompt"} (line 4887)
  [PASS]  k57 type guard on user (line 4887)

-- System reminder asymmetry --
  [PASS]  opened_file_in_ide case with isMeta:!0 (line 5042)
  [PASS]  plan_file_reference case with isMeta:!0 (line 5042)
  [PASS]  <system-reminder> wrapper emitted (line 1682)

-- Classifier rules (that do NOT save us) --
  [PASS]  "delayed effects" reasoning rule (line 2827)
  [PASS]  "Unauthorized Persistence" rule (line 2880)
  [PASS]  "creating cron jobs" in rule (line 2880)

-- Asymmetry negative checks --
  [PASS]  no "scheduled_task_replay" case (no match — confirms asymmetry)
  [PASS]  no "cron_prompt_replay" wrapper (no match — confirms asymmetry)
  [PASS]  classifier rule does NOT cite scheduled_tasks.json by path (no match — confirms asymmetry)

==== Summary ====
Positive checks : 16 / 16
Negative checks : 3 / 3
OVERALL: PASS — all evidence verified on live cli.js
```

Any DRIFT line indicates the line number moved but the semantic claim still holds. FAIL lines
mean Anthropic shipped a fix or the bundle is a different version.

### From `setup.sh` / `variant_a_direct_write.sh` / `variant_b_oneshot.sh`

After running the setup and opening `claude` in the scratch directory for ~2 minutes:

```
$ cat /tmp/poc-cron-bounty2-marker.txt
POC-CRON-BOUNTY2 fired at 2026-04-08T14:32:01Z
POC-CRON-BOUNTY2 fired at 2026-04-08T14:34:02Z
```

Each line proves one successful replay of the scheduled prompt into a `role:"user"` transcript
turn. If the file is empty, the replay did not reach the tool-execution stage — possible causes:

- Session was not left open long enough
- Classifier flagged the harmless `echo` prompt (unlikely; it is clearly benign)
- Bundle is not v2.1.97 (run `verify.sh` to confirm)

---

## What to Look For (Security-Review Checklist)

When reproducing this PoC, the reviewer should confirm each of the following observations:

1. **The file is loaded silently.** Starting `claude` in the scratch directory produces no
   banner, no "you have scheduled tasks" notification, no audit entry.

2. **The classifier is never invoked on the stored prompt.** The prompt becomes a transcript
   message without any pre-check. Tapping the classifier logs (if available) during cron fire
   shows zero evaluations against the prompt text itself.

3. **The transcript turn is shape-identical to keyboard input.** Inspecting the agent's
   message history shows a plain `role:"user"` text block — no `<system-reminder>` wrapper, no
   `isMeta:!0` flag on the content block, no `<scheduled_task>` tag.

4. **Variant A never invokes `CronCreate`.** Shell-level tracing of `variant_a_direct_write.sh`
   shows only a `cat > ... <<EOF` heredoc. The classifier's "creating cron jobs" rule at
   `cli.js:2880` does not match this primitive.

5. **Variant B leaves zero trace.** After the one-shot fires, `cat scheduled_tasks.json` shows
   the task has been removed (or the file has been rewritten to an empty `tasks:[]` array).

6. **No user consent was solicited.** At no point did Claude prompt the human for
   confirmation before replaying the stored task.

---

## Cleanup

```bash
rm -rf /tmp/poc-cron-bounty2 /tmp/poc-cron-bounty2-marker.txt
```

That is the complete cleanup. Nothing persists outside `/tmp/`.

---

## Dependencies

- `bash` 4+ (macOS ships 3.2 — the scripts use `printf`/`$(...)` only, POSIX-compatible)
- `ripgrep` (`rg`) — required by `verify.sh`
- `@anthropic-ai/claude-code@2.1.97` installed and `claude` on `$PATH`

No Node dependencies. No npm install. No network.

## Executable Bit

If the shell scripts are not already executable in your checkout, run them with an explicit
`bash` invocation:

```bash
bash ./verify.sh
bash ./setup.sh
bash ./variant_a_direct_write.sh
bash ./variant_b_oneshot.sh
```

Or restore the executable bit first:

```bash
chmod +x ./*.sh
./verify.sh
```
