# Incremental Analysis of Real Programming Languages — Summary for `octocode-engine`

## Source

Research note: `/Users/guybary/Documents/octocode-mcp/.octocode/research/incremental-analysis-of-real-programming-languages.md`

Paper: Tim A. Wagner and Susan L. Graham, **Incremental Analysis of Real Programming Languages**.

## Core idea

The paper argues that real programming languages often cannot be handled cleanly by narrow deterministic parsing models. Languages such as C, C++, Fortran, Haskell, and others contain syntactic constructs whose correct interpretation may depend on later syntactic context, type information, scope bindings, layout rules, or user edits in an incomplete program.

Instead of forcing ambiguity out early with ad hoc parser hacks, the paper proposes an intermediate representation called an **abstract parse DAG**. It explicitly preserves multiple possible interpretations until a later stage has enough information to resolve them. This enables a familiar pass-oriented compiler pipeline while still supporting incremental analysis.

The parser behind this representation is an **incremental generalized LR parser**: it combines GLR parsing for arbitrary context-free grammars with subtree reuse via state matching. Deterministic regions are reused cheaply; only changed or non-deterministic regions are reconstructed.

## Important concepts

### 1. Preserve ambiguity explicitly

When a construct has multiple interpretations, the representation keeps a choice node rather than prematurely choosing one parse. Later syntactic or semantic passes can filter the alternatives.

Example from C/C++:

```c
int foo() {
  int i;
  int j;
  a(b);
  c(d);
  i = 1;
  j = 2;
}
```

The middle lines may be declarations or function calls depending on whether `a` and `c` are type names in scope. A batch compiler may hack around this by feeding symbol-table information into the lexer/parser. The paper instead keeps both interpretations and lets semantic analysis resolve them.

### 2. Separate production nodes from choice nodes

Most of the program is deterministic and can be represented like an ordinary parse tree. Only genuinely ambiguous regions need special representation.

The abstract parse DAG uses:

- normal production nodes for deterministic structure;
- symbol/choice nodes only where multiple interpretations exist;
- subtree and context sharing to avoid exponential blowup.

This is important because ambiguity in real programs is usually local and small.

### 3. Ambiguity is localized in practice

The paper’s empirical result is that real programming-language ambiguity is usually constrained and localized. In measured C and C++ programs, explicitly representing ambiguity added roughly **0–0.5% space overhead** in many cases, and reconstruction overhead stayed below **1%** because non-deterministic regions were tiny.

Practical implication: explicit ambiguity does not necessarily mean huge memory or runtime cost if the representation shares deterministic structure and limits recomputation to affected regions.

### 4. Incrementality depends on subtree reuse

Incremental parsing should not reprocess the whole file after every edit. The parser stores parse-state information in nodes and reuses unchanged subtrees when their left and right context still match.

Key mechanisms:

- changed terminals invalidate only affected ancestors and nearby lookahead-sensitive regions;
- unchanged deterministic subtrees can be shifted in constant time;
- if context changed, only leading/trailing edges may need reconstruction;
- non-deterministic regions are reconstructed atomically, but this is cheap when ambiguity is localized.

### 5. Track dynamic lookahead instead of preserving parser internals

GLR parsing may temporarily fork parsers to obtain more lookahead. The paper avoids making the graph-structured parse stack persistent. Instead, it records enough state in parse DAG nodes to know whether a region was deterministic or required extra dynamic lookahead.

This keeps the long-lived representation focused on program structure, not parser implementation artifacts.

### 6. Disambiguate as early as safely possible

The paper distinguishes several kinds of filters:

- **static syntactic filters**: precedence, associativity, prefer-shift rules; can be encoded in parse tables;
- **dynamic syntactic filters**: e.g. “prefer declaration over expression” rules that require more context;
- **semantic filters**: depend on type/scope/name binding information.

Best practice: apply filters at the earliest stage where the required information is available, but do not destroy alternatives that may need to be reconsidered after future edits.

### 7. Semantic disambiguation should be part of incremental analysis

For ambiguities like C/C++ typedef-name resolution, parsing alone cannot decide. Semantic passes propagate bindings/scopes into ambiguous regions, select the valid interpretation, and then later passes can treat the result like a normal tree.

If semantic information changes, the ambiguous region can be reinterpreted without reparsing the local text.

### 8. Errors should not force total failure

Incomplete or malformed programs may leave ambiguities unresolved indefinitely. This is desirable in interactive/incremental tools: features that do not require full resolution can continue working, while code generation or deeper semantic services can wait.

The representation should support partially resolved analysis states.

## Best practices for `octocode-engine`

### 1. Prefer structured intermediate representations over text-only heuristics

`octocode-engine` should continue moving analysis work toward explicit structured representations rather than relying on regex/text post-processing where language structure matters.

Applicable areas:

- structural search;
- signature extraction;
- context minification;
- LSP symbol/context handling;
- future incremental code analysis features.

Text scanning is useful for discovery, but semantic or syntactic decisions should be represented explicitly when possible.

### 2. Preserve uncertainty instead of guessing too early

When the engine cannot confidently classify a construct, it should avoid forcing a single interpretation. Instead, return a representation that exposes uncertainty to callers.

Examples of useful uncertainty-preserving outputs:

- multiple candidate symbols/signatures;
- ambiguous parse/search matches with confidence or reason metadata;
- unresolved language-server locations distinguished from true absence;
- partial analysis results that explain which stage lacked enough information.

This aligns with the paper’s principle: unresolved ambiguity is data, not an error.

### 3. Keep deterministic fast paths cheap

Most code is not ambiguous. Any richer representation should be pay-as-you-go:

