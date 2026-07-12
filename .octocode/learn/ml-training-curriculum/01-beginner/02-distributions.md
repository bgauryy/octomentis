# 02 — Probability distributions (what models actually output)

## Why this matters

Neural nets rarely spit out a single “answer” as a hard fact. They spit out **numbers that define a probability distribution**, then we **sample** or take the **argmax**.

If you understand distributions, attention’s softmax, language-model loss, and temperature sampling all click.

Canonical intro for softmax-as-distribution: [Dive into Deep Learning — Softmax Regression](https://d2l.ai/chapter_linear-classification/softmax-regression.html).

---

## Vocabulary

| Term | Meaning |
|------|---------|
| **Random variable** | quantity with uncertain value (e.g. next token) |
| **Distribution** | assignment of probability to each possible value |
| **PMF** | probability mass function (discrete) — `P(X = k)` |
| **PDF** | probability density (continuous) — density, not probability |
| **Support** | set of values that can occur |
| **Expectation E[X]** | average value under the distribution |
| **Entropy** | uncertainty / “surprise budget” of a distribution |

Rules every discrete distribution must obey:

- `P(x) ≥ 0` for all x  
- `Σ_x P(x) = 1`

---

## Distributions you will meet constantly

### Bernoulli — coin flip

- Support: `{0, 1}`  
- Parameter: `p = P(X=1)`  
- Use: binary classification, dropout masks, success/fail rewards  

### Categorical — dice with K faces

- Support: `{1…K}`  
- Parameters: probabilities `p₁…p_K` summing to 1  
- Use: **next-token prediction** (vocab size K), multi-class classification  

### Softmax — how we *make* a categorical from raw scores

Given logits (raw scores) `o₁…o_K`:

```
P(i) = exp(o_i) / Σ_j exp(o_j)
```

Properties:

- all `P(i) > 0` and sum to 1  
- larger logit → larger probability  
- **argmax of P = argmax of o** (ordering preserved)

This is exactly what an LLM does over its vocabulary at each step.

### Gaussian (Normal) — continuous bell curve

- Parameters: mean `μ`, variance `σ²`  
- Use: regression noise models, weight init, VAEs, diffusion (advanced)  

### Binomial / Multinomial

- Counts of Bernoulli / Categorical trials  
- Useful for thinking about batches of labels  

---

## Temperature, top-p, and “creativity”

After softmax, sampling controls reshape the categorical:

| Knob | Effect |
|------|--------|
| **Temperature T** | divide logits by T before softmax. High T → flatter (more random). Low T → peakier (more greedy). |
| **top-k** | keep only k largest probs, renormalize |
| **top-p (nucleus)** | keep smallest set whose mass ≥ p, renormalize |

Same model, different **sampling distribution** → different behavior. Training usually uses the full softmax + cross-entropy; decoding uses these knobs.

---

## Cross-entropy = “how surprised was the model?”

If true label is class `y` (one-hot), and model predicts `P`:

```
L = − log P(y)
```

- If `P(y)` is near 1 → loss near 0  
- If `P(y)` is tiny → loss huge  

Training an LLM = repeatedly: predict next-token distribution, compute `−log P(true next token)`, backprop.

This is **maximum likelihood** under a categorical model.

---

## Distributions inside attention

Attention weights are also a **categorical distribution over positions**:

```
weights = softmax(scores / √d)
output  = Σ_j weights_j · Value_j
```

So: “distributions” aren’t only at the final token head — they’re the soft routing mechanism inside the net.

---

## Check yourself

1. Softmax turns logits into what kind of distribution?  
2. Why is next-token loss `−log P(correct token)`?  
3. What does raising temperature do to the distribution?


## Do this now

1. Open [d2l Softmax Regression](https://d2l.ai/chapter_linear-classification/softmax-regression.html) → Colab.
2. In a notebook, compute `softmax([2.0, 1.0, 0.1])` by hand vs `torch.softmax`.

## Tutorials

- [d2l Softmax + Colab](https://d2l.ai/chapter_linear-classification/softmax-regression.html)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

[`03-loss-and-gradients.md`](./03-loss-and-gradients.md) — how training actually moves parameters.

## Sources

- [d2l — Softmax Regression](https://d2l.ai/chapter_linear-classification/softmax-regression.html)  
- [Wikipedia — Cross-entropy](https://en.wikipedia.org/wiki/Cross-entropy)
