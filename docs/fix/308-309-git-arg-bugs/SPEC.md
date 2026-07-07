# fix/308-309-git-arg-bugs

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Fix two pre-existing argument-handling bugs in `scripts/core/src/git.sh` that
were discovered during feature 10's review (PR #310). Both are silent
wrong-behavior hazards: #309 writes to the wrong file when `$GITIGNORE_PATH`
differs from the first argument; #308 silently drops the `-C <repo>` option
because `$1` is consumed as a branch name. They cannot wait for a feature
cycle because #309 has an active caller (`zimfw.sh`) that passes a path that
may differ from `$GITIGNORE_PATH`, and #308 is a footgun for any future caller
using the documented `-C` option form.

## Issue

`#308` — `git::current_commit_hash`/`check_branch_is_behind` shift `$1` as
branch, breaking `-C` option.
`#309` — `git::add_to_gitignore` writes to `$GITIGNORE_PATH` instead of its
first argument.

Both must be closed by this PR (`Closes #308`, `Closes #309`).

## Branch

`fix/308-309-git-arg-bugs`

## Root cause

**#309** (`scripts/core/src/git.sh:578`): `git::add_to_gitignore` declares
`local -r gitignore_file_path="${1:-}"` (the intended target) but then appends
to `$GITIGNORE_PATH` (a global env var) instead of `$gitignore_file_path`. When
the two differ, content lands in the wrong file and the function returns 1
(the subsequent `grep` on `$gitignore_file_path` finds nothing).

**#308** (`scripts/core/src/git.sh:184-188`, `278-282`): `git::current_commit_hash`
and `git::check_branch_is_behind` both do `local -r branch="${1:-HEAD}"; [[ -n
"${1:-}" ]] && shift`. This consumes `$1` as the branch name unconditionally.
When a caller passes `git::current_commit_hash -C <repo>`, `-C` becomes the
"branch" and `<repo>` is passed through as a git argument — but `rev-parse`
receives `-C` as the ref to verify, which fails or returns the wrong SHA.

## Scope

### In scope

