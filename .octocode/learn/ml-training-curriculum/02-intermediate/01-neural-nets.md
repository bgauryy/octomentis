# 01 — Neural networks (building blocks)

## Layers as functions

A neural net is a stack of differentiable functions:

```
x → Linear → Nonlinearity → Linear → … → logits
```

**Linear (Dense / Affine):** `y = Wx + b`  
Learns a weighted mix of inputs.

**Nonlinearity:** without it, stacked linears collapse to one linear map. Common:

| Activation | Shape |
|------------|-------|
| ReLU | `max(0, x)` |
| GELU / SiLU | smooth ReLU-like (Transformers) |
| Softmax | distribution over classes (usually last layer) |

---

## Embeddings

Discrete IDs (token IDs, user IDs) → dense vectors via a lookup table.

For LLMs:

1. text → **tokenizer** → token IDs  
2. IDs → **embedding matrix** → vectors of size `d_model`  
3. add **positional** information (absolute, RoPE, ALiBi, …)  
4. run Transformer blocks  

---

## Depth, width, residual connections

- **Width** = hidden size  
- **Depth** = number of layers  

**Residuals** (`x + F(x)`) let gradients flow through deep stacks — essential for Transformers.

**LayerNorm / RMSNorm** stabilize activations.

---

## From MLP to sequence models

| Architecture | Strength | Weakness |
|--------------|----------|----------|
| MLP on fixed vector | simple | no variable-length structure |
| CNN | local patterns | long-range needs depth/dilation |
| RNN / LSTM | sequential | slow, vanishing memory |
| **Transformer** | parallel + long-range via attention | quadratic cost in sequence length (classically) |

LLMs = Transformers (with many efficiency variants: GQA, MoE, sparse attention, …).

---

## Capacity vs data

More parameters can fit more complex functions — but need enough data and regularization.  
**Scaling laws** (empirically): loss improves predictably with more params, data, and compute — until you hit data quality walls.

---

## Check yourself

1. Why do we need nonlinearities?  
2. What does an embedding layer do?  
3. Why residuals?


## Do this now

1. Run [d2l MLP](https://d2l.ai/chapter_multilayer-perceptrons/mlp.html) Colab for one training loop.
2. Optional: [3Blue1Brown ch.1](https://www.youtube.com/watch?v=aircAruvnKk).

## Tutorials

- [d2l MLP](https://d2l.ai/chapter_multilayer-perceptrons/mlp.html)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`02-attention.md`](./02-attention.md) → [`05-attention-deep-dive.md`](./05-attention-deep-dive.md)

## Sources

- [d2l — Multilayer Perceptrons](https://d2l.ai/chapter_multilayer-perceptrons/index.html)
- [d2l — Word Embedding](https://d2l.ai/chapter_natural-language-processing-pretraining/word-embedding-dataset.html)
