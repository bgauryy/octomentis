# Conversation Categorization — Full Taxonomy Schema

**Source:** `workbench.desktop.main.js` — `conversation_tags_categorization_prompt` Statsig config
**Version:** 1.3.1

## Task Categories
| Name | Description |
|------|-------------|
| Styling | UI/UX changes, CSS, theming, visual improvements |
| Refactoring | Restructure/clean up code without changing behavior |
| Testing | Write tests, improve test infra, fix test failures |
| Documentation | Comments, README updates, API docs |
| New Features | Add new functionality, endpoints, components |
| Bug Fixing & Debugging | Investigating or fixing bugs, errors, crashes |
| Code Review | Review code for issues or improvements |
| Performance | Optimize for speed, memory, efficiency |
| DevOps | CI/CD, deployment, Docker, Kubernetes |
| Infrastructure | Cloud infra, servers, networking |
| Configuration | Build setup, linting, environment config |
| Scripting | Scripts for specific/temporary tasks |
| Terminal Command | Shell commands or CLI operations |
| Data Analysis | Analyze data or extract insights |
| Data Visualization | Charts, graphs, visualizations |

## Complexity Levels
| Level | Description |
|-------|-------------|
| trivial | Single line or obvious change |
| low | 1-2 files, minimal code changes |
| medium | 3-10 files, editing related code |
| high | Cross-cutting concerns, many searches/edits, architectural |

## Intent Types
| Intent | Description |
|--------|-------------|
| Plan | Planning a feature/approach before implementation |
| Ask | Seeking to understand codebase or asking questions |
| Task Automation | Delegating tasks like git, lint, build |
| Write Code | Writing code and making actual changes |

## Subcategories
Architecture, Security, Data/Database, DevOps/Deployment, UI/Styling, API Integration, Performance, Testing, Documentation, Configuration, Code Review, Learning

## User Guidance Levels
| Level | Description |
|-------|-------------|
| high | Specific files/functions/lines, acceptance criteria, low ambiguity |
| medium | General direction with some specifics, some ambiguity |
| low | Vague/reactive requests, error-paste-fix, high ambiguity |

## Output Schema
```json
{
  "categories": ["array", "max 2 from task_categories"],
  "complexity": "single from complexity_levels",
  "intent": "single from intent_types",
  "subcategories": ["array", "max 2 from subcategories"],
  "userGuidanceLevel": "single from user_guidance_levels"
}
```