1. `scripts/core/src/git.sh:578` — change `tee -a "$GITIGNORE_PATH"` to
   `tee -a "$gitignore_file_path"` (one-line fix, #309).
2. `scripts/core/src/git.sh:184-188` (`git::current_commit_hash`) and
   `:278-282` (`git::check_branch_is_behind`) — restructure so git options
   (`-C`, `--git-dir`, etc.) are not consumed as the branch name. The
   conservative fix: only shift `$1` if it does not start with `-` (i.e. it's
   a branch/commit, not an option). If `$1` starts with `-`, leave it in `$@`
   and use the default `HEAD` (#308).
3. `tests/core/git.bats` — update the `add_to_gitignore` tests to use distinct
   files for `$1` and `$GITIGNORE_PATH` (so the test would have caught the
   bug). Update `current_commit_hash`/`check_branch_is_behind` tests to cover
   the `-C <repo>` form without explicit `HEAD` (the form that was broken).

### Out of scope

- Other `git::*` functions with the same shift pattern (`git::is_valid_commit`
  at `:192` has a similar shape but its `$1` is a commit, not a branch, and it
  doesn't default to `HEAD` — the footgun is less severe). File a separate
  issue if it needs fixing.
- Refactoring the entire `git.sh` argument-parsing approach (a general
  `git::parse_args` helper). That's a feature, not a fix.

## Impact

- **Modules/files touched:** `scripts/core/src/git.sh` (2 functions + 1 line),
  `tests/core/git.bats` (3 tests updated).
- **Blast radius:** `git::add_to_gitignore` is called by `zimfw.sh:31` and
  `z.sh:31`. The `zimfw.sh` caller passes `${DOTFILES_PATH}/.gitignore` which
  matches the default `GITIGNORE_PATH` — so it works today by coincidence. If
  a user overrides `GITIGNORE_PATH`, `zimfw.sh` silently writes to the wrong
  file. `git::current_commit_hash`/`check_branch_is_behind` have no current
  callers in `scripts/` (only tests call them), so the fix is preventive.
- **Detection lead time:** #309 is silent (wrong file, no error message until
  the grep check returns 1). #308 fails with a confusing git error
  (`rev-parse: -C: unknown ref`). Both would surface as "gitignore not
  working" or "version check broken" user reports.

## Rules that must never be violated

- **Shell compatibility:** all scripts must be POSIX-compatible bash, no
  bashisms that break on macOS bash 3.2 (CLAUDE.md hard rules). The fix uses
  only `[[ "$1" == -* ]]` pattern matching — POSIX-safe.
- **Core libraries are sourced, not executed** (ARCHITECTURE.md:17). The fix
  does not add `set -euo pipefail` to `git.sh` (it's a sourced library).
- **No new dependencies** (CLAUDE.md hard rules). The fix uses only bash
  builtins and existing `git::git` wrapper.
- **`command -p` for portable command resolution** (CLAUDE.md). The fix
  doesn't add new external commands.

## Risks

- **Operational:** the `add_to_gitignore` fix changes where content is written
  for callers that pass a path ≠ `$GITIGNORE_PATH`. The `zimfw.sh` caller
  passes `${DOTFILES_PATH}/.gitignore` (== default `GITIGNORE_PATH`), so no
  behavior change for it. The `z.sh` caller passes `$GITIGNORE_PATH` directly,
  so no change. Risk: a hypothetical caller relying on the buggy behavior
  (writing to `$GITIGNORE_PATH` regardless of `$1`) would break — but that's
  the bug being fixed.
- **Security:** n/a — no auth, secrets, PII, or network involved.
- **Compliance:** n/a.

## Acceptance criteria

- [ ] `git::add_to_gitignore "$f1" "build/"` with `GITIGNORE_PATH="$f2"` (f1 ≠ f2)
      writes "build/" to `$f1`, not `$f2`, and returns 0. (unit test,
      `tests/core/git.bats`)
- [ ] `git::current_commit_hash -C "$REPO_DIR"` (no explicit `HEAD`) returns
      the HEAD SHA of `$REPO_DIR`. (unit test, `tests/core/git.bats`)
- [ ] `git::current_commit_hash HEAD -C "$REPO_DIR"` (explicit `HEAD`) still
      works — no regression. (unit test, existing)
- [ ] `git::check_branch_is_behind -C "$REPO_DIR"` does not consume `-C` as
      the branch name. (unit test, `tests/core/git.bats`)
- [ ] `git::add_to_gitignore` existing tests (append + no-duplicate) pass with
      distinct files. (regression, `tests/core/git.bats`)
- [ ] `bash scripts/self/static_analysis && bash scripts/self/lint` green.
- [ ] `make test` passes (all 158+ tests).

## Rollback

Revert the PR. No data-side cleanup: the fix only changes where
`add_to_gitignore` writes content — if it wrote to the wrong file before the
fix, that content is already there and reverting doesn't remove it. The
`current_commit_hash` fix is pure logic — no state to clean up.

## Effort

**XS** — 3 one-line code changes + 3 test updates, single commit, ≤ 1h.

## Impact (extra section)

See above — blast radius confined to `git.sh` functions and their 2 recipe
callers, both of which pass paths that match defaults.

## Rules that must never be violated (extra section)

See above.

## Operational risks

n/a — no scheduled jobs, queues, caches, schemas, or external adapters
involved. `git::add_to_gitignore` is called during package installation
(`zimfw.sh`, `z.sh`), which is interactive/user-initiated, not a background job.

## Security risks

n/a — no auth, secrets, PII, webhooks, or rate limits involved.

## Compliance touchpoints

n/a.

## Affected docs

- `docs/architecture/ARCHITECTURE.md` — no change needed (the fix upholds the
  existing invariants, doesn't change them).
- `docs/fix/README.md` — register the fix entry (status `pending`).

## Observability

No log line or metric — these are library functions. The fix is confirmed by
the unit tests: `git::add_to_gitignore` writes to the correct file;
`git::current_commit_hash -C <repo>` returns the right SHA. If the fix
regresses, the tests fail.

## Cross-issue notes

- **#308 + #309** — bundled into one fix PR (same file, both small, filed
  during the same review). The PR closes both.
- **#300** (audit standalone scripts for `set -euo`) — unrelated; `git.sh` is
  a sourced library, intentionally omits `set -e`.
- **Feature 10 (#310, merged)** — added the tests that discovered both bugs.
  The tests work around the bugs; this fix removes the workarounds.

## Effort

**XS** — 3 one-line code changes in `scripts/core/src/git.sh` + 3 test updates
in `tests/core/git.bats`. Single commit, ≤ 1h.

## Decisions made during drafting

1. **Bundle #308 + #309** — both are in the same file, both small, both filed
   from the same review. One PR closes both. The branch name uses both issue
   numbers: `fix/308-309-git-arg-bugs`.
2. **Conservative fix for #308** — only shift `$1` if it doesn't start with
   `-` (i.e. it's a branch/commit, not an option). This preserves the existing
   behavior for callers that pass a branch name, while fixing the `-C` case.
   Alternative considered: a full `getopts`-based argument parser — rejected
   as overengineering for a 2-function fix.
3. **Test update for #309** — the existing tests point `GITIGNORE_PATH` at the
   same file as `$1` (the workaround). The updated tests use distinct files so
   the test would have caught the bug. This is a test improvement, not just a
   fix verification.
4. **`git::is_valid_commit` not in scope** — it has a similar shift pattern
   (`:192`) but its `$1` is a commit hash, not a branch, and it doesn't
   default to `HEAD`. The footgun is less severe (a caller passing `-C`
   would get `cat-file -t -C` which fails loudly). Filed as out-of-scope; a
   separate issue can be opened if needed.
