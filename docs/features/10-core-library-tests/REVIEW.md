# Review Change — feature 10 (core-library-tests)

> Branch: `feat/10-core-library-tests` vs `main`. Scope: 4 new `.bats` files
> under `tests/core/` + SPEC + ROADMAP row flip.

**Axes run:** review-implementation, review-code, review-security,
review-verify, review-debt, review-perf, workflow, spec-drift
**Skipped:** review-design, review-a11y, review-brand, review-seo — no UI
surface (Bash framework, tests only).

## Synthesized decision table

| Axis | Finding | Sev | Class | WHY | Route |
|---|---|---|---|---|---|
| spec-drift | None — diff matches SPEC scope exactly (4 files, 51 tests, no scripts/ change) | — | ignore | Acceptance criteria all met | drop |
| workflow | Clean tree, commits on feature branch only, format `feat(10): …` correct | — | ignore | Compliant | drop |
| review-verify | Gate green: static_analysis + lint + `bats --recursive tests/` (155 tests, 0 fail, 8 skip) | — | ignore | Verified real behavior | drop |
| review-code | `git.bats:16` captures `_REAL_GIT="$GIT_EXECUTABLE"` at load time — relies on `_main.sh` having set it; setup() resets it per test. Correct mock hygiene. | — | ignore | Pattern is sound | drop |
| review-code | `json.bats:17-41` `_pty_bash` helper uses python3 pty to make `[[ -t 0 ]]` true for file-form tests. Skips gracefully when python3 absent. | low | intentional-tradeoff | File-form branch of json.sh is gated by tty check; pty is the only way to exercise it under bats | decision (this doc) |
| review-security | No secrets, no network, no injection surface in test files. Mocks write only to `tests/helpers/mocks/`. | — | ignore | Clean | drop |
| review-debt | `git.bats` covers 13 of ~30 `git::*` functions (SPEC asked for ≥10). Remaining functions are lower-use. | low | postpone | Coverage gap is acceptable for S size; follow-up feature proposed | issue + trigger (next test-expansion feature) |
| review-perf | Tests use temp dirs + real `git init`; teardown cleans up. No N+1, no hot-path concern. | — | ignore | Tests-only, no runtime impact | drop |
| review-implementation | Pre-existing bug: `git::add_to_gitignore` writes to `$GITIGNORE_PATH` not `$gitignore_file_path` (`scripts/core/src/git.sh:578`). Test works around it. | med | postpone | Pre-existing source bug, NOT introduced by this PR; scope is tests-only | issue #308 |
| review-implementation | Pre-existing bug: `git::current_commit_hash`/`check_branch_is_behind` shift `$1` as branch, breaking `-C` option (`scripts/core/src/git.sh:184`). Tests use `HEAD -C <repo>` form. | low-med | postpone | Pre-existing source footgun, NOT introduced by this PR | issue #309 |

## Manual verification (a human must check)

- CI `🚀 Build (macos-latest)` passes — the 6 `json.bats` tests run there with
  yq installed (they skip locally without yq).
- The `_pty_bash` helper behaves on the macOS runner (python3 pty) — the 2
  file-form json tests depend on it.
- No test pollutes the real `git` global config (setup uses `temp_dir` repos
  with local `user.email`/`user.name` config).

## Non-fix-now destinations (step 8): 4 triaged

- **#308** — `git::add_to_gitignore` wrong-file write (postpone → tracked issue)
- **#309** — `git::current_commit_hash`/`check_branch_is_behind` shift footgun (postpone → tracked issue)
- **review-debt** git coverage gap → drop (acceptable for S; follow-up feature proposed in report)
- **review-code** pty helper → documented decision (this file)

## Summary

Clean test-only addition; gate green; no SPEC drift; no fix-now findings. Two
pre-existing source bugs discovered and filed as tracked issues (#308, #309)
rather than fixed inline (scope discipline). The pty helper for json file-form
tests is an accepted tradeoff documented here.

Decision: **PASS**
