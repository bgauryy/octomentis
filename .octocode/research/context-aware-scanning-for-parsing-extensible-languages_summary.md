# Summary: Context-Aware Scanning for Parsing Extensible Languages

Source note: `/Users/guybary/Documents/octocode-mcp/.octocode/research/context-aware-scanning-for-parsing-extensible-languages.md`

## Core idea

The paper proposes coupling an LR parser with a context-aware scanner. Instead of scanning the next token from the full token vocabulary, the parser passes the scanner the set of terminals that are valid in the current parse state. The scanner then only returns tokens from that valid lookahead set.

This lets the scanner resolve many lexical ambiguities using syntactic context:

- `SELECT` can be an identifier in Java context and a SQL keyword inside an embedded SQL query.
- `table` can mean different extension keywords in different grammar contexts.
- `>>` can be scanned as two `>` tokens in generic type syntax when the shift operator is not valid.
- `=` can have separate Java-assignment and SQL-equality token identities, each with its own precedence.

The scanner intentionally subordinates “maximal munch” to “valid in this context”: a shorter valid token beats a longer invalid token.

## Mechanism

### 1. Valid lookahead set

For each LR parse state, compute:

```text
validLA(state) = { terminal | parseTable[state, terminal] is shift, reduce, or accept }
```

The parser passes `validLA` to the scanner at each token boundary.

### 2. Scanner returns a set, not one token

The context-aware scanner interface is effectively:

```text
nextToken(validLookaheadSet, inputPosition) -> (set<Token>, newPosition)
```

Outcomes:

- `0` tokens: lexical/parse error.
- `1` token: deterministic success.
- `>1` tokens: lexical ambiguity; either reject at generation time or resolve with a declared disambiguation function.

Important invariant:

```text
returnedTokens ⊆ validLookaheadSet
```

### 3. DFA possible-token sets

The scanner DFA tracks not only accepted terminals for a state, but also terminals that may still be accepted from reachable future states:

```text
poss(state) = terminals that can be accepted after consuming more input from state
```

During scanning, it intersects `poss(state)` with `validLA`. Scanning stops when no valid token can still be reached.

This avoids scanning past a valid context-specific boundary just because some globally valid longer token exists.

### 4. Explicit lexical precedence

The paper rejects global textual-order precedence from lexer specs because extensible grammars are composed from unordered modules. Instead it uses explicit precedence relations, commonly via lexer classes:

```text
keyword dominates identifier
identifier submitsTo keywordClass
```

Precedence is asymmetric and non-transitive. Only relationships that matter are declared.

### 5. Static lexical determinism analysis

The generator can prove scanner determinism by checking every parser state and scanner DFA accept state:

```text
for every parseState and scannerState:
  after applying validLA and lexical precedence,
  at most one terminal remains accepted
```

If ambiguity remains, the language spec must provide a disambiguation function for that exact ambiguity set.

### 6. Static optimization of precedence

Instead of applying precedence dynamically during scanning, the generator can precompute DFA `accept` and `reject` sets:

- Move lower-precedence accepted terminals into a DFA-state reject set.
- Use fast set intersections at scan time.
- Represent terminal sets as bit vectors because the terminal universe is known at generation time.

### 7. Error reporting strategy

A context-aware scanner can return no token for misplaced-but-lexically-valid input because it only sees valid tokens. For better diagnostics, rerun scanning at the error position with the full terminal set to identify the unexpected lexeme, then report it alongside the expected valid lookahead set.

## Best practices for `octocode-engine`

### 1. Prefer context-aware tokenization when parsing mixed or extensible languages

`octocode-engine` deals with code search, structural search, minification, signature extraction, sanitization, and language-aware processing across many languages. When a feature needs parsing or tokenization, avoid assuming one global token meaning per lexeme.

Useful principle:

> Token meaning should be constrained by the syntactic or analysis context whenever possible.

This matters for embedded languages and mixed syntaxes such as:

- Markdown with fenced code blocks.
- TSX/JSX where `<` may start a tag, generic type, or comparison.
- SQL strings or template literals embedded in JS/TS.
- Shell snippets in YAML, package scripts, CI config, Dockerfiles, or Markdown.
- Rust macros or language constructs with context-sensitive token interpretation.

### 2. Do not over-rely on maximal munch

Maximal munch is simple but can be wrong when a longer token is invalid in the current context. Engine parsers/scanners should prefer:

1. Valid in current grammar/context.
2. Explicit lexical precedence.
3. Longest match only among context-valid candidates.

This is especially relevant for lightweight parsers and minifiers that currently may operate with regex-like or token-stream assumptions.

### 3. Keep lexical precedence explicit and local

Avoid hidden precedence based on declaration order, regex order, or language-module load order. For maintainable multi-language scanning, precedence rules should be explicit, inspectable, and narrow.

Good pattern:

```text
Keyword > Identifier only in contexts where the keyword must be reserved.
```

Bad pattern:

```text
Every keyword always beats every identifier globally.
```

The second approach breaks non-reserved keywords and embedded DSLs.

### 4. Separate token classes from token identities

