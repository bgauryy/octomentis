# 05 — Normalize & clean data (flows)

Turning messy raw text/code into **training-ready** rows. Complements [`01-digesting-data.md`](./01-digesting-data.md).

Canonical processing stack (industry practice): download → clean → heuristic filter → dedup → model filter / PII → blend → tokenize. See [NVIDIA — Mastering LLM Techniques: Data Preprocessing](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/) and web-scale recipes like [FineWeb](https://arxiv.org/abs/2406.17557).

### First SFT fast path (skip web-scale stages)

For a few hundred–thousand chat/code rows you already own:

1. UTF-8 + whitespace / HTML cleanup  
2. PII / secrets scrub  
3. Length + empty-turn heuristics  
4. Exact dedup on prompts (fuzzy/semantic optional)  
5. Decontam vs your eval prompts  
6. Schema → chat JSON → pack/mask → tokenize  

Skip language-ID drama, FineWeb-scale fuzzy/semantic dedup, and model quality classifiers until you’re on noisy web dumps.

---

## Worked mini-example (10 → 7 rows)

Imagine 10 raw ticket lines → SFT JSONL:

| Gate | Count | What happened |
|------|------:|---------------|
| Raw | 10 | 1 mojibake (`cafÃ©`), 1 API key in body, 2 empty, 2 duplicate prompts |
| UTF-8 + PII scrub | 10 | Fixed encoding; redacted key |
| Heuristic (drop empty / too short) | 8 | Removed 2 empties |
| Exact dedup on user text | 7 | Kept one of each duplicate prompt |
| Decontam | 7 | None matched frozen eval (or drop if one did) |

Final row shape:

```json
{"messages":[{"role":"user","content":"Reset password for café app"},{"role":"assistant","content":"1. Open Settings…"}]}
```

Log **drop counts per gate**. Chat **template** applies at **tokenize** time, not during scrub.

---

## End-to-end normalize flow

```
Raw dump (logs, WARC, git, tickets, PDFs…)
  │
  ├─1─ Extract / convert          → utf-8 text or JSONL/Parquet
  ├─2─ Unicode & encoding fix     → no “cafÃ©”
  ├─3─ Language ID / split        → keep target langs
  ├─4─ Structural normalize       → newlines, whitespace, HTML→text
  ├─5─ PII / secrets scrub        → emails, keys, phones
  ├─6─ Heuristic quality filters  → length, repetition, boilerplate
  ├─7─ Dedup (exact → fuzzy → semantic)
  ├─8─ Toxicity / safety filters  (as required)
  ├─9─ License / ToS gate
  ├─10 Decontaminate vs eval
  ├─11 Schema transform           → chat / CPT / preference JSON
  ├─12 Split train/val + version hash
  └─13 Pack / tokenize + masks    → see 03-packing-and-masks.md
```

Skip stages only with a written reason (e.g. already-clean internal JSONL).

---

## What “normalize” means (concrete)

| Step | Do this | Why |
|------|---------|-----|
| **Encoding** | Force UTF-8; fix mojibake / broken Unicode | Models hate garbled bytes |
| **Whitespace** | Collapse crazy runs; keep meaningful newlines in code | Stable tokenization |
| **HTML / Markdown** | Strip tags or convert to plain/md consistently | One format per dataset |
| **Line endings** | `\n` everywhere | Cross-OS dumps |
| **Code** | Keep syntax; optional `black`/`prettier` only if product wants that style | Don’t “fix” code into a style you don’t ship |
| **Chat turns** | One role schema (`system/user/assistant`); drop empty turns | Template match |
| **Numbers / dates** | Usually leave as-is unless domain needs canonical form | Over-normalizing hurts |
| **URLs** | Optionally normalize/strip tracking params (pretrain); keep if task needs them | FineWeb-style URL hygiene |

**Normalize ≠ paraphrase.** Don’t rewrite meaning in this stage — that’s synthetic generation ([`06-synthetic-data.md`](./06-synthetic-data.md)).

---

## Heuristic filters (fast, cheap)

From NeMo Curator–style practice:

| Filter | Drop if… |
|--------|----------|
| Word / char count | Too short to be useful or absurdly long |
| Repetition / n-gram | Copy-paste spam, keyboard mashing |
| Boilerplate | Cookie banners, nav chrome, “lorem ipsum” |
| Symbol ratio | Mostly punctuation / binary garbage |
| Language confidence | Wrong language for this shard |

**Cascade** filters (cheap first) and log **how many** each stage removes — silent 90% drops are a bug.

---

## Deduplication (three levels)

| Level | Method | Catches |
|-------|--------|---------|
| **Exact** | Hash full doc | Identical copies |
| **Fuzzy** | MinHash + LSH + Jaccard | Near-dupes, reformats |
| **Semantic** | Embeddings + cluster / similarity | Paraphrases, translations of same idea |

Dedup reduces overfitting and wasted tokens ([Lee et al. dedup](https://arxiv.org/abs/2107.06499); FineWeb-scale pipelines).

For **SFT**, also dedupe on **prompt** (same question, many answers → keep best or preference pair).

---

## PII & secrets

| Action | Tools / idea |
|--------|----------------|
| Redact emails, phones, SSNs | Regex + NER / Presidio-class tools |
| Strip API keys, tokens | gitleaks / trufflehog on code |
| Drop customer dumps without consent | Policy gate before train |
| Log redaction rate | Prove the scrub ran |

Training on secrets = security incident + model that regurgitates them.

---

## Model-based quality (optional but powerful)

After heuristics:

- Small **quality classifier** (keep “textbook-like” / high educational value — Phi-style intuition)  
- Toxicity / jailbreak classifiers if product needs them  
- For code: **parse / typecheck / run tests**  

Web-scale: FineWeb shows careful filtering of Common Crawl beats dumping raw crawl ([arXiv:2406.17557](https://arxiv.org/abs/2406.17557)).

---

## Blend & shuffle

- Mix sources with **explicit ratios** (code %, docs %, chat %, general)  
- Shuffle so one domain doesn’t dominate early steps  
- Version the blend recipe with the dataset hash  

---

## Mini checklist

- [ ] UTF-8 + language ID done  
- [ ] PII/secrets scrubbed; rate logged  
- [ ] Heuristics + dedup applied; drop counts logged  
- [ ] Decontam vs frozen eval  
- [ ] Schema matches train objective (CPT vs SFT vs prefs)  
- [ ] Dataset id + hash recorded  

---

## Check yourself

1. Normalize vs synthetic rewrite — difference?  
2. Exact vs fuzzy vs semantic dedup — one line each.  
3. Why cascade cheap filters before model-based ones?


## Do this now

1. Take 10 messy text rows; apply UTF-8 fix + a length filter; log drop counts (use the mini-example table).
2. Skim [NVIDIA data preprocessing](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/).

## Tutorials

- [NVIDIA preprocessing](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/) · [FineWeb blog](https://huggingface.co/spaces/HuggingFaceFW/blogpost-fineweb-v1)
- Hub: [`../05-practice/TUTORIALS.md`](../05-practice/TUTORIALS.md)

## Next

**Flow A:** [`02-datasets-for-finetuning.md`](./02-datasets-for-finetuning.md) → packing → eval → train.  
Optional Flow B: [`06-synthetic-data.md`](./06-synthetic-data.md) · map: [`07-end-to-end-data-flows.md`](./07-end-to-end-data-flows.md)

## Sources

- [NVIDIA — Data preprocessing for LLMs](https://developer.nvidia.com/blog/mastering-llm-techniques-data-preprocessing/)  
- [FineWeb (arXiv:2406.17557)](https://arxiv.org/abs/2406.17557)  
- [Deduplicating training data (arXiv:2107.06499)](https://arxiv.org/abs/2107.06499)  
- [NeMo Curator](https://docs.nvidia.com/nemo/curator/) (tooling reference)
