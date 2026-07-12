#!/usr/bin/env bash
# ============================================================================
#  Bounty 2 PoC — Evidence Verification
# ============================================================================
#
# Greps the live cli.js bundle for every string/symbol cited in the
# EXPLANATION.md and VALIDATION.md documents, and prints PASS/FAIL per item.
#
# This script is read-only. It does not write or modify anything. Safe to
# run any time. No privileges required.
#
# Prerequisite:
#   Claude Code v2.1.97 must be installed so cli.js is present at the
#   expected path. If installed elsewhere, set CLAUDE_CLI=/path/to/cli.js.
#
# Usage:
#   ./verify.sh
#
# Exit code:
#   0  if all checks pass
#   1  if any check fails (drift or uninstalled bundle)
#
# ============================================================================

set -uo pipefail

CLI_JS="${CLAUDE_CLI:-/Users/guybary/.nvm/versions/node/v22.22.0/lib/node_modules/@anthropic-ai/claude-code/cli.js}"
PKG_JSON="$(dirname "${CLI_JS}")/package.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass_count=0
fail_count=0
total=0

printf '%b==== Bounty 2 PoC — Live Evidence Verification ====%b\n' "${BLUE}" "${NC}"
printf 'Bundle: %s\n' "${CLI_JS}"

if [ ! -f "${CLI_JS}" ]; then
  printf '%bFATAL: cli.js not found at %s%b\n' "${RED}" "${CLI_JS}" "${NC}"
  printf 'Set CLAUDE_CLI=/path/to/cli.js and re-run.\n'
  exit 1
fi

# Check ripgrep
if ! command -v rg >/dev/null 2>&1; then
  printf '%bFATAL: ripgrep (rg) is required to run this script.%b\n' "${RED}" "${NC}"
  printf 'Install with: brew install ripgrep\n'
  exit 1
fi

# Bundle metadata
size_bytes="$(wc -c < "${CLI_JS}" | tr -d ' ')"
printf 'Size  : %s bytes\n' "${size_bytes}"
if [ -f "${PKG_JSON}" ]; then
  version="$(rg -o '"version":\s*"[^"]+"' "${PKG_JSON}" | head -n1 || printf 'unknown')"
  printf 'Ver   : %s\n' "${version}"
fi
printf '\n'

# ----------------------------------------------------------------------------
# check() — runs a pattern and prints PASS if matched, FAIL otherwise
# $1 = human label
# $2 = expected line or "any"
# $3 = rg pattern (fixed-string)
# ----------------------------------------------------------------------------
check() {
  local label="$1"
  local expected_line="$2"
  local pattern="$3"
  total=$((total + 1))

  local hit
  hit="$(rg --fixed-strings -n -m1 -- "${pattern}" "${CLI_JS}" 2>/dev/null | head -n1)"

  if [ -z "${hit}" ]; then
    printf '  %b[FAIL]%b  %s\n' "${RED}" "${NC}" "${label}"
    printf '           pattern: %s\n' "${pattern}"
    fail_count=$((fail_count + 1))
    return
  fi

  local line_num="${hit%%:*}"
  if [ "${expected_line}" = "any" ] || [ "${line_num}" = "${expected_line}" ]; then
    printf '  %b[PASS]%b  %s (line %s)\n' "${GREEN}" "${NC}" "${label}" "${line_num}"
    pass_count=$((pass_count + 1))
  else
    printf '  %b[DRIFT]%b %s (expected line %s, found %s)\n' "${YELLOW}" "${NC}" \
      "${label}" "${expected_line}" "${line_num}"
    pass_count=$((pass_count + 1))
  fi
}

printf '%b-- Storage layer --%b\n' "${BLUE}" "${NC}"
check 'scheduled_tasks.json path constant Rhz' '2710' 'Rhz=Mi1(".claude","scheduled_tasks.json")'
check 'Job creator wl4(q,K,_,z,Y,A)'           '2710' 'function wl4(q,K,_,z,Y,A)'
check 'Async file reader sL6'                  'any'  'async function sL6'
check 'File writer Xi1(q,K)'                   'any'  'function Xi1(q,K)'

printf '\n'
printf '%b-- Tool surface --%b\n' "${BLUE}" "${NC}"
check 'Tool name $k="CronCreate"'              '2747' '$k="CronCreate"'
check 'durable description string'             '2737' 'Pass durable: true to write to .claude/scheduled_tasks.json'
check 'recurring docstring example'            'any'  'One-shot tasks'

printf '\n'
printf '%b-- Replay path --%b\n' "${BLUE}" "${NC}"
check 'Cron enqueue priority:"later",isMeta:!0' 'any'  'priority:"later",isMeta:!0'
check 'k57 returns {text,mode:"prompt"}'       '4887' 'return{text:_S7(K),mode:"prompt"}'
check 'k57 type guard on user'                 '4887' 'if(q.type!=="user")return null'

printf '\n'
printf '%b-- System reminder asymmetry --%b\n' "${BLUE}" "${NC}"
check 'opened_file_in_ide case with isMeta:!0' 'any'  'case"opened_file_in_ide":'
check 'plan_file_reference case with isMeta:!0' 'any' 'case"plan_file_reference":'
check '<system-reminder> wrapper emitted'      'any'  '<system-reminder>'

printf '\n'
printf '%b-- Classifier rules (that do NOT save us) --%b\n' "${BLUE}" "${NC}"
check '"delayed effects" reasoning rule'       '2827' 'consider delayed effects'
check '"Unauthorized Persistence" rule'        '2880' 'Unauthorized Persistence'
check '"creating cron jobs" in rule'           '2880' 'creating cron jobs'

printf '\n'
printf '%b-- Asymmetry negative checks --%b\n' "${BLUE}" "${NC}"
# These should NOT exist — a hit is a FAIL (bug fixed / different codepath)
neg_count=0
neg_total=0

neg_check() {
  local label="$1"
  local pattern="$2"
  neg_total=$((neg_total + 1))
  local hit
  hit="$(rg --fixed-strings -n -m1 -- "${pattern}" "${CLI_JS}" 2>/dev/null | head -n1)"
  if [ -z "${hit}" ]; then
    printf '  %b[PASS]%b  %s (no match — confirms asymmetry)\n' "${GREEN}" "${NC}" "${label}"
    neg_count=$((neg_count + 1))
  else
    printf '  %b[FAIL]%b  %s (unexpected match: %s)\n' "${RED}" "${NC}" "${label}" "${hit}"
  fi
}

neg_check 'no "scheduled_task_replay" case in renderer'     'scheduled_task_replay'
neg_check 'no "cron_prompt_replay" wrapper anywhere'        'cron_prompt_replay'
neg_check 'no "replayed from scheduled task" marker string' 'replayed from scheduled task'
neg_check 'no re-classification call on sL6 result'         'classify(await sL6'

printf '\n'
printf '%b==== Summary ====%b\n' "${BLUE}" "${NC}"
printf 'Positive checks : %d / %d\n' "${pass_count}" "${total}"
printf 'Negative checks : %d / %d\n' "${neg_count}" "${neg_total}"

if [ "${fail_count}" -eq 0 ] && [ "${neg_count}" -eq "${neg_total}" ]; then
  printf '%bOVERALL: PASS — all evidence verified on live cli.js%b\n' "${GREEN}" "${NC}"
  exit 0
else
  printf '%bOVERALL: FAIL — %d positive failures, %d negative failures%b\n' \
    "${RED}" "${fail_count}" "$((neg_total - neg_count))" "${NC}"
  exit 1
fi
