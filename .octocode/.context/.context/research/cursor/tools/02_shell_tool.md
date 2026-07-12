# Shell Tool — Command Execution Internals

**Confidence:** `confirmed` — protobuf types, system prompt instructions, server config, terminal file system evidence

---

## What It Claims To Do

Execute shell commands in a stateful terminal session with optional backgrounding.

## What It Actually Does Under the Hood

### Architecture: PTY-Based Terminal Sessions

The Shell tool doesn't use `child_process.exec()`. It operates through VSCode's **integrated terminal API**, which manages real pseudo-terminal (PTY) sessions.

```
LLM emits ToolCallDelta: tool="Shell"
  │
  ├─ args: { command, working_directory?, block_until_ms?, description? }
  │
  ├─ cursor-agent-exec receives ShellArgs
  │    │
  │    ├─ Resolves or creates terminal session
  │    │   ├─ Terminal sessions are STATEFUL (cwd, env persist)
  │    │   ├─ Each session has a unique ID (maps to terminal file)
  │    │   └─ Session state saved to: ~/.cursor/projects/<hash>/terminals/<id>.txt
  │    │
  │    ├─ Sends command to PTY
  │    │   ├─ dontSendCtrlCBeforeCommand: true (server config)
  │    │   └─ Command written as raw input to the PTY
  │    │
  │    ├─ Waits for completion OR timeout
  │    │   ├─ block_until_ms (default 30,000ms)
  │    │   ├─ If command completes within timeout → return stdout/stderr
  │    │   └─ If timeout exceeded → move to BACKGROUND
  │    │
  │    └─ Returns ShellResult
  │         ├─ stdout/stderr content
  │         ├─ exit_code (if completed)
  │         ├─ task_id (if backgrounded)
  │         └─ elapsed_ms
  │
  └─ Backgrounded commands continue running
       └─ Output streams to terminal file for Await tool polling
```

### Terminal File System

Each terminal session is persisted as a text file:

```
~/.cursor/projects/<project-hash>/terminals/
├── 1.txt
├── 2.txt
├── 3.txt
└── ...
```

File format:
```
---
pid: 68861
cwd: /Users/me/proj
last_command: sleep 5
last_exit_code: 1
---
(...full terminal output...)
```

The first ~10 lines are always metadata. The agent can:
- Read any terminal file to check output
- Use `head -n 10 *.txt` to get metadata for all terminals
- Monitor background commands by reading the end of the file

### Backgrounding Mechanism

```
Command lifecycle:
  1. Command starts executing in PTY
  2. Timer starts: block_until_ms (default 30s)
  3. If command completes before timer → immediate result
  4. If timer expires:
     a. Command continues running in PTY
     b. Shell tool returns with task_id
     c. Output continues streaming to terminal file
     d. Footer with exit_code + elapsed_ms appended when done
  5. block_until_ms=0 → immediate background (for servers, watchers)
```

### Await Tool — The Polling Companion

The `Await` tool (AwaitArgs/AwaitResult protobuf) is tightly coupled with Shell:

```
Await {
  task_id?: string     ← shell task to poll (optional — omit to just sleep)
  block_until_ms: int  ← max wait time
  pattern?: string     ← regex to match in output (JS regex with multiline flag)
}
```

Behavior:
- Reads the terminal output file
- Blocks until pattern matches OR task completes OR timeout
- Header has `pid` and `running_for_ms` (updated every 5s)
- Footer with `exit_code` and `elapsed_ms` appears on completion
- Pattern matches anywhere in the full output, not just new output

### WriteShellStdin — Interactive Commands

The `WriteShellStdin` tool (WriteShellStdinArgs/WriteShellStdinResult) handles interactive input:
- Writes raw bytes to a running PTY's stdin
- Used for: confirming prompts, sending passwords, interactive REPLs
- Separate protobuf type from Shell — indicates distinct execution path

### Composite Shell Commands

The server config defines a `compositeShellCommands` list — commands recognized as having subcommands:

```
ansible, apt, az, aws, aws-vault, brew, buildah, cargo, cf, chef,
circleci, composer, conda, consul, docker, docker-compose, doctl,
eksctl, firebase, flyctl, gem, gh, git, gcloud, glab, helm, heroku,
ibmcloud, ip, kops, kubectl, kustomize, linode-cli, mercurial,
nerdctl, nomad, npm, oci, op, pacman, packer, pip, pipenv, pipx,
pnpm, podman, pulumi, systemctl, terraform, uv, vault, yarn
```

These are likely used for:
- Permission categorization (e.g., `git push` vs `git status`)
- Command classification for telemetry
- Approval flow decisions (read vs write operations)

### Permission Model

The system prompt reveals the approval hierarchy:

```
Shell command categories:
  ├─ Read-only (auto-approved in explore/plan agents):
  │   ls, git status, git log, git diff, find, cat, head, tail
  │
  ├─ Destructive (blocked in explore/plan agents):
  │   mkdir, touch, rm, cp, mv, git add, git commit,
  │   npm install, pip install, file creation/modification
  │
  └─ Agent mode (full access with user approval flow):
      All commands, subject to user permission settings
```

The explore agent's Shell access is explicitly restricted:
- "Use Bash ONLY for read-only operations"
- "NEVER use Bash for: mkdir, touch, rm, cp, mv, git add, git commit, npm install, pip install, or any file creation/modification"

### Stateful Sessions

Critical design detail: **terminals are stateful across sequential calls**.

```
Call 1: Shell { command: "cd /tmp && export FOO=bar" }
Call 2: Shell { command: "echo $FOO" }  ← prints "bar"
Call 3: Shell { command: "pwd" }        ← prints "/tmp"
```

The `working_directory` parameter overrides this for a single call without changing the persistent state.

### Ctrl+C Behavior

Server config: `dontSendCtrlCBeforeCommand: true`

This means Cursor does NOT send Ctrl+C before new commands. Previously it did (to kill any running process before sending the next command). This was changed to prevent accidentally killing intentionally-backgrounded processes.

## Execution Flow Detail

```
User message → LLM
  → ToolCallDelta { name: "Shell", args: {...} }
    → cursor-agent-exec
      → Resolve terminal session (create or reuse)
      → Write command to PTY stdin
      → Start block_until_ms timer
      → Read PTY output stream
        ├─ Command completes → capture exit code + output
        │   → Write terminal file with metadata + output
        │   → Return ShellResult { stdout, exit_code, elapsed_ms }
        │
        └─ Timer expires → background
            → Return ShellResult { task_id, partial_output }
            → Terminal file continues updating
            → Agent uses Await to poll
              → Await reads terminal file
              → Returns when pattern matches or task completes
```

## Security Observations

| Finding | Severity | Confidence |
|---------|----------|------------|
| Shell commands execute in real PTY with full user permissions — no sandboxing | `medium` | `confirmed` |
| `cliSandboxDefaultEnabled: false` in server config — sandbox is OFF by default | `medium` | `confirmed` |
| Terminal files persist command history with full output in plaintext | `low` | `confirmed` |
| Composite command list suggests permission-based command classification exists server-side | `info` | `likely` |
| Explore/plan agent Shell restrictions are prompt-level only, not enforced by tool schema | `low` | `confirmed` |

---

*Evidence: system prompt tool descriptions, server_config.json (runTerminalServerConfig, cliSandboxDefaultEnabled, dontSendCtrlCBeforeCommand), terminal file format from terminal_files_information, protobuf types (ShellArgs, ShellResult, WriteShellStdinArgs, AwaitArgs)*
