# Octocode MCP - Next-Gen Features Ideas

> Improving local indexing to compete with Mimir, ACI, and semantic search tools.

---

## 1. Semantic Search with Vector Embeddings

### Motivation
Current: `localSearchCode` uses ripgrep → exact text match only.  
Problem: Can't find "related code" or "similar patterns" — only literal strings.

### Integration
```typescript
// localSearchCode gains new mode
{
  pattern: "user authentication",
  mode: "semantic",           // NEW: 'exact' | 'semantic' | 'hybrid'
  semanticThreshold: 0.7      // similarity score cutoff
}
```

### Impact
- Find code by **intent** not just keywords
- "Find similar functions to this one"
- Auto-suggest related files during research

### Tech Stack
| Option | Pros | Cons |
|--------|------|------|
| **Qdrant** | MIT, fast, production-ready | Requires Docker/binary |
| **LanceDB** | Embedded, zero-config | Newer, less docs |
| **Chroma** | Python-native, simple API | Needs Python bridge |

### POC
```typescript
// src/utils/embeddings.ts
import { OpenAI } from 'openai';
import { QdrantClient } from '@qdrant/js-client-rest';

const qdrant = new QdrantClient({ url: 'http://localhost:6333' });
const openai = new OpenAI();

export async function indexFile(path: string, content: string) {
  const chunks = chunkCode(content, 512); // ~512 tokens per chunk
  const embeddings = await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: chunks.map(c => c.text)
  });
  
  await qdrant.upsert('code', {
    points: chunks.map((chunk, i) => ({
      id: hash(`${path}:${chunk.start}`),
      vector: embeddings.data[i].embedding,
      payload: { path, start: chunk.start, end: chunk.end, text: chunk.text }
    }))
  });
}

export async function semanticSearch(query: string, limit = 10) {
  const [embedding] = (await openai.embeddings.create({
    model: 'text-embedding-3-small',
    input: [query]
  })).data;
  
  return qdrant.search('code', {
    vector: embedding.embedding,
    limit,
    with_payload: true
  });
}
```

---

## 2. AST-Based Code Intelligence

### Motivation
Current: Text search can't distinguish function names from comments.  
Problem: No understanding of code structure, symbols, or relationships.

### Integration
```typescript
// localSearchCode gains symbol awareness
{
  pattern: "handleAuth",
  symbolType: "function",     // NEW: 'function' | 'class' | 'method' | 'variable'
  includeReferences: true     // find usages too
}

// localGetFileContent gains structure
{
  path: "src/auth.ts",
  extractSymbols: true        // NEW: returns parsed symbols
}
```

### Impact
- "Find all functions that call X"
- "Show me classes that implement Y"
- Jump to definition across files

### Tech Stack
| Option | Pros | Cons |
|--------|------|------|
| **tree-sitter** | Fast, multi-language, WASM | Learning curve |
| **ts-morph** | TypeScript-native, rich API | TS/JS only |
| **ctags** | Universal, simple | Less precise |

### POC
```typescript
// src/utils/ast.ts
import Parser from 'tree-sitter';
import TypeScript from 'tree-sitter-typescript';

const parser = new Parser();
parser.setLanguage(TypeScript.typescript);

export function extractSymbols(content: string, path: string): CodeSymbol[] {
  const tree = parser.parse(content);
  const symbols: CodeSymbol[] = [];
  
  const query = new Parser.Query(TypeScript.typescript, `
    (function_declaration name: (identifier) @func)
    (class_declaration name: (type_identifier) @class)
    (method_definition name: (property_identifier) @method)
  `);
  
  for (const match of query.matches(tree.rootNode)) {
    const node = match.captures[0].node;
    symbols.push({
      type: match.pattern === 0 ? 'function' : match.pattern === 1 ? 'class' : 'method',
      name: node.text,
      path,
      range: { start: node.startIndex, end: node.endIndex },
      line: node.startPosition.row + 1
    });
  }
  return symbols;
}
```

---

## 3. Persistent File Index

