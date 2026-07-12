# AutoWiki for Octocode skills — Decision Brief

**Date:** 2026-07-07
**Question:** How can Octocode leverage the "AutoWiki" pattern (AI-generated, continuously-refreshed repo docs) for `octocode-research` and one other skill?

## Framing

"AutoWiki" = AI-generated, structured, hyperlinked-to-code documentation that
refreshes on every push (via `git diff`) and is surfaced to agents through a
pointer in `AGENTS.md`/`CLAUDE.md`. Prior art researched: Factory AutoWiki
(multi-agent generation pipeline, GitHub Wiki + in-repo `droid-wiki/` + web
viewer), LangChain OpenWiki (open-source CLI, `openwiki/` folder, scheduled
GitHub Actions `--update` runs), Devin DeepWiki (`.devin/wiki.json` steering
file, public `deepwiki.com`), Google Code Wiki (continuously regenerated,
chat-integrated).

## Verdict: narrow — consume + detect, don't generate

Building a competing multi-agent wiki generator inside Octocode is out of
scope (duplicates existing, well-funded products) and high-risk (generation
pipelines are exactly the kind of thing that goes stale and erodes trust
faster than no doc at all). The value Octocode can add without new
infrastructure is narrower and higher-confidence:

1. **`octocode-research`** — when a wiki/doc artifact already exists in a
   target repo (`ARCHITECTURE.md`, `droid-wiki/`, `openwiki/`,
   `.devin/wiki.json`, GitHub Wiki, DeepWiki/Code Wiki page), treat it as a
   fast orientation lead in the router — not a new evidence grade. Read it
   first for named entry points, then verify any specific claim through the
   normal lexical/structural/semantic loop.
2. **`octocode-awareness`** — the harness already collects `edit_log` (every
   file edit, with session/task linkage) and has a `mine → propose → validate
   → apply` harness loop. Compare a doc's own last `edit_log` timestamp
   against edit activity in the source directories it describes; when drift
   crosses a threshold, emit a `harness_log` `propose` event
   (`failure_signature: "doc-staleness"`) — the same shape failure-mined
   proposals already use, so `exportHarness()` surfaces doc-refresh
   candidates with zero new plumbing.

## Why this scope

- No new tables, no generation pipeline, no external dependency.
- Doc staleness detection is opt-in per doc (explicit `{docFile, sourceDirs}`
  targets) — never automatic for every `.md` file in a repo, avoiding noise.
- The router change is additive: existing branches are untouched; the new
  branch only fires when a wiki/doc artifact is already present.

## Risks

- A stale-but-confident wiki page is worse than no page — the router branch
  explicitly requires re-verifying claims, not trusting them.
- `edit_log` is populated manually today (the `post-edit` hook does not yet
  auto-populate it) — the staleness signal is only as good as the edit_log
  coverage for the repos it's run against.

## Implemented

- `packages/octocode-awareness/src/docs.ts` — `mineDocStaleness()` (pure
  read) + `proposeDocRefresh()` (harness_log `propose` event), plus the
  `awareness doc-staleness` CLI command, tests, and docs
  (`docs/HARNESS.md`, skill `references/harness.md`).
- `docs/AGENT_ALGORITHMS.md` §1c + §3 router branch, mirrored into
  `skills/octocode-research/references/octocode.md` and
  `references/research-flow.md`.
