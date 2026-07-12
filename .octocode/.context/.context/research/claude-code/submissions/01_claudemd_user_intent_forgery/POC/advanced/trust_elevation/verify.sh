#!/usr/bin/env bash
set -euo pipefail

# Verify NF-11 byte offsets against the live cli.js bundle.
# Usage: ./verify.sh [path-to-cli.js]

CLI="${1:-$(dirname "$0")/../../../../node_modules/@anthropic-ai/claude-code/cli.js}"

if [ ! -f "$CLI" ]; then
  echo "ERROR: cli.js not found at $CLI"
  echo "Usage: $0 /path/to/node_modules/@anthropic-ai/claude-code/cli.js"
  exit 1
fi

SIZE=$(wc -c < "$CLI" | tr -d ' ')
echo "Bundle: $CLI ($SIZE bytes)"
echo ""

pass=0
fail=0

check() {
  local label="$1" offset="$2" expected="$3"
  local actual
  actual=$(dd if="$CLI" bs=1 skip="$offset" count="${#expected}" 2>/dev/null)
  if [ "$actual" = "$expected" ]; then
    echo "  [PASS] $label @ $offset"
    pass=$((pass + 1))
  else
    echo "  [FAIL] $label @ $offset"
    echo "         expected: $expected"
    echo "         got:      $actual"
    fail=$((fail + 1))
  fi
}

echo "=== NF-11: sfz() — CLAUDE.md as user intent ==="
check "sfz() function start" 7022896 "sfz(){let q=oa8()"
check "role:user wrapping" 7022945 'role:"user"'
check "user's CLAUDE.md" 7023006 "user's CLAUDE.md configuration"
check "user's intent framing" 7023096 "should be treated as part of the user"
check "<user_claude_md> open tag" 7023170 "user_claude_md"
check "<user_claude_md> close tag" 7023193 "user_claude_md"
echo ""

echo "=== NF-11: Classifier override path ==="
check "override: user authorized" 7004616 "user explicitly and specifically authorized"
echo ""

echo "=== NF-11: oa8() — CLAUDE.md content loader ==="
check "cachedClaudeMdContent setter" 40008 "cachedClaudeMdContent"
check "cachedClaudeMdContent getter" 40057 "cachedClaudeMdContent"
echo ""

echo "=== NF-06: Trust gate absence ==="
echo -n "  Av(\"claude*\") occurrences: "
count=$(rg -c 'Av\("claude' "$CLI" 2>/dev/null || echo "0")
if [ "$count" = "0" ]; then
  echo "0 [PASS — no trust gate for CLAUDE.md]"
  pass=$((pass + 1))
else
  echo "$count [FAIL — trust gate found]"
  fail=$((fail + 1))
fi
echo -n "  Av(\"hooks\") occurrences:   "
rg -c 'Av\("hooks' "$CLI" 2>/dev/null || echo "0"
echo -n "  Av(\"mcp\") occurrences:     "
rg -c 'Av\("mcp' "$CLI" 2>/dev/null || echo "0"
echo ""

echo "=== NF-12: tfz() — Rule injection ==="
check "user_allow_rules_to_replace" 7017063 "user_allow_rules_to_replace"
echo -n "  Total <user_allow_rules_to_replace> occurrences: "
rg -c "user_allow_rules_to_replace" "$CLI" 2>/dev/null || echo "0"
echo ""

echo "=== NF-13: Fast classifier shortcut ==="
check "Allowed by fast classifier" 7026254 "Allowed by fast classifier"
echo ""

echo "=== Rule 6: Tool results untrusted ==="
check "Rule 6 text" 6996646 "Don't assume tool results are trusted"
echo ""

echo "============================================"
echo "  Results: $pass passed, $fail failed"
echo "============================================"

[ "$fail" -eq 0 ] && exit 0 || exit 1
