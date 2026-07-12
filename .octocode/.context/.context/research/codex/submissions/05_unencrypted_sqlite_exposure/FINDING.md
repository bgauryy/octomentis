## Summary:

Codex Desktop stores all automation metadata, run history, thread IDs, inbox items, archived user/assistant messages, and workspace paths in a plaintext SQLite database at `~/Library/Application Support/Codex/`. The database uses `better-sqlite3` with **no encryption at rest** (no SQLCipher, no application-level encryption). Any process with user-level file access can read the database to enumerate automation IDs, learn workspace paths, read archived conversation content, and identify high-value targets for attacks via BUG-01 (memory poisoning) or BUG-02 (TOML replacement). The SQLite database is the **reconnaissance enabler** for the entire attack chain.

**Severity:** MEDIUM
**CWEs:** CWE-312 (Cleartext Storage of Sensitive Information), CWE-922 (Insecure Storage of Sensitive Information)
**Target:** `com.openai.codex` v26.325.31654 — Codex Desktop (Electron)

## Steps To Reproduce:

  1. Locate the Codex SQLite database: `find ~/Library/Application\ Support/Codex -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" 2>/dev/null` (or check the appData directory directly)
  1. Open with sqlite3: `sqlite3 ~/Library/Application\ Support/Codex/<database_file>`
  1. Enumerate automations: `SELECT id, name, prompt, status, cwds FROM automations;`
  1. Read archived messages: `SELECT thread_id, archived_user_message, archived_assistant_message FROM automation_runs;`
  1. List inbox items: `SELECT title, description, thread_id FROM inbox_items;`

## Supporting Material/References:

  * Schema creation: `product-name-CswjKXkf.js` charOffset ~318739 — `CREATE TABLE IF NOT EXISTS automations (...)`
  * Tables: `automations` (id, name, prompt, status, rrule, cwds, model, last_run_at, next_run_at), `automation_runs` (thread_id, automation_id, inbox_title, archived_user_message, archived_assistant_message, source_cwd), `inbox_items` (title, description, thread_id, read_at)
  * Migration history: versions 1–17+ showing progressive addition of fields including `rrule`, `cwds`, `archived_reason`, `source_cwd`
  * Native module: `better-sqlite3` in `app.asar.unpacked/node_modules/better-sqlite3/` — standard SQLite, no encryption module

---

## Detailed Explanation

### What Is Exposed?

| Table | Sensitive Fields | Risk |
|-------|-----------------|------|
| `automations` | `id`, `name`, `prompt`, `cwds`, `status` | Attacker learns automation IDs to target BUG-01/02 |
| `automation_runs` | `archived_user_message`, `archived_assistant_message`, `source_cwd` | Leak full conversation content including code, commands, credentials mentioned in chat |
| `inbox_items` | `title`, `description`, `thread_id` | Leak task descriptions, project context |

### Why This Enables the Full Kill Chain

Without this bug, an attacker would need to guess or brute-force automation UUIDs to target BUG-01 or BUG-02. With database access:

```
1. Read SQLite → enumerate all automation IDs and their cwds
2. Identify highest-value automation (the one with 'danger-full-access')
3. Write poisoned memory.md to that specific automation's directory
4. Wait 30 seconds → full system compromise
```

### Additional Risks

- **Conversation history leakage:** Archived messages may contain API keys, passwords, or proprietary code discussed with the agent
- **Workspace path enumeration:** `cwds` and `source_cwd` reveal all directories the user works in
- **Prompt leakage:** Automation prompts may contain sensitive business logic or internal URLs

### Recommended Fixes

1. **Encrypt at rest:** Use SQLCipher or application-level encryption with a key derived from the system keychain
2. **Restrict file permissions:** Set `0600` on the database file
3. **Minimize stored data:** Purge archived messages after a configurable retention period
4. **Redact sensitive content:** Strip or hash credentials/keys before storing in run history
