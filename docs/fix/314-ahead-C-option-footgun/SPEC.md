# fix/314-ahead-C-option-footgun

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

`git::check_branch_is_ahead` (`scripts/core/src/git.sh:306-309`) consumes its
first argument as the branch name even when that argument is a git option flag
(`-C <repo>`), the identical shift footgun that `git::check_branch_is_behind`
had before fix #313. This fix applies the same `[[ "$1" != -* ]]` guard so
options pass through to `git` instead of being mistaken for a branch name. It
is a preventive fix: the latent footgun has one real caller today, but that
caller passes the branch explicitly and is not currently bitten — the fix
closes the trap before a caller uses the `-C` option form.

## Issue

`#314` — tracked issue. Required. The PR must close it.

## Branch

`fix/314-ahead-C-option-footgun`

## Root cause

`scripts/core/src/git.sh:306-309`:

```bash
git::check_branch_is_ahead() {
  local -r branch="${1:-$(git::current_branch "$@")}"
  [[ -z "$branch" ]] && return 1
  [[ -n "${1:-}" ]] && shift
```

When a caller passes `git::check_branch_is_ahead -C "$REPO"`, `$1` (`-C`) is
consumed as the branch name: `branch` becomes `-C`, then `shift` drops `-C`,
and `$REPO` is passed through as a bare git argument — producing
`git "$REPO" config --get "branch.-C.merge"` which errors / finds no upstream
and returns 1. The option never reaches `git`.

This is the twin of #308, fixed for `check_branch_is_behind` in PR #313
(commit `80e3f49`, `scripts/core/src/git.sh:281-296`) with the
`[[ "$1" != -* ]]` guard. The #313 SPEC's out-of-scope section named
`is_valid_commit` as another carrier of the same pattern but did not name
`check_branch_is_ahead`; #314 was filed to close that gap.

## Scope

### In scope

The smallest change set that closes the issue:

1. `scripts/core/src/git.sh` — rewrite the `git::check_branch_is_ahead`
   argument-parsing prologue (lines 306-309) to mirror the fixed
   `git::check_branch_is_behind` (lines 281-289): declare `branch` without
   `-r`, guard `$1` against `-*`, assign + `shift` only for a real branch
   name, else fall back to `git::current_branch "$@"`. No other behavior
   change.
2. `tests/core/git.bats` — add a distinguishing regression test that sets up
   a remote with local genuinely ahead, wires `branch.main.merge`, and
   asserts `git::check_branch_is_ahead -C "$REPO_DIR"` returns 0. Under the
   bug the function returns 1 (no `branch.-C.merge`), so a 0 proves `-C` was
   preserved.

### Out of scope

- **`git::is_valid_commit`** (`scripts/core/src/git.sh:197-202`) has the same
  `${1:-...}` + `shift` footgun. It was named in the #313 SPEC. File a
  separate issue if it needs the same guard; do not fix it here.
- **`git::check_branch_is_ahead` symmetric-difference semantics** — the
  function uses `rev-list --count "${upstream}...${branch}"` (three-dot
  symmetric difference), so it returns 0 (true) on *any* divergence, not only
  when local is strictly ahead. That is pre-existing behavior and out of
  scope; this fix only repairs argument parsing.
- **#315** (`add_to_gitignore` dedup unescaped regex, `git.sh:586,591`) and
  **#316** (`git.sh` whole-file `shfmt` formatting) are separate issues on the
  same file. They are parallel, not blocking.

## Impact

- **Modules/files touched:** `scripts/core/src/git.sh` (function
  `git::check_branch_is_ahead`, ~5 lines), `tests/core/git.bats` (one new
  `@test` block).
- **Blast radius:** dev-only / silent regression. The one real caller,
  `scripts/core/src/sloth_update.sh:147`
  (`git::check_branch_is_ahead "${SLOTH_DEFAULT_BRANCH:-main}" "${SLOTH_UPDATE_GIT_ARGS[@]}"`),
  passes the branch name explicitly as `$1`, so it is **not** currently
  bitten — the bug only triggers when `-C` (or any `-*` flag) is the *first*
  argument. No current caller uses the option-first form. The fix is
  preventive: it closes the trap before a caller adopts
  `check_branch_is_ahead -C "$REPO"`. If the fix were wrong (e.g. broke the
  explicit-branch path), `sloth_update.sh`'s unpushed-commits detection would
  silently misfire — caught by the existing explicit-branch test path.
