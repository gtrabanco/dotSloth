# Active fixes

Index of in-progress and pending fixes. Merged fixes are removed from this table —
history lives in git log + closed issues.

## Status legend

- `pending` — SPEC drafted, branch not yet open
- `in-progress` — branch open, work ongoing
- `done` — built, PR open, awaiting merge (merge state lives in the forge — same
  meaning as the roadmap's `done`); remove the row only **after** the PR merges

## Active

| Folder | Topic | Status | Depends on | Issue |
|--------|-------|--------|------------|-------|
| 265-gem-update-false-positive | gem::update_apps silently fails on broken system Ruby | done · [#270](https://github.com/gtrabanco/dotSloth/pull/270) | — | [#265](https://github.com/gtrabanco/dotSloth/issues/265) |
| 280-remaining-path-fallback | Remaining DOTLY_PATH fallback in init scripts | done · [#281](https://github.com/gtrabanco/dotSloth/pull/281) | — | [#280](https://github.com/gtrabanco/dotSloth/issues/280) |
| 266-complete-path-fallback-refactor | Complete DOTLY_PATH fallback refactor in context scripts | pending | — | [#266](https://github.com/gtrabanco/dotSloth/issues/266) |
| 240-testing-framework-finalize | Add 10th test file to meet acceptance criterion #5 | pending | — | [#240](https://github.com/gtrabanco/dotSloth/issues/240) |
| 269-set-euo-pipefail | Migrate remaining scripts to set -euo pipefail | done · [#282](https://github.com/gtrabanco/dotSloth/pull/282) | — | [#269](https://github.com/gtrabanco/dotSloth/issues/269) |

## Conventions

- One folder per fix: `docs/fix/<issue-number>-<topic>/SPEC.md`.
- Every fix has a tracked issue; the PR closes it.
- Remove the row when the PR merges.
