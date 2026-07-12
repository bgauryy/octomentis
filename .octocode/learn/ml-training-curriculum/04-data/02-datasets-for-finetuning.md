# 02 — Building datasets for fine-tuning

## Start from a use case

Write one sentence:

> After fine-tuning, the model should reliably do **X** for users like **Y**, measured by **Z**.

Examples of Z: exact JSON schema validity, pass@1 on internal tests, human preference win-rate, latency budget.

If you can’t name Z, you’re not ready to collect data.

---

## Collection strategies

| Source | Good for |
|--------|----------|
| Production logs (scrubbed) | real distribution |
| Expert-written examples | high quality, expensive |
| Seed + expand with LLM | coverage, needs verify |
| Public HF datasets | bootstrap; check license & overlap |
| Agent rollouts (success only) | tool-use SFT |

Prefer **real failures** of the base model as seeds — teach what it currently gets wrong.

---

## Example design tips

1. **One skill per example** when possible; mix skills across the set.  
2. Show the **format** you want at inference (JSON, markdown, tool calls).  
3. Include **hard negatives** in prefs: fluent but wrong.  
4. Multi-turn: keep only turns needed; don’t dump entire noisy chats.  
5. Balance: don’t let 80% of data be one easy template.

---

## Tokenization check

Before a long train run:

```text
sample → apply_chat_template → tokenize → decode
```

Confirm special tokens, roles, and that loss masks look right (assistant-only).

---

## Versioning

Treat datasets like code:

- `dataset_id` + hash  
- changelog (what filtered, what added)  
- link to train config that used them  

Reproducibility > vibes.

---

## Mini project (do this)

1. Pick a 3B–8B open instruct model.  
2. Write 50 gold `(user, assistant)` pairs for a narrow task.  
3. Hold out 10.  
4. LoRA SFT for 1 epoch.  
5. Compare base vs tuned on the 10 + 10 fresh prompts.  

If tuned wins on format but loses on general chat, mix in general data next round.

---

## Check yourself

1. What makes a good success metric Z?  
2. Why inspect `apply_chat_template` before training?  
3. Why version datasets?


## Do this now

1. Read [HF chat templating](https://huggingface.co/docs/transformers/chat_templating) and run `apply_chat_template` on 3 of your rows.
2. Skim [TRL dataset formats](https://huggingface.co/docs/trl/dataset_formats).

## Tutorials

- [Chat templating](https://huggingface.co/docs/transformers/chat_templating) · [TRL dataset formats](https://huggingface.co/docs/trl/dataset_formats)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

**Flow A:** [`03-packing-and-masks.md`](./03-packing-and-masks.md) → [`04-evaluation-literacy.md`](./04-evaluation-literacy.md) → train ([`../05-practice/00-first-lora-path.md`](../05-practice/00-first-lora-path.md))

## Sources

- [HF chat templating](https://huggingface.co/docs/transformers/chat_templating)
- [LIMA](https://arxiv.org/abs/2305.11206)
- [Raschka LoRA tips (dataset importance)](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms)
