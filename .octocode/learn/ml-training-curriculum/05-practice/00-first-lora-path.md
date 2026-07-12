# First LoRA — one ordered path (students)

Follow **this page** when you want a first fine-tune without getting lost in Next links.

```
1. Skim theory (optional but useful)
2. Minimal data (your JSONL)
3. Smoke-train on Colab
4. Checklist + best practices
5. Serious retrain with clean data
```

---

## Step 0 — Open these tabs

| Tab | Link |
|-----|------|
| Tutorials hub | [`TUTORIALS.md`](./TUTORIALS.md) |
| Hands-on run | [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md) |
| Glossary | [`../GLOSSARY.md`](../GLOSSARY.md) |

---

## Step 1 — Tiny theory (≤2 hours)

1. [`../01-beginner/01-what-is-ml.md`](../01-beginner/01-what-is-ml.md)  
2. [`../01-beginner/04-tokens-and-gpu-basics.md`](../01-beginner/04-tokens-and-gpu-basics.md)  
3. Optional: [Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) first hour  

Skip deep attention for the **smoke** run; come back later.

---

## Step 2 — Minimal data (before serious FT)

1. Write **20–50** chat rows → [`../04-data/02-datasets-for-finetuning.md`](../04-data/02-datasets-for-finetuning.md)  
2. Run `apply_chat_template` once ([HF chat templating](https://huggingface.co/docs/transformers/chat_templating))  
3. Hold out **5** prompts never used in train  

For a **Colab smoke test**, the notebook’s default dataset is OK — then redo with *your* JSONL.

---

## Step 3 — Smoke LoRA (prove the pipeline)

→ [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md) Option A (Unsloth) or B (HF).

**Done when:** loss didn’t NaN, inference cell runs, adapter saved.

---

## Step 4 — Checklist + best practices

1. [`01-first-finetune-checklist.md`](./01-first-finetune-checklist.md)  
2. Skim [`../03-advanced/06-best-practices-finetuning.md`](../03-advanced/06-best-practices-finetuning.md)  
3. Optional: [`../04-data/05-normalize-and-clean.md`](../04-data/05-normalize-and-clean.md) fast path  

---

## Step 5 — Serious retrain

1. Clean/normalize your data ([`../04-data/01-digesting-data.md`](../04-data/01-digesting-data.md) Flow A)  
2. Packing/masks if needed ([`../04-data/03-packing-and-masks.md`](../04-data/03-packing-and-masks.md))  
3. Retrain 1 epoch with your JSONL  
4. Eval holdouts ([`../04-data/04-evaluation-literacy.md`](../04-data/04-evaluation-literacy.md))  

---

## Full curriculum (after first LoRA)

`README.md` path: Beginner → Intermediate → Data → Advanced → Practice.

Student eval notes: [`STUDENT-EVAL.md`](./STUDENT-EVAL.md)
