# BOUNTY-5: Plugin Installation via Deep Link — Supply Chain Vector

## Classification

| Field | Value |
|-------|-------|
| ID | BOUNTY-5 |
| Severity | **MEDIUM** |
| Confidence | confirmed |
| CWE | CWE-494 (Download of Code Without Integrity Check), CWE-829 (Inclusion of Untrusted Functionality) |
| Category | Supply Chain Attack via URI Scheme |
| Target | Cursor.app v3.0.12 — `cursor-deeplink` extension, `/plugin/add` path |

---

## Summary

The `cursor://` URI handler accepts a `/plugin/add` path that opens the extension marketplace installer for any plugin ID. Combined with typosquatted or malicious extensions on the marketplace, this enables one-click supply chain attacks. Notably, the install call includes `skipTracking: true`, bypassing Cursor's installation tracking.

---

## How It Works

**Handler** (`cursor-deeplink/dist/main.js:124600`):
```javascript
t.handlePluginAdd = async function(e) {
  const A = t.get("id")?.trim();
  // Opens marketplace installer for ANY plugin ID:
  await r.commands.executeCommand(
    "workbench.action.openMarketplaceEditor",
    {
      pluginId: A,
      openInstallModal: true,    // Auto-opens install dialog
      skipTracking: true          // ← Bypasses install tracking!
    }
  );
};
```

---

## Steps To Reproduce

```bash
# Attacker publishes typosquatted extension "pretier" (instead of "prettier"):
LINK="cursor://anysphere.cursor-deeplink/plugin/add?id=attacker.pretier"
```

Place on website: "Install Prettier for Cursor: [Install](cursor://...)"

User clicks → Cursor opens the install dialog for the malicious extension.

---

## Impact

- Opens install modal for any extension ID — no validation
- `skipTracking: true` means the install bypasses analytics/monitoring
- Combined with marketplace typosquatting: user sees familiar name, clicks install
- Malicious extension gains full extension API access (file read/write, terminal, network)
- Social engineering is minimal — "install this extension" is a normal workflow

---

## Mitigation

1. Remove `skipTracking: true` — all installs should be tracked
2. Add a warning banner: "This extension was suggested by an external link"
3. Validate plugin ID against a known-good list or add a delay/confirmation step
4. Show the extension's trust level and download count prominently in the deeplink flow
