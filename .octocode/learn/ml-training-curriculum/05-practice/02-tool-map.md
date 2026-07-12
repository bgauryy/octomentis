# 02 — Tool map (what to use when)

## Learn theory

| Resource | Use |
|----------|-----|
| [Dive into Deep Learning](https://d2l.ai/) | math + code for softmax, MLPs, attention, Transformers |
| [Attention Is All You Need](https://arxiv.org/abs/1706.03762) | original Transformer |
| [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) | visual walkthrough |
| [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) | implement the paper |
| [Curriculum reading path](./03-transformer-reading-path.md) | ordered known-source path |
| 3Blue1Brown / Karpathy videos | intuition (search current playlists) |

## Fine-tune small/medium models

| Tool | Use |
|------|-----|
| **Unsloth** | fastest path on consumer GPU / Colab |
| **HF TRL + PEFT** | standard SFT/DPO/PPO stack |
| **Axolotl / LLaMA-Factory** | config-driven training suites |
| **bitsandbytes** | 4/8-bit quantization for QLoRA |

## Data

| Tool | Use |
|------|-----|
| Hugging Face `datasets` | load/share datasets |
| Cleanlab / dedup scripts | quality |
| Your own validators | JSON schema, tests for code |

## Eval

| Tool | Use |
|------|-----|
| lm-evaluation-harness | academic-style benchmarks |
| Custom unit tests | product metrics |
| LLM-as-judge | preference proxies (biased) |

## Frontier / agentic RL (study + org-scale)

| Tool | Use |
|------|-----|
| [THUDM/slime](https://github.com/THUDM/slime) | GLM-style RL post-training |
| [slime docs](https://thudm.github.io/slime/) | how to run |
| vLLM / SGLang | high-throughput serve + rollouts |

## GLM-5.2 specifically

| Link | Use |
|------|-----|
| [zai-org/GLM-5.2](https://huggingface.co/zai-org/GLM-5.2) | weights + serve notes |
| [GLM-5.2 blog](https://huggingface.co/blog/zai-org/glm-52-blog) | architecture + RL story |
| [arXiv:2602.15763](https://arxiv.org/abs/2602.15763) | technical report |

## Best practices (in this curriculum)

- [Training BP](../03-advanced/05-best-practices-training.md) — warmup, batch/LR, monitoring, pretrain checklist  
- [Fine-tuning BP](../03-advanced/06-best-practices-finetuning.md) — LoRA defaults, anti-patterns, starter recipe  
- [Coding model FT](../03-advanced/07-coding-model-finetuning.md) — OSS-Instruct, Evol, OpenCodeInstruct, eval, RL  
- [Coding checklist](./04-coding-finetune-checklist.md)  

## Rule of thumb

```
Learn → Unsloth/TRL on 3B–8B → solid data/eval habits
      → larger SFT/DPO
      → read slime/GLM blogs
      → only then org-scale RL
```

## Sources

- Tutorials (all sessions): [`TUTORIALS.md`](./TUTORIALS.md)
- Hands-on LoRA: [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md)
- Hub: [`RESOURCES.md`](./RESOURCES.md)
- Transformer path: [`03-transformer-reading-path.md`](./03-transformer-reading-path.md)
- Answers: [`ANSWERS.md`](./ANSWERS.md)
