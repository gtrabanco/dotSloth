# Review Report — Feature 07 (restorer-v2)

**Date:** 2026-07-06
**Branch:** `feat/07-restorer-v2`
**Commits:** `a0a920a` (docs), `8963732` (implementation)
**Gate:** static_analysis ✓, lint ✓, 96 tests ✓

## Summary

The restorer script (`restorer`) was enhanced with validation, rollback, progress feedback, and component flags. The changes are additive — new functions and flags, no rewrite of existing logic. The script remains self-contained (no `scripts/core/src/` dependencies).

## Changes reviewed

- Argument parsing: added `--dry-run`, `--components`, `--components=` flags + `shift` (fixes latent infinite-loop bug)
- New functions: `show_progress`, `has_component`, `validate_dotfiles`, `create_rollback_point`, `rollback`, `restorer_cleanup` (EXIT trap)
- Validation: `validate_dotfiles()` called when `--continue` + existing dotfiles
- Rollback: `create_rollback_point()` before destructive ops; `restorer_cleanup` trap offers rollback on failure
- Progress: `[n/total]` output at each phase
- Component gating: `dotfiles` (submodule + core install), `packages` (import), `shell`/`symlinks` (noted as via core install)
- Dry-run: prints planned actions, skips actual operations
- Version bumped to v2.0.0

## Findings

| # | Severity | Finding | Disposition |
|---|----------|---------|-------------|
| 1 | LOW | Indentation in dry-run clone block inconsistent | Postpone (style only, restorer excluded from shellcheck) |
| 2 | LOW | `has_component` uses `echo \| grep -q` (subshell) | Postpone (acceptable for once-run script) |
| 3 | LOW | Rollback saves symlinks list but doesn't restore them | Postpone (accepted risk, noted in SPEC) |
| 4 | INFO | Original arg parsing missing `shift` — fixed as side effect | No action needed (bug fix) |
| 5 | INFO | `shell`/`symlinks` components show progress but work is in `dot core install` | No action needed (design noted in SPEC) |

## Verdict

**No fix-now findings.** Implementation matches SPEC, gate is green, known limitations are documented.

## Manual verification checklist

- [ ] `bash restorer --help` shows new flags
- [ ] `bash restorer --version` shows v2.0.0
- [ ] `bash restorer --dry-run` (with DOTLY_ENV=CI) prints planned actions without making changes
- [ ] `bash restorer --components=dotfiles` (with DOTLY_ENV=CI) skips package import
