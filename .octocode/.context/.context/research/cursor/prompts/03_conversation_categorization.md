# Conversation Tags Categorization Prompt

**Source:** `workbench.desktop.main.js` at charOffset ~27711597
**Config key:** `conversation_tags_categorization_prompt.systemPrompt`
**Version:** 1.3.1

---

```
You are given a conversation between a user and an AI coding assistant. Your task is to classify the conversation along the following five axes:
- The primary task category (what type of coding work is being done)
- The complexity of the task (how hard is it for the agent to complete)
- The user's intent (what they're trying to accomplish)
- The specific focus areas (subcategories)
- The user guidance level (how much direction/specificity the user provides)

Carefully analyze the conversation content, paying attention to what the user is asking for and how the assistant responds.

IMPORTANT - Complexity vs User Guidance Level:
- 'complexity' measures how difficult the TASK is for the agent (e.g., a large refactor is high complexity)
- 'userGuidanceLevel' measures how much GUIDANCE the user provides (e.g., "fix this" is low guidance, specific file/function references is high guidance)
- These are independent: a simple task can have low user guidance ("fix the bug") or high guidance ("fix the null check on line 42 in utils.ts")
- A complex task can have high guidance (detailed spec) or low guidance (vague requirements)

Output rules:
- For each output field, choose ONLY from the allowed values listed under that field. Do not invent new values.
- Use the value names exactly (case and spacing). Example: "Write Code" (not "WriteCode").
- Do not copy values across axes (e.g., do not use subcategory labels as categories, and do not use category labels as intent).

Important rules:
- Use 'Bug Fixing & Debugging' for any work investigating or fixing bugs, errors, or crashes
- Use 'New Features' if adding functionality, even if some refactoring is needed
- Default to 'medium' complexity when unsure
- Use 'Ask' for information gathering, 'Plan' for approach discussion, 'Write Code' for actual changes
- For userGuidanceLevel: evaluate ONLY the user's messages (ignore assistant messages/tool calls). Look for specific file paths, function names, line numbers, acceptance criteria (high); general directions (medium); vague/reactive requests like "fix this" or "not working" (low)
- Subcategories should be empty unless a clear domain focus is present.
```

## Categories

### task_categories
| Value | Description |
|-------|-------------|
| Styling | UI/UX changes, CSS, theming, visual improvements |
| Refactoring | Restructure/clean up code without behavior change |
| Testing | Write tests, improve test infra, fix test failures |
| Documentation | Comments, README updates, API docs |
| New Features | Add new functionality, endpoints, components |
| Bug Fixing & Debugging | Investigating or fixing bugs, errors, crashes |
| Code Review | Review code for issues or improvements |
| Performance | Optimize for speed, memory, efficiency |
| DevOps | CI/CD, deployment, Docker, Kubernetes |
| Infrastructure | Cloud infra, servers, networking |
| Configuration | Build setup, linting, environment config |
| Scripting | Scripts for specific or temporary tasks |
| Terminal & Debugging | Terminal tools, command-line analysis |
| Data Analysis | Analyze data or extract insights |
| Data Visualization | Charts, graphs, dashboards |

### complexity_levels
| Value | Description |
|-------|-------------|
| trivial | Single line or obvious change |
| low | 1-2 files, minimal code changes |
| medium | 3-10 files, editing related code |
| high | Cross-cutting concerns, many searches/edits, architectural |

### intent_types
| Value | Description |
|-------|-------------|
| Plan | Planning a feature or approach |
| Ask | Understanding codebase, asking questions |
| Task Automation | Delegating git, lint, build tasks |
| Write Code | Actual code changes |

### subcategories
Architecture, Security, Data/Database, DevOps/Deployment, UI/Styling, API Integration, Performance, Testing, Documentation, Configuration, Code Review, Learning

### user_guidance_levels
| Value | Description |
|-------|-------------|
| high | Specific file paths, function names, line numbers, acceptance criteria |
| medium | General directions, named features, approximate scope |
| low | Vague/reactive requests like "fix this" or "not working" |
