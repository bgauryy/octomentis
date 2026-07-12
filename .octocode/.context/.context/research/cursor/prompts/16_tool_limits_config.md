# Tool Limits & Operational Configuration

**Source:** `workbench.desktop.main.js` — `tool_limits_config` Statsig dynamic config

## Configuration (embedded defaults)

These limits control how tools behave during agent execution:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `readFilesToolMaxFileSizeInBytes` | 2,000,000 (2MB) | Max file size for ReadFiles tool |
| `editFileToolMaxFileSizeInChars` | 150,000 | Max chars for EditFile tool |
| `fileSearchToolMaxResults` | 10 | Max results from FileSearch |
| `listDirV2ClientSideCharacterBudget` | 1,000 | Char budget for ListDir output |
| `readFileV2ToolMaxFileSizeInBytes` | 200,000,000 (200MB) | Max for ReadFileV2 (binary) |
| `composerDiffMaxComputationTimeMs` | 2,000 | Max diff computation time |
