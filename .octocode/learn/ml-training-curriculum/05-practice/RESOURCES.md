# Resources & citations

Validated while building this curriculum (2026-07-08). Prefer these over random blog SEO.

## Foundations

| Topic | Source | Confidence |
|-------|--------|------------|
| Softmax as categorical distribution | [d2l.ai Softmax Regression](https://d2l.ai/chapter_linear-classification/softmax-regression.html) | strong |
| Transformer / attention (paper) | [Vaswani et al. 2017, arXiv:1706.03762](https://arxiv.org/abs/1706.03762) | strong |
| Visual Transformer walkthrough | [Jay Alammar — Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) | strong |
| Line-by-line implementation | [Harvard NLP — Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) | strong |
| Attention chapter (scoring, MHA, PE, architecture) | [d2l Attention Mechanisms and Transformers](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html) | strong |
| Multi-head attention | [d2l §11.5](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html) | strong |
| Transformer architecture | [d2l §11.7](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html) | strong |
| Self-attention + positional encoding | [d2l §11.6](https://d2l.ai/chapter_attention-mechanisms-and-transformers/self-attention-and-positional-encoding.html) | strong |
| Attention scoring (dot vs additive) | [d2l §11.3](https://d2l.ai/chapter_attention-mechanisms-and-transformers/attention-scoring-functions.html) | strong |
| RoPE | [RoFormer, arXiv:2104.09864](https://arxiv.org/abs/2104.09864) | strong |
| FlashAttention | [Dao et al., arXiv:2205.14135](https://arxiv.org/abs/2205.14135) | strong |
| Grouped-Query Attention | [Ainslie et al., arXiv:2305.13245](https://arxiv.org/abs/2305.13245) | strong |
| Cross-entropy | [Wikipedia — Cross-entropy](https://en.wikipedia.org/wiki/Cross-entropy) | strong (definitional) |
| Curriculum deep dives | [`../02-intermediate/04-transformers-deep-dive.md`](../02-intermediate/04-transformers-deep-dive.md), [`../02-intermediate/05-attention-deep-dive.md`](../02-intermediate/05-attention-deep-dive.md) | — |

## Fine-tuning stack

| Topic | Source | Confidence |
|-------|--------|------------|
| SFT API | [HF TRL SFT Trainer](https://huggingface.co/docs/trl/sft_trainer) | strong |
| LoRA via PEFT | [HF TRL PEFT integration](https://huggingface.co/docs/trl/peft_integration) | strong |
| Beginner FT path | [Unsloth fine-tuning guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide) | strong |
| Beginner FT | [Unsloth for beginners](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners) | strong |
| LoRA hyperparams | [Unsloth LoRA hyperparameters guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide) | strong |
| LoRA experiment tips | [Raschka — Practical Tips for Finetuning LLMs Using LoRA](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms) | strong |
| Curriculum BP docs | [`../03-advanced/05-best-practices-training.md`](../03-advanced/05-best-practices-training.md), [`../03-advanced/06-best-practices-finetuning.md`](../03-advanced/06-best-practices-finetuning.md) | — |

## GLM-5.2 / agentic RL

| Topic | Source | Confidence |
|-------|--------|------------|
| Model card (753B, MIT, serve stack) | [huggingface.co/zai-org/GLM-5.2](https://huggingface.co/zai-org/GLM-5.2) | strong |
| IndexShare, 1M ctx, slime, anti-hack, OPD | [HF blog 2026-06-17](https://huggingface.co/blog/zai-org/glm-52-blog) | strong |
| Technical report | [arXiv:2602.15763](https://arxiv.org/abs/2602.15763) | strong |
| slime framework | [github.com/THUDM/slime](https://github.com/THUDM/slime) | strong |
| slime docs | [thudm.github.io/slime](https://thudm.github.io/slime/) | strong |

## Intuition articles (secondary)

| Topic | Source | Confidence |
|-------|--------|------------|
| Visual self-attention | [jtlicardo.com self-attention](https://jtlicardo.com/blog/self-attention-mechanism/) | moderate |
| QKV intuition | [arpitbhayani.me QKV](https://arpitbhayani.me/blogs/qkv-matrices/) | moderate |

## Practical tutorials (Colab / YouTube / notebooks)

**Primary index:** [`TUTORIALS.md`](./TUTORIALS.md) — one row of URLs per curriculum session.  
**First run:** [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md).

| Bundle | URL |
|--------|-----|
| Unsloth notebooks | https://unsloth.ai/docs/get-started/unsloth-notebooks |
| HF LoRA Colab | https://colab.research.google.com/github/huggingface/notebooks/blob/main/course/en/chapter11/section4.ipynb |
| Karpathy Let’s build GPT | https://www.youtube.com/watch?v=kCc8FmEb1nY |
| Karpathy Zero to Hero | https://karpathy.ai/zero-to-hero.html |
| d2l Colabs | https://d2l.ai/ |
| HF LLM course | https://huggingface.co/learn/llm-course |

## Guided reading path

See [`03-transformer-reading-path.md`](./03-transformer-reading-path.md) for Alammar → d2l → paper → Annotated Transformer → RoPE/Flash/GQA.

Marketing / social posts about GLM benchmarks were treated as **leads only**, not citations.

## Curriculum files

See parent [`README.md`](../README.md) for the reading order.

## Coding model fine-tuning

| Topic | Source | Confidence |
|-------|--------|------------|
| OSS-Instruct / Magicoder | [arXiv:2312.02120](https://arxiv.org/abs/2312.02120) · [ise-uiuc/magicoder](https://github.com/ise-uiuc/magicoder) | strong |
| Magicoder OSS-Instruct data | [HF dataset 75K](https://huggingface.co/datasets/ise-uiuc/Magicoder-OSS-Instruct-75K) | strong |
| WizardCoder / Evol-Instruct | [arXiv:2306.08568](https://arxiv.org/abs/2306.08568) | strong |
| OpenCodeInstruct (5M + ablations) | [arXiv:2504.04030](https://arxiv.org/abs/2504.04030) | strong |
| EvalPlus (HumanEval+/MBPP+) | [evalplus/evalplus](https://github.com/evalplus/evalplus) | strong |
| FIM pretrain | [arXiv:2506.00204](https://arxiv.org/abs/2506.00204) | moderate |
| Dataset index | [mlabonne/llm-datasets](https://github.com/mlabonne/llm-datasets) | moderate (index; verify each set) |
| Curriculum chapter | [`../03-advanced/07-coding-model-finetuning.md`](../03-advanced/07-coding-model-finetuning.md) | — |
| Coding checklist | [`04-coding-finetune-checklist.md`](./04-coding-finetune-checklist.md) | — |

## Synthetic data & normalization

| Topic | Source | Confidence |
|-------|--------|------------|
| Synthetic FT overview | [Eugene Yan — Synthetic data](https://eugeneyan.com/writing/synthetic/) | strong |
| Self-Instruct | [arXiv:2212.10560](https://arxiv.org/abs/2212.10560) | strong |
| Textbook-quality synth | [Textbooks Are All You Need](https://arxiv.org/abs/2306.11644) | strong |
| LLM data preprocessing | [NVIDIA blog](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/) | strong |
| FineWeb filtering | [arXiv:2406.17557](https://arxiv.org/abs/2406.17557) | strong |
| Curriculum: normalize | [`../04-data/05-normalize-and-clean.md`](../04-data/05-normalize-and-clean.md) | — |
| Curriculum: synthetic | [`../04-data/06-synthetic-data.md`](../04-data/06-synthetic-data.md) | — |
| Curriculum: flows | [`../04-data/07-end-to-end-data-flows.md`](../04-data/07-end-to-end-data-flows.md) | — |

### Added after teacher/tutor audit (2026-07-08)

| Gap | Doc |
|-----|-----|
| Tokens / VRAM / logits | [`../01-beginner/04-tokens-and-gpu-basics.md`](../01-beginner/04-tokens-and-gpu-basics.md) |
| Packing + masks | [`../04-data/03-packing-and-masks.md`](../04-data/03-packing-and-masks.md) |
| Eval literacy | [`../04-data/04-evaluation-literacy.md`](../04-data/04-evaluation-literacy.md) |
| Check-yourself answers | [`ANSWERS.md`](./ANSWERS.md) |
| Expanded jargon | [`../GLOSSARY.md`](../GLOSSARY.md) |

Extra known sources for those gaps:

- [Karpathy Zero to Hero](https://karpathy.ai/zero-to-hero.html)
- [HF chat templating](https://huggingface.co/docs/transformers/chat_templating)
- [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness)
- [DPO paper](https://arxiv.org/abs/2305.18290) · [InstructGPT](https://arxiv.org/abs/2203.02155)
- [Chinchilla](https://arxiv.org/abs/2203.15556)
- [PyTorch mixed precision](https://pytorch.org/blog/what-every-user-should-know-about-mixed-precision-training-in-pytorch/)
- [LIMA](https://arxiv.org/abs/2305.11206)
