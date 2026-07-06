#!/usr/bin/env bash
# Mock harness for external commands in tests
# Sourceable library: provides mock_command, unmock_command, clear_mocks

# Default mock directory (tests/helpers/mocks/)
# This directory is prepended to PATH by setup.bash
_MOCK_HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOCK_DIR="${MOCK_DIR:-${_MOCK_HARNESS_DIR}/mocks}"

# Create a mock for an external command
# Usage: mock_command <cmd> [--exit-code N] [--stdout "text"] [--stderr "text"]
# The mock binary will output the given stdout/stderr and exit with the given code.
mock_command() {
  local cmd="$1"
  shift

  local exit_code=0
  local stdout=""
  local stderr=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --exit-code)
        exit_code="$2"
        shift 2
        ;;
      --stdout)
        stdout="$2"
        shift 2
        ;;
      --stderr)
        stderr="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  [[ -z "$cmd" ]] && return 1

  mkdir -p "$MOCK_DIR"
  local mock_path="$MOCK_DIR/$cmd"

  cat > "$mock_path" << MOCK
#!/usr/bin/env bash
$([[ -n "$stderr" ]] && echo "printf '%s\n' '$(echo "$stderr" | sed "s/'/'\\\\''/g")' >&2")
$([[ -n "$stdout" ]] && echo "printf '%s\n' '$(echo "$stdout" | sed "s/'/'\\\\''/g")'")
exit ${exit_code}
MOCK
  chmod +x "$mock_path"
}

# Create a mock from a script file (for complex mocks)
# Usage: mock_command_script <cmd> <script_path>
mock_command_script() {
  local cmd="$1"
  local script_path="$2"

  [[ -z "$cmd" || ! -f "$script_path" ]] && return 1

  mkdir -p "$MOCK_DIR"
  cp "$script_path" "$MOCK_DIR/$cmd"
  chmod +x "$MOCK_DIR/$cmd"
}

# Remove a mock for a specific command
# Usage: unmock_command <cmd>
unmock_command() {
  local cmd="$1"
  [[ -z "$cmd" ]] && return 1
  rm -f "$MOCK_DIR/$cmd"
}

# Remove all mocks
clear_mocks() {
  [[ -d "$MOCK_DIR" ]] && rm -f "$MOCK_DIR"/* 2> /dev/null || true
}

# Check if a command is mocked
is_mocked() {
  local cmd="$1"
  [[ -z "$cmd" ]] && return 1
  [[ -f "$MOCK_DIR/$cmd" ]]
}
