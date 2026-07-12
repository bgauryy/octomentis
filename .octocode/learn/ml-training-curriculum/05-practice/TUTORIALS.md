# Tutorials hub — practical URLs for every session

Hands-on links (Colab, YouTube, official notebooks). Theory stays in each lesson; **do these** to make it stick.

> Prefer free Colab / local. Check notebook “Open in Colab” buttons on d2l pages.

---

## Fast track (first LoRA in one weekend)

**Use the ordered path:** [`00-first-lora-path.md`](./00-first-lora-path.md) (don’t invent your own order).

| Step | Do this | URL |
|------|---------|-----|
| 1 | Watch LLM overview (1h) | [Karpathy — Intro to LLMs](https://www.youtube.com/watch?v=zjkBMFhNj_g) |
| 2 | Build intuition: GPT from scratch | [Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) · [nanoGPT](https://github.com/karpathy/nanoGPT) |
| 3 | Smoke fine-tune on free GPU | [Unsloth notebooks](https://unsloth.ai/docs/get-started/unsloth-notebooks) · follow [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md) |
| 4 | Or HF LoRA course notebook | [HF LoRA Colab](https://colab.research.google.com/github/huggingface/notebooks/blob/main/course/en/chapter11/section4.ipynb) |
| 5 | Checklist + serious retrain | [`01-first-finetune-checklist.md`](./01-first-finetune-checklist.md) → your JSONL + BP |

Smoke = prove the pipeline. Serious = your data + checklist.

---

## 01 — Beginner

| Lesson | Tutorials |
|--------|-----------|
| What is ML | [d2l — Preliminaries (Colab buttons on page)](https://d2l.ai/chapter_preliminaries/index.html) · [3Blue1Brown — Neural nets playlist](https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_ZCJB-3pi) |
| Distributions / softmax | [d2l Softmax Regression + Colab](https://d2l.ai/chapter_linear-classification/softmax-regression.html) |
| Loss & gradients | [Karpathy micrograd (backprop spelled out)](https://www.youtube.com/watch?v=VMj-3S1tku0) · [Zero to Hero course](https://karpathy.ai/zero-to-hero.html) · [d2l Autograd](https://d2l.ai/chapter_preliminaries/autograd.html) |
| Tokens & VRAM | [Karpathy — Let’s build the GPT Tokenizer](https://www.youtube.com/watch?v=zduSFxRajkE) · [HF tokenizers](https://huggingface.co/docs/transformers/fast_tokenizers) · [tiktoken](https://github.com/openai/tiktoken) |

**Do now:** run micrograd video paused-with-code, or open d2l softmax Colab and train one epoch.

---

## 02 — Intermediate (attention / Transformers)

| Lesson | Tutorials |
|--------|-----------|
| RNN → attention | [d2l Attention chapter index](https://d2l.ai/chapter_attention-mechanisms-and-transformers/index.html) (Colab on each section) |
| Neural nets | [d2l MLP](https://d2l.ai/chapter_multilayer-perceptrons/mlp.html) · [3Blue1Brown ch.1](https://www.youtube.com/watch?v=aircAruvnKk) |
| Attention intro | [Illustrated Transformer](https://jalammar.github.io/illustrated-transformer/) · [d2l Attention scoring](https://d2l.ai/chapter_attention-mechanisms-and-transformers/attention-scoring-functions.html) |
| Transformers (LLM) | [Let’s build GPT](https://www.youtube.com/watch?v=kCc8FmEb1nY) · [HF causal LM](https://huggingface.co/docs/transformers/tasks/language_modeling) |
| Transformers deep | [Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/) · [d2l Transformer + Colab](https://d2l.ai/chapter_attention-mechanisms-and-transformers/transformer.html) |
| Attention deep | [d2l Multi-head attention](https://d2l.ai/chapter_attention-mechanisms-and-transformers/multihead-attention.html) · [FlashAttention paper](https://arxiv.org/abs/2205.14135) (read abstract + fig) |

**Do now:** watch Illustrated Transformer once, then run d2l multi-head Colab; optionally train nanoGPT on a tiny text file.

---

## 04 — Data

| Lesson | Tutorials |
|--------|-----------|
| Digesting data | [HF Datasets quickstart](https://huggingface.co/docs/datasets/quickstart) · [LIMA paper](https://arxiv.org/abs/2305.11206) (skim) |
| Datasets for FT | [HF chat templating](https://huggingface.co/docs/transformers/chat_templating) · [TRL dataset formats](https://huggingface.co/docs/trl/dataset_formats) |
| Packing & masks | [TRL SFT Trainer](https://huggingface.co/docs/trl/sft_trainer) (search packing / completion) |
| Eval literacy | [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness) · [EvalPlus](https://github.com/evalplus/evalplus) |
| Normalize & clean | [NVIDIA data preprocessing](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/) · [FineWeb blog](https://huggingface.co/spaces/HuggingFaceFW/blogpost-fineweb-v1) |
| Synthetic data | [Eugene Yan — Synthetic data](https://eugeneyan.com/writing/synthetic/) · [Self-Instruct repo](https://github.com/yizhongw/self-instruct) |
| Data flows | This curriculum [`07-end-to-end-data-flows.md`](../04-data/07-end-to-end-data-flows.md) |

**Do now:** load a HF dataset, `apply_chat_template` on 3 rows, print token ids; write 10 gold JSONL examples for your task.

---

## 03 — Advanced (train / fine-tune)

| Lesson | Tutorials |
|--------|-----------|
| Pretraining | [Let’s reproduce GPT-2](https://www.youtube.com/watch?v=l8pRSuU81PU) · [build-nanogpt](https://github.com/karpathy/build-nanogpt) · [HF LM training](https://huggingface.co/docs/transformers/tasks/language_modeling) |
| Fine-tuning LoRA | [Unsloth FT guide](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide) · [Unsloth notebooks](https://unsloth.ai/docs/get-started/unsloth-notebooks) · [TRL SFT](https://huggingface.co/docs/trl/sft_trainer) · [TRL LoRA notebook](https://github.com/huggingface/trl/blob/main/examples/notebooks/sft_trl_lora_qlora.ipynb) · [HF LoRA Colab](https://colab.research.google.com/github/huggingface/notebooks/blob/main/course/en/chapter11/section4.ipynb) |
| RLHF / prefs | [TRL DPO Trainer](https://huggingface.co/docs/trl/dpo_trainer) · [Philschmid DPO walkthrough](https://www.philschmid.de/dpo-align-llms-in-2024-with-trl) |
| GLM-5.2 case | [Model card](https://huggingface.co/zai-org/GLM-5.2) · [Blog](https://huggingface.co/blog/zai-org/glm-52-blog) · [slime](https://thudm.github.io/slime/) |
| Training BP | [PyTorch mixed precision](https://pytorch.org/blog/what-every-user-should-know-about-mixed-precision-training-in-pytorch/) |
| Fine-tuning BP | [Unsloth LoRA hyperparams](https://unsloth.ai/docs/get-started/fine-tuning-llms-guide/lora-hyperparameters-guide) · [Raschka LoRA tips](https://magazine.sebastianraschka.com/p/practical-tips-for-finetuning-llms) |
| Coding models | [Magicoder repo](https://github.com/ise-uiuc/magicoder) · [EvalPlus](https://github.com/evalplus/evalplus) · [AMD StarCoder FT blog](https://rocm.blogs.amd.com/artificial-intelligence/starcoder-fine-tune/README.html) |

**Do now:** open one Unsloth Colab → Run all on a tiny dataset → chat with the adapter. Then swap in *your* 20 JSONL rows.

---

## 05 — Practice

| Doc | Tutorials |
|-----|-----------|
| First FT checklist | [Unsloth beginners](https://unsloth.ai/docs/get-started/fine-tuning-for-beginners) |
| Hands-on first LoRA | [`05-hands-on-first-lora.md`](./05-hands-on-first-lora.md) |
| Coding FT checklist | [EvalPlus README](https://github.com/evalplus/evalplus) |
| Tool map | [`02-tool-map.md`](./02-tool-map.md) |

---

## Playlist / course bookmarks

| Resource | URL |
|----------|-----|
| Karpathy Zero to Hero | https://karpathy.ai/zero-to-hero.html |
| Karpathy YouTube | https://www.youtube.com/@AndrejKarpathy |
| 3Blue1Brown Deep Learning | https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_ZCJB-3pi |
| d2l.ai (all Colabs) | https://d2l.ai/ |
| HF LLM course | https://huggingface.co/learn/llm-course |
| Unsloth notebooks | https://unsloth.ai/docs/get-started/unsloth-notebooks |

---

## How to use with this curriculum

1. Read the lesson (10–20 min).  
2. Open **one** tutorial from that row (don’t binge).  
3. Complete the lesson’s **Do this now** (in the lesson or below).  
4. Check yourself → [`ANSWERS.md`](./ANSWERS.md).
