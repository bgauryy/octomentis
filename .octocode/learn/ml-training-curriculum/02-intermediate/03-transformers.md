# 03 — Transformers and LLMs

## Block structure (decoder-only GPT-style)

Repeat N times:

```
x → RMSNorm → Multi-Head Attention → + residual
  → RMSNorm → MLP (FFN)            → + residual
```

Final norm → **LM head / unembedding** (linear map to vocab size; sometimes **weight-tied** to input embeddings) → **logits** → softmax → next-token distribution.

**MLP / FFN** usually expands to `4×` hidden size (or gated variants like SwiGLU), applies nonlinearity, projects back.

---

## Autoregressive generation

1. Encode prompt tokens  
2. Sample / argmax next token from categorical distribution  
3. Append token; repeat  

Training: teacher-forcing — predict every next token in parallel with causal mask; loss = average `−log P(token_t | tokens_<t)`.

---

## Tokenization

Subword tokenizers (BPE, SentencePiece, …) map text ↔ ID sequences.

Implications:

- “words” ≠ tokens  
- code and multilingual text need good vocab coverage  
- chat models wrap turns in a **chat template** (special tokens) — **must match at train and inference**

---

## Context length

Max tokens the model was trained / engineered to handle.

Long context needs:

- architecture (RoPE scaling, sparse attention, …)  
- mid-training / continued pretrain on long sequences  
- inference engine support (KV cache, paging)

GLM-5.2 advertises a solid **1M-token** context with IndexShare sparse attention — see advanced case study.

---

## Base vs Instruct vs Reasoning

| Checkpoint type | Trained for |
|-----------------|-------------|
| **Base** | raw next-token; great for further training |
| **Instruct / Chat** | follow instructions (SFT + often preference/RL) |
| **Reasoning / effort levels** | extra compute at decode (“think longer”) |

Fine-tune **base** when you want full control of behavior; fine-tune **instruct** when you want to specialize an already-aligned model (careful not to wreck alignment).

---

## MoE and scale

**Mixture of Experts:** many FFN experts; a router picks a few per token. Increases parameter count without proportional FLOPs per token.

Frontier open models (including GLM-class) often combine MoE + efficient attention + heavy post-training.

---

## What you need to “know” before fine-tuning

1. Chat template / special tokens  
2. Max context you’ll train on  
3. License and intended use  
4. Whether you need LoRA vs full update  
5. Eval tasks that match your goal  

---

## Check yourself

1. Sketch one Transformer block.  
2. Why must train and serve use the same chat template?  
3. Base vs instruct — when to pick which?


## Do this now

1. Watch [Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) (or first hour).
2. Clone [nanoGPT](https://github.com/karpathy/nanoGPT) and skim `train.py` / `model.py`.

## Tutorials

- [Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) · [nanoGPT](https://github.com/karpathy/nanoGPT) · [HF language modeling](https://huggingface.co/docs/transformers/tasks/language_modeling)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

Data before FT: [`../04-data/01-digesting-data.md`](../04-data/01-digesting-data.md) → then Advanced: [`../03-advanced/01-pretraining.md`](../03-advanced/01-pretraining.md)

## Sources

- [HF — AutoModelForCausalLM](https://huggingface.co/docs/transformers/model_doc/auto)
- [HF — Chat templating](https://huggingface.co/docs/transformers/chat_templating)
- [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/)
