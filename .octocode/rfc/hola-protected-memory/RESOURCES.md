# Resources: HOLA-Inspired Protected Memory

Appendix for `RFC.md` / `IMPLEMENTATION.md` / `KPI.md`. Decisive claims stay cited in those files; this inventory keeps the research trail reviewable.

## POC And MVP Resource Map

| Phase | What to read first | Why |
|---|---|---|
| Optional POC | HOLA paper (Primary Sources) + `memory.ts` scoring/novelty/recall anchors | Prove surprise-vs-recency ranking without UX |
| MVP | `attend.ts` result/orchestration + `MEMORY_NAVIGATION.md` + KPI fixtures | Ship explainable `protected_memory` surface |
| Post-MVP | TinyLFU / MemGPT / semantic embed path | Admission polish and optional semantic blend |
| Safety | Memory poisoning refs | Do not weaken trust/scope in v0 |

## Primary Sources

| Resource | Link | Why it matters |
| --- | --- | --- |
| HOLA arXiv HTML | https://arxiv.org/html/2607.02303v1 | Main source for surprise-selected auxiliary memory, Wikitext results, needle recall, and limitations. |
| HOLA PDF | https://arxiv.org/pdf/2607.02303 | User-provided source. Keep as the canonical paper artifact. |

## Local Code References

| Area | File and lines | Notes |
| --- | --- | --- |
| Current scoring constants | `packages/octocode-awareness/src/memory.ts:26` | Decay weights, BM25 normalization, relevance floor, salience floor, half-life defaults. |
| Similarity and decay | `packages/octocode-awareness/src/memory.ts:104` | `findSimilarMemories` / decay components for novelty analogs. |
| FTS / lexical search | `packages/octocode-awareness/src/memory.ts:288` | Candidate IDs, BM25, score computation. |
| Insert novelty | `packages/octocode-awareness/src/memory.ts:552` | Computes novelty from similar memories and stores refs/FTS. |
| Recall API | `packages/octocode-awareness/src/memory.ts:764` | Filters, hydration, explain path, sorting, access bumps. |
| Forget behavior | `packages/octocode-awareness/src/memory.ts:949` | Existing deletion semantics; protected memory must not bypass this. |
| Optional embeddings | `packages/octocode-awareness/src/memory.ts` (embed helpers near end of file) | Embedding storage and JS-scan semantic recall — post-MVP only. |
| Attend result shape | `packages/octocode-awareness/src/attend.ts:45` | Evidence, gaps, trace, trust warnings, drive state. |
| Attend orchestration | `packages/octocode-awareness/src/attend.ts:285` | Composes repo profile, workboard, recall, trace, warnings, and next action. |
| Memory schema | `packages/octocode-awareness/src/db.ts:262` | `memories` table fields available to protected ranking. |
| Memory refs | `packages/octocode-awareness/src/db.ts:474` | Provenance/reference table. |
| FTS table | `packages/octocode-awareness/src/db.ts:695` | SQLite FTS canonical search index. |
| Navigation docs | `packages/octocode-awareness/docs/MEMORY_NAVIGATION.md:1` | `attend` as read-only helper and current non-goals. |
| Recall tests | `packages/octocode-awareness/tests/memory-upgrades.test.ts:20` | Existing seeded recall and weak-pool tests (baseline 10 passing, 2026-07-10). |
| Scope tests | `packages/octocode-awareness/tests/memory.test.ts` | Exact ref/file/regex/asOf filtering and workspace isolation. |
| Recall CLI | `packages/octocode-awareness/bin/awareness.ts` (`memory recall` / `get-memory`) | Lexical-first recall CLI and optional semantic branch; `--protected` is post-MVP. |
| Package scripts | `packages/octocode-awareness/package.json` | Build, lint, test, self-test, verify commands. |
| This RFC packet | `.octocode/rfc/hola-protected-memory/` | Decision + plan + KPIs + this appendix. |
| Related trust RFC | `.octocode/rfc/awareness-operational-trust/RFC.md` | Dependency / sequencing note for v4 lossless-memory gate. |

## Prior Art And Related Systems

| Resource | Link | Use for this RFC |
| --- | --- | --- |
| LangGraph memory concepts | https://docs.langchain.com/oss/python/concepts/memory | Distinguishes short-term and long-term memory plus semantic, episodic, procedural types. |
| Letta archival memory | https://docs.letta.com/guides/core-concepts/memory/archival-memory/ | Example of searchable long-term archival memory surface. |
| Zep Memory docs | https://help.getzep.com/v2/memory | Product prior art for retrieval-oriented agent memory. |
| Zep paper | https://arxiv.org/abs/2501.13956 | Temporal knowledge-graph memory prior art. |
| Mem0 memory types | https://docs.mem0.ai/core-concepts/memory-types | Scope layering across conversation, session, user, and organization memory. |
| Generative Agents | https://arxiv.org/abs/2304.03442 | Memory stream, reflection, and retrieval scoring precedent. |
| MemGPT | https://arxiv.org/abs/2310.08560 | Explicit memory hierarchy and self-managed context precedent. |
| TinyLFU | https://arxiv.org/abs/1512.00727 | Admission-policy prior art: keep useful entries, not merely recent entries. |
| Caffeine W-TinyLFU | https://github.com/ben-manes/caffeine/wiki/Efficiency | Practical cache admission/eviction background. |
| Memory poisoning survey/example | https://arxiv.org/abs/2606.04329 | Safety reference for long-term agent memory. |
| Unit 42 memory poisoning write-up | https://unit42.paloaltonetworks.com/indirect-prompt-injection-poisons-ai-longterm-memory/ | Practical prompt-injection risk framing for memory systems. |

## Internal Research Artifacts

| Artifact | Path | Notes |
| --- | --- | --- |
| Brainstorming run ledger | `.octocode/brainstorming/runs/br_20260709071030_apply-hola-style-surprise-protected-memory-cache.json` | Earlier verdict: prototype first, 8/10 idea, derived read-only lane over existing awareness data. |
| Baseline attend smoke | Live CLI 2026-07-10 | `attend --query "protected memory recall baseline" --compact` OK; evidence recalled HOLA RFC memory. |
| Baseline unit slice | `tests/memory-upgrades.test.ts` | 10 passed before protected-memory implementation. |

## Open Research Leads

- Does HOLA's write-magnitude surprise map better to `novelty_score`, access correction history, failure signatures, or a new derived signal?
- Should protected-memory ranking eventually use semantic hits as candidates, or only as tie-breakers?
- Can cache-admission ideas like TinyLFU improve protected selection without making scoring opaque?
- What provenance and trust signals are strong enough to suppress a protected candidate rather than merely warn?
- Can memory poisoning tests be added without broadening the first implementation too much?

## Search Prompts

```text
HOLA linear attention auxiliary memory surprise cache arxiv 2607.02303
agent memory surprise novelty retrieval protected exact facts
long term agent memory poisoning indirect prompt injection
TinyLFU admission policy recency frequency cache
octocode-awareness memory novelty_score attend evidence trace
```
