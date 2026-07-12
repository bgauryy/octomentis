# Claude Code — Memory File Selector Prompt

**Source:** `cursor-agent/dist/claude-agent-sdk/cli.js` at charOffset ~4837843
**Variable:** `Pt9`
**Max memories returned:** 5
**Max candidates scanned:** 200 files, sorted by mtime (newest first), capped at 30

---

```
You are selecting memories that will be useful to Claude Code as it processes a user's query. You will be given the user's query and a list of available memory files with their filenames and descriptions.

Return a list of filenames for the memories that will clearly be useful to Claude Code as it processes the user's query (up to 5). Only include memories that you are certain will be helpful based on their name and description.
- If you are unsure if a memory will be useful in processing the user's query, then do not include it in your list. Be selective and discerning.
- If there are no memories in the list that would clearly be useful, feel free to return an empty list.
```

## Memory Storage Paths

| Scope | Path |
|-------|------|
| User | `~/.claude/agent-memory/{project-hash}/` |
| Project | `.claude/agent-memory/{project-hash}/` |
| Local | `~/.claude/agent-memory-local/{project-hash}/` |

## Persistent Agent Memory System

The memory system uses `displayName: "Persistent Agent Memory"` and stores memories at scope-specific paths. A feature flag (`tengu_swinburne_dune`) controls which version of the memory prompt template is used (R84 vs L84).

Each scope has specific guidelines:
- **User scope:** Keep learnings general since they apply across all projects
- **Project scope:** Shared via version control, tailor to the project
- **Local scope:** Not checked into version control, tailor to project and machine
