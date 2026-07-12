# Research Workspace

Load when bootstrapping a `.research/` directory for multi-file, multi-step analysis.

## When to Bootstrap

Create `.research/{{timestamp}}-{{research-name}}/` when analysis will span multiple files, create derived artifacts, or need an auditable trail. Keep it light for quick triage; expand only when the investigation earns the structure.

Name format: `YYYYMMDDTHHMMSSZ-<slug>` — e.g. `.research/20260428T102530Z-mcp-audit/`.

## Directory Structure

| File / Dir | Purpose |
| ---------- | ------- |
| `research-metadata.md` | Scope, approvals, artifact hashes, extraction decisions, assumptions |
| `research.md` | Executive summary, stated intent vs actual behavior, risk verdict |
| `overview.md` | Runtime model, entry points, module architecture |
| `search-playbook.md` | Reproducible search recipe: queries, anchors, flags, dead-end filters |
| `findings.md` | Each finding: severity, confidence, evidence, impact |
| `paths.md` | Searched, remaining, dead ends, reflection notes |
| `examined.log` | Append-only log to avoid duplicate work |
| `flows.md` | Traced call paths: entry → wrapper → sink |
| `execution-graph.md` | Call graph: nodes, edges, confidence, unresolved jumps |
| `chunks.md` | Chunk summaries for large/minified files |
| `deobfuscation-notes.md` | Bundler classification, decoder hypotheses, source-map status |
| `strings.md` | High-signal strings, URLs, tokens, encoded payloads |
| `extracted/originals/` | Originals when repeatability requires them |
| `extracted/chunks/` | Bounded extract windows, named by purpose |
| `extracted/decoded/` | Decoded payloads |
| `extracted/prettified/` | Prettified modules for reading |
| `ast/src/` | Extracted/prettified source for structural AST search |
| `mapping/tool-coverage.md` | Tools/queries used, why, outcome |
| `mapping/file-surface-map.md` | File inventory: `queued` → `in-progress` → `validated` → `closed-low` |
| `mapping/chunk-map.md` | Large-file chunks with offsets and next proof step |
| `mapping/flow-map.md` | Source → transform → sink chains with evidence links |
| `mapping/binary-artifact-map.md` | Binary/archive map: hash, status, next action |

**Start with:** `research-metadata.md`, `search-playbook.md`, `findings.md`, `examined.log`. Add mapping files only when they remove confusion.

## Large File Chunking

Goal: break large files into meaningful, citable chunks.

| Step | Action | Command |
| ---- | ------ | ------- |
| 1 Discover | Find large files | `npx octocode tools localFindFiles --queries '{"path":"<abs>","sizeGreater":"1M"}'` |
| 2 Classify | Identify: source map, bundler family, minified-vs-obfuscated, binary/archive | `npx octocode search <file> --target artifacts --inspect` |
| 3 Anchor | Search for high-signal patterns | `npx octocode search "eval\|fetch\|require\|sourceMappingURL" <path> --files-only` |
| 4 Extract | Window around each anchor (name by purpose, not byte range) | `npx octocode search <file> --match-string "<anchor>" --content-view exact` |
| 5 Save | Chunks → `extracted/chunks/`; decoded → `extracted/decoded/`; prettified → `extracted/prettified/`; AST-ready → `ast/src/` | — |

## Execution Graph Layers (Minified/Obfuscated)

Build the graph in layers when minification hides intent:

1. **Runtime shell** — bundler/loader wrapper, module registry, chunk loader
2. **Entry points** — install hooks, CLI bins, MCP tools, browser events, service workers, Electron main/preload
3. **Decoder layer** — string arrays, base64/hex decoders, `Function`/`eval` packers, WASM bridge wrappers
4. **Capability layer** — network, filesystem, process execution, credential access, crypto, IPC, native bindings
5. **Sink layer** — outbound endpoint, command execution, persistence path, sensitive file read, prompt injection

When LSP cannot parse minified code, build the graph manually in `execution-graph.md` and mark confidence as `confirmed`, `likely`, or `uncertain`.

## Ask-or-Extract Decision

- **Extract without asking** when: read-only, bounded, local, necessary to understand a concrete flow (e.g. a 10KB chunk around an `eval` hit, a decoded string table, a small prettified module from a source map).
- **Ask the user first** when: copying whole large artifacts, unpacking many files, using external tools not in the tooling contract, inspecting sensitive-looking data, or crossing workspace boundaries.
- **Record the decision** in `research-metadata.md`: what was needed, why bounded read was insufficient, what was extracted or deferred, where artifacts were written, what remains unknown.
