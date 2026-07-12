# Binary & Compressed File Workflow

Use this when the target includes archives, compressed logs, native modules, packed blobs, or unknown files (`.zip`, `.jar`, `.apk`, `.wasm`, `.node`, `.so`, `.dylib`, `.exe`, `.dll`, `.bin`, `.asar`, `.gz`, `.zst`).

Optimized for low-noise, repeatable white-hat investigations. All tool commands use `npx octocode`.

> **Tool map:** For the full canonical command table, see `octocode-cli-tools.md`. This document covers routing decisions, per-family step chains, pitfalls, and templates.

---

## Tool Ratings (Validated by Live Tests)

Tested against real artifacts on macOS arm64.

| Operation | Rating | Notes |
| --------- | ------ | ----- |
| `search <path> --tree` | ★★★★★ | Reliable, fast. Use `--depth 1` first always. |
| `tools localFindFiles` | ★★★★★ | Find by name/time/size/type. `modifiedWithin:"7d"` for recent changes. |
| `search "<term>" <path> --files-only` | ★★★★★ | Right entry point. Add `--hidden --no-ignore` for binary/artifact hunts. |
| `search <file> --content-view exact` | ★★★★☆ | `--match-string` is **case-sensitive** — wrong case returns empty, not an error. |
| `search <file> --target artifacts --inspect` | ★★★★★ | Correctly identified bzip2-wrapped DMG (204MB) and Mach-O fat binary. Fast. |
| `search <file> --target artifacts --strings` | ★★★★☆ | Add `--match-string` filter. Without it: pagination required on large binaries. |
| `search <file> --target artifacts --decompress` | ★★★★☆ | 10 MB output limit — large files need `--match-string` or `--char-offset` pagination. |
| `search <file> --target artifacts --list` | ★★★★☆ | ZIP/JAR/TAR work out of box. DMG/7z/RAR need `brew install sevenzip`. |
| `search <file> --target artifacts --extract <entry>` | ★★★★★ | Full round-trip confirmed. Exact member name required (case-sensitive from `--list` output). |

**Backend coverage gaps (install to unblock):**

| Missing | Affects | Fix (macOS) |
| ------- | ------- | ----------- |
| `7z` / `7zz` | DMG, 7z, RAR archives | `brew install sevenzip` |
| `zstd` | `.zst` decompress | `brew install zstd` |
| `lz4` | `.lz4` decompress | `brew install lz4` |
| `brotli` | `.br` decompress | `brew install brotli` |
| `pdftotext` / `pdfinfo` | PDF text/info | `brew install poppler` |
| `wasm2wat` | WASM disassemble | `brew install wabt` |
| `hermes-dec` | `.hbc` Hermes bytecode | `pipx install hermes-dec` |
| `hermes-decomp` | `.hbc` CFG / Metro modules | `git clone SymbioticSec/hermes-decomp && cargo build --release` |
| `shuji` | Source map reconstruction | `npm i -g shuji` |
| `source-map-explorer` | Source map attribution | `npm i -g source-map-explorer` |

---

## Per-Family Workflow Chains

Always **start with identification** before doing anything else. Routing on assumption wastes calls.

### Step 0 — Identify First (all families)

```bash
npx octocode search <path> --target artifacts --inspect
```

Read the returned `mimeType` and hints. Route from there:

| mimeType | Route to |
| -------- | -------- |
| `application/gzip`, `application/x-bzip2`, `application/x-xz`, `application/zstd` | → **Single-stream Compressed** |
| `application/zip`, `application/x-tar`, `application/x-7z-compressed` | → **Multi-entry Archive** |
| `application/pdf` | → **PDF** |
| `application/wasm` | → **WASM** |
| `application/x-mach-binary`, `application/x-elf` | → **Native Binary** |
| `application/x-bzip2` on a `.dmg` | → **Multi-entry Archive** (needs `7z`) |
| anything else / `application/octet-stream` | → **Raw Binary** |

---

### 1. Single-Stream Compressed (.gz / .bz2 / .xz / .lzma / .zst / .lz4 / .br / .lzfse)

These wrap a **single file** — typically a log, JSONL stream, or text payload.

```bash
Step 1  npx octocode search <path> --target artifacts --inspect
        → confirms format: gzip / bzip2 / xz / zstd / lz4 / brotli

Step 2  npx octocode search <path> --target artifacts --decompress
        → if output present → scan decompressedContent
        → if "Output size limit exceeded"
              add --match-string "<keyword>" to filter, or
              use --char-offset 0 --char-length 8000 windows

Step 3  npx octocode search "<IOC>" <dir>
        → fast second pass over the raw stream without full decompress

Step 4  npx octocode search <decompressed-file> --match-string "..." --content-view exact
        → on the decompressed content for surrounding context
```

