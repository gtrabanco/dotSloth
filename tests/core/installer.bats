#!/usr/bin/env bats
# bats file=true

# Unit tests for functions defined in the installer script.
# The installer is a monolithic script (~500 lines) with interactive code at the
# bottom. We extract function definitions via awk so only the target functions
# are loaded — no network, no user prompts, no side effects.

load "../helpers/setup"

# ── Helpers ───────────────────────────────────────────────────────────────

# Extract a single function by name from the installer script and eval it.
# Usage: _extract_func <func_name>
_extract_func() {
  local fname="$1"
  awk -v name="$fname" '
    $0 ~ "^"name" *\\(\\) *" { in_func=1; depth=0 }
    in_func {
      print
      for (i=1; i<=length($0); i++) {
        c = substr($0, i, 1)
        if (c == "{") depth++
        if (c == "}") depth--
      }
      if (in_func && depth <= 0 && NR > 1) exit
    }
  ' "${SLOTH_PATH}/installer"
}

setup() {
  # Extract helper output functions used by create_dotfiles_dir
  eval "$(_extract_func '_w')"
  eval "$(_extract_func '_a')"
  eval "$(_extract_func '_e')"
  eval "$(_extract_func '_s')"
  eval "$(_extract_func 'current_timestamp')"
  # Target functions:
  eval "$(_extract_func 'create_dotfiles_dir')"

  # Provide DOTFILES_PATH so functions have a target
  export DOTFILES_PATH
}

teardown() {
  clear_mocks
  # Clean up any temp dirs we may have left
  rm -rf /tmp/dotSloth-installer-test-* 2>/dev/null || true
}

# ── create_dotfiles_dir() ─────────────────────────────────────────────────

@test "create_dotfiles_dir backs up an existing directory" {
  local test_dir
  test_dir=$(temp_dir)
  printf 'existing' > "$test_dir/file.txt"

  create_dotfiles_dir "$test_dir"

  # The function: mv old -> backup, then mkdir -p at original path.
  # So the original path exists again but as a new empty directory.
  [ -d "$test_dir" ]
  # Backup should exist with .back suffix
  local found
  found=$(ls -d "${test_dir}".*.back 2>/dev/null | head -1)
  [ -n "$found" ]
  [ -f "$found/file.txt" ]
  rm -rf "$found" 2>/dev/null || true
}

@test "create_dotfiles_dir creates a new directory when path does not exist" {
  local test_dir="/tmp/dotSloth-installer-test-$$"

  [ ! -d "$test_dir" ]
  create_dotfiles_dir "$test_dir"
  [ -d "$test_dir" ]
  rm -rf "$test_dir"
}

@test "create_dotfiles_dir creates parent directories when needed" {
  local test_parent
  test_parent=$(temp_dir)
  local new_path="$test_parent/nested/dir"

  [ ! -d "$new_path" ]
  create_dotfiles_dir "$new_path"
  [ -d "$new_path" ]
  rm -rf "$test_parent"
}
