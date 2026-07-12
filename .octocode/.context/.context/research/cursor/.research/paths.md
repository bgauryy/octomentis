# Explored Paths — Cursor v3.0.16

## Discovery Log

### 2026-04-14: Initial Full Extraction

**What is this?** Complete extraction of Cursor.app v3.0.16 from `/Applications/Cursor.app/` to `research/cursor/`.

**What was explored:**
1. `/Applications/Cursor.app/Contents/` — Top-level app bundle
2. `/Applications/Cursor.app/Contents/Resources/app/` — All application code
3. All 18 `cursor-*` extensions — Full directory copy with dist/, schemas/, worker/, scripts/
4. `core/out/` — All JS, HTML, CSS files from `vs/` tree
5. `core/bin/` — Shell scripts (code, cursor, cursor-tunnel)
6. `config/` — package.json, product.json, policies/
7. `core/out/vscode-dts/` — VSCode type definitions
8. `core/out/media/` — Icons, fonts, images

**What I know now:**
- No obfuscation — standard minification only
- Single webpack bundle for workbench, esbuild for extensions
- Claude Agent SDK v0.2.70 embedded (Claude Code v2.1.70)
- 18 cursor-specific extensions mapped with roles
- Canvas runtime for agent-authored UI
- 21+ AI model IDs found (Claude 3 through Claude 4.6)
- Chain-of-thought identifiers found in extension host
- Prior security audit (v3.0.12) exists in `docs/`
- 13 system prompts already extracted in `prompts/`

**What else is here?**
- Massive workbench bundle (54 MB) contains most Cursor AI UI logic
- `nls.keys.json` / `nls.messages.json` contain all user-facing strings
- Extension host has AI chain-of-thought logic
- product.json has extensive config including extension replacement maps

**Research paths:**
1. Deep dive into workbench.desktop.main.js — AI composer, chat UI, model selection
2. cursor-agent/dist/main.js — Agent orchestration logic
3. cursor-agent-exec — Tool execution, canvas system
4. cursor-mcp — MCP protocol implementation
5. cursor-always-local — Feature flags, experimentation
6. nls.messages.json — All user-facing strings for feature discovery

**Next micro-step:** User should prioritize which features/flows to analyze deeper.

## Files Extracted

| Category | Files | Total Size |
|----------|-------|-----------|
| Core JS | 25 | 73 MB |
| Extension JS | 21 | 66 MB |
| Config | 3 | 72 KB |
| Prompts | 14 | 60 KB |
| Docs (prior) | 8 | 108 KB |
| Syntaxes | 27 | ~120 KB |
| Media/Assets | ~15 | ~5 MB |
| Type definitions | 1 | ~300 KB |
| **Total** | **~198** | **~152 MB** |
