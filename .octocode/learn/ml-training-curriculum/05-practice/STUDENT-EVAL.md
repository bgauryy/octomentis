# Student evaluation — curriculum readiness

**Date:** 2026-07-09  
**Audience:** students using this pack as a self-study course  
**Verdict after fixes:** **READY for students** (with the caveats below)

---

## Scorecard

| Area | Score | Notes |
|------|-------|-------|
| Content accuracy (sampled) | Strong | Core claims match d2l / HF / Unsloth / papers cited |
| Beginner → advanced arc | Strong | Path is Data-before-FT; README warns about folder numbers |
| Navigation / Next links | Fixed | Neural-nets loop removed; Flow A Next chains aligned; intermediate linear |
| First LoRA entry | Fixed | Single ordered path: [`00-first-lora-path.md`](./00-first-lora-path.md) |
| Glossary | Fixed | A–Z, PEFT deduped, beginner terms added |
| Check yourself coverage | Good | All numbered lessons; practice helpers are reference-only |
| ANSWERS.md | Good | Matches Check yourself; includes `00-from-rnn` |
| Tutorials / Sources | Good | Numbered lessons + hands-on have Sources |
| Honest scope | Strong | README states what you can/can’t do at home |

---

## What was wrong (pre-fix)

1. README implied **every** file had Check yourself / Next / Tutorials — practice helpers don’t.  
2. `01-neural-nets` **Next** looped back to `00`.  
3. Conflicting first-LoRA orders (checklist “read BP first” vs Colab-first).  
4. Folder `03` before `04` trapped linear directory browsers.  
5. Glossary unsorted; PEFT duplicated; missing beginner terms.  
6. `00-from-rnn` lacked Check yourself (ANSWERS had a stub only).  
7. Data **Next** links conflicted with Flow A.

---

## How to study (student contract)

1. Open [`../README.md`](../README.md) → follow **stage order**, not folder sort.  
2. Want a weekend LoRA? → [`00-first-lora-path.md`](./00-first-lora-path.md) only.  
3. Full course? → Beginner → Intermediate (listed order) → Data Flow A → Advanced → Practice.  
4. After each lesson: attempt Check yourself → then [`ANSWERS.md`](./ANSWERS.md).  
5. Unknown word → [`../GLOSSARY.md`](../GLOSSARY.md).

---

## Remaining caveats (OK for v1)

- Folder names stay `03-advanced` / `04-data` (renaming would break links); README + Next links are the source of truth.  
- External Colab/notebooks can change; if a link 404s, use the TUTORIALS hub alternate.  
- GLM-5.2 / frontier sections are **case studies**, not homework you can reproduce at full scale.  
- Practice docs (`02-tool-map`, `03-transformer-reading-path`, RESOURCES) are maps, not lessons.

---

## Teacher / tutor notes (short)

- Prefer **one Next** primary target per lesson; secondary links labeled optional.  
- Smoke FT ≠ production FT: path separates Colab proof from checklist + BP.  
- Synthetic data always after seeds + normalize-again (Flow B).
