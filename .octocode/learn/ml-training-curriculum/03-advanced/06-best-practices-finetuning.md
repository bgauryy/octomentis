# Best practices — fine-tuning models (SFT / LoRA / QLoRA)

Evidence-backed habits for adapting pretrained LLMs. Complements [`02-finetuning-lora.md`](./02-finetuning-lora.md).

Primary sources:

- [Sebastian Raschka — Practical Tips for Finetuning LLMs Using LoRA](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms) (2023; still the clearest experiment writeup)  
- [Unsloth — Fine-tuning LLMs Guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide)  
- [Unsloth — LoRA Hyperparameters Guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide)  
- [HF TRL SFT](https://huggingface.co/docs/trl/sft_trainer) · [PEFT integration](https://huggingface.co/docs/trl/peft_integration)

---

## 0. When to fine-tune (and when not)

| Do fine-tune | Don’t (yet) |
|--------------|-------------|
| Stable format / tone / domain you need repeatedly | One-off question → prompt or RAG first |
| Model fails a measurable task you can label | You have &lt;20 noisy examples and no metric |
| You need weight-level skill (coding style, tools) | You only need fresh facts → retrieval often better |

**Best practice:** write metric **Z** before collecting data. No Z → no FT.

---

## 1. Data beats hyperparameters

From Raschka + LIMA-style results: **1k curated ≫ 50k mediocre synthetic**.

| Practice | Detail |
|----------|--------|
| Quality bar | Every example should be something you’d ship |
| Cover tasks you care about | Missing a skill in SFT data → model can “forget” how to follow it (Raschka arithmetic observation) |
| Chat template match | Train exactly as you serve |
| Assistant-only loss | Don’t train on user tokens |
| Hold out early | Val + fresh prompts never seen in train |
| Decontaminate | No eval leakage |

Dumping raw docs can help **code** continued-pretrain; for chat assistants, prefer **structured Q/A or multi-turn**.

---

## 2. Method ladder (don’t skip rungs)

```
Prompt / RAG
  → QLoRA SFT (cheapest serious FT)
  → LoRA 16-bit SFT
  → Full FT (rare)
  → DPO / ORPO
  → Online RL (verifiers)
```

Unsloth rule of thumb: **if LoRA/QLoRA can’t learn it, full FT usually won’t magically fix it** — fix data first.

QLoRA: ~⅓ less VRAM, slower wall-clock (Raschka ~33% mem save / ~39% slower) — worth it on memory-bound GPUs.

---

## 3. LoRA hyperparameter defaults that work

| Knob | Practical start | Notes |
|------|-----------------|-------|
| **Rank `r`** | 8–32 (try 16) | Higher for diverse/hard tasks; too high → overfit |
| **Alpha** | `r` or **`2 × r`** | Classic heuristic; Raschka & Unsloth both endorse trying `2r` |
| **Target modules** | **All major linears**: `q,k,v,o` + MLP `gate,up,down` | Q/V-only is weaker; all-layers helped a lot in Raschka |
| **Dropout** | 0–0.05 | Unsloth often uses 0 for speed; raise if overfit |
| **Bias** | `"none"` | Faster, little gain from training bias |
| **LR (LoRA/QLoRA)** | **`2e-4`** start | Unsloth default band `2e-4` … `5e-6` |
| **LR (RL / DPO)** | **`5e-6`** order | Much lower than SFT |
| **LR (full FT)** | Lower than LoRA | Easy to destroy the base |
| **Epochs** | **1–3** | Raschka: 2× passes on Alpaca/LIMA **hurt** — overfit |
| **Weight decay** | ~0.01 | Don’t overdo |
| **Warmup** | 5–10% of steps | Stabilizes |
| **Scheduler** | linear or cosine | Fine; AdamW less sensitive than SGD |
| **Effective batch** | **~16** common target | `batch × grad_accum` (e.g. 2×8) |
| **Seed** | fixed (e.g. 3407) | Compare runs fairly |

**rsLoRA / LoftQ:** advanced; try after defaults fail.

---

## 4. Effective batch size without OOM

```
effective_batch = per_device_batch × grad_accumulation × num_gpus
```

Same effective batch ⇒ similar updates; **small micro-batch + high accum** saves VRAM (slightly slower). Prefer that over OOM.

Watch: some stacks historically made `batch` vs `accum` **not** equivalent (Unsloth documents fixes) — validate loss curves if you switch.

---

## 5. Sequence length & memory

- Set `max_seq_length` to what your **data actually needs**, not the model max.  
- Longer sequences dominate VRAM (attention + activations).  
- Raschka: jumping max length ~1.3k → 2k raised memory ~18GB → ~27GB in one setup.  
- Pack short examples when possible; don’t pad a whole batch to rare outliers without packing.

---

## 6. Fight overfitting (FT-specific)

| Lever | Action |
|-------|--------|
| Epochs | Prefer 1; stop if val rises |
| Rank | Lower `r` |
| Data | More diverse / more gold examples |
| Mix | Blend general instruction data with niche |
| WD / dropout | Mild increase |
| Early stop | On val loss or task metric |

**Catastrophic forgetting:** narrow SFT without mix → great on niche, dumb elsewhere. Keep a general slice or shorter train.

---

## 7. Eval like a product, not a leaderboard tourist

1. **Automatic:** schema validity, unit tests, exact-match where fair.  
2. **Held-out prompts:** 20–50 human-scored.  
3. **Regression suite:** general chat + safety cases you care about.  
4. **Blind A/B:** base vs tuned (shuffle labels).  

A falling train loss that stays in a “reasonable” range (Unsloth often cites ~0.5–1.0 as a *vibe check*) only means learning is happening — **absolute CE is not comparable** across tokenizers, templates, or loss masks. **Task metrics decide ship**.

---

## 8. Train / serve consistency

- Same **chat template** and tokenizer fixes.  
- Prefer **train precision ≈ serve precision** when you care about 4-bit deploy (Unsloth guidance).  
- Save **adapter** + optionally **merge** for single-file serve.  
- Multiple LoRAs can be stored separately or merged (Raschka Q9) — test combined quality.

---

## 9. Experiment hygiene

1. Change **one** major knob per run (data *or* `r` *or* LR).  
2. Log: data hash, template, `r`, alpha, targets, LR, epochs, effective batch, seed, commit.  
3. Keep a “best so far” adapter; don’t overwrite blindly.  
4. Smoke inference on 5 prompts before overnight jobs.

---

## 10. Anti-patterns

| Anti-pattern | Do instead |
|--------------|------------|
| Full FT first | QLoRA/LoRA first |
| 10 epochs on 500 rows | 1 epoch + more data |
| Only `q_proj`/`v_proj` forever | Target all major linears |
| Ignore template | Verify encode→decode |
| Optimize only train loss | Hold-out + task eval |
| Synthetic data, no verify | Tests / schema / human spot-check |
| Fine-tune 70B+ before 8B works | Prove recipe on small model |
| RL before clean SFT | SFT → prefs → RL |

---

## 11. One-page starter recipe

```text
Model:      3B–8B instruct (or Unsloth 4-bit)
Method:     QLoRA
r / alpha:  16 / 32
Targets:    q,k,v,o + gate,up,down
LR:         2e-4, warmup 5–10%, cosine/linear
Epochs:     1 (check val; maybe 2)
Eff. batch: 16
Loss:       assistant tokens only
Data:       500–5k gold chat examples + small general mix
Eval:       30 held-out + 10 regression prompts
```

Then scale data and `r` only if metrics demand it.

---

## Check yourself

1. Why is `alpha ≈ 2r` a common default?  
2. Why can a second epoch hurt SFT?  
3. Name three anti-patterns.


## Do this now

1. Skim [Unsloth LoRA hyperparams](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide).
2. Skim [Raschka LoRA tips](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms) takeaways list.
3. Apply one change to your next run (e.g. target all linears, or 1 epoch only).

## Tutorials

- [Unsloth hyperparams](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide) · [Raschka LoRA](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

Coding models: [`07-coding-model-finetuning.md`](./07-coding-model-finetuning.md) · Eval: [`../04-data/04-evaluation-literacy.md`](../04-data/04-evaluation-literacy.md) · Practice: [`../05-practice/01-first-finetune-checklist.md`](../05-practice/01-first-finetune-checklist.md) · [`04-glm-52-case-study.md`](./04-glm-52-case-study.md)

## Sources

- [Unsloth LoRA hyperparameters](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide)
- [Raschka — Practical Tips for LoRA](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms)
- [HF TRL SFT](https://huggingface.co/docs/trl/sft_trainer) · [PEFT](https://huggingface.co/docs/trl/peft_integration)
