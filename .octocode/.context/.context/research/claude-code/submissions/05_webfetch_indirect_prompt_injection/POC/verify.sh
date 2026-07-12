#!/usr/bin/env bash
set -euo pipefail

CLI_JS="${CLI_JS:-$(readlink -f "$(which claude)" 2>/dev/null || echo "/Users/guybary/.nvm/versions/node/v22.22.0/lib/node_modules/@anthropic-ai/claude-code/cli.js")}"

if [ ! -f "$CLI_JS" ]; then
  echo "ERROR: cli.js not found at $CLI_JS"
  echo "Set CLI_JS=/path/to/cli.js and re-run."
  exit 1
fi

echo "=== WebFetch IPI — Code Reference Verification ==="
echo "Bundle: $CLI_JS"
echo "Size:   $(wc -c < "$CLI_JS") bytes"
echo "Lines:  $(wc -l < "$CLI_JS")"
echo "Date:   $(date -r "$CLI_JS" '+%Y-%m-%d %H:%M')"
echo ""

PASS=0
FAIL=0

check() {
  local label="$1"
  local pattern="$2"
  local result
  result=$(grep -c "$pattern" "$CLI_JS" 2>/dev/null || echo "0")
  if [ "$result" -gt 0 ]; then
    echo "  PASS  [$result hit(s)]  $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  [0 hits]     $label"
    FAIL=$((FAIL + 1))
  fi
}

echo "--- WebFetch Tool Constants ---"
check "WebFetch tool name constant"                    '"WebFetch"'
check "Web page content: template string"              'Web page content:'
check "web_fetch_apply query source"                   'web_fetch_apply'

echo ""
echo "--- Turndown Pipeline ---"
check "TurndownService bundled"                        'turndown:function'
check "turndown() call (HTML→Markdown)"                '\.turndown('

echo ""
echo "--- Sub-LLM Empty System Prompt ---"
check "systemPrompt: eK([]) or I5([])"                'systemPrompt:eK(\[\])\|systemPrompt:I5(\[\])'
check "hasAppendSystemPrompt:false"                    'hasAppendSystemPrompt:!1\|hasAppendSystemPrompt:false'

echo ""
echo "--- Preapproved Host Passthrough ---"
check "isPreapprovedUrl export"                        'isPreapprovedUrl'
check "text/markdown content-type check"               'text/markdown'
check "Preapproved host string"                        'Preapproved host'

echo ""
echo "--- Cache & Constants ---"
check "900000 (15-min TTL)"                            '900000'
check "52428800 (50MB max)"                            '52428800'
check "10485760 (10MB max content)"                    '10485760'

echo ""
echo "--- Domain Blocklist ---"
check "skipWebFetchPreflight settings gate"            'skipWebFetchPreflight'
check "api.anthropic.com/api/web/domain_info"          'api/web/domain_info'
check "DomainBlockedError"                             'DomainBlockedError'

echo ""
echo "--- Redirect Handling ---"
check "maxRedirects:0"                                 'maxRedirects:0\|maxRedirects: 0'
check "REDIRECT DETECTED"                              'REDIRECT DETECTED'

echo ""
echo "--- Classifier Override ---"
check "explicitly and specifically authorized"         'explicitly and specifically authorized'
check "shouldBlock boolean schema"                     'shouldBlock'

echo ""
echo "==================================="
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL CHECKS PASSED"
else
  echo "WARNING: $FAIL check(s) failed — review above"
fi