- **Detection lead time:** silent — a caller using the option-first form
  would get a wrong "not ahead" result with no error message. The regression
  test is the detection mechanism.

## Rules that must never be violated

From `CLAUDE.md` hard rules + `docs/architecture/ARCHITECTURE.md`:

- **Core libraries (`scripts/core/src/*.sh`) must not source or execute user
  dotfiles scripts** — this fix stays inside `git.sh`, a core library. ✓
- **`set -euo pipefail` is intentionally omitted in sourced library files**
  (`ARCHITECTURE.md` invariant, line 38) — `set -e` would propagate to the
  caller's shell. The fix must not add `set -e` to `git.sh`. ✓
- **Shell compatibility:** all scripts must be bash-compatible; shfmt lints
  as bash. The guard uses `[[ ]]` (bash), consistent with the rest of
  `git.sh` and the fixed `check_branch_is_behind`. ✓
- **Evidence over reflex:** the "no current callers" claim in the issue body
  is inaccurate — `sloth_update.sh:147` is a caller (passes branch
  explicitly, not currently bitten). The SPEC records this with the file
  path rather than repeating the issue's claim. ✓
- **Track, don't inline:** `is_valid_commit` (same footgun) is out of scope
  and left for a separate issue, not silently fixed here. ✓

## Risks

- **Operational risks:** n/a — no scheduled job, queue, cache, or schema
  interaction. `check_branch_is_ahead` is a read-only git query.
- **Security risks:** n/a — no auth, secrets, PII, webhooks, or rate-limits.
  The function reads a local git config value and runs `git rev-list`.
- **Compliance touchpoints:** n/a.
- **Migration / backwards-compat:** none. The fix changes argument parsing
  only for the option-first call form (`-C` as `$1`), which currently
  misbehaves. The explicit-branch form (`check_branch_is_ahead main -C $REPO`)
  and the no-arg form (`check_branch_is_ahead`) are unchanged: `$1` is `main`
  (not a flag) or empty, both taking the same branch as before. No caller
  relies on the buggy option-first behavior.

## Acceptance criteria

- [ ] `git::check_branch_is_ahead -C "$REPO"` preserves `-C` as a git option
  and resolves the branch via `git::current_branch "$@"` (unit/integration —
  the new bats test). **Test layer:** integration (real temp git repo, per
  `tests/core/git.bats` tier (a)).
- [ ] The new test **distinguishes buggy from fixed behavior**: under the bug
  it returns 1 (no `branch.-C.merge`), under the fix it returns 0 (local
  ahead, upstream found). A test that returns non-zero under both is not
  acceptable — it must assert status 0. (Manual verification: temporarily
  revert the fix and confirm the test fails.)
- [ ] The explicit-branch call form
  `git::check_branch_is_ahead main -C "$REPO"` still works (the existing
  `sloth_update.sh:147` path). **Test layer:** covered by the no-upstream
  return-1 test pattern + the new test's setup; add a minimal explicit-branch
  assertion if the existing suite does not already exercise it.
- [ ] The no-arg form `git::check_branch_is_ahead` (branch defaults to
  current) is unchanged.
