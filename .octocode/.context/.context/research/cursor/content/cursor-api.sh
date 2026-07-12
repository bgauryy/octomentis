#!/usr/bin/env bash
# Cursor API Client — mimics how Cursor IDE calls api2.cursor.sh
# Uses the same gRPC-web (connect-rpc) auth, checksum, and headers as the real client.
set -euo pipefail

CONTENT_DIR="$(cd "$(dirname "$0")" && pwd)"
DB="$HOME/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
BASE_URL="https://api2.cursor.sh"
VERSION="3.0.16"

# ── Extract credentials ──────────────────────────────────────────
dbval() { sqlite3 "$DB" "SELECT value FROM ItemTable WHERE key = '$1'" 2>/dev/null; }

TOKEN="$(dbval 'cursorAuth/accessToken')"
MACHINE_ID="$(dbval 'storage.serviceMachineId')"
EMAIL="$(dbval 'cursorAuth/cachedEmail')"
MEMBERSHIP="$(dbval 'cursorAuth/stripeMembershipType')"

[ -z "$TOKEN" ] && { echo "ERROR: No access token. Is Cursor logged in?" >&2; exit 1; }

# ── Compute x-cursor-checksum (reverse-engineered from workbench.desktop.main.js) ──
compute_checksum() {
  node -e "
    const y = Math.floor(Date.now() / 1e6);
    const b = new Uint8Array([(y>>40)&255,(y>>32)&255,(y>>24)&255,(y>>16)&255,(y>>8)&255,y&255]);
    let e = 165;
    for (let t = 0; t < b.length; t++) { b[t] = (b[t] ^ e) + t % 256; e = b[t]; }
    process.stdout.write(Buffer.from(b).toString('base64') + '${MACHINE_ID}');
  "
}

