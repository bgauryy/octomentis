# Summary: Efficient and Flexible Incremental Parsing

Source note: `/Users/guybary/Documents/octocode-mcp/.octocode/research/efficient-and-flexible-incremental-parsing.md`

## Core idea

The paper presents an incremental LR-family parsing algorithm that updates a retained parse tree after arbitrary textual and structural edits. Instead of reparsing from scratch or storing parse states in every tree node, it parses a mixed input stream of:

- newly lexed terminal tokens around changed text, and
- reusable nonterminal subtrees from the previous parse tree.

The key result is an optimal incremental parser with runtime roughly:

```text
O(t + s log N)
```

where:

- `t` = number of new terminal symbols,
- `s` = number of modification sites,
- `N` = number of nodes in the retained parse tree.

The algorithm’s performance depends on the number and scope of edits, not whether the edits occur near the beginning, middle, or end of the file.

The paper also emphasizes that true incrementality requires balanced representation of long repeated structures, plus deliberate node reuse so downstream tools keep stable identities and cached annotations.

## Main mechanisms

### 1. Persistent parse tree as the shared program representation

Incremental parsing assumes the environment keeps a persistent parse tree. Nodes expose constant-time access to:

- parent,
- children,
- grammar production/type,
- local change metadata,
- nested change metadata.

The parser does not need to persist parse-stack links, parser states, or terminal links inside each node.

### 2. Versioned editing model

The paper separates three versions during parsing:

- **Reference**: the most recent parsed version.
- **Previous**: the version immediately before the current parse begins.
- **Current**: the version being constructed by the parser.

A history service reports where changes happened:

- **local changes**: edits directly on a node, such as text changes on a token or structural changes on an internal node.
- **nested changes**: ancestor paths leading to changed descendants.

This lets the parser traverse only affected regions and reuse unchanged subtrees elsewhere.

### 3. Sentential-form parsing instead of state matching

Older incremental LR parsers often store the parser state in each parse tree node and reuse a subtree only if the current parse state matches the stored state. The paper argues that this is sufficient but not necessary, especially poor for LR(1) tables with many similar states.

Sentential-form parsing instead asks:

> Can the grammar symbol represented by this subtree be shifted in the current parser state?

If yes, the subtree can often be reused without inspecting its contents.

Benefits:

- no persistent parser-state fields in nodes,
- more reuse than state matching,
- subtrees can be reused in any grammatically valid context,
- works with LR(1), LALR(1), SLR(1), and related LR-family parsers.

### 4. Left and right breakdowns

When a reused subtree contains changes or cannot be shifted in the current context, the parser breaks it down and exposes smaller pieces.

- **Left breakdown**: decomposes the current lookahead subtree from the left, exposing its first child or the next affected region.
- **Right breakdown**: decomposes the top subtree on the parse stack from the right, undoing reductions whose validity depends on following lookahead.

The first simple algorithm eagerly calls right breakdown after shifting a nonterminal subtree. It is correct but has extra logarithmic overhead.

### 5. Optimistic parsing and delayed backtracking

The optimized algorithm avoids eager right breakdown. It shifts reusable subtrees optimistically and verifies later that the following parse actions are valid.

If the optimism was wrong, it backtracks locally by invoking right breakdown only when an error is detected during verification.

This turns the conservative runtime from about:

```text
O(t + s (log N)^2)
```

into:

```text
O(t + s log N)
```

### 6. Complete nonterminal parse-table transitions

To reduce directly on nonterminal lookahead, the parser table needs complete and correct nonterminal transitions, not only terminal actions.

This is a small parser-generator extension: enumerate valid nonterminal lookahead actions rather than forcing the parser to inspect a subtree just to find its first terminal.

### 7. Ambiguous grammars need fragile-region handling

Many practical parser generators allow ambiguous grammars resolved with static mechanisms such as:

- operator precedence,
- associativity,
- prefer-shift rules,
- production-order reduction precedence.

Plain sentential-form subtree reuse can be wrong for these grammars because the nonterminal shift test does not encode all disambiguation decisions. Example: changing `a + b + c` to involve `*` may require restructuring based on precedence, not just shifting an old expression subtree.

The paper’s solution is to mark ambiguity-sensitive productions or regions as **fragile**:

- directly fragile: production participates in a parse-table conflict,
- dynamically fragile: a subtree exposes fragile structure along its left or right edge.

Fragile subtrees are broken down rather than reused whole. Unambiguous regions still benefit from sentential-form reuse.

### 8. Long sequences must be balanced

A crucial warning: many parse trees are really linked lists because grammars encode lists via left or right recursion:

```text
statements -> statements statement
```

If long sequences remain unbalanced, any incremental parser degenerates toward linear behavior for edits near one end of the list.

The paper recommends representing associative repetitive constructs nondeterministically and balancing them like trees. Grammar notation should distinguish true associative sequences, such as statement lists or declaration lists, from semantically meaningful recursive expressions.

This is what makes `log N` traversal realistic.

### 9. Node reuse is separate from parser correctness

Incremental parsing should not only produce the same parse tree shape as batch parsing; it should preserve stable node identities when conceptually the same program element remains.

The paper defines reuse paths:

- **bottom-up reuse**: reuse a parent when reused children justify keeping it.
- **top-down reuse**: reuse a child when its retained context justifies keeping it.

Unambiguous bottom-up reuse requires all children to remain the same. Ambiguous bottom-up reuse can reuse a parent if at least one child remains, using a policy to resolve competition.

This matters because later tools may attach expensive or user-authored annotations to syntax nodes.

## Best practices for `octocode-engine`

### 1. Treat parsing as an incremental transformation over versioned structure

For future engine features that parse or structurally analyze files, avoid designing the parser as a stateless batch-only pass if results will be reused across requests.

A good internal model is:

```text
old tree + edit/change report -> new tree + reuse report
```

Even if the first implementation reparses whole files, keep APIs compatible with later incremental operation:

- accept previous analysis artifacts,
- return stable node IDs or spans where possible,
- expose changed regions,
- separate tokenization/parsing output from cache invalidation policy.

### 2. Do not store parser implementation state in persistent nodes by default

The paper’s strongest design lesson is to keep persistent syntax nodes semantically meaningful and compact.

Avoid storing fields like:

- LR parse state,
- transient parser stack links,
- temporary lookahead state,
- parser-generator internal IDs that are not part of the syntax contract.

If metadata is needed, prefer transient parse-stack records or side tables. Persistent nodes should primarily store stable syntax identity: kind/production, children, span/text relationship, and analysis annotations.

### 3. Reuse unchanged subtrees by grammar validity, not by old parser state

When reusing parsed structure, prefer tests equivalent to:

```text
is this subtree’s grammar symbol valid in the current context?
```

rather than:

```text
does this subtree have the same old parser state?
```

This increases reuse and keeps parse artifacts portable across parser-table changes.

### 4. Separate correctness from reuse policy

The parser should first guarantee the same structural result as a batch parse. Node reuse should be a deliberate policy layered onto reductions and post-processing.

Useful distinction for engine design:

- **Structural correctness**: the new tree represents the current text correctly.
- **Identity preservation**: unchanged conceptual nodes keep stable IDs.
- **Cache reuse**: downstream analyses reuse annotations only when the preserved identity and changed-region report make that safe.

Do not conflate these concerns in one cache key or one parser branch.

### 5. Balance long repeated constructs

Any parser or structural representation in `octocode-engine` should avoid linked-list-shaped ASTs for long constructs:

- statement lists,
- import lists,
- declarations,
- object members,
- array elements,
- markdown blocks,
- search result groups,
- token streams split into chunks.

Use balanced chunk trees, ropes, green-tree-style nodes, or equivalent structures for long sequences. Otherwise incremental updates will quietly become linear.

Practical rule:

> If a list can grow with file size, do not represent it as a recursive chain.

### 6. Make associativity explicit

Only balance constructs whose grouping is semantically irrelevant. Do not rebalance expressions or syntax where grouping affects meaning, precedence, associativity, comments, formatting, or diagnostics.

For grammar-driven parsers, mark associative list-like grammar constructs explicitly instead of inferring them from recursion shape.

### 7. Track local and nested dirtiness separately

The paper’s local/nested change split is directly useful for engine caches.

For a syntax tree, minified tree, structural-search index, or signature index, track:

- node changed directly,
- descendant changed,
- subtree unchanged.

This enables cheap traversal of only affected regions while still preserving ancestors when safe.

