# 07 — How to train / fine-tune a **coding** model

Specialized path for code LLMs and coding agents. Assumes you already know SFT/LoRA ([`02-finetuning-lora.md`](./02-finetuning-lora.md), [`06-best-practices-finetuning.md`](./06-best-practices-finetuning.md)) and data hygiene ([`../04-data/`](../04-data/)).

---

## TL;DR pipeline (best current practice)

```
Pick a strong code-capable base (or general base)
    → (optional) Continued pretrain on your languages / repo
    → SFT on NL→code instructions (OSS-Instruct / Evol / OpenCodeInstruct-style)
    → Filter with tests + LLM judge; decontaminate vs HumanEval/MBPP/…
    → Eval with pass@k + harder suites (LiveCodeBench, BigCodeBench, SWE-*)
    → (advanced) RL with verifiable rewards (unit tests / SWE harness) + anti-hack
```

**Individuals:** skip full CPT and agentic RL first. Do **QLoRA SFT** on a clean, test-backed instruction set.

---

## 1. What “coding model” means (pick your job)

| Goal | Train for | Primary metrics |
|------|-----------|-----------------|
| **Completion / IDE** | FIM + next-token on code | HumanEval-style, fill-in-middle probes |
| **Chat coding assistant** | NL→code SFT (instructions) | HumanEval+, MBPP+, LiveCodeBench |
| **Repo / agent engineer** | Long-context SFT + tool traces + RL | SWE-bench / Terminal-Bench / internal CI |
| **Private codebase expert** | CPT on repo + internal SFT | Internal tests, not public leaderboards |

Don’t mix goals blindly: a great HumanEval model can still fail multi-file SWE tasks.

---

## 2. Base model choice

| Prefer | Why |
|--------|-----|
| Code-specialized base/instruct (Qwen-Coder, DeepSeek-Coder, CodeLlama, StarCoder-class, …) | Already saw lots of code tokens |
| Strong general instruct (Llama/Qwen/…) | Fine if you bring **enough** code SFT |
| Match license to your product | Especially for proprietary fine-tunes |

Start **3B–8B** to prove the recipe; scale later.

---

## 3. Data techniques that actually work (evidence)

### A. OSS-Instruct (Magicoder) — `strong`

Seed = **real open-source snippets** → teacher LLM invents a **problem + solution** inspired by the snippet.

