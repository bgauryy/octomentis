# llms.txt Adoption Across Major Providers

> Survey of `/llms.txt` adoption — the [llmstxt.org](https://llmstxt.org) standard for making docs LLM-friendly. Checked April 2026.

## LLM Model Providers

| Provider | Status | URL | Size |
|----------|--------|-----|------|
| **Anthropic** | Yes | [platform.claude.com/llms.txt](https://platform.claude.com/llms.txt) | 109KB · 1113 lines |
| **OpenAI** | Yes | [developers.openai.com/llms.txt](https://developers.openai.com/llms.txt) | 77KB master + sub-indexes (API, Codex, Apps SDK, Commerce, Cookbook) |
| **Mistral AI** | Yes | [docs.mistral.ai/llms.txt](https://docs.mistral.ai/llms.txt) | Full doc index |
| **Cohere** | Yes | [docs.cohere.com/llms.txt](https://docs.cohere.com/llms.txt) | Versioned (v1/v2) |
| **AI21 (Jamba)** | Yes | [docs.ai21.com/llms.txt](https://docs.ai21.com/llms.txt) | Docs + API ref |
| **Perplexity** | Yes | [docs.perplexity.ai/llms.txt](https://docs.perplexity.ai/llms.txt) | 20KB · 118 lines |
| Google (Gemini) | **No** | 404 on all 8 domains (`ai.google.dev`, `cloud.google.com`, `developers.google.com`, `deepmind.google`…) | — |
| DeepSeek | **No** | 404 on all 6 domains (`deepseek.com`, `api-docs.deepseek.com`, `platform.deepseek.com`…) | — |
| xAI (Grok) | **No** | 404 on all 5 domains (`docs.x.ai`, `x.ai`, `api.x.ai`, `developers.x.ai`…) | — |
| Meta (Llama) | **No** (AI) | [developers.meta.com/llms.txt](https://developers.meta.com/llms.txt) exists but covers Horizon OS/VR/Wearables only. Llama AI docs (`llama.meta.com`, `ai.meta.com`) return 404 | — |

## Inference & Cloud Providers

| Provider | Status | URL | Size |
|----------|--------|-----|------|
| **NVIDIA** | Yes | [docs.nvidia.com/llms.txt](https://docs.nvidia.com/llms.txt) | Master index → per-product files (NIM, NeMo, CUDA, Jetson…) |
| **Fireworks AI** | Yes | [docs.fireworks.ai/llms.txt](https://docs.fireworks.ai/llms.txt) | 48KB · 366 lines |
| **Together AI** | Yes | [docs.together.ai/llms.txt](https://docs.together.ai/llms.txt) | 34KB · 238 lines |
| **RunPod** | Yes | [docs.runpod.io/llms.txt](https://docs.runpod.io/llms.txt) | 37KB · 268 lines |
| **Anyscale** | Yes | [docs.anyscale.com/llms.txt](https://docs.anyscale.com/llms.txt) | Sectioned with sub-indexes |
| **Groq** | Partial | [docs.groq.com/llms.txt](https://docs.groq.com/llms.txt) | Landing page, not structured index |
| **Cerebras** | Partial | [docs.cerebras.ai/llms.txt](https://docs.cerebras.ai/llms.txt) | Minimal — links to sub-docs |
| AWS Bedrock | No | — | — |
| Microsoft Azure | No | — | — |
| Hugging Face | No | — | — |
| SambaNova | No | — | — |

## Developer Tools & Frameworks

| Provider | Status | URL | Size |
|----------|--------|-----|------|
| **Vercel** | Yes | [vercel.com/llms.txt](https://vercel.com/llms.txt) | 343KB · 2004 lines |
| **LangChain** | Yes | [docs.langchain.com/llms.txt](https://docs.langchain.com/llms.txt) | 100KB · 819 lines |
| **Stripe** | Yes | [docs.stripe.com/llms.txt](https://docs.stripe.com/llms.txt) | 90KB · 645 lines |
| **Cloudflare** | Yes | [docs.cloudflare.com/llms.txt](https://docs.cloudflare.com/llms.txt) | Per-product sub-indexes + `llms-full.txt` |
| **Cursor** | Yes | [cursor.com/llms.txt](https://www.cursor.com/llms.txt) | Agent, CLI, help center. Multi-language |
| **GitHub** | Yes | [docs.github.com/llms.txt](https://docs.github.com/llms.txt) | API-based (search, article, pagelist endpoints) |
| **Databricks** | Yes | [docs.databricks.com/llms.txt](https://docs.databricks.com/llms.txt) | 30KB · 211 lines |

## Implementation Patterns

**Monolithic** — Single file with all docs (Anthropic, Stripe, LangChain)

**Hierarchical** — Master index linking to per-product sub-indexes (OpenAI, NVIDIA, Cloudflare)

**Full-text variant** — `llms-full.txt` with inlined content alongside the index (OpenAI Cookbook at 986KB, Cloudflare)

**API-based** — Structured endpoints instead of static file (GitHub)

## Notable Holdouts

Google, Meta, xAI, DeepSeek, AWS, Microsoft, Hugging Face — none serve `llms.txt` on any known domain.
