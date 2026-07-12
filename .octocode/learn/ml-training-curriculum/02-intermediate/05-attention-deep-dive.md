# 05 — Attention mechanisms (deep dive)

Everything around attention: scoring, multi-head math, masks, positions, KV cache, and modern efficiency tricks.

**Prereq:** [`02-attention.md`](./02-attention.md)  
**Pair with:** [`04-transformers-deep-dive.md`](./04-transformers-deep-dive.md)

### Known sources

| Topic | Source |
|-------|--------|
| Scaled dot-product + multi-head | [Vaswani et al. 2017](https://arxiv.org/abs/1706.03762) |
| Visual QKV walkthrough | [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) |
| Scoring functions + MHA | [d2l Attention Scoring](https://d2l.ai/chapter_attention-mechanisms-and-transformers/attention-scoring-functions.html) · [d2l Multi-Head](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html) · [d2l Self-Attention & PE](https://d2l.ai/chapter_attention-mechanisms-and-transformers/self-attention-and-positional-encoding.html) |
| Code annotation | [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) |
| RoPE | [RoFormer / Su et al., arXiv:2104.09864](https://arxiv.org/abs/2104.09864) |
| FlashAttention | [Dao et al., arXiv:2205.14135](https://arxiv.org/abs/2205.14135) |
| GQA | [Ainslie et al., arXiv:2305.13245](https://arxiv.org/abs/2305.13245) |

---

## 1. Attention as soft dictionary lookup

For each query vector **q**:

1. Score how well **q** matches every key **kⱼ**  
2. Turn scores into a **probability distribution** (softmax)  
3. Return the weighted sum of values **vⱼ**

So attention = **content-based addressing** into a set of (key, value) pairs.

Self-attention: the set is *the other tokens in the same sequence* (Alammar’s “it” ↔ “animal” example).

---

## 2. Attention scoring functions

From [d2l §11.3](https://d2l.ai/chapter_attention-mechanisms-and-transformers/attention-scoring-functions.html):

### Additive (Bahdanau-style)

```
score(q, k) = wᵀ tanh(W_q q + W_k k)
```

Flexible; more params; historically used in RNN seq2seq.

### Scaled dot-product (Transformer default)

```
score(q, k) = (q · k) / √d_k
```

Why scale by `√d_k`? Dot products grow with dimension → softmax saturates → tiny gradients. Scaling keeps variance in a nicer range (Vaswani et al.).

Matrix form for a whole sequence:

```
Attention(Q, K, V) = softmax(Q Kᵀ / √d_k) V
```

Optional **attention dropout** on the weights after softmax (training only).

---

## 3. Multi-head attention (math)

Instead of one attention in `d_model` space, run **h** heads in parallel in smaller subspaces, then fuse ([d2l §11.5](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html)):

```
head_i = Attention(Q W_i^Q, K W_i^K, V W_i^V)
MultiHead(Q,K,V) = Concat(head_1 … head_h) W^O
```

Typical: `d_k = d_v = d_model / h`.

**Why heads?** Different heads can specialize (syntax vs long-range vs punctuation). d2l: combine knowledge from **different representation subspaces**.

Implementation trick: one big `W_q` projecting to `h × d_k`, then reshape/transpose to run heads in a batched matmul (see d2l `transpose_qkv`).

---

## 4. Three attention patterns in Transformers

| Pattern | Q from | K,V from | Where |
|---------|--------|----------|-------|
| **Self-attention** | sequence A | A | encoder; decoder (masked) |
| **Cross-attention** | decoder | encoder memory | classic MT decoder |
| **Causal self-attention** | tokens | tokens ≤ t | GPT / LLM decoders |

---

## 5. Masks (critical)

Softmax ignores `−∞` inputs (weight → 0).

| Mask | Effect |
|------|--------|
| **Padding mask** | don’t attend to PAD positions |
| **Causal / subsequent mask** | query t cannot see keys > t |
| **Custom / sparse** | only attend to selected indices (window, DSA, …) |

Causal mask is what makes **parallel training** compatible with **autoregressive** generation.

---

## 6. Positional information

Attention is **permutation-equivariant** without positions — shuffle tokens, same bag of interactions. Need order signals ([d2l §11.6](https://d2l.ai/chapter_attention-mechanisms-and-transformers/self-attention-and-positional-encoding.html)).

| Method | Idea |
|--------|------|
| **Absolute sin/cos PE** (Vaswani) | add fixed PE vector to embeddings |
| **Learned absolute PE** | embedding table over positions |
| **RoPE** (Su et al.) | *rotate* Q/K by position-dependent angles so dot-products encode **relative** offset |
| **ALiBi** | add distance bias to attention scores |
| **Relative bias** (T5-style) | learned biases by distance buckets |

**RoPE** dominates modern open LLMs: absolute position via rotation; relative structure falls out of Q·K. Long-context often needs RoPE scaling / interpolation + mid-training on long sequences.

---

## 7. KV cache (why decode is memory-bound)

At step t, keys/values for tokens `1…t-1` don’t change.

**Cache** them; only compute K/V for the new token; attend new Q to full cached K/V.

| Grows with | Impact |
|------------|--------|
| layers × KV heads × d_k × sequence length × batch | VRAM |
| Long context | often **the** serving bottleneck |

This is why **GQA/MQA**, quantization of KV (FP8), paging (vLLM), and sparse attention matter as much as FLOPs.

---

## 8. MHA vs MQA vs GQA

| Variant | Query heads | KV heads | Tradeoff |
|---------|-------------|----------|----------|
| **MHA** | h | h | best quality; largest KV cache |
| **MQA** | h | **1** | tiny cache; fast decode; quality risk ([GQA paper](https://arxiv.org/abs/2305.13245) discusses MQA) |
| **GQA** | h | g (1 < g < h) | middle ground — groups of queries share KV |

GQA (Ainslie et al. 2023): train or convert models so several query heads share one KV head → big inference win, small quality hit vs full MHA.

---

## 9. FlashAttention (exact, but fast)

Naive attention materializes the full `n × n` score matrix in HBM → huge memory traffic.

[FlashAttention (Dao et al., 2022)](https://arxiv.org/abs/2205.14135): **IO-aware exact** attention — tile Q/K/V through fast on-chip SRAM, never fully write the huge matrix to HBM. Same math, less memory movement → faster + lower peak memory.

Later: FlashAttention-2/3 — better parallelism / hardware mapping. As a user: prefer frameworks that call Flash kernels (PyTorch SDPA, xFormers, most LLM servers).

---

## 10. Sparse & long-context attention

Full attention is O(n²). For 100K–1M tokens, models use:

| Idea | Behavior |
|------|----------|
| Sliding window | local neighborhood only |
| Dilated / global tokens | some positions see all |
| Sparse indexer (DSA) | learn/select top-k keys |
| **IndexShare** (GLM-5.2) | share indexer across layers to cut cost |

Exact recipes are model-specific; the *idea* is: don’t pay full n² every layer.

---

## 11. Worked micro-example (1 head, 3 tokens)

Ignore `√d_k`. Tokens A,B,C. Query for B scores vs keys: `[1.0, 2.0, 0.0]`.

```
softmax([1, 2, 0]) ≈ [0.24, 0.67, 0.09]
output_B ≈ 0.24 V_A + 0.67 V_B + 0.09 V_C
```

B mostly mixes its own value, some A, little C.

With **causal** mask at position B, score vs C becomes `−∞` → weight 0 → only A and B.

---

## 12. Attention dropout, temperature, and “explanations”

- **Train dropout** on attention weights ≠ decode **temperature** (temperature reshapes the *token* softmax at the LM head).  
- Attention maps are **hints**, not faithful proofs of reasoning.  
- Head ablation can measure importance (d2l exercise idea) — don’t over-interpret a single heatmap.

---

## 13. Cheat sheet

```
scores   = Q @ K.T / sqrt(d_k)
scores   = mask(scores)          # pad / causal / sparse
weights  = softmax(scores)       # distribution over positions
weights  = dropout(weights)      # train only
out      = weights @ V
# multi-head: do above per head, concat, @ W_O
# positions: RoPE on Q,K (modern) or add PE to x (classic)
# decode: reuse K,V cache; consider GQA + FlashAttention
```

---

## Check yourself

1. Why scale dot-products by `√d_k`?  
2. MHA vs GQA — what shrinks?  
3. What problem does FlashAttention solve if the math is already “exact”?  
4. Why do we need RoPE (or PE) at all?


## Do this now

1. Run [d2l Multi-head attention](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html) Colab.
2. Skim [FlashAttention abstract](https://arxiv.org/abs/2205.14135) + [GQA abstract](https://arxiv.org/abs/2305.13245).

## Tutorials

- [d2l Multi-head](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html) · [FlashAttention](https://arxiv.org/abs/2205.14135)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`04-transformers-deep-dive.md`](./04-transformers-deep-dive.md) → [`03-transformers.md`](./03-transformers.md) → [`../04-data/`](../04-data/)

## Sources

(See table at top of this file — Vaswani, d2l, RoPE, FlashAttention, GQA, Illustrated Transformer, Annotated Transformer.)
