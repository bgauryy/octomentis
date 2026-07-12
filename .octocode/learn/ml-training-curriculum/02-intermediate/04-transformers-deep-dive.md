# 04 — How Transformers work (deep dive)

Canonical sources this chapter compresses:

- [Vaswani et al., 2017 — Attention Is All You Need](https://arxiv.org/abs/1706.03762)  
- [Jay Alammar — The Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)  
- [Harvard NLP — The Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/)  
- [d2l.ai — The Transformer Architecture](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html)  
- [d2l.ai — Self-Attention and Positional Encoding](https://d2l.ai/chapter_attention-mechanisms-and-transformers/self-attention-and-positional-encoding.html)

Read [`02-attention.md`](./02-attention.md) first if Q/K/V is new.

---

## 1. Why Transformers replaced RNNs

| Property | RNN / LSTM | Transformer (self-attention) |
|----------|------------|------------------------------|
| Parallelism over sequence | poor (sequential) | excellent (matrix ops) |
| Path length between distant tokens | long (O(n) steps) | short (O(1) via attention) |
| Long-range deps | hard | direct (every pair can interact) |
| Cost | O(n) per step | classic attention **O(n²)** |

d2l summary: self-attention wins on **parallel compute** and **shortest max path length** — hence deep stacks without recurrence ([d2l Transformer](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html)).

---

## 2. Original Transformer = encoder–decoder

From Alammar / Vaswani (machine translation):

```
Input tokens  →  Encoder stack (N×)  →  memory
Target tokens →  Decoder stack (N×)  →  next-token logits
                      ↑
              cross-attention to encoder
```

Paper default: **N = 6** identical layers each side (weights not shared across layers).

### Encoder layer (2 sublayers)

1. **Multi-head self-attention** — Q, K, V all from the same sequence  
2. **Position-wise FFN** — same MLP applied independently at each position  

Around each: **residual** `x + Sublayer(x)` then **LayerNorm** (original paper: post-norm).

### Decoder layer (3 sublayers)

1. **Masked** multi-head self-attention (causal — no future tokens)  
2. **Encoder–decoder (cross) attention** — Q from decoder, K/V from encoder output  
3. **Position-wise FFN**  

Same residual + LayerNorm pattern.

**Modern LLMs (GPT-style)** usually drop the encoder: **decoder-only** stacks with causal self-attention only. Same blocks; no cross-attn to a separate encoder.

---

## 3. Data flow (one forward pass)

1. **Tokenize** → IDs  
2. **Embed** → vectors of size `d_model` (paper: 512)  
3. **Add positional encoding** (sin/cos in original; **RoPE** in most modern LMs — see attention deep dive)  
4. Run through N blocks  
5. Final linear → **vocab logits** → softmax → distribution  

Alammar’s key insight: each position has its own path through the FFN (embarrassingly parallel); **dependencies live in attention**.

---

## 4. Position-wise feed-forward network

Same two-layer MLP at every token:

```
FFN(x) = max(0, x W₁ + b₁) W₂ + b₂   # ReLU in original
```

Typical width: `d_ff = 4 × d_model` (paper: 2048 if `d_model=512`).

Modern variants: **GELU**, **SwiGLU** / gated FFNs (Llama-style).

Why “position-wise”? Weights shared across positions; no mixing across tokens here — **attention** does the mixing.

---

## 5. Residuals + normalization

Without residuals, deep attention stacks are hard to train.

| Style | Order | Common in |
|-------|-------|-----------|
| **Post-norm** (original) | Sublayer → Add → Norm | Vaswani 2017 |
| **Pre-norm** | Norm → Sublayer → Add | Most modern LLMs |
| **RMSNorm** | cheaper norm variant | Llama, many OSS LMs |

Pre-norm tends to train more stably at depth.

---

## 6. Dimensionality cheat sheet (original paper)

| Symbol | Typical | Meaning |
|--------|---------|---------|
| `d_model` | 512 | residual stream width |
| `h` | 8 | number of heads |
| `d_k = d_v` | 64 | per-head key/value dim (`d_model / h`) |
| `d_ff` | 2048 | FFN hidden |
| `N` | 6 | layers per stack |

Multi-head keeps total compute similar to one full-dim attention by splitting channels across heads ([d2l multi-head](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html)).

---

## 7. Training objective (seq2seq vs LM)

| Setup | Predicts | Mask |
|-------|----------|------|
| Original MT Transformer | next target token given source + previous targets | causal on decoder; full on encoder |
| Decoder-only LM | next token given previous tokens | causal everywhere |

Loss: token-level **cross-entropy** (see beginner distributions chapter).

---

## 8. Inference vs training

**Training:** teacher forcing — full target sequence in parallel under causal mask.

**Inference:** autoregressive loop — emit one token, append, repeat. Engines cache **K/V** so past tokens aren’t recomputed (KV cache — attention deep dive).

---

## 9. Mental model to keep

```
Transformer block ≈
   "soft routing over tokens" (attention)
 + "per-token MLP compute" (FFN)
 + "highway for gradients" (residual + norm)
```

Stack many → hierarchical features (syntax → semantics → task structure), though layers don’t map cleanly to linguistic levels.

---

## 10. Where to go next in code

| Resource | What you get |
|----------|----------------|
| [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) | line-by-line PyTorch of the paper |
| [d2l Transformer notebook](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html) | teachable implementation + exercises |
| [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) | visual walkthrough |

---

## Check yourself

1. Name the 2 encoder vs 3 decoder sublayers.  
2. Why can FFNs run in parallel across positions?  
3. How does a GPT-style model differ from the 2017 MT Transformer?


## Do this now

1. Open [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) and run/read the notebook.
2. Run [d2l Transformer](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html) Colab.

## Tutorials

- [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) · [d2l Transformer](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`03-transformers.md`](./03-transformers.md) (LLM summary) → [`../04-data/01-digesting-data.md`](../04-data/01-digesting-data.md)

## Sources

- [Vaswani et al. 2017](https://arxiv.org/abs/1706.03762)
- [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)
- [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/)
- [d2l — Transformer Architecture](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html)
