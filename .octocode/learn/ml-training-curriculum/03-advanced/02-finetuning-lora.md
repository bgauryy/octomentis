# 02 — Fine-tuning: SFT, LoRA, QLoRA

## Why fine-tune?

Pretraining taught “language.” Fine-tuning teaches **your task / style / domain**:

- company tone, API formats, languages  
- coding conventions, tool-calling schemas  
- domain knowledge not emphasized in pretrain  

Often better than prompting alone when you have **consistent** examples and need reliability.

---

## Supervised Fine-Tuning (SFT)

Dataset: instruction → response (and optionally multi-turn).

Loss: still next-token cross-entropy, usually **only on assistant tokens** (mask user tokens).

Tools:

- [Hugging Face TRL — SFT Trainer](https://huggingface.co/docs/trl/sft_trainer)  
- [TRL PEFT integration](https://huggingface.co/docs/trl/peft_integration)  
- [Unsloth fine-tuning guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide)  

---

## Full fine-tune vs LoRA

| Method | Updates | VRAM | Risk |
|--------|---------|------|------|
| **Full FT** | all weights | high | strong adaptation; can forget |
| **LoRA** | low-rank adapters on selected layers | much lower | good for most apps |
| **QLoRA** | LoRA on 4-bit quantized base | lowest | great for consumer GPUs |

**LoRA idea:** for a weight `W`, learn `ΔW ≈ B A` with small rank `r`. Freeze `W`; train `A, B`. Merge adapters at export if desired.

Typical knobs: `r`, `lora_alpha`, target modules (`q_proj`, `v_proj`, …), dropout.

---

## Recipe that works for beginners

1. Start from a **strong open instruct model** in your size budget (or base if you’ll do heavy alignment).  
2. Build **1k–50k high-quality** examples (quality ≫ quantity).  
3. Match the model’s **chat template**.  
4. Train LoRA/QLoRA 1–3 epochs; watch val loss.  
5. Eval on held-out prompts + real tasks.  
6. If it regresses on general ability → lower LR, fewer steps, more diverse data, or smaller LoRA rank.

Unsloth documents beginner paths and lists GLM-5.2 among models you can run/fine-tune tooling-wise ([Unsloth tutorials](https://unsloth.ai/docs/models/tutorials)) — still respect VRAM: **753B full model is not a laptop fine-tune**.

---

## Hyperparameters (starting points)

| Knob | Typical start |
|------|----------------|
| LR | 1e-4 to 2e-4 for LoRA; lower for full FT |
| Rank r | 8–64 |
| Batch | as large as VRAM allows (use grad accumulation) |
| Epochs | 1–3 |
| Max seq len | fit your data; don’t waste on empty padding |

---

## Catastrophic forgetting

Too much narrow SFT → model becomes a parrot for your set and worse at everything else.

Mitigations: mix general data, early stop, LoRA instead of full, replay, lower LR.

---

## Check yourself

1. What tokens should the SFT loss include?  
2. What does LoRA freeze vs train?  
3. When is QLoRA the right default?


## Do this now

1. Follow the ordered path: [`../05-practice/00-first-lora-path.md`](../05-practice/00-first-lora-path.md).  
2. Smoke: [`../05-practice/05-hands-on-first-lora.md`](../05-practice/05-hands-on-first-lora.md) (Unsloth or HF Colab).  
3. Then checklist + BP before a serious retrain.

## Tutorials

- [Unsloth FT guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide) · [TRL SFT](https://huggingface.co/docs/trl/sft_trainer) · [TRL LoRA notebook](https://github.com/huggingface/trl/blob/main/examples/notebooks/sft_trl_lora_qlora.ipynb)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

Hands-on path: [`../05-practice/00-first-lora-path.md`](../05-practice/00-first-lora-path.md) → checklist [`../05-practice/01-first-finetune-checklist.md`](../05-practice/01-first-finetune-checklist.md) → [`06-best-practices-finetuning.md`](./06-best-practices-finetuning.md) (before serious retrain) · coding: [`07-coding-model-finetuning.md`](./07-coding-model-finetuning.md) · then [`03-rlhf-and-preferences.md`](./03-rlhf-and-preferences.md)

## Sources

- [HF TRL — SFT Trainer](https://huggingface.co/docs/trl/sft_trainer)
- [HF TRL — PEFT integration](https://huggingface.co/docs/trl/peft_integration)
- [Unsloth fine-tuning guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide)
- [Raschka — Practical Tips for LoRA](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms)
