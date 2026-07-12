# Transformer & attention — reading order (known sources)

Use this when you want primary materials, not only the curriculum summaries.

## Must-read path (≈1–2 days)

1. **Visual intuition** — [The Illustrated Transformer (Jay Alammar)](https://jalammar.github.io/illustrated-transformer/)  
2. **Curriculum** — [`02-attention.md`](../02-intermediate/02-attention.md) → [`05-attention-deep-dive.md`](../02-intermediate/05-attention-deep-dive.md) → [`04-transformers-deep-dive.md`](../02-intermediate/04-transformers-deep-dive.md)  
3. **Textbook + code** — [d2l Attention chapter](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html) (esp. §§11.3, 11.5, 11.6, 11.7)  
4. **Paper** — [Attention Is All You Need](https://arxiv.org/abs/1706.03762)  
5. **Implement** — [The Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/)

## Modern LLM stack (after the classics)

| Paper / note | Why |
|--------------|-----|
| [RoFormer / RoPE](https://arxiv.org/abs/2104.09864) | How modern models encode position |
| [FlashAttention](https://arxiv.org/abs/2205.14135) | Why training/serving attention is fast |
| [GQA](https://arxiv.org/abs/2305.13245) | How decode stays memory-efficient |
| [GLM-5.2 blog](https://huggingface.co/blog/zai-org/glm-52-blog) | Sparse long-context (IndexShare) in production |

## Optional video / course

- Alammar’s updated short course linked from the Illustrated Transformer page (2025 update on that site)  
- d2l Colab notebooks linked from each chapter page  

## Don’t skip

- Causal vs padding masks  
- Why `√d_k` scaling exists  
- KV cache at inference  
- Pre-norm vs post-norm (see transformer deep dive)

## Practical (do while reading)

| Step | Tutorial |
|------|----------|
| Visual | [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) |
| Code along | [Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) · [nanoGPT](https://github.com/karpathy/nanoGPT) |
| Implement paper | [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) |
| d2l Colab | [Transformer architecture](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html) |

Full session index: [`TUTORIALS.md`](./TUTORIALS.md).

## Sources

This file *is* a source index. Primary URLs above; full hub: [`RESOURCES.md`](./RESOURCES.md).
