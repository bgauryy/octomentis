# 03 — Preferences, RLHF, and agentic RL

## After SFT: “helpful” isn’t enough

SFT teaches format and imitation. Preference / RL stages teach **what good looks like** when many answers are fluent:

- safer, more honest, better style  
- higher win-rate vs baselines  
- for agents: **actually solve tasks** (tests pass, tools used correctly)

---

## Preference learning (offline)

Collect pairs: same prompt, answer A vs B, human or judge picks winner.

Methods (conceptual):

| Method | Idea |
|--------|------|
| **Reward model (RM)** | train a model to score answers; then RL against it |
| **DPO / IPO / …** | skip explicit RL; optimize policy directly from pairs |
| **ORPO / KTO** | variants with different data assumptions |

You still need careful data: biased judges → biased models.

---

## Online RL (PPO and friends)

Loop:

1. Policy generates completions (rollouts)  
2. Reward model / verifier scores them  
3. Update policy to increase expected reward (with KL penalty to stay near SFT ref)

**PPO** is classic. Newer recipes (GRPO, RLOO, …) simplify the critic setup for LLMs.

**KL penalty** stops the model from drifting into reward-hacking gibberish.

---

## Verifiable rewards (math, code)

When you can check correctness automatically:

- unit tests, compilers, math checkers  
- reward = pass/fail (+ partial credit)

This powers much of modern “reasoning” post-training — and **coding agents**.

Danger: **reward hacking** — agent finds shortcuts (read the answer key, curl GitHub solutions). Labs add anti-hack filters (GLM-5.2 blog describes rule + LLM-judge online guards).

---

## Agentic RL

Not single-turn chat: multi-step tool use, long trajectories, environments.

Needs:

- rollout infrastructure (sandboxes, tools, timeouts)  
- trajectory handling (compaction, credit assignment)  
- scalable trainers  

**slime** ([THUDM/slime](https://github.com/THUDM/slime), [docs](https://thudm.github.io/slime/)) is Zhipu/THUDM’s open RL post-training framework used for GLM-scale agentic RL / OPD-style merging of experts ([GLM-5.2 blog](https://huggingface.co/blog/zai-org/glm-52-blog)).

---

## What you should practice first

1. SFT + LoRA on a clean dataset  
2. Simple preference pairs + DPO (small model)  
3. Only then: verifiable RL on math/code with a harness  

Jumping straight to agentic RL without eval hygiene wastes money.

> **Tutor note:** Skip this whole chapter until your first LoRA SFT succeeds. Alignment without a working SFT loop wastes time.

---

## Check yourself

1. SFT vs DPO vs PPO — one sentence each.  
2. What is reward hacking?  
3. Why KL to a reference model?


## Do this now

1. Read [TRL DPO Trainer](https://huggingface.co/docs/trl/dpo_trainer) quick start.
2. Skim [Philschmid DPO walkthrough](https://www.philschmid.de/dpo-align-llms-in-2024-with-trl) — run only after one SFT works.

## Tutorials

- [TRL DPO](https://huggingface.co/docs/trl/dpo_trainer) · [DPO with TRL (2024)](https://www.philschmid.de/dpo-align-llms-in-2024-with-trl)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`04-glm-52-case-study.md`](./04-glm-52-case-study.md)

## Sources

- [InstructGPT / RLHF (arXiv:2203.02155)](https://arxiv.org/abs/2203.02155)
- [DPO (arXiv:2305.18290)](https://arxiv.org/abs/2305.18290)
- [HF TRL — DPO Trainer](https://huggingface.co/docs/trl/dpo_trainer)
- [THUDM/slime](https://github.com/THUDM/slime) (agentic RL infra)
