# 07 — restorer-v2

> Feature specification. Improve the restorer script with validation, rollback, and progress feedback.

## Goal

Improve the `restorer` bootstrap script to add: (1) validation of existing dotfiles before overwriting, (2) automatic rollback on failure, (3) progress feedback during long operations, and (4) a `--components` flag for partial restoration. The restorer is the recovery path when a user's system is broken — it must be reliable and informative.

## Branch

`feat/07-restorer-v2`

## Size

**M** — the restorer is 530 lines and the improvements touch multiple sections. Phased execution.

## Dependencies

None. The restorer is a standalone script.

## Context

Issue #242 requests validation, rollback, partial restore, and progress feedback. The restorer was fixed in #234 (4 bugs) but remains fragile: if it fails mid-operation, it leaves the system in an inconsistent state. The product audit (2026-07-06) noted no tests exist for the restorer (#268). This feature adds safety mechanisms without rewriting the script from scratch.

## Business goals

n/a (internal/technical feature)

## Technical goals

1. Validate dotfiles backup before overwriting existing files
2. Create a rollback point before destructive operations (backup existing dotfiles, symlinks)
3. On failure, offer to rollback to the pre-restore state
4. Show progress steps during the restore flow
5. Support `--components` flag to restore only specific parts (dotfiles, packages, symlinks, shell)
6. Keep the script self-contained (no dependency on `scripts/core/src/`)

## Scope

### In scope

- Add `validate_dotfiles()` function — check git repo is accessible, has expected structure
- Add `create_rollback_point()` — backup existing dotfiles dir + symlinks list to a temp location
- Add `rollback()` — restore from rollback point
- Add `--components` flag — accept `dotfiles`, `packages`, `symlinks`, `shell` (default: all)
- Add progress output (`[1/4] Validating...`, `[2/4] Cloning...`, etc.)
- Add `--dry-run` flag — show what would be done without making changes
- Wrap the main flow in a trap that offers rollback on failure

### Out of scope / non-goals

- Complete rewrite of the restorer (incremental improvement only)
- Checksum-based validation (git clone already validates integrity)
- GUI/TUI progress bar (text output is sufficient)
- Tests for the restorer (tracked separately in #268 — the restorer is a bootstrap script that's hard to test in CI)

## Architecture impact

The restorer is a standalone script (per ARCHITECTURE.md: "must be self-contained — they run before dotSloth is installed"). All new functions must be self-contained — no sourcing of `scripts/core/src/`. The improvements are additive: new functions + a trap, no rewrite of existing logic.

Invariants to respect:
- The restorer must not depend on `SLOTH_PATH` or `scripts/core/src/`
- All new code must work with bash 3.2 (macOS default)
- `set -euo pipefail` must be maintained

## Design

### `validate_dotfiles()`

```bash
validate_dotfiles() {
  local dotfiles_path="$1"
  [[ -d "$dotfiles_path" ]] || return 1
  [[ -d "$dotfiles_path/.git" ]] || return 1
  [[ -f "$dotfiles_path/shell/exports.sh" ]] || return 1
  git -C "$dotfiles_path" rev-parse HEAD >/dev/null 2>&1 || return 1
  return 0
}
```

### `create_rollback_point()`

```bash
create_rollback_point() {
  ROLLBACK_DIR=$(mktemp -d "/tmp/dotSloth-rollback-XXXXXX")
  if [[ -d "$DOTFILES_PATH" ]]; then
    cp -a "$DOTFILES_PATH" "$ROLLBACK_DIR/dotfiles"
  fi
  # Save symlink list
  ls -la "$HOME" | grep '^l' > "$ROLLBACK_DIR/symlinks.txt" 2>/dev/null || true
  echo "$ROLLBACK_DIR"
}
```

### `rollback()`

```bash
rollback() {
  local rollback_dir="$1"
  [[ -d "$rollback_dir" ]] || return 1
  if [[ -d "$rollback_dir/dotfiles" ]]; then
    rm -rf "$DOTFILES_PATH"
    mv "$rollback_dir/dotfiles" "$DOTFILES_PATH"
  fi
  _e "Rolled back to pre-restore state."
}
```

### Progress output

```bash
show_progress() {
  local current="$1" total="$2" message="$3"
  _w "[$current/$total] $message"
}
```

### `--components` flag

```bash
# Parse --components=dotfiles,packages,symlinks,shell
COMPONENTS="${COMPONENTS:-dotfiles,packages,symlinks,shell}"
```

### Failure trap

```bash
restorer_cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]] && [[ -n "${ROLLBACK_DIR:-}" ]]; then
    _e "Restore failed. Would you like to rollback? [Y/n]"
    read -r reply
    [[ "${reply:-Y}" =~ ^[Yy] ]] && rollback "$ROLLBACK_DIR"
  fi
  [[ -n "${SUDO_PID:-}" ]] && stop_sudo
}
trap restorer_cleanup EXIT
```

## Decisions to confirm

1. **Validation depth:** Check directory exists + `.git` exists + `shell/exports.sh` exists + git HEAD resolves. Not checksum-based (git clone validates integrity).
2. **Rollback scope:** Backup the existing dotfiles directory + symlink list. Not individual files (too slow for large dotfiles).
3. **Components:** `dotfiles`, `packages`, `symlinks`, `shell` — matching the main restore phases.
4. **Progress:** Simple `[n/total]` text output, no TUI.
5. **Dry-run:** `--dry-run` flag shows what would be done, makes no changes.

## Acceptance criteria

1. `validate_dotfiles()` function exists and is called before overwriting
2. `create_rollback_point()` is called before destructive operations
3. `rollback()` function exists and is offered on failure via trap
4. `--components` flag is accepted and filters which phases run
5. `--dry-run` flag is accepted and shows planned actions without making changes
6. Progress output shows `[n/total]` during the restore flow
7. `bash scripts/core/static_analysis` passes (restorer is excluded from shellcheck per ARCHITECTURE.md, but must pass bash syntax check)
8. `bash scripts/core/lint` passes
9. `make test` passes with 96 tests (no regressions)

## Testing requirements

The restorer is a bootstrap script that's hard to test in CI (it clones repos, installs packages, modifies the shell). Tests are tracked separately in #268. This feature focuses on the implementation. Manual verification: run `restorer --dry-run` to verify the flow.

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| Normal restore | Full restore from GitHub | `bash restorer` |
| Dry run | Shows planned actions | `bash restorer --dry-run` |
| Partial restore | Only dotfiles, no packages | `bash restorer --components=dotfiles` |
| Failure + rollback | Clone fails, rollback offered | Simulate by using invalid git URL |

## Phases

P1: Add validation, rollback point, progress output, failure trap — safety mechanisms.
P2: Add `--components` and `--dry-run` flags — partial restore and preview mode.

## Deploy & rollback

n/a — merging the PR is sufficient. Rollback: revert PR.

## Open questions / risks

- The rollback backup could be large if the user has many dotfiles — accepted risk (temp dir, cleaned on success).
- The trap fires on any non-zero exit — need to be careful with `set -e` interactions.
- bash 3.2 compatibility: no `mapfile`, no associative arrays in the restorer.

## Deliverables

- Modified `restorer` script
- Updated `docs/features/ROADMAP.md` (status flip)

## Post-merge next feature

Issue sweep — all roadmap features done, sweep open issues.