**Pitfalls:**
- Output is capped at ~10 MB. Large `.log.gz` files always hit it — add `--match-string` or paginate.
- Use `--char-offset` from pagination results to page through large streams.
- The path must be under an allowed workspace root (`/Users/<user>`). `/tmp` may be blocked.

---

### 2. Multi-Entry Archive (.zip / .jar / .apk / .tar.* / .7z / .dmg / .rar / .aar)

These contain **multiple members** — extract only what you need.

```bash
Step 1  npx octocode search <path> --target artifacts --inspect
        → confirms: zip / tar / 7z-compressed / etc.

Step 2  npx octocode search <path> --target artifacts --list
        → scan entry names for suspicious files:
            postinstall scripts, .js/.sh/.py files, .env, credentials, unusual binaries
        → if backendMissing: install named CLI (brew install sevenzip for 7z/DMG/RAR)
        → if large archive: page with --page N

Step 3  npx octocode search <path> --target artifacts --extract <exact/member/name.js>
        → member name is CASE-SENSITIVE — copy exactly from list output
        → returns content for text members, binary representation for others

Step 4  npx octocode search <path> --match-string "eval" --content-view exact
        → or: npx octocode search "fetch|XMLHttpRequest|postinstall" <extracted-dir>

Step 5  If the extracted member is itself binary:
        → back to Step 0 (--inspect) for the extracted member
```

**Pitfalls:**
- Without `7z`/`7zz`, DMG/RAR/7z archives always fail. `brew install sevenzip`.
- Member name matching is case-sensitive. Copy the exact string from `--list` output.
- `.jar` files are ZIPs — the underlying tool handles them.
- `.asar` (Electron) — also handled as archive; extract JS sources member by member.

---

### 3. Raw Binary / Unknown Blob

Unknown blobs need a triage chain before spending tokens on strings.

```bash
Step 1  npx octocode search <path> --target artifacts --inspect
        → if archive → go to workflow 2
        → if text/* → npx octocode search <file> --content-view exact directly
        → if application/octet-stream or unknown → continue

Step 2  npx octocode search <path> --target artifacts --inspect
        → record hash from inspect output in binary-artifact-map.md
        → check against known-bad hash lists if available

Step 3  npx octocode search <path> --target artifacts --strings
        → look for: URLs, API keys, /bin/sh, eval, base64, persistence paths
        → add --match-string "<keyword>" to filter large binaries
        → if more pages needed: use --char-offset <nextScanOffset from results>

Step 4  npx octocode search "https://|AKIA|BEGIN PRIVATE" <path> --hidden
        → faster sweep across binary content for IOC patterns

Step 5  Shell hexdump as last resort when --inspect and --strings are both inconclusive:
        xxd <path> | head -20
```

**Pitfalls:**
- `--strings` without `--match-string` always paginates on large binaries. Add a filter or use `--char-offset`.
- Use `nextScanOffset` from the response to page through. Never compute the offset manually.

---

### 4. PDF

```bash
Step 1  npx octocode search <path> --target artifacts --inspect
        → if encrypted: stop, note limitation

Step 2  npx octocode search <path> --target artifacts --inspect
        → metadata: author, creator tool, creation date, page count

Step 3  npx octocode search <path> --target artifacts --strings --match-string "<keyword>"
        → text extraction (needs poppler for pdftotext backend)
        → use --match-string to filter large docs

Step 4  npx octocode search <path> --target artifacts --list
        → reveals embedded files — common malware delivery vector

Step 5  npx octocode search <path> --target artifacts --inspect
        → raw object tree for embedded scripts, forms, or JS actions
```

**Pitfalls:**
- Needs `poppler` (`brew install poppler`). Without it: backend missing.
- Large PDFs — use `--match-string` filter.

---

### 5. WASM

```bash
Step 1  npx octocode search <path> --target artifacts --inspect
        → size, section names, function count, imports, exports

Step 2  npx octocode search <path> --target artifacts --strings --match-string "fd_write"
        → what host functions does it import? ("fd_write", "proc_exit" = WASI; "eval" = suspicious)
        → what does it export? Unexpected large exports surface obfuscated logic.

Step 3  npx octocode search <path> --target artifacts --strings --match-string "<funcName>"
        → scope strings to a known suspicious export/import name
        → without --match-string: large WASM output hits pagination
```

**Pitfalls:**
- `wasm2wat` / `wasm-objdump` / `wasm-dis` — install `wabt` (`brew install wabt`).
- Disassemble on large modules without `--match-string` → pagination required. Scope it.

---

### 6. Native Binary (ELF / Mach-O / .node / .so / .dylib)

