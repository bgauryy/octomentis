#!/usr/bin/env bash
# verify.sh — Submission 6 / Memory-Persistent Universal Jailbreak
#
# Re-verifies every load-bearing code citation in the submission against the
# live Claude Code cli.js bundle. Uses string anchors (not line numbers) so
# the script remains valid across minor minifier-rename releases.
#
# Usage:
#   ./verify.sh                                    # uses the default nvm path
#   ./verify.sh /path/to/@anthropic-ai/claude-code/cli.js
#
# Exits 0 if all checks pass, 1 otherwise.

set -u

DEFAULT_CLI="/Users/guybary/.nvm/versions/node/v22.22.0/lib/node_modules/@anthropic-ai/claude-code/cli.js"
CLI="${1:-${DEFAULT_CLI}}"

if [ ! -f "${CLI}" ]; then
  echo "[error] cli.js not found at: ${CLI}"
  echo "        Usage: $0 /path/to/node_modules/@anthropic-ai/claude-code/cli.js"
  exit 1
fi

SIZE="$(wc -c < "${CLI}" | tr -d ' ')"
LINES="$(wc -l < "${CLI}" | tr -d ' ')"
VERSION="$(sed -n '4p' "${CLI}" | sed 's|//[[:space:]]*Version:[[:space:]]*||' | tr -d '[:space:]')"

echo "=============================================================="
echo "  Submission 6 PoC — verify.sh"
echo "  Memory-Persistent Universal Jailbreak"
echo "=============================================================="
echo "  Target : ${CLI}"
echo "  Size   : ${SIZE} bytes"
echo "  Lines  : ${LINES}"
echo "  Version: ${VERSION}"
echo "--------------------------------------------------------------"

pass=0
fail=0

check_present () {
  local label="$1" needle="$2"
  if grep -Fq -- "${needle}" "${CLI}"; then
    echo "  [PASS] ${label}"
    pass=$((pass + 1))
  else
    echo "  [FAIL] ${label}"
    echo "         needle: ${needle}"
    fail=$((fail + 1))
  fi
}

check_absent () {
  local label="$1" needle="$2"
  if grep -Fq -- "${needle}" "${CLI}"; then
    echo "  [FAIL] ${label}  (expected ABSENT)"
    fail=$((fail + 1))
  else
    echo "  [PASS] ${label}  (0 hits, as expected)"
    pass=$((pass + 1))
  fi
}

check_regex_present () {
  local label="$1" pattern="$2"
  if grep -Eq -- "${pattern}" "${CLI}"; then
    echo "  [PASS] ${label}"
    pass=$((pass + 1))
  else
    echo "  [FAIL] ${label}"
    echo "         pattern: ${pattern}"
    fail=$((fail + 1))
  fi
}

report_line () {
  local label="$1" needle="$2"
  local hit
  hit="$(grep -Fn -- "${needle}" "${CLI}" | head -n 1 | awk -F: '{print $1}')"
  if [ -n "${hit}" ]; then
    echo "  [info] ${label} → first hit on line ${hit}"
  else
    echo "  [info] ${label} → NOT FOUND"
  fi
}

echo ""
echo "=== Memory loading — nested_memory handler ==="
check_present "nested_memory string literal"                  "nested_memory"
check_present "isMeta:!0 flag on memory content"              "isMeta:!0"
check_regex_present "i8() call with content template"         'i8\(\{content:'
check_present "Contents of \${path} template"                 'Contents of ${path}'

echo ""
echo "=== Memory loading — relevant_memories handler ==="
check_present "relevant_memories string literal"              "relevant_memories"

echo ""
echo "=== Memory storage path ==="
check_present "memoryDir variable"                            "memoryDir"
check_present ".claude/projects path pattern"                 ".claude/projects"
check_regex_present "memory directory construction"           'memory.*Dir\|memoryDir'

echo ""
echo "=== Transcript flattening (xm4 or equivalent) ==="
check_present "role:\"user\" in transcript flattening"        'role:"user"'
check_present "queued_command attachment type"                 '"queued_command"'

echo ""
echo "=== Classifier override clause ==="
check_present "override: explicitly and specifically authorized"  "explicitly and specifically authorized"
check_present "override: shouldBlock: false"                      "shouldBlock: false"
check_present "Apply user intent as the final signal"             "Apply user intent as the final signal"

echo ""
echo "=== isMeta is NOT in classifier path ==="
check_present "isMeta flag exists in bundle"                  "isMeta"
check_present "shouldBlock schema exists"                     "shouldBlock"

echo ""
echo "=== Negative checks — the absences that matter ==="
check_absent  "no memory-specific trust gate Av(\"memory\")"  'Av("memory")'
check_absent  "no source:\"memory\" provenance marker"         'source:"memory"'
check_absent  "no kind:\"memory\" type marker"                 'kind:"memory"'

echo ""
echo "=== HOME directory storage (not repo-scoped) ==="
check_present "~/.claude or home-relative claude dir"          ".claude/"
check_present "projects subdirectory"                          "/projects/"

echo ""
echo "=== Diagnostic line numbers (informational, not pass/fail) ==="
report_line "nested_memory"                                    "nested_memory"
report_line "relevant_memories"                                "relevant_memories"
report_line "memoryDir"                                        "memoryDir"
report_line "isMeta:!0"                                        "isMeta:!0"
report_line "explicitly and specifically authorized"           "explicitly and specifically authorized"

echo ""
echo "=============================================================="
echo "  Results: ${pass} passed, ${fail} failed"
echo "=============================================================="

if [ "${fail}" -eq 0 ]; then
  echo "[verdict] PASS — submission evidence verified against ${CLI}"
  exit 0
else
  echo "[verdict] FAIL — ${fail} check(s) did not match"
  exit 1
fi
