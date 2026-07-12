# Local Vector Databases for TypeScript/Node.js Code Indexing

## Executive Summary

This document compares local vector databases and embedding stores suitable for code indexing and retrieval in TypeScript/Node.js MCP tools. All solutions evaluated run entirely locally without cloud dependencies.

**Top Recommendations:**
1. **LanceDB** - Best overall: Rust-based performance, excellent TypeScript API, persistent storage, handles large-scale data
2. **Vectra** - Best for simplicity: Pure TypeScript, file-backed, ideal for small-medium codebases
3. **Orama** - Best for hybrid search: Full-text + vector search, pure TypeScript, great for code search

---

## Comparison Table

| Vector DB | GitHub | Stars | Language | Persistent Storage | Scale (100K+) | TypeScript API | Performance | Code Features |
|-----------|--------|-------|----------|-------------------|----------------|----------------|-------------|---------------|
| **LanceDB** | [lancedb/lancedb](https://github.com/lancedb/lancedb) | 8.8K | Rust + Node bindings | ✅ Yes (Lance format) | ✅ Yes (petabytes) | ✅ Excellent | ⚡ Very Fast | Multimodal, SQL |
| **Vectra** | [Stevenic/vectra](https://github.com/Stevenic/vectra) | 581 | Pure TypeScript | ✅ Yes (file-backed) | ⚠️ Limited (RAM) | ✅ Excellent | ⚡ Fast (<2ms) | Document chunking |
| **Orama** | [oramasearch/orama](https://github.com/oramasearch/orama) | 10.1K | Pure TypeScript | ✅ Plugin-based | ✅ Yes | ✅ Excellent | ⚡ Fast | Hybrid search, BM25 |
| **ChromaDB** | [chroma-core/chroma](https://github.com/chroma-core/chroma) | 55K+ | Python + JS client | ⚠️ Requires server | ✅ Yes | ⚠️ Client only | ⚡ Fast | - |
| **SQLite VSS** | [asg017/sqlite-vss](https://github.com/asg017/sqlite-vss) | 874 | C++ (SQLite ext) | ✅ Yes (SQLite) | ⚠️ Limited | ⚠️ Basic | ⚡ Fast | SQL queries |
| **USearch** | [unum-cloud/usearch](https://github.com/unum-cloud/usearch) | - | C++ + Node bindings | ❌ In-memory | ✅ Yes | ⚠️ Basic | ⚡⚡ Very Fast | Minimal |
| **HNSW Node** | [yoshoku/hnswlib-node](https://github.com/yoshoku/hnswlib-node) | - | C++ + Node bindings | ❌ In-memory | ✅ Yes | ⚠️ Basic | ⚡⚡ Very Fast | HNSW algorithm |
| **FAISS Node** | Multiple | - | C++ + Node bindings | ⚠️ Manual | ✅ Yes | ⚠️ Basic | ⚡⚡ Very Fast | Facebook's FAISS |

---

## Detailed Analysis

### 1. LanceDB ⭐ **RECOMMENDED**

**GitHub**: https://github.com/lancedb/lancedb  
**NPM**: `@lancedb/lancedb` (v0.24.1)  
**Stars**: 8,800  
**Language**: Rust core + Node.js bindings (native binaries)

#### Features
- ✅ **Persistent Storage**: Lance columnar format (efficient, versioned)
- ✅ **Large Scale**: Handles petabytes of data, billions of vectors
- ✅ **TypeScript API**: Excellent, well-documented SDK
- ✅ **Performance**: Very fast indexing and querying (Rust backend)
- ✅ **Multimodal**: Supports text, images, videos, point clouds
- ✅ **SQL Support**: Query vectors with SQL
- ✅ **Zero-copy**: Efficient memory usage
- ✅ **Versioning**: Automatic data versioning
- ✅ **GPU Support**: Optional GPU acceleration for indexing

#### Architecture
- Core written in Rust for performance
- Node.js bindings via native modules (pre-built binaries)
- Columnar storage format (Lance) optimized for analytics
- Supports both embedded and server modes

#### API Example
```typescript
import * as lancedb from "@lancedb/lancedb";

const db = await lancedb.connect("data/code-index");
const table = await db.createTable("code_vectors", [
  { 
    id: 1, 
    vector: [0.1, 1.0, ...], 
    file: "src/utils.ts",
    function: "calculateTotal",
    code: "export function calculateTotal() {...}"
  }
]);

const results = await table
  .vectorSearch([0.1, 0.3, ...])
  .limit(20)
  .toArray();
```

#### Pros
- Production-ready, mature codebase
- Excellent performance (Rust backend)
- Handles very large datasets
- Rich feature set (SQL, versioning, multimodal)
- Great TypeScript support
- Active development

#### Cons
- Requires native binaries (larger install size)
- More complex than pure JS solutions
- Learning curve for advanced features

#### Best For
- Large codebases (100K+ vectors)
- Production deployments
- When you need SQL queries
- Multimodal data (code + docs + images)

---

### 2. Vectra ⭐ **BEST FOR SIMPLICITY**

**GitHub**: https://github.com/Stevenic/vectra  
**NPM**: `vectra` (v0.12.3)  
**Stars**: 581  
**Language**: Pure TypeScript/Node.js

#### Features
- ✅ **Persistent Storage**: File-backed (folder-based indexes)
- ✅ **TypeScript API**: Excellent, Pinecone-compatible
- ✅ **Performance**: Very fast (<1ms for small, 1-2ms for medium)
- ✅ **Zero Infrastructure**: No servers, just files
- ✅ **Document Support**: Built-in chunking and retrieval
- ✅ **Metadata Filtering**: MongoDB-style query operators
- ✅ **Hybrid Retrieval**: Optional BM25 keyword search
- ✅ **Portable**: Language-agnostic file format

#### Architecture
- Pure TypeScript implementation
- File-backed storage (one folder per index)
- In-memory at query time (entire index loaded)
- Simple JSON-based format

#### API Example
```typescript
import { LocalIndex } from 'vectra';
import path from 'node:path';

const index = new LocalIndex(path.join(process.cwd(), 'code-index'));

if (!(await index.isIndexCreated())) {
  await index.createIndex({
    version: 1,
    metadata_config: { indexed: ['file', 'language'] }
  });
}

await index.insertItem({
  vector: await getVector('function calculateTotal()'),
  metadata: { 
    file: 'src/utils.ts',
    language: 'typescript',
    code: 'export function calculateTotal() {...}'
  }
});

const results = await index.queryItems(
  queryVector,
  '',
  10,
  { language: { $eq: 'typescript' } }
);
```

#### Pros
- Pure TypeScript (no native dependencies)
- Simple mental model (one folder = one index)
- Fast for small-medium datasets
- Great TypeScript API
- Document chunking built-in
- Portable file format

#### Cons
- Entire index loads into RAM
- Not suitable for very large datasets (millions of vectors)
- Linear scan (no advanced indexing like HNSW)
- Limited to single-machine usage

#### Best For
- Small-medium codebases (<100K vectors)
- Development/local workflows
- When simplicity is priority
- Document-based code indexing

#### Performance Notes
- Small indexes: <1ms per query
- Medium indexes: 1-2ms per query
- Memory: ~12KB per 1536-dim vector (in-memory)
- Limits: Not for multi-million vector corpora

---

### 3. Orama ⭐ **BEST FOR HYBRID SEARCH**

**GitHub**: https://github.com/oramasearch/orama  
**NPM**: `@orama/orama` (v3.1.18)  
**Stars**: 10,131  
**Language**: Pure TypeScript/JavaScript

#### Features
- ✅ **Persistent Storage**: Plugin-based (`@orama/plugin-data-persistence`)
- ✅ **TypeScript API**: Excellent, well-designed
- ✅ **Hybrid Search**: Full-text + vector search
- ✅ **BM25**: Keyword-based ranking
- ✅ **Performance**: Fast (microseconds for small datasets)
- ✅ **Browser Support**: Works in browser, Node.js, edge
- ✅ **Plugins**: Rich ecosystem (embeddings, analytics, etc.)
- ✅ **Facets**: Advanced filtering and faceting

#### Architecture
- Pure TypeScript/JavaScript
- In-memory by default
- Plugin system for persistence
- Supports full-text, vector, and hybrid search

#### API Example
```typescript
import { create, insert, search } from '@orama/orama';

const db = create({
  schema: {
    file: 'string',
    code: 'string',
    embedding: 'vector[1536]'
  }
});

await insert(db, {
  file: 'src/utils.ts',
  code: 'export function calculateTotal() {...}',
  embedding: [0.1, 0.2, ...]
});

// Hybrid search (full-text + vector)
const results = await search(db, {
  term: 'calculate total',
  mode: 'hybrid',
  vector: {
    value: queryVector,
    property: 'embedding'
  }
});
```

#### Pros
- Pure TypeScript (no native dependencies)
- Excellent hybrid search (full-text + vector)
- Rich plugin ecosystem
- Works everywhere (browser, Node.js, edge)
- Great TypeScript support
- Active development

#### Cons
- In-memory by default (requires plugin for persistence)
- Plugin-based persistence may be less mature
- May not scale as well as native solutions

#### Best For
- Code search with keyword matching
- When you need full-text search alongside vectors
- Browser-based code indexing
- Hybrid retrieval scenarios

---

### 4. ChromaDB

**GitHub**: https://github.com/chroma-core/chroma  
**NPM**: `chromadb` (v3.2.2)  
**Stars**: 55,000+  
**Language**: Python server + JavaScript client

#### Features
- ⚠️ **Local Mode**: Requires running ChromaDB server locally
- ✅ **TypeScript Client**: Good client library
- ✅ **Scale**: Handles large datasets
- ✅ **Performance**: Fast when server is running

#### Architecture
- Python-based server (requires separate process)
- JavaScript/TypeScript client library
- REST API communication
- Can run locally but requires server setup

#### Pros
- Very popular and mature
- Good client library
- Handles large datasets
- Rich feature set

#### Cons
- **Not fully local**: Requires running server process
- Python dependency for server
- More complex setup than embedded solutions
- Not ideal for "zero infrastructure" use case

#### Best For
- When you can run a local server
- Multi-language environments
- Existing ChromaDB infrastructure

---

### 5. SQLite VSS ⚠️ **DEPRECATED**

**GitHub**: https://github.com/asg017/sqlite-vss  
**NPM**: `sqlite-vss` (v0.1.2)  
**Stars**: 874  
**Language**: C++ (SQLite extension)

#### Status
⚠️ **Not in active development** - Author recommends [`sqlite-vec`](https://github.com/asg017/sqlite-vec) instead.

#### Features (Historical)
- ✅ Persistent storage (SQLite)
- ✅ SQL queries
- ⚠️ Limited to 1GB indices
- ⚠️ CPU-only (no GPU)
- ⚠️ No mmap support (must fit in RAM)

#### Recommendation
**Skip** - Use `sqlite-vec` instead if you need SQLite-based vector search.

---

### 6. USearch

**GitHub**: https://github.com/unum-cloud/usearch  
**NPM**: `usearch` (v2.21.4)  
**Language**: C++ + Node.js bindings

#### Features
- ❌ **In-Memory Only**: No built-in persistence
- ✅ **Performance**: Very fast (C++ backend)
- ✅ **Scale**: Handles large datasets
- ⚠️ **API**: Basic Node.js bindings

#### Pros
- Extremely fast
- Handles large datasets
- Multiple metric types supported

#### Cons
- No persistence (must implement yourself)
- Basic TypeScript API
- Less mature than other options

#### Best For
- When you need maximum performance
- When you can implement your own persistence
- Low-level vector search needs

---

### 7. HNSW Node Libraries

**NPM Packages**:
- `hnswlib-node` (v3.0.0) - https://github.com/yoshoku/hnswlib-node
- `hnswlib-wasm` (v0.8.2) - WASM version

#### Features
- ❌ **In-Memory Only**: No built-in persistence
- ✅ **Performance**: Very fast (HNSW algorithm)
- ✅ **Scale**: Handles large datasets efficiently
- ⚠️ **API**: Basic Node.js bindings

#### Pros
- HNSW algorithm (state-of-the-art)
- Very fast approximate nearest neighbor search
- Handles large datasets efficiently

#### Cons
- No persistence (must implement yourself)
- Basic TypeScript API
- Lower-level than full vector DB solutions

#### Best For
- When you need HNSW algorithm specifically
- When you can implement your own persistence layer
- Building custom vector search solutions

---

### 8. FAISS Node Bindings

**NPM Packages**:
- `faiss-node` (v0.5.1) - https://github.com/ewfian/faiss-node
- `faiss-napi` (v0.10.3) - Alternative implementation

#### Features
- ⚠️ **Persistence**: Manual (must save/load indices)
- ✅ **Performance**: Very fast (Facebook's FAISS)
- ✅ **Scale**: Handles very large datasets
- ⚠️ **API**: Basic Node.js bindings

#### Pros
- Industry-standard (Facebook's FAISS)
- Very fast
- Handles very large datasets
- Multiple index types

#### Cons
- No built-in persistence
- Basic TypeScript API
- Complex to use (low-level)
- Requires understanding of FAISS index types

#### Best For
- When you need FAISS specifically
- Research/experimentation
- Building custom solutions

---

## Recommendations for TypeScript MCP Tool

### Primary Recommendation: **LanceDB**

**Why:**
1. ✅ **Production-ready**: Mature, well-maintained, handles scale
2. ✅ **Performance**: Rust backend provides excellent speed
3. ✅ **TypeScript API**: Excellent developer experience
4. ✅ **Persistent Storage**: Efficient Lance format with versioning
5. ✅ **Large Scale**: Handles 100K+ vectors easily
6. ✅ **Features**: SQL queries, multimodal support, GPU optional

**Use Case**: Production code indexing for large repositories

---

### Secondary Recommendation: **Vectra**

**Why:**
1. ✅ **Simplicity**: Pure TypeScript, no native dependencies
2. ✅ **File-Backed**: Simple folder-based storage
3. ✅ **Fast**: Sub-millisecond queries for small-medium datasets
4. ✅ **TypeScript API**: Excellent, Pinecone-compatible
5. ✅ **Document Support**: Built-in chunking for code

**Use Case**: Development/local workflows, small-medium codebases

---

### Alternative: **Orama**

**Why:**
1. ✅ **Hybrid Search**: Full-text + vector search (great for code)
2. ✅ **Pure TypeScript**: No native dependencies
3. ✅ **BM25**: Keyword matching alongside semantic search
4. ✅ **Plugin System**: Extensible architecture

**Use Case**: When you need keyword search alongside semantic search

---

## Implementation Considerations

### For Code Indexing Specifically

1. **Chunking Strategy**: Code benefits from AST-aware chunking
   - Vectra: Built-in document chunking
   - LanceDB/Orama: Manual chunking required

2. **Metadata**: Code has rich metadata (file path, function name, language, etc.)
   - All solutions support metadata filtering
   - Vectra: MongoDB-style queries
   - LanceDB: SQL queries

3. **Update Frequency**: Code changes frequently
   - LanceDB: Versioning support
   - Vectra: File-based, easy to rebuild
   - Orama: In-memory, requires re-indexing

4. **Scale**: Code repositories can be large
   - LanceDB: Best for large scale
   - Vectra: Limited by RAM
   - Orama: Plugin-based persistence

### Performance Benchmarks (Estimated)

| Solution | Indexing (10K vectors) | Query (10K vectors) | Memory (10K vectors) |
|----------|------------------------|---------------------|----------------------|
| LanceDB | ~5-10s | <10ms | ~100MB |
| Vectra | ~2-5s | <2ms | ~120MB |
| Orama | ~3-6s | <5ms | ~150MB |
| USearch | ~1-3s | <1ms | ~60MB |
| HNSW Node | ~2-4s | <2ms | ~80MB |

*Note: Benchmarks are estimates based on documentation and typical performance. Actual results vary by hardware and data.*

---

## Conclusion

For a TypeScript MCP tool doing code indexing:

1. **Choose LanceDB** if you need production-scale, persistent storage, and excellent performance
2. **Choose Vectra** if you prioritize simplicity, pure TypeScript, and small-medium codebases
3. **Choose Orama** if you need hybrid search (full-text + vector) for code

All three solutions are excellent choices with different strengths. The decision depends on your specific requirements for scale, simplicity, and search capabilities.
