# SPEC: 04-upstream-sync

## Summary

Synchronize compatible improvements from upstream CodelyTV/dotly into dotSloth without breaking existing functionality. dotSloth has diverged significantly (198 unique files vs 53 upstream-only), so this is a selective, file-by-file sync — not a structural merge.

## Motivation

- Upstream has bug fixes and improvements in common files (69 shared) that dotSloth lacks
- Upstream has useful utility scripts (`git-discard`, `git-undo`) not in dotSloth
- Upstream core modules (`args.sh`, `collections.sh`, `documentation.sh`, etc.) may have fixes worth incorporating
- The existing `docs/DIFF_REPORT_UPSTREAM.md` (2026-07-03) provides the baseline analysis

## Scope

### In scope
1. Sync compatible bug fixes and improvements to the 69 shared files
2. Port useful upstream-only utility scripts (`bin/git-discard`, `bin/git-undo`)
3. Incorporate improvements from upstream core modules into dotSloth's `scripts/core/src/`
4. Update `scripts/core/_main.sh` if upstream has sourced-module improvements

### Out of scope
- Structural restructuring (dotSloth keeps `scripts/core/src/`, upstream uses flat layout)
- Removing dotSloth-unique features (home automation, PV systems, Tesla integrations)
- Changing `bin/dot` structure (dotSloth's 196-line version is intentionally more complex)
- Git submodules approach (upstream uses dotbot/z modules; dotSloth has its own system)

## Approach

### Phase 1: Audit upstream changes since last sync
- Diff each shared file between `upstream/main` and `HEAD`
- Categorize changes: bug fix / improvement / breaking / cosmetic
- Identify which changes are safe to cherry-pick

### Phase 2: Sync core module improvements
- Port upstream improvements to `scripts/core/src/` modules
- Ensure `_main.sh` sourcing still works correctly
- Verify no regressions in `scripts/self/static_analysis` and `scripts/core/lint`

### Phase 3: Port utility scripts
- Add `bin/git-discard` and `bin/git-undo` from upstream
- Adapt any path references (`DOTLY_PATH` → `SLOTH_PATH`)
- Add `set -euo pipefail` per project standards

### Phase 4: Sync bin/ and scripts/ improvements
- Apply upstream improvements to shared bin files (`bin/$`, `bin/pbcopy`, `bin/pbpaste`)
- Sync improvements to `scripts/package/`, `scripts/symlinks/`, etc.
- Each sync is a separate commit for easy revert if needed

## Acceptance criteria

- `bash scripts/self/static_analysis` passes
- `bash scripts/core/lint` passes
- `make test` passes (60 tests)
- No dotSloth-unique functionality is removed or broken
- Each synced file is a separate commit with clear message referencing upstream change
- Upstream remote is configured for future syncs

## Dependencies

- None (no roadmap dependencies)

## Size

M — multi-file sync across ~69 shared files, needs careful per-file analysis

## Issue

Closes #239
