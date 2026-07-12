#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Submission 4 — Classifier Rule Injection + Fast-Path Shortcut
# Verifier: runs grep against the live installed cli.js to confirm every
# evidence item from VALIDATION.md is still present in the binary. Prints a
# PASS/FAIL line per check and a final summary.
#
# This script does NOT send data anywhere, does NOT modify any files, and does
# NOT run Claude Code. It is a read-only static verifier.
# -----------------------------------------------------------------------------

set -uo pipefail

CLI_JS_DEFAULT="${HOME}/.nvm/versions/node/v22.22.0/lib/node_modules/@anthropic-ai/claude-code/cli.js"
CLI_JS="${CLAUDE_CLI_JS:-${CLI_JS_DEFAULT}}"

printf '[verify] target cli.js: %s\n' "${CLI_JS}"

if [[ ! -f "${CLI_JS}" ]]; then
    printf '[verify] ERROR: cli.js not found at %s\n' "${CLI_JS}" >&2
    printf '[verify] override with: CLAUDE_CLI_JS=/path/to/cli.js ./verify.sh\n' >&2
    exit 2
fi

# Print bundle metadata
if command -v stat >/dev/null 2>&1; then
    if stat -f '%z' "${CLI_JS}" >/dev/null 2>&1; then
        SIZE="$(stat -f '%z' "${CLI_JS}")"     # BSD / macOS
    else
        SIZE="$(stat -c '%s' "${CLI_JS}")"     # GNU / Linux
    fi
    printf '[verify] cli.js size: %s bytes\n' "${SIZE}"
fi

# -----------------------------------------------------------------------------
# Check harness. grep -F (fixed strings) everywhere we can — avoids regex
# corner cases in minified code. grep -E only where we need real regex.
# -----------------------------------------------------------------------------
PASS=0
FAIL=0

check_fixed() {
    local label="$1" needle="$2"
    if grep -F -q -- "${needle}" "${CLI_JS}"; then
        printf '  PASS  %s\n' "${label}"
        PASS=$((PASS + 1))
    else
        printf '  FAIL  %s\n' "${label}"
        FAIL=$((FAIL + 1))
    fi
}

check_regex() {
    local label="$1" pattern="$2"
    if grep -E -q -- "${pattern}" "${CLI_JS}"; then
        printf '  PASS  %s\n' "${label}"
        PASS=$((PASS + 1))
    else
        printf '  FAIL  %s\n' "${label}"
        FAIL=$((FAIL + 1))
    fi
}

printf '\n[verify] Part 1 — Rule Injection\n'

check_fixed "XML marker <user_allow_rules_to_replace> present" \
            '<user_allow_rules_to_replace>'

check_fixed "XML marker <user_deny_rules_to_replace> present" \
            '<user_deny_rules_to_replace>'

check_fixed "XML marker <user_environment_to_replace> present" \
            '<user_environment_to_replace>'

check_fixed "default ALLOW 'Memory Directory' bullet present" \
            '- Memory Directory: Routine writes to and deletes from'

check_fixed "default DENY 'Git Destructive' bullet present" \
            '- Git Destructive: Force pushing'

check_fixed "default ENV 'Trusted repo' bullet present" \
            '- **Trusted repo**:'

check_fixed "ehz() classifier prompt builder (was tfz)" \
            'async function ehz(q){let K=rhz()'

check_fixed "ehz() calls i06() to read custom rules" \
            'z=i06()'

check_fixed "ehz() performs the allow-rules .replace()" \
            '.replace(/<user_allow_rules_to_replace>'

check_fixed "ehz() performs the deny-rules .replace()" \
            '.replace(/<user_deny_rules_to_replace>'

check_fixed "ehz() performs the environment .replace()" \
            '.replace(/<user_environment_to_replace>'

check_fixed "i06() settings reader (was Ng6) definition present" \
            'function i06()'

check_fixed "i06() loops over userSettings/localSettings/flagSettings/policySettings" \
            'for(let Y of["userSettings","localSettings","flagSettings","policySettings"]'

check_fixed "i06() concatenates autoMode.allow across sources" \
            'if(O.data.allow)K.push(...O.data.allow)'

check_fixed ".claude/settings.local.json referenced as personal/local" \
            '.claude/settings.local.json'

check_fixed "autoMode.{allow, soft_deny, environment} user-facing docs" \
            'autoMode.{allow, soft_deny, environment}'

check_fixed "rx8() default-rule unwrapper (was vS8)" \
            'function rx8(){return{allow:yi1("user_allow_rules_to_replace")'

printf '\n[verify] Part 2 — Fast Classifier Shortcut\n'

check_fixed "ORz() two-stage classifier (was OZz)" \
            'async function ORz(q,K,_,z,Y,A,O,$,w)'

check_fixed "256-token Stage-1 budget present" \
            'max_tokens:(w==="fast"?256:64)+Z'

check_fixed "Stage-1 hard-return ALLOW path" \
            'reason:"Allowed by fast classifier"'

check_fixed "Stage-1 hard-return labels decision as stage:'fast'" \
            'stage:"fast"'

check_fixed "KRz Stage-1 instructions: does NOT apply ALLOW exceptions" \
            'Stage 1 does NOT apply user intent or ALLOW exceptions'

check_fixed "_Rz Stage-2 reinforcement: explicit not suggestive" \
            'explicit (not suggestive or implicit) user confirmation'

check_fixed "rl4() <block>yes/no</block> parser (was Vm4)" \
            '<block>(yes|no)'

check_fixed "Auto-mode cache control tag" \
            'querySource:"auto_mode"'

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
TOTAL=$((PASS + FAIL))
printf '\n[verify] -------- summary --------\n'
printf '[verify] PASS: %d / %d\n' "${PASS}" "${TOTAL}"
printf '[verify] FAIL: %d / %d\n' "${FAIL}" "${TOTAL}"

if [[ "${FAIL}" -eq 0 ]]; then
    printf '[verify] VERDICT: all checks passed — Submission 4 is reproducible on this cli.js\n'
    exit 0
else
    printf '[verify] VERDICT: one or more checks failed — bundle may have drifted. Review against EXPLANATION.md.\n'
    exit 1
fi
