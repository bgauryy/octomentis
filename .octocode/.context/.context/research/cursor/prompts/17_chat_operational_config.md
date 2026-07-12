# Chat Operational Configuration

**Source:** `server_config.json` — `chatConfig` from `ServerConfigService/GetServerConfig`

## Configuration (server-side)

These settings shape how the chat/agent system operates:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `fullContextTokenLimit` | 30,000 | Max tokens in full context window |
| `maxRuleLength` | 100,000 | Max chars for a single rule file |
| `maxMcpTools` | 100 | Max MCP tools allowed per session |
| `warnMcpTools` | 80 | Warn when MCP tools exceed this |
| `summarizationMessage` | "Chat context summarized." | Shown when context is summarized |
| `numFilesForMemoryGeneration` | 999,999 | Effectively unlimited files for memory |
| `numSummarizationsBeforeWarningShown` | 10 | Warn after N summarizations |
| `cursorRulesReadFileFixEnabled` | true | Fix for reading .cursor/rules |
| `dontSendCtrlCBeforeCommand` | true | Don't send Ctrl+C before terminal commands |
