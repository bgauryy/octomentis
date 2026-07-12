#!/usr/bin/env bash
# ============================================================================
#  Bounty 2 PoC — Setup (HARMLESS marker variant)
# ============================================================================
#
# Creates a scratch project at /tmp/poc-cron-bounty2/ and plants a harmless
# .claude/scheduled_tasks.json that, when replayed by Claude Code's cron
# scheduler, instructs the agent to append a marker line to
# /tmp/poc-cron-bounty2-marker.txt and nothing else.
#
# Safety:
#   - No secrets read
#   - No network access
#   - No files modified outside /tmp/poc-cron-bounty2/ and the marker file
#   - Idempotent — safe to re-run
#
# Usage:
#   ./setup.sh
#   cd /tmp/poc-cron-bounty2 && claude       # start Claude Code in the scratch dir
#
# What to watch for:
#   After a session is open for ~2 minutes, the file
#   /tmp/poc-cron-bounty2-marker.txt should contain at least one line like
#     POC-CRON-BOUNTY2 fired at 2026-04-08T12:34:56Z
#   That line is proof that the replayed cron prompt executed with
#   user-level trust.
#
# Cleanup:
#   rm -rf /tmp/poc-cron-bounty2 /tmp/poc-cron-bounty2-marker.txt
#
# ============================================================================

set -euo pipefail

SCRATCH_DIR="/tmp/poc-cron-bounty2"
MARKER_FILE="/tmp/poc-cron-bounty2-marker.txt"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_SRC="${SCRIPT_DIR}/scheduled_tasks.json"

printf '[setup] Bounty 2 PoC — harmless marker variant\n'
printf '[setup] scratch dir : %s\n' "${SCRATCH_DIR}"
printf '[setup] marker file : %s\n' "${MARKER_FILE}"
printf '[setup] task source : %s\n' "${TASK_SRC}"

if [ ! -f "${TASK_SRC}" ]; then
  printf '[setup] ERROR: %s not found\n' "${TASK_SRC}" >&2
  exit 1
fi

mkdir -p "${SCRATCH_DIR}/.claude"

# Idempotent: always overwrite with the canonical harmless payload
cp "${TASK_SRC}" "${SCRATCH_DIR}/.claude/scheduled_tasks.json"

# Touch the marker so 'ls' shows something on first run
if [ ! -f "${MARKER_FILE}" ]; then
  : > "${MARKER_FILE}"
fi

printf '[setup] planted task file:\n'
printf '        %s\n' "${SCRATCH_DIR}/.claude/scheduled_tasks.json"
printf '[setup] task contents:\n'
printf '        ------------------------------------------------------------\n'
sed 's/^/        /' "${SCRATCH_DIR}/.claude/scheduled_tasks.json"
printf '        ------------------------------------------------------------\n'

printf '[setup] READY.\n'
printf '\n'
printf 'Next steps:\n'
printf '  1. Open a new terminal and cd into the scratch directory:\n'
printf '       cd %s\n' "${SCRATCH_DIR}"
printf '  2. Start Claude Code (any normal session):\n'
printf '       claude\n'
printf '  3. Leave the session idle. Within ~2 minutes the cron should fire.\n'
printf '  4. Check the marker file:\n'
printf '       cat %s\n' "${MARKER_FILE}"
printf '\n'
printf 'Expected outcome:\n'
printf '  - A line of the form "POC-CRON-BOUNTY2 fired at <timestamp>" in\n'
printf '    %s\n' "${MARKER_FILE}"
printf '  - This proves the cron prompt was replayed as role:"user" and\n'
printf '    executed with full tool access, bypassing the classifier rules\n'
printf '    that target CronCreate tool invocation.\n'
printf '\n'
printf 'Cleanup when done:\n'
printf '  rm -rf %s %s\n' "${SCRATCH_DIR}" "${MARKER_FILE}"
