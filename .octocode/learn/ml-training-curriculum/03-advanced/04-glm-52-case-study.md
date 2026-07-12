# 04 — Case study: GLM-5.2 (how a frontier open model is trained)

Sources (fetched / cited):

- Model card: [huggingface.co/zai-org/GLM-5.2](https://huggingface.co/zai-org/GLM-5.2)  
- Blog: [GLM-5.2: Built for Long-Horizon Tasks](https://huggingface.co/blog/zai-org/glm-52-blog) (2026-06-17)  
- Tech report: [arXiv:2602.15763](https://arxiv.org/abs/2602.15763)  
- RL framework: [THUDM/slime](https://github.com/THUDM/slime)

---

## What it is

- Flagship **open-weight** model from Z.AI / zai-org  
- **~753B parameters** (model card), **MIT** license  
- Focus: **long-horizon** coding / agentic work with a solid **1M-token** context  
- Effort levels (e.g. High / Max) trade compute for quality at inference  

This is **not** a “fine-tune on your laptop” base. It is the **reference architecture + post-training story** you study to understand the full stack.

---

## Map onto the curriculum

| Stage | GLM-5.2 angle |
|-------|----------------|
| Pretrain + mid-train | Long-context training for coding-agent trajectories; IndexShare sparse attention for 1M context |
| Architecture | IndexShare: one indexer shared across every 4 sparse-attention layers → fewer FLOPs at long context; MTP improvements for speculative decoding |
| Post-train RL | **slime** for agentic RL; critic-based PPO for long/compacted trajectories; anti-hack module for coding rewards |
| Distill / merge | Parallel **OPD** training merging many expert models into one (~2 days claimed in blog for that phase) |
| Serve | vLLM, SGLang, Transformers, Unsloth (inference), etc. — see model card |

---

## Architecture ideas worth stealing (conceptually)

### IndexShare (DSA)

Sparse attention needs an **indexer** to pick which tokens to attend to. Sharing one indexer across 4 layers cuts indexer cost on 3/4 of layers — important when `n = 1M`.

Lesson: at extreme context, **attention engineering** matters as much as “more layers.”

### MTP + speculative decoding

Multi-Token Prediction draft heads; IndexShare/KVShare + rejection sampling + TV loss → higher acceptance length (~+20% in their ablation).

Lesson: training and inference co-design (draft model must match serve-time KV behavior).

---

## Agentic RL lessons

From the blog:

1. Long trajectories + compaction → prefer **token-level critic / single-rollout** formulations over naive group comparisons.  
2. Coding rewards are hackable → **online** detect+block bad tool calls, continue rollout (don’t always kill the whole episode).  
3. Infrastructure (**slime**) is part of the model quality story — rollouts, PD disaggregation, FP8 KV, etc.

---

## What *you* can do with GLM-5.2

| Action | Realistic? |
|--------|------------|
| Call via API / Coding Plan | yes |
| Run quantized / served weights on serious hardware | yes (org-scale GPUs) |
| LoRA on full 753B | generally impractical for individuals |
| Study card + blog + slime examples; apply recipes to **7B–32B** open models | **best learning path** |
| Fine-tune smaller GLM-family or other open models with Unsloth/TRL | yes |

HF lists adapters/finetunes under the model tree — community experiments exist; treat them as leads, verify quality.

---

## Takeaway recipe (portable)

```
Strong pretrain
  → long-context mid-train on real agent traces
  → SFT on high-quality instruction/agent data
  → verifiable + preference RL with anti-hack
  → serve with long-context-optimized engine
```

Your personal version replaces industrial RL with: **clean SFT + eval harness + maybe DPO**.

---

## Check yourself

1. Why is 1M context an infrastructure problem, not just a training flag?  
2. What problem does anti-hack address in coding RL?  
3. What should an individual practice instead of training 753B?


## Do this now

1. Skim [GLM-5.2 model card](https://huggingface.co/zai-org/GLM-5.2) (serve + license).
2. Read [GLM-5.2 blog](https://huggingface.co/blog/zai-org/glm-52-blog) sections on IndexShare + slime.
3. Optional: [slime docs](https://thudm.github.io/slime/).

## Tutorials

- [Model card](https://huggingface.co/zai-org/GLM-5.2) · [Blog](https://huggingface.co/blog/zai-org/glm-52-blog) · [slime](https://thudm.github.io/slime/)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

If you skipped data: [`../04-data/`](../04-data/) · Else eval: [`../04-data/04-evaluation-literacy.md`](../04-data/04-evaluation-literacy.md) · Practice: [`../05-practice/01-first-finetune-checklist.md`](../05-practice/01-first-finetune-checklist.md)

## Sources

- [zai-org/GLM-5.2 model card](https://huggingface.co/zai-org/GLM-5.2)
- [GLM-5.2 blog](https://huggingface.co/blog/zai-org/glm-52-blog)
- [arXiv:2602.15763](https://arxiv.org/abs/2602.15763)
- [THUDM/slime](https://github.com/THUDM/slime)
