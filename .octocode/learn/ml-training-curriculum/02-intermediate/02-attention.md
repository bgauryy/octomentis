# 02 — Attention mechanism (Q, K, V)

## Intuition

For each token, attention asks:

> “Given what I’m looking for (**Query**), which other tokens’ **Keys** match, and what **Values** should I mix in?”

It builds a **weighted average** of other positions — weights = a **softmax distribution over sequence positions**.

Classic paper: [Attention Is All You Need (Vaswani et al., 2017)](https://arxiv.org/abs/1706.03762).

---

## The formula

For matrices `Q, K, V` (each row = one token):

```
Attention(Q, K, V) = softmax( (Q Kᵀ) / √d_k ) V
```

Step by step:

1. **Scores** `S = Q Kᵀ` — similarity of every query with every key  
2. **Scale** by `√d_k` — keeps softmax from saturating when `d_k` is large  
3. **Softmax** over keys (per query row) → attention weights (distribution)  
4. **Mix** values: weighted sum of `V` rows  

Output same length as queries; each position is a context-aware vector.

---

## Where Q, K, V come from

From the same input `X` (self-attention):

```
Q = X W_Q
K = X W_K
V = X W_V
```

`W_Q, W_K, W_V` are learned. Different projections let the model separate “what I seek”, “what I advertise”, and “what I contribute.”

**Cross-attention:** Q from one sequence, K/V from another (encoder–decoder).

---

## Causal (decoder) mask

Language models must not peek at future tokens when predicting the next one.

Mask: set scores for future positions to `−∞` before softmax → weight 0.

Training still runs in parallel over the sequence; the mask enforces the autoregressive rule.

---

## Multi-head attention

Run `h` attention heads in parallel (each with its own `W_Q, W_K, W_V`), concatenate, project with `W_O`.

Why: different heads specialize (syntax, coreference, code structure, …).

---

## Complexity and modern variants

Classic attention: **O(n²)** in sequence length `n` (every token attends to every other).

At long context (100K–1M tokens) this dominates. Production models use:

| Idea | Role |
|------|------|
| **GQA / MQA** | fewer KV heads → smaller KV cache |
| **FlashAttention** | IO-aware exact attention kernels |
| **Sparse / DSA / IndexShare** | attend to selected positions (see GLM-5.2) |
| **Sliding window** | local attention + occasional global |

Serving bottleneck often shifts from FLOPs to **KV-cache memory**.

---

## Tiny numeric sketch

Tokens A, B. Ignore scale. Suppose scores for query A: `[2.0, 0.0]` toward A,B.

```
softmax([2, 0]) ≈ [0.88, 0.12]
```

A’s output ≈ `0.88·V_A + 0.12·V_B` — mostly itself, a little B.

---

## Attention ≠ “the model is thinking about X”

Attention weights are a useful diagnostic, not a full explanation of reasoning. Treat heatmaps as hints, not proof.

---

## Check yourself

1. Write the Attention(Q,K,V) formula from memory.  
2. Why divide by `√d_k`?  
3. What does the causal mask prevent?


## Do this now

1. Finish [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) (self-attention section).
2. Open [d2l Attention scoring](https://d2l.ai/chapter_attention-mechanisms-and-transformers/attention-scoring-functions.html) Colab.

## Tutorials

- [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) · [d2l scoring](https://d2l.ai/chapter_attention-mechanisms-and-transformers/attention-scoring-functions.html)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`05-attention-deep-dive.md`](./05-attention-deep-dive.md) → [`04-transformers-deep-dive.md`](./04-transformers-deep-dive.md) → [`03-transformers.md`](./03-transformers.md)

## Sources

- [Vaswani et al. 2017 — Attention Is All You Need](https://arxiv.org/abs/1706.03762)
- [d2l — Attention chapter](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html)
- [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)
