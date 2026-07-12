# Reporting

Load when forming findings or writing the final security verdict.

## Severity

| Level | Meaning |
| ----- | ------- |
| `critical` | Confirmed malicious or highly dangerous with meaningful reachability |
| `high` | Strong exploit path or highly suspicious hidden behavior |
| `medium` | Suspicious, worth manual review, but intent or reachability is incomplete |
| `low` | Minor concern, unusual but likely legitimate |
| `info` | Notable but benign context |

## Confidence

| Level | Meaning |
| ----- | ------- |
| `confirmed` | 2+ evidence modes agree, or call chain traced end-to-end |
| `likely` | Strong indicators, one link unresolved |
| `uncertain` | Noisy hit, limited tooling, or incomplete reachability |

## Finding Format

Each material finding MUST include:

1. **Severity** — `critical` / `high` / `medium` / `low` / `info`
2. **Confidence** — `confirmed` / `likely` / `uncertain`
3. **Artifact & evidence** — file path, line numbers, tool output (e.g. `src/index.js:42 — eval(Buffer.from(...))`)
4. **Why it matters** — what capability this grants an attacker
5. **Impact path** — exploit or business impact chain (e.g. `postinstall → exec(decoded-payload) → exfil /Users/$USER/.ssh`)
6. **Strongest benign alternative** — the most plausible legitimate explanation
7. **Next validation step** — the one action that would confirm or refute the finding

## Final Verdict

Choose exactly one:

- `understood / no meaningful risk found` — evidence is sufficient to rule out meaningful threat
- `review recommended` — suspicious but not confirmed; human review warranted
- `high risk` — strong exploit path exists; describe containment steps
- `do not run / do not use` — confirmed malicious or critically dangerous
- `insufficient evidence` — tooling gaps or incomplete analysis prevent a verdict

For `high risk` or `do not run`: MUST include exact evidence, exploit path, data/capability at risk, and fastest containment step.

## Evidence Standards

- **`confirmed`** requires at least two: direct code read, structural AST match, LSP call-chain trace, runtime proof, or confirmed network/filesystem evidence.
- **`likely`** is acceptable for reporting if the missing link is clearly stated and the next validation step is concrete.
- **`uncertain`**: treat as a lead only. State it explicitly as a lead and document the escalation condition before including it in a report.
- Never escalate to `high` / `critical` on a single pattern match without flow proof.
