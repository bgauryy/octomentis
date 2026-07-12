# Guardrail Bypass & AI Security Resources

Resources for white-hat testing of AI guardrails, MCP servers, and agentic systems. Each entry tells you **when** to reach for it and **what** it gives you.

Pair with [Hacking Books Reference](./hacking-books-reference.md) for web/JS methodology and [Advanced Threat Patterns](./advanced-threat-patterns.md) for detection signatures.

---

## AI/LLM Red Teaming Frameworks

Use when testing LLM guardrails, safety filters, or alignment controls.

| Tool | When to use | What you get |
|------|-------------|-------------|
| [promptfoo/promptfoo](https://github.com/promptfoo/promptfoo) | Black-box LLM testing, CI/CD security pipelines | Automated red-team attacks, YAML configs, multi-provider comparison, plugin system for custom bypass techniques |
| [NVIDIA/garak](https://github.com/NVIDIA/garak) | Comprehensive LLM vulnerability scanning | 50+ probe families (jailbreak, injection, leakage, toxicity), extensible detectors, MCP wrapper via `EdenYavin/Garak-MCP` |
| [microsoft/PyRIT](https://github.com/microsoft/PyRIT) | Multi-turn attack strategies, enterprise red teaming | Orchestrated multi-step attacks, scoring engines, MITRE ATLAS mapping, Azure integration |
| [Tencent/AI-Infra-Guard](https://github.com/Tencent/AI-Infra-Guard) | MCP server scanning, agent security, full-stack AI red teaming | Dedicated MCP scan module, agent/skill analysis, LLM jailbreak benchmarks, AI infra vuln detection |

---

## Guardrail Implementations (Study to Bypass)

Study how guardrails work internally to find bypass paths.

| Tool | When to use | Bypass angles |
|------|-------------|--------------|
| [guardrails-ai/guardrails](https://github.com/guardrails-ai/guardrails) | Understanding programmable LLM guardrails | Input validation edge cases, output filter gaps, validator chain ordering weaknesses |
| [NVIDIA-NeMo/Guardrails](https://github.com/NVIDIA-NeMo/Guardrails) | Dialog flow constraint analysis (Colang DSL) | State machine bypass, topical rail boundaries, input vs output rail gaps, action injection points |
| [presidio-oss/hai-guardrails](https://github.com/presidio-oss/hai-guardrails) | TypeScript guardrail bypass (directly relevant to JS/Node AI apps) | Prompt injection guard evasion (encoding, unicode, split-payload), PII regex gaps |
| [superagent-ai/superagent](https://github.com/superagent-ai/superagent) | AI app security layer testing (prompt injection, data leak, harmful output) | Adversarial classifier evasion, exfiltration via encoding/steganography, output filter bypass |
| [asgeirtj/system_prompts_leaks](https://github.com/asgeirtj/system_prompts_leaks) | Reverse-engineering vendor guardrail design from leaked system prompts | Extracted prompts from ChatGPT, Claude, Gemini, Grok, Codex — reveals safety instructions, tool schemas, behavioral constraints, and hidden rules to study bypass surfaces |

---

## Prompt Injection Benchmarks & Labs

Use when measuring bypass success rates or practicing attacks.

| Tool | When to use | What you get |
|------|-------------|-------------|
| [lakeraai/pint-benchmark](https://github.com/lakeraai/pint-benchmark) | Evaluating prompt injection detection accuracy | Labeled injection dataset, evaluation metrics, false positive/negative analysis |
| [whitecircle-ai/circle-guard-bench](https://github.com/whitecircle-ai/circle-guard-bench) | Benchmarking LLM guard systems against jailbreaks | Guard model evaluation, jailbreak success rate measurement, cross-model comparison |
| [R3dShad0w7/PromptMe](https://github.com/R3dShad0w7/PromptMe) | Practicing OWASP LLM Top 10 vulnerabilities | Deliberately vulnerable LLM app with 10 mapped vulnerability classes |
| [SECFORCE/LLMGoat](https://github.com/SECFORCE/LLMGoat) | Hands-on OWASP LLM Top 10 exploitation practice | Intentionally vulnerable LLM environment for guardrail bypass training |

---

## MCP & Agent Security

Use when auditing MCP servers, agent configs, or tool-use chains.

| Tool | When to use | What you get |
|------|-------------|-------------|
| [HeadyZhang/agent-audit](https://github.com/HeadyZhang/agent-audit) | Static scanning of LLM agents and MCP configs | 49 rules mapped to OWASP Agentic Top 10, taint analysis, prompt injection detection in configs |
| [beelzebub-labs/beelzebub](https://github.com/beelzebub-labs/beelzebub) | Understanding how AI agents interact with deceptive environments | LLM-powered honeypot framework with MCP honeypot support, agent deception detection |

---

## Application & Node.js Pentest Tools

Use when actively testing web apps, APIs, or Node.js services.

| Tool | When to use | What you get |
|------|-------------|-------------|
| [KeygraphHQ/shannon](https://github.com/KeygraphHQ/shannon) | White-box JS/TS web app and API pentesting | Source code analysis, automated exploit generation, TypeScript-native Node.js testing |
| [vxcontrol/pentagi](https://github.com/vxcontrol/pentagi) | Fully autonomous multi-step penetration testing | AI-powered vulnerability chaining, multi-agent architecture, real-time attack reporting |
| [protectai/vulnhuntr](https://github.com/protectai/vulnhuntr) | Zero-shot source code vulnerability discovery via LLM | AI-driven vuln finding without pre-trained signatures |
| [j3ssie/osmedeus](https://github.com/j3ssie/osmedeus) | Full recon-to-exploitation workflow for bug bounty | Agentic orchestration engine, automated security pipeline |
| [yogeshojha/rengine](https://github.com/yogeshojha/rengine) | Automated web application reconnaissance | Configurable recon workflows, multi-tool orchestration |

---

## Vulnerability Scanners & Templates

| Tool | When to use | What you get |
|------|-------------|-------------|
| [projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates) | Automated scanning with known vulnerability patterns | 9000+ templates: XSS, SSRF, default creds, Express/Next.js/Nuxt fingerprinting, API misconfigs |
| [trickest/cve](https://github.com/trickest/cve) | Finding exploitable CVEs in JS/Node.js dependencies | All CVEs with PoC exploits, continuously updated |

---

## Payload Databases & Cheatsheets

| Resource | When to use | Key JS content |
|----------|-------------|---------------|
| [swisskyrepo/PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | Need specific exploit payloads for any web vuln class | XSS with WAF bypass, SSTI for Pug/EJS/Handlebars, `child_process` command injection, SSRF for cloud metadata, JWT attacks, prototype pollution chains, GraphQL injection |
| [HackTricks-wiki/hacktricks](https://github.com/HackTricks-wiki/hacktricks) | Comprehensive pentest methodology with exploitation steps | Node.js deserialization, Electron exploitation, browser extension security, JWT/session attacks, prototype pollution to RCE |
| [HackTricks-wiki/hacktricks-cloud](https://github.com/HackTricks-wiki/hacktricks-cloud) | Attacking Node.js apps on AWS/GCP/Azure | Cloud-specific attack techniques, metadata endpoint exploitation |

---

## Standards & Risk Taxonomies

| Resource | When to use | What you get |
|----------|-------------|-------------|
| [OWASP LLM Top 10](https://github.com/OWASP/www-project-top-10-for-large-language-model-applications) | Mapping findings to industry-standard AI risk categories | LLM01: Prompt Injection, LLM02: Sensitive Info Disclosure, LLM03: Supply Chain, LLM05: Improper Output Handling, LLM06: Excessive Agency, LLM07: System Prompt Leakage |
| [requie/LLMSecurityGuide](https://github.com/requie/LLMSecurityGuide) | OWASP GenAI Top 10 deep-dive with attack-to-defense mapping | Case studies, adversarial attack taxonomy, defense strategies |

---

## Secrets & Supply Chain

| Tool | When to use | What you get |
|------|-------------|-------------|
| [gitleaks/gitleaks](https://github.com/gitleaks/gitleaks) | Scanning git repos for leaked secrets | Pre-commit hooks, CI/CD scanning, custom regex rules, GitHub Actions integration |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | Agent-native security skills for AI systems | 753+ MITRE ATT&CK mapped cybersecurity skills for Claude Code, Copilot, OpenAI agents |

---

## Bypass Technique Quick-Reference

### AI Guardrail Bypass Categories

| Technique | Description | Tools |
|---|---|---|
| **Direct Jailbreak** | System prompt override, DAN roleplay, developer mode | promptfoo, garak |
| **Indirect Prompt Injection** | Instructions via external data (web pages, documents, tool outputs) | PyRIT, custom payloads |
| **Encoding Evasion** | Base64, ROT13, Unicode, leetspeak to bypass text filters | PayloadsAllTheThings |
| **Multi-Turn Escalation** | Gradual escalation across conversation turns | PyRIT orchestrators |
| **Tool/Agent Exploitation** | Abusing tool-use capabilities (file read, web fetch, code exec) | agent-audit, AI-Infra-Guard |
| **MCP Server Attacks** | Tool description injection, schema injection, tool poisoning | AI-Infra-Guard, agent-audit |
| **Context Window Manipulation** | Overwhelming context to push instructions out of attention | promptfoo, garak |
| **Output Format Exploitation** | Code blocks, translations, or formats that bypass output filters | Manual testing |
| **Token Smuggling** | Special tokens, control characters, model-specific tokens | garak probes |
| **Few-Shot Poisoning** | Examples that shift model behavior toward harmful outputs | PyRIT, promptfoo |

### Application-Level Bypass Techniques (Node.js / CLI / Web)

| Technique | Target | Tools |
|---|---|---|
| **Prototype Pollution** | JS object manipulation → RCE | PayloadsAllTheThings, HackTricks |
| **Command Injection** | `child_process.exec` with user input | nuclei-templates, shannon |
| **Path Traversal** | `fs.readFile` with unsanitized paths | nuclei-templates |
| **SSRF** | Server-side fetch to internal/metadata endpoints | PayloadsAllTheThings, nuclei |
| **Deserialization** | `node-serialize`, YAML unsafe load | HackTricks Node.js section |
| **Template Injection** | Pug, EJS, Handlebars SSTI | PayloadsAllTheThings SSTI section |
| **JWT Attacks** | Algorithm confusion, none algorithm, key brute-force | PayloadsAllTheThings JWT section |
| **npm Supply Chain** | Typosquatting, dependency confusion, install scripts | socket-cli, gitleaks |
| **Electron Escape** | nodeIntegration + contextIsolation bypass | HackTricks Electron section |
| **CLI Argument Injection** | Unsanitized args passed to shell commands | Manual + nuclei templates |

---

## Decision Guide

```
What are you testing?
│
├─ LLM/AI guardrails?
│  ├─ Black-box (API only) → promptfoo, garak
│  ├─ White-box (source access) → PyRIT, agent-audit, study guardrail source
│  └─ MCP server → AI-Infra-Guard, agent-audit
│
├─ Web application (JS/Node)?
│  ├─ Automated scanning → shannon, nuclei + templates
│  ├─ Manual testing → PayloadsAllTheThings, HackTricks
│  └─ Source review → semgrep, eslint-plugin-security
│
├─ npm package / supply chain?
│  ├─ Behavioral analysis → socket-cli, js-x-ray
│  ├─ Secret scanning → gitleaks
│  └─ Dependency audit → npm audit, snyk
│
├─ CLI tool?
│  ├─ Argument injection → manual + nuclei
│  ├─ Privilege escalation → HackTricks, GTFOBins
│  └─ Config injection → agent-audit for MCP CLIs
│
└─ Electron / Extension / Desktop?
   ├─ Electron → HackTricks Electron, contextIsolation bypass
   ├─ Extension → manifest analysis, webRequest interception
   └─ React Native → Metro bundle analysis
```