- Paper: [Magicoder / OSS-Instruct (arXiv:2312.02120)](https://arxiv.org/abs/2312.02120) · [ise-uiuc/magicoder](https://github.com/ise-uiuc/magicoder)  
- ~75K synthetic instructions; more realistic / less teacher-bias than Self-Instruct-from-21-seeds  
- **Orthogonal** to Evol-Instruct — Magicoder-S = OSS-Instruct **then** Evol data  
- Important negative result: finetuning on raw **comment↔function** pairs from GitHub **hurt** vs generating instructions from seeds  

**Practice:** if you have a private repo, sample snippets → generate (problem, solution, tests) with a strong teacher → verify tests → SFT.

### B. Code Evol-Instruct (WizardCoder) — `strong`

Take seed instructions and **evolve complexity** (constraints, edge cases, multi-step).

- [WizardCoder (arXiv:2306.08568)](https://arxiv.org/abs/2306.08568)  
- Great as a **second stage** after OSS-Instruct-style data  

### C. OpenCodeInstruct-scale SFT (NVIDIA, 2025) — `strong`

[OpenCodeInstruct (arXiv:2504.04030)](https://arxiv.org/abs/2504.04030): **5M** Python instruction samples with:

- question + solution  
- **unit tests** + **execution feedback**  
- **LLM quality judgments**  

Key ablations to steal:

| Finding | Implication |
|---------|-------------|
| ~**500k** samples already beat stock Llama3 / Qwen2.5-Coder instruct | You don’t need 5M to start |
| **LLM judge** filtered quality better than execution-only | Use both: tests for correctness, judge for usefulness/clarity |
| **Genetic-Instruct** (Evol + Self-Instruct) > either alone | Combine mutation + crossover |
| Larger / diverse **seeds** (Stack-V2 functions + TACO algos) help | Seed diversity > one tiny seed bank |
| **NL→code** format ≫ code→code (HumanEval-style) prompting for SFT | Train the way users ask |

### D. Continued pretrain (CPT) on code — `moderate` / situational

Raw code next-token (or **FIM**) on your languages/repo **before** chat SFT.

| Use CPT when | Skip CPT when |
|--------------|---------------|
| New language / heavy proprietary APIs | Base already strong on your stack |
| Completion / FIM product | You only need chat Q→code |

FIM (fill-in-the-middle) is a **pretrain/CPT** trick for IDE completion ([structure-aware FIM, arXiv:2506.00204](https://arxiv.org/abs/2506.00204)) — not a substitute for instruction SFT.

### E. Verifiable RL / agent RL — `strong` for frontier, advanced for you

After SFT: optimize **pass/fail** from unit tests or SWE harnesses (0/1 rewards). Labs (DeepSWE-style, GLM slime) show agents learn tool habits from pure verifiable RL — and also **reward-hack** (see [`04-glm-52-case-study.md`](./04-glm-52-case-study.md) anti-hack).

**You:** run SFT until pass@k is solid; only then toy with GRPO/PPO on sandboxed tests.

---

## 4. Code-specific SFT best practices

| Practice | Detail |
|----------|--------|
| **NL→code examples** | User states intent; assistant returns full solution (+ brief explanation if you want chat style) |
| **Attach tests when possible** | Even if loss is only on code, keep tests for **filtering** and **eval** |
| **Execute to filter** | Drop samples that fail their own tests (or mark for repair) |
| **Decontaminate** | Strip overlap with HumanEval, MBPP, LiveCodeBench, APPS, DS-1000, … |
| **Longer context** | Multi-file / traceback tasks need higher `max_seq_length` |
| **Packing** | Use proper masks ([`../04-data/03-packing-and-masks.md`](../04-data/03-packing-and-masks.md)) |
| **Assistant-only loss** | Same as chat SFT |
| **Mix general data** | Avoid catastrophic forgetting of normal chat |
| **License / secrets** | Scrub API keys; respect repo licenses for CPT |
| **Don’t dump raw repo as SFT** | Prefer instruction form; Magicoder showed naive comment–code SFT can regress |

Hyperparams: start from general LoRA defaults (`r=16–32`, `alpha=2r`, LR `2e-4`, 1–2 epochs) — code data is often longer, so watch VRAM / grad accum.

---

## 5. Evaluation (coding)

| Suite | What it stresses |
|-------|------------------|
| **HumanEval / HumanEval+** | Function synthesis; + = harder tests ([EvalPlus](https://github.com/evalplus/evalplus)) |
| **MBPP / MBPP+** | Short Python tasks |
| **LiveCodeBench** | Fresher competitive problems (less stale leakage) |
| **BigCodeBench** | More realistic / library-heavy |
| **MultiPL-E** | Multilingual |
| **SWE-bench / Terminal-Bench** | Agent / repo-level (hard) |
| **Your CI** | The only metric that matters for private code |

Report **pass@1** and **pass@k**. Never tune on the test set. Prefer LiveCodeBench-style freshness if you generate synthetic data near HumanEval.

See also [`../04-data/04-evaluation-literacy.md`](../04-data/04-evaluation-literacy.md).

---

## 6. Private / company codebase recipe

1. **Legal + scrub** — licenses, PII, secrets.  
2. **CPT (optional)** — pack modules with FIM or causal LM; decontam vs internal eval.  
3. **Build SFT** — real tickets / PR descriptions → patches; or OSS-Instruct-from-internal-snippets.  
4. **Require tests** — generate or reuse unit tests; keep only green (or graded) samples.  
5. **QLoRA SFT** on instruct checkpoint.  
6. **Eval** — held-out internal tasks + regression on general coding.  
7. **Ship adapter** — same chat template as serve.

RAG over the repo still helps for **facts**; FT helps for **style, APIs, and workflows**.

---

## 7. Starter recipe (individual, 1 GPU)

```text
Base:     Qwen2.5-Coder or similar 7B instruct (or base + more SFT)
Method:   QLoRA, r=16–32, alpha=2r, all major linears
Data:     5k–50k NL→code (Magicoder-OSS-Instruct-75K subset, OpenCodeInstruct sample,
          or your verified synthetic); + 10–20% general chat
Filter:   run tests where present; decontaminate public benches
Train:    1 epoch, LR 2e-4, eff. batch ~16, max_len 4k–8k if VRAM allows
Eval:     HumanEval+ / MBPP+ + 20 internal prompts with unit tests
Next:     add Evol-style hard set; only then consider test-based RL
```

Public seeds to study (check licenses):

- [ise-uiuc/Magicoder-OSS-Instruct-75K](https://huggingface.co/datasets/ise-uiuc/Magicoder-OSS-Instruct-75K)  
- OpenCodeInstruct (see paper / NVIDIA release notes for HF mirrors)  
- [mlabonne/llm-datasets](https://github.com/mlabonne/llm-datasets) (curated index — verify each set)

---

## 8. Anti-patterns (coding-specific)

| Don’t | Do instead |
|-------|------------|
| SFT on raw files with no instructions | NL→code or FIM CPT with clear objective |
| Trust synthetic code without running it | Execute tests / sandboxes |
| Optimize only HumanEval | Add LiveCodeBench / internal CI |
| Train on leaked bench solutions | Decontaminate |
| Jump to SWE-RL before SFT works | Prove pass@k first |
| Ignore anti-hack in agent RL | Block answer-key shortcuts (GLM lesson) |

---

## Check yourself

1. OSS-Instruct vs Evol-Instruct — what does each change?  
2. Why prefer NL→code over code→code for SFT?  
3. When is CPT on a private repo worth it?  
4. Name two evals beyond HumanEval.


## Do this now

1. Browse [Magicoder repo](https://github.com/ise-uiuc/magicoder) + [OSS-Instruct-75K](https://huggingface.co/datasets/ise-uiuc/Magicoder-OSS-Instruct-75K).
2. Install/run [EvalPlus](https://github.com/evalplus/evalplus) on a small model’s generations (follow README).
3. Optional: [StarCoder FT blog](https://rocm.blogs.amd.com/artificial-intelligence/starcoder-fine-tune/README.html).

## Tutorials

- [Magicoder](https://github.com/ise-uiuc/magicoder) · [EvalPlus](https://github.com/evalplus/evalplus) · coding checklist [`../05-practice/04-coding-finetune-checklist.md`](../05-practice/04-coding-finetune-checklist.md)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`../05-practice/04-coding-finetune-checklist.md`](../05-practice/04-coding-finetune-checklist.md) · [`06-best-practices-finetuning.md`](./06-best-practices-finetuning.md) · agent RL: [`03-rlhf-and-preferences.md`](./03-rlhf-and-preferences.md) + [`04-glm-52-case-study.md`](./04-glm-52-case-study.md)

## Sources

- [Magicoder / OSS-Instruct — arXiv:2312.02120](https://arxiv.org/abs/2312.02120) · [GitHub](https://github.com/ise-uiuc/magicoder)  
- [WizardCoder / Code Evol-Instruct — arXiv:2306.08568](https://arxiv.org/abs/2306.08568)  
- [OpenCodeInstruct — arXiv:2504.04030](https://arxiv.org/abs/2504.04030)  
- [EvalPlus](https://github.com/evalplus/evalplus) · [LiveCodeBench](https://livecodebench.github.io/) (project site)  
- [Structure-aware FIM — arXiv:2506.00204](https://arxiv.org/abs/2506.00204)  
- [Awesome RLVR](https://github.com/opendilab/awesome-RLVR) · GLM anti-hack: [GLM-5.2 blog](https://huggingface.co/blog/zai-org/glm-52-blog)  
- [mlabonne/llm-datasets](https://github.com/mlabonne/llm-datasets)  
- General FT: [Unsloth](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide) · [TRL SFT](https://huggingface.co/docs/trl/sft_trainer)