# ── API call helper ──────────────────────────────────────────────
# Usage: api <service/method> <outfile> [json_body]
api() {
  local endpoint="$1"
  local outfile="$2"
  local body="${3:-{\}}"
  local ck
  ck="$(compute_checksum)"

  curl -s -X POST "${BASE_URL}/${endpoint}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "x-cursor-client-version: ${VERSION}" \
    -H "x-cursor-client-type: ide" \
    -H "x-cursor-client-os: darwin" \
    -H "x-cursor-client-arch: arm64" \
    -H "x-cursor-client-device-type: desktop" \
    -H "x-cursor-client-os-version: 24.6.0" \
    -H "x-ghost-mode: false" \
    -H "x-cursor-checksum: ${ck}" \
    -H "x-cursor-timezone: $(date +%Z)" \
    -H "connect-protocol-version: 1" \
    --data-raw "$body" > "$outfile"

  local sz; sz=$(wc -c < "$outfile" | tr -d ' ')
  echo "  ✓ $(basename "$outfile") (${sz}B)"
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Cursor API Fetcher — api2.cursor.sh                 ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║ Email:      ${EMAIL}"
echo "║ Membership: ${MEMBERSHIP}"
echo "║ Machine:    ${MACHINE_ID}"
echo "║ Version:    ${VERSION}"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ═════════════════════════════════════════════════════════════════
# 1. AGENT SERVICE (agent.v1.AgentService)
# ═════════════════════════════════════════════════════════════════
echo "▸ 1. agent.v1.AgentService"
api "agent.v1.AgentService/GetUsableModels" "$CONTENT_DIR/agent_usable_models.json" '{}'
api "agent.v1.AgentService/NameAgent" "$CONTENT_DIR/agent_name_agent.json" '{"userMessage":"Build a REST API with authentication"}'
api "agent.v1.AgentService/CreateTranscriptOverview" "$CONTENT_DIR/agent_transcript_overview.json" '{"formattedConversation":"User: How do I use async/await?\nAssistant: Here is how..."}'
api "agent.v1.AgentService/GetDefaultModelForCli" "$CONTENT_DIR/agent_default_cli_model.json" '{}'
api "agent.v1.AgentService/GetNewChatNudgeParameterizedModelPicker" "$CONTENT_DIR/agent_model_picker_nudge.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 2. AI SERVICE (aiserver.v1.AiService)
# ═════════════════════════════════════════════════════════════════
echo "▸ 2. aiserver.v1.AiService"
api "aiserver.v1.AiService/ServerTime" "$CONTENT_DIR/ai_server_time.json" '{}'
api "aiserver.v1.AiService/GetSimplePrompt" "$CONTENT_DIR/ai_simple_prompt.json" '{"query":"Explain dependency injection","answerPlaceholder":""}'
api "aiserver.v1.AiService/GetUserInstructions" "$CONTENT_DIR/ai_user_instructions.json" '{}'
api "aiserver.v1.AiService/GetChatSuggestions" "$CONTENT_DIR/ai_chat_suggestions.json" '{}'
api "aiserver.v1.AiService/CheckFeatureStatus" "$CONTENT_DIR/ai_feature_status.json" '{"feature":"agent"}'
api "aiserver.v1.AiService/CheckFeaturesStatus" "$CONTENT_DIR/ai_features_status.json" '{"features":["agent","composer","chat","predictions","tab","background_agent","grind_mode"]}'
api "aiserver.v1.AiService/GetEffectiveTokenLimit" "$CONTENT_DIR/ai_token_limit_opus.json" '{"modelName":"claude-4.6-opus-high"}'
api "aiserver.v1.AiService/GetEffectiveTokenLimit" "$CONTENT_DIR/ai_token_limit_gpt5.json" '{"modelName":"gpt-5.4-high"}'
api "aiserver.v1.AiService/ShowWelcomeScreen" "$CONTENT_DIR/ai_welcome_screen.json" '{}'
api "aiserver.v1.AiService/GetComposerAutocomplete" "$CONTENT_DIR/ai_composer_autocomplete.json" '{"query":"implement a"}'
api "aiserver.v1.AiService/ShouldTurnOnCppOnboarding" "$CONTENT_DIR/ai_cpp_onboarding.json" '{}'
api "aiserver.v1.AiService/CheckQueuePosition" "$CONTENT_DIR/ai_queue_position.json" '{}'
api "aiserver.v1.AiService/CheckUsageBasedPrice" "$CONTENT_DIR/ai_usage_price.json" '{}'
api "aiserver.v1.AiService/CppConfig" "$CONTENT_DIR/ai_cpp_config.json" '{}'
api "aiserver.v1.AiService/IsCursorPredictionEnabled" "$CONTENT_DIR/ai_prediction_enabled.json" '{}'
api "aiserver.v1.AiService/AvailableDocs" "$CONTENT_DIR/ai_available_docs.json" '{}'
api "aiserver.v1.AiService/IntentPrediction" "$CONTENT_DIR/ai_intent_prediction.json" '{"query":"refactor to async/await"}'
api "aiserver.v1.AiService/GetContextScores" "$CONTENT_DIR/ai_context_scores.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 3. AUTH SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 3. aiserver.v1.AuthService"
api "aiserver.v1.AuthService/GetEmail" "$CONTENT_DIR/auth_email.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 4. SERVER CONFIG
# ═════════════════════════════════════════════════════════════════
echo "▸ 4. aiserver.v1.ServerConfigService"
api "aiserver.v1.ServerConfigService/GetServerConfig" "$CONTENT_DIR/server_config.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 5. HEALTH & NETWORK
# ═════════════════════════════════════════════════════════════════
echo "▸ 5. Health & Network"
api "aiserver.v1.HealthService/Ping" "$CONTENT_DIR/health_ping.json" '{}'
api "aiserver.v1.NetworkService/GetPublicIp" "$CONTENT_DIR/network_public_ip.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 6. DASHBOARD / TEAMS / CREDITS
# ═════════════════════════════════════════════════════════════════
echo "▸ 6. Dashboard & Teams"
api "aiserver.v1.DashboardService/GetTeams" "$CONTENT_DIR/dashboard_teams.json" '{}'
api "aiserver.v1.TeamCreditsService/GetTeamCredits" "$CONTENT_DIR/team_credits.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 7. MCP REGISTRY
# ═════════════════════════════════════════════════════════════════
echo "▸ 7. aiserver.v1.MCPRegistryService"
api "aiserver.v1.MCPRegistryService/GetKnownServers" "$CONTENT_DIR/mcp_known_servers.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 8. CURSOR PREDICTION
# ═════════════════════════════════════════════════════════════════
echo "▸ 8. aiserver.v1.CursorPredictionService"
api "aiserver.v1.CursorPredictionService/CursorPredictionConfig" "$CONTENT_DIR/prediction_config.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 9. BACKGROUND COMPOSER (Cloud Agent)
# ═════════════════════════════════════════════════════════════════
echo "▸ 9. aiserver.v1.BackgroundComposerService"
api "aiserver.v1.BackgroundComposerService/ListBackgroundComposers" "$CONTENT_DIR/bg_composers_list.json" '{}'
api "aiserver.v1.BackgroundComposerService/ListDetailedBackgroundComposers" "$CONTENT_DIR/bg_composers_detailed.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 10. MARKETPLACE
# ═════════════════════════════════════════════════════════════════
echo "▸ 10. aiserver.v1.MarketplaceService"
api "aiserver.v1.MarketplaceService/GetMarketplace" "$CONTENT_DIR/marketplace.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 11. IN-APP ADS
# ═════════════════════════════════════════════════════════════════
echo "▸ 11. aiserver.v1.InAppAdService"
api "aiserver.v1.InAppAdService/GetAd" "$CONTENT_DIR/inapp_ad.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 12. SCM (GitHub integration)
# ═════════════════════════════════════════════════════════════════
echo "▸ 12. aiserver.v1.SCMService"
api "aiserver.v1.SCMService/GetPullRequest" "$CONTENT_DIR/scm_pull_request.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 13. CODEBASE SNAPSHOT
# ═════════════════════════════════════════════════════════════════
echo "▸ 13. aiserver.v1.CodebaseSnapshotService"
api "aiserver.v1.CodebaseSnapshotService/RegisterCodebase" "$CONTENT_DIR/codebase_register.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 14. REPOSITORY SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 14. aiserver.v1.RepositoryService"
api "aiserver.v1.RepositoryService/FastRepoInitHandshake" "$CONTENT_DIR/repo_handshake.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 15. GIT INDEX
# ═════════════════════════════════════════════════════════════════
echo "▸ 15. aiserver.v1.GitIndexService"
api "aiserver.v1.GitIndexService/RepoHistoryInitHandshake" "$CONTENT_DIR/git_index_handshake.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 16. FAST SEARCH
# ═════════════════════════════════════════════════════════════════
echo "▸ 16. aiserver.v1.FastSearchService"
api "aiserver.v1.FastSearchService/StartFastSearch" "$CONTENT_DIR/fast_search_start.json" '{"query":"authentication middleware"}'

# ═════════════════════════════════════════════════════════════════
# 17. CONVERSATIONS
# ═════════════════════════════════════════════════════════════════
echo "▸ 17. aiserver.v1.ConversationsService"
api "aiserver.v1.ConversationsService/GetCommitMetrics" "$CONTENT_DIR/conversations_metrics.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 18. AUTOMATIONS
# ═════════════════════════════════════════════════════════════════
echo "▸ 18. aiserver.v1.AutomationsService"
api "aiserver.v1.AutomationsService/CreateAutomation" "$CONTENT_DIR/automations_create.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 19. HALLUCINATED FUNCTIONS
# ═════════════════════════════════════════════════════════════════
echo "▸ 19. aiserver.v1.HallucinatedFunctionsService"
api "aiserver.v1.HallucinatedFunctionsService/V0ChainRun" "$CONTENT_DIR/hallucinated_functions.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 20. ENTERPRISE ADMIN
# ═════════════════════════════════════════════════════════════════
echo "▸ 20. aiserver.v1.EnterpriseAdminService"
api "aiserver.v1.EnterpriseAdminService/GetManualEnterpriseContract" "$CONTENT_DIR/enterprise_contract.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 21. BUGBOT SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 21. aiserver.v1.BugbotService"
api "aiserver.v1.BugbotService/LogDeeplinkEvent" "$CONTENT_DIR/bugbot_deeplink.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 22. BUGBOT ADMIN
# ═════════════════════════════════════════════════════════════════
echo "▸ 22. aiserver.v1.BugbotAdminService"
api "aiserver.v1.BugbotAdminService/GetTeamTrialEnd" "$CONTENT_DIR/bugbot_trial_end.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 23. REVIEW SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 23. aiserver.v1.ReviewService"
api "aiserver.v1.ReviewService/StreamReview" "$CONTENT_DIR/review_stream.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 24. DEEPLINK SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 24. aiserver.v1.DeeplinkService"
api "aiserver.v1.DeeplinkService/CreateDeeplink" "$CONTENT_DIR/deeplink_create.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 25. SCHEDULER / DISTRIBUTOR
# ═════════════════════════════════════════════════════════════════
echo "▸ 25. Scheduler & Distributor"
api "aiserver.v1.SchedulerService/Acquire" "$CONTENT_DIR/scheduler_acquire.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 26. USAGE SIMULATION
# ═════════════════════════════════════════════════════════════════
echo "▸ 26. aiserver.v1.UsageSimulationService"
api "aiserver.v1.UsageSimulationService/GetSimulation" "$CONTENT_DIR/usage_simulation.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 27. LINTER SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 27. aiserver.v1.LinterService"
api "aiserver.v1.LinterService/LintFile" "$CONTENT_DIR/linter_lint.json" '{"filePath":"test.ts","fileContent":"const x: string = 5;"}'

# ═════════════════════════════════════════════════════════════════
# 28. FAST APPLY
# ═════════════════════════════════════════════════════════════════
echo "▸ 28. aiserver.v1.FastApplyService"
api "aiserver.v1.FastApplyService/ReportEditFate" "$CONTENT_DIR/fast_apply_fate.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 29. SHADOW WORKSPACE
# ═════════════════════════════════════════════════════════════════
echo "▸ 29. aiserver.v1.ShadowWorkspaceService"
api "aiserver.v1.ShadowWorkspaceService/GetLintsForChange" "$CONTENT_DIR/shadow_lints.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 30. AI BRANCH (Opus Chain)
# ═════════════════════════════════════════════════════════════════
echo "▸ 30. aiserver.v1.AiBranchService"
api "aiserver.v1.AiBranchService/OpusChainGetPlan" "$CONTENT_DIR/ai_branch_plan.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 31. AI PROJECT SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 31. aiserver.v1.AiProjectService"
api "aiserver.v1.AiProjectService/AiProjectAgentInit" "$CONTENT_DIR/ai_project_init.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 32. CMDK SERVICE (inline edits)
# ═════════════════════════════════════════════════════════════════
echo "▸ 32. aiserver.v1.CmdKService"
api "aiserver.v1.CmdKService/StreamCmdK" "$CONTENT_DIR/cmdk_stream.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 33. INFERENCE SERVICE (raw model)
# ═════════════════════════════════════════════════════════════════
echo "▸ 33. aiserver.v1.InferenceService"
api "aiserver.v1.InferenceService/Stream" "$CONTENT_DIR/inference_stream.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 34. CHAT SERVICE (unified)
# ═════════════════════════════════════════════════════════════════
echo "▸ 34. aiserver.v1.ChatService"
api "aiserver.v1.ChatService/StreamUnifiedChat" "$CONTENT_DIR/chat_unified_stream.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 35. AUTOPILOT SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 35. aiserver.v1.AutopilotService"
api "aiserver.v1.AutopilotService/StreamAutopilot" "$CONTENT_DIR/autopilot_stream.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 36. REPLAY CHAT
# ═════════════════════════════════════════════════════════════════
echo "▸ 36. aiserver.v1.ReplayChatService"
api "aiserver.v1.ReplayChatService/StreamReplayChat" "$CONTENT_DIR/replay_chat_stream.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 37. GIT GRAPH
# ═════════════════════════════════════════════════════════════════
echo "▸ 37. aiserver.v1.GitGraphService"
api "aiserver.v1.GitGraphService/InitGitGraph" "$CONTENT_DIR/git_graph_init.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 38. BIDI SERVICE
# ═════════════════════════════════════════════════════════════════
echo "▸ 38. aiserver.v1.BidiService"
api "aiserver.v1.BidiService/BidiAppend" "$CONTENT_DIR/bidi_append.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 39. DEBUGGER
# ═════════════════════════════════════════════════════════════════
echo "▸ 39. aiserver.v1.DebuggerService"
api "aiserver.v1.DebuggerService/GitFilter" "$CONTENT_DIR/debugger_git_filter.json" '{}'

# ═════════════════════════════════════════════════════════════════
# 40. CLIENT LOGGER
# ═════════════════════════════════════════════════════════════════
echo "▸ 40. aiserver.v1.ClientLoggerService"
api "aiserver.v1.ClientLoggerService/GetDebuggingDataUploadUrl" "$CONTENT_DIR/client_logger_url.json" '{}'

# ═════════════════════════════════════════════════════════════════
# DONE
# ═════════════════════════════════════════════════════════════════
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DONE — All output in: ${CONTENT_DIR}/"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "File summary:"
for f in "$CONTENT_DIR"/*.json; do
  sz=$(wc -c < "$f" | tr -d ' ')
  name=$(basename "$f")
  first50=$(head -c 120 "$f" | tr '\n' ' ')
  printf "  %-45s %6sB  %s\n" "$name" "$sz" "$first50"
done