```bash
Step 1  npx octocode search <path> --target artifacts --inspect
        → is it fat (multi-arch)? x86_64? arm64? Linux ELF or macOS Mach-O?
        → uses lipo (macOS) or readelf/file (Linux)

Step 2  npx octocode search <path> --target artifacts --inspect
        → what dylibs/so does it depend on?
        → flag: unexpected network libs, crypto, anything not matching stated purpose

Step 3  npx octocode search <path> --target artifacts --strings --match-string "undefined"
        → undefined symbols = external deps imported at runtime
        → look for: execve, popen, fork, socket, connect, dlopen

Step 4  npx octocode search <path> --target artifacts --inspect   [macOS only]
        → code-signature: is it signed? By whom? Revoked?

Step 5  npx octocode search <path> --target artifacts --inspect   [macOS only]
        → entitlements: com.apple.security.network.client = network access
        → com.apple.security.files.user-selected.read-write = disk access
```

**Pitfalls:**
- `otool` (macOS) and `readelf`/`nm`/`ldd` (Linux) — usually pre-installed. Missing on some CI images.
- `--strings` output can be huge — use `--match-string` to filter for specific symbol names.
- `.node` files are Mach-O on macOS, ELF on Linux. `--inspect` routes correctly.

---

### 7. Hermes Bytecode (.hbc) — React Native

React Native release builds precompile JS to Hermes bytecode. The bundle looks binary but is the JS logic.

**Identify first (before choosing a tool):**

```bash
# 1. Extract from APK (APK is a ZIP)
npx octocode search app.apk --target artifacts --list
npx octocode search app.apk --target artifacts --extract assets/index.android.bundle
# Same for IPA: list → Payload/<App>.app/main.jsbundle

# 2. Check if it's Hermes bytecode (not plain JS)
file apk_out/assets/index.android.bundle
# → "Hermes JavaScript bytecode, version 84"  ← Hermes
# → "ASCII text"                              ← plain minified JS → use minification-guide.md

# 3. If file magic DB is stale, check first 8 bytes manually
xxd apk_out/assets/index.android.bundle | head -1
# Hermes execution magic (LE): c6 1f bc 03 c1 03 19 1f
```

**Read the bytecode version:**

```bash
hbc-file-parser bundle.hbc           # hermes-dec
hermes-decomp info bundle.hbc        # SymbioticSec hermes-decomp
```

**Tool selection:**

| Goal | Tool | Install | Version coverage |
|------|------|---------|-----------------|
| **Disasm + decompile** (most common) | **hermes-dec** (P1sec) | `pipx install hermes-dec` or `snap install hermes-dec` | Broad; AGPL-3.0 |
| **Rich analysis** (CFG, IR, Metro modules, TUI, diff) | **hermes-decomp** (SymbioticSec) | `git clone` + `cargo build --release` | Active 2026-03-27 |
| **Round-trip patching** at bytecode level | **hbctool** | `pip install hbctool` | 59, 62, 74, 76 only |
| **Reference disasm** matching exact Hermes build | **hbcdump** | Build from `facebook/hermes` source | Exact build match |

**Workflow:**

```bash
# Step 1: parse header (get version, confirm format)
hbc-file-parser index.android.bundle

# Step 2a: disassemble (opcode-accurate, register-style output)
hbc-disassembler index.android.bundle > disasm.txt

# Step 2b: decompile (JS-like pseudo-code — not valid JS, jump labels still present)
hbc-decompiler index.android.bundle > decompiled.js

# Step 3: extract Metro modules (one file per module)
hermes-decomp extract index.android.bundle -o modules/

# Step 4: search the output with octocode
npx octocode search 'https://|api\.|fetch|eval|process\.env|\.ssh|AKIA' decompiled.js
npx octocode search 'https://|api\.|fetch|eval' modules/
```

**Analysis tips:**
- Start with strings: `hermes-decomp` xref/strings subcommands, or `npx octocode search` on decompiled output
- Decompiled output is NOT valid JS — variables are register-names (`r0`, `r6`), control flow uses labels. Read for intent, not syntax
- Metro modules: `hermes-decomp modules` or `extract` separates the module table into individual files — scan each for the IOC you care about
- If `hbctool` version-mismatches: check the bytecode version from Step 1, try `hermes-dec` instead

**Pitfall:** `file` output depends on the installed magic database. If it reports "data" or "octet-stream" but magic bytes match `c6 1f bc 03 c1 03 19 1f`, it's Hermes — trust the hex, not the label.

---

## What to Search First in Strings

Start with high-impact indicators before broad regex packs.

