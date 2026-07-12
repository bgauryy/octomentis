# Check-yourself — answer key

Use after attempting questions yourself. Short answers only.

---

## 01-beginner

### 01-what-is-ml
1. **Parameters** = numbers that define the model; **loss** = how wrong; **optimizer** = how to update parameters.  
2. Tune hyperparameters / detect overfitting without touching the final test set.  
3. Pretrain → SFT → preference/RL (post-training).

### 02-distributions
1. A **categorical** distribution (probabilities over classes/tokens).  
2. Maximum-likelihood / cross-entropy for the true next token.  
3. Flattens the distribution → more random samples.

### 03-loss-and-gradients
1. forward → loss → backward → optimizer.step → zero_grad.  
2. Decoupled **weight decay** (regularization).  
3. Pads aren’t real tokens — including them pollutes the average loss / gradients.

### 04-tokens-and-gpu-basics
1. Tokenizer splits into subwords; multi-token spellings are common.  
2. Softmax → probabilities; logits are pre-softmax.  
3. Activations and (at decode) KV cache — both grow with seq length.

---

## 02-intermediate

### 00-from-rnn-to-attention
1. Sequential state + vanishing/exploding gradients make long-range credit assignment hard.  
2. Softmax-weighted mix of values from query–key similarity.  
3. Attention mixes all positions in parallel (no step-by-step recurrence for the mix).

### 01-neural-nets
1. Without nonlinearities, stacked linears = one linear map.  
2. Maps discrete IDs → dense vectors.  
3. Let gradients / information skip layers (`x + F(x)`).

### 02-attention
1. `softmax(QKᵀ/√d_k) V`.  
2. Keep softmax from saturating when dots grow with dimension.  
3. Looking at future tokens when predicting the next one.

### 03-transformers
1. Norm → attention → residual → norm → FFN → residual (pre-norm variant).  
2. Special tokens / role formatting must match or the model sees a different language.  
3. Base = raw LM; instruct = already aligned for chat — pick based on control vs convenience.

### 04-transformers-deep-dive
1. Encoder: self-attn + FFN. Decoder: masked self-attn + cross-attn + FFN.  
2. No token–token mixing inside FFN — each position independent.  
3. Decoder-only, causal self-attn, no separate encoder/cross-attn.

### 05-attention-deep-dive
1. Control dot-product scale so softmax stays well-behaved.  
2. Number of **KV heads** (and thus KV cache size).  
3. Memory traffic / materializing huge `n×n` matrices — not changing the math.  
4. Without positions, attention is bag-of-tokens (permutation issue).

---

## 03-advanced

### 01-pretraining
1. Next-token log-likelihood / cross-entropy.  
2. Garbage in → garbage parameters; filters beat architecture tweaks.  
3. Extend context / domain after main pretrain.

### 02-finetuning-lora
1. Usually **assistant** tokens only.  
2. Freeze base `W`; train low-rank `A,B`.  
3. When VRAM is tight but you still want LoRA-quality adaptation.

### 03-rlhf-and-preferences
1. SFT = imitate labels; DPO = learn from preference pairs; PPO = online RL vs reward.  
2. Optimizing the reward signal via shortcuts, not real skill.  
3. Keep policy near the SFT reference — stop reward hacking / drift.

### 04-glm-52-case-study
1. KV cache, kernels, and reliability under long messy traces — not just a config flag.  
2. Agents cheating verifiable rewards (leaking answers, curling solutions).  
3. Study the pipeline; fine-tune smaller open models with SFT/LoRA.

### 05-best-practices-training
1. e.g. warmup, AdamW, grad clip (any three from stability stack).  
2. Prevent train/eval overlap from faking progress.  
3. Lower learning rate (then check data / NaNs).

### 06-best-practices-finetuning
1. Scales LoRA update strength; `2r` is a common heuristic.  
2. Overfitting / memorization on static instruction sets.  
3. e.g. full FT first; many epochs on tiny data; ignore chat template.

### 07-coding-model-finetuning
1. **OSS-Instruct** = invent problems from real code snippets; **Evol-Instruct** = harden/complexify existing instructions.  
2. Matches how users ask; OpenCodeInstruct found NL→code beats code→code SFT formatting.  
3. When the base lacks your languages/APIs — else start with instruction SFT.  
4. e.g. LiveCodeBench, BigCodeBench, SWE-bench, MultiPL-E, internal CI.

---

## 04-data

### 01-digesting-data
1. Extract → normalize → filter → schema → dedup/decontam → split → pack/tokenize → train (any 5).  
2. Overlap makes metrics lie.  
3. When outputs are **verified** (tests, schema, humans).

### 02-datasets-for-finetuning
1. Measurable success criterion tied to the use case.  
2. Catch template/special-token bugs before wasting GPU time.  
3. Reproducibility and debugging (“which data made this?”).

### 03-packing-and-masks
1. Cross-example attention/loss leakage.  
2. Assistant (completion) tokens.  
3. Padding fills length; packing concatenates many examples efficiently **with masks**.

### 04-evaluation-literacy
1. Different tokenizations ⇒ different probability spaces.  
2. Code / generative tasks with multiple samples.  
3. Catch forgetting / regressions after fine-tunes.

### 05-normalize-and-clean
1. Normalize fixes encoding/format; synthetic rewrite creates new content.  
2. Exact = identical hash; fuzzy = near-dup (MinHash); semantic = same meaning.  
3. Cheap filters remove bulk junk before expensive model scoring.

### 06-synthetic-data
1. Distill = ToS/bias from teacher; self-improve = amplify own errors.  
2. Without critique/verify you train on fluent nonsense.  
3. Diverse, realistic, task-aligned seeds (human gold or real artifacts).

### 07-end-to-end-data-flows
1. Flow B (seeds → generate → filter → blend → SFT).  
2. Synth output is still messy — needs encoding/PII/dedup/schema.  
3. Version hashes, decontam, masks, real eval, PII/license gates.
