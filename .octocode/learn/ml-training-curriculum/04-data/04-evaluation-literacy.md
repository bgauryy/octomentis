# 03 — Evaluation literacy (what “good” means)

Loss going down ≠ model ready to ship. This chapter defines common metrics.

---

## Language-modeling metrics

| Metric | Meaning | Caveat |
|--------|---------|--------|
| **Cross-entropy / NLL** | Average `−log P(true token)` | Depends on tokenizer & mask |
| **Perplexity** | `exp(average NLL)` | Lower better; **not comparable** across different vocabs/templates |

Absolute loss bands (e.g. “0.5–1.0”) are **rough vibes only** — compare runs with the **same** data, template, and mask.

---

## Task metrics

| Metric | Use |
|--------|------|
| **Exact match / EM** | Short answers, extraction |
| **F1** | Partial credit on spans |
| **pass@k** | Code: fraction of problems with ≥1 correct sample in k tries |
| **Win rate** | Blind A/B vs baseline (human or judge model) |
| **Schema / unit tests** | Structured output & tools — often best product metric |

**Best practice:** define metric **Z** before collecting SFT data ([`02-datasets-for-finetuning.md`](./02-datasets-for-finetuning.md)).

---

## Harnesses

- [EleutherAI lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) — academic suites (MMLU, etc.)  
- Custom: your unit tests + 20–50 held-out prompts  

Watch **contamination**: if train data overlaps eval, scores lie ([`01-digesting-data.md`](./01-digesting-data.md)).

---

## Regression suite

After every fine-tune, re-run:

1. Your task metric Z  
2. A few **general** chat prompts  
3. Any **safety / format** cases you care about  

Niche SFT can raise Z and wreck general behavior (forgetting).

---

## Check yourself

1. Why can’t you compare perplexity across two different tokenizers?  
2. When is pass@k the right metric?  
3. What is a regression suite for?


## Do this now

1. Clone [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) and run one tiny task from the README.
2. For code: skim [EvalPlus](https://github.com/evalplus/evalplus) README and run HumanEval+ once if you have generations.

## Tutorials

- [lm-eval](https://github.com/EleutherAI/lm-evaluation-harness) · [EvalPlus](https://github.com/evalplus/evalplus)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

**Flow A done → train:** [`../05-practice/00-first-lora-path.md`](../05-practice/00-first-lora-path.md) · [`../03-advanced/02-finetuning-lora.md`](../03-advanced/02-finetuning-lora.md)  
Map / other flows: [`07-end-to-end-data-flows.md`](./07-end-to-end-data-flows.md)

## Sources

- [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness)  
- [Lessons on reproducible LM eval (arXiv:2405.14782)](https://arxiv.org/abs/2405.14782)  
- [HF Evaluate](https://huggingface.co/docs/evaluate/index)
