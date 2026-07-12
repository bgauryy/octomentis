# 04 — Coding model fine-tune checklist

Use with [`../03-advanced/07-coding-model-finetuning.md`](../03-advanced/07-coding-model-finetuning.md).

## Goal

- [ ] One sentence: completion vs chat-coder vs repo-agent vs private-code expert  
- [ ] Metric Z: e.g. HumanEval+ pass@1 **and** N internal tests green  

## Data

- [ ] Format is **NL → code** (not raw file dump)  
- [ ] Tests attached where possible; failing synthetics filtered or repaired  
- [ ] Decontaminated vs HumanEval / MBPP / LiveCodeBench / your suite  
- [ ] Secrets & licenses scrubbed  
- [ ] Optional: OSS-Instruct from your snippets; Evol pass for harder set  
- [ ] 10–20% general chat mix (unless pure completion CPT)  

## Train

- [ ] Code-capable base chosen (or justified general base)  
- [ ] QLoRA/LoRA; assistant-only loss; packing masks OK  
- [ ] `max_seq_length` fits tracebacks / multi-file snippets  
- [ ] 1–2 epochs; early-stop on val / held-out pass rate  

## Eval

- [ ] HumanEval+ or MBPP+ (or multilingual MultiPL-E)  
- [ ] Fresher set (LiveCodeBench / BigCodeBench) if available  
- [ ] Blind internal prompts with unit tests  
- [ ] Regression: general coding + chat still sane  

## Only if SFT is strong

- [ ] Sandbox for verifiable RL (0/1 tests)  
- [ ] Anti-hack: no answer-key / curl-solution shortcuts  
- [ ] SWE-style harness only with real infra budget  

## Do this now

1. Follow [EvalPlus](https://github.com/evalplus/evalplus) to score a baseline model.
2. Browse [Magicoder](https://github.com/ise-uiuc/magicoder) data format; draft 20 NL→code rows with tests.

## Tutorials

- [EvalPlus](https://github.com/evalplus/evalplus) · [Magicoder](https://github.com/ise-uiuc/magicoder) · [TUTORIALS.md](./TUTORIALS.md)

## Sources

- [`../03-advanced/07-coding-model-finetuning.md`](../03-advanced/07-coding-model-finetuning.md)  
- [Magicoder](https://arxiv.org/abs/2312.02120) · [OpenCodeInstruct](https://arxiv.org/abs/2504.04030) · [EvalPlus](https://github.com/evalplus/evalplus)
