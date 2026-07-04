# fix/240-testing-framework-finalize

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Feature 05 (testing-framework) is marked `in-progress` in the roadmap but 7/8
acceptance criteria are already met. The only missing criterion is "At least 10
test files" (9 exist). This fix adds the 10th test file (`tests/core/dotly.bats`),
closes #240, and flips roadmap 05 to `done`.

## Issue

`#240` — tracked issue. Required. The PR must close it.

## Branch

`fix/240-testing-framework-finalize`

## Root cause

Feature 05 SPEC (`docs/features/05-testing-framework/SPEC.md`) specifies 8
acceptance criteria. 7 are met:

1. ✅ `make test` runs on macOS (48/48 pass)
2. ✅ `make test` runs on Ubuntu (CI matrix)
3. ✅ CI has a `test` job on both macOS and Ubuntu
4. ✅ CI fails the build if any test fails
5. ❌ **At least 10 test files** (9 exist, not 10)
6. ✅ Tests run in under 60 seconds (6.5s)
7. ✅ Tests do not require network access or root privileges
8. ✅ Human-readable output (bats default format)

Evidence:
- `find tests -name '*.bats' | wc -l` → 9
- `make test` → 48/48 ok in 6.5s
- `.github/workflows/ci.yml` — test job exists with macOS + Ubuntu matrix

## Scope

### In scope

The smallest change set that closes the issue.

1. Create `tests/core/dotly.bats` — test `dotly::list_bash_files` and
   `dotly::list_dotfiles_bash_files` (2 functions in `scripts/core/src/dotly.sh`).
2. Update `docs/features/ROADMAP.md` — flip feature 05 from `in-progress` to
   `done`.
3. Close #240 via the PR.

### Out of scope

- Adding more than 1 test file — the SPEC requires 10, we have 9, adding 1
  satisfies the criterion. Expanding coverage is an ongoing effort, not part of
  this fix.
- Testing `sloth_update.sh` — tracked in #267.
- Testing `restorer`/`installer` — tracked in #268.
- Performance/benchmark testing — out of scope per SPEC.

## Impact

- Modules/files touched: `tests/core/dotly.bats` (new), `docs/features/ROADMAP.md`
  (1 line change).
- Blast radius: none — adding a test file cannot break existing functionality.
- Detection lead time: immediate — test failures show in CI.

## Rules that must never be violated

- Tests must not modify production files.
- Tests must be idempotent (can run multiple times safely).
- Tests must work on both macOS and Linux (CI matrix).
- Tests must not require network access or root privileges.
- Test files follow `snake_case` naming.
- Test files use `#!/usr/bin/env bats` shebang.
- Tests use `SLOTH_PATH` environment variable to point to repo root.

## Risks

- **Operational**: n/a — adding a test file has no operational impact.
- **Security**: n/a.
- **Compliance**: n/a.

## Acceptance criteria

- [ ] `tests/core/dotly.bats` exists and tests `dotly::list_bash_files` and
      `dotly::list_dotfiles_bash_files` (unit test)
- [ ] `find tests -name '*.bats' | wc -l` → 10 (or more)
- [ ] `make test` passes (48 existing + new dotly tests)
- [ ] Tests run in under 60 seconds total
- [ ] `bash scripts/self/static_analysis` passes clean
- [ ] `dot core lint` passes clean
- [ ] `docs/features/ROADMAP.md` feature 05 status → `done`
- [ ] #240 closed by the PR

## Rollback

Revert the PR. No data-side cleanup needed.

## Effort

**XS** — 1 new test file (~20 lines), 1 line change in ROADMAP.md. ≤ 1h.

## Impact (extra sections)

- Layers: test layer only (`tests/core/dotly.bats`), documentation
  (`docs/features/ROADMAP.md`).
- Blast radius: none.
- Detection lead time: immediate.

## Rules that must never be violated (extra)

- Tests must not modify production files.
- Tests must be idempotent.
- Tests must work on macOS and Linux.
- Tests must not require network or root.
- `snake_case` naming, `#!/usr/bin/env bats` shebang.

## Operational risks

n/a — adding a test file has no operational impact.

## Security risks

n/a.

## Compliance touchpoints

n/a.

## Affected docs

- `docs/features/ROADMAP.md` — feature 05 status: `in-progress` → `done`.
- `docs/fix/README.md` — update entry status from `pending` to `done` when PR opens.

## Observability

- `find tests -name '*.bats' | wc -l` → 10 (was 9).
- `make test` → 48+N tests pass (was 48).

## Cross-issue notes

- #267 (tests for sloth_update.sh) — postpone, parallel. This fix does not
  overlap.
- #268 (tests for restorer/installer) — postpone, parallel. This fix does not
  overlap.
- #265 (gem false positive) — parallel, no overlap.

## Effort

**XS** — 1 new test file, 1 line change. ≤ 1h.

## Decisions made during drafting

- Chose `dotly.sh` as the 10th test file because:
  - `dotly::list_bash_files` was relevant to fix #234 (restorer broken).
  - `dotly.sh` has only 2 functions — small, focused test file.
  - Fills a gap in core library coverage (currently only log, output, package,
    platform are tested).
- Alternative candidates: `files.sh` (3 functions), `str.sh`, `json.sh` — all
  valid but `dotly.sh` has the strongest link to a recent bug fix.
- Roadmap flip: `in-progress` → `done` because all 8 acceptance criteria will
  be met after this fix.
