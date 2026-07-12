# 06 — Synthetic data (generate → critique → filter)

How to **create** training examples with models — without poisoning yourself.

> **Skip until you need Flow B.** First do Flow A in [`07-end-to-end-data-flows.md`](./07-end-to-end-data-flows.md) and normalize real data in [`05-normalize-and-clean.md`](./05-normalize-and-clean.md).

Practitioner overview: [Eugene Yan — Synthetic data for finetuning](https://eugeneyan.com/writing/synthetic/). NVIDIA frames SDG as **Generate → Critique → Filter** ([data preprocessing blog](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/)).

---

## When synthetic helps

| Use | Example |
|-----|---------|
| Scale instructions cheaply | Self-Instruct / Evol / OSS-Instruct |
| Cover rare skills | Edge-case APIs, languages, formats |
| Preference pairs | Chosen/rejected from teacher or self |
| Privacy | Avoid shipping raw user logs |
| Textbook-quality pretrain shards | Phi “Textbooks Are All You Need” style |

**When not:** you have zero gold seeds and no verifier — you’ll amplify garbage.

---

## Two families

| Family | Idea | Risk |
|--------|------|------|
| **Distillation** | Strong **teacher** writes data for a weaker **student** | ToS / license of teacher API; teacher bias |
| **Self-improvement** | Model generates, filters, then trains on its own outputs | Error amplification; limited by starting ability |

Classic pair (Dec 2022): [Self-Instruct](https://arxiv.org/abs/2212.10560) (self-bootstrap) vs Unnatural Instructions (distill from stronger model) — see Yan’s writeup.

Respect **API ToS** when distilling commercial models.

---

## Core methods (know these names)

| Method | What it does | Cite |
|--------|--------------|------|
| **Self-Instruct** | Seed tasks → generate new instructions/IO → filter → SFT | [arXiv:2212.10560](https://arxiv.org/abs/2212.10560) |
| **Evol-Instruct** | Mutate instructions to be harder / more constrained | WizardLM / [WizardCoder](https://arxiv.org/abs/2306.08568) |
| **OSS-Instruct** | Seed = **real code snippets** → invent problem+solution | [Magicoder](https://arxiv.org/abs/2312.02120) |
| **Genetic-Instruct** | Combine Evol (mutation) + Self-Instruct (crossover) | Method inside [OpenCodeInstruct](https://arxiv.org/abs/2504.04030) |
| **Textbook-quality** | Curate/generate highly educational text (not raw web) | [Textbooks Are All You Need](https://arxiv.org/abs/2306.11644) |
| **Preference synth** | Sample 2 answers → rank with judge / constitution | DPO/RLHF data |

Coding-specific detail: [`../03-advanced/07-coding-model-finetuning.md`](../03-advanced/07-coding-model-finetuning.md).

---

## The only safe loop: Generate → Critique → Filter → (optional) Human

```
Seeds (human gold, OSS snippets, tickets)
    │
    ▼
GENERATE     teacher / self prompts → candidates
    │
    ▼
CRITIQUE     LLM-as-judge, rubrics, constitutions, pairwise rank
    │
    ▼
VERIFY       unit tests, schema, compilers, retrieval fact-check
    │
    ▼
FILTER       dedupe, decontam, PII, length, diversity caps
    │
    ▼
BLEND        mix with real human data (don’t go 100% synthetic blindly)
    │
    ▼
TRAIN        SFT / DPO / CPT
    │
    ▼
EVAL         held-out real tasks (not only synthetic self-tests)
```

**Synthetic without VERIFY = confident garbage.**

OpenCodeInstruct finding to remember: **unit tests / execution feedback** and **LLM judge** both help; judge alone beat execution-only filtering in their ablations — still **use both** when you can ([arXiv:2504.04030](https://arxiv.org/abs/2504.04030)).

---

## Seed design (most important knob)

| Seed type | Effect |
|-----------|--------|
| Tiny / narrow | Mode collapse — same tasks forever |
| Diverse human gold | Better coverage |
| Real artifacts (code, docs, tickets) | More realistic (OSS-Instruct lesson) |
| Algorithmic contest banks | Hard reasoning / code |

**Rule:** invest in seeds + filters more than in “generate 10M once.”

---

## Diversity & collapse

- Cap near-duplicates (embedding / n-gram).  
- Mix seed sources; periodically inject fresh human examples.  
- Track **task-type histogram** — if 80% is “write a sort function,” stop.  
- For Evol: limit evolution depth so instructions stay solvable.

---

## Preference / alignment synthetic data

1. Same prompt → sample A, B (temp > 0).  
2. Rank with stronger judge or rules (tests, constitutions).  
3. Emit `chosen` / `rejected` for DPO/ORPO.  
4. Spot-check judges — they are biased.

---

## Normalize after generate

Synthetic rows still go through [`05-normalize-and-clean.md`](./05-normalize-and-clean.md):

- schema fix, PII scrub, dedup, decontam  
- apply chat template only at tokenize time  
- version: `synth_v3__teacher_X__filter_Y`

---

## Anti-patterns

| Don’t | Do |
|-------|-----|
| Train on unfiltered teacher dumps | Critique + verify + filter |
| 100% synthetic forever | Keep a human gold core |
| Use bench problems as seeds | Decontaminate |
| One prompt template for all tasks | Diverse seeds / OSS-Instruct |
| Ignore ToS when distilling | Use allowed teachers / local models |

---

## Starter recipe (SFT)

```text
1. Write 50–200 human gold examples (your real task)
2. Generate 5×–50× with a strong local/allowed teacher
3. Auto-verify (tests/schema) + LLM rubric score
4. Keep top tier; dedupe; decontam
5. Blend ~20–40% human/gold-ish with synthetic
6. QLoRA 1 epoch; eval on held-out HUMAN prompts
```

---

## Check yourself

1. Distillation vs self-improvement — risk of each?  
2. Why is Generate→Critique→Filter the default loop?  
3. What makes a good seed set?


## Do this now

1. Read [Eugene Yan — Synthetic data](https://eugeneyan.com/writing/synthetic/) (Self-Instruct vs distillation sections).
2. Generate 20 synthetic Q&A from your 10 gold seeds with a local/allowed teacher; keep only verified ones.

## Tutorials

- [Yan synthetic guide](https://eugeneyan.com/writing/synthetic/) · [Self-Instruct repo](https://github.com/yizhongw/self-instruct)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`07-end-to-end-data-flows.md`](./07-end-to-end-data-flows.md) · coding synth: [`../03-advanced/07-coding-model-finetuning.md`](../03-advanced/07-coding-model-finetuning.md)

## Sources

- [Eugene Yan — Synthetic data for finetuning](https://eugeneyan.com/writing/synthetic/)  
- [Self-Instruct (arXiv:2212.10560)](https://arxiv.org/abs/2212.10560)  
- [Textbooks Are All You Need (arXiv:2306.11644)](https://arxiv.org/abs/2306.11644)  
- [Magicoder / OSS-Instruct](https://arxiv.org/abs/2312.02120) · [WizardCoder](https://arxiv.org/abs/2306.08568) · [OpenCodeInstruct](https://arxiv.org/abs/2504.04030)  
- [NVIDIA data preprocessing (SDG section)](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/)
