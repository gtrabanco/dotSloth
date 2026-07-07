# 05 — testing-framework

> Feature specification. Implement a complete automated testing system for dotSloth using bats-core.

## Goal

Add automated testing infrastructure to dotSloth using bats-core, enabling regression detection, safe upstream synchronization, and confidence in refactoring. Currently there are zero automated tests — bugs like #227, #221, #221 pass silently.

## Branch

`feat/05-testing-framework`

## Size

**S** — single-pass execution. The framework setup is straightforward; initial test coverage is intentionally minimal (core libraries + critical paths). Expanding test coverage is a separate ongoing effort.

## Dependencies

None. This is an independent infrastructure feature.

## Context

dotSloth has ~7500 lines of Bash across 30+ scripts with zero automated tests. Recent bugs (#227 escaping, #243 double install, #244 dnf exit code 100) went undetected because there is no test harness. The CI only runs `shfmt` (lint) and `shellcheck` (static analysis) — no behavioral verification. bats-core is the de facto standard for Bash testing, is well-maintained, and integrates easily into GitHub Actions.

## Business goals

n/a (internal/technical feature)

## Technical goals

1. Provide a runnable test harness (`bats`) that can be executed locally and in CI
2. Enable behavioral testing of core libraries, context scripts, and package managers
3. Integrate into the existing CI pipeline without blocking existing jobs
4. Keep setup lightweight — no complex mocking, prefer integration-style tests
5. Support both macOS and Linux test environments (CI matrix)

## Scope

### In scope

- Install bats-core as a dependency (via package manager recipes or Homebrew/Brewfile)
- Create `tests/` directory structure mirroring the project layout:
  - `tests/core/` — tests for `scripts/core/src/*.sh` libraries
  - `tests/package/` — tests for package manager wrappers
  - `tests/scripts/` — tests for context scripts
  - `tests/integration/` — tests for end-to-end command dispatch via `bin/dot`
- Add a `Makefile` target `test` (or `make test`) to run all tests
- Add a GitHub Actions job `test` that runs bats in the CI matrix (macOS + Ubuntu)
- Add initial test coverage for critical paths:
  - Core library sourcing (`scripts/core/src/_main.sh`)
  - Platform detection (`scripts/core/src/platform.sh`)
  - Package manager wrappers (`dnf.sh`, `brew.sh`)
  - `bin/dot` entry point behavior (help, version, error handling)
- Add a test runner script `scripts/self/test` for convenience (like `scripts/self/lint`)
- Update CI to include the test job

### Out of scope / non-goals

- Full test coverage of all scripts (this is the foundation, not the completion)
- Performance/benchmark testing (separate feature)
- Code coverage reporting (nice-to-have, not required for this feature)
- Testing the installer/restorer scripts (they are self-contained bootstrap, not runnable in test context)
- Testing user dotfiles scripts (out of scope — user-controlled)
- Mocking framework or complex test doubles (keep tests simple)

## Architecture impact

This feature adds a new top-level `tests/` directory and a `Makefile` target. It does not modify any existing production code beyond adding a `scripts/self/test` runner. The CI adds a new job but does not change existing jobs.

Invariants to respect:
- Tests must not modify production files
- Tests must be idempotent (can run multiple times safely)
- Tests must work on both macOS and Linux (CI matrix)
- Tests must not require network access (no package installation during tests)
- Test files must follow the project's naming convention: `snake_case`
- Test files must use `#!/usr/bin/env bats` shebang

## Design

### Directory structure

```
tests/
├── helpers/
│   ├── setup.sh          # Common setup: set SLOTH_PATH, source libraries
│   └── mocks.sh          # Mock functions for external commands (curl, sudo, etc.)
├── core/
│   ├── platform.bats     # Tests for platform detection
│   ├── output.bats       # Tests for output functions
│   ├── log.bats          # Tests for logging functions
│   └── args.bats         # Tests for argument parsing
├── package/
│   ├── dnf.bats          # Tests for dnf package manager wrapper
│   └── brew.bats         # Tests for brew package manager wrapper
├── scripts/
│   ├── dot.bats          # Tests for bin/dot entry point
│   └── script.bats       # Tests for script:: functions
└── integration/
    └── dispatch.bats     # Tests for context dispatch via bin/dot
```

### Test conventions

- Each `.bats` file tests one module/script
- Use `setup()` and `teardown()` for per-test environment management
- Use `run <command>` pattern for capturing output and exit codes
- Use assertions: `assert`, `assert_failure`, `assert_success`, `assert_output`
- Mock external commands via PATH manipulation (put mocks dir first)
- Use `SLOTH_PATH` environment variable to point to the repo root
- Tests must be runnable without root privileges

### CI integration

Add a new job to `.github/workflows/ci.yml`:

```yaml
test:
  runs-on: ${{ matrix.os }}
  strategy:
    matrix:
      os: [macos-latest, ubuntu-latest]
  steps:
    - uses: actions/checkout@v2
    - name: Install bats-core
      run: |
        # Platform-specific installation
        if [[ "$RUNNER_OS" == "Linux" ]]; then
          # apt-based installation
          ...
        else
          # Homebrew on macOS
          brew install bats-core
        fi
    - name: Run tests
      run: make test
```

### Makefile target

```makefile
test:
	bash scripts/self/test
```

### Test runner script

`scripts/self/test` — mirrors `scripts/self/lint` pattern:
1. Set up environment (`SLOTH_PATH`)
2. Run `bats tests/`
3. Return appropriate exit code

## Decisions to confirm

1. **bats-core installation method**: Use Homebrew on macOS, apt from PPA on Ubuntu. This is standard for CI environments.
2. **Test coverage scope**: Start with ~10-15 core tests covering the most critical paths. Expand gradually.
3. **CI gating**: Tests should be required for PR merge (like lint and static_analysis).

## Acceptance criteria

1. `make test` runs all tests successfully on macOS
2. `make test` runs all tests successfully on Ubuntu
3. CI has a `test` job that runs bats on both macOS and Ubuntu
4. CI fails the build if any test fails (like lint/static_analysis)
5. At least 10 test files exist covering core libraries and package managers
6. Tests run in under 60 seconds total
7. Tests do not require network access or root privileges
8. Test output is human-readable (bats default format)

## Testing requirements

Integration tests preferred over unit tests. Test behavior by executing scripts with representative inputs and verifying exit codes and output. No heavy mocking — use PATH manipulation for external command overrides.

## Dev scenarios

| Scenario | Reproduces | Mechanism it drives |
|---|---|---|
| Core library sourcing | Verify `_main.sh` sources all libraries without errors | `run bats tests/core/` |
| Platform detection | Verify `platform::is_macos`, `platform::is_linux` return correct values | `run bats tests/core/platform.bats` |
| Package manager wrapper interface | Verify `dump`, `update_all`, `install` functions exist | `run bats tests/package/dnf.bats` |
| Entry point help | Verify `bin/dot --help` shows usage | `run bats tests/scripts/dot.bats` |
| Entry point error | Verify `bin/dot nonexistent` returns non-zero exit | `run bats tests/scripts/dot.bats` |
| CI integration | Verify CI runs tests on push/PR to main | `git push && check CI` |

## Phases

P1: Framework setup — install bats-core, create directory structure, write helpers/setup.sh and helpers/mocks.sh, create test runner script `scripts/self/test`
P2: Core library tests — write tests for platform.sh, output.sh, log.sh, args.sh
P3: Package manager tests — write tests for dnf.sh, brew.sh wrappers
P4: Entry point and dispatch tests — write tests for bin/dot, integration dispatch tests
P5: CI integration — add test job to CI, update Makefile, verify on both platforms

## Deploy & rollback

n/a — merging the PR is sufficient. Rollback: revert PR.

## Open questions / risks

- bats-core may not be available in older Ubuntu images — may need to install from source or PPA
- Some tests may need mock data files — decide on test fixtures approach
- CI matrix doubles the test time — consider if both OSes are needed for every run

## Deliverables

- `tests/` directory with bats test files
- `scripts/self/test` test runner
- Updated `Makefile` with `test` target
- Updated `.github/workflows/ci.yml` with test job
- Updated `docs/features/ROADMAP.md` with feature 05 entry

## Post-merge next feature

Feature 06: `pm-timeouts` — improve package manager system with configurable timeouts
