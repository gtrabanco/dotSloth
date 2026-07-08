# fix/319-is-valid-commit-C-option

## Goal

`git::is_valid_commit` (`scripts/core/src/git.sh:197-199`) consumes `-C` as the commit argument when a caller passes `git::is_valid_commit -C "$REPO"` (relying on the `HEAD` default), the same shift footgun fixed for `check_branch_is_behind` (#313) and `check_branch_is_ahead` (#317). This fix applies the same `[[ "$1" != -* ]]` guard.

## Issue

`#319`

## Branch

`fix/319-is-valid-commit-C-option`

## Root cause

```bash
git::is_valid_commit() {
  local -r commit="${1:-HEAD}"
  [[ -n "${1:-}" ]] && shift
  [[ $(git::git "$@" cat-file -t "$commit") == commit ]]
}
```

When `$1` is `-C`, `commit` becomes `-C`, shift drops it, and `"$REPO"` becomes a bare git argument — `git "$REPO" cat-file -t "-C"` is invalid.

## Scope

### In scope

1. `scripts/core/src/git.sh` — rewrite `is_valid_commit` prologue to mirror the fixed `check_branch_is_behind`/`check_branch_is_ahead`.
2. `tests/core/git.bats` — distinguishing regression test: `git::is_valid_commit -C "$REPO_DIR"` with no explicit commit — fixed returns 0 (HEAD valid), buggy returns non-zero (commit=-C invalid).

### Out of scope

- Other git.sh issues (#315, #316).

## Acceptance criteria

- [ ] `git::is_valid_commit -C "$REPO"` resolves commit=HEAD via default, not -C.
- [ ] Test distinguishes buggy from fixed.
- [ ] Gate green.

## Effort

XS — same mechanical pattern as #314.
