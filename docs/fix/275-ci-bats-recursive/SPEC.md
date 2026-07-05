# fix/275-ci-bats-recursive

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Fix the CI test job that runs `bats tests/` (non-recursive), discovering 0 test files and passing vacuously. Every CI "green" on all merged PRs has been a false positive — no tests actually ran. This must be fixed before any more PRs merge to prevent undetected regressions.

## Issue

`#275` — tracked issue. Required. The PR must close it.

## Branch

`fix/275-ci-bats-recursive`

## Root cause

`.github/workflows/ci.yml:138` runs `bats tests/` without the `--recursive` flag. Bats only scans the top-level `tests/` directory, which contains no `.bats` files directly — all tests live in subdirectories (`tests/core/`, `tests/integration/`, `tests/package/`, `tests/scripts/`). The command outputs `1..0` and exits 0, passing vacuously.

The Makefile (`Makefile:65`) already uses the correct command: `bats --recursive tests/`.

## Scope

### In scope

- Change `.github/workflows/ci.yml:138` from `bats tests/` to `make test`

### Out of scope

- Fixing the dotly.bats test 6 failure (#274) — separate fix
- Adding new tests (#267, #268) — separate fixes
- Restructuring the test directory layout — not needed

## Impact

- Modules/files touched: `.github/workflows/ci.yml` (1 line)
- Blast radius: CI only — no production code changes. Once fixed, CI will actually run 60 tests. Any failing test (e.g. #274) will now surface.
- Detection lead time: immediate — CI runs on every push after this fix merges.

## Rules that must never be violated

- CI must never pass vacuously — a green check must mean tests ran and passed.
- No production code changes in this fix — CI config only.

## Risks

- **Operational:** Once CI actually runs tests, previously-hidden failures (#274) will surface. This is expected and desirable — #274 is triaged as fix-now and will be fixed separately.
- **Security:** n/a
- **Compliance:** n/a

## Acceptance criteria

- [ ] `.github/workflows/ci.yml` test job uses `make test` (or `bats --recursive tests/`)
- [ ] CI discovers and runs all 60 tests on the fix branch
- [ ] `make test` passes locally (60 tests)
- [ ] `bash scripts/self/static_analysis` passes
- [ ] `bash scripts/self/lint` passes

## Rollback

Revert the one-line change in `.github/workflows/ci.yml`. No data-side cleanup needed.

## Effort

XS — one-line change, ≤ 1h.

## Affected docs

- `docs/fix/README.md` — add entry for #275

## Observability

CI "Tests" check will show `1..60` (or higher) instead of `1..0` in the job output, confirming tests actually ran.

## Cross-issue notes

- **#274** (dotly.bats test 6 fails) — will surface as a CI failure once this fix lands. Fix #275 first, then #274. Both are fix-now.
- **#267** (sloth_update tests) — will add more tests; this fix ensures they actually run in CI.
- **#268** (restorer tests) — same as #267.
- **#273** (gem.bats grep-based tests) — will surface in CI once this fix lands; not a blocker.

## Decisions made during drafting

- Chose `make test` over `bats --recursive tests/` to centralize the test command in the Makefile (DRY principle). If the test command changes in the future, only the Makefile needs updating.
