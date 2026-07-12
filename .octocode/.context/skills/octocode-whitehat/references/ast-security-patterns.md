# AST Security Patterns

Load when you need the full security pattern preset equivalents or the structural investigation workflow. Core patterns and LSP are in `ast-reference.md`.

## Security Preset Equivalents

| Threat category | `npx octocode` equivalent |
| --------------- | ------------------------- |
| `eval-usage` | `--pattern 'eval($$$ARGS)'` |
| `function-constructor` | `--pattern 'new Function($$$ARGS)'` |
| `vm-run` | `--pattern 'vm.runInContext($$$ARGS)'` |
| `process-exec` | `--pattern 'exec($$$ARGS)'` + `--pattern 'spawn($$$ARGS)'` |
| `fetch-call` | `--pattern 'fetch($$$ARGS)'` |
| `http-request` | `--pattern 'http.request($$$ARGS)'` + `--pattern 'https.request($$$ARGS)'` |
| `websocket-call` | `--pattern 'new WebSocket($$$ARGS)'` |
| `listen-call` | `--pattern '$SERVER.listen($$$ARGS)'` |
| `env-access` | `--pattern 'process.env.$NAME'` |
| `fs-read` | `--pattern 'fs.readFileSync($$$ARGS)'` |
| `fs-write` | `--pattern 'fs.writeFile($$$ARGS)'` + `--pattern 'writeFileSync($$$ARGS)'` |
| `base64-decode` | `--pattern 'atob($INPUT)'` + `--pattern 'Buffer.from($INPUT, "base64")'` |
| `string-from-char-code` | `--pattern 'String.fromCharCode($$$ARGS)'` |
| `dynamic-import` | `--pattern 'import($MODULE)'` |
| `require-call` | `--pattern 'require($MODULE)'` |
| `innerhtml-write` | `--pattern '$TARGET.innerHTML = $VALUE'` |
| `credential-path` | `search '\.ssh\|id_rsa\|\.npmrc\|Authorization\|Bearer\|api[_-]?key' <path> --case-insensitive` |
| `metadata-endpoint` | `search '169\.254\.169\.254' <path>` |
| `prompt-injection-string` | `search 'ignore previous\|system prompt\|jailbreak\|do anything now' <path> --case-insensitive` |
| `phishing-lure-string` | `search 'verify account\|reset password\|seed phrase\|wallet' <path> --case-insensitive` |
| `empty-catch` | `--rule` with `kind: catch_clause` + empty body regex |
| `console-log` | `--pattern 'console.log($$$ARGS)'` |
| `debugger` | `--rule 'rule: {kind: debugger_statement}'` |

## Security Investigation Workflow

Run on extracted/prettified source in `.research/{{date}}-{{slug}}/ast/src/`:

```bash
TARGET=.research/20260428T102530Z-audit/ast/src

# Dynamic execution
npx octocode search --pattern 'eval($$$ARGS)' $TARGET --lang js
npx octocode search --pattern 'new Function($$$ARGS)' $TARGET --lang js
npx octocode search --pattern 'vm.runInContext($$$ARGS)' $TARGET --lang js

# Network sinks
npx octocode search --pattern 'fetch($$$ARGS)' $TARGET --lang js
npx octocode search --pattern 'http.request($$$ARGS)' $TARGET --lang js

# Process execution
npx octocode search --pattern 'exec($$$ARGS)' $TARGET --lang js
npx octocode search --pattern 'spawn($$$ARGS)' $TARGET --lang js

# Credentials + env
npx octocode search --pattern 'process.env.$NAME' $TARGET --lang js
npx octocode search '\.ssh|id_rsa|Authorization|Bearer' $TARGET --case-insensitive

# Decoders
npx octocode search --pattern 'atob($INPUT)' $TARGET --lang js
npx octocode search --pattern 'Buffer.from($INPUT, "base64")' $TARGET --lang js
npx octocode search --pattern 'String.fromCharCode($$$ARGS)' $TARGET --lang js

# Dynamic loading
npx octocode search --pattern 'require($MODULE)' $TARGET --lang js
npx octocode search --pattern 'import($MODULE)' $TARGET --lang js

# XSS sinks
npx octocode search --pattern '$T.innerHTML = $V' $TARGET --lang js

# Prompt injection
npx octocode search 'ignore previous|system prompt|jailbreak' $TARGET --case-insensitive

# For each anchor hit → prove the call chain
npx octocode search $TARGET/<file>.js --op callHierarchy --symbol <name> --line <n>
```

## Pattern Wildcards

| Wildcard | Matches |
|----------|---------|
| `$X` | Any single AST node |
| `$$$ARGS` | Zero or more nodes (variadic) |

**Function body gotcha:** `function $NAME($$$PARAMS)` = zero matches when functions have return types. Add `{ $$$BODY }` or use `--rule` with `kind: function_declaration`.
