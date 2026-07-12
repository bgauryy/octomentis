# Rules Assembly — How .cursor/rules/ Files Are Injected

**Source:** `workbench.desktop.main.js` at charOffset ~31734144
**Function:** Anonymous rule assembly function

---

## Mechanism

Cursor assembles a `<rules>` XML block that is injected into the system prompt. Rules come from multiple sources:

### Rule Types

| Kind | Source | Behavior |
|------|--------|----------|
| `alwaysAppliedWorkspace` | `.cursor/rules/*.mdc` with `alwaysApply: true` | Injected into every system prompt |
| `requestableWorkspace` | `.cursor/rules/*.mdc` with `alwaysApply: false` | Listed by path; agent can read if relevant |
| `repoSpecific` | Repo-level AI context setting | Injected if non-empty |
| `manuallyAttached` | User manually attaches via @ mention | Injected with content inline |

### Assembly Template

```xml
<rules>
The rules section has a number of possible rules/memories/context that you should consider.
In each subsection, we provide instructions about what information the subsection contains
and how you should consider/follow the contents of the subsection.

<always_applied_workspace_rules description="These are workspace-level rules that the agent must always follow.">
  <always_applied_workspace_rule name="{fullPath}">{content}</always_applied_workspace_rule>
  ...
</always_applied_workspace_rules>

<agent_requestable_workspace_rules description="These are workspace-level rules that the agent should follow. Use the Read tool with the provided absolute path to fetch full contents.">
  <agent_requestable_workspace_rule fullPath="{fullPath}">{description}</agent_requestable_workspace_rule>
  ...
</agent_requestable_workspace_rules>

<repo_specific_rule description="This is a rule set by the user about the repository that the agent must follow">
  {content}
</repo_specific_rule>

</rules>
```

### Manually Attached Rules (Cursor Rules Context)

When rules are manually attached via @ mention, they're injected separately:

```xml
<cursor_rules_context>
Cursor Rules are extra documentation provided by the user to help the AI understand the codebase.
Use them if they seem useful to the users most recent query, but do not use them if they seem unrelated.

Rule Name: {filename}
Description: {content}

</cursor_rules_context>
```

## Security Note

Rule content is read from `.cursor/rules/*.mdc` files with minimal sanitization. The content is parsed via `aEb()` (which strips frontmatter) but is otherwise injected as-is into the system prompt. This is the attack surface exploited in BOUNTY-2 (rule injection via deep link).
