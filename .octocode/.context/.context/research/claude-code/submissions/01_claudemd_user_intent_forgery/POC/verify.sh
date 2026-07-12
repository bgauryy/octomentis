#!/usr/bin/env bash
# verify.sh — Submission 1 / CLAUDE.md User-Intent Forgery
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
echo "  Submission 1 PoC — verify.sh"
echo "  CLAUDE.md User-Intent Forgery"
echo "=============================================================="
echo "  Target : ${CLI}"
echo "  Size   : ${SIZE} bytes"
echo "  Lines  : ${LINES}"
echo "  Version: ${VERSION}"
echo "--------------------------------------------------------------"

pass=0
fail=0

# Check a literal (fixed) string. Pass = at least one match.
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

# Check a literal (fixed) string is ABSENT. Pass = zero matches.
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

# Report the exact line(s) a literal string appears on. For diagnostic use.
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
echo "=== thz() forged-message builder (cli.js:2926) ==="
check_present "thz() function declaration"                     "function thz()"
check_present "thz() disk read via Rs8()"                      "function thz(){let q=Rs8()"
check_present "thz() emits role:\"user\""                      'role:"user"'
check_present "preamble: 'user's CLAUDE.md configuration'"     "user's CLAUDE.md configuration"
check_present "preamble: 'instructions the user provided'"     "instructions the user provided to the agent"
check_present "intent binding: 'part of the user's intent'"    "should be treated as part of the user's intent when evaluating actions"
check_present "<user_claude_md> open tag"                      "<user_claude_md>"
check_present "</user_claude_md> close tag"                    "</user_claude_md>"

echo ""
echo "=== Classifier override clause (cli.js:2834) ==="
check_present "override: 'explicitly and specifically authorized'" "explicitly and specifically authorized"
check_present "override: 'not merely implied'"                 "not merely implied"
check_present "override: 'not a scope escalation'"             "not a scope escalation"
check_present "override: 'shouldBlock: false'"                 "shouldBlock: false"
check_present "4-step classification process"                  "Apply user intent as the final signal"

echo ""
echo "=== Classifier entry point ox8() and wiring ==="
check_present "ox8() function declaration"                     "async function ox8("
check_present "thz() is called (not just declared)"            "let j=thz()"
check_present "forged message spread into messages array"      "let j=thz(),H=j?[j]:[]"

echo ""
echo "=== classify_result tool schema (cli.js:2939) ==="
check_present "classify_result tool name"                      '"classify_result"'
check_present "schema: shouldBlock:y.boolean()"                "shouldBlock:y.boolean()"

echo ""
echo "=== Negative checks — the absences that matter ==="
check_absent  "no Av(\"claudemd\") trust-gate invocation"       'Av("claudemd")'
check_absent  "no 'claudemd' as a source type marker"           'source:"claudemd"'
check_absent  "no 'claudemd' as a kind marker"                  'kind:"claudemd"'

echo ""
echo "=== Diagnostic line numbers (informational, not pass/fail) ==="
report_line "function thz()"                                   "function thz()"
report_line "explicitly and specifically authorized"           "explicitly and specifically authorized"
report_line "<user_claude_md>"                                 "<user_claude_md>"
report_line "shouldBlock:y.boolean()"                          "shouldBlock:y.boolean()"
report_line "should be treated as part of the user's intent"   "should be treated as part of the user's intent"

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
