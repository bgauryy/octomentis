#!/usr/bin/env bash
# verify.sh — Static verifier for Submission 3 (<system-reminder> Tag Spoofing)
#
# Read-only. Runs grep against the installed Claude Code cli.js to confirm every
# line-number/string claim in VALIDATION.md. Prints PASS / FAIL per check.
#
# Usage: bash verify.sh
# Exit 0 on all-PASS, 1 otherwise.

set -u

CLI="${CLI_JS:-/Users/guybary/.nvm/versions/node/v22.22.0/lib/node_modules/@anthropic-ai/claude-code/cli.js}"

if [[ ! -f "$CLI" ]]; then
  echo "FAIL: cli.js not found at $CLI"
  echo "Set CLI_JS=/path/to/cli.js and re-run."
  exit 1
fi

SIZE=$(wc -c < "$CLI" | tr -d ' ')
echo "=== Submission 3 verifier ==="
echo "Target: $CLI"
echo "Size:   $SIZE bytes"
echo

FAIL=0
PASS=0

# pass_if_grep <label> <pattern>            — PASS if at least one match
# pass_if_nogrep <label> <pattern>          — PASS if ZERO matches (negative check)
# pass_if_count <label> <pattern> <min>     — PASS if count >= min

pass_if_grep() {
  local label="$1" pat="$2"
  if grep -F -q -- "$pat" "$CLI"; then
    printf '  [PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '  [FAIL] %s    (pattern: %s)\n' "$label" "$pat"
    FAIL=$((FAIL + 1))
  fi
}

pass_if_grep_e() {
  local label="$1" pat="$2"
  if grep -E -q -- "$pat" "$CLI"; then
    printf '  [PASS] %s\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '  [FAIL] %s    (pattern: %s)\n' "$label" "$pat"
    FAIL=$((FAIL + 1))
  fi
}

pass_if_nogrep_e() {
  local label="$1" pat="$2"
  local count
  count=$(grep -E -c -- "$pat" "$CLI" || true)
  if [[ "$count" -eq 0 ]]; then
    printf '  [PASS] %s    (0 hits — confirmed absent)\n' "$label"
    PASS=$((PASS + 1))
  else
    printf '  [FAIL] %s    (expected 0, got %s)\n' "$label" "$count"
    FAIL=$((FAIL + 1))
  fi
}

pass_if_count_ge() {
  local label="$1" pat="$2" min="$3"
  local count
  count=$(grep -F -c -- "$pat" "$CLI" || true)
  if [[ "$count" -ge "$min" ]]; then
    printf '  [PASS] %s    (count=%s >= %s)\n' "$label" "$count" "$min"
    PASS=$((PASS + 1))
  else
    printf '  [FAIL] %s    (count=%s, expected >= %s)\n' "$label" "$count" "$min"
    FAIL=$((FAIL + 1))
  fi
}

echo "--- POSITIVE CHECKS (expected to match) ---"

#  1. Total <system-reminder> occurrences — canonical "34" (use >= 30 to tolerate drift)
pass_if_count_ge "1. <system-reminder> literal occurs >= 30 times" "system-reminder" 30

#  2. Canonical emitter ZU8() exists
pass_if_grep "2. ZU8() canonical emitter defined"               "function ZU8(q,K)"

#  3. Canonical template text "As you answer the user's questions"
pass_if_grep "3. Template: 'As you answer the user's questions'" "As you answer the user's questions, you can use the following context:"

#  4. Closing </system-reminder> tag present
pass_if_grep "4. </system-reminder> closing tag present"        "</system-reminder>"

#  5. gitStatus array assembly — "Current branch: \${Y}"
pass_if_grep "5. gitStatus: Current branch interpolation"       "\`Current branch: \${Y}\`"

#  6. gitStatus: "Main branch (you will usually use this for PRs)"
pass_if_grep "6. gitStatus: Main branch template string"        "Main branch (you will usually use this for PRs)"

#  7. gitStatus: "Git user: \${w}"
pass_if_grep "7. gitStatus: Git user interpolation"             "\`Git user: \${w}\`"

#  8. gitStatus: "Recent commits:"
pass_if_grep "8. gitStatus: 'Recent commits:' literal"          "Recent commits:"

#  9. nested_memory handler — raw content interpolation
pass_if_grep "9. nested_memory handler: Contents-of template"   "Contents of \${q.content.path}"

# 10. relevant_memories handler present
pass_if_grep "10. relevant_memories handler case"               "case\"relevant_memories\""

# 11. mcp_instructions_delta handler emits MCP Server Instructions
pass_if_grep "11. mcp_instructions_delta: MCP Server Instructions header" "# MCP Server Instructions"

# 12. jq7() WebFetch URL->markdown (renamed from v17)
pass_if_grep "12. jq7() WebFetch URL->markdown exists"          "async function jq7(q,K)"

# 13. $q7() preapproved URL check (renamed from isPreapprovedUrl)
pass_if_grep "13. \$q7() preapproved URL check exists"          "function \$q7(q)"

# 14. Hq7() sub-LLM applyPromptToMarkdown (renamed from T17)
pass_if_grep "14. Hq7() sub-LLM applyPromptToMarkdown exists"   "async function Hq7(q,K,_,z,Y)"

# 15. Turndown raw passthrough in jq7 (no sanitization)
pass_if_grep "15. Turndown raw passthrough in jq7"              "(await mOY()).turndown(J)"

echo
echo "--- NEGATIVE CHECKS (expected to be absent) ---"

# N1. Nonce adjacent to system-reminder
pass_if_nogrep_e "N1. No nonce near system-reminder"            "system-reminder[^\"]{0,100}nonce|nonce[^\"]{0,100}system-reminder"

# N2. Signing / HMAC / verify / secret adjacent to system-reminder
pass_if_nogrep_e "N2. No crypto material near system-reminder"  "system-reminder[^\"]{0,200}(hmac|verify[A-Z]|signTag|signSystemReminder)"

# N3. Stripping of </system-reminder> in external content
pass_if_nogrep_e "N3. No stripping of </system-reminder>"       "replace[^\"]{1,80}</system-reminder>"

# N4. No sanitization helper for system-reminder
pass_if_nogrep_e "N4. No sanitizeSystemReminder/stripSystemReminder helper" "(sanitize|strip)[A-Za-z]*SystemReminder"

# N5. isPreapprovedUrl is still active (NOT a negative — confirm the ~100 host list still exists via cg8)
pass_if_grep "N5. cg8() host allowlist helper still present"    "function cg8("

echo
echo "--- SUMMARY ---"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  echo
  echo "VERDICT: ALL CHECKS PASSED — bug remains live in v2.1.97."
  exit 0
else
  echo
  echo "VERDICT: SOME CHECKS FAILED — inspect output above."
  exit 1
fi
