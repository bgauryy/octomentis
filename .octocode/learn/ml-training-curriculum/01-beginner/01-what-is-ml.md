# 01 — What is machine learning?

## One sentence

**Machine learning** = write a program that **improves from examples** by adjusting **parameters** to reduce **error** (or increase **reward**).

You do **not** hand-code every rule. You hand-code:

1. a **model family** (what shapes of functions are allowed),
2. a **loss** (how wrong is wrong),
3. an **optimizer** (how to nudge parameters),
4. and you feed **data**.

---

## Three learning styles

| Style | Input | Output | Example |
|-------|-------|--------|---------|
| **Supervised** | `(x, y)` pairs | predict `y` from `x` | image → “cat”; prompt → answer |
| **Unsupervised / self-supervised** | `x` only | structure / next piece of `x` | next-token prediction on text |
| **Reinforcement** | state, action, reward | policy that maximizes reward | agent coding until tests pass |

Modern LLMs use **all three** across their life:

1. **Pretrain** (self-supervised next-token)
2. **SFT** (supervised instruction/response)
3. **RL / preference** (reward from humans or verifiers)

---

## Parameters, predictions, loss

- **Parameters θ** — numbers inside the model (weights). Training = changing θ.
- **Forward pass** — compute prediction `ŷ = f_θ(x)`.
- **Loss L** — scalar “how bad”: e.g. cross-entropy between predicted distribution and true label.
- **Backward pass** — compute gradients `∂L/∂θ` (how to change each weight).
- **Update** — `θ ← θ − η · gradient` (η = learning rate).

Repeat over many batches → model fits the data distribution (ideally generalizes).

---

## Train vs validation vs test

| Split | Purpose |
|-------|---------|
| **Train** | update θ |
| **Validation** | tune hyperparameters, catch overfitting |
| **Test** | final report — touch once |

**Overfitting:** great train loss, bad val/test → memorized, didn’t generalize.  
**Underfitting:** bad everywhere → model too weak or undertrained.

---

## Classical ML vs deep learning vs LLMs

| Era | Typical model | Data scale |
|-----|---------------|------------|
| Classical | linear/logistic regression, trees, SVM | thousands–millions of features/rows |
| Deep learning | CNNs, RNNs, Transformers | large labeled or unlabeled corpora |
| LLMs | huge Transformers | trillions of tokens + post-training |

Same math skeleton (loss + gradients). Scale + architecture + data quality change what emerges.

---

## What “training a model” means in practice

1. Collect / clean data  
2. Choose architecture + init (or start from a **pretrained** checkpoint)  
3. Choose loss + optimizer + batch size + LR schedule  
4. Run training loop; monitor train/val metrics  
5. Evaluate on held-out tasks  
6. Ship (quantize, serve) or continue with fine-tuning / RL  

For most people today: **start from a pretrained open model**, then **fine-tune** — don’t train from scratch.

---

## Check yourself

1. What are parameters, loss, and optimizer each for?  
2. Why do we need a validation set?  
3. Name the three stages of modern LLM training.


## Do this now

1. Skim [d2l Preliminaries](https://d2l.ai/chapter_preliminaries/index.html) and open one Colab section.
2. Watch [3Blue1Brown — What is a neural network?](https://www.youtube.com/watch?v=aircAruvnKk) (≈20 min).

## Tutorials

- [d2l.ai](https://d2l.ai/) · [3Blue1Brown neural nets playlist](https://www.youtube.com/playlist?list=PLZHQObOWTQDNU6R1_67000Dx_ZCJB-3pi)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`02-distributions.md`](./02-distributions.md) — the language models speak in: probability.

## Sources

- [d2l.ai — Dive into Deep Learning](https://d2l.ai/) (intro + supervised learning chapters)  
- [Karpathy — Neural Networks: Zero to Hero](https://karpathy.ai/zero-to-hero.html)
