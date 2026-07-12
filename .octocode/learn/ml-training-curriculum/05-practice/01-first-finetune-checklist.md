# 01 — First fine-tune checklist

Use this **after** a smoke LoRA (or when you’re ready to train for real).

**Ordered path (start here if lost):** [`00-first-lora-path.md`](./00-first-lora-path.md)

**Before a serious retrain (not required for Colab smoke):** skim [`../03-advanced/06-best-practices-finetuning.md`](../03-advanced/06-best-practices-finetuning.md) · [`../03-advanced/05-best-practices-training.md`](../03-advanced/05-best-practices-training.md)

## Before you touch a GPU

- [ ] One-sentence goal + metric Z  
- [ ] Base checkpoint chosen (license OK)  
- [ ] 50–500+ quality examples in chat schema  
- [ ] Train/val split; eval prompts frozen  
- [ ] Chat template verified (encode → decode)  
- [ ] Secrets/PII scrubbed  

## Environment

- [ ] GPU with enough VRAM **or** Unsloth/Colab path  
- [ ] `transformers` + `trl` + `peft` (+ `bitsandbytes` for QLoRA)  
- [ ] Fixed seed; logged config (LR, r, epochs, max_len)  

Official refs:

- [TRL SFT Trainer](https://huggingface.co/docs/trl/sft_trainer)  
- [TRL PEFT / LoRA](https://huggingface.co/docs/trl/peft_integration)  
- [Unsloth fine-tuning guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide)  
- [Unsloth for beginners](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners)  

## Train

- [ ] LoRA/QLoRA first (not full FT)  
- [ ] Assistant-only loss mask  
- [ ] Monitor train + val loss (stop if val rises hard)  
- [ ] Save adapter checkpoints each epoch  

## After

- [ ] Blind eval on held-out + fresh prompts  
- [ ] Check regressions (general chat, safety refusals if relevant)  
- [ ] Export: adapter merge or serve adapter  
- [ ] Write a short postmortem: what data helped / hurt  

## Red flags

| Symptom | Likely cause |
|---------|--------------|
| Loss NaN | LR too high, bad data, unstable precision |
| Perfect train, garbage eval | overfit / leakage / template mismatch |
| Ignores instructions | wrong template or loss on user tokens |
| Became dumb at everything | too many epochs on narrow data |


## Do this now

1. Complete [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md) Option A or B.
2. Tick every box in this checklist against that run.

## Tutorials

- [Unsloth beginners](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners) · [TUTORIALS.md](./TUTORIALS.md)

## Next

Coding specialization: [`04-coding-finetune-checklist.md`](./04-coding-finetune-checklist.md) · [`02-tool-map.md`](./02-tool-map.md) · [`ANSWERS.md`](./ANSWERS.md) · [`RESOURCES.md`](./RESOURCES.md)

## Sources

- [Unsloth fine-tuning guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide)
- [HF TRL SFT](https://huggingface.co/docs/trl/sft_trainer)
- [HF chat templating](https://huggingface.co/docs/transformers/chat_templating)
- Curriculum BP: [`../03-advanced/06-best-practices-finetuning.md`](../03-advanced/06-best-practices-finetuning.md)
