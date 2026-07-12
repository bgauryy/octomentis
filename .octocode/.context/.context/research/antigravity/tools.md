# Antigravity Agent Tools — Complete Inventory

## Core Agent Tools (extracted from language server binary)

### File Operations
```
read_file          — Read file contents
write_to_file      — Write content to file  
edit_file          — Edit existing file with replacements
create_file        — Create a new file
delete_file        — Delete a file
replace_content    — Replace content in file (ReplacementChunks)
```

### Search & Discovery
```
grep_search        — "Use ripgrep to find exact pattern matches within files or directories"
codebase_search    — Semantic codebase search (embeddings-based)
file_search        — Search for files by name
find_by_name       — Find files by name pattern
list_directory     — List directory contents
```

### Command Execution
```
execute_command    — Execute a shell command
run_command        — Run a terminal command
manage_task        — "Use the manage_task tool to interact with them (e.g. to kill them or check their status)"
send_message       — Send messages between agents/tasks
                     "send_message should not be used to provide input to tasks; use the manage_task tool with action 'send_input' instead"
```

### Web & Network
```
web_search         — Search the web
read_url_content   — "Read URL content from [url]"
open_url           — Open URL in browser
check_deploy_status — Check deployment status
```

### Browser Automation (30+ tools via CDP)
```
browser_url                    — Navigate to URL
browser_click                  — Click at coordinates
browser_click_element          — Click DOM element
browser_input                  — Type text input
browser_press_key              — Press keyboard key
browser_select_option          — Select dropdown option
browser_scroll_up              — Scroll up
browser_scroll_down            — Scroll down
browser_scroll                 — General scroll
browser_get_dom                — Get DOM tree
browser_screenshot             — Take page screenshot
browser_pixel                  — Get pixel info
browser_javascript             — Execute JavaScript in browser
browser_pages                  — List all pages
browser_page                   — Switch to page
browser_refresh_page           — Refresh current page
browser_resize_window          — Resize browser window
browser_text                   — Get text content
browser_move_mouse             — Move mouse to position
browser_mouse_down             — Mouse button down
browser_mouse_up               — Mouse button up
browser_mouse_wheel            — Mouse wheel scroll
browser_drag_pixel_to_pixel    — Drag and drop
browser_get_network_request    — Inspect specific network request
browser_list_network_requests  — List all network requests
browser_subagent               — Spawn browser-focused sub-agent
browser_console_logs           — Get console output
```

### Agent & Task Management
```
mcp_tool           — Call MCP server tools
invoke_subagent    — Invoke a subagent
define_subagent    — Define a new subagent
```

### Notebook Support
```
notebook_edit      — Edit Jupyter notebook cells
```

## Tool Implementation Architecture

Tools are implemented in Go at `google3/third_party/jetski/cortex/tools/`:

| Directory | Purpose |
|-----------|---------|
| `tools/code/` | File editing (ReplacementChunk, replaceFileContentArgs) |
| `tools/browser/` | Browser automation via Chrome DevTools Protocol |
| `tools/knowledge/` | Knowledge base and search |
| `tools/notebook/` | Jupyter notebook operations |
| `tools/subagent/` | Subagent spawning and management |
| `tools/tooloverrides/` | SDK tool override system |

## Tool Validation Strings

From the binary, these validation messages reveal tool constraints:

- "ReplacementChunks is a required parameter. Follow the function call schema exactly."
- "TargetFile is a required parameter. Please follow the function call schema exactly."
- "you may not create the file diffs artifact, the system will update it automatically"
- "user reviewed the command and decided not to run it, check with the user to continue"
- "Grep is only allowed within the workspace. We could not determine if the search path is in the workspace."
- "Find is only allowed within the workspace. We could not determine if the search path is in the workspace."
- "Wait for a specified duration before continuing execution. The maximum duration is 60 seconds."
- "Moving mouse to coordinates (%d, %d) on browser page with page_id: %s"
- "failed to call click function on element with backendNodeId %d"

## Auto-Execution Policy

The system has fine-grained command execution policies:

```
cascadeAllowedCommands   — Whitelist of allowed commands
cascadeDeniedCommands    — Blacklist of denied commands
cascadeAutoExecutionPolicy — Auto-run policy (ask/allow/deny)
```

Browser-specific:
```
browser_js_execution_policy      — JS execution policy
browser_js_auto_run_policy       — Auto-run JS policy
browser_js_execution_enabled     — Global JS execution toggle
```