- use ordinary compact nodes/results for deterministic cases;
- allocate ambiguity/choice structures only when needed;
- avoid wrapping every result in heavyweight abstractions just to support rare ambiguous cases.

This mirrors the parse DAG design: conventional tree shape for common cases, choice nodes only for uncommon ambiguity.

### 4. Reuse unchanged work aggressively

For future incremental engine behavior, cache/reuse should operate at structural boundaries, not just whole-file boundaries.

Potential design principles:

- cache by file content hash plus relevant parser/analyzer configuration;
- cache extractable substructures such as symbols, signatures, imports, and search indices;
- invalidate only regions affected by edits when possible;
- separate lexical/textual invalidation from semantic invalidation.

The paper’s main performance lesson is that incremental systems are viable when they avoid redoing deterministic unchanged work.

### 5. Keep parser/analyzer implementation artifacts out of public outputs

The paper warns against making the parser’s internal graph-structured stack the persistent program representation. For `octocode-engine`, public TypeScript/Rust outputs should expose domain concepts, not internal traversal/cache/parser machinery.

Good output concepts:

- symbol;
- range;
- signature;
- match;
- ambiguity/candidate;
- redaction;
- validation result;
- parse/search diagnostics.

Avoid leaking concepts that are purely internal implementation details unless they are intentionally part of the API contract.

### 6. Distinguish “not found” from “not resolved”

The paper’s unresolved ambiguity model maps directly to engine ergonomics. The engine should preserve distinctions such as:

- no match exists;
- match exists but was filtered out;
- language server unavailable;
- syntax could not be parsed;
- semantic information was insufficient;
- result was truncated/minified/sanitized;
- multiple candidates exist.

This is especially important for MCP/LSP tools, where callers may otherwise interpret an empty result as proof of absence.

### 7. Apply filters in layers

Design analysis pipelines as staged filters:

1. cheap lexical/file discovery;
2. syntactic or structural matching;
3. semantic/LSP resolution where available;
4. security sanitization/redaction;
5. response shaping/minification/pagination.

Each stage should document whether it eliminates candidates, annotates them, or preserves alternatives.

### 8. Make semantic filtering reversible or recomputable

If a decision depends on non-local information, such as imports, scope, type definitions, dependency graph, language-server state, or project configuration, avoid making it irreversible in cached data.

A cached syntactic result can often be reused under many semantic contexts. A cached semantic result may need invalidation when project context changes.

### 9. Treat invalid or incomplete source as a first-class case

The engine should be robust against partial files, broken syntax, generated fragments, and edited-in-progress code. Best practices:

- return partial results with diagnostics instead of failing the whole operation;
- isolate invalid regions where possible;
- continue analysis for unaffected regions;
- include explicit warnings when parsing/minification/search fell back to a weaker mode.

This is consistent with the paper’s support for persistent unresolved alternatives in erroneous programs.

### 10. Optimize for localized recomputation

The paper’s key empirical assumption is locality: ambiguities and edits usually affect small regions. Engine features should be designed to exploit this:

- avoid whole-repo recomputation for local changes;
- use range-aware operations where possible;
- keep per-file metadata small and composable;
- represent long sequences in forms that support efficient access/pagination;
- avoid linear scans of huge structures when indexes or balanced representations are practical.

### 11. Avoid duplicate analysis flows

The paper’s staged model reinforces a clean architecture rule for this repository: each analysis responsibility should have one owner. If structural search, minification, sanitization, or LSP resolution already has an owner in `octocode-engine`, extend that owner rather than adding parallel ad hoc implementations in TypeScript wrappers.

### 12. Measure overhead, do not assume it

The paper validates its representation with empirical overhead measurements. Similar changes in `octocode-engine` should be benchmarked with realistic files and repositories.

Useful metrics:

- memory overhead of richer result structures;
- runtime overhead vs existing path;
- cache hit rate;
- false positive / false negative rate for structural extraction;
- behavior on malformed code;
- size impact after minification and pagination.

## Concrete design lessons

### For structural search

- Prefer AST-backed matches when syntax matters.
- Preserve multiple candidate matches if the parser cannot disambiguate confidently.
- Report parse/fallback diagnostics separately from empty search results.
- Keep regex/text search as discovery, not as the final authority for syntactic claims.

### For context minification

- Preserve enough structural information for downstream tools to understand uncertainty.
- Avoid collapsing ambiguous or partially parsed regions into misleading summaries.
- Mark omitted/truncated/sanitized regions explicitly.
- Keep deterministic code paths compact and fast.

### For signature extraction

- Treat overloads, language-specific declarations, macros, generated code, and partial syntax as candidate sets when necessary.
- Expose candidate ranges and confidence/diagnostic metadata rather than selecting arbitrarily.
- Cache syntax-level extraction separately from semantic/LSP refinement.

### For LSP support

- Empty semantic results should carry reason metadata where possible.
- Distinguish unsupported capability, server unavailable, parse error, no references, and ambiguous symbol resolution.
- Use document symbols or local search as fallback evidence, but do not pretend fallback evidence is equivalent to full semantic resolution.

### For security scanning/sanitization

- Sanitization should be a filtering stage with explicit reporting, not silent mutation.
- Preserve structural boundaries where possible so redaction does not destroy the ability to reason about code regions.
- Keep original offsets/ranges or range mappings when practical.

## Main takeaway

The strongest lesson for `octocode-engine` is: **represent structure, uncertainty, and partial knowledge explicitly; make deterministic cases fast; and defer irreversible decisions until the right analysis stage has enough information.**

This produces tools that are more correct on real-world languages, more useful on incomplete code, and easier to evolve without adding ad hoc parser or regex hacks.
