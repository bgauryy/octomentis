# RFC: Fix plan for all open CLI issues (P1–P6 + R1)

**Mode:** Implementation plan (RFC-shaped).
**Source:** [`CLI_ISSUES_PLAN.md`](../CLI_ISSUES_PLAN.md) open items, grounded in
[`CLI_OVERVIEW.md`](../CLI_OVERVIEW.md).
**Evidence base:** live `octocode search` runs (local v2.0.0 build, Homebrew
Node, 2026-06-22) + source reads cited as `file:line`. The seven already-fixed
issues (I4/I5, I6, I7, I9, I10, I20) are out of scope — see `CLI_ISSUES_PLAN.md` §3.

---

## Audit Reasoning — kept (2026-07-12)

**Status:** Partially implemented — P1–P5 landed with tests; P6 and R1 open.
**Why kept:** Two concrete, still-open fixes remain; deleting would lose the root-cause evidence for them.
**Evidence:** `buildDetailedDomains` (P1), `pagination.ts:46-61` (P2), `directToolCatalog.exec.ts` (P3), `pullRequestsParams`/`filterPullRequestsByMatch` (P4), pre-filled `next.graph` proof (P5) — all confirmed landed with matching tests.
**Remaining work:** P6 — uniform `{ truncated, total, next }` markers on repo/npm/PR preview fields (`isPartial` only exists for artifacts/binary today). R1 — echo `base` on the OQL materialize envelope (`materialize.ts:47-50` uses it only to absolutize `localPath`, never echoes it).

---

## Goal

Close every open CLI/OQL issue with the smallest correct change per issue,
without regressing the guardrails in `OCTOCODE_QUERY_LANGUAGE_PLAN.md` §8
(typed object, no predicate loss, AST≠LSP, freshness-first, bounded
materialization, visible budget/diagnostics).

## Evidence summary

| ID | Issue | Confirmed root cause (file:line) | Effort |
|----|-------|-----------------------------------|--------|
| P1 | `research view:"detailed"` inlines full domain arrays | `researchTargets.ts:1435-1443` embeds `data.files/dependencies/symbols/graphFacts` whole; only `packets` are paged (`packetPage`) | S |
| P2 | `totalPages` ≠ `ceil(totalItems/itemsPerPage)` | `pagination.ts:43-66` passes `totalPages` through verbatim while `totalItems` maps from a *different* unit (`totalFiles`/`totalMatches`); `mapCodeResult` emits one row **per match** (`resultMap.ts:51`) | S |
| P3 | `tools --scheme`/`context` load native engine | `tool-command.ts:23` imports `/direct`; `direct.ts:26` barrels `directToolCatalog.ts`, which at `:18` imports `@octocodeai/octocode-engine/lsp/manager` → native `.node` at module eval | M |
| P4 | PR body-only `matchString` ignored | `targetParams.ts:91-110` `pullRequestsParams` has no body-match field (`matchString` at `:136` belongs to `artifactsParams`); `.passthrough()` lets it through but `prContentFetcher.ts`/`prTransformation.ts` never filter on it | M |
| P5 | `research mode:"prove"` stays candidate, no internal LSP proof | by design — `targetParams.ts:158-160` documents it; proof lane lives only in `executeGraph`/`proveSymbolPacketWithLsp` (`researchTargets.ts:413-447`) | M |
| P6 | compact preview fields read as full data | repo/npm/PR preview slices built in `repoSearch.ts`, `providerMappers.ts`, `prContentFetcher.ts`; no `*Preview`/`truncated` naming convention | M |
| R1 | materialize envelope drops `base` | `materialize.ts:51-54` already absolutizes `localPath`; envelope `base` simply not echoed (cosmetic) | XS |

Out-of-scope adjacent finding (logged, not planned here): `target:"research"`
over a **Rust-only** folder returns zero source files — research inventory in
`research/analyze.ts` (`readSourceFiles`) is still JS/TS-only despite native
graph facts existing for other langs. Track separately (relates to plan G3 tail).

---

## Per-issue fix plans

### P1 — per-domain paging for `research view:"detailed"`  *(Phase 1, S)*

**Now:** `researchTargets.ts:1435-1443` spreads `manifests/files/dependencies/
symbols/graphFacts` as complete arrays when `view==="detailed"`. Verified live:
`files:31, symbols:202, graphFacts:32` in one row.

**Fix:** reuse the existing `packetPage(query, n)` helper (`researchTargets.ts:140`)
per domain. Replace the raw spread with sliced windows + per-domain page
metadata, e.g.:
```
filesPage:   { ...page, items: data.files.slice(start,end) }
symbolsPage: { ...page, items: data.symbols.slice(start,end) }
```
Keep counts in `summary` (already present) so the headline numbers survive.
Emit `next.page` continuations that advance all detailed domains together (or
a `domain` selector). Honor `select` so a narrow projection drops unrequested
domains entirely (closes the "rich records ignore narrow `select`" half of the
old I8 note).

