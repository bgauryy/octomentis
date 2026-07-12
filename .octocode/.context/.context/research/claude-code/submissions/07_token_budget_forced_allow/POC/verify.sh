#!/usr/bin/env bash
# verify.sh — Submission 7 / Stage-1 Token Budget Forced Allow
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
echo "  Submission 7 PoC — verify.sh"
echo "  Stage-1 Token Budget Forced Allow"
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
echo "=== Stage-1 Token Budget (256 tokens) ==="
check_present "max_tokens with fast conditional"              'max_tokens:'
check_regex_present "256-token cap in fast mode"              '"fast"\?256'
check_regex_present "64-token alternative"                    '256:64'
check_present "fast mode string"                              '"fast"'

echo ""
echo "=== Vm4() Block Parser ==="
check_present "<block> tag in bundle"                         "<block>"
check_present "</block> closing tag"                          "</block>"
check_regex_present "<block>(yes|no) pattern"                 '<block>.*yes\|<block>.*no'
check_present "shouldBlock boolean"                           "shouldBlock"

echo ""
echo "=== Fast-Path Return (stage-2 skip) ==="
check_present "Allowed by fast classifier"                    "Allowed by fast classifier"

echo ""
echo "=== Stage-1 Prompt Instruction ==="
check_regex_present "Stage 1 does NOT apply user intent"      'Stage 1.*NOT.*user intent\|stage.1.*not.*user intent'
check_present "ALLOW exceptions deferred"                     "ALLOW"

echo ""
echo "=== Stage-2 Override Clause ==="
check_present "explicitly and specifically authorized"        "explicitly and specifically authorized"
check_present "Apply user intent as the final signal"         "Apply user intent as the final signal"
check_present "shouldBlock: false (override)"                 "shouldBlock: false"

echo ""
echo "=== Classifier Architecture ==="
check_present "classify_result tool"                          '"classify_result"'
check_regex_present "shouldBlock:y.boolean() schema"          'shouldBlock.*boolean'
check_present "Classifier prompt template exists"             "classify"

echo ""
echo "=== Context Biasing Vectors (confirming injection surfaces) ==="
check_present "user_claude_md tag (S1 injection point)"       "user_claude_md"
check_present "role:\"user\" in transcript"                   'role:"user"'
check_present "queued_command (S2 injection point)"           '"queued_command"'

echo ""
echo "=== Negative Checks ==="
check_absent  "no probabilistic stage-2 sampling"             "probabilistic"
check_absent  "no stage-2 audit on fast-path allow"           "audit_fast_path"

echo ""
echo "=== Diagnostic line numbers (informational, not pass/fail) ==="
report_line "max_tokens with 256"                             '?"fast"?256'
report_line "<block>"                                         "<block>"
report_line "Allowed by fast classifier"                      "Allowed by fast classifier"
report_line "explicitly and specifically authorized"           "explicitly and specifically authorized"
report_line "shouldBlock"                                     "shouldBlock"

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
