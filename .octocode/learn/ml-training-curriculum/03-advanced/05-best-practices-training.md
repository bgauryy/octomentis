# Best practices — training models (general + pretrain)

Practical rules that survive across classical deep learning and LLM pretraining. Fine-tune-specific rules live in [`06-best-practices-finetuning.md`](./06-best-practices-finetuning.md).

---

## 1. Decide the job before the knobs

| Goal | Prefer |
|------|--------|
| Learn a new domain / format | Fine-tune (SFT/LoRA) a strong pretrained model |
| Teach preference / agent skill | SFT → DPO/RL with verifiers |
| Train from scratch | Only if no usable base exists and you have data + compute |

**Best practice:** don’t pretrain when fine-tuning solves it. Pretrain is for *new* bases or continued pretrain on huge domain corpora.

---

## 2. Data first, always

1. **Filter** before you scale — toxic/PII/license/junk destroy more than architecture saves.  
2. **Dedup** near-duplicates; overweighting one doc = memorization.  
3. **Mix** domains deliberately (code %, math %, chat %, …).  
4. **Decontaminate** against eval sets early.  
5. **Version** every dataset (hash + changelog).

Quality ≫ quantity until you’re at industrial scale.

---

## 3. Stability stack (almost every serious run)

| Practice | Why |
|----------|-----|
| **LR warmup** (≈5–10% of steps, or fixed warmup steps) | Stops early loss spikes / lasting damage ([warmup literature](https://proceedings.neurips.cc/paper_files/paper/2024/file/059445c2d5b3ef918079851628fef1d6-Paper-Conference.pdf)) |
| **Cosine or linear decay** after warmup | Converge without overshooting |
| **AdamW** as default | Decoupled weight decay; standard for Transformers |
| **Gradient clipping** (e.g. 1.0) | Survives bad batches |
| **BF16 / mixed precision** | Speed + stability on modern GPUs |
| **Fixed seed + logged config** | Reproducible comparisons |

Warmup is not optional folklore for large-batch / high-LR runs — skipping it can permanently hurt the run, not just “slow start.”

---

## 4. Batch size and learning rate

- Larger **effective batch** → stabler gradients.  
- Prefer `micro_batch × grad_accumulation × #GPUs` as the real batch.  
- **LR vs batch:** classic SGD often scales LR with batch size; many **AdamW LoRA/SFT** runs keep LR fixed and only change accumulation — don’t cargo-cult √N. Retune LR when you change batch a lot in pretrain.  
- If loss explodes: cut LR first, then check data NaNs / bad packing.  
- Pretrain papers (e.g. batch-size schedules on MoE) show stepwise batch growth with LR retuning — treat as advanced; start fixed.

---

## 5. Monitor the right signals

| Signal | Healthy | Bad |
|--------|---------|-----|
| Train loss | Smooth down | Spike, NaN, stuck flat |
| Val / held-out loss | Tracks train, then plateaus | Diverges up (overfit) |
| Grad norm | Bounded | Exploding |
| Throughput tokens/s | Stable | Sudden drop (IO / stragglers) |
| Eval tasks you care about | Periodic | Only watching loss |

**Best practice:** schedule **task evals** during long runs — loss alone lies (especially under reward hacking later).

---

## 6. Regularization without cargo cult

- **Weight decay** ~0.01–0.1 (don’t crank to kill learning).  
- **Dropout** — useful in some nets; for short LLM SFT often less critical than data mix.  
- **Early stop** on val when fine-tuning small sets.  
- For pretrain: rely more on **data scale + schedule** than heavy dropout.

---

## 7. Checkpointing & recovery

- Save every N steps + keep last K + best-by-val.  
- Store **optimizer state** if you resume; store **RNG** if you need bit-repro.  
- Smoke-test resume once before a week-long job.  
- Log: git commit, data hash, hyperparams, hardware, precision.

---

## 8. Parallelism & precision (scale)

| Technique | When |
|-----------|------|
| Data parallel | Default multi-GPU |
| Tensor / pipeline parallel | Model won’t fit one GPU |
| FSDP / ZeRO | Shard optimizer + params |
| Activation checkpointing | Trade compute for VRAM |
| FP8 (train/serve) | Throughput at frontier; validate quality |

**Best practice:** train and serve in compatible precision when possible (Unsloth: same-precision train/serve preserves accuracy better).

---

## 9. Common training failure modes

| Symptom | Likely cause | First fix |
|---------|--------------|-----------|
| Loss NaN in first steps | LR too high, no warmup, bad init | Lower LR, add warmup |
| Loss flat | LR too low, frozen wrong modules, data empty | Raise LR, check trainable params |
| Perfect train, bad val | Overfit / leakage | Less epochs, more data, decontam |
| Slow tokens/s | Seq packing, IO, small batch | Pack, prefetch, tune batch |
| OOM | Context too long, batch too big | Grad accum, checkpointing, shorter seq |

---

## 10. Pretrain-specific checklist

- [ ] Token budget and scaling-law estimate written down  
- [ ] Context-length schedule (short → long mid-train) planned  
- [ ] Packing + **attention/loss masks** defined (not just concatenation)  
- [ ] Eval suite frozen before launch  
- [ ] Checkpoint + resume tested  
- [ ] Cost cap / kill criteria set  

Individuals: prefer **continued pretrain** on domain text over full scratch when possible.

---

## Check yourself

1. Name three items in the “stability stack.”  
2. Why decontaminate before a long pretrain?  
3. What do you cut first when loss explodes?


## Do this now

1. Read [PyTorch mixed precision](https://pytorch.org/blog/what-every-user-should-know-about-mixed-precision-training-in-pytorch/).
2. In your next train run: log LR, grad norm, and val loss every N steps.

## Tutorials

- [PyTorch AMP blog](https://pytorch.org/blog/what-every-user-should-know-about-mixed-precision-training-in-pytorch/)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`06-best-practices-finetuning.md`](./06-best-practices-finetuning.md)

## Sources

- [PyTorch mixed precision](https://pytorch.org/blog/what-every-user-should-know-about-mixed-precision-training-in-pytorch/)
- [NVIDIA mixed precision guide](https://docs.nvidia.com/deeplearning/performance/mixed-precision-training/index.html)
- [Warmup / large-batch training notes](https://mbrenndoerfer.com/writing/learning-rate-warmup-linear-duration-large-batch-training)
