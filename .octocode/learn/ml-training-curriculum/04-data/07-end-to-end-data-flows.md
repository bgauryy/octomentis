# 07 — End-to-end data flows (map)

How normalize, synthetic, packing, and train stages connect. Use this as a **routing map**.

> **If overwhelmed after [`01-digesting-data.md`](./01-digesting-data.md):** read **Flow A + Decision tree** here first, then [`05-normalize-and-clean.md`](./05-normalize-and-clean.md). Save Flow E (web pretrain) for later. Synthetic details = [`06-synthetic-data.md`](./06-synthetic-data.md) when you need Flow B.

---

## Flow A — Real data → SFT (most teams)

```
Raw sources
  → [`05-normalize-and-clean.md`](./05-normalize-and-clean.md)
  → Schema (chat JSON) — [`02-datasets-for-finetuning.md`](./02-datasets-for-finetuning.md)
  → [`03-packing-and-masks.md`](./03-packing-and-masks.md) + tokenize
  → SFT / LoRA ([`../03-advanced/02-finetuning-lora.md`](../03-advanced/02-finetuning-lora.md))
  → [`04-evaluation-literacy.md`](./04-evaluation-literacy.md)
```

Also: [`01-digesting-data.md`](./01-digesting-data.md).

---

## Flow B — Synthetic-augmented SFT

```
Human seeds (+ optional OSS snippets)
  → [`06-synthetic-data.md`](./06-synthetic-data.md) Generate (Self/Evol/OSS-Instruct)
  → Critique + Verify (tests/judge)
  → [`05-normalize-and-clean.md`](./05-normalize-and-clean.md) (yes, again)
  → Blend with real data
  → [`03-packing-and-masks.md`](./03-packing-and-masks.md) → SFT → Eval on HUMAN holdout
```

---

## Flow C — Code specialist

```
Code corpus / snippets
  → (optional) CPT + FIM
  → OSS-Instruct / OpenCodeInstruct-style **instruction data**
  → Execute tests filter (keep green / graded rows)
  → Decontam HumanEval/LiveCodeBench
  → QLoRA SFT → EvalPlus / internal CI
  → (later) verifiable RL + anti-hack
```

Filter **before** you train. Full path: [`../03-advanced/07-coding-model-finetuning.md`](../03-advanced/07-coding-model-finetuning.md). Beginners: finish Flow A first.

---

## Flow D — Preference / alignment data

```
Prompts (real or synth)
  → Sample 2+ completions
  → Rank (human / judge / tests)
  → chosen/rejected JSON
  → Normalize + dedupe ([`05-normalize-and-clean.md`](./05-normalize-and-clean.md))
  → DPO/ORPO ([`../03-advanced/03-rlhf-and-preferences.md`](../03-advanced/03-rlhf-and-preferences.md))
```

---

## Flow E — Pretrain / CPT web text

```
Common Crawl / internal dump
  → Extract
  → [`05-normalize-and-clean.md`](./05-normalize-and-clean.md) heuristics + dedup + quality (FineWeb-like)
  → Blend domains
  → Pack documents (masked)
  → Causal LM train
```

You rarely run E at home; still learn the **filter discipline**. Skip on first pass.

---

## Decision tree

```
Have labeled chat/code examples?
  YES → Flow A (add B if too few)
  NO  → Can you write 50 gold seeds?
          YES → Flow B
          NO  → Stop; collect gold first

Coding + tests available?
  YES → Flow C filters

Need style/safety ranking?
  YES → Flow D after SFT works
```

---

## Shared invariants (every flow)

1. **Version** dataset hashes.  
2. **Decontaminate** eval.  
3. **Mask** pads / user tokens / pack boundaries.  
4. **Eval** on real held-out tasks.  
5. **Don’t** skip PII/license gates.

---

## Check yourself

1. Which flow if you have 80 gold tickets and a strong teacher API?  
2. Why run normalize **after** synthetic generate?  
3. Name three invariants shared by all flows.


## Do this now

1. Pick Flow A or B for your project; write the stages on paper with your real paths.
2. Open the linked lesson for the **next** stage only (don’t open all flows).

## Tutorials

- Map lives in this file · Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

Train: [`../05-practice/00-first-lora-path.md`](../05-practice/00-first-lora-path.md) · [`../05-practice/01-first-finetune-checklist.md`](../05-practice/01-first-finetune-checklist.md) · BP: [`../03-advanced/06-best-practices-finetuning.md`](../03-advanced/06-best-practices-finetuning.md)

## Sources

- Flows synthesize: NVIDIA preprocessing, Yan synthetic guide, Magicoder/OpenCodeInstruct, FineWeb, this curriculum’s packing/eval chapters.
