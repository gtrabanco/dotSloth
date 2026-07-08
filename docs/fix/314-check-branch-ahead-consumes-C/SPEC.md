# fix/314-check-branch-ahead-consumes-C

> Fix specification for `git::check_branch_is_ahead` consuming `-C` as the branch
> name — the twin of the `check_branch_is_behind` footgun fixed in #313.

## Goal

`git::check_branch_is_ahead` (`scripts/core/src/git.sh:306-309`) shares the
identical argument-shift footgun that `git::check_branch_is_behind` had before
fix #313: a caller passing `git::check_branch_is_ahead -C "$REPO"` has `-C`
consumed as the branch name, producing `git config --get "branch.-C.merge"`
which errors out. This fix applies the same `[[ "$1" != -* ]]` guard already
proven in `check_branch_is_behind` (PR #313, commit 80e3f49), plus a
distinguishing regression test. It cannot wait for a feature cycle because it
is a latent defect in a core git helper that will silently break the first
caller that uses the `-C` option form — the same class of bug that #308/#313
already proved bites in practice.

## Issue

`#314` — tracked issue. Required. The PR must close it.

## Branch

`fix/314-check-branch-ahead-consumes-C`

## Root cause

`scripts/core/src/git.sh:307-309` uses the `${1:-$(git::current_branch "$@")}`
pattern that treats the first positional argument as the branch name
unconditionally:

```bash
git::check_branch_is_ahead() {
  local -r branch="${1:-$(git::current_branch "$@")}"
  [[ -z "$branch" ]] && return 1
  [[ -n "${1:-}" ]] && shift
  ...
```

When a caller passes `git::check_branch_is_ahead -C "$REPO"`, `$1` (`-C`) is
captured into `branch`, then `shift` drops it, and the remaining `"$REPO"` is
passed through as a git argument — producing `git "$REPO" config --get
"branch.-C.merge"` which is invalid. The `-C` git option is never forwarded to
`git::current_branch`, so the branch is never resolved.

Evidence: the fixed `check_branch_is_behind` at `scripts/core/src/git.sh:281-298`
uses the `[[ "$1" != -* ]]` guard precisely to avoid this; `check_branch_is_ahead`
at `scripts/core/src/git.sh:306-320` was left with the old pattern when #313
landed (its SPEC's out-of-scope section explicitly deferred sibling functions).

## Scope

### In scope

The smallest change set that closes the issue:

1. Rewrite `git::check_branch_is_ahead` (`scripts/core/src/git.sh:306-309`) to
   use the `[[ "$1" != -* ]]` guard, mirroring `check_branch_is_behind`
   (`scripts/core/src/git.sh:281-288`).
2. Add one distinguishing regression test in `tests/core/git.bats` for
   `git::check_branch_is_ahead` with the `-C` option, modeled on the
   `check_branch_is_behind with -C option does not consume -C` test
   (`tests/core/git.bats:148-165`), but set up so the fixed code returns 0
   (local ahead of remote) while the buggy code returns 1 (no upstream).

### Out of scope

Adjacent problems found during analysis — each filed separately, not part of
this SPEC:

- **#315** — `git::add_to_gitignore` dedup uses unescaped regex
  (`scripts/core/src/git.sh:586,591`). Separate issue, separate fix branch.
- **#316** — `scripts/core/src/git.sh` fails `shfmt -d` (pre-existing
  formatting). Separate chore commit/PR; this SPEC's edited region is clean by
  construction (it copies the already-formatted `check_branch_is_behind` block).

## Impact

- **Modules/files touched:**
  - `scripts/core/src/git.sh` (function `git::check_branch_is_ahead`, ~lines 306-309).
  - `tests/core/git.bats` (new test block under a `git::check_branch_is_ahead` section).
- **Blast radius:** dev-only / preventive. No current callers of
  `git::check_branch_is_ahead` exist in `scripts/` (only tests call it) — same
  posture as `check_branch_is_behind` before #313. If the fix is wrong, the
  worst case is the function misreports ahead/behind for a future `-C` caller;
  no data corruption, no user-visible surface today.
- **Detection lead time:** silent until a caller adopts the `-C` form, at which
  point the error is immediate (`git config --get "branch.-C.merge"` fails
  loudly). The regression test is the early-warning system.

## Rules that must never be violated

From `CLAUDE.md` hard rules + architecture:

- **Shell compatibility:** the fix must remain POSIX-compatible bash; the guard
  `[[ "$1" != -* ]]` is already used in the sibling function and is safe on
  macOS bash 3.2.
- **`set -euo pipefail`:** the function's existing `local -r` usage is
  preserved; the rewrite keeps `local branch` (non-`-r`, matching the sibling)
  so the conditional assignment is valid.
- **No new dependencies.**
- **Core scripts must not source dotfiles user scripts** — n/a (no new sourcing).

## Risks

- **Operational risks:** n/a. No scheduled job, queue, cache, or schema
  interaction. The function is a pure git query helper.
- **Security risks:** n/a. No auth, secrets, PII, webhooks, or rate-limits
  involved.
- **Compliance touchpoints:** n/a.

## Acceptance criteria

Objective checkboxes, each independently verifiable:

- [ ] `git::check_branch_is_ahead` rewritten with the `[[ "$1" != -* ]]` guard,
  structurally mirroring `git::check_branch_is_behind` (`scripts/core/src/git.sh:281-288`).
  (unit — `tests/core/git.bats`)
- [ ] New test `git::check_branch_is_ahead with -C option does not consume -C`
  passes: sets up a remote, resets local main to `origin/main`, adds a local
  commit so local is ahead, wires `branch.main.merge`, and asserts
  `git::check_branch_is_ahead -C "$REPO_DIR"` returns 0. (unit — `tests/core/git.bats`)
- [ ] The new test FAILS against the pre-fix code (verified by temporarily
  reverting the function) and PASSES against the fixed code — proving it is a
  distinguishing regression test, not a weak guard. (manual verification during
  implementation)
- [ ] `bats --recursive tests/` is green (157 → 158 tests, 0 fail). (gate)
- [ ] `shfmt -ln bash -sr -ci -i 2 -d scripts/core/src/git.sh` reports no diffs
  in the edited region. (gate — note: pre-existing diffs elsewhere are tracked
  by #316 and are out of scope)
- [ ] `shellcheck scripts/core/src/git.sh` introduces no new warnings in the
  edited function. (gate)

## Rollback

Revert the PR (single commit). No data-side cleanup — the function is a pure
query with no persistent state. Nothing is preserved or lost; the pre-fix
behavior (broken for `-C` callers) is restored.

## Effort

**XS** — one function rewrite (~4 lines) mirroring an already-merged pattern,
plus one regression test modeled on an existing gold-standard test. One commit,
well under 1h.

## Impact (extended)

- **Layers:** infrastructure (`scripts/core/src/`) — no domain/use-case/page
  layers; this is a core shell helper.
- **Blast radius:** preventive only (no current callers).

## Rules that must never be violated (extended)

- The `local -r` → `local` change for `branch` is required because the
  conditional assignment (`branch="$1"` vs `branch="$(...)"`) cannot use `local
  -r` with a later assignment in bash. This matches the sibling function
  exactly (`scripts/core/src/git.sh:282`).

## Operational risks

n/a — no scheduled-job, queue, cache, schema, or external-adapter interaction.

## Security risks

n/a — no auth, secrets, PII, webhooks, or rate-limits.

## Compliance touchpoints

n/a.

## Affected docs

- `docs/fix/README.md` — add the active fix row (status `pending`); remove on
  merge. (acceptance criterion: "Updated `docs/fix/README.md` Active table")

No other docs require update — this is an internal helper fix with no
user-visible behavior change.

## Observability

The regression test in `tests/core/git.bats` is the confirmation that the fix
is live and healthy. In production there is no log line/metric (the function is
a library helper); the test gate (`make test` / `bats --recursive tests/`) is
the health signal — a future regression that reintroduces the footgun turns the
new test red.

## Cross-issue notes

- **#313 (merged)** — the reference fix for the twin function
  `check_branch_is_behind`. This fix copies its proven pattern. No action.
- **#315 (open)** — `add_to_gitignore` dedup regex in the same file
  (`scripts/core/src/git.sh`). Parallel, independent; do not absorb into this
  fix. Separate branch/PR.
- **#316 (open)** — `git.sh` fails `shfmt -d` (pre-existing formatting across
  the whole file). Parallel; this SPEC's edited region is clean by construction.
  A separate chore PR should run `shfmt -w` on the whole file; do not mix
  formatting into this behavioral fix.
- **#312 (open)** — stale fix folders. Unrelated; housekeeping.

## Decisions made during drafting

- **Test setup choice (local ahead vs behind):** the issue suggests "set up a
  remote + upstream so the fixed code returns 0." For `check_branch_is_ahead`,
  returning 0 means local is genuinely ahead, so the test resets local main to
  `origin/main` then adds an empty commit — making local strictly 1 commit
  ahead. This avoids the symmetric-difference ambiguity of the three-dot
  `...` operator (a diverged repo would also return 0, which would not prove
  "ahead"). The implementer may re-question this if a simpler setup is
  equivalent.
- **`local -r` → `local`:** the rewrite drops `-r` from the `branch` local to
  allow the conditional assignment, exactly as the sibling function does. Not a
  behavioral change.
- **Not fixing #315/#316 here:** per "track, don't inline" — they stay separate
  issues with their own branches.
