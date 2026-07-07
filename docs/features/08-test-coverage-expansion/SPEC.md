# 08 — test-coverage-expansion

> Feature specification. Add behavioral tests for `sloth_update.sh` auto-updater and other critical untested paths.

## Goal

Add bats-core tests for `scripts/core/src/sloth_update.sh` — the auto-updater module that was fixed in #233 (3 bugs) without test coverage. This is a critical path: if the updater breaks silently, users cannot update dotSloth. Also add tests for a few other critical untested library functions.

## Branch

`feat/08-test-coverage-expansion`

## Size

**S** — single-pass execution. The framework is already in place (feature 05). Tests are integration-style: source the library, call functions with controlled inputs, assert on return codes and output.

## Dependencies

None. Feature 05 (testing-framework) is done and merged.

## Context

Feature 05 added bats-core with 11 test files covering ~48% of core libraries. `sloth_update.sh` (417 lines, 9 functions) has zero tests. Issue #267 tracks this gap. The product audit (2026-07-06) flagged it as a high-severity finding. The profile is now "internal tool" — stricter testing is expected.

## Business goals

n/a (internal/technical feature)

## Technical goals

1. Add `tests/core/sloth_update.bats` covering the auto-updater's critical paths
2. Add `tests/core/dot.bats` covering `dot::` namespace functions
3. Add `tests/core/files.bats` covering `files::` namespace functions
4. All tests work without network access (mock git where needed)
5. All tests pass on both macOS and Ubuntu (CI matrix)

## Scope

### In scope

- `tests/core/sloth_update.bats` — tests for:
  - `sloth_update::get_current_version` (git describe output)
  - `sloth_update::get_latest_stable_version` (Homebrew path with mock, git path with mock)
  - `sloth_update::should_be_updated` (stable channel, pinned version, latest channel)
  - `sloth_update::local_sloth_repository_can_be_updated` (clean dir, dirty dir, force version file)
  - `sloth_update::exists_migration_script` (migration script exists, doesn't exist)
  - `sloth_update::sloth_repository_set_ready` (Homebrew path, git path)
- `tests/core/dot.bats` — tests for `dot::list_contexts`, `dot::list_scripts`, `dot::_escape_dotfiles_paths`
- `tests/core/files.bats` — tests for `files::check_if_path_is_older`, `files::get_real_path`

### Out of scope / non-goals

- Tests for `restorer` and `installer` (tracked separately in #268)
- Tests for `gem.bats` functional tests (tracked separately in #273)
- Tests for all 23 libraries (this expands coverage for the most critical paths only)
- Performance/benchmark testing
- Code coverage reporting

## Architecture impact

Adds new test files under `tests/`. No production code changes. Tests follow the existing pattern: source `_main.sh` via `tests/helpers/setup.bash`, use `run` and `assert_*` patterns.

Invariants to respect:
- Tests must not modify production files
- Tests must be idempotent
- Tests must work on both macOS and Linux
- Tests must not require network access

## Design

### Test approach

Integration-style: source the library, call functions with controlled environment variables and mocked external commands. Use PATH manipulation for mocking `git`, `brew` where needed.

### Mocking strategy

- Create a `tests/helpers/mocks/git` script that intercepts `git` commands and returns canned responses
- Set `HOMEBREW_SLOTH=true` to test Homebrew paths without actual Homebrew
- Use temp directories for `SLOTH_PATH`, `DOTFILES_PATH` to avoid touching real files
- Mock `git::git`, `git::is_in_repo`, `git::check_remote_exists` via function overrides in test setup

### Test structure

```bash
#!/usr/bin/env bats

setup() {
  source "$SLOTH_PATH/tests/helpers/setup.bash"
  _setup_test_env
  # Override git functions for testing
  git::git() { :; }
  git::is_in_repo() { return 0; }
}

@test "sloth_update::get_current_version returns version from git describe" {
  ...
}
```

## Decisions to confirm

1. **Mocking approach:** Function overrides in setup() rather than PATH manipulation — simpler, more reliable for bash functions.
2. **Test scope:** Focus on sloth_update.sh (critical path) + dot.sh + files.sh. Other libraries deferred.
3. **No network:** All tests must run without network access. Git remote operations are mocked.

## Acceptance criteria

1. `tests/core/sloth_update.bats` exists with at least 10 test cases
2. `tests/core/dot.bats` exists with at least 3 test cases
3. `tests/core/files.bats` exists with at least 3 test cases
4. `make test` runs all new tests successfully on macOS
5. `make test` runs all new tests successfully on Ubuntu
6. Total test count increases from 62 to at least 78
7. Tests do not require network access or root privileges
8. `bash scripts/core/static_analysis` passes
9. `bash scripts/core/lint` passes

## Testing requirements

Integration tests preferred. Source the library, override external dependencies, call functions, assert on return codes and output. No heavy mocking framework — use bash function overrides in setup().

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| Auto-updater: current version | `sloth_update::get_current_version` returns git describe output | `run bats tests/core/sloth_update.bats` |
| Auto-updater: update available | `sloth_update::should_be_updated` returns 0 when remote is newer | `run bats tests/core/sloth_update.bats` |
| Auto-updater: Homebrew path | Functions return early when `HOMEBREW_SLOTH=true` | `run bats tests/core/sloth_update.bats` |
| Dot namespace: list contexts | `dot::list_contexts` returns context directories | `run bats tests/core/dot.bats` |
| Files namespace: path age | `files::check_if_path_is_older` returns correct boolean | `run bats tests/core/files.bats` |

## Phases

P1: Write sloth_update.bats, dot.bats, files.bats — all tests pass, gate green, single commit.

## Deploy & rollback

n/a — merging the PR is sufficient. Rollback: revert PR.

## Open questions / risks

- Mocking `git::git` and other git functions may miss edge cases that real git would catch — accepted tradeoff for test simplicity.
- `sloth_update::sloth_update` and `sloth_update::gracefully` are complex flows with many branches — testing every path may require many mocks. Focus on the most critical paths.

## Deliverables

- `tests/core/sloth_update.bats`
- `tests/core/dot.bats`
- `tests/core/files.bats`
- Updated `docs/features/ROADMAP.md` (status flip)

## Post-merge next feature

Feature 06: `pm-timeouts` — improve package manager system with configurable timeouts
