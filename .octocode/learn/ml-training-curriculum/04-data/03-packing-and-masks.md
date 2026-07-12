# 03 — Packing, padding, and loss masks

**Critical gap fix** (teacher audit): “pack / tokenize” is not just concatenation.

---

## Three different masks (don’t confuse them)

| Mask | Purpose |
|------|---------|
| **Padding mask** | Ignore `pad` positions in attention and usually in loss |
| **Causal mask** | Token t cannot attend to future tokens (> t) |
| **Loss / label mask** | Which positions contribute to cross-entropy (e.g. **assistant-only** in SFT) |

You often need **all three** in chat SFT.

---

## Padding vs packing

**Padding:** make every sequence in a batch the same length by appending `pad`. Wasteful if lengths vary a lot.

**Packing:** concatenate several short examples into one long sequence up to `max_seq_length` to raise tokens/sec.

### Packing without proper boundaries = silent bug

If you glue Doc A and Doc B into one sequence and allow full (causal) attention across the join, token at the start of B can attend to A’s content as if it were context — **cross-example leakage**.

**Best practice:**

1. Insert a clear separator / `eos` between packed docs when appropriate.  
2. Use an **attention mask** (or equivalent) so positions only attend within their own example (plus causal).  
3. Set **labels to ignore index** (`-100` in PyTorch) on pads, user turns, and any tokens you must not train on.  
4. Verify with a tiny packed batch: decode masks, print which positions have loss > 0.

Frameworks (TRL, Axolotl, etc.) often have packing flags — **read what mask they apply**; don’t assume.

---

## Assistant-only loss (SFT)

For chat:

```
<user> ... </user> <assistant> ... </assistant>
```

Compute loss **only** on assistant token positions. Training on user tokens teaches the model to imitate the user, not answer.

---

## Checklist before a long run

- [ ] Pad token id set; pads ignored in loss  
- [ ] Causal mask on (decoder-only)  
- [ ] If packing: sample-boundary attention + loss masks verified  
- [ ] Chat template applied before tokenize  
- [ ] Spot-check 3 decoded training rows  

---

## Check yourself

1. Why is packing without masks dangerous?  
2. What should SFT usually put in the loss mask?  
3. Padding vs packing — one sentence each.


## Do this now

1. In [TRL SFT docs](https://huggingface.co/docs/trl/sft_trainer), find packing / completion-only options for your TRL version.
2. Print which token ids would get `ignore_index=-100` for one chat example (assistant-only).

## Tutorials

- [TRL SFT Trainer](https://huggingface.co/docs/trl/sft_trainer)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

**Flow A:** [`04-evaluation-literacy.md`](./04-evaluation-literacy.md) → [`../03-advanced/02-finetuning-lora.md`](../03-advanced/02-finetuning-lora.md) · hands-on: [`../05-practice/00-first-lora-path.md`](../05-practice/00-first-lora-path.md)  
(If you skipped normalize: [`05-normalize-and-clean.md`](./05-normalize-and-clean.md) first.)

## Sources

- [HF TRL SFT Trainer](https://huggingface.co/docs/trl/sft_trainer) (packing / completion-only options — check current docs)  
- [HF chat templating](https://huggingface.co/docs/transformers/chat_templating)  
- [PyTorch CrossEntropyLoss `ignore_index`](https://pytorch.org/docs/stable/generated/torch.nn.CrossEntropyLoss.html)
