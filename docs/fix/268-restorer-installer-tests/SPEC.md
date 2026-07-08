# fix/268-restorer-installer-tests

## Goal

Add unit and integration tests for the `restorer` and `installer` scripts' core
utility functions. These are the two largest untested critical paths in the
project — both are self-contained bootstrap scripts (~500 lines each) with no
test coverage. The mock harness from feature 09 (#303) now unblocks this.

## Issue

`#268`

## Branch

`fix/268-restorer-installer-tests`

## Root cause

Feature 05 (testing-framework) explicitly excluded restorer/installer from scope
(`docs/features/05-testing-framework/SPEC.md:62`). The mock harness (feature 09)
was built to unblock this gap. Bugs like #234 (4 restorer bugs) went undetected
because there were no tests.

## Scope

### In scope

**Restorer tests** (`tests/core/restorer.bats`):
1. `has_component()` — pure logic: "dotfiles" in "dotfiles,packages" → 0; "shell" not in "dotfiles" → 1
2. `validate_dotfiles()` — integration: mock git repo → 0; missing dir → 1; non-git dir → 1; no HEAD → 1
3. `create_rollback_point()` + `rollback()` — integration: creates rollback dir with dotfiles copy and symlinks.txt; rollback restores both
4. `backup_dotfiles_dir()` — unit: existing dir → renamed to `*.back`; non-existing → mkdir succeeds

**Installer tests** (`tests/core/installer.bats`):
1. `create_dotfiles_dir()` — unit: existing dir → backup created; non-existing → mkdir succeeds
2. `command_exists()` — already tested in `tests/core/dot.bats`, skip

### Out of scope

- Full interactive flow testing (git clone, user prompts, package import) — requires
  PTY mocking beyond bats scope. Covered by `--dry-run` manual verification.
- `install_clt()`, `start_sudo()`, `stop_sudo()` — macOS-specific, hard to mock.
- `restorer_cleanup()` — trap-based, tested implicitly via integration.

## Impact

- **Files touched:** `tests/core/restorer.bats` (new), `tests/core/installer.bats` (new)
- **Blast radius:** test-only, no production code changes
- **Detection lead time:** immediate — tests run on every PR via CI

## Rules that must never be violated

- Tests must not depend on network access (mock git, curl, etc.)
- Tests must not modify `$HOME` or system state (use temp dirs)
- Tests must work on both Linux and macOS CI
- `set -euo pipefail` intentionally omitted in sourced library files (ARCHITECTURE.md)

## Risks

- **Operational:** None — test-only change
- **Security:** None — no secrets, no auth, no PII
- **Compliance:** n/a

## Acceptance criteria

- [ ] `tests/core/restorer.bats` created with ≥4 test cases
- [ ] `tests/core/installer.bats` created with ≥2 test cases
- [ ] All tests pass: `bats tests/core/restorer.bats tests/core/installer.bats`
- [ ] No existing tests broken: `bats --recursive tests/`
- [ ] shfmt + shellcheck clean on any new/modified files

## Rollback

`git revert` — test-only, no data cleanup needed.

## Effort

S — ~1h. Mock harness exists, functions are isolated, bats patterns established.

## Cross-issue notes

- **#273** (gem.bats regression guards) — parallel, unrelated
- **#296** (restorer rollback symlinks) — already merged; tests will cover the new behavior
- **#303** (mock harness) — prerequisite, already merged
