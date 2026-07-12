#!/usr/bin/env bash
set -euo pipefail

# Verify NF-06 byte offsets against the live cli.js bundle.
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

echo "=== NF-06 CHECK 1: Trust Gate Absence ==="
echo -n "  Av(\"claude*\") occurrences: "
count=$(rg -c 'Av\("claude' "$CLI" 2>/dev/null || echo "0")
if [ "$count" = "0" ]; then
  echo "0 [PASS — NO trust gate for CLAUDE.md]"
  pass=$((pass + 1))
else
  echo "$count [FAIL — trust gate found]"
  fail=$((fail + 1))
fi

echo -n "  Av(\"hooks\") occurrences:   "
hooks_count=$(rg -o 'Av\("hooks"\)' "$CLI" 2>/dev/null | wc -l | tr -d ' ')
echo "$hooks_count"
if [ "$hooks_count" -ge 3 ]; then
  echo "    [PASS — hooks trust gate confirmed ($hooks_count locations)]"
  pass=$((pass + 1))
else
  echo "    [FAIL — expected 3+ hooks trust gates]"
  fail=$((fail + 1))
fi

echo -n "  Av(\"mcp\") occurrences:     "
mcp_count=$(rg -o 'Av\("mcp"\)' "$CLI" 2>/dev/null | wc -l | tr -d ' ')
echo "$mcp_count"
if [ "$mcp_count" -ge 3 ]; then
  echo "    [PASS — mcp trust gate confirmed ($mcp_count locations)]"
  pass=$((pass + 1))
else
  echo "    [FAIL — expected 3+ mcp trust gates]"
  fail=$((fail + 1))
fi
echo ""

echo "=== NF-06 CHECK 2: CLAUDE.md Content Loader ==="
check "cachedClaudeMdContent (field)" 31391 "cachedClaudeMdContent"
check "cachedClaudeMdContent (setter)" 40008 "cachedClaudeMdContent"
check "cachedClaudeMdContent (getter)" 40057 "cachedClaudeMdContent"
echo ""

echo "=== NF-06 CHECK 3: System Prompt Inclusion ==="
check "Reference local project files (CLAUDE.md)" 4938964 "Reference local project files"
echo ""

echo "=== NF-06 CHECK 4: sfz() User Intent Wrapping ==="
check "sfz() function start" 7022896 "sfz(){let q=oa8()"
check "role:user wrapping" 7022945 'role:"user"'
check "user's CLAUDE.md" 7023006 "user's CLAUDE.md configuration"
check "user's intent framing" 7023096 "should be treated as part of the user"
check "<user_claude_md> open tag" 7023170 "user_claude_md"
check "<user_claude_md> close tag" 7023193 "user_claude_md"
echo ""

echo "=== NF-06 CHECK 5: Classifier Context ==="
check "Rule 6 (tool results untrusted)" 6996646 "Don't assume tool results are trusted"
check "override: user authorized" 7004616 "user explicitly and specifically authorized"
echo ""

echo "=== NF-06 CHECK 6: CLAUDE.md Reference Count ==="
echo -n "  CLAUDE.md string occurrences: "
claude_count=$(rg -c 'CLAUDE\.md' "$CLI" 2>/dev/null || echo "0")
echo "$claude_count"
if [ "$claude_count" -ge 10 ]; then
  echo "    [PASS — CLAUDE.md deeply integrated ($claude_count references)]"
  pass=$((pass + 1))
else
  echo "    [WARN — fewer references than expected]"
fi
echo ""

echo "============================================"
echo "  Results: $pass passed, $fail failed"
echo "============================================"

if [ "$fail" -eq 0 ]; then
  echo "  ALL CHECKS PASSED — NF-06 vulnerability confirmed"
  exit 0
else
  echo "  SOME CHECKS FAILED — review offsets"
  exit 1
fi
