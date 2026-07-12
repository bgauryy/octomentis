# Resources: Homeostatic Awareness Loop

This appendix keeps the deeper research out of default agent briefings while preserving enough context for future design work.

## 2026-07-08 Deep Research Verdict

Four subagent lanes converged on the same decision: prototype the Homeostatic Awareness Loop, but add retrieval/compression and trust/provenance gates before building more storage. Biology gives the metabolism metaphor, AI-agent work gives the reflection loop, ML retrieval work gives the context-control warning, and product prior art says Octocode's wedge is repo-scoped operational awareness rather than a generic memory database or external task board.

A later pass on creativity, vision, motivation, personality, resources, and collective intelligence adds a bounded drive layer. Awareness should not pretend to be one permanent agent. It should help many agents share vision, learning gaps, resource leads, creative alternatives, operating norms, and a transactive map of who or what knows what.

## Local Awareness Resources

| Resource | Use it for | Key point |
|---|---|---|
| `packages/octocode-awareness/skills/octocode-awareness/SKILL.md` | Agent operating instructions | Start with workspace status, recall, refinements, signals, then verify/reflect/project |
| `packages/octocode-awareness/skills/octocode-awareness/references/full-flow.md` | Whole awareness loop | One SQLite store, many surfaces; attend/claim/learn/verify/reflect/project/housekeep |
| `packages/octocode-awareness/skills/octocode-awareness/references/data-model.md` | Schema semantics | Memories, tasks, locks, signals, refinements, edit logs, harness logs have different jobs |
| `packages/octocode-awareness/skills/octocode-awareness/references/repo-context-management.md` | Wiki/projection policy | `.octocode` is generated repo context, not the canonical DB |
| `.octocode/MEMORY_NAVIGATION.md` | Product direction | Prototype deterministic navigation before topic tracks, new schemas, or raw conversation storage |
| `packages/octocode-awareness/src/repo-context.ts` | Query/projection code | Existing views, formats, profile/activity rows, CSV/HTML/inject machinery |
| `packages/octocode-awareness/src/maintenance.ts` | Digest/sleep code | Existing cleanup covers expired memories, old superseded rows, locks, refinements, FTS |
| `packages/octocode-awareness/src/memory.ts` | Consolidation code | Novelty and similar-memory IDs already exist for advisory consolidation |

## Brain and Nature Resources

