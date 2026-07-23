# fix/329-bun-dump-readonly-error

> Fix specification. Copy this folder to `docs/fix/<issue-number>-<topic>/`, fill
> every section, and register the entry in `docs/fix/README.md`. Lighter than a
> feature spec — no planning artifacts. The SPEC alone is the source of truth.

## Goal

Fix `dot package dump` crashing with a `readonly variable` error when processing a user's custom `.sh` file in `~/.dotfiles/package/managers/` that lacks a `dump` function. The dump script sources the file before verifying the `dump` function exists, causing a crash on files that cannot be sourced cleanly.

## Issue

`#329` — tracked issue. Required. The PR must close it.

## Branch

`fix/329-bun-dump-readonly-error`

## Root cause

The dump script (`scripts/package/dump`, line 50) calls `package::load_manager "$package_manager"` to source a package manager file **before** verifying that the sourced file actually defines the `dump` function. The guard condition at line 43 (`! package::command_exists "$package_manager" "dump"`) should skip files without a dump function, but the `load_manager` call at line 50 still sources the file unconditionally inside the block.

When a user places a custom `.sh` file in `~/.dotfiles/package/managers/` (e.g., a bun recipe file that happens to define `bun::is_available` but no `bun::dump`), the sourcing step can fail with a `readonly variable` error or other parse errors, crashing the entire dump loop.

Evidence:
- `scripts/package/dump` line 50: `package::load_manager "$package_manager"` — sources the file
- `scripts/package/dump` line 43: `! package::command_exists "$package_manager" "dump"` — guard check, but `load_manager` is called inside the block after this check
- `scripts/core/src/package.sh` line 62: `package::load_manager` calls `dot::load_library` which sources the file via `.`
- The bun recipe (`scripts/package/src/recipes/bun.sh`) has no `dump` function, only recipe functions (`install`, `uninstall`, `version`, etc.)
- `scripts/core/src/package.sh` line 88: `script::function_exists` checks for function presence by sourcing the file in a subshell

## Scope

### In scope

- Reorder the dump script so the dump function check (`package::command_exists "$package_manager" "dump"`) is evaluated **before** `package::load_manager "$package_manager"` is called, ensuring files without a dump function are never sourced.
- Add defensive error handling around `package::load_manager` to gracefully skip any package manager file that fails to source.

### Out of scope

- Adding a `dump` function to the core bun recipe — out of scope; bun is a recipe, not a package manager wrapper.
- Validating package manager wrapper files for interface compliance in `package::load_manager` — would be a broader change; tracked separately (see Cross-issue notes).
- Changing `get_available_package_managers` to validate full package manager interface — broader refactoring; not required for this fix.

## Impact

- **Modules/files touched:**
  - `scripts/package/dump` — the only file modified (reorder lines 49–50, add error guard on `load_manager`)
- **Blast radius:** Minimal. The change only affects the order of operations in the dump loop. No new logic, no new dependencies.
  - If wrong: a package manager without a dump function could crash the dump script (same as current behavior).
  - Best case: the fix prevents the crash and skips the file cleanly.
- **Detection lead time:** Immediate — `dot package dump` either succeeds or fails. No silent degradation possible.

## Rules that must never be violated

- **Shell compatibility:** all scripts must be POSIX-compatible bash (`CLAUDE.md` → Workflow conventions). No bashisms that break on macOS default bash (3.2).
- **`set -euo pipefail`:** the dump script already uses this header (line 2). The fix must not change this.
- **Core libraries must not source user dotfiles scripts** (`docs/architecture/ARCHITECTURE.md` → Dependency rules). The dump script sources user package manager files — this fix makes that sourcing safer by checking first.
- **Evidence over reflex:** every claim in this SPEC cites a file path and line number.
- **Track, don't inline:** new problems found during implementation become separate `docs/fix/` entries, never silently fixed here.

## Risks

### Operational risks
- **Sourcing side effects:** If a custom package manager file has side effects during sourcing (variable assignments, function definitions), the `|| continue` guard on `load_manager` will still source the file (the error occurs during sourcing). The guard prevents the *dump call* from executing, but the file is still sourced. This is acceptable — the file was going to be sourced anyway, and the guard simply prevents downstream errors.
- **No scheduled jobs or queue interactions.** The dump script is user-invoked only.

### Security risks
- **No auth, secrets, PII, or webhooks involved.** The dump script writes package lists to local files.
- **Rate-limits:** n/a.

### Compliance touchpoints
- n/a. No data retention, regional, or consumer-protection rules apply to a local package dump.

### Migration / backwards-compat
- n/a. No schema changes, no API changes, no user-visible behavior change (the fix only prevents a crash).

## Acceptance criteria

- [ ] **Unit/Integration: `dot package dump` runs without error when a custom `.sh` file in `~/.dotfiles/package/managers/` lacks a `dump` function.** Test by placing a minimal `.sh` file with only a function definition (no `dump`) and running `dot package dump`. The script should skip the file gracefully.
- [ ] **Integration: `dot package dump` still works correctly for package managers that DO have a `dump` function.** Verify that existing package managers (brew, npm, pip, etc.) still dump correctly after the fix.
- [ ] **Integration: The bun recipe (`scripts/package/src/recipes/bun.sh`) does not appear in the dump loop.** Confirmed by checking that `bun` is not in `package::get_available_package_managers` output (bun is a recipe, not a package manager wrapper, and has no `is_available` function in the core).
- [ ] **Lint: `./scripts/core/lint` passes (shfmt).** No new syntax introduced.
- [ ] **Static analysis: `./scripts/core/static_analysis` passes (shellcheck).** No new warnings introduced.
- [ ] **Verification gate: `./scripts/core/lint && ./scripts/core/static_analysis` passes.**

## Rollback

Revert the single commit on the fix branch:
```bash
git revert <commit-sha>
```
No data-side cleanup needed — the fix only changes script logic, no data is modified.

## Effort

**XS** — single-line reorder plus one `|| continue` guard on an existing function call. One commit, ≤ 1 hour.