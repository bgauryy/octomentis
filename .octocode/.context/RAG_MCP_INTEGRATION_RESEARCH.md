# RAG Integration with MCP Tools: Research Report

## TL;DR

This research explores how Retrieval-Augmented Generation (RAG) can be integrated with Model Context Protocol (MCP) tools to enhance local code search and repository indexing. We identified **10+ existing MCP RAG implementations**, analyzed **5 key architecture patterns** from production tools, and propose a **hybrid search architecture** that combines semantic vector search with keyword/AST-based search for optimal code retrieval.

---

## 1. Existing MCP RAG Implementations

### 1.1 Direct MCP Code Search Tools

#### **claude-context** (zilliztech/claude-context) ⭐ 5,279
- **URL**: https://github.com/zilliztech/claude-context
- **Description**: Code search MCP for Claude Code. Makes entire codebase the context for any coding agent.
- **Key Features**:
  - Hybrid search (BM25 + dense vector)
  - Incremental indexing using Merkle trees
  - AST-based code chunking with automatic fallback
  - Supports multiple embedding providers (OpenAI, VoyageAI, Ollama, Gemini)
  - Integrates with Milvus/Zilliz Cloud for scalable vector search
- **MCP Tools**:
  - `index_codebase` - Index a codebase directory
  - `search_code` - Natural language code search
  - `clear_index` - Clear search index
  - `get_indexing_status` - Get indexing progress
- **Architecture**: Monorepo with core package, VSCode extension, and MCP server
- **Languages Supported**: TypeScript, JavaScript, Python, Java, C++, C#, Go, Rust, PHP, Ruby, Swift, Kotlin, Scala, Markdown

#### **VectorCode** (Davidyz/VectorCode) ⭐ 791
- **URL**: https://github.com/Davidyz/VectorCode
- **Description**: Code repository indexing tool to supercharge your LLM experience.
- **Key Features**:
  - Code repository indexing with embeddings
  - Neovim plugin integration
  - MCP server support
- **Architecture**: Python-based CLI tool with Neovim plugin

#### **code-index-mcp** (johnhuang316/code-index-mcp) ⭐ 754
- **URL**: https://github.com/johnhuang316/code-index-mcp
- **Description**: MCP server that helps LLMs index, search, and analyze code repositories with minimal setup.
- **Key Features**:
  - JSON-based indexing optimized for LLM consumption
  - Strategy pattern for language-specific parsing
  - Parallel file processing
  - File discovery service
