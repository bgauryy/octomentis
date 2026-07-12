# MCP Authentication Status Messages

**Source:** `workbench.desktop.main.js` at charOffset ~27703359
**Config key:** `mcp_auth_status_copy_config`

---

## Auth Tool Description

```
Authenticate this MCP server so its tools can be used. Call this tool through your MCP tool-calling interface when STATUS.md indicates this server needs authentication.
```

## Error Status Message

```
The MCP server errored. If this server is important for completing the task, concisely inform the user and ask them to check the MCP status in Cursor Settings; otherwise continue with a different approach.
```

## Needs Auth Status Message (with auth tool)

```
The MCP server needs authentication. Authenticate it by calling the `{authToolName}` tool for server "{serverIdentifier}" through your MCP tool-calling interface using an empty arguments object. If this server is important for completing the task, do that first; otherwise continue with a different approach.
```

## Config Defaults

| Setting | Value |
|---------|-------|
| `fastRetryBaseDelayMs` | 5,000 |
| `fastRetryMaxDelayMs` | 60,000 |
| `fastRetryMaxAttempts` | 5 |
| `periodicRetryBaseDelayMs` | 300,000 (5 min) |
| `periodicRetryMaxDelayMs` | 1,800,000 (30 min) |
| `focusRetryCooldownMs` | 300,000 (5 min) |
| `healthProbeTimeoutMs` | 10,000 |
| `degradedProbeDelayMs` | 30,000 |
| `maxDegradedProbeFailures` | 3 |
| `keepaliveProbeDelayMs` | 300,000 (5 min) |
| `stabilityThresholdMs` | 30,000 |
