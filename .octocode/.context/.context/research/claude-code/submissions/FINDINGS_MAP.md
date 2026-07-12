# Findings → Submissions Map

> Post-reorganization. Primary findings live inside each `submissions/*/FINDING.md`.
> Non-submitted findings remain in `findings/` with concise names.

## Structure

```
submissions/
  01_claudemd_user_intent_forgery/
    FINDING.md              ← NF-11 + NF-06 (CLAUDE.md user-intent escalation)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/
  02_cron_classifier_bypass/
    FINDING.md              ← ISB-02 (CronCreate persistence)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/
  03_system_reminder_spoofing/
    FINDING.md              ← NF-16 (system-reminder tag spoofing)
    FINDING_GIT_VARIANT.md  ← NF-15 (git content injection — delivery variant)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/
  04_classifier_rule_injection/
    FINDING.md              ← NF-12 (classifier rule injection)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/
  05_webfetch_indirect_prompt_injection/
    FINDING.md              ← NF-14 (WebFetch IPI)
    FINDING_MCP_CHANNEL.md  ← ISB-03 (MCP delivery channel)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/
  06_memory_persistent_jailbreak/
    FINDING.md              ← NF-17 (memory persistence)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/
  07_token_budget_forced_allow/
    FINDING.md              ← NF-13 (fast classifier shortcut)
    BOUNTY.md, EXPLANATION.md, VALIDATION.md, WHY_BUG.md, POC/

findings/                     (not submitted — research backlog)
  01_classifier_architecture.md   ← ISB-01 (foundation, feeds all)
  02_mcp_delivery_channel.md      ← ISB-03 (also in S5)
  03_hook_rce_product_security.md ← NF-01 (product security, not model safety)
  04_subagent_delegation.md       ← NF-04 (candidate for S8)
  05_attack_chains.md             ← 8 campaigns combining all findings
  06_git_content_injection.md     ← NF-15 (also in S3)
  07_stdin_cli_injection.md       ← NF-18 (CI/CD, needs validation)
```

## Cross-references

| Submission | Primary Finding | Secondary | Cross-cutting |
|------------|----------------|-----------|---------------|
| S1 | NF-11 + NF-06 | NF-13 (fast-path amplifier) | ISB-01, attack chains |
| S2 | ISB-02 | NF-17 (memory self-replication) | ISB-01, ISB-03 |
| S3 | NF-16 | NF-15 (git variant) | NF-11, NF-14 |
| S4 | NF-12 + NF-13 | NF-11 (chain amplifier) | ISB-01 |
| S5 | NF-14 | ISB-03 (MCP channel), NF-16 | — |
| S6 | NF-17 | ISB-02 (cron self-replication) | NF-11 |
| S7 | NF-13 | NF-11, NF-12 (context biasing) | ISB-01 |

## Next candidates (from findings/)

| Priority | Finding | Effort | Potential |
|----------|---------|--------|-----------|
| 1 | `04_subagent_delegation.md` (NF-04) | HIGH — needs empirical PoC | CRITICAL if demonstrated |
| 2 | `07_stdin_cli_injection.md` (NF-18) | LOW — quick CLI test | HIGH for CI/CD angle |
| 3 | `03_hook_rce_product_security.md` (NF-01) | LOW | Product security track (not model safety bounty) |