**Blast radius:** one function (`researchTargets.ts` detailed branch); the
record envelope shape gains `*Page` keys. Consumers reading `data.files` get a
windowed array — update `OCTOCODE_SEARCH_EVAL.md` detailed-research rows and any
test asserting full arrays.

**Verify:** detailed research over `oql/` returns ≤ `itemsPerPage` entries per
domain; `next.page` walks them; `select:["symbols"]` omits files/deps.

### P2 — make `totalPages` consistent with `totalItems`/`itemsPerPage`  *(Phase 1, S)*

**Now:** `pagination.ts:toOqlPagination` forwards backing-tool `totalPages`
(`:43`) and `itemsPerPage` (`:49`) verbatim, but derives `totalItems` from
`totalFiles`/`totalMatches` (`:58-66`) — different unit. `mapCodeResult` rows
are per-match (`resultMap.ts:51`). Verified: `{itemsPerPage:5, totalItems:50,
totalPages:7}`.

**Fix:** in `toOqlPagination`, after resolving `totalItems` + `itemsPerPage`,
recompute `totalPages = Math.max(1, Math.ceil(totalItems/itemsPerPage))`
whenever both are numbers, instead of trusting the upstream value. Recompute
`hasMore` from `currentPage < totalPages`. Carry `totalItemsKind` (already
mapped at `:73`) so the unit is explicit. Unify the thinner
`resultMap.ts:26-37 toPagination` to delegate to (or share) the same
normalizer so both code/structure paths agree.

**Blast radius:** `pagination.ts` (all OQL targets route pagination through it)
+ `resultMap.ts`. Risk: backing tools whose `totalItems` is a *capped* estimate
(`totalItemsCapped` at `:76`) — when capped, keep `hasMore:true` and **don't**
assert an exact `totalPages` (omit or mark approximate). Add that guard.

**Verify:** for local code/content/structure and GitHub code/structure,
`ceil(totalItems/itemsPerPage) === totalPages` (uncapped) or `totalItemsCapped`
present with `hasMore` honest. Add a pagination unit test.

### P3 — native-free static schema/help for `tools --scheme` / `context`  *(Phase 2, M)*

**Now:** `tool-command.ts:23` statically imports from
`@octocodeai/octocode-tools-core/direct`. `direct.ts:26` re-exports
`directToolCatalog.js`, which imports the engine at `:18`. So even the pure
text path (`loadToolContent`, `formatDirectToolSchemaText`) drags in the
`.node` addon → fails on Codex.app Node before any output.

**Fix (recommended — A): pure subpath.** Add an engine-free export
`@octocodeai/octocode-tools-core/schema` exposing only `loadToolContent`
(`toolMetadata/state.ts`, already core-text-sourced) + the `format*SchemaText`
formatters + catalog *metadata* (names/categories), with **no** transitive
`@octocodeai/octocode-engine` import. Split `directToolCatalog.ts` into
`directToolCatalog.meta.ts` (pure: definitions, schema text, display fields) and
`directToolCatalog.exec.ts` (`executeDirectTool` + engine imports). `direct.ts`
keeps re-exporting both; the new `/schema` subpath exports only the meta module.
Then `tool-command.ts` imports schema/help/`--scheme`/`context` from `/schema`
and lazily `await import('.../direct')` only inside the execute path.

**Complementary (B):** move the `releaseAllPooledClients` import
(`directToolCatalog.ts:18`) and any other engine touch to a dynamic import at
call time, so even `/direct` is engine-free until a tool actually runs.

**Blast radius:** new package export (`package.json` `exports` map) + a file
split in tools-core + import-site change in `tool-command.ts`. Bundlers
(esbuild/rollup-dts per `[[tools-core-bundled-not-published]]`) must include the
new subpath. Keep `direct.ts` API unchanged for existing consumers.

**Verify:** `tools ghSearchCode --scheme` and `context` produce schema text
**without** loading `*.node` (assert via a Node run that stubs the engine path,
or run under Codex.app Node). Execution path still works under Homebrew Node.

### P4 — PR body `matchString` filtering  *(Phase 2, M)*

**Now:** no body-match param on PRs (`targetParams.ts:91-110`). `prContentFetcher.ts`
already fetches body/comments/reviews (`:114-268`) — the data exists, it's just
never filtered.

**Fix:** (1) add `matchString?: string` (and optional `matchScope?:
"body"|"comments"|"reviews"|"all"`) to `pullRequestsParams`. (2) Thread it into
the backing `ghHistoryResearch` PR path; in `prContentFetcher.ts`/
`prTransformation.ts` filter/spotlight matching PRs and trim non-matching body
sections (reuse the existing `windowPatch`/char-window logic in
`history.ts:17`). (3) Surface a `zeroMatches`/`partialResult` diagnostic when a
PR has no body match. Keep it a *content* filter, never a search-index claim.

**Blast radius:** `targetParams.ts`, PR fetch/transform files, scheme text
(`schemeText.ts` pullRequests params hint), CLI `pr` command help, docs. The raw
`ghHistoryResearch` tool schema also needs the field if parity is required.

**Verify:** `pullRequests {prNumber, matchString:"…"}` returns only matching
body slices; absent → `zeroMatches`; `content fetch.content.match` unaffected.

