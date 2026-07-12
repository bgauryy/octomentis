# `lspGetSemantics` — Improvements

## Current State
- **Hard validation rule:** `symbolName` and `lineHint` are required for all types except `documentSymbols` — but this is a Zod `superRefine` rule, not stated anywhere in descriptions. Agents guess `lineHint` and get silent empty results.
- `format:"compact"` saves ~50% tokens on call trees — never documented
- `groupByFile:true` for references returns a per-file summary instead of every call site — never documented
- `orderHint` for disambiguation when a symbol appears multiple times on the same line — never documented
- `depth` for call tree recursion — never documented
- `includeDeclaration:false` to omit the declaration itself from references — never documented
- `workspaceRoot` override — never documented
- `resolvedSymbol` in output — the confirmation that LSP actually found the symbol — never read by agents
- Language tier differences (`callers`/`callees` only on TS/JS/Go/Rust; `Python`/`C++` use references) not documented

---

## Description

### Current
*(Reconstructed from schema)*
```
Typed LSP queries for semantic navigation.
Type routing: documentSymbols=file outline (uri only); hover=signature+JSDoc; definition=jump to decl; typeDefinition=generic types; implementation=abstract member impl (member name, not class); references=same-package usages (bounded by TS server open files, NOT cross-package); callers=cross-package incoming calls (TS/JS/Go/Rust only — Python/C++ use references instead); callees=outgoing calls; callHierarchy=both.
Language tiers — Tier 1 all types: TS/JS/Go/Rust. Tier 2 no callHierarchy: Python/C++. Tier 3 documentSymbols+hover+definition only: Shell/HTML/CSS/YAML/TOML.
All non-documentSymbols types need symbolName+lineHint from a prior localSearchCode hit.
Next: localGetFileContent(startLine/endLine), localSearchCode for uri/symbolName/lineHint.
```

### Proposed
```
Semantic code navigation via LSP. Requires a running LSP server for the file's language.

Prerequisites (hard rules — Zod enforced, returns validation error if violated):
- All types except documentSymbols require: uri + symbolName + lineHint
- lineHint must be an integer (1-based line number from a real localSearchCode hit — never guess)
- symbolName must be non-empty

Always get uri and lineHint from a prior localSearchCode result:
- uri = files[0].path from localSearchCode
- lineHint = matches[0].line from localSearchCode (1-based)
- symbolName = the exact identifier at that line (case-sensitive, no parentheses)

Type routing:
- documentSymbols: file outline — needs uri only, no symbolName/lineHint
- hover: signature + JSDoc for a symbol
- definition: jump to declaration (follows re-exports and aliases)
- typeDefinition: resolve generic type parameters
- implementation: find implementations of an abstract method (use the member name, not the class)
- references: usages within the same package (bounded by TS server open files, NOT cross-package)
- callers: cross-package incoming calls — TS/JS/Go/Rust only; use references for Python/C++
- callees: outgoing calls from a function
- callHierarchy: both callers and callees in one call

Token efficiency:
- format:"compact" on callers/callees/callHierarchy → line-oriented strings, ~50% fewer tokens than "structured"
- groupByFile:true on references → per-file summary instead of every call site — use for blast radius checks
- depth controls recursion depth for call trees (default shallow)

Language support:
- Tier 1 (all types): TypeScript, JavaScript, Go, Rust
- Tier 2 (no callHierarchy): Python, C++
- Tier 3 (documentSymbols + hover + definition only): Shell, HTML, CSS, YAML, TOML

Output signals:
- resolvedSymbol.foundAtLine: confirms which line LSP resolved (verify against your lineHint)
- empty result with no error: lineHint or symbolName was wrong — re-run localSearchCode to get accurate values

Next: localGetFileContent(startLine=result.range.start.line) to read the definition; localSearchCode for finding more occurrences.
```

---

## Schema

### `lineHint` field — make the prerequisite hard and explicit

**Current:** `"Needed except for documentSymbols. 1-based line from a prior localSearchCode hit."`

**Proposed:** `"1-based line number of the symbol in the file. Required for all types except documentSymbols. Must come from a real localSearchCode match (matches[0].line) — never estimate or guess. A wrong lineHint causes silent empty results. If uncertain, run localSearchCode first to get the exact line."`

### `symbolName` field

**Current:** `"Needed except for documentSymbols. Exact identifier at lineHint; case-sensitive, no parentheses."`

