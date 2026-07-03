# dotSloth Tests

BATS-based test suite for the dotSloth framework.

## Structure

```
tests/
├── helpers/          # Shared setup and mock functions
│   ├── setup.sh      # BATS load hook — sets SLOTH_PATH, sources core libs
│   └── mocks.sh      # Mock external commands (curl, brew, dnf, etc.)
├── core/             # Tests for scripts/core/src/*.sh
│   ├── platform.bats # platform:: functions
│   ├── output.bats   # output:: functions
│   ├── log.bats      # log:: functions
│   └── package.bats  # package:: functions
├── package/          # Tests for scripts/package/src/package_managers/*.sh
│   ├── dnf.bats      # DNF package manager wrapper
│   └── brew.bats     # Homebrew package manager wrapper
├── scripts/          # Tests for script-level utilities
│   ├── dot.bats      # bin/dot entry point behavior
│   └── script.bats   # script:: utility functions
└── integration/      # End-to-end integration tests
    └── dispatch.bats # dot command dispatch and help output
```

## Running Tests

### Prerequisites

Install BATS-core:

```bash
# macOS
brew install bats-core

# Linux (Debian/Ubuntu)
sudo apt install bats

# From source
git clone --recursive https://github.com/bats-core/bats-core.git
cd bats-core
./install /usr/local
```

### Run all tests

```bash
bats tests/
```

### Run specific test file

```bash
bats tests/core/platform.bats
```

### Run with verbose output

```bash
bats -v tests/
```

### Run with timing

```bash
bats --timing tests/
```

## Writing Tests

### Structure

Each `.bats` file follows this pattern:

```bash
#!/usr/bin/env bats
# bats file=true

load "helpers/setup"

setup() {
    # Per-test setup
}

@test "description of test" {
    run function_under_test "arg1" "arg2"
    [ "$status" -eq 0 ]
    [[ "$output" == *"expected"* ]]
}
```

### Best Practices

1. **Test behavior, not implementation** — assert on outputs, exit codes, and side effects
2. **Use `run`** to capture command output and exit status
3. **Mock external commands** — use `tests/helpers/mocks.sh` to override `curl`, `brew`, `dnf`, etc.
4. **Keep tests fast** — avoid network calls, slow I/O, or interactive prompts
5. **One assertion per test** when possible — each `@test` should verify one thing
6. **Use `skip`** for tests that require unavailable tools (e.g., `dnf` on macOS)

### Mocking External Commands

The `tests/helpers/mocks.sh` file provides mock functions for common external tools. Load it via `setup.sh` to override real commands during tests.

Example mock:

```bash
# In mocks.sh
mock_curl() {
    echo "mocked response"
    return 0
}
```

## CI Integration

Tests run automatically on PRs to `main` via GitHub Actions (`.github/workflows/ci.yml`).

## Test Categories

- **Unit tests** (`tests/core/`, `tests/package/`, `tests/scripts/`): Test individual functions in isolation
- **Integration tests** (`tests/integration/`): Test end-to-end behavior of the `dot` command dispatch
