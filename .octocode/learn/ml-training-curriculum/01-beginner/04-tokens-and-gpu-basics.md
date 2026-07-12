# 04 — Tokens, logits, and GPU memory (beginner glue)

The missing “hardware + text units” chapter. Read after loss/gradients; before or with attention.

---

## What is a token?

Models don’t see characters or words. A **tokenizer** maps text ↔ integer IDs.

Example (illustrative — real IDs depend on the tokenizer):

```
"Hello world!"  →  ["Hello", " world", "!"]  →  [15496, 995, 0]
```

| Idea | Meaning |
|------|---------|
| **Vocabulary** | Finite set of token strings the model knows |
| **BPE / SentencePiece** | Algorithms that learn frequent subword chunks |
| **Special tokens** | `<|im_start|>`, `eos`, `pad`, … — control chat/format |
| **Context length** | Max tokens the model can process in one window |

One English word ≠ one token. Code and non-English often use **more** tokens.

**Sources:** [Karpathy — Zero to Hero](https://karpathy.ai/zero-to-hero.html) (tokenization lectures) · [HF tokenizers](https://huggingface.co/docs/transformers/fast_tokenizers)

---

## What is a logit?

After the Transformer, a linear **LM head** (unembedding) outputs one number per vocab entry — **logits**.

```
logits  --softmax-->  P(next token)
```

Training loss uses logits (via cross-entropy). Decoding samples from `P` (with temperature / top-p).

Sometimes the LM head **shares weights** with the input embedding matrix (**weight tying**) — not always.

---

## VRAM, OOM, and what fills the GPU

**VRAM** = GPU memory. **OOM** = out of memory (training/inference crash).

Rough consumers during training:

| Consumer | Scales with |
|----------|-------------|
| Model weights | parameter count × precision (BF16 ≈ 2 bytes/param) |
| Activations | batch × seq_len × hidden × layers |
| Optimizer states | ~2× trainable params for AdamW |
| KV cache (decode) | layers × KV heads × d × seq_len × batch |

**Rules of thumb for beginners:**

- Shorter `max_seq_length` and smaller micro-batch save the most VRAM.  
- **Gradient accumulation** simulates a larger batch without storing a huge micro-batch.  
- **QLoRA** shrinks the *frozen* base; adapters stay trainable and small.

---

## Effective batch (again)

```
effective_batch = per_device_batch × gradient_accumulation_steps × num_gpus
```

Same effective batch ⇒ similar update size; small micro-batch + high accum = less VRAM.

---

## Check yourself

1. Why might “ChatGPT” be multiple tokens?  
2. Logits vs probabilities — which does softmax produce?  
3. Name two things that grow VRAM when you raise sequence length.


## Do this now

1. Watch [Let’s build the GPT Tokenizer](https://www.youtube.com/watch?v=zduSFxRajkE) (or skim first 20 min).
2. In Python: `pip install tiktoken` → encode `"Hello world!"` and print token count.

## Tutorials

- [Tokenizer video](https://www.youtube.com/watch?v=zduSFxRajkE) · [HF tokenizers](https://huggingface.co/docs/transformers/fast_tokenizers) · [tiktoken](https://github.com/openai/tiktoken)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`../02-intermediate/00-from-rnn-to-attention.md`](../02-intermediate/00-from-rnn-to-attention.md) or [`../04-data/03-packing-and-masks.md`](../04-data/03-packing-and-masks.md)

## Sources

- [Karpathy — Neural Networks: Zero to Hero](https://karpathy.ai/zero-to-hero.html)  
- [Hugging Face — Tokenizers](https://huggingface.co/docs/transformers/fast_tokenizers)  
- [Hugging Face — Chat templating](https://huggingface.co/docs/transformers/chat_templating)  
- [PyTorch — Mixed precision](https://pytorch.org/blog/what-every-user-should-know-about-mixed-precision-training-in-pytorch/)
