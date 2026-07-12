# 01 — Digesting data (from raw → training-ready)

## The real bottleneck

For most fine-tunes, **data quality** beats fancy optimizers.

“Digesting data” means turning messy logs, docs, tickets, and code into **consistent (prompt, completion)** examples the model can imitate — then **filtering** hard.

---

## Pipeline

```
Raw sources
  → Extract / parse
  → Normalize (encoding, PII, format)
  → Filter (quality, toxicity, license, leakage)
  → Transform to schema (chat messages / plain text)
  → Dedup + decontaminate vs eval
  → Split train/val
  → Pack / tokenize (**with masks** — see [`03-packing-and-masks.md`](./03-packing-and-masks.md))
  → Train
```

Packing without sample-boundary attention + loss masks can silently mix unrelated examples. Treat packing as a **masking** problem, not just concatenation.

---

## Schemas you’ll use

### Causal LM (pretrain-style)

```json
{"text": ".... long document ...."}
```

### Chat SFT

```json
{
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

### Preference

```json
{
  "prompt": "...",
  "chosen": "...",
  "rejected": "..."
}
```

Always apply the target model’s **chat template** when tokenizing.

---

## Quality filters (practical)

| Filter | Why |
|--------|-----|
| Length bounds | drop empty / insane walls of text |
| Language ID | keep intended languages |
| Exact + near dedup | stop memorization / overweighting |
| PII scrub | secrets, emails, keys |
| License / ToS | don’t train on forbidden data |
| Heuristic quality | reject boilerplate, spam |
| **Eval decontam** | remove examples overlapping your test set |

For code: compile/parse checks, license headers, remove secrets (gitleaks-style).

---

## Synthetic data

Short version: generate with a teacher/self loop, then **critique + verify + filter**. Full chapter: [`06-synthetic-data.md`](./06-synthetic-data.md).

Normalize/clean details: [`05-normalize-and-clean.md`](./05-normalize-and-clean.md). Flow map: [`07-end-to-end-data-flows.md`](./07-end-to-end-data-flows.md).

---

## How much data?

| Goal | Rough ballpark |
|------|----------------|
| Style / format adapt | hundreds–few thousand **great** examples |
| New domain QA | thousands–tens of thousands |
| Competitive specialist | 50k+ carefully curated + mix of general |
| Pretrain | billions–trillions of tokens |

Start tiny, measure, grow. 500 perfect > 50,000 mediocre.

---

## Leakage and contamination

If train contains eval problems (or GitHub solutions to your benchmark), metrics lie.

Hold out early. Hash prompts. For agent tasks, sandbox without answer keys (see GLM anti-hack lesson).

---

## Check yourself

1. List 5 stages of a data digest pipeline.  
2. Why decontaminate against eval?  
3. When is synthetic data safe to use?


## Do this now

1. Follow [HF Datasets quickstart](https://huggingface.co/docs/datasets/quickstart) — load any dataset and print 3 rows.
2. Write 10 gold `messages` JSONL lines for a task you care about.

## Tutorials

- [HF Datasets quickstart](https://huggingface.co/docs/datasets/quickstart) · [LIMA](https://arxiv.org/abs/2305.11206)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

**Flow A order (follow this):** skim [`07-end-to-end-data-flows.md`](./07-end-to-end-data-flows.md) (Flow A + decision tree) → [`05-normalize-and-clean.md`](./05-normalize-and-clean.md) → [`02-datasets-for-finetuning.md`](./02-datasets-for-finetuning.md) → [`03-packing-and-masks.md`](./03-packing-and-masks.md) → [`04-evaluation-literacy.md`](./04-evaluation-literacy.md) → train. Add [`06-synthetic-data.md`](./06-synthetic-data.md) only when you need Flow B.

## Sources

- [LIMA (arXiv:2305.11206)](https://arxiv.org/abs/2305.11206) — quality over quantity
- [HF Datasets](https://huggingface.co/docs/datasets/index)
- [Deduplicating training data (arXiv:2107.06499)](https://arxiv.org/abs/2107.06499)
- [NVIDIA LLM data preprocessing](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/)
- [Eugene Yan — Synthetic data](https://eugeneyan.com/writing/synthetic/)
