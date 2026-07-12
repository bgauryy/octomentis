# Variant D — Memory File Tag Spoofing

| Field | Value |
|---|---|
| **Marker** | `POC3_MEMORY_TAG_SPOOFING_PROOF` |
| **User interaction** | **Zero** after one-time write |
| **Persistence** | **Cross-session** — survives source repo deletion, loads on every session with matching project hash |
| **Target code paths** | `relevant_memories` handler at `cli.js:5071–5074`, `nested_memory` handler at `cli.js:5069–5071` |

## How it works

Claude Code stores "memory" files under `~/.claude/projects/<project-hash>/memory/`. On every session start, the attachment normalizer loads matching memory files and emits them as user-role messages via:

```javascript
// cli.js:5071-5074
case "relevant_memories":
  return Y_(q.memories.map((z, Y) => {
    let A = z.header ?? xK7(z.path, z.mtimeMs), O = z.path.startsWith("<synthesis:");
    return i8({
      content: `${Y === 0 && !O ? "Retrieved for possible relevance — use only if it actually applies to what the user asked.\n\n" : ""}${A}\n\n${z.content}`,
      isMeta: !0
    });
  }));
```

`z.content` is the raw memory file content. A memory file containing `<system-reminder>…</system-reminder>` is emitted verbatim into the message stream, and the model sees it as an elevated runtime directive.

The `isMeta: !0` flag is a UI display hint only — the content still reaches the API exactly as if the user had typed it.

## Sandbox mode (default)

`setup.sh` **does not write to the real memory path** by default. It creates a sandbox copy at `/tmp/poc-sysrem-memory/context.md` so you can inspect the payload structure. A real attacker would deliver the same file to `~/.claude/projects/<hash>/memory/context.md` via:

- A Bash tool call (`echo ... > ~/.claude/projects/.../memory/context.md`).
- A Write tool call the model makes in response to a "please remember this" user or CLAUDE.md instruction.
- An MCP tool result that writes to the path.
- Direct filesystem access (malicious script, supply-chain compromise, etc.).

## Opt-in full test

If you want to observe the marker in a real Claude Code session:

```bash
# 1. Run the sandbox setup
bash variant_d_memory/setup.sh

# 2. Find your project's memory directory
ls -la ~/.claude/projects/ 2>/dev/null

# 3. Copy the payload into the matching project's memory directory
cp /tmp/poc-sysrem-memory/context.md \
   ~/.claude/projects/<your-project-hash>/memory/context.md

# 4. Start a new Claude Code session in the matching project directory
#    and ask a benign question. Marker should appear.

# 5. IMPORTANT: clean up the real memory file afterwards.
rm ~/.claude/projects/<your-project-hash>/memory/context.md
```

## Control test

Remove the `<system-reminder>` block from the memory file and restart Claude Code — the marker should no longer appear.

## Cleanup

```bash
rm -rf /tmp/poc-sysrem-memory
# (and if you did the opt-in full test, remove the file from ~/.claude/projects/)
```

## Persistence properties

This is the only variant that persists across session restarts, CLAUDE.md changes, and source-repo deletion:

- The memory file lives in the user's home directory, keyed by a hash of the project path.
- Anthropic's own classifier rule file (cli.js:1959) explicitly names "Memory Poisoning" as a concern — confirming awareness of the risk — but there is no corresponding content check before memory is injected into the message stream.
- `isMeta: true` is UI-only and does not change delivery to the API.

## Safety invariants

- Default mode writes only to `/tmp/poc-sysrem-memory`.
- Full live test is opt-in, requires explicit manual copy, and is clearly reversible.
- Marker string is the only observable effect.
- No exfiltration, no credential access, no shell commands in the payload.
