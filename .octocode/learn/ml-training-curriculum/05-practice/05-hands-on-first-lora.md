# 05 — Hands-on: your first LoRA fine-tune (practical)

Goal: **finish one smoke fine-tune** this session (Colab or local GPU).

**If lost:** follow [`00-first-lora-path.md`](./00-first-lora-path.md) (theory → minimal data → this page → checklist).  
Theory: [`../03-advanced/02-finetuning-lora.md`](../03-advanced/02-finetuning-lora.md).

---

## Option A — Fastest (Unsloth Colab) ≈ 30–90 min

1. Open the catalog: [Unsloth notebooks](https://unsloth.ai/docs/get-started/unsloth-notebooks)  
2. Pick a **small instruct** model notebook (e.g. Llama-3.1/3.2 1B–8B or Qwen similar).  
3. Runtime → GPU. **Run all** once with the default dataset to prove the pipeline.  
4. Replace the dataset with **your** JSONL (see format below).  
5. Train 1 epoch.  
6. Run the notebook’s inference cells. Save the LoRA adapter.  

Guide: [Unsloth fine-tuning](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide) · [Beginners](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners)

---

## Option B — Hugging Face TRL ≈ 1–2 h

1. LoRA course notebook: [HF Colab — LoRA adapters](https://colab.research.google.com/github/huggingface/notebooks/blob/main/course/en/chapter11/section4.ipynb)  
2. Or clone TRL example: [sft_trl_lora_qlora.ipynb](https://github.com/huggingface/trl/blob/main/examples/notebooks/sft_trl_lora_qlora.ipynb)  
3. Docs while you edit: [SFT Trainer](https://huggingface.co/docs/trl/sft_trainer) · [PEFT](https://huggingface.co/docs/trl/peft_integration)

---

## Your data (minimum viable)

Create `train.jsonl` (20–100 lines is enough for a smoke test):

```json
{"messages":[{"role":"user","content":"Say hello in one short sentence."},{"role":"assistant","content":"Hello — glad you're here."}]}
{"messages":[{"role":"user","content":"What is 2+2?"},{"role":"assistant","content":"4"}]}
```

**Before training**, in a Python cell:

```python
from transformers import AutoTokenizer
tok = AutoTokenizer.from_pretrained("YOUR_MODEL")  # same as train
msgs = [{"role":"user","content":"Hi"},{"role":"assistant","content":"Hello!"}]
text = tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=False)
print(text)
print(tok(text)["input_ids"][:40])
```

Docs: [Chat templating](https://huggingface.co/docs/transformers/chat_templating)

Hold out 5 prompts you **never** train on. After FT, compare base vs tuned answers.

---

## Suggested knobs (smoke run)

| Knob | Start |
|------|-------|
| Method | QLoRA |
| r / alpha | 16 / 32 |
| LR | 2e-4 |
| Epochs | 1 |
| Max seq | 2048 (or lower if OOM) |
| Eff. batch | ~8–16 via grad accum |

If OOM: lower max seq, batch=1, raise `gradient_accumulation_steps`.

---

## Done when

- [ ] Train loss trended down (no NaN)  
- [ ] Inference cell runs  
- [ ] Adapter folder saved  
- [ ] 5 holdout prompts look better on *your* format (or you know why not)  
- [ ] You wrote 3 lines: data hash, model id, knobs used  

## Next

[`01-first-finetune-checklist.md`](./01-first-finetune-checklist.md) → [`../03-advanced/06-best-practices-finetuning.md`](../03-advanced/06-best-practices-finetuning.md) (serious retrain) · coding: [`04-coding-finetune-checklist.md`](./04-coding-finetune-checklist.md) · path: [`00-first-lora-path.md`](./00-first-lora-path.md)

## Tutorials

- [Unsloth notebooks](https://unsloth.ai/docs/get-started/unsloth-notebooks)  
- [HF LoRA Colab](https://colab.research.google.com/github/huggingface/notebooks/blob/main/course/en/chapter11/section4.ipynb)  
- [TRL SFT](https://huggingface.co/docs/trl/sft_trainer)  
- Full index: [`TUTORIALS.md`](./TUTORIALS.md)

## Sources

- [Unsloth fine-tuning guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide)  
- [Unsloth for beginners](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners)  
- [HF TRL SFT Trainer](https://huggingface.co/docs/trl/sft_trainer)  
- [HF chat templating](https://huggingface.co/docs/transformers/chat_templating)  
- [HF PEFT / LoRA](https://huggingface.co/docs/trl/peft_integration)
