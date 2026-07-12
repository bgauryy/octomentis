# Local Explorer MCP - Best Practices & Implementation Guide

**Generated from analysis of actual tool implementations and Linux kernel documentation**

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Performance Optimization](#performance-optimization)
3. [Tool-Specific Best Practices](#tool-specific-best-practices)
4. [Common Pitfalls & Fixes](#common-pitfalls--fixes)
5. [Architecture Patterns](#architecture-patterns)
6. [Security Guidelines](#security-guidelines)
7. [Token Optimization](#token-optimization)

---

## Core Principles

### 1. Bulk Operations First (5-10x Faster)
**All tools support parallel batch processing via `queries` arrays.**

```typescript
// ✅ BEST: Process multiple searches in parallel
{
  queries: [
    { pattern: "auth", type: "ts" },
    { pattern: "config", type: "json" },
    { pattern: "error", mode: "discovery" }
  ]
}

// ❌ AVOID: Sequential single queries
// Makes 3 separate calls instead of 1
```

**Why it works**: From `bulkOperations.ts:125-127`:
```typescript
const promises = queries.map((query) => processFn(query));
const results = await settleAll(promises);
```
All queries execute in parallel with Promise.all under the hood.

---

### 2. Progressive Disclosure Workflow
**Start broad, then narrow down.**

```
Step 1: DISCOVERY (fast, ~20 tokens per result)
  ├─ VIEW_STRUCTURE (depth=1) → See directory layout
  ├─ RIPGREP (filesOnly=true) → Find which files contain pattern
  └─ FIND_FILES (name pattern) → Locate files by metadata

Step 2: FILTERED SEARCH (moderate detail)
  ├─ RIPGREP (contextLines=3, charLength=10000)
  └─ FIND_FILES (with time/size filters)

Step 3: TARGETED READ (detailed)
  └─ FETCH_CONTENT (matchString or line range)
```

---

## Performance Optimization

### Token Efficiency (Critical for LLM Performance)

#### 1. Discovery Mode (25x Token Reduction)
```typescript
// ✅ BEST: Discovery first
{
  mode: "discovery",      // or filesOnly: true
  pattern: "validateUser",
  type: "ts"
}
// Returns: ~20 tokens per file (just paths)

// ❌ AVOID: Full content search immediately
{
  mode: "detailed",
  pattern: "validateUser"
}
// Returns: ~500+ tokens per file (with context)
```

#### 2. Targeted Extraction (85% Token Savings)
```typescript
// ✅ BEST: Extract specific sections with matchString
{
  path: "/src/auth.ts",
  matchString: "validateUser",
  matchStringContextLines: 20
}
// Returns: Only matching sections (~15% of file)

// ❌ AVOID: Reading full file
{
  path: "/src/auth.ts",
  fullContent: true
}
// Returns: Entire file content (100% tokens)
```

#### 3. Pagination (Prevents Token Explosion)
```typescript
// ✅ BEST: Always paginate large results
{
  pattern: "error",
  contextLines: 3,
  charLength: 10000  // REQUIRED!
}

// ❌ DANGEROUS: Context without pagination
{
  pattern: "error",
  contextLines: 3
  // Missing charLength → 7-8x output explosion!
}
```

**From `local_fetch_content.ts:134-145`**:
```typescript
const estimatedTokens = Math.ceil(resultContent.length / 4);
if (!query.charLength && resultContent.length > maxContentLength) {
  return {
    error: `Result is ${resultContent.length.toLocaleString()} chars (~${estimatedTokens.toLocaleString()} tokens). Please use charLength parameter.`,
    hints: ['RECOMMENDED: charLength=10000 (paginate results)']
  };
}
```

#### 4. Minification (30-60% Token Savings)
```typescript
// ✅ BEST: Use minification (default)
{
  path: "/src/utils.ts",
  minified: true  // Default: removes whitespace, normalizes
}

// ⚠️ WHEN TO DISABLE: Config files that need formatting
{
  path: "/config.json",
  minified: false  // Keep JSON structure readable
}
```

#### 5. Limit Matches Per File
```typescript
// ✅ BEST: Prevent output explosion
{
  pattern: "error",
  maxMatchesPerFile: 3  // Default: 3 matches per file
}

// ❌ AVOID: No limit (can return thousands)
{
  pattern: "error"
  // Could return 100+ matches per file!
}
```

---

### File Type Filters (25% Performance Gain)

```typescript
// ✅ BEST: Use type parameter (cleaner, faster)
{
  type: "ts",
  pattern: "interface"
}

// ✅ GOOD: Use {} for multiple extensions (25% faster)
{
  include: ["*.{ts,tsx}"],
  pattern: "Component"
}

// ❌ AVOID: Separate globs (slower!)
{
  include: ["*.ts", "*.tsx"]  // Makes separate passes
}
```

**Why**: Ripgrep's `--type` flag is optimized internally, glob alternatives require pattern expansion.

---

### Always Exclude Build Artifacts

```typescript
// ✅ RECOMMENDED: Default exclusions
{
  excludeDir: ["node_modules", ".git", "dist", ".cache", "build"]
}

// Real impact: Reduces search space by 80-90% in typical projects
```

---

## Tool-Specific Best Practices

### RIPGREP (Primary Content Search)

#### Discovery → Detailed Pattern
```typescript
// Step 1: Discovery (find which files)
{
  mode: "discovery",
  pattern: "validateUser",
  type: "ts"
}

// Step 2: Detailed (get context from specific files)
{
  mode: "detailed",
  pattern: "validateUser",
  include: ["src/auth.ts", "src/validators.ts"]  // From step 1 results
}
```

#### Pattern Safety
```typescript
// ✅ BEST: Use fixedString for literals (faster, safer)
{
  pattern: "TODO:",
  fixedString: true  // No regex parsing, no injection risk
}

// ⚠️ ONLY USE REGEX WHEN NEEDED
{
  pattern: "function\\s+\\w+",
  perlRegex: false  // Basic regex
}

// 🔥 ADVANCED: PCRE2 with lookahead/lookbehind
{
  pattern: "(?<=export )\\w+",
  perlRegex: true  // Perl-compatible regex
}
```

#### Context Lines (CRITICAL WARNING)
```typescript
// ❌ DANGEROUS: 7-8x output explosion
{
  contextLines: 3,
  pattern: "error"
  // Without charLength, this returns MASSIVE results
}

// ✅ SAFE: Always pair with charLength
{
  contextLines: 3,
  charLength: 10000,
  pattern: "error"
}
```

**From `hints.ts:40`**:
> "Warning: contextLines without charLength → massive output"

#### Multiline Mode (Memory Warning)
```typescript
// ⚠️ USE SPARINGLY: Loads entire files into memory
{
  multiline: true,
  multilineDotall: true,
  pattern: "struct \\{[\\s\\S]*?field"
}

// ✅ PREFER: Single-line patterns when possible
{
  pattern: "struct.*field"  // Works for most cases
}
```

---

### FIND_FILES (Metadata Search)

#### Time-Based Search (CORRECT FORMAT)
```typescript
// ✅ CORRECT: Use specific format
{
  modifiedWithin: "7d"   // 7 days
}
{
  modifiedWithin: "2h"   // 2 hours
}
{
  modifiedWithin: "30m"  // 30 minutes
}

// ❌ WRONG: Natural language doesn't work
{
  modifiedWithin: "7 days"      // ❌ Won't work!
  modifiedWithin: "2 hours"     // ❌ Won't work!
  modifiedWithin: "last week"   // ❌ Won't work!
}
```

#### Size Format (CORRECT UNITS)
```typescript
// ✅ CORRECT: No space, suffix only
{
  sizeGreater: "10M",  // 10 megabytes
  sizeLess: "1G"       // 1 gigabyte
}

// ❌ WRONG: Full unit names or spaces
{
  sizeGreater: "10MB"   // ❌ Won't work!
  sizeGreater: "10 M"   // ❌ Won't work!
}
```

#### Depth Control (Performance)
```typescript
// ✅ BEST: Use depth limits (default: 5)
{
  maxDepth: 3,        // Stop at 3 levels deep
  name: "*.test.ts"
}

// ⚠️ WARNING: Deep nesting without limit
{
  name: "*.ts"
  // Searches all depths (can be slow in large repos)
}
```

#### Unique Feature: Permission Filtering
```typescript
// Only FIND_FILES has permission search
{
  permissions: "755",     // Unix permissions
  executable: true,       // Boolean filter
  path: "/scripts"
}
```

---

### FETCH_CONTENT (File Reader)

#### Three Reading Modes
```typescript
// 1️⃣ TARGETED EXTRACTION (BEST - 85% savings)
{
  path: "/src/auth.ts",
  matchString: "validateUser",
  matchStringContextLines: 20
}

// 2️⃣ LINE RANGE (Good for known sections)
{
  path: "/src/utils.ts",
  startLine: 1,
  endLine: 100,
  charLength: 5000  // Paginate if needed
}

// 3️⃣ FULL CONTENT (Use sparingly)
{
  path: "/src/small-file.ts",
  fullContent: true,
  charLength: 10000  // REQUIRED for files >100KB
}
```

#### File Size Validation
**From `local_fetch_content.ts:68-75`**:
```typescript
if (fileSizeKB > 100 && query.fullContent && !query.charLength) {
  return {
    error: 'fullContent=true REQUIRES charLength for files >100KB',
    hints: [
      'RECOMMENDED: charLength=10000 (paginate through file)',
      `Full file would be approximately ${Math.round(fileSizeKB * 0.25)}K tokens`
    ]
  };
}
```

#### Minification Control
```typescript
// ✅ ENABLE for code files (default)
{
  path: "/src/component.tsx",
  minified: true  // 30-60% token savings
}

// ❌ DISABLE for config files
{
  path: "/config.json",
  minified: false  // Preserve JSON formatting
}
{
  path: "/.prettierrc",
  minified: false  // Preserve YAML structure
}
```

---

### VIEW_STRUCTURE (Directory Explorer)

#### Depth Strategy
```typescript
// Step 1: Overview (fast)
{
  path: "/project",
  depth: 1  // See top-level only
}

// Step 2: Drill down (based on Step 1 findings)
{
  path: "/project/src",
  depth: 2  // Include subdirectories
}

// ⚠️ AVOID: Deep recursion on large dirs
{
  path: "/project",
  depth: 5  // Very slow on large codebases!
}
```

#### Tree View (New Feature)
```typescript
// ✅ BEST: Visual tree structure (default)
{
  path: "/project/src",
  treeView: true,  // Shows hierarchy with visual lines
  depth: 2
}
// Output:
// src
// │
// ├── components
// │   ├── Button.tsx
// │   └── Input.tsx
// └── utils
//     └── helpers.ts

// Legacy: Metadata view
{
  path: "/project/src",
  treeView: false,
  details: true  // Shows size, perms, dates
}
```

#### Sorting & Filtering
```typescript
// Find largest files
{
  path: "/project",
  sortBy: "size",
  reverse: true,
  filesOnly: true
}

// Find recent changes
{
  path: "/project/src",
  sortBy: "time",
  details: true
}

// Filter by extension
{
  path: "/project",
  extensions: ["ts", "tsx"],
  filesOnly: true
}
```

---

### VIEW_BINARY (Binary Inspector)

#### Safe Binary Analysis
```typescript
// Step 1: Identify file type
{
  operation: "identify",
  path: "/app.jar"
}

// Step 2: List archive contents
{
  operation: "list-archive",
  path: "/app.jar",
  maxFiles: 100
}

// Step 3: Extract and search within archive
{
  operation: "extract-file",
  path: "/app.jar",
  archiveFile: "config.properties",
  matchString: "database"  // Search within extracted file
}
```

#### String Extraction
```typescript
// ✅ BEST: Use appropriate minLength
{
  operation: "strings",
  path: "/binary",
  minLength: 8,        // Cleaner output (default: 6)
  charLength: 10000    // Paginate results
}

// ⚠️ WARNING: Low minLength = noise
{
  operation: "strings",
  minLength: 3  // Returns many junk strings
}
```

#### Windows Binaries
```typescript
// ✅ Use UTF-16LE for Windows executables
{
  operation: "strings-utf16le",
  path: "/app.exe",
  minLength: 8
}

// ❌ WRONG: ASCII strings on Windows binary
{
  operation: "strings",  // Misses UTF-16 strings!
  path: "/app.exe"
}
```

**Best Practice Check** (from `local_view_binary.ts:185`):
```typescript
// Check file size first (best practice)
const fileSize = await getFileSize(sanitizedPath);
```

---

## Common Pitfalls & Fixes

### 1. Token Limit Exceeded (25K MCP Limit)

**Problem**: Bulk response exceeds MCP token limit

**From `bulkOperations.ts:292-332`**:
```typescript
const estimatedTokens = Math.ceil(formattedText.length / 4);
const MAX_MCP_TOKENS = 25000;

if (estimatedTokens > MAX_MCP_TOKENS) {
  return {
    error: `Response is ${estimatedTokens.toLocaleString()} tokens (max: ${MAX_MCP_TOKENS.toLocaleString()})`,
    hints: [
      '1. Use pagination (charLength=10000) on individual queries',
      '2. Reduce number of queries per batch',
      '3. Use more specific filters (matchString, startLine/endLine)',
      '4. Use filesOnly=true for search operations',
      `Safe limit per query: approximately ${Math.floor(MAX_MCP_TOKENS / flatResults.length)} tokens`
    ]
  };
}
```

**Solutions**:
```typescript
// ❌ TOO LARGE: 10 queries with full content
{
  queries: [
    { path: "file1.ts", fullContent: true },
    { path: "file2.ts", fullContent: true },
    // ... 8 more
  ]
}

// ✅ FIX 1: Use pagination
{
  queries: [
    { path: "file1.ts", fullContent: true, charLength: 10000 },
    { path: "file2.ts", fullContent: true, charLength: 10000 }
  ]
}

// ✅ FIX 2: Use targeted extraction
{
  queries: [
    { path: "file1.ts", matchString: "function", matchStringContextLines: 10 },
    { path: "file2.ts", matchString: "class", matchStringContextLines: 10 }
  ]
}

// ✅ FIX 3: Reduce query count (split into batches)
// Batch 1:
{ queries: [/* first 5 queries */] }
// Batch 2:
{ queries: [/* next 5 queries */] }
```

---

### 2. Context Lines Without Pagination

**Problem**: Output explosion when using contextLines

```typescript
// ❌ DANGEROUS: Returns 7-8x more data
{
  pattern: "error",
  contextLines: 3
}
// Each match returns 7 lines (3 before + 1 match + 3 after)
// × 100 matches = 700 lines instead of 100!

// ✅ FIX: Always use charLength
{
  pattern: "error",
  contextLines: 3,
  charLength: 10000  // Paginate results
}
```

---

### 3. Wrong Time/Size Format

**Problem**: Natural language formats don't work

```typescript
// ❌ WRONG: Natural language
{
  modifiedWithin: "7 days",
  sizeGreater: "10MB"
}

// ✅ CORRECT: Specific format
{
  modifiedWithin: "7d",   // d/h/m only
  sizeGreater: "10M"      // k/M/G only
}
```

---

### 4. Separate Glob Patterns (Performance Hit)

**Problem**: Each glob makes a separate pass

```typescript
// ❌ SLOW: Makes 2 passes
{
  include: ["*.ts", "*.tsx"]
}

// ✅ FAST: Single pass with alternatives (25% faster)
{
  include: ["*.{ts,tsx}"]
}
```

---

### 5. Missing Exclusions (Wasted Search Time)

**Problem**: Searching through build artifacts

```typescript
// ❌ SLOW: Searches everything
{
  pattern: "config",
  path: "/project"
}
// Searches node_modules, dist, .git (80-90% wasted time)

// ✅ FAST: Exclude build artifacts
{
  pattern: "config",
  path: "/project",
  excludeDir: ["node_modules", ".git", "dist", ".cache"]
}
```

---

### 6. Minified JSON/YAML Files

**Problem**: Minification breaks structure

```typescript
// ❌ WRONG: Minify config files
{
  path: "/config.json",
  minified: true  // Breaks JSON structure
}

// ✅ CORRECT: Disable for config files
{
  path: "/config.json",
  minified: false  // Preserve formatting
}
```

---

### 7. Multiline Without Need

**Problem**: Loads entire files into memory

```typescript
// ❌ SLOW: Unnecessarily uses multiline
{
  pattern: "function.*{",
  multiline: true  // Loads full file!
}

// ✅ FAST: Use single-line pattern
{
  pattern: "function.*\\{"  // Works on individual lines
}
```

---

## Architecture Patterns

### 1. Bulk Operations Structure

**From `bulkOperations.ts`**:

```typescript
/**
 * Standard pattern for all tools
 */
export async function executeBulkOperation<TQuery, TResult>(
  queries: Array<TQuery>,
  processor: (query: TQuery) => Promise<TResult>,
  config: { toolName: string }
): Promise<CallToolResult> {
  // 1. Execute all queries in parallel
  const promises = queries.map((query) => processor(query));
  const results = await settleAll(promises);

  // 2. Categorize by status
  const hasResults = results.filter(r => r.status === 'hasResults');
  const empty = results.filter(r => r.status === 'empty');
  const errors = results.filter(r => r.status === 'error');

  // 3. Collect hints by status
  const hasResultsHints = new Set<string>();
  const emptyHints = new Set<string>();
  const errorHints = new Set<string>();

  // 4. Build response
  return {
    instructions: `Bulk response from ${toolName}...`,
    results: flatResults,
    summary: { total, hasResults, empty, errors },
    hasResultsStatusHints: [...hasResultsHints],
    emptyStatusHints: [...emptyHints],
    errorStatusHints: [...errorHints]
  };
}
```

### 2. Hint System (Connection-Aware)

**From `hints.ts:1-8`**:
```typescript
/**
 * Smart, connection-aware hints for local file search tools
 * Optimized for token efficiency and intelligent research flows
 *
 * PHILOSOPHY: Guide LLMs through logical research paths using connection matrix
 * EFFICIENCY: Concise, actionable, connection-driven
 */
```

**Hint Categories**:
1. **hasResults**: Next logical workflow steps
2. **empty**: Alternative search strategies
3. **error**: Specific solutions with parameters

**Example from `hints.ts:38-42`**:
```typescript
hasResults: [
  'Next (strong): RIPGREP search patterns | FIND_FILES filter by metadata',
  'Next (moderate): FETCH_CONTENT read interesting files',
  'Optimize: depth=1-2 quick | sortBy="time"/"size" | bulk queries parallel',
  'Warning: depth>2 on large dirs very slow | >1000 entries needs charLength'
]
```

### 3. Defense in Depth Security

**Three-Layer Validation**:

#### Layer 1: Path Validation
```typescript
// pathValidator.ts
export function validatePath(
  path: string,
  allowedRoots: string[]
): ValidationResult {
  // 1. Normalize path (resolve ../, ./)
  const normalized = resolve(path);

  // 2. Check allowed roots
  if (!allowedRoots.some(root => normalized.startsWith(root))) {
    return { valid: false, error: 'Path outside allowed directories' };
  }

  // 3. Check blocked patterns
  if (BLOCKED_PATHS.some(pattern => normalized.includes(pattern))) {
    return { valid: false, error: 'Path matches blocked pattern' };
  }

  return { valid: true, path: normalized };
}
```

**Blocked Patterns** (from `patternsConstants.ts`):
- Credentials: `.env`, `*.key`, `*.pem`, `credentials.json`
- System: `/etc`, `/sys`, `/proc`, `/dev`
- Temporary: `/tmp`
- Build: `node_modules`, `dist`, `.git`

#### Layer 2: Command Validation
```typescript
// commandValidator.ts
export function validateCommand(
  command: string[],
  allowedCommands: Set<string>
): ValidationResult {
  // 1. Check command is allowed
  if (!allowedCommands.has(command[0])) {
    return { valid: false, error: 'Command not allowed' };
  }

  // 2. Check for injection patterns
  for (const arg of command.slice(1)) {
    if (INJECTION_PATTERNS.some(p => p.test(arg))) {
      return { valid: false, error: 'Invalid argument' };
    }
  }

  return { valid: true };
}
```

**Allowed Commands**:
- `rg` (ripgrep)
- `find`
- `ls`
- `file`
- `unzip` (read-only)
- `strings`

**Injection Prevention**:
- Shell metacharacters: `; | & $ ( ) > < \` ` " '`
- Command substitution: `$(...)`, `` `...` ``
- Newlines and null bytes

#### Layer 3: Execution Context Validation
- Process isolation
- Timeout enforcement (30s default)
- Resource limits
- Read-only operations

---

## Security Guidelines

### 1. Path Safety

```typescript
// ✅ SAFE: Allowed paths
{
  path: "/home/user/project"
}
{
  path: "/Users/username/code"
}

// ❌ BLOCKED: Sensitive paths
{
  path: "/etc/passwd"         // System config
}
{
  path: "/Users/user/.env"    // Credentials
}
{
  path: "/var/log"            // System logs
}
```

### 2. Pattern Safety

```typescript
// ✅ SAFE: Use fixedString for user input
{
  pattern: userInput,
  fixedString: true  // No regex injection
}

// ⚠️ CAREFUL: Validate regex patterns
function validateUserPattern(pattern: string): boolean {
  try {
    new RegExp(pattern);
    return !INJECTION_PATTERNS.test(pattern);
  } catch {
    return false;
  }
}
```

### 3. Binary Analysis Safety

```typescript
// ✅ READ-ONLY: All binary operations are safe
{
  operation: "strings",
  path: "/suspicious.exe"
}
// Never executes, only reads strings

// ✅ SAFE: Archive extraction is read-only
{
  operation: "extract-file",
  path: "/archive.zip",
  archiveFile: "config.json"
}
// Extracts to memory, doesn't write to disk
```

---

## Token Optimization

### Token Estimation Formula

**From `bulkOperations.ts:293`**:
```typescript
const estimatedTokens = Math.ceil(content.length / 4);
```

**Rule of thumb**: 4 characters ≈ 1 token

### Optimization Checklist

- [ ] Use `mode: "discovery"` or `filesOnly: true` first (25x reduction)
- [ ] Use `matchString` for targeted extraction (85% savings)
- [ ] Enable `minified: true` for code files (30-60% savings)
- [ ] Set `maxMatchesPerFile: 3` (prevents explosion)
- [ ] Use `charLength: 10000` for pagination (prevents errors)
- [ ] Exclude build artifacts with `excludeDir` (80-90% reduction)
- [ ] Use `type: "ts"` instead of globs (cleaner, faster)
- [ ] Limit queries per batch to stay under 25K token limit

### Token Budget Example

```typescript
// Safe bulk operation (stays under 25K tokens)
{
  queries: [
    // Discovery: ~20 tokens per file × 10 files = 200 tokens
    { mode: "discovery", pattern: "auth", type: "ts" },

    // Targeted read: ~500 tokens per file × 3 files = 1,500 tokens
    { path: "auth.ts", matchString: "validate", matchStringContextLines: 15 },
    { path: "login.ts", matchString: "session", matchStringContextLines: 15 },
    { path: "token.ts", matchString: "refresh", matchStringContextLines: 15 },

    // Structure: ~100 tokens
    { path: "/src", depth: 1 }
  ]
}
// Total: ~1,800 tokens (well under 25K limit)
```

---

## Research Context Best Practices

### Use researchGoal & reasoning

```typescript
// ✅ GOOD: Helps track multi-step research
{
  path: "/src",
  pattern: "validateUser",
  researchGoal: "Understand authentication flow",
  reasoning: "Need to find how users are validated before proceeding to authorization"
}

// Benefits:
// 1. Context preserved across queries
// 2. Easier to debug complex workflows
// 3. Better hints from connection matrix
// 4. Clearer audit trail
```

---

## Summary: Quick Reference

| Task | Tool | Mode | Token Cost |
|------|------|------|------------|
| Find files containing pattern | RIPGREP | `mode: "discovery"` | ~20 tokens/file |
| Get pattern with context | RIPGREP | `mode: "detailed"` | ~500 tokens/file |
| Find files by name | FIND_FILES | `name: "*.ts"` | ~50 tokens/file |
| Find recent changes | FIND_FILES | `modifiedWithin: "7d"` | ~50 tokens/file |
| Read specific function | FETCH_CONTENT | `matchString: "funcName"` | ~15% of file |
| Read full file | FETCH_CONTENT | `fullContent: true` | 100% of file |
| See directory structure | VIEW_STRUCTURE | `depth: 1` | ~100 tokens |
| Identify binary | VIEW_BINARY | `operation: "identify"` | ~10 tokens |

---

## Additional Resources

- **Technical Design**: `/context/linux/SEARCH_COMMANDS_TECHNICAL_DESIGN.md`
- **User Guide**: `/context/linux/SEARCH_COMMANDS_USER_GUIDE.md`
- **Implementation**: `/packages/local-explorer-mcp/src/tools/`
- **Utilities**: `/packages/local-explorer-mcp/src/utils/`

---

**Generated**: 2025-10-29
**Source**: Analysis of local-explorer-mcp v1.x implementation and Linux kernel documentation