| Category | Example indicators | Why it matters |
| -------- | ------------------ | -------------- |
| Exfil endpoints | `https://`, `webhook`, `api/collect`, `telegram`, `discord`, `pastebin`, `ngrok` | Data theft and C2 paths often leak in strings |
| Cloud/secret markers | `AKIA`, `ASIA`, `SECRET_KEY`, `BEGIN PRIVATE KEY`, `x-api-key` | Immediate credential exposure risk |
| Command execution | `/bin/sh`, `cmd.exe`, `powershell`, `bash -c`, `child_process` | RCE or post-exploitation behavior |
| Persistence | `LaunchAgents`, `cron`, `systemd`, `Startup`, `autorun` | Survives restart and expands impact |
| Stealth/anti-analysis | `isDebuggerPresent`, `sandbox`, `vmware`, `sleep`, `setTimeout` + long delay | Evasion logic signals intent to hide |
| Decode-then-exec | `base64`, `atob`, `Buffer.from`, `eval`, `Function(` | Typical payload staging pipeline |
| Sensitive local paths | `.ssh`, `.aws/credentials`, `.npmrc`, `.env`, `id_rsa`, `wallet.dat` | Targeting secrets on disk |

If any single artifact contains both secret markers and outbound endpoint indicators, escalate immediately.

---

## Pitfalls & Gotchas (Confirmed by Live Tests)

| Pitfall | Symptom | Fix |
| ------- | ------- | --- |
| `--strings` without `--match-string` on large binary | Pagination required every time | Add `--match-string "<keyword>"` or use `--char-offset` windows |
| `--content-view exact` with wrong-case `--match-string` | Empty result, no error — silent miss | `--match-string` is case-sensitive; verify exact casing |
| `--list/--extract` on DMG/RAR/7z without `7z` installed | `backendMissing` error | `brew install sevenzip` |
| `--decompress` on large compressed files | "Output size limit exceeded" | Add `--match-string` to filter, or use `--char-offset` + `--char-length` windows |
| `--target artifacts --extract` member not found | Silent error or wrong extract | Copy member name byte-for-byte from `--list` output — case-sensitive |
| `backendMissing` misread as "clean" | Missing backend = no result, not safe verdict | Install named CLI or record as investigation gap |

---

## Mapping Templates

### `mapping/binary-artifact-map.md`

```md
| ID  | Path               | Type               | Size  | Status   | Key Signals             | Next Step                    |
| --- | ------------------ | ------------------ | ----- | -------- | ----------------------- | ---------------------------- |
| A01 | path/to/blob.wasm  | WebAssembly binary | 412KB | queued   | -                       | --inspect + --strings        |
| A02 | path/to/update.zip | Zip archive        | 2.1MB | examined | webhook URL, eval chain | --extract suspicious member  |
```

Status values: `queued` → `examined` → `escalated` → `closed-low`

### `examined.log`

Append one line per action:

```text
2026-04-09T13:20Z | A02 | --strings --match-string webhook | hit: webhook + AKIA-like token
2026-04-09T13:22Z | A02 | --inspect (hash) | 55d1...a9f4
2026-04-09T13:26Z | A02 | --list | found installer.js + payload.dat
2026-04-09T13:31Z | A02 | --extract installer.js | confirmed eval(Buffer.from(...))
```

### `mapping/tool-coverage.md`

Track what you already ran so loops stay low-noise:

```md
| Step | Operation              | Query Focus                                  | Outcome                    | Next                   |
| ---- | ---------------------- | -------------------------------------------- | -------------------------- | ---------------------- |
| 1    | --inspect (A02)        | identify format + hash                       | zip archive, hash captured | --list                 |
| 2    | --extract installer.js | JS installer                                 | JS installer streamed      | search for eval chain  |
| 3    | search "beacon URL"    | beacon URL IOC in installer                  | 2 hits                     | fetch surrounding ctx  |
```

### `strings.md`

Track only strings that can change the verdict:

```md
| Artifact ID | String                         | Class         | Searched in code? | Flow proven? | Notes                            |
| ----------- | ------------------------------ | ------------- | ----------------- | ------------ | -------------------------------- |
| A02         | https://example-cdn.tld/beacon | endpoint      | yes               | partial      | called from postinstall          |
| A02         | BEGIN PRIVATE KEY              | secret-marker | yes               | no           | likely test fixture, verify path |
```

---

## Low-Friction Prioritization

When time is limited or noise is high:

1. Inspect only newest or largest 10 artifacts first.
2. Filter `--strings` output with `--match-string` — avoid full dumps.
3. Prioritize artifacts touched by recent commits or install paths (`scripts/`, `bin/`, `postinstall`).
4. Close low-signal items quickly as `closed-low`, with one-line rationale.

Prioritizing keeps momentum while preserving an auditable trail of what was examined and why.