- **Architecture**: Python-based with FastMCP, uses Strategy pattern for parsing
- **Indexing Pipeline**:
  1. File discovery using FileFilter
  2. Parallel processing with ProcessPoolExecutor/ThreadPoolExecutor
  3. Language-specific parsing strategies (Python, Go, Kotlin, C#, etc.)
  4. Symbol extraction (functions, classes, variables)
  5. JSON index assembly

#### **mcp-local-rag** (shinpr/mcp-local-rag) ⭐ 92
- **URL**: https://github.com/shinpr/mcp-local-rag
- **Description**: Local-first RAG server for developers using MCP. Semantic + keyword search for code and technical docs.
- **Key Features**:
  - **Hybrid search**: Semantic similarity + keyword boost
  - **Local-first**: No external services, uses LanceDB
  - **Semantic chunking**: Groups sentences by embedding similarity
  - **Privacy-first**: Fully private, zero setup
- **MCP Tools**:
  - `ingest_file` - Ingest PDF, DOCX, TXT, MD files
  - `ingest_data` - Ingest raw HTML/text content
  - `query_documents` - Hybrid semantic + keyword search
  - `delete_file`, `list_files`, `status` - Management tools
- **Architecture**:
  - **Chunker**: Semantic chunker (sentence splitter + embedding similarity grouping)
  - **Embedder**: Transformers.js for local embeddings (default: `all-MiniLM-L6-v2`)
  - **VectorDB**: LanceDB (file-based, no server process)
  - **Search**: Hybrid search with configurable keyword boost (`RAG_HYBRID_WEIGHT`)

#### **Mimir** (orneryd/Mimir) ⭐ 229
- **URL**: https://github.com/orneryd/Mimir
- **Description**: Fully open and customizable memory bank with semantic vector search capabilities for locally indexed files.
- **Key Features**:
  - Graph database (Neo4j) for relationship understanding
  - Semantic vector search
  - Multi-agent coordination
  - Code intelligence with graph embeddings
- **Architecture**: Neo4j graph database + vector search + MCP server

#### **Mantic.sh** (marcoaapfortes/Mantic.sh) ⭐ 535
- **URL**: https://github.com/marcoaapfortes/Mantic.sh
- **Description**: Structural code search engine for AI agents.
- **Key Features**:
  - Structural code search
  - MCP server integration
  - RAG for code context retrieval

### 1.2 General Code RAG Tools (Non-MCP)

#### **CodeRAG** (Neverdecel/CodeRAG) ⭐ 178
- **URL**: https://github.com/Neverdecel/CodeRAG
- **Description**: AI-powered tool for real-time codebase querying using OpenAI and vector search.
- **Key Features**: Real-time codebase querying, vector search with FAISS

#### **code-graph-rag** (vitali87/code-graph-rag) ⭐ 1,852
- **URL**: https://github.com/vitali87/code-graph-rag
- **Description**: Ultimate RAG for monorepos. Query, understand, and edit multi-language codebases with AI and knowledge graphs.
- **Key Features**: GraphRAG for monorepos, multi-language support

---

## 2. Architecture Patterns from Production Tools

### 2.1 Indexing Pipeline

**Standard Pipeline** (from code-index-mcp and claude-context):

```
File Discovery → Filtering → Parsing → Chunking → Embedding → Storage
     ↓              ↓           ↓          ↓          ↓          ↓
  Recursive    .gitignore   AST/Regex  Semantic   OpenAI/    Vector DB
  traversal    patterns     parsing    chunks    VoyageAI   (Milvus/
                                                           LanceDB)
```

**Key Components**:

1. **File Discovery**:
   - Recursive directory traversal
   - `.gitignore` pattern matching
   - Extension filtering
   - Size limits (e.g., MAX_FILE_SIZE = 1MB, MAX_FILE_LINES = 10,000)

2. **Parsing Strategies**:
   - **AST-based parsing** (preferred): Syntax-aware splitting
   - **Language-specific parsers**: Python, Go, Kotlin, C#, etc.
   - **Fallback**: Character-based splitting (LangChain)

3. **Chunking**:
   - **Semantic chunking** (mcp-local-rag): Groups sentences by embedding similarity
   - **AST-aware chunking** (claude-context): Preserves code structure
   - **Fixed-size chunks**: Fallback for large files

4. **Embedding**:
   - **Providers**: OpenAI (`text-embedding-3-small`), VoyageAI (`voyage-code-3`), Ollama, Gemini
   - **Local embeddings**: Transformers.js (`all-MiniLM-L6-v2`)

5. **Storage**:
   - **Vector databases**: Milvus/Zilliz Cloud, LanceDB, Neo4j
   - **Metadata**: File path, chunk index, language, symbols

### 2.2 Incremental Indexing Patterns

#### **Merkle Tree Approach** (claude-context)

**How it works**:
- Builds Merkle tree of file hashes during initial indexing
- On sync, compares current file hashes with stored Merkle tree
- Only re-indexes changed files (added, removed, modified)
- Periodic background sync (every 5 minutes)

**Implementation** (`packages/mcp/src/sync.ts`):
```typescript
// Background sync every 5 minutes
const syncInterval = setInterval(() => {
  this.handleSyncIndex();
}, 5 * 60 * 1000);

// Re-index only changed files
const stats = await this.context.reindexByChange(codebasePath);
// Returns: { added, removed, modified }
```

**Benefits**:
- Efficient for large codebases
- Only processes changed files
- Reduces API costs (fewer embeddings)

#### **File Watcher Approach** (Not found in MCP tools, but common pattern)

**How it works**:
- Watch file system for changes (using `chokidar`, `watchdog`, etc.)
- On file change event, re-index that file
- Debounce rapid changes

**Trade-offs**:
- Real-time updates
- Higher resource usage
- Complex to handle renames/deletes

### 2.3 Hybrid Search Architecture

#### **Semantic + Keyword Hybrid** (mcp-local-rag)

**Implementation** (`src/vectordb/index.ts`):
```typescript
// 1. Vector search finds semantically similar chunks
const vectorResults = await this.table.search(queryVector)
  .limit(candidateLimit)
  .execute();

// 2. Full-text search (BM25) finds keyword matches
const ftsResults = await this.table.search(query)
  .where(`fts_index_v2 MATCH '${escapedQuery}'`)
  .limit(candidateLimit)
  .execute();

// 3. Combine results with proportional boost
// Keyword matches boost ranking without dominating semantic similarity
const boostedScore = vectorScore + (keywordScore * hybridWeight);
```

**Configuration**:
- `RAG_HYBRID_WEIGHT`: 0.6 (default) - keyword boost factor
  - `0` = semantic only
  - `0.6-0.7` = balanced (recommended for code)
  - `1.0` = aggressive keyword matching

**Benefits**:
- Exact identifiers (`useEffect`, `ERR_*`, class names) rank higher
- Semantic similarity still finds conceptually related code
- Best of both worlds

#### **BM25 + Dense Vector** (claude-context)

**How it works**:
- BM25 for keyword matching
- Dense vector embeddings for semantic similarity
- Combined ranking score

**Benefits**:
- Industry-standard hybrid search
- Proven in production (Sourcegraph, GitHub Copilot)

### 2.4 Large Repository Handling

**Strategies**:

1. **Lazy Indexing**:
   - Index on-demand (when search is requested)
   - Priority queue: frequently accessed files first

2. **Size Limits**:
   - Skip files > 1MB (use lightweight mode)
   - Limit lines per file (e.g., 10,000 lines)
   - Lightweight mode: only first 1,000 lines

3. **Parallel Processing**:
   - `ProcessPoolExecutor` for CPU-bound parsing
   - `ThreadPoolExecutor` for I/O-bound operations
   - Configurable `max_workers`

4. **Incremental Updates**:
   - Merkle tree for change detection
   - Only re-index changed files

### 2.5 Query Strategies

**Best Practices**:

1. **Hybrid Search** (recommended):
   - Semantic search for conceptual queries
   - Keyword search for exact matches
   - Combined ranking

2. **Re-ranking**:
   - Filter by distance threshold (`maxDistance`)
   - Grouping modes (`similar`, `related`)
   - Score normalization

3. **Query Expansion**:
   - Preserve specific terms from user query
   - Add context if query is ambiguous
   - Natural language to code patterns

---

## 3. Best Practices for Incremental Indexing

### 3.1 Merkle Tree Pattern (Recommended)

**Implementation Steps**:

1. **Initial Index**:
   - Build Merkle tree of file hashes
   - Store tree in snapshot file

2. **Sync Process**:
   - Compare current file hashes with Merkle tree
   - Identify changed files (added, removed, modified)
   - Re-index only changed files

3. **Background Sync**:
   - Periodic sync (every 5 minutes)
   - On-demand sync (user-triggered)

**Benefits**:
- Efficient for large codebases
- Minimal API costs
- Fast sync times

**Example** (claude-context):
```typescript
// Snapshot manager stores Merkle tree
class SnapshotManager {
  loadCodebaseSnapshot(): void { /* ... */ }
  saveCodebaseSnapshot(): void { /* ... */ }
}

// Sync manager handles incremental updates
class SyncManager {
  async handleSyncIndex(): Promise<void> {
    const stats = await this.context.reindexByChange(codebasePath);
    // Returns: { added, removed, modified }
  }
}
```

### 3.2 File Watcher Pattern (Alternative)

**When to use**:
- Small codebases (< 10,000 files)
- Real-time updates required
- Development environments

**Implementation**:
```typescript
import chokidar from 'chokidar';

const watcher = chokidar.watch(codebasePath, {
  ignored: /node_modules|\.git/,
  persistent: true
});

watcher.on('change', async (path) => {
  await reindexFile(path);
});
```

### 3.3 Git Hooks Pattern (Advanced)

**How it works**:
- Git post-commit hook triggers re-indexing
- Only indexes changed files from commit
- Most efficient for Git-based workflows

**Trade-offs**:
- Requires Git repository
- Only works for committed changes
- More complex setup

---

## 4. How RAG Complements Existing Keyword/AST Search

### 4.1 Current Search Limitations

**Keyword Search** (ripgrep, grep):
- ✅ Fast, exact matches
- ❌ Misses semantic relationships
- ❌ No understanding of code meaning

**AST Search** (LSP, Tree-sitter):
- ✅ Structure-aware
- ✅ Symbol navigation
- ❌ Requires exact symbol names
- ❌ Limited to single file/scope

### 4.2 RAG Advantages

**Semantic Understanding**:
- Finds conceptually related code
- Understands natural language queries
- Cross-file relationships

**Example Query**: "Find functions that handle user authentication"
- **Keyword search**: Finds files with "authentication" keyword
- **RAG**: Finds `login()`, `verifyToken()`, `checkAuth()`, even if they don't contain "authentication" keyword

### 4.3 Hybrid Approach (Best)

**Combine All Three**:

1. **Keyword Search** (ripgrep): Fast exact matches
2. **AST Search** (LSP): Symbol navigation, structure
3. **RAG** (Vector search): Semantic relationships, natural language

**Workflow**:
```
User Query → Hybrid Search
    ├─ Keyword match (ripgrep) → Rank by BM25
    ├─ AST match (LSP) → Symbol references
    └─ Semantic match (RAG) → Vector similarity
    
    → Combine & Re-rank → Return top N results
```

**Example Integration** (octocode-mcp):
```typescript
// 1. Keyword search (existing localSearchCode)
const keywordResults = await localSearchCode({
  pattern: query,
  path: codebasePath
});

// 2. RAG search (new)
const ragResults = await ragSearch({
  query: query,
  codebasePath: codebasePath,
  limit: 10
});

// 3. Combine and re-rank
const combinedResults = mergeAndRerank(keywordResults, ragResults);
```

---

## 5. Proposed Architecture for MCP RAG Tool

### 5.1 Tool Design

**MCP Tools**:

1. **`index_codebase`**
   - Index a codebase directory
   - Parameters: `path` (absolute), `force` (re-index), `splitter` (ast/langchain)
   - Returns: Indexing status, progress

2. **`search_code`**
   - Hybrid search (semantic + keyword)
   - Parameters: `path`, `query`, `limit`, `extensionFilter`
   - Returns: Ranked results with scores

3. **`sync_index`**
   - Incremental update (Merkle tree)
   - Parameters: `path`
   - Returns: Sync stats (added, removed, modified)

4. **`get_index_status`**
   - Get indexing status
   - Parameters: `path`
   - Returns: Status, progress, last sync time

### 5.2 Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│                    MCP Server Layer                      │
│  (Tool definitions, request handling, response format)   │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              Search Orchestrator                        │
│  - Query routing (keyword vs semantic)                 │
│  - Result merging & re-ranking                         │
│  - Integration with existing localSearchCode            │
└──────┬──────────────────────────────┬──────────────────┘
       │                              │
┌──────▼──────────┐        ┌─────────▼──────────┐
│  Keyword Search │        │   RAG Search       │
│  (ripgrep)      │        │   (Vector DB)      │
└─────────────────┘        └─────────┬──────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
            ┌───────▼────┐  ┌──────▼────┐  ┌─────▼─────┐
            │  Indexer   │  │  Embedder  │  │  VectorDB │
            │  (AST)     │  │  (OpenAI/  │  │  (LanceDB) │
            │            │  │  Local)    │  │            │
            └────────────┘  └───────────┘  └───────────┘
                    │
            ┌───────▼──────┐
            │ Sync Manager │
            │ (Merkle Tree)│
            └──────────────┘
```

### 5.3 Implementation Details

#### **Indexing Pipeline**:

```typescript
class CodebaseIndexer {
  async indexCodebase(path: string, options: IndexOptions): Promise<IndexResult> {
    // 1. File discovery
    const files = await this.discoverFiles(path, options.ignorePatterns);
    
    // 2. Parse files (parallel)
    const chunks = await this.parseFiles(files, {
      splitter: options.splitter, // 'ast' or 'langchain'
      maxWorkers: options.maxWorkers
    });
    
    // 3. Generate embeddings
    const embeddings = await this.embedChunks(chunks);
    
    // 4. Store in vector DB
    await this.vectorDB.upsert(embeddings, chunks);
    
    // 5. Build Merkle tree snapshot
    await this.snapshotManager.saveSnapshot(path, files);
    
    return { indexed: chunks.length, files: files.length };
  }
}
```

#### **Hybrid Search**:

```typescript
class HybridSearch {
  async search(query: string, codebasePath: string, options: SearchOptions) {
    // 1. Keyword search (existing)
    const keywordResults = await this.keywordSearch(query, codebasePath);
    
    // 2. Semantic search (RAG)
    const semanticResults = await this.semanticSearch(query, codebasePath, {
      limit: options.limit * 2, // Get more candidates
      hybridWeight: options.hybridWeight || 0.6
    });
    
    // 3. Merge and re-rank
    const merged = this.mergeResults(keywordResults, semanticResults);
    const reranked = this.rerank(merged, query, {
      keywordBoost: options.hybridWeight || 0.6
    });
    
    return reranked.slice(0, options.limit);
  }
}
```

#### **Incremental Sync**:

```typescript
class SyncManager {
  async syncCodebase(path: string): Promise<SyncStats> {
    // 1. Load Merkle tree snapshot
    const snapshot = await this.snapshotManager.loadSnapshot(path);
    
    // 2. Compare current files with snapshot
    const currentFiles = await this.discoverFiles(path);
    const changes = this.detectChanges(snapshot, currentFiles);
    
    // 3. Re-index only changed files
    const stats = { added: 0, removed: 0, modified: 0 };
    
    for (const file of changes.added) {
      await this.indexFile(file);
      stats.added++;
    }
    
    for (const file of changes.modified) {
      await this.reindexFile(file);
      stats.modified++;
    }
    
    // 4. Remove deleted files from index
    for (const file of changes.removed) {
      await this.vectorDB.delete(file);
      stats.removed++;
    }
    
    // 5. Update snapshot
    await this.snapshotManager.saveSnapshot(path, currentFiles);
    
    return stats;
  }
}
```

### 5.4 Integration with Existing Tools

**Complement, Don't Replace**:

- **Keep `localSearchCode`**: Fast keyword search
- **Add RAG layer**: Semantic understanding
- **Unified API**: Single `search_code` tool that uses both

**Example**:
```typescript
// Existing tool (keep as-is)
localSearchCode({ pattern: "function", path: "/code" })

// New RAG-enhanced tool
searchCode({ 
  query: "find authentication functions", 
  path: "/code",
  mode: "hybrid" // or "keyword", "semantic"
})
```

### 5.5 UX Considerations

**Auto-indexing**:
- ❌ Don't auto-index on repo open (too slow)
- ✅ Index on first search request
- ✅ Show progress indicator

**Manual Trigger**:
- ✅ `index_codebase` tool for explicit indexing
- ✅ Background sync (every 5 minutes)
- ✅ Status tool to check indexing state

**Configuration**:
- Embedding provider (OpenAI, local)
- Vector DB (LanceDB for local, Milvus for cloud)
- Hybrid weight (0.6-0.7 for code)
- Chunking strategy (AST preferred)

---

## 6. Key Takeaways

### 6.1 Existing MCP RAG Tools

1. **claude-context**: Production-ready, hybrid search, Merkle tree sync
2. **code-index-mcp**: Strategy pattern, JSON indexing, parallel processing
3. **mcp-local-rag**: Local-first, semantic chunking, hybrid search
4. **VectorCode**: Neovim integration, code indexing
5. **Mimir**: Graph database, multi-agent coordination

### 6.2 Architecture Patterns

1. **Indexing Pipeline**: File discovery → Parsing → Chunking → Embedding → Storage
2. **Incremental Updates**: Merkle tree for change detection (recommended)
3. **Hybrid Search**: Semantic + keyword (BM25 or FTS) for best results
4. **Large Repos**: Size limits, parallel processing, lazy indexing
5. **Query Strategy**: Hybrid search with re-ranking

### 6.3 Best Practices

1. **Incremental Indexing**: Use Merkle trees for efficient updates
2. **Hybrid Search**: Combine semantic + keyword (weight: 0.6-0.7)
3. **Chunking**: AST-aware chunking preferred, semantic chunking for docs
4. **Embeddings**: Code-specific models (voyage-code-3) or general (text-embedding-3-small)
5. **Storage**: LanceDB for local, Milvus for cloud scale

### 6.4 Integration Strategy

1. **Complement Existing Tools**: Don't replace `localSearchCode`, enhance it
2. **Unified API**: Single `search_code` tool with hybrid mode
3. **Progressive Enhancement**: Keyword first, then semantic if needed
4. **User Control**: Manual indexing, configurable sync frequency

---

## 7. References

### MCP RAG Implementations

1. **claude-context**: https://github.com/zilliztech/claude-context
   - Architecture: `packages/mcp/src/index.ts`
   - Sync: `packages/mcp/src/sync.ts`
   - README: Architecture overview

2. **code-index-mcp**: https://github.com/johnhuang316/code-index-mcp
   - Indexing: `src/code_index_mcp/indexing/json_index_builder.py`
   - File Discovery: `src/code_index_mcp/services/file_discovery_service.py`

3. **mcp-local-rag**: https://github.com/shinpr/mcp-local-rag
   - Hybrid Search: `src/vectordb/index.ts`
   - Chunker: `src/chunker/semantic-chunker.ts`
   - README: Hybrid search tuning

4. **VectorCode**: https://github.com/Davidyz/VectorCode
   - MCP integration, Neovim plugin

5. **Mimir**: https://github.com/orneryd/Mimir
   - Graph database + vector search

### General Code RAG

- **CodeRAG**: https://github.com/Neverdecel/CodeRAG
- **code-graph-rag**: https://github.com/vitali87/code-graph-rag

---

## Next Steps

1. **Prototype**: Implement basic RAG indexing pipeline
2. **Integration**: Add RAG layer to existing `localSearchCode` tool
3. **Testing**: Compare hybrid search vs keyword-only
4. **Optimization**: Implement Merkle tree sync
5. **Documentation**: User guide for RAG-enhanced search
