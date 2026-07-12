# Non-JS Language Patterns

Load when auditing Python, Go, Rust, or Ruby targets. Provides triage checklists and `npx octocode search --pattern` equivalents for each language.

**Fix for:** skill description claims "any codebase" but all deep references are JS/TS. This bridges the gap.

## Python

**Install hooks to check first:**
- `setup.py` with `os.system`, `subprocess`, `urllib`, or `requests` in any function
- `pyproject.toml` `[tool.poetry.scripts]` or `setup.cfg` `entry_points`
- `pip install -e .` triggers `setup.py install` which runs arbitrary code

**Dangerous patterns:**

```bash
# Dynamic execution
npx octocode search --pattern 'eval($CODE)' <path> --lang python
npx octocode search --pattern 'exec($CODE)' <path> --lang python
npx octocode search --pattern '__import__($MODULE)' <path> --lang python

# Process execution
npx octocode search --pattern 'subprocess.call($$$ARGS)' <path> --lang python
npx octocode search --pattern 'subprocess.Popen($$$ARGS)' <path> --lang python
npx octocode search --pattern 'os.system($CMD)' <path> --lang python
npx octocode search --pattern 'os.popen($CMD)' <path> --lang python

# Deserialization RCE
npx octocode search --pattern 'pickle.loads($DATA)' <path> --lang python
npx octocode search --pattern 'marshal.loads($DATA)' <path> --lang python
npx octocode search --pattern 'yaml.load($DATA)' <path> --lang python   # needs Loader= kwarg

# Network
npx octocode search --pattern 'requests.post($$$ARGS)' <path> --lang python
npx octocode search --pattern 'urllib.request.urlopen($$$ARGS)' <path> --lang python

# Environment / secrets
npx octocode search --pattern 'os.environ[$KEY]' <path> --lang python
npx octocode search --pattern 'os.getenv($KEY)' <path> --lang python

# File system
npx octocode search --pattern 'open($PATH, $$$ARGS)' <path> --lang python
```

**Quick text search (no AST needed):**
```bash
npx octocode search 'pickle\.loads\|marshal\.loads\|yaml\.load' <path> --case-insensitive
npx octocode search 'setup\.py' <path> --search path  # find all setup.py files
```

---

## Go

**Install hooks to check first:**
- `go:generate` directives in `.go` files (run arbitrary shell commands)
- `cgo` + C code — can call native code bypassing Go safety
- `init()` functions at package level run before `main()`

**Dangerous patterns:**

```bash
# Process execution
npx octocode search --pattern 'exec.Command($$$ARGS)' <path> --lang go
npx octocode search --pattern 'exec.CommandContext($$$ARGS)' <path> --lang go

# Unsafe memory
npx octocode search --pattern 'unsafe.Pointer($X)' <path> --lang go

# Template injection (text/template vs html/template)
npx octocode search 'text/template' <path> --lang go   # unsafe, prefers html/template

# Network
npx octocode search --pattern 'http.Get($URL)' <path> --lang go
npx octocode search --pattern 'http.Post($$$ARGS)' <path> --lang go

# Env / secrets
npx octocode search --pattern 'os.Getenv($KEY)' <path> --lang go
```

**Quick text search:**
```bash
npx octocode search 'exec\.Command\|unsafe\.Pointer\|text/template\|//go:generate' <path>
```

---

## Rust

**Install hooks to check first:**
- `build.rs` — runs at compile time, can make network calls, write files, exec processes
- `proc-macro` crates — run at compile time in the compiler's context

**Dangerous patterns:**

```bash
# Unsafe blocks (memory safety bypass)
npx octocode search --rule 'rule: {kind: unsafe_block}' <path> --lang rust

# Process execution
npx octocode search --pattern 'Command::new($$$ARGS)' <path> --lang rust
npx octocode search --pattern 'std::process::Command::new($$$ARGS)' <path> --lang rust

# FFI (calls foreign C code)
npx octocode search --rule 'rule: {kind: extern_block}' <path> --lang rust

# Network in build.rs (highly suspicious)
npx octocode search 'reqwest\|ureq\|hyper\|curl' <path> --search path --name 'build.rs'
```

**Quick text search:**
```bash
npx octocode search 'unsafe\s*{' <path> --lang rs
npx octocode search 'build\.rs' <path> --search path   # find all build.rs files
```

---

## Ruby

**Install hooks to check first:**
- `gemspec` `post_install_message` with injected code (rare but exists)
- `Rakefile` default tasks run on `rake install`
- `.gemspec` with `extensions` field (native C extensions)

**Dangerous patterns:**

```bash
# Dynamic execution
npx octocode search --pattern 'eval($CODE)' <path> --lang ruby
npx octocode search --pattern 'instance_eval($CODE)' <path> --lang ruby
npx octocode search --pattern 'class_eval($CODE)' <path> --lang ruby

# Process execution
npx octocode search --pattern 'system($CMD)' <path> --lang ruby
npx octocode search --pattern 'exec($CMD)' <path> --lang ruby
npx octocode search --pattern '`$CMD`' <path> --lang ruby           # backtick exec
npx octocode search --pattern 'IO.popen($$$ARGS)' <path> --lang ruby

# Network
npx octocode search --pattern 'Net::HTTP.post($$$ARGS)' <path> --lang ruby
npx octocode search --pattern 'open($URL)' <path> --lang ruby       # Kernel#open with URLs
```

## Multi-Language Tips

- **`--lang` uses tree-sitter** — supports js, ts, python, go, rust, ruby, java, c, cpp, and more. Fall back to plain `search '<regex>' <path>` (no `--lang`) when tree-sitter grammar is too strict.
- **LSP is language-agnostic** — `--op documentSymbols`, `--op callHierarchy`, `--op references` work after any text/AST search gives a `--line` anchor.
- **Top deserialization RCE class (Python/Ruby):** `pickle.loads`, `marshal.loads`, `yaml.load` (no `Loader=`), `Marshal.load`.