### P5 — decide `research mode:"prove"` auto-proof  *(Phase 2, M — decision first)*

**Now:** documented intentional split (`targetParams.ts:158-160`): `research`
prove requires `intent` but does not run LSP; `graph proof:"lsp"` is the proof
lane (`researchTargets.ts:413-447`). Matches plan G4/O6 "partial by design."

**Decision:** Option A (keep split, improve ergonomics) vs Option B (auto-escalate).
- **A (recommended):** keep `research` candidate-only; make the `next.semantic`/
  `next.graph` continuation it emits a *one-call* upgrade (pre-filled
  `proof:"lsp"` graph query for the current page's symbols). Cheapest, preserves
  the candidate/proof honesty boundary.
- **B:** add `research mode:"prove"` → internally call the graph proof step,
  returning `evidence.kind:"proof"` for resolved symbols. Higher cost per call,
  blurs the research/graph split, risks unbounded LSP fan-out.

**Blast radius (A):** continuation builder in `researchTargets.ts` + scheme text.
No envelope-kind change. **Verify:** `research mode:"prove"` emits an executable
`next.*` whose single run yields LSP-proven packets with bounded `proofLimit`.

### P6 — name/flag compact preview fields  *(Phase 2, M)*

**Now:** repo `topics`/`description`, npm `exports`/`bin`, PR body previews, and
suggestion lists are slices emitted under plain names (`repoSearch.ts`,
`providerMappers.ts`, `prContentFetcher.ts`) — agents can mistake a slice for
full data.

**Fix:** adopt one convention in the transformer/view layer
(`oql/transformers/*`): either suffix sliced fields (`exportsPreview`,
`bodyPreview`) or attach a sibling `{ truncated:true, total:N, next:{…} }`
marker, and document it once in `OCTOCODE_QUERY_LANGUAGE.md`. Prefer the marker
form (no field renames → smaller blast radius). Wire the marker through
`resultMap`/`transformers` so every preview carries it uniformly.

**Blast radius:** transformer/view layer + docs + eval rows; field renames would
ripple to consumers, so favor the additive marker. **Verify:** every preview
field in repo/npm/PR results carries a truncation marker with a real `total`
and an executable `next.*` to the full data.

### R1 — echo materialize `base` (optional)  *(low value)*

**Now:** `materialize.ts:51-54` already joins relative paths with `sc.base` and
returns absolute `localPath`/`repoRoot`; cross-repo handoff is agent-safe
(verified). Envelope-level `base` is just not surfaced.

**Fix:** only if a consumer needs it — echo `base` on the envelope alongside the
absolute `localPath`. Otherwise close as won't-fix (paths are already absolute).

---

## Alternatives considered

- **Do nothing:** P1/P2 actively mislead agents (token bloat, wrong page math);
  P3 blocks an entire runtime (Codex.app). Not acceptable for P1–P3.
- **One big "OQL envelope v2" rewrite:** rejected — P1/P2/P6 are independent,
  small, and individually verifiable; a unified rewrite couples them and breaks
  the live compatibility contract (guardrail §8 "current schemas remain the live
  contract").
- **P3 via lazy-load only (Option B alone):** insufficient if execution-path tool
  impls statically import the engine elsewhere; the pure subpath (A) is the
  robust guarantee, B is complementary.

## Sequencing

1. **Phase 1 (cheap, agent-felt):** P1, P2. Pure functions, unit-testable, no
   API surface change beyond additive `*Page`/consistent counts.
2. **Phase 2:** P3 (unblocks Codex.app), P4, P6. P3 first (highest user impact).
3. **Decision then build:** P5 — pick A vs B before coding.
4. **Optional:** R1.

Order within a phase is by dependency, not preference; P1/P2/P3 are independent
and can land in parallel.

## Risks & open questions

- **P2 capped totals:** some backing tools report estimated/capped `totalItems`;
  recomputed `totalPages` must not claim false precision — gate on
  `totalItemsCapped`.
- **P3 bundling:** the new pure subpath must be picked up by the esbuild/rollup
  bundles ([[tools-core-bundled-not-published]]) and the published `public.d.ts`.
- **P4 parity:** decide whether the raw `ghHistoryResearch` tool gets the same
  `matchString` field or it stays OQL-only (CLI/MCP schema-contract tests).
- **P5:** product call — is candidate-with-easy-upgrade (A) enough, or do agents
  need one-shot proof (B)?
- **P6:** marker vs rename — rename is cleaner long-term but breaks consumers;
  marker is safer now.

## Verification gates (all)

Per `OCTOCODE_QUERY_LANGUAGE_PLAN.md` §9: planner snapshots unchanged; pagination
returns a typed continuation per domain (P1, P2); diagnostics stay distinct
(P4 `zeroMatches`, P6 truncation markers); no predicate loss; AST≠LSP honesty
(P5); CLI/MCP schema parity (P3, P4). Add focused tests:
`tests/oql/pagination.test.ts` (P2), research-detailed paging (P1),
engine-free schema import (P3), PR match filter (P4).
