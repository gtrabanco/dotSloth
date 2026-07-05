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
- [ ] Add `bin/git-discard` from upstream (adapt paths)
- [ ] Add `bin/git-undo` from upstream (adapt paths)
- [ ] Add `set -euo pipefail` to both scripts
- [ ] Verify scripts are executable

## P4: Sync bin/ and scripts/ improvements
- [ ] Apply upstream improvements to shared bin files
- [ ] Sync improvements to `scripts/package/`, `scripts/symlinks/`, etc.
- [ ] Each sync is a separate commit

## Completion
- [ ] `bash scripts/self/static_analysis` passes
- [ ] `bash scripts/core/lint` passes
- [ ] `make test` passes (60 tests)
- [ ] No dotSloth-unique functionality removed
- [ ] All synced files have clear commit messages