A lexeme like `=` or `table` may need multiple token identities depending on language mode or grammar context. The engine should not collapse same-text tokens too early if downstream analysis needs different semantics.

Example lesson:

- `=` in host language assignment and `=` in embedded SQL equality can be separate tokens even with the same lexeme.
- Those tokens can then carry different precedence, associativity, or analysis behavior.

### 5. Use deterministic analysis before runtime heuristics

For generated or semi-generated parsers, prefer build-time validation that proves ambiguity cannot happen. If ambiguity is unavoidable, require an explicit resolver for the exact ambiguity set.

For `octocode-engine`, this maps to:

- Detect ambiguous scanner/parser states during test/build time.
- Fail loudly when a language grammar or scanner extension introduces unresolved ambiguity.
- Avoid broad runtime “guessing” rules that silently choose plausible interpretations.

### 6. Represent token candidate sets efficiently

If a parser/scanner knows the full terminal universe, use compact set representations such as bitsets rather than dynamic string/set objects on hot paths.

Practical engine implication:

- Precompute valid-token sets, accept sets, reject sets, and precedence masks.
- Runtime scanning should mostly be bit operations and table lookups.
- This fits Rust well and keeps native-engine parsing/minification paths fast.

### 7. Memoize scan results across parser reductions

The paper notes that after LR reduce actions, the next valid lookahead set is often a subset of the previous one and still contains the already-scanned token. Rescanning can often be avoided.

Engine lesson:

- If implementing parser-driven scanning, cache the last scan result at an input offset.
- Reuse it when the new context still accepts the selected token.
- Invalidate/rescan only when dynamic disambiguation depends on mutable parser attributes.

### 8. Treat disambiguation functions as exceptional, not normal

Disambiguation functions are useful for cases like C typedef-name versus identifier, but they couple scanning to semantic state.

Best practice:

- Prefer grammar context and lexical precedence first.
- Use semantic disambiguation only for unavoidable language cases.
- Keep resolvers small, named, and tied to a specific ambiguity set.
- Test resolver behavior with parser-state changes and incremental parsing scenarios.

### 9. Improve parse errors with a second broad scan

When context-aware scanning returns no token, diagnostics should not stop at “expected one of X.” Run a non-contextual or full-terminal scan at the same offset to identify the actual unexpected token.

For `octocode-engine`, this is useful for developer-facing diagnostics in:

- Structural search parsing.
- Query parsing.
- Language-aware minification/signature extraction.
- Any future grammar-based local analysis.

Better diagnostic shape:

```text
Unexpected token `class`; expected identifier, type, or expression.
```

rather than:

```text
No token matched valid lookahead set.
```

### 10. Design grammar extensions as composable modules

The paper’s central extensibility lesson is that host-language and DSL grammar modules should compose by set union, with explicit conflict checks. Extension authors should not need to know the whole parse table.

For the engine, this suggests:

- Language-specific scanner/parser modules should declare their tokens, precedence, layout rules, and embeddings explicitly.
- Composition should run validation rather than rely on import order.
- Adding support for a new embedded language should not require global rewrites of existing tokenizers.

### 11. Allow layout rules to vary by embedded language

Whitespace and comments are not universal. Embedded languages may need different layout handling than the host.

Examples:

- Markdown fenced code blocks preserve newlines.
- Python indentation is syntax.
- SQL inside JS strings has different comment and whitespace rules.
- Table-like DSLs may use newline as a row separator.

Engine scanners should avoid one global “ignore whitespace/comments” rule when analyzing mixed-language content.

### 12. Keep scanner/parser coupling deliberate

The paper acknowledges that disjoint scanners are simpler and should be used when sufficient. Context-aware scanning is valuable when the disjoint model causes ambiguity, awkward grammar hacks, or incorrect tokenization.

Rule of thumb for `octocode-engine`:

- Use simple disjoint tokenization for regular, single-language, unambiguous tasks.
- Use parser-informed/context-aware scanning for mixed syntax, embedded DSLs, non-reserved keywords, or ambiguous operators.

## Where this could apply in `octocode-engine`

Potential areas to evaluate:

1. **Structural search parsing** — avoid regex-shaped approximations when syntax context can disambiguate constructs.
2. **Signature extraction** — correctly handle context-sensitive tokens in TSX, generics, macros, or embedded declarations.
3. **Minification** — preserve or remove whitespace based on syntactic context, not generic token adjacency alone.
4. **Security scanning** — avoid false positives/negatives by recognizing embedded language regions and token roles.
5. **Query/config parsing** — parse small engine query languages with explicit deterministic ambiguity checks.
6. **Future language plugin architecture** — validate token/grammar extension composition at build time.

## Main takeaway

For `octocode-engine`, the strongest lesson is not “use LR everywhere.” It is:

> Make scanners context-sensitive where ambiguity matters, make precedence explicit, prove determinism ahead of runtime, and keep runtime scanning table-driven and bitset-fast.

This provides a useful design target for robust multi-language code analysis: deterministic behavior, fewer grammar hacks, better embedded-language handling, and clearer diagnostics when parsing fails.
