# Glossary (quick)

Plain-English definitions for terms used across this curriculum. Sorted A–Z. Deep dives: each lesson’s **Sources** · hub: [`05-practice/RESOURCES.md`](./05-practice/RESOURCES.md) · answers: [`05-practice/ANSWERS.md`](./05-practice/ANSWERS.md).

| Term | Short definition |
|------|------------------|
| **Activation checkpointing** | Recompute activations in backward to save VRAM (trade compute). |
| **Attention** | Softmax-weighted mix of values from query–key scores. |
| **Autograd** | Automatic differentiation — computes gradients for you. |
| **Autoregressive** | Predict next token given previous tokens. |
| **Backpropagation** | Chain-rule algorithm that computes gradients through the network. |
| **Bahdanau attention** | Classic additive attention used with RNN seq2seq. |
| **Base model** | Pretrained LM before instruction/RL alignment (raw next-token). |
| **Base vs instruct** | Base = completion LM; instruct/chat = further tuned to follow instructions. |
| **BF16 / FP16 / FP8** | Lower-precision number formats for speed/memory. |
| **BPE** | Byte-Pair Encoding — builds a subword vocabulary. |
| **Causal mask** | Blocks attending to future tokens. |
| **Chat template** | Special-token formatting for roles; must match train/serve. |
| **Checkpoint** | Saved model (and often optimizer) state at a step. |
| **Continued pretrain (CPT)** | More next-token training on domain text/code (not chat SFT). |
| **Cross-attention** | Q from one sequence, K/V from another. |
| **Cross-entropy / NLL** | Loss ≈ `−log P(true token)`; NLL = negative log-likelihood. |
| **Decontamination** | Remove train examples that overlap eval sets. |
| **Decoder-only** | Transformer stack with causal self-attention only (typical LLMs). |
| **Deduplication** | Remove exact / fuzzy / semantic duplicate docs. |
| **Distillation (data)** | Teacher model writes synthetic data for a student. |
| **Distribution** | Assignment of probability to outcomes. |
| **DPO** | Direct preference optimization from chosen/rejected pairs. |
| **Effective batch** | `micro_batch × grad_accum × GPUs`. |
| **Embedding** | Input lookup: token ID → vector. |
| **Epoch** | One pass over a finite dataset. |
| **Evol-Instruct** | Evolve instructions to be harder/more complex (WizardCoder). |
| **FIM** | Fill-in-the-middle — complete a span given left+right context. |
| **Fine-tune** | Continue training a pretrained model on task data. |
| **FlashAttention** | Exact attention with IO-aware tiling (less HBM traffic). |
| **FSDP / ZeRO** | Shard model/optimizer state across GPUs. |
| **Genetic-Instruct** | Combine Evol mutation + Self-Instruct crossover (see OpenCodeInstruct). |
| **Gradient** | Direction to increase loss; we step opposite. |
| **Gradient accumulation** | Several micro-steps before one optimizer update. |
| **Gradient clipping** | Cap grad norm to stop explosions. |
| **GQA** | Grouped-Query Attention — several Q heads share KV heads. |
| **GRPO / ORPO / KTO / IPO** | Preference/RL algorithm variants (see RLHF chapter). |
| **HBM** | GPU high-bandwidth memory (where big tensors live). |
| **Heuristic filter** | Cheap rule-based quality gate (length, repetition, …). |
| **HumanEval / MBPP** | Classic Python function-synthesis benchmarks (+ = EvalPlus). |
| **Hyperparameter** | Training knob you set (LR, batch, epochs, LoRA rank) — not learned by GD. |
| **IndexShare / DSA / MTP** | GLM long-context / speculative-decoding techniques. |
| **Instruct model** | Checkpoint already SFT/aligned for chat-style instructions. |
| **KL divergence** | Distance between two distributions; RL keeps policy near reference. |
| **KV cache** | Stored keys/values for fast autoregressive decode. |
| **Learning rate (LR)** | Step size for parameter updates. |
| **LiveCodeBench** | Fresher competitive-programming-style code eval. |
| **LLM-as-judge** | Use an LLM to score/rank outputs (biased — spot-check). |
| **LM head / unembedding** | Linear map from hidden state → vocab logits (may be weight-tied). |
| **LoRA / adapter / PEFT** | Low-rank (or other) adapters; train few params on a frozen base. |
| **Logits** | Raw scores before softmax. |
| **Loss mask / ignore_index** | Positions excluded from the training loss. |
| **Mid-training** | Extra pretrain phase (e.g. longer context) after main pretrain. |
| **MinHash / LSH** | Fuzzy near-duplicate detection at scale. |
| **Mixed precision** | Train with BF16/FP16 compute + FP32 where needed. |
| **MLP / FFN** | Feed-forward sublayer inside a Transformer block. |
| **Mode collapse** | (Synth data) generator keeps producing near-identical tasks/answers. |
| **MoE** | Mixture of Experts — routed sparse FFNs. |
| **Mojibake** | Garbled text from wrong character encoding. |
| **MQA** | Multi-Query Attention — one shared KV head. |
| **Multi-head attention** | Several attention heads in parallel, then concatenated. |
| **Normalize (data)** | Fix encoding/format/schema without rewriting meaning. |
| **OOM** | Out of memory (usually GPU VRAM). |
| **OpenCodeInstruct** | Large verified Python instruction corpus (tests + judge; arXiv:2504.04030). |
| **Optimizer** | Algorithm that applies gradients (AdamW, SGD, …). |
| **OSS-Instruct** | Generate coding instructions inspired by open-source snippets (Magicoder). |
| **Overfitting** | Great train metrics, poor held-out — memorized instead of generalized. |
| **Packing** | Concatenate short examples into one sequence (**needs masks**). |
| **Padding mask** | Ignore pad positions in attention/loss. |
| **pass@k** | Fraction of problems solved by at least one of k samples. |
| **Perplexity** | `exp(average NLL)` — lower is better; not cross-tokenizer comparable. |
| **PII** | Personally identifiable information (emails, phones, …). |
| **PPO** | Proximal Policy Optimization (online RL). |
| **Pretrain** | Next-token training on huge corpora. |
| **QLoRA** | LoRA on a quantized frozen base. |
| **RAG** | Retrieve documents at inference instead of baking facts into weights. |
| **Reference model** | Frozen SFT policy used as KL anchor in RL/DPO setups. |
| **Residual connection** | `x + F(x)` skip path — helps deep nets train. |
| **Reward hacking** | Optimizing the reward without solving the real task. |
| **Reward model (RM)** | Model that scores completions for RLHF. |
| **RLHF** | Reinforcement learning from human (or AI) feedback. |
| **RMSNorm** | Lightweight normalization used in many modern LLMs. |
| **RNN** | Recurrent net — processes tokens sequentially (pre-Transformer). |
| **RoPE** | Rotary Position Embedding — rotate Q/K by position. |
| **Rollout** | Generated trajectory (tokens/actions) for RL. |
| **Scaled dot-product** | `(QKᵀ)/√d_k` scoring. |
| **Scaling laws** | Empirical curves relating loss to params/data/compute. |
| **Self-attention** | Q, K, V all from the same sequence. |
| **Self-Instruct** | Bootstrap instructions from seeds + model generations. |
| **Semantic dedup** | Drop paraphrases via embedding similarity. |
| **SentencePiece** | Common subword tokenizer toolkit. |
| **Seq2seq** | Encoder–decoder mapping one sequence to another. |
| **SFT** | Supervised fine-tuning on instruction data. |
| **Softmax** | Maps logits → categorical distribution. |
| **Speculative decoding** | Draft tokens with a small model; verify with the big one. |
| **SWE-bench** | Repo-level issue-fixing benchmark for coding agents. |
| **SwiGLU / GELU / SiLU** | Activation functions used in FFNs. |
| **Synthetic data** | Model- or simulation-generated training examples. |
| **Teacher / student** | Strong generator model vs model being trained. |
| **Teacher forcing** | Train with gold previous tokens, not the model’s own samples. |
| **Temperature / top-k / top-p** | Decoding knobs that reshape the next-token distribution. |
| **Tokenizer** | Text ↔ token ID conversion. |
| **Transformer** | Architecture of attention + FFN blocks. |
| **Underfitting** | Poor train and val — model too weak or undertrained. |
| **Validation set** | Held-out data for tuning, not final report. |
| **VRAM** | GPU memory capacity. |
| **Warmup** | Gradually raise LR at the start of training. |
| **Weight decay** | Regularizer that penalizes large weights (AdamW). |
| **Weight tying** | Share input embedding and LM-head weights. |

Tutorials: [`05-practice/TUTORIALS.md`](./05-practice/TUTORIALS.md)