**Proposed:** `"Exact identifier at lineHint. Required for all types except documentSymbols. Case-sensitive. No parentheses, no type annotations — just the bare name. Example: 'fetchPRDetail' not 'fetchPRDetail()'. Must match the token at lineHint exactly."`

### `format` field

**Current:** `'Output format: "structured" typed objects or "compact" line-oriented strings.'`

**Proposed:** `'Output format for call-flow results (callers/callees/callHierarchy). "structured" (default): typed objects with full location metadata. "compact": line-oriented strings — ~50% fewer tokens, sufficient for most navigation. Use "compact" unless you need to parse location objects programmatically.'`

### `groupByFile` field

**Current:** `"references: compact per-file summary instead of a flat usage list."`

**Proposed:** `"For references type: return a per-file summary (file path + count) instead of listing every call site. Use for blast radius assessment — tells you which files reference the symbol without flooding output. Set false (default) when you need exact line numbers."`

### `depth` field

**Current:** no description.

**Proposed:** `"Call tree recursion depth for callHierarchy/callers/callees. 0: immediate callers/callees only. Higher values trace deeper chains. Default shallow. Raise to 3–5 for full call hierarchy analysis. High depth on widely-used symbols can return very large results — combine with format:'compact'."`

### `orderHint` field

**Current:** `"Nth (0-based) occurrence when symbolName repeats on lineHint."`

**Proposed:** `"0-based index to disambiguate when the same symbolName appears multiple times on lineHint (e.g. overloaded functions, chained calls). Default 0 (first occurrence). If you get the wrong symbol, increment orderHint."`

### `includeDeclaration` field

**Current:** `"references: set false to omit the declaration itself."`

**Proposed:** `"For references type: include the symbol's own declaration in the results. Default true. Set false when you want only callers/usages, not the definition site itself."`

### `workspaceRoot` field

**Current:** no description.

**Proposed:** `"Override the workspace root for LSP server resolution. Omit to auto-detect from the file path. Set explicitly when working with files in a non-standard location or when the auto-detected root is wrong."`

### `contextLines` field

**Current:** `"Lines of context for call-flow previews (callers/callees/callHierarchy)."`

**Proposed:** `"Lines of source context to include around each call site in callers/callees/callHierarchy results. 0: location only. 3–10: enough to understand the calling context. Default 0. Raise to reduce follow-up localGetFileContent calls."`

---

## Output

### Document `resolvedSymbol` — the key verification signal

```
results[0].data.resolvedSymbol?: {
  name: string         → the symbol LSP actually resolved (verify matches symbolName)
  uri: string          → the file LSP found it in (may differ from input uri for re-exports)
  foundAtLine: number  → the line LSP resolved to (verify against lineHint)
  orderHint?: number
}
```

**If `resolvedSymbol` is absent or `foundAtLine` differs significantly from `lineHint`:** lineHint was inaccurate. Re-run `localSearchCode` to get a fresh match line, then retry.

### Document all type-specific output shapes

**`documentSymbols`:**
```
symbols: Array<{
  name: string
  kind: string          → "function" | "class" | "interface" | "variable" | etc.
  range: { start: {line, character}, end: {line, character} }
  children?: symbols[]  → nested symbols
}>
```
Use `range.start.line + 1` as `lineHint` for follow-up LSP calls on specific symbols.

**`definition` / `typeDefinition` / `hover`:**
```
locations: Array<{
  uri: string           → absolute file path
  range: { start: {line, character}, end: {line, character} }
  content?: string      → surrounding source (when contextLines > 0)
}>
```

**`references`:**
- Default: flat `locations[]` with uri + range per usage
- `groupByFile:true`: per-file summary `{ uri, count }[]`

**`callers` / `callees` / `callHierarchy`:**
- `format:"structured"`: location objects with full metadata
- `format:"compact"`: line strings — path:line: snippet

### Key patterns

**Blast radius check:**
```
localSearchCode(symbolName, path)
→ lspGetSemantics(type:"references", groupByFile:true, format:"compact")
→ count files affected
```

**Call chain trace:**
```
lspGetSemantics(type:"callers", depth:3, format:"compact")
→ read the compact tree
→ identify the entry points
```

**File outline before navigating:**
```
lspGetSemantics(type:"documentSymbols", uri)
→ find the symbol name and range.start.line
→ lspGetSemantics(type:"definition", symbolName, lineHint=range.start.line+1)
```
