# Octocode CLI Tools

Use this when choosing the right `npx octocode` command for any security-research capability.

Always run `npx octocode search --scheme` before raw `tools` calls — never guess field names.

## Canonical Tool Map

| Capability | Command | Use when |
| ---------- | ------- | -------- |
| Directory map | `npx octocode search <path> --tree [--depth N]` | Orient before searching; `--depth 1` first |
| File discovery | `npx octocode tools localFindFiles --queries '{"path":"<abs>","modifiedWithin":"7d"}'` | Find by name, time, size, type, exec bit |
| Text/regex search | `npx octocode search "<term>" <path>` | Find files + line anchors |
| Files-only triage | `npx octocode search "<term>" <path> --files-only` | Which files hit, before reading content |
| Targeted file read | `npx octocode search <file> --content-view exact` | Exact content or bounded region |
| Bounded region | `npx octocode search <file> --match-string "<anchor>" --content-view exact` | Window around a known string |
| Binary/archive/WASM/native | `npx octocode search <file> --target artifacts --inspect` | Non-text artifact families |
| Binary strings | `npx octocode search <file> --target artifacts --strings` | High-signal string extraction |
| Single-stream decompress | `npx octocode search <file> --target artifacts --decompress` | `.gz`/`.bz2`/`.xz`/`.zst` payloads |
| Archive list | `npx octocode search <file> --target artifacts --list` | Enumerate ZIP/JAR/TAR/7z members |
| Archive extract entry | `npx octocode search <file> --target artifacts --extract <entry>` | One member (case-sensitive name from `--list`) |
| Unpack to disk | `npx octocode unzip <archive>` | Local analysis of many archive members |
| AST structural pattern | `npx octocode search --pattern '<ast>' <path> --lang <lang>` | Prove code shape structurally |
| AST relational rule | `npx octocode search --rule '<yaml>' <path> --lang <lang>` | inside/has/not relational queries |
| Document symbols | `npx octocode search <file> --op documentSymbols` | All symbols + exact lines (use as `--line` source) |
| LSP definition | `npx octocode search <file> --op definition --symbol <name> --line <n>` | Resolve a wrapper or decoder |
| LSP call hierarchy | `npx octocode search <file> --op callHierarchy --symbol <name> --line <n>` | Who calls it, what it calls |
| LSP all references | `npx octocode search <file> --op references --symbol <name> --line <n>` | All usages of a type/variable/export |
| LSP callers only | `npx octocode search <file> --op callers --symbol <name> --line <n>` | Incoming call sites only |

Batch independent angles (up to 5 queries per `tools` call). Sequence only when the next query needs results from the prior one.

## What-Tool-When

| What you want to know | Command chain |
| --------------------- | ------------- |
| What is in this project? | `--tree --depth 1` → `localFindFiles` for recent/large/executable paths |
| Where does pattern X appear? | `--files-only` → content search → `--match-string "<anchor>" --content-view exact` |
| What does this code say? | `--content-view exact` or `--start-line N --end-line M` |
| What family is this artifact? | `--target artifacts --inspect` → route by type |
| What is in a binary/blob? | `--inspect` → `--strings` → `search "<string>" <dir> --hidden` |
| What is inside an archive? | `--list` → `--extract <entry>` (case-sensitive) |
| What is inside a compressed stream? | `--decompress` + `--match-string` for large streams |
| Where is X defined/called/used? | `--op documentSymbols` → `--op definition/callHierarchy/references --symbol <name> --line <n>` |
| Prove a code shape structurally | `--pattern 'eval($X)' <path> --lang js` — see `ast-reference.md` |

## Tool Ratings

| Operation | Rating | Critical gotcha |
| --------- | ------ | --------------- |
| `search <path> --tree` | ★★★★★ | `--depth 1` first. Never skip on unknown targets. |
| `tools localFindFiles` | ★★★★★ | `modifiedWithin:"7d"` finds attack-surface changes fastest. |
| `search "<term>" <path>` | ★★★★★ | Start with `--files-only`. Add `--hidden --no-ignore` for dotfile/artifact hunts. |
| `--content-view exact` | ★★★★☆ | `--match-string` is **case-sensitive** — wrong case → empty, no error. |
| `--target artifacts --inspect` | ★★★★★ | Correctly resolves fat Mach-O, bzip2-wrapped DMGs, misnamed archives. |
| `--target artifacts --strings` | ★★★★☆ | Add `--match-string`; without it large binaries paginate. |
| `--target artifacts --decompress` | ★★★★☆ | 10 MB cap. Add `--match-string` or use `--char-offset`. |
| `--target artifacts --list/--extract` | ★★★★☆ | ZIP/JAR/TAR work out of box. DMG/RAR/7z need `brew install sevenzip`. |
| `--pattern '<ast>' --lang <lang>` | ★★★★★ | Pattern MUST match a complete node. No body = zero matches. Use `--rule` for partial. |
| `--op documentSymbols` | ★★★★★ | Always run first — gives exact `--line` for all follow-up LSP calls. |
| `--op callHierarchy` | ★★★★☆ | Requires parseable source. Minified one-liners → fall back to text search. |
| Source map (`shuji`) | ★★★★★ | `npm i -g shuji` → `shuji file.js.map -o out/`. Needs `sourcesContent`. |
| JS deobfuscation (`webcrack`) | ★★★★☆ | Node 22+. Best for bundled + obfuscated in one pass. |
| Hermes bytecode (`hermes-dec`) | ★★★★☆ | `pipx install hermes-dec`. Output is pseudo-JS, not valid syntax. |

**A missing optional CLI is not a clean verdict.** Record the gap; install the named tool or use a fallback operation.