- [ ] Verification gate green: `shfmt -d` clean on the edited region of
  `git.sh`; `shellcheck` clean on `git.sh`; `bats --recursive tests/` passes
  (158 → 159 tests, 0 fail). Note: `scripts/self/lint` and
  `scripts/self/static_analysis` require `SLOTH_PATH` and may fail in a
  worktree; fall back to running `shfmt` and `shellcheck` directly on
  `git.sh` (per the project's documented worktree caveat).
- [ ] Updated `docs/fix/README.md` — fix #314 row added with status
  `pending`, removed after merge.

## Rollback

Revert the single PR. No data-side cleanup — the fix is pure code, no
state, no schema, no files written. `git revert <merge-sha>` restores the
previous (buggy) behavior. Nothing is preserved or lost beyond the code
change.

## Effort

**XS** — one commit, ~5 lines of code + one test block. The fix is a
mechanical mirror of the already-merged `check_branch_is_behind` guard (PR
#313, commit `80e3f49`). ≤ 1h.

## Impact (extra)

- **Layers touched:** `scripts/core/src/` (core library layer) —
  `git.sh` only. No context scripts, no user dotfiles, no entry point.
- **Modules/files:** `scripts/core/src/git.sh` (function
  `git::check_branch_is_ahead`), `tests/core/git.bats`.
- **Blast radius:** dev-only, silent regression, preventive fix. See Impact
  above.
- **Detection lead time:** silent without the test; the test is the guard.

## Rules that must never be violated (extra)

See "Rules that must never be violated" above — all invariants from
`CLAUDE.md` hard rules and `docs/architecture/ARCHITECTURE.md` (lines 27-39)
are honored. The fix adds no `set -e`, stays inside the core library layer,
uses bash-compatible `[[ ]]`, and does not touch user dotfiles.

## Operational risks

n/a — `check_branch_is_ahead` is a read-only git query (`git config --get`
+ `git rev-list --count`). No scheduled job, queue, cache, schema, or
external-adapter interaction. No concurrency hazard (git config + rev-list
are local, atomic reads).

## Security risks

n/a — no auth, secrets, PII, webhooks, or rate-limits. The function reads a
local git config key (`branch.<name>.merge`) and runs `git rev-list`. The
fix does not change what data is read or where it goes.

## Compliance touchpoints

n/a — dotSloth is a dotfiles framework; no data-retention, regional, or
consumer-protection rules apply to a git branch-status query.

## Affected docs

- `docs/fix/README.md` — add the #314 row (status `pending`), remove after
  merge. (Acceptance criterion above.)
- No other docs need update: the function's docstring
  (`scripts/core/src/git.sh:302-305`) already documents
  `@param string local_branch current branch by default` — the fix makes
  the code match that contract (options are not branch names).

## Observability

The fix has no runtime log line (the function returns a status code, not a
message). Health is confirmed by the bats suite: the new test passing proves
`-C` is preserved. If the fix regresses silently, the test fails in CI —
that is the alert. No metric or prod-side observability applies (dev-only,
no prod deployment of this library function).

## Cross-issue notes

- **#308 / #313 (merged)** — the reference fix. `check_branch_is_behind`
  was fixed with the `[[ "$1" != -* ]]` guard in PR #313 (commit `80e3f49`).
  This fix applies the identical pattern to the twin function. No dependency;
  #313 is already on `main`.
- **#315** (`add_to_gitignore` dedup unescaped regex, `git.sh:586,591`) —
  same file, different function (line 586 vs 306), no overlap. **Parallel**,
  no merge conflict expected (disjoint regions).
- **#316** (`git.sh` whole-file `shfmt` formatting) — same file. If #316
  lands first it reformats the whole file including this fix's region; if
  #314 lands first, #316's rebase is trivial (formatting-only). **Parallel**,
  low conflict risk. Recommended order: #314 (behavior) before #316
  (formatting) so the formatter cleans the fix's region too.
- **`is_valid_commit`** (`git.sh:197-202`) — same footgun, named in #313's
  out-of-scope. Not yet filed as an issue. Out of scope here; file separately
  if it needs the guard.

## Decisions made during drafting

- **Topic slug `ahead-C-option-footgun`** — kebab-case, ≤ 40 chars, no
  leading verb, describes the defect (the `-C` option is consumed by the
  shift footgun). Branch `fix/314-ahead-C-option-footgun`.
- **Test setup uses push-then-commit** (not a standalone divergent remote)
  so local is *genuinely* ahead (1 commit ahead of `origin/main`), giving
  clean `rev-list --count` semantics. This avoids the "diverged, not ahead"
  ambiguity that a two-independent-roots setup would create.
- **The issue body's "No current callers in `scripts/`" claim is
  inaccurate** — `sloth_update.sh:147` is a caller. Recorded with evidence
  in Impact rather than repeated. The fix conclusion (preventive) is
  unchanged: that caller passes the branch explicitly and is not bitten.
- **No `set -e` added** — per `ARCHITECTURE.md` line 38, sourced library
  files intentionally omit `set -euo pipefail`. The fix preserves this.
- **`is_valid_commit` left for a separate issue** — track-don't-inline; not
  silently fixed here even though the pattern is identical.
