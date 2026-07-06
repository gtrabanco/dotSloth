# 09 — mock-harness

> Feature specification. Mock harness for external commands in the test suite.

## Goal

Create a reusable mock harness that lets tests stub external commands (`gem`, `brew`, `git`, `npm`, etc.) with configurable exit codes and output. This unblocks functional tests for package managers (#273), bootstrap scripts (#268), and core libraries that shell out.

## Branch

`feat/09-mock-harness`

## Size

**S** — single helper file + mock directory + tests.

## Dependencies

None.

## Context

Issue #302 (filed from product audit). The test setup (`tests/helpers/setup.bash`) already prepends `tests/helpers/mocks` to PATH, but that directory doesn't exist. The `mocks.sh` file defines mock functions but they're not usable as PATH-based stubs. Current tests for package managers use grep-based regression guards (#273) because there's no way to mock the external `gem`/`brew`/`dnf` commands.

## Scope

### In scope

- Create `tests/helpers/mocks/` directory (referenced by setup.bash but missing)
- Create `tests/helpers/mock.sh` — a sourceable library with:
  - `mock_command <cmd> [--exit-code N] [--stdout "text"] [--stderr "text"]` — creates a mock binary in the mocks dir
  - `mock_command_script <cmd> <script_path>` — creates a mock from a script file
  - `unmock_command <cmd>` — removes a mock binary
  - `clear_mocks` — removes all mocks
- Tests for the mock harness itself (`tests/helpers/mock_test.bats`)
- Update `tests/helpers/setup.bash` to source the mock library
- Keep existing `mocks.sh` for backward compatibility (deprecated)

### Out of scope

- Rewriting existing tests to use mocks (tracked in #273, #268, feature 10)
- Mocking complex command interactions (stateful mocks, call counters) — keep it simple first

## Design

### `mock_command`

Creates a simple bash script in `tests/helpers/mocks/` that outputs fixed text and exits with a fixed code:

```bash
mock_command() {
  local cmd="$1"
  shift
  local exit_code=0
  local stdout=""
  local stderr=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --exit-code) exit_code="$2"; shift 2 ;;
      --stdout) stdout="$2"; shift 2 ;;
      --stderr) stderr="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  
  local mock_path="${MOCK_DIR:-$(dirname "${BASH_SOURCE[0]}")/mocks}/$cmd"
  mkdir -p "$(dirname "$mock_path")"
  cat > "$mock_path" << MOCK
#!/usr/bin/env bash
[[ -n "$stderr" ]] && echo "$stderr" >&2
[[ -n "$stdout" ]] && echo "$stdout"
exit $exit_code
MOCK
  chmod +x "$mock_path"
}
```

### `unmock_command`

```bash
unmock_command() {
  local cmd="$1"
  local mock_path="${MOCK_DIR:-$(dirname "${BASH_SOURCE[0]}")/mocks}/$cmd"
  rm -f "$mock_path"
}
```

### `clear_mocks`

```bash
clear_mocks() {
  local mock_dir="${MOCK_DIR:-$(dirname "${BASH_SOURCE[0]}")/mocks}"
  rm -f "$mock_dir"/* 2>/dev/null || true
}
```

## Acceptance criteria

1. `tests/helpers/mocks/` directory exists
2. `tests/helpers/mock.sh` provides `mock_command`, `unmock_command`, `clear_mocks`
3. `mock_command gem --exit-code 1 --stdout ""` creates a mock that exits 1 with no output
4. `mock_command brew --stdout "installed"` creates a mock that exits 0 with "installed"
5. `unmock_command gem` removes the mock
6. `clear_mocks` removes all mocks
7. `tests/helpers/setup.bash` sources the mock library
8. Tests for the mock harness pass (5+ tests)
9. `bash scripts/core/static_analysis` passes
10. `bash scripts/core/lint` passes
11. `make test` passes with 96+ tests (no regressions)

## Testing requirements

Tests for the mock harness itself: `tests/helpers/mock_test.bats` — test `mock_command`, `unmock_command`, `clear_mocks`.

## Phases

Single pass (S-sized): implement mock.sh + mocks dir + tests + setup.bash update.

## Open questions / risks

- Mock binaries persist between tests if not cleaned up — tests should call `clear_mocks` in teardown
- The mocks dir is in PATH (set by setup.bash) — mocks override real commands for all tests
- bash 3.2 compatibility: no `mapfile`, use `while read` loops
