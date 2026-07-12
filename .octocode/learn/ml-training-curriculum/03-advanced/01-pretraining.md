# 01 — Pretraining (making a base model)

## Goal

Learn general language / code / world structure by predicting the next token on a huge corpus.

```
maximize  Σ  log P_θ(token_t | token_<t)
```

Equivalent: minimize cross-entropy / perplexity.

You are **compressing** the training distribution into parameters θ.

---

## Data at pretrain scale

- Web text, books, code, math, synthetic data  
- Heavy **filtering**, dedup, PII/toxicity handling, quality classifiers  
- Mixture ratios matter (code %, math %, …)  
- Packing documents into sequences with **attention / loss masks** so unrelated docs don’t leak into each other (see [`../04-data/03-packing-and-masks.md`](../04-data/03-packing-and-masks.md))  


This stage is where “digest data” is industrial: petabyte pipelines, not a CSV.

See [`../04-data/`](../04-data/) for the *principles* that still apply at small scale.

---

## Compute recipe (conceptual)

Pick:

- model size (layers, width, heads, MoE)  
- context length schedule (e.g. 4k → 32k → 128k mid-train)  
- tokens to train (trillions)  
- batch tokens, LR warmup/decay, precision (BF16/FP8)  
- parallelism: data / tensor / pipeline / expert  

**Scaling laws** guide the tradeoff: bigger model vs more tokens vs more compute.

---

## Mid-training / long-context extension

After main pretrain, many labs continue training on longer sequences and domain mixtures (coding agents, tools). GLM-5.2 expanded **1M-context** training for coding-agent trajectories ([HF blog](https://huggingface.co/blog/zai-org/glm-52-blog)).

---

## What you get

A **base checkpoint**: strong at completion, not necessarily a good assistant.

Next stages specialize it: SFT → preference/RL.

---

## Can you pretrain at home?

| Scale | Feasible? |
|-------|-----------|
| Tiny LM (millions of params) on niche data | yes, educational |
| 1–7B from scratch well | expensive but possible for labs |
| 70B+ / MoE frontier | no for individuals |

**Practical path:** download open base/instruct weights; invest effort in **data + fine-tune + eval**.

---

## Check yourself

1. What objective does pretraining optimize?  
2. Why is data filtering as important as architecture?  
3. What is mid-training for?


## Do this now

1. Watch [Let’s reproduce GPT-2](https://www.youtube.com/watch?v=l8pRSuU81PU) (or first 30 min).
2. Browse [build-nanogpt](https://github.com/karpathy/build-nanogpt) commit history.

## Tutorials

- [Reproduce GPT-2 video](https://www.youtube.com/watch?v=l8pRSuU81PU) · [build-nanogpt](https://github.com/karpathy/build-nanogpt) · [HF LM task](https://huggingface.co/docs/transformers/tasks/language_modeling)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

Read data first if you haven’t: [`../04-data/01-digesting-data.md`](../04-data/01-digesting-data.md) · Then [`05-best-practices-training.md`](./05-best-practices-training.md) · [`02-finetuning-lora.md`](./02-finetuning-lora.md)

## Sources

- [Chinchilla scaling (arXiv:2203.15556)](https://arxiv.org/abs/2203.15556)
- [HF — Causal language modeling](https://huggingface.co/docs/transformers/tasks/language_modeling)
- [The Pile (arXiv:2101.00027)](https://arxiv.org/abs/2101.00027)
