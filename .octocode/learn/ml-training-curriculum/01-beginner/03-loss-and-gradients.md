# 03 — Loss, gradients, and the training loop

## The training loop (every modern stack)

```python
for batch in dataloader:
    preds = model(batch.x)           # forward
    loss = criterion(preds, batch.y) # scalar
    loss.backward()                  # gradients via autograd
    optimizer.step()                 # update θ
    optimizer.zero_grad()            # clear grads
```

Frameworks (PyTorch, JAX) compute gradients for you. You still must choose **loss**, **optimizer**, **LR**, **batch size**.

---

## Common losses

| Loss | When |
|------|------|
| **MSE / L1** | regression (continuous targets) |
| **Binary cross-entropy** | Bernoulli outputs |
| **Categorical cross-entropy** | classification / next-token |
| **Contrastive / InfoNCE** | embeddings, CLIP-style |
| **RL policy losses** | PPO, GRPO, etc. (advanced) |

For LLMs, the workhorse is **token-level cross-entropy** (often averaged over tokens in the batch, with padding masked).

---

## Gradients in one picture

Loss is a function of millions/billions of parameters. The **gradient** is the direction of steepest increase. We step **opposite** to decrease loss.

**Chain rule** through layers = backpropagation. Each layer gets `∂L/∂(its weights)`.

Intuition: if increasing weight `w` made the wrong token more likely, gradient says “decrease `w`.”

---

## Optimizers (practical)

| Optimizer | Notes |
|-----------|-------|
| **SGD + momentum** | classic; needs careful LR |
| **Adam / AdamW** | default for most deep learning; AdamW = Adam + decoupled weight decay |
| **Adafactor / Lion / …** | memory-friendly or research variants |

**Learning rate** is the most important hyperparameter. Too high → loss explodes / NaNs. Too low → crawls.

**Schedules:** warmup (start small LR), then cosine/linear decay. Almost all serious LLM runs use warmup.

---

## Batch size, epochs, tokens

| Term | Meaning |
|------|---------|
| **Batch size** | examples (or tokens) per update |
| **Epoch** | one pass over the dataset (less meaningful for huge streams) |
| **Steps** | number of optimizer updates |
| **Tokens seen** | best scale unit for LLM pretraining |

Larger batches → stabler gradients, need LR scaling rules; memory limited by GPU VRAM.

---

## Regularization (fight overfitting)

- **Weight decay** — penalize large weights  
- **Dropout** — randomly zero activations in training  
- **Data augmentation / mix** — more variety  
- **Early stopping** — stop when val worsens  
- **LoRA / fewer trainable params** — less capacity to overfit small SFT sets  

---

## Metrics ≠ loss

Loss guides training. You also track task metrics:

- accuracy, F1, perplexity (`exp(avg NLL)`)  
- for LLMs: win-rate, pass@k, SWE-bench, human prefs  

A model can have lower loss but worse product behavior (reward hacking — see advanced RL).

---

## Hardware reality check

| Goal | Rough hardware |
|------|----------------|
| Learn + tiny MLP | CPU / any GPU |
| Fine-tune 7B QLoRA | ~12–24 GB VRAM (or Unsloth/Colab) |
| Full fine-tune 7B | multi-GPU |
| Pretrain / RL on 70B–700B+ | industrial cluster |

Curriculum path: **learn theory → fine-tune small → understand large**.

---

## Check yourself

1. Write the 4-line training loop from memory.  
2. What does AdamW add vs plain Adam?  
3. Why mask padding tokens in the loss?


## Do this now

1. Watch [Karpathy micrograd](https://www.youtube.com/watch?v=VMj-3S1tku0) and pause to type along.
2. Or follow [Zero to Hero](https://karpathy.ai/zero-to-hero.html) lecture 1.

## Tutorials

- [micrograd video](https://www.youtube.com/watch?v=VMj-3S1tku0) · [d2l Autograd](https://d2l.ai/chapter_preliminaries/autograd.html)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`04-tokens-and-gpu-basics.md`](./04-tokens-and-gpu-basics.md) → [`../02-intermediate/00-from-rnn-to-attention.md`](../02-intermediate/00-from-rnn-to-attention.md)

## Sources

- [d2l — Optimization](https://d2l.ai/chapter_optimization/index.html)  
- [d2l — Autograd](https://d2l.ai/chapter_preliminaries/autograd.html)  
- [Karpathy — Zero to Hero (backprop)](https://karpathy.ai/zero-to-hero.html)