### 8. Use stable sentinel/root nodes for mutable documents

The paper uses permanent sentinel nodes for beginning-of-stream, end-of-stream, and an ultra-root. The practical lesson is to keep stable anchors that survive edits.

For engine internals, useful stable anchors include:

- file identity,
- root document node,
- text rope root,
- beginning/end sentinels for token streams,
- stable range maps for diagnostics and caches.

Stable anchors simplify incremental traversals, diffing, and undo-like transformations.

### 9. Handle ambiguous or context-sensitive syntax conservatively

For languages or modes with ambiguity, do not blindly reuse high-level subtrees. Mark fragile regions and force finer-grained recomputation when disambiguation may change.

Examples relevant to `octocode-engine`:

- TSX/JSX angle-bracket ambiguity,
- JavaScript regex literal vs division,
- TypeScript generic syntax vs comparison,
- Rust macro bodies,
- Markdown fenced code and embedded languages,
- shell/YAML/JSON snippets inside config files,
- operator-precedence-sensitive expression edits.

A subtree that is valid by kind may still be invalid by disambiguation context.

### 10. Keep parser-table and grammar metadata available for analysis

If the engine owns a parser generator or table-driven parser in the future, preserve enough metadata to answer:

- which nonterminals can be shifted from a state,
- which productions participate in conflicts,
- which productions are list/sequence constructs,
- which reductions are safe under partial lookahead,
- which syntax regions are fragile.

This metadata is valuable for incremental parsing, error recovery, and explaining parse decisions.

### 11. Design cache invalidation around reuse paths

For downstream engine features such as signature extraction, minification, structural search, and semantic indexing, reuse should be justified by paths:

- bottom-up: unchanged children imply unchanged parent-derived result,
- top-down: unchanged context implies stable containment identity.

This gives a more principled cache invalidation model than simple span overlap.

### 12. Prefer optimistic reuse with cheap rollback over eager invalidation

The optimized parser wins by reusing optimistically and repairing locally only when evidence proves the reuse invalid.

For engine caches, this translates to:

- assume unchanged subtrees are reusable,
- validate using cheap structural/context checks,
- invalidate only the minimal region when validation fails,
- avoid eagerly clearing large caches on small edits.

### 13. Preserve user-visible and expensive annotations through node identity

The paper’s motivation for node reuse applies beyond IDE annotations. In `octocode-engine`, stable node identity could preserve:

- parsed symbol IDs,
- signature extraction results,
- structural-search captures,
- minification maps,
- diagnostics,
- security scan findings,
- cross-reference/index entries.

If a user changes an identifier spelling, most ancestor nodes should ideally retain identity and cached analysis.

### 14. Treat parser output as reversible/loggable when possible

The paper treats parsing itself as a transformation recorded in the version history. For engine debugging and reliability, this suggests keeping enough traceability to answer:

- what changed between parse versions,
- which nodes were reused,
- which nodes were rebuilt,
- which fragile regions forced recomputation,
- which cache entries were invalidated and why.

This is especially useful for debugging incremental correctness bugs.

## Concrete design implications

If `octocode-engine` later adds deeper native parsing or incremental indexing, a robust architecture would include:

1. **Immutable/green syntax nodes** or versioned nodes with stable identity.
2. **Balanced sequence nodes** for long lists and token chunks.
3. **Change reports** that distinguish local and nested edits.
4. **Reusable subtree validation** based on grammar/context validity.
5. **Fragile-region metadata** for ambiguous syntax.
6. **Explicit reuse reports** for downstream caches.
7. **Parser traces** for debugging incremental behavior.

## What not to copy blindly

The paper is centered on LR-family parser generators and persistent syntax-tree IDEs. `octocode-engine` should not adopt the full design unless it actually owns parser tables and persistent parse trees.

Avoid overengineering current features with:

- custom LR parser generators,
- full document version histories,
- parse-table conflict machinery,
- node-reuse algorithms,

unless a concrete engine feature needs long-lived parse artifacts across edits.

The transferable lessons are broader:

- reuse structure by validity, not by incidental parser state;
- balance long sequences;
- track changes precisely;
- preserve identities for unchanged conceptual nodes;
- treat ambiguous syntax as fragile;
- keep transient parser machinery out of persistent data.