| Domain | Source | Design lesson for awareness |
|---|---|---|
| Prediction error | [Schultz, Dayan, Montague, Science 1997](https://pubmed.ncbi.nlm.nih.gov/9054347/) | Learning is driven by changes/errors in expected outcomes. Product rule: failed checks, user corrections, and recall misses feed reflection. |
| Motor adaptation | [Shadmehr, Smith, Krakauer, Annual Review of Neuroscience 2010](https://www.annualreviews.org/content/journals/10.1146/annurev-neuro-060909-153135) | Forward models stay calibrated through sensory prediction errors. Product rule: agents should verify and update their plan, not just record success. |
| Synaptic tagging | [Frey and Morris, Nature 1997](https://doi.org/10.1038/385533a0) | Local tags let useful plasticity persist. Product rule: candidate memories need evidence refs, scope, and temporary review state before promotion. |
| Microglial pruning | [Schafer et al., Neuron 2012](https://pubmed.ncbi.nlm.nih.gov/22632727/) | Microglia prune in an activity- and complement-dependent way. Product rule: stale, weak, duplicate, or unsafe links get tagged for review. |
| Complement tagging | [Stevens et al., Cell 2007](https://pubmed.ncbi.nlm.nih.gov/18083105/) | Complement can tag unwanted synapses for elimination. Product rule: supersession and trust tags are safer than silent deletion. |
| Forgetting mechanism | [Wang et al., Science 2020](https://pubmed.ncbi.nlm.nih.gov/32029629/) | Forgetting can involve complement-dependent synaptic elimination. Product rule: forgetting is active memory hygiene, not failure. |
| Glymphatic cleanup | [Xie et al., Science 2013](https://pubmed.ncbi.nlm.nih.gov/24136970/) and [NIH 2024 human glymphatic report](https://www.nih.gov/news-events/nih-research-matters/brain-waste-clearance-system-shown-people-first-time) | Sleep supports metabolic cleanup and waste clearance. Product rule: digest should drain stale operational waste and refresh projections. |
| Brain-immune border | [Louveau et al., Nature 2015](https://pubmed.ncbi.nlm.nih.gov/26030524/) | CNS lymphatic vessels carry fluid and immune cells from CSF. Product rule: awareness needs scoped boundary surfaces between local repo state and global memory. |
| Neuroimmune physiology | [Immune cells and CNS physiology, JEM 2019](https://rupress.org/jem/article/216/1/60/42423/Immune-cells-and-CNS-physiology-Microglia-and) | Immune activity supports surveillance, damage response, and cognition but must be bounded. Product rule: trust gates should protect policy and durable memory. |
| Hippocampal replay | [Wilson & McNaughton, Science 1994](https://doi.org/10.1126/science.8036517) | Replay recent experience before promoting durable state. Product rule: sleep reviews work traces, failures, and changed files. |
| Sleep consolidation | [Diekelmann & Born, Nature Reviews Neuroscience 2010](https://doi.org/10.1038/nrn2762) | Consolidation reorganizes memories. Product rule: digest merges/supersedes/refactors awareness rows while preserving IDs. |
| Active forgetting | [Langille, Frontiers 2019](https://doi.org/10.3389/fncel.2019.00071) | Forgetting complements learning. Product rule: stale or low-value rows become review/prune candidates. |
| Synaptic homeostasis | [Tononi & Cirelli, Neuron 2014](https://doi.org/10.1016/j.neuron.2013.12.025) | Capacity is protected by downscaling. Product rule: projections have budgets and drill-down links. |
| Active inference and homeostasis | [The Free Energy Principle for Perception and Action](https://pmc.ncbi.nlm.nih.gov/articles/PMC8871280/) | Agents should select actions from a model of past experience and preferred future state. Product rule: `attend` should route before action. |
| Sleep consolidation and forgetting | [Remembering to Forget](https://www.frontiersin.org/journals/cellular-neuroscience/articles/10.3389/fncel.2019.00071/full) | Consolidation and forgetting are coupled. Product rule: reflection without pruning is half a loop. |
| Synaptic homeostasis | [Linking Network Activity to Synaptic Plasticity during Sleep](https://www.frontiersin.org/journals/neural-circuits/articles/10.3389/fncir.2017.00061/full) | Capacity is protected by downscaling after waking learning. Product rule: projections need budgets and downsampling. |
| Human sleep synchrony | [Augmenting hippocampal-prefrontal neuronal synchrony during sleep enhances memory consolidation in humans](https://www.nature.com/articles/s41593-023-01324-5) | Timing and coordination matter during consolidation. Product rule: sleep/digest should run after meaningful capture, not randomly during edits. |
| Hippocampal replay | [A model of hippocampal replay driven by experience and environmental structure facilitates spatial learning](https://elifesciences.org/articles/82301) | Replay should respect structure and changed environments. Product rule: navigation trace must record why evidence was selected and where it may be stale. |
| Adaptive cycle / panarchy | [Panarchy: ripples of a boundary concept](https://ecologyandsociety.org/vol27/iss3/art21/) and [Adaptive Cycle](https://www.resalliance.org/adaptive-cycle) | Systems alternate growth/conservation with release/reorganization. Product rule: split capture from consolidation/prune/project. |
| Stigmergy and coordination traces | [Active Inferants](https://www.frontiersin.org/journals/behavioral-neuroscience/articles/10.3389/fnbeh.2021.647732/full) and [Self-Organization and Stigmergy](https://link.springer.com/rwe/10.1007/978-3-030-28102-1_179) | Local traces coordinate agents without central micromanagement. Product rule: locks, signals, tasks, and projections are traces, not authority. |
| Autophagy / metabolism | [Autophagy: mechanisms, roles in human diseases, and therapeutic perspectives](https://www.frontiersin.org/journals/cell-and-developmental-biology/articles/10.3389/fcell.2026.1776289/full) | Healthy systems recycle damaged or unnecessary components. Product rule: digest should turn stale/superseded state into smaller reusable signals. |

## Creativity, Drive, and Collective Intelligence Resources

| Domain | Source | Design lesson for awareness |
|---|---|---|
| Creative cognition | [Default and Executive Network Coupling Supports Creative Idea Production](https://www.nature.com/articles/srep10964) | Creativity is not just random divergence. It couples spontaneous memory/simulation with executive filtering. Product rule: `attend` may suggest alternatives, but verification and constraints select. |
| Vision / goals | [Locke and Latham, goal-setting theory](https://pubmed.ncbi.nlm.nih.gov/12237980/) | Goals organize action through mechanisms, moderators, incentives, and limits. Product rule: `drive_state.goal` should be explicit, scoped, and tied to acceptance criteria. |
| Self-determination | [Deci and Ryan, Self-Determination Theory](https://selfdeterminationtheory.org/SDT/documents/2000_DeciRyan_PIWhatWhy.pdf) | Growth-supporting contexts satisfy autonomy, competence, and relatedness. Product rule: agents need bounded choices, feedback, and handoff context, not only commands. |
| Intrinsic motivation / curiosity | [Kaplan and Oudeyer, intrinsic motivation](https://www.frontiersin.org/journals/neuroscience/articles/10.3389/neuro.01.1.1.017.2007/full) | Curiosity can follow expected learning progress, especially reducible prediction error. Product rule: gaps become `next_probe` only when probing can improve the task. |
| Growth mindset | [A national experiment reveals where a growth mindset improves achievement](https://www.nature.com/articles/s41586-019-1466-y) | Improvement loops work best when challenge, strategy change, help seeking, and peer norms align. Product rule: reflections should turn failures into better strategy, not blame. |
| Collective intelligence | [Woolley et al., Science 2010](https://ofew.berkeley.edu/sites/default/files/evidence_for_a_collective_intelligence_factor_in_the_performance_of_human_groups_woolley_et_al.pdf) | Group intelligence is a property of interaction, not just individual capability. Product rule: signals/refinements should improve turn-taking, handoff clarity, and shared sensitivity. |
| Team personality | [Peeters et al., team personality meta-analysis](https://research.utwente.nl/en/publications/personality-and-team-performance-a-meta-analysis/) | Team-level traits can affect performance, but composition and variance matter. Product rule: encode team norms/temperament, not a single agent personality. |
| Information foraging | [Pirolli and Card, Information Foraging](https://act-r.psy.cmu.edu/wordpress/wp-content/uploads/2012/12/280uir-1999-05-pirolli.pdf) | Information seeking optimizes value gained per cost under attention limits. Product rule: resource leads need why-useful, cost/freshness, and task fit. |
| Transactive memory | [Wegner, Transactive Memory](https://dtg.sites.fas.harvard.edu/DANWEGNER/pub/Wegner%20Transactive%20Memory.pdf) and [Argote and Ren, transactive memory systems](https://carlsonschool.umn.edu/sites/carlsonschool.umn.edu/files/2018-10/ArgoteRen-JMS-TransactiveMemory-2012.pdf) | Groups remember through individual stores plus communication about who knows what. Product rule: awareness identity is the corpus plus traces connecting agents, sources, and claims. |

## Awareness Organ Vocabulary

| Organ cue | Agent-facing phrase | Concrete surface |
|---|---|---|
| Senses | "What is the workspace state?" | `workspace status`, `repo-profile`, `docs staleness` |
| Attention | "What matters now?" | future `attend`; recall/refinement/signal packet today |
| Memory | "What should survive this run?" | `memory record`, `reflect record`, evidence refs |
| Error signal | "What did reality correct?" | failed tests, `verify audit`, user feedback |
| Vision | "What future state are we steering toward?" | current request, plan/RFC/KPI, active refinements |
| Curiosity / drive | "Which uncertainty can we reduce now?" | gaps, recall misses, `next_probe`, learning progress |
| Imagination | "What alternatives are worth testing?" | brainstorm options, prior art, resource leads |
| Team temperament | "What norms guide this run?" | source skill policy, repo guidance, scorecard routes |
| Transactive map | "Who or what knows this?" | source refs, memory IDs, agent IDs, signals, refinements |
| Immune pruning | "What should be tagged, superseded, or distrusted?" | trust gate, novelty, `memory forget --dry-run` |
| Sleep cleanup | "What should be replayed and drained?" | `maintenance digest --dry-run`, future sleep report |
| Corpus bridge | "Who else needs the trace?" | `signal`, `refinement`, locks |
| Projection | "What should future agents see first?" | Markdown, CSV, HTML, manifest caps |

## AI, ML, and Product Resources

| Domain | Source | Design lesson for awareness |
|---|---|---|
| Retrieval-augmented generation | [Lewis et al., 2020](https://arxiv.org/abs/2005.11401) | Keep mutable knowledge outside model/context with provenance and update paths. |
| Retrieval at scale | [RETRO, 2021](https://arxiv.org/abs/2112.04426) | Explicit retrieval can substitute for brute-force context/model scale. |
| Episodic inference memory | [Memorizing Transformers, 2022](https://arxiv.org/abs/2203.08913) | Recent traces and durable lessons should be retrieved differently. |
| Long-term model memory | [LongMem, 2023](https://arxiv.org/abs/2306.07174) | Use layered stores rather than a single giant prompt. |
| Retrieval evaluation | [BEIR, 2021](https://arxiv.org/abs/2104.08663) | BM25/lexical is a robust baseline; semantic recall should be optional and measured. |
| Long-context failure | [Lost in the Middle, 2024](https://aclanthology.org/2024.tacl-1.9/) | Do not dump long awareness context; rank, trim, and place critical items deliberately. |
| Retrieval hurts | [Yoran et al., 2023](https://arxiv.org/html/2310.01558v1) | Irrelevant retrieval can reduce quality. Product rule: recall must abstain and expose why-selected notes. |
| Agent reflection loop | [Generative Agents, 2023](https://arxiv.org/abs/2304.03442) and [Reflexion, 2023](https://arxiv.org/abs/2303.11366) | Raw episodes should feed reflection and planning only through feedback-grounded summaries. |
| Tiered agent memory | [MemGPT, 2023](https://arxiv.org/abs/2310.08560) and [CoALA, 2023](https://arxiv.org/abs/2309.02427) | Separate semantic facts, episodic traces, procedural knowledge, and working context. |
| Memory risk | [Self-correction limits, 2023](https://arxiv.org/abs/2310.01798), [memory poisoning, 2026](https://arxiv.org/abs/2606.04329), and [Unit 42 memory poisoning writeup](https://unit42.paloaltonetworks.com/indirect-prompt-injection-poisons-ai-longterm-memory/) | Reflections and persistent memory need verification, trust boundaries, and scoped writes. |
| Product prior art | [mem0](https://github.com/mem0ai/mem0), [Letta](https://github.com/letta-ai/letta), [Graphiti](https://github.com/getzep/graphiti), [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence) | Generic memory/checkpointing is crowded. Octocode should focus on repo-scoped evidence, verification debt, handoffs, and projections. |

## Awareness Surface Routing

| User/agent need | Best surface | Avoid |
|---|---|---|
| Start work | `attend` or current checklist: `workspace status`, `memory recall`, `refinement get`, `signal list` | Reading every generated doc |
| Search/filter/sort rows | `query <view> --format csv|json|table`, `.octocode/awareness/csv/*.csv`, HTML view | Hand-editing CSV |
| Human wiki snapshot | `repo inject --mode local` | Treating `.octocode/MEMORY.md` as the DB |
| Durable lesson | `memory record` / `reflect record` with evidence refs | Routine status memories |
| Candidate durable lesson | trust/provenance gate, similar-memory recall, verification refs | Directly promoting raw chat, generated wiki, or unverified external text |
| Know where to learn next | `drive_state.resource_leads`, `RESOURCES.md`, local docs, source refs | Dumping full papers or docs into startup context |
| Explore alternatives | `drive_state.alternatives` plus RFC option comparison | Treating brainstorming as a decision |
| Preserve collective identity | source skill norms, signals, refinements, transactive map | Storing one fictional agent personality |
| Follow-up backlog | `refinement set|get` | Overloading task rows |
| Active edit coordination | `lock acquire|release`, `verify audit|mark` | Manual Kanban state |
| Inter-agent note | `signal publish|reply|ack|resolve` | Adding transient messages to long docs |
| Cleanup/review | `maintenance digest --dry-run`, future sleep report, docs staleness | Silent deletion |

## Promotion Rules

| Candidate | Promote to memory/wiki when | Keep out when |
|---|---|---|
| Gotcha | Reusable failure mode with file/command/evidence ref | One-off annoyance with no reuse |
| Lesson | Changes future behavior or plan choice | Mere status update |
| Decision | Chooses among alternatives with reason | Temporary preference |
| Reflection | Has outcome, judgment, failure signature, or eval evidence | Pure diary entry |
| Task | Verification obligation or audit trail | Product backlog item without edit/verify connection |
| Refinement | Durable follow-up or handoff | Immediate to-do already being executed |
| Signal | Needs agent/human routing | General FYI better summarized elsewhere |

## Projection Budget Policy

| Projection | Keep | Move to rows/details |
|---|---|---|
| `.octocode/AGENTS.md` | Current instructions, top risks, projection health, links | Full memory/task/refinement lists |
| `.octocode/MEMORY.md` | Highest-value active memories and consolidation warnings | Full memory rows |
| `.octocode/GOTCHAS.md` | Top gotchas by importance/relevance | Long history of every failure |
| `.octocode/LEARN.md` | Decisions, architecture notes, opportunities | Raw reflection text |
| `.octocode/references/*.md` | Compact stable reference notes | Research dumps |
| `.octocode/awareness/csv/*.csv` | Generated sortable/filterable rows | Source-of-truth edits |
| `.octocode/awareness/index.html` | Browse/search/filter current projection | Live DB freshness guarantee |

## Open Research Hooks

- Compare `attend` traces against real agent sessions: which surfaces were useful, which were noise, and which facts were missing?
- Measure memory promotion precision: how often did a projected lesson help a later task?
- Measure recall misses: which misses are lexical vocabulary issues and which require semantic retrieval?
- Audit task grouping: how many hook-generated task rows collapse into meaningful verification clusters?
- Track projection freshness: how often are generated docs older than the memory/refinement state agents need?
- Measure resource lead utility: how often did a suggested article/doc/source reduce uncertainty or change the implementation plan?
- Measure collective identity drift: do agents preserve evidence-first, bounded, cooperative norms without repeating personality lore?
