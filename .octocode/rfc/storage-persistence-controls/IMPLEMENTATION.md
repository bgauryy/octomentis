# Implementation: Storage & Persistence Controls

> Decision: see `RFC.md` §Summary / §Rationale (option **C**). This file does not restate goals.

## Resolved Questions (were open in RFC.md)

| Open question (RFC §) | Resolution | Evidence | Confidence |
|---|---|---|---|
| Q1 Exact env names | Use discrete vars: `OCTOCODE_STORAGE_STATS`, `OCTOCODE_STORAGE_SESSION`, `OCTOCODE_STORAGE_GC_ORPHANS` (+ `.octocoderc` `storage.*`). Matches existing MCP `env` style (`ENABLE_CLONE`, `OCTOCODE_CACHE_TTL_MS`). | `docs/CONFIGURATION.md` Advanced + MCP env examples | confirmed |
| Q2 Include `tmp.binary` TTL in v1? | **Defer** to Phase 3 follow-up. v1 focuses on continuous small-file writers (stats/session) + orphan GC + docs. Binary/clone already have/need separate TTL work. | Sample `tmp/binary` 155 MB vs continuous `stats.json` writes; clone already has TTL/caps | likely |
| Q3 `octocode status --json`? | **Yes, Phase 2** — expose `storage` object with `stats`, `session`, `gcOrphans` and optional `homeDisk` hint if cheap. | CLI already has `status` command surface | confirmed |

## Approach

Add `storage` to config defaults → gate `writeSessionToDisk` / flush timer → document home layout → optional orphan GC → status field.

## Steps (dependency-ordered)

### Phase 1: Config + gate (shippable)

- [ ] Extend `octocode-config` types/defaults/validator/resolver for `storage.stats`, `storage.session`, `storage.gcOrphans`.
- [ ] Wire env: `OCTOCODE_STORAGE_STATS` ∈ `disk|memory|off`, `OCTOCODE_STORAGE_SESSION` ∈ `disk|memory`, `OCTOCODE_STORAGE_GC_ORPHANS` ∈ truthy.
- [ ] In tools-core `sessionDiskIO` / `sessionCache`: skip file writes per mode; do not start flush timer when nothing is disk-backed.
- [ ] Unit tests: dirty updates with `stats=off` leave no `stats.json`; `session=memory` leaves no `session.json`; default still writes both.
- [ ] Update `docs/CONFIGURATION.md` home table + settings reference.

### Phase 2: Observability + #443 closeout

- [ ] CLI `status --json` includes persistence mode.
- [ ] Optional: `octocode cache` / status note pointing at `tmp/` sizes (reuse existing cache command if present).
- [ ] Maintainer comment on #443 with inventory summary + knob names.

### Phase 3 (follow-up, optional)

- [ ] Binary/unzip TTL or size cap under `tmp/binary` (largest observed bucket).
- [ ] `storage.gcOrphans` startup path + test with fixture orphan files.

## Files / APIs / Contracts Touched

| File | Change |
|---|---|
| `packages/octocode-config/src/config/types.ts` | `StorageConfigOptions` |
| `packages/octocode-config/src/config/defaults.ts` | defaults `disk` / `disk` / `false` |
| `packages/octocode-config/src/config/resolver*.ts` + `validator.ts` | resolve/validate |
| `packages/octocode-tools-core/src/shared/session/sessionDiskIO.ts` | gated writes |
| `packages/octocode-tools-core/src/shared/session/sessionCache.ts` | timer gate |
| `packages/octocode-tools-core/tests/shared/session/*` | persistence modes |
| `docs/CONFIGURATION.md` | home layout + knobs |
| `packages/octocode/src/cli/commands/status.ts` | Phase 2 |

MCP package: expect **no** business-logic change if config is read inside tools-core session bootstrap.

## Risk Mitigations

| Risk (`RFC.md` §Pre-mortem) | Mitigation |
|---|---|
| Stats skill breaks | Document; status shows mode; default remains disk |
| Empty flush timer | Gate `startFlushTimer` |
| Orphan GC surprise | Default false; document paths deleted |

## Test and Verification Plan (V&V)

| Type | Scope | Approach | Command |
|------|-------|----------|---------|
| Unit | sessionDiskIO / sessionCache | Modes off/memory/disk | `yarn workspace @octocodeai/octocode-tools-core test` |
| Unit | config resolve | Env + rc merge | `yarn workspace @octocodeai/config test` |
| Integration | Isolated home | Tool calls under `OCTOCODE_HOME` tmpdir; assert file absence | vitest / script |
| Docs | CONFIGURATION | Table lists tmp + knobs | manual / contract test if exists |

## Rollout / Rollback

- Ship behind defaults = current behavior.
- Rollback: unset env / remove `storage` key; or revert commit — no data migration.
- Announce in #443 + CONFIGURATION changelog blurb.

## Open follow-ups

- Phase 3 binary tmp policy.
- Awareness disk policy remains separate package concern.
