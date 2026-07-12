# ML Training Curriculum — Beginner → Advanced

**Goal:** go from “what is machine learning?” to being able to **digest data, train, and fine-tune models** — including how frontier open models like **GLM-5.2** are built and adapted.

**Audience:** builders who want intuition + a practical path, not a pure math textbook.

---

## How to use (students)

1. Follow the **Learning path** table below (folder numbers are historical — **Data is stage 3**, Advanced is stage 4).  
2. **Numbered lessons** (`01-…`, `02-…`) end with **Do this now**, **Check yourself**, **Next**, **Tutorials**, **Sources**. Grade yourself with [`05-practice/ANSWERS.md`](./05-practice/ANSWERS.md).  
3. **Practice helpers** (checklists, tool map, reading path, ANSWERS, RESOURCES, TUTORIALS hub) are reference docs — they may omit Check yourself.  
4. Jargon: [`GLOSSARY.md`](./GLOSSARY.md) (A–Z).  
5. **First LoRA without getting lost:** [`05-practice/00-first-lora-path.md`](./05-practice/00-first-lora-path.md).

**Practical hub:** [`05-practice/TUTORIALS.md`](./05-practice/TUTORIALS.md) · smoke run: [`05-practice/05-hands-on-first-lora.md`](./05-practice/05-hands-on-first-lora.md).

**Student readiness:** [`05-practice/STUDENT-EVAL.md`](./05-practice/STUDENT-EVAL.md).

---

## Learning path (recommended order)

| Stage | Folder | You will understand |
|-------|--------|---------------------|
| **1. Beginner** | [`01-beginner/`](./01-beginner/) | ML, distributions, loss/gradients, **tokens + VRAM** |
| **2. Intermediate** | [`02-intermediate/`](./02-intermediate/) | Nets, **attention** (intro + deep), **Transformers** (intro + deep) |
| **3. Data** | [`04-data/`](./04-data/) | Digest, **normalize/clean**, **synthetic data**, **flows**, packing, eval |
| **4. Advanced** | [`03-advanced/`](./03-advanced/) | Pretrain → SFT/LoRA → RLHF; **best practices**; **coding models**; GLM-5.2 |
| **5. Practice** | [`05-practice/`](./05-practice/) | **First-LoRA path**, hands-on, checklists, **TUTORIALS**, ANSWERS, RESOURCES |

> Do **not** browse folders by number alone: `03-advanced` comes **after** `04-data` in the path. Data before Advanced so SFT assumes real dataset hygiene.

---

## Mental model (keep this)

```
Data  →  Model (parameters θ)  →  Predictions (often a distribution)
              ↑
         Loss / Reward
              ↑
         Optimizer (SGD, Adam, …)
```

For language models:

```
Raw text/code  →  Tokens  →  Transformer (attention)  →  Next-token distribution
                                                              ↓
                              Pretrain → SFT → Preference/RL → Deploy / Fine-tune again
```

---

## Quick map

