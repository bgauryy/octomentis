# Resources: Scheduled Connector Ingestion for Octocode Awareness

## Primary Sources
| Resource | Link or path | Why it matters |
|---|---|---|
| OpenWiki Brains announcement | https://www.langchain.com/blog/introducing-openwiki-brains-general-purpose-wiki-memory-for-agents | The "proactive, connector-fed, scheduled" framing this RFC responds to |
| Pi JSON event stream mode docs | `node_modules/@earendil-works/pi-coding-agent/docs/json.md` | Confirms `pi --mode json` non-interactive invocation contract |

## Local Code References
| Area | File and lines | Decision relevance |
|---|---|---|
| No existing scheduler | repo-wide search `cron\|setInterval\|scheduler\|daemon` under `packages/` — 0 matches | Confirms net-new capability, no conflict to resolve |
| Memory schema state constraint | `packages/octocode-awareness/src/db-schema.ts:34` | Forces the "no new state value" design choice |
| Nullable workspace scope | `packages/octocode-awareness/src/db-schema.ts:38` | Confirms cross-workspace memory was already possible if ever needed |
| MemoryReview computed lane + tag convention | `packages/octocode-awareness/src/repo-workboard.ts:147-157` | Direct template for the new `unattended_write` reason |
| DDL-as-contract rule | `packages/octocode-awareness/docs/DB.md:84-86` | Constrains Phase 1 to code-only, non-schema |
| No-daemon invariant | `packages/octocode-awareness/docs/THESIS.md:78,82-83` | Directly shapes Option A vs. B in Rationale |
| Coordination/memory vs. external-research boundary | `packages/octocode-awareness/docs/HOW_IT_WORKS.md:127-129` | Confirms ingestion belongs outside Awareness itself |
| Secrets policy | `packages/octocode-awareness/AGENTS.md:39-40` | Constrains credential handling to `@octocodeai/config`, never Awareness rows |
| Harness-apply gate pattern | `packages/octocode-awareness/docs/HARNESS.md:76-78` | Template for the new `OCTOCODE_ALLOW_INGESTION` gate |
| In-process memory tools retired; CLI is the write path | `packages/octocode-pi-extension/src/index.ts:619-624` | Confirms ingestion writes go through `bash` + Awareness CLI, guided by the bundled skill |
| `octocode-agent`'s reserved-subcommand router | `packages/octocode-agent/bin/launcher.mjs:163-176` (`parseInvocation`) | Exact plug point Phase 4 extends — same shape as `update`/`update core` |
| `octocode-agent` launch machinery reused unchanged | `packages/octocode-agent/bin/launcher.mjs:252-286` (`buildPiArgs`, `launchAgent`) | Phase 4 forwards through this, no new subprocess logic |
| `octocode-agent` is deliberately thin (no `src/`) | `packages/octocode-agent/package.json` | Confirms domain logic does not belong there |
| `pi-extension` owns all prompt/tool/skill/Awareness-bridge content | `packages/octocode-pi-extension/src/index.ts` | Confirms connector/prompt/state code belongs there, not a new package |
| `pi-extension` has zero dependency on `octocode-agent` (standalone invariant) | `packages/octocode-pi-extension/package.json` dependencies list | Confirmed baseline the standalone guardrail test protects |
| `resolvePromptMode`'s option > env > default precedence | `packages/octocode-pi-extension/src/prompt.ts:45-51` | Template for the new ingestion-mode resolution |
| `PiContext.mode` documented field | `packages/octocode-pi-extension/src/types.ts:170` | Lets the extension recognize a headless run without any env var |
| Pi headless subprocess launch pattern | `packages/octocode-agent/docs/PI_INTEGRATION.md:33-58,135-180` | Confirms agent-runner design is a thin reuse, not new orchestration |
| "No divergent code path" standalone claim | `packages/octocode-agent/docs/PI_INTEGRATION.md:46-47` | Direct textual source for the standalone invariant |
| Existing web-search connector code | `skills/octocode-brainstorming/scripts/{serper,tavily,exa}-search.mjs`, `lib/web-search-common.mjs` | First connector = import, not build |
| Generic token loading | `packages/octocode-config/src/tokens/envTokens.ts` | Credential path for the web-search connector |
| Unrelated same-word prior RFC | `.octocode/rfc/RFC-octocode-ingest.md` | Different concept (local SQLite code-graph for OQL) — no overlap, noted to avoid name confusion |

## Prior Art and Related Systems
| Resource | Link | Lesson for this RFC |
|---|---|---|
| OpenWiki Brains | (see Primary Sources) | Retrieval (full-text/semantic/MCP) is still "exploring" on their side per the blog itself — this RFC doesn't need to compete there, only close the scheduling/ingestion gap |

## Internal Research Artifacts
| Artifact | Path | What it supports |
|---|---|---|
| Prior chat: Awareness vs. OpenWiki Brains rating, then package-placement correction | this conversation thread | Origin of the identified gap and the two design revisions (no new package; standalone invariant) captured in this RFC |

## Open Research Leads
- Whether `pi --mode json` has any undocumented TTY requirement — not decision-grade until Phase 0
  spike runs; currently a doc-and-type-level claim.
- Real-world review-lane throughput (how fast humans/agents actually clear `MemoryReview`) — no
  current baseline exists; KPI.md target of "≥80% within 7 days" is a proposed target, not a
  measured one.

## Reproducible Search Prompts
- `cron|setInterval|scheduler|daemon` over `packages/` — surfaced zero scheduling infra (grep, this session)
- `connector|gmail|notion|twitter|hacker news|scheduled|cron` over `packages/octocode-awareness` — surfaced zero connector/scheduling code (grep, this session)
- `OCTOCODE_AGENT\b|octocode-agent` over `packages/octocode-pi-extension/src` — surfaced only comment-level references, confirming zero real coupling (grep, this session)
