# AST Reference

Load when you need structural code-shape proof via `npx octocode search --pattern/--rule`. For the full security pattern library and investigation workflow, see `ast-security-patterns.md`.

## Which Approach

| Goal | Approach |
| ---- | -------- |
| Orient: all symbols + lines | `npx octocode search <file> --op documentSymbols` |
| Prove a call/assignment shape | `search --pattern '<ast>' <path> --lang js` |
| Complete node match | `search --pattern` with `$X` (one node) or `$$$ARGS` (list) |
| Partial / relational match (inside/has/not) | `search --rule '<yaml>'` |
| Prove call chain semantically | `search <file> --op callHierarchy --symbol <name> --line <n>` |
| Find all usages of a symbol | `search <file> --op references --symbol <name> --line <n>` |

**Golden rule:** orient with `documentSymbols`, find structurally with `--pattern`, prove semantically with LSP.

## Key Security Patterns

```bash
# Dynamic execution
npx octocode search --pattern 'eval($$$ARGS)' ./src --lang js
npx octocode search --pattern 'new Function($$$ARGS)' ./src --lang js

# Network sinks
npx octocode search --pattern 'fetch($$$ARGS)' ./src --lang js
npx octocode search --pattern 'http.request($$$ARGS)' ./src --lang js

# Process execution
npx octocode search --pattern 'exec($$$ARGS)' ./src --lang js
npx octocode search --pattern 'spawn($$$ARGS)' ./src --lang js

# Environment + credentials
npx octocode search --pattern 'process.env.$NAME' ./src --lang js
npx octocode search --pattern 'Buffer.from($INPUT, "base64")' ./src --lang js

# XSS sinks
npx octocode search --pattern '$TARGET.innerHTML = $VALUE' ./src --lang js

# Dynamic loading
npx octocode search --pattern 'require($MODULE)' ./src --lang js
npx octocode search --pattern 'import($MODULE)' ./src --lang js
```

## Relational Rules (YAML)

Use when a pattern alone can't express the relationship:

```bash
# Empty catch block
npx octocode search --rule 'rule:
  kind: catch_clause
  has:
    kind: statement_block
    regex: "^\{\\s*\}$"' ./src --lang js

# Switch without default case
npx octocode search --rule 'rule:
  kind: switch_statement
  not:
    has:
      kind: switch_default
      stopBy: end' ./src --lang js

# Deeply nested callbacks (3+ levels)
npx octocode search --rule 'rule:
  kind: arrow_function
  inside:
    kind: arrow_function
    inside: {kind: arrow_function, stopBy: end}
    stopBy: end' ./src --lang js
```

## LSP Semantic Proof

After structural search gives a file + line anchor:

```bash
# Step 1: exact lines for every symbol
npx octocode search ./src/server.js --op documentSymbols

# Step 2: go to definition
npx octocode search ./src/server.js --op definition --symbol handleRequest --line 42

# Step 3: call hierarchy (callers + callees)
npx octocode search ./src/server.js --op callHierarchy --symbol handleRequest --line 42

# Step 4: all references
npx octocode search ./src/server.js --op references --symbol handleRequest --line 42
```

**Tips:** Never guess `--line` — use `documentSymbols` first. On minified one-liners, fall back to text search. Use `orderHint` when the same symbol name appears multiple times on one line.

## TypeScript Best Practices

| Scenario | Use | Why |
|----------|-----|-----|
| Find all functions | `--op documentSymbols` | Ignores type annotations |
| Find specific calls | `--pattern 'JSON.parse($X)'` | Call expressions have no TS types |
| Match with return type | `--pattern 'function $N(): Promise<$T> { $$$B }'` | Include exact type shape |
| Structural smells | `--rule` with `kind:` | Rules match partial shapes |

**Gotcha:** `function $NAME($$$PARAMS)` returns 0 matches when functions have return types. Either include the full type shape in the pattern or use `--rule` with `kind: function_declaration`.

See `ast-security-patterns.md` for the full security preset equivalents table and investigation workflow.
