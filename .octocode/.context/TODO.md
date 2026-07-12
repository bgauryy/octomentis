# TODO

## ghSearchPRs — 10/10 polish

- [ ] Add top-level `reviewPacketComplete: false` when any requested PR review surface has more pages.
  - Sources to inspect: `bodyPagination`, `filePagination`, `commentPagination`, `commitPagination`, per-file `patchPagination`.
  - Include a compact `nextReviewPage` / `continueReview` object with the next recommended calls.

- [ ] Add richer review-state aggregation.
  - [ ] Approval count.
  - [ ] Requested-changes count.
  - [ ] Commented / pending / dismissed counts where GitHub exposes them.
  - [ ] Latest review state by reviewer, de-duplicated by reviewer login and latest submitted timestamp.
  - [ ] Surface this under `reviewSummary.reviewStates` or a dedicated `reviewStateSummary` field.

- [ ] Rename internal provider-layer `fileChanges` terminology to `changedFiles`.
  - Public/direct tool output is already `changedFiles`.
  - Internal cleanup should touch provider result types, provider mappers, tests, and structured pagination references.
  - Keep a temporary compatibility bridge only if needed inside lower-level GitHub API adapters.
