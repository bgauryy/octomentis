# Cursor v3.0.16 — Full Code Extraction & Research

**Target:** Cursor.app v3.0.16 (Anysphere, Inc.) — VSCode 1.105.1
**Source:** `/Applications/Cursor.app/Contents/Resources/app/`
**Extracted:** 2026-04-14
**Method:** Full file extraction + static analysis of minified JS bundles

---

## Directory Structure

```
research/cursor/
├── .research/                    # Analysis master docs (navigate from here)
│   ├── research.md               #   MASTER DOC — executive summary, all findings
│   ├── overview.md               #   Bundle structure, entry points, architecture
│   ├── flows.md                  #   Execution flows, activation, agent chains
│   ├── entities.md               #   Extensions, business objects, feature flags
│   ├── strings.md                #   URLs, API keys, model IDs, endpoints
│   └── paths.md                  #   Explored regions, reflection log
├── config/                       # App configuration
│   ├── package.json              #   App identity (name, version, main entry)
│   ├── product.json              #   Product config (57 KB — URLs, keys, mappings)
│   └── policies/                 #   macOS MDM policy templates
├── core/                         # Core application code (73 MB)
│   ├── bin/                      #   Shell scripts (code, cursor, cursor-tunnel)
│   └── out/
│       ├── main.js               #   Electron main process (1.3 MB)
│       ├── cli.js                #   CLI process (210 KB)
│       ├── bootstrap-fork.js     #   Process forking (19 KB)
│       ├── nls.keys.json         #   NLS translation keys (463 KB)
│       ├── nls.messages.json     #   NLS translation strings (724 KB)
│       ├── media/                #   Icons, fonts, images
│       ├── vscode-dts/           #   VSCode API type definitions
│       └── vs/                   #   All VS subsystem bundles
│           ├── workbench/
│           │   ├── workbench.desktop.main.js  # MAIN BUNDLE (54 MB)
│           │   └── api/                       # Extension hosts (4.8 MB + 4.5 MB)
│           ├── code/                          # Workbench HTML, shared process, CLI
│           ├── editor/                        # Editor services
│           ├── platform/                      # Platform services
│           └── base/                          # Sandbox preloads
├── extensions/                   # All 18 cursor-specific extensions (66 MB)
│   ├── cursor-agent/             #   Agent framework + Claude SDK (40 MB)
│   ├── cursor-agent-exec/        #   Agent execution + Canvas runtime (4.8 MB)
│   ├── cursor-retrieval/         #   Code indexing & search (4.6 MB)
│   ├── cursor-always-local/      #   Experimentation & feature flags (4.1 MB)
│   ├── cursor-mcp/               #   MCP protocol handler (2.8 MB)
│   ├── cursor-resolver-helper/   #   Remote connection tokens (2.7 MB)
│   ├── cursor-commits/           #   Git commit tracking (2.4 MB)
│   ├── cursor-browser-automation/ #  Browser automation MCP (1.6 MB)
│   ├── cursor-shadow-workspace/  #   Shadow workspace (1.2 MB)
│   ├── cursor-deeplink/          #   URI deep-links (898 KB)
│   ├── cursor-polyfills-remote/  #   Polyfills (101 KB)
│   ├── cursor-resolver/          #   Remote authority resolver (98 KB)
│   ├── cursor-ndjson-ingest/     #   NDJSON log ingestion (18 KB)
│   ├── cursor-explorer/          #   Workspace explorer (16 KB)
│   ├── cursor-socket/            #   TCP/TLS sockets (11 KB)
│   ├── cursor-checkout/          #   Branch migration (9 KB)
│   ├── cursor-file-service/      #   Retrieval stub (367 B)
│   └── cursor-worktree-textmate/ #   Worktree syntax (27 grammars)
├── prompts/                      # Extracted system prompts (13 documents)
│   ├── README.md                 #   Prompt inventory & notes
│   ├── 01–05: Intent analysis, writeback, categorization, rules, blocklist
│   ├── 06–10: Subagent prompts (general, explore, plan, guide, statusline)
│   └── 11–13: Memory selector, home agent, MCP auth
├── docs/                         # Prior security audit (v3.0.12)
│   ├── BOUNTY.md                 #   Security bounty report (8 findings)
│   ├── research.md               #   v3.0.12 audit executive summary
│   ├── findings.md               #   Security findings (F01–F10)
│   ├── overview.md               #   v3.0.12 architecture
│   └── strings.md                #   v3.0.12 extracted strings
└── submissions/                  # Bounty submission write-ups (8)
```

## Quick Links

| Area | Start here |
|------|------------|
| Master research | [.research/research.md](.research/research.md) |
| Architecture & bundles | [.research/overview.md](.research/overview.md) |
| Execution flows | [.research/flows.md](.research/flows.md) |
| Extensions & entities | [.research/entities.md](.research/entities.md) |
| URLs, keys, model IDs | [.research/strings.md](.research/strings.md) |
| Extraction log | [.research/paths.md](.research/paths.md) |
| System prompts | [prompts/README.md](prompts/README.md) |
| Security audit (v3.0.12) | [docs/BOUNTY.md](docs/BOUNTY.md) |

## Key Stats

| Metric | Value |
|--------|-------|
| Total extracted | ~152 MB, 198 files |
| Core JS files | 25 files, 73 MB |
| Extension JS files | 21 files, 66 MB |
| Largest bundle | workbench.desktop.main.js (54 MB) |
| Cursor extensions | 18 |
| AI model IDs found | 21+ (Claude 3 through 4.6) |
| System prompts extracted | 13 |
| Bundler | Webpack (workbench), esbuild (extensions) |
| Obfuscation | None |
| Source maps | Not shipped |
