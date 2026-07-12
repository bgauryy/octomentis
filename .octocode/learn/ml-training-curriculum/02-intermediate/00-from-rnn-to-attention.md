# 00 — From RNNs to attention (motivation)

Short bridge before the attention/Transformer chapters. Sources: [d2l Attention chapter](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html), [Vaswani 2017](https://arxiv.org/abs/1706.03762), [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/).

---

## The old stack: seq2seq + RNNs

1. Encoder RNN reads source tokens one-by-one → hidden state  
2. Decoder RNN emits target tokens  
3. Early models passed only the **final** encoder state → bottleneck  

**Bahdanau attention** fixed the bottleneck: at each decode step, look at *all* encoder states with a soft weight. Still sequential; still RNN-bound.

---

## The leap: attention is enough

Transformers drop recurrence and convolution for the main mixing mechanism:

> If attention can pull the right context, stack attention + MLPs.

Benefits: train in parallel on GPUs/TPUs; model long-range links in one step.

Cost: classic self-attention is **quadratic** in sequence length — the tax modern kernels (FlashAttention) and sparse/GQA designs try to reduce.

---

## What you should feel in your bones

1. **Attention = weighted average** of values, weights from query–key match.  
2. **Self-attention** = every token can look at every other (modulo mask).  
3. **Transformer** = attention + FFN + residual/norm, repeated.  
4. **LLMs** = usually decoder-only Transformers trained to predict the next token.

---

## Check yourself

1. Why do RNNs struggle with long-range dependencies in practice?  
2. In one sentence: what does attention compute?  
3. Why can Transformers train more in parallel than RNNs?

## Do this now

1. Open [d2l Attention chapter](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html) and skim section titles.
2. Read the first half of [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/).

## Tutorials

- [d2l Attention](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html) · [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`01-neural-nets.md`](./01-neural-nets.md) → [`02-attention.md`](./02-attention.md) → [`05-attention-deep-dive.md`](./05-attention-deep-dive.md) → [`04-transformers-deep-dive.md`](./04-transformers-deep-dive.md) → [`03-transformers.md`](./03-transformers.md)

## Sources

- [d2l — Attention Mechanisms and Transformers](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html)
- [Vaswani et al. 2017](https://arxiv.org/abs/1706.03762)
- [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/)
