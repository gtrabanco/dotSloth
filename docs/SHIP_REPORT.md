# SHIP REPORT

**Run date:** 2026-07-08
**Run mode:** `ship-roadmap --continue --fullauto`
**Branch:** `main` (sweep + shipped fixes)

## Sweep summary

15 open issues triaged:

| Disposition | Count | Issues |
|-------------|-------|--------|
| fix-now (shipped) | 2 | #319, #315 |
| wontfix (closed) | 4 | #316, #222, #218, #217 |
| deferred (closed) | 3 | #236, #237, #238 |
| postpone (left open) | 6 | #312, #300, #296, #273, #268, #224 |

## Shipped fixes

### PR #320 — `fix(git): guard is_valid_commit prologue against -C footgun` (Closes #319)

- **File:** `scripts/core/src/git.sh` — `is_valid_commit` prologue rewritten with `[[ "$1" != -* ]]` guard
- **Test:** distinguishing regression test (`is_valid_commit -C "$REPO_DIR"` with no explicit commit)
- **Gate:** shfmt ✓, shellcheck ✓, bats 23/23 ✓

### PR #321 — `fix(git): use fixed-string grep in add_to_gitignore dedup` (Closes #315)

- **File:** `scripts/core/src/git.sh` — `grep -q "^${content}$"` → `grep -Fxq` (fixed-string, whole-line)
- **Bonus:** removed dead `echo > /dev/null 2>&1` line
- **Test:** distinguishing regression test (glob metacharacters: `foo.bar` vs `fooXbar`)
- **Gate:** shfmt ✓, shellcheck ✓, bats 23/23 ✓

## Issue state after sweep

| Issue | State | Disposition |
|-------|-------|-------------|
| #319 | closed (by PR #320) | fix-now |
| #315 | closed (by PR #321) | fix-now |
| #316 | closed | wontfix (shfmt passes, cleaned by #313) |
| #222 | closed | wontfix (stale 2022 discussion) |
| #218 | closed | wontfix (stale 2022 discussion) |
| #217 | closed | duplicate of #224 |
| #236 | closed | deferred (Rust migration) |
| #237 | closed | deferred (Rust migration) |
| #238 | closed | deferred (Rust migration) |
| #312 | open | postpone (stale fix folders cleanup) |
| #300 | open | postpone (set -euo pipefail audit) |
| #296 | open | postpone (restorer symlink restore) |
| #273 | open | postpone (gem.bats test quality) |
| #268 | open | postpone (restorer/installer tests) |
| #224 | open | postpone (documentation improvements) |

## Remaining open issues (8 total)

**Postpone (6):** #312, #300, #296, #273, #268, #224 — no trigger met, left for future passes.

## Run decisions

- **PR #320 (fix #319):** OPEN — auto-merge not enabled at repo level; needs manual squash-merge.
- **PR #321 (fix #315):** OPEN — same; needs manual squash-merge.
- **Deferred features (#236, #237, #238):** closed per SHIP_DECISIONS.md (Rust migration requires native binary distribution infrastructure).

## Verification

- `shfmt -ln bash -sr -ci -i 2 -d` — clean on both branches
- `shellcheck -s bash` — clean on both branches
- `bats --recursive tests/` — 23/23 on both branches (159 total across full suite)