### Motivation
Current: Every `localSearchCode` runs fresh ripgrep.  
Problem: Repeated searches on same codebase = wasted time.

### Integration
```typescript
// New tool or localSearchCode option
{
  pattern: "auth",
  useIndex: true,             // NEW: use persistent index
  forceReindex: false         // NEW: rebuild if needed
}

// Background indexing via session
{
  "indexOnStartup": true,
  "watchForChanges": true,
  "indexPaths": ["src/", "packages/"]
}
```

### Impact
- 10-100x faster repeated searches
- Instant symbol lookup
- Background incremental updates

### Tech Stack
| Option | Pros | Cons |
|--------|------|------|
| **SQLite** | Embedded, zero-config, FTS5 | No vectors natively |
| **LevelDB** | Fast K/V, embedded | Manual indexing |
| **better-sqlite3** | Sync API, fast | Node.js only |

### POC
```typescript
// src/utils/index.ts
import Database from 'better-sqlite3';

const db = new Database('.octocode/index.db');

db.exec(`
  CREATE TABLE IF NOT EXISTS files (
    path TEXT PRIMARY KEY,
    hash TEXT,
    indexed_at INTEGER
  );
  CREATE VIRTUAL TABLE IF NOT EXISTS content USING fts5(
    path, line, text, tokenize='porter'
  );
  CREATE TABLE IF NOT EXISTS symbols (
    id INTEGER PRIMARY KEY,
    path TEXT,
    name TEXT,
    type TEXT,
    line INTEGER,
    UNIQUE(path, name, line)
  );
  CREATE INDEX IF NOT EXISTS idx_symbols_name ON symbols(name);
`);

export function indexFile(path: string, content: string, hash: string) {
  const lines = content.split('\n');
  
  db.prepare('DELETE FROM content WHERE path = ?').run(path);
  const insert = db.prepare('INSERT INTO content (path, line, text) VALUES (?, ?, ?)');
  
  const batch = db.transaction(() => {
    lines.forEach((text, i) => insert.run(path, i + 1, text));
    db.prepare('INSERT OR REPLACE INTO files VALUES (?, ?, ?)').run(path, hash, Date.now());
  });
  batch();
}

export function searchIndex(query: string) {
  return db.prepare(`
    SELECT path, line, snippet(content, 2, '>>>', '<<<', '...', 32) as match
    FROM content WHERE text MATCH ? ORDER BY rank LIMIT 100
  `).all(query);
}
```

---

## 4. Relationship Graph

### Motivation
Current: Tools find isolated code snippets.  
Problem: No understanding of how code connects (imports, calls, inheritance).

### Integration
```typescript
// New tool: localGraphQuery
{
  startPath: "src/auth.ts",
  query: "imports",           // 'imports' | 'importedBy' | 'calls' | 'calledBy'
  depth: 2                    // traverse depth
}

// localGetFileContent enhancement
{
  path: "src/auth.ts",
  includeGraph: true          // returns import/export edges
}
```

### Impact
- Understand codebase architecture
- Impact analysis: "What breaks if I change X?"
- Smart context gathering for LLMs

### Tech Stack
| Option | Pros | Cons |
|--------|------|------|
| **In-memory graph** | Simple, fast | Lost on restart |
| **SQLite relations** | Persistent, queryable | Not graph-native |
| **Neo4j embedded** | Full graph power | Heavy dependency |

### POC
```typescript
// src/utils/graph.ts
interface GraphNode {
  path: string;
  exports: string[];
  imports: Map<string, string[]>; // path -> imported symbols
}

const graph = new Map<string, GraphNode>();

export function buildGraph(files: { path: string; content: string }[]) {
  for (const { path, content } of files) {
    const imports = extractImports(content);  // from AST
    const exports = extractExports(content);
    graph.set(path, { path, exports, imports });
  }
}

export function getImportedBy(targetPath: string): string[] {
  const results: string[] = [];
  for (const [path, node] of graph) {
    if (node.imports.has(targetPath)) results.push(path);
  }
  return results;
}

export function getDependencyChain(path: string, depth = 3): string[] {
  const visited = new Set<string>();
  const queue = [{ path, level: 0 }];
  
  while (queue.length > 0) {
    const { path: p, level } = queue.shift()!;
    if (visited.has(p) || level > depth) continue;
    visited.add(p);
    
    const node = graph.get(p);
    if (node) {
      for (const imp of node.imports.keys()) {
        queue.push({ path: imp, level: level + 1 });
      }
    }
  }
  return [...visited];
}
```

