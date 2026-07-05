# TASKS: 04-upstream-sync

## P1: Audit upstream changes
- [x] Add upstream remote temporarily
- [x] Diff each shared file between `upstream/main` and `HEAD`
- [x] Categorize changes: bug fix / improvement / breaking / cosmetic
- [x] Document safe-to-cherry-pick changes in `AUDIT.md`
- [ ] Remove upstream remote after audit

## P2: Sync core module improvements
- [x] Port upstream improvements to `scripts/core/src/` modules
- [x] Verify `_main.sh` sourcing still works
- [x] Verify `scripts/self/static_analysis` passes
- [x] Verify `scripts/core/lint` passes

## P3: Port utility scripts
- [x] Add `bin/git-discard` from upstream (adapt paths)
- [x] Add `bin/git-undo` from upstream (adapt paths)
- [x] Add `set -euo pipefail` to both scripts
- [x] Verify scripts are executable

## P4: Sync bin/ and scripts/ improvements
- [x] Apply upstream improvements to shared bin files
- [x] Sync improvements to `scripts/package/`, `scripts/symlinks/`, etc.
- [x] Each sync is a separate commit

## Completion
- [x] `bash scripts/self/static_analysis` passes
- [x] `bash scripts/core/lint` passes
- [x] `make test` passes (60 tests)
- [x] No dotSloth-unique functionality removed
- [x] All synced files have clear commit messages
