# 06 — pm-timeouts

> Feature specification. Add configurable timeout support to package manager wrappers to prevent hangs during `dot up`.

## Goal

Add a configurable timeout mechanism to all package manager `update_all` flows. Currently only `mas.sh` has timeout support (added in fix #248). All other package managers (`brew`, `apt`, `dnf`, `pip`, `npm`, `cargo`, `gem`, `snap`, `pacman`, `yum`) can hang indefinitely during `dot up` — especially when a package manager prompts for input, hits a network issue, or waits on a lock.

## Branch

`feat/06-pm-timeouts`

## Size

**S** — single-pass execution. The timeout pattern is already proven in `mas.sh`. This feature applies the same pattern to the remaining package managers via a shared helper function.

## Dependencies

None. Feature 05 (testing-framework) is done and merged.

## Context

Issue #241 requests configurable timeouts for package managers. Fix #248 added timeout to `mas.sh` using a 3-tier fallback (`gtimeout` → `timeout` → bash job control). The same pattern should be applied to all package managers. The `up` command (`bin/up`) calls `package::command <pm> update_all` for each available package manager — if any hangs, the entire update process stalls.

## Business goals

n/a (internal/technical feature)

## Technical goals

1. Add a shared `package::run_with_timeout` helper function
2. Add `SLOTH_PM_TIMEOUT` environment variable (default: 300 seconds = 5 minutes)
3. Add per-package-manager timeout overrides (e.g. `BREW_TIMEOUT`, `APT_TIMEOUT`)
4. Apply timeout to `update_all` and `self_update` in all package managers
5. Output a clear error message when a timeout occurs
6. Keep the 3-tier fallback from #248 (gtimeout → timeout → bash job control)

## Scope

### In scope

- Add `package::run_with_timeout` to `scripts/core/src/package.sh`
- Add `SLOTH_PM_TIMEOUT` env var (default 300)
- Add per-PM timeout env vars: `BREW_TIMEOUT`, `APT_TIMEOUT`, `DNF_TIMEOUT`, `PIP_TIMEOUT`, `NPM_TIMEOUT`, `CARGO_TIMEOUT`, `GEM_TIMEOUT`, `SNAP_TIMEOUT`, `PACMAN_TIMEOUT`, `YUM_TIMEOUT`, `MAS_UPGRADE_TIMEOUT` (already exists)
- Apply timeout to `update_all` and `self_update` in: `brew.sh`, `apt.sh`, `dnf.sh`, `pip.sh`, `npm.sh`, `cargo.sh`, `gem.sh`, `snap.sh`, `pacman.sh`, `yum.sh`
- Add tests for `package::run_with_timeout`

### Out of scope / non-goals

- Timeout for `install`, `dump`, `import` operations (only update flows)
- Timeout for `mas.sh` (already has it from #248)
- Timeout for `composer.sh`, `volta.sh`, `pipx.sh` (less common, can be added later)
- Config file for timeouts (env vars are sufficient)

## Architecture impact

Modifies `scripts/core/src/package.sh` (adds helper) and package manager wrappers (use helper). No new files. No boundary violations — package managers already depend on `package.sh` via `dot::load_library`.

Invariants to respect:
- The helper must be in `scripts/core/src/package.sh` (core library)
- Package managers use it via the standard `package::` namespace
- The 3-tier fallback must work on macOS (no GNU `timeout` by default) and Linux

## Design

### `package::run_with_timeout`

```bash
# package::run_with_timeout <timeout_seconds> <command> [args...]
# Returns the command's exit code, or 124 on timeout
package::run_with_timeout() {
  local -r timeout="${1:-300}"
  shift

  if command -v gtimeout &>/dev/null; then
    gtimeout "$timeout" "$@"
  elif command -v timeout &>/dev/null; then
    timeout "$timeout" "$@"
  else
    # Bash job control fallback (for macOS without GNU coreutils)
    local pid
    "$@" &
    pid=$!
    (
      sleep "$timeout"
      kill "$pid" 2>/dev/null
    ) &
    local timer_pid=$!
    wait "$pid" 2>/dev/null
    local exit_code=$?
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null
    return $exit_code
  fi
}
```

### Per-PM timeout resolution

Each package manager resolves its timeout from its specific env var, falling back to `SLOTH_PM_TIMEOUT`:

```bash
# In brew::update_all:
local -r timeout="${BREW_TIMEOUT:-${SLOTH_PM_TIMEOUT:-300}}"
package::run_with_timeout "$timeout" brew update
```

## Decisions to confirm

1. **Default timeout:** 300 seconds (5 minutes) — sufficient for most package managers, prevents indefinite hangs.
2. **Timeout exit code:** 124 (standard for `timeout` command).
3. **Scope:** Only `update_all` and `self_update` — these are the long-running operations that can hang.
4. **Helper location:** `scripts/core/src/package.sh` — core library, available to all package managers.

## Acceptance criteria

1. `package::run_with_timeout` is defined in `scripts/core/src/package.sh`
2. `SLOTH_PM_TIMEOUT` env var is respected (default 300)
3. Per-PM timeout env vars override the global default
4. All 10 package managers (excluding `mas.sh` which already has it) use the timeout helper in `update_all`
5. Timeout produces a clear error message
6. `bash scripts/core/static_analysis` passes
7. `bash scripts/core/lint` passes
8. `make test` passes with at least 91 tests (no regressions) + new tests for the helper

## Testing requirements

Integration tests: call `package::run_with_timeout` with a fast command (e.g. `echo`) and a slow command (e.g. `sleep 10` with 1s timeout), assert on exit codes.

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| Normal update with timeout | `package::run_with_timeout 5 echo hello` returns 0 | `run bats tests/package/timeout.bats` |
| Timeout exceeded | `package::run_with_timeout 1 sleep 10` returns 124 | `run bats tests/package/timeout.bats` |
| Per-PM override | `BREW_TIMEOUT=10` overrides `SLOTH_PM_TIMEOUT=300` | manual verification |

## Phases

P1: Add `package::run_with_timeout` helper, apply to all package managers, add tests — single commit.

## Deploy & rollback

n/a — merging the PR is sufficient. Rollback: revert PR.

## Open questions / risks

- The bash job control fallback may not work in all shells — but `dot up` always runs in bash.
- Some package managers may not respond well to being killed mid-operation — accepted risk, better than hanging forever.

## Deliverables

- Modified `scripts/core/src/package.sh` (new helper)
- Modified package manager wrappers (10 files)
- New `tests/package/timeout.bats`
- Updated `docs/features/ROADMAP.md` (status flip)

## Post-merge next feature

Feature 07: `restorer-v2` — improve restorer with validation, rollback, partial restore