---

## 5. Quick Wins (No New Dependencies)

### 5.1 De-duplicate Base Hints
```typescript
// Current: 5 hints repeat in EVERY response
// Fix: Move to instructions string, not per-result hints

// Before (in every result)
hints: [
  "Use 'owner', 'repo'...",
  "Follow 'mainResearchGoal'...",
  "Do findings answer...",
  "Got 3+ examples?...",
  "Check pushedAt/lastModified..."
]

// After (once in instructions)
instructions: "Base guidance: use owner/repo fields, follow research goals, stop at 3+ examples.\n\nResult-specific hints below."
```

### 5.2 Fix Byte/Char Offset Confusion
```typescript
// Current output (confusing)
location: {
  byteOffset: 1234,
  charOffset: 1234,  // misleading name
}

// Fix: rename and document
location: {
  byteOffset: 1234,
  byteLength: 50,
  // charOffset removed - was same as byteOffset for ASCII
}
// Add hint: "For UTF-8 with multibyte chars, convert byte offset to char offset"
```

### 5.3 Better PR Search Errors
```typescript
// Current: generic "Invalid search query" error
// Fix: validate and provide specific guidance

if (!params.owner && !params.repo && !params.query) {
  return {
    error: "PR search requires either: (1) owner+repo, (2) prNumber+owner+repo, or (3) query",
    examples: [
      { owner: "facebook", repo: "react", state: "open" },
      { query: "fix auth bug", owner: "my-org" }
    ]
  };
}
```

---

## Priority Matrix

| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| De-dup hints | 2h | Medium | 🔥 P0 |
| Fix offset naming | 1h | Low | 🔥 P0 |
| Better PR errors | 2h | Medium | 🔥 P0 |
| Persistent index (SQLite) | 2d | High | ⭐ P1 |
| AST parsing (tree-sitter) | 3d | High | ⭐ P1 |
| Semantic search | 5d | Very High | 🎯 P2 |
| Relationship graph | 3d | High | 🎯 P2 |

---

## Architecture Vision

```
┌─────────────────────────────────────────────────────────────┐
│                     Octocode MCP v2                         │
├─────────────────────────────────────────────────────────────┤
│  Tools Layer                                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Search   │ │ Content  │ │ Structure│ │ Graph    │       │
│  │(semantic)│ │ (AST)    │ │ (indexed)│ │ (deps)   │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
│       │            │            │            │              │
├───────┼────────────┼────────────┼────────────┼──────────────┤
│  Index Layer       │            │            │              │
│  ┌─────────────────┴────────────┴────────────┴─────────┐   │
│  │                    Unified Index                     │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐  │   │
│  │  │ Vectors │  │ FTS5    │  │ Symbols │  │ Graph  │  │   │
│  │  │ (Qdrant)│  │(SQLite) │  │ (AST)   │  │ (Edges)│  │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
├───────────────────────────┼─────────────────────────────────┤
│  Storage Layer            │                                 │
│  ┌────────────────────────┴────────────────────────────┐   │
│  │              .octocode/index/                        │   │
│  │  index.db (SQLite) │ vectors/ (Qdrant) │ cache/     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Next Steps

1. **P0**: Ship hint cleanup + error improvements (1 day)
2. **P1**: SQLite persistent index + basic FTS (3 days)
3. **P1**: Tree-sitter integration for symbols (3 days)
4. **P2**: Qdrant + embeddings for semantic search (1 week)
5. **P2**: Dependency graph from AST (3 days)

