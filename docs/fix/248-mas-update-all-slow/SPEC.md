# fix/248-mas-update-all-slow

> Fix for `mas::update_all()` performance and hanging issues.

## Goal

Fix `mas::update_all()` in `scripts/package/src/package_managers/mas.sh` to
eliminate redundant `mas` calls, add timeout protection, and prevent hanging on
Apple ID prompts.

## Issue

`#248` — tracked issue. The PR must close it.

## Branch

`fix/248-mas-update-all-slow`

## Root cause

`mas::update_all()` (lines 39-62) has three performance problems:

1. **`mas list` called 3x per outdated app** (lines 49-50) — once for `app_list_line` lookup, once for `app_old_version`, plus once in the loop iteration context.
2. **`mas info` called 2x per outdated app** (lines 51, 53) — once for version, once for URL.
3. **No timeout on `mas upgrade`** (line 59) — hangs indefinitely on Apple ID prompt.

For N outdated apps, this results in 5+ `mas` CLI invocations per app. With 50
outdated apps, that's 250+ subprocess calls.

## Scope

### In scope

- Cache `mas list` output once at the start of `mas::update_all()`.
- Parse version info from cached data instead of calling `mas list`/`mas info` per app.
- Add timeout to `mas upgrade` (30s default, configurable).
- Suppress Apple ID prompt by using non-interactive mode.

### Out of scope

- `mas::install()` timeout (separate issue).
- `mas::uninstall()` timeout (separate issue).
- Refactoring other package managers (pip, dnf, etc.).

## Impact

- **Files touched:** `scripts/package/src/package_managers/mas.sh` only.
- **Blast radius:** `mas::update_all()` is called by `dot up`. If the fix is wrong,
  update detection or upgrade could fail silently.
- **Detection lead time:** Immediate — user sees the fix (or failure) on next `dot up`.

## Rules that must never be violated

- Pure bash, no new dependencies.
- Preserve all existing output format (emoji, tree structure).
- Preserve `log::file` usage for upgrade logging.
- Preserve `output::answer`/`output::write`/`output::empty_line` calls.
- `set -euo pipefail` must be maintained.

## Risks

- **Operational:** `mas upgrade` with timeout may leave partial upgrades.
- **Security:** n/a — no credential changes.
- **Compliance:** n/a — internal tooling only.

## Acceptance criteria

- [ ] `mas list` is called exactly once in `mas::update_all()`.
- [ ] `mas info` is called at most once per app (only for display, not for version).
- [ ] `mas upgrade` has a 30s timeout by default.
- [ ] Apple ID prompt is suppressed (non-interactive mode).
- [ ] `make test` passes (48/48).
- [ ] `bash scripts/self/lint` passes.

## Rollback

Revert the commit — `mas.sh` is unchanged otherwise. No data cleanup needed.

## Effort

**XS** — single file, single function, well-contained change.
