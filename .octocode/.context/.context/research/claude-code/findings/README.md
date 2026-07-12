# Findings — Not Submitted

These 7 findings were NOT submitted as standalone bounties. They are foundational research, delivery channels, candidates, or product-security issues.

Primary findings that back specific submissions were moved into `submissions/*/FINDING.md`.

| # | File | Original ID | Why Not Submitted |
|---|------|------------|-------------------|
| 1 | `01_classifier_architecture.md` | ISB-01 | Foundation doc — describes the classifier, all 18 BLOCK rules, override path. Feeds ALL submissions. |
| 2 | `02_mcp_delivery_channel.md` | ISB-03 | Delivery channel for classifier bypass. Overlaps S5 (WebFetch). Also copied to S5. |
| 3 | `03_hook_rce_product_security.md` | NF-01 | Product security issue (hooks = config-driven RCE). Not model safety — classifier not involved. |
| 4 | `04_subagent_delegation.md` | NF-04 | TOCTOU gap in classifier (checks spawn prompt, not runtime). Needs empirical PoC. **Best candidate for S8.** |
| 5 | `05_attack_chains.md` | — | 8 attack campaigns combining all findings. Cross-cutting overview. |
| 6 | `06_git_content_injection.md` | NF-15 | Git metadata injection (commits, branches, PRs). Feeds into S3 as variant. Also copied to S3. |
| 7 | `07_stdin_cli_injection.md` | NF-18 | CI/CD stdin injection + `--system-prompt-file` arbitrary file read. Needs empirical validation. |

## Where primary findings went

| Submission | FINDING.md source | Original ID |
|------------|------------------|------------|
| S1 `01_claudemd_user_intent_forgery/` | NF-11 + NF-06 (merged) | CLAUDE.md user-intent escalation |
| S2 `02_cron_classifier_bypass/` | ISB-02 | CronCreate persistence |
| S3 `03_system_reminder_spoofing/` | NF-16 (+ NF-15 as variant) | System-reminder tag spoofing |
| S4 `04_classifier_rule_injection/` | NF-12 | Classifier rule injection |
| S5 `05_webfetch_indirect_prompt_injection/` | NF-14 (+ ISB-03 as channel) | WebFetch IPI |
| S6 `06_memory_persistent_jailbreak/` | NF-17 | Memory persistence |
| S7 `07_token_budget_forced_allow/` | NF-13 | Fast classifier shortcut |