| Topic | Primary doc |
|-------|-------------|
| How ML works | [`01-beginner/01-what-is-ml.md`](./01-beginner/01-what-is-ml.md) |
| Tokens / VRAM / logits | [`01-beginner/04-tokens-and-gpu-basics.md`](./01-beginner/04-tokens-and-gpu-basics.md) |
| Distributions | [`01-beginner/02-distributions.md`](./01-beginner/02-distributions.md) |
| Attention (intro) | [`02-intermediate/02-attention.md`](./02-intermediate/02-attention.md) |
| Attention (deep) | [`02-intermediate/05-attention-deep-dive.md`](./02-intermediate/05-attention-deep-dive.md) |
| How Transformers work | [`02-intermediate/04-transformers-deep-dive.md`](./02-intermediate/04-transformers-deep-dive.md) |
| Packing & masks | [`04-data/03-packing-and-masks.md`](./04-data/03-packing-and-masks.md) |
| Normalize & clean | [`04-data/05-normalize-and-clean.md`](./04-data/05-normalize-and-clean.md) |
| Synthetic data | [`04-data/06-synthetic-data.md`](./04-data/06-synthetic-data.md) |
| Data flows map | [`04-data/07-end-to-end-data-flows.md`](./04-data/07-end-to-end-data-flows.md) |
| Evaluation | [`04-data/04-evaluation-literacy.md`](./04-data/04-evaluation-literacy.md) |
| Training BP | [`03-advanced/05-best-practices-training.md`](./03-advanced/05-best-practices-training.md) |
| Fine-tuning BP | [`03-advanced/06-best-practices-finetuning.md`](./03-advanced/06-best-practices-finetuning.md) |
| **Train a coding model** | [`03-advanced/07-coding-model-finetuning.md`](./03-advanced/07-coding-model-finetuning.md) |
| Coding FT checklist | [`05-practice/04-coding-finetune-checklist.md`](./05-practice/04-coding-finetune-checklist.md) |
| GLM-5.2 | [`03-advanced/04-glm-52-case-study.md`](./03-advanced/04-glm-52-case-study.md) |
| **First LoRA (ordered path)** | [`05-practice/00-first-lora-path.md`](./05-practice/00-first-lora-path.md) |
| **Tutorials (all sessions)** | [`05-practice/TUTORIALS.md`](./05-practice/TUTORIALS.md) |
| **First LoRA (hands-on)** | [`05-practice/05-hands-on-first-lora.md`](./05-practice/05-hands-on-first-lora.md) |
| Answer key | [`05-practice/ANSWERS.md`](./05-practice/ANSWERS.md) |
| All citations hub | [`05-practice/RESOURCES.md`](./05-practice/RESOURCES.md) |
| Glossary | [`GLOSSARY.md`](./GLOSSARY.md) |

---

## Honest scope

- **You can** fine-tune small/medium open models (LoRA/QLoRA) on a laptop/Colab.  
- **You cannot** pretrain GLM-5.2-class models at home — study the pipeline; practice on 3B–8B.  
- Numbered lessons cite known sources (d2l, Vaswani, Alammar, HF, Unsloth, Raschka, arXiv, …).

---

## Suggested pace

| Pace | Plan |
|------|------|
| **Fast** (1–2 weeks) | Beginner skim → [`00-first-lora-path.md`](./05-practice/00-first-lora-path.md) (smoke Colab → checklist → retrain with your JSONL) |
| **Solid** (4–6 weeks) | Full beginner + intermediate deep dives + data + one SFT |
| **Deep** (2–3 months) | + **coding FT** + RLHF/GLM + eval harness + [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) |

### Intermediate order (follow Next links)

1. [`00-from-rnn-to-attention.md`](./02-intermediate/00-from-rnn-to-attention.md)  
2. [`01-neural-nets.md`](./02-intermediate/01-neural-nets.md)  
3. [`02-attention.md`](./02-intermediate/02-attention.md)  
4. [`05-attention-deep-dive.md`](./02-intermediate/05-attention-deep-dive.md)  
5. [`04-transformers-deep-dive.md`](./02-intermediate/04-transformers-deep-dive.md)  
6. [`03-transformers.md`](./02-intermediate/03-transformers.md)  

Then: **`04-data/`** (Flow A) → **`03-advanced/`** → **`05-practice/`**.

### Data Flow A (linear)

[`01-digesting-data`](./04-data/01-digesting-data.md) → skim [`07` flows](./04-data/07-end-to-end-data-flows.md) → [`05-normalize`](./04-data/05-normalize-and-clean.md) → [`02-datasets`](./04-data/02-datasets-for-finetuning.md) → [`03-packing`](./04-data/03-packing-and-masks.md) → [`04-eval`](./04-data/04-evaluation-literacy.md) → train.

Start: [`01-beginner/01-what-is-ml.md`](./01-beginner/01-what-is-ml.md)
