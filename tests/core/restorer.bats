#!/usr/bin/env bats
# bats file=true

# Unit tests for functions defined in the restorer script.
# The restorer is a monolithic script (~500 lines) with interactive code at the
# bottom. We extract function definitions via awk so only the target functions
# are loaded — no network, no user prompts, no side effects.

load "../helpers/setup"

# ── Helpers ───────────────────────────────────────────────────────────────

# Extract a single function by name from the restorer script and eval it.
# Usage: _extract_func <func_name>
_extract_func() {
  local fname="$1"
  # Use awk: find the function definition line, track brace depth, print everything
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
  ' "${SLOTH_PATH}/restorer"
}

setup() {
  # Provide color vars referenced by extracted _e/_s/_a (defined at top level in restorer, not in extracted funcs)
  red='\033[0;31m'
  green='\033[0;32m'
  purple='\033[0;35m'
  normal='\033[0m'

  # Extract only logic helpers from the restorer script and eval them.
  # Output helpers (_w/_a/_e/_s) are no-op stubs to reduce eval surface (they are pure side-effects for messaging).
  _w() { :; }
  _a() { :; }
  _e() { :; }
  _s() { :; }
  eval "$(_extract_func 'current_timestamp')"
  # Target functions:
  eval "$(_extract_func 'has_component')"
  eval "$(_extract_func 'validate_dotfiles')"
  eval "$(_extract_func 'create_rollback_point')"
  eval "$(_extract_func 'rollback')"
  eval "$(_extract_func 'backup_dotfiles_dir')"

  # Provide a default COMPONENTS so has_component works
  COMPONENTS="dotfiles,packages,symlinks,shell"
  # Provide DOTFILES_PATH so rollback/backup functions have a target
  export DOTFILES_PATH
  DOTFILES_PATH=$(temp_dir)

  # Create a real git repo for validate_dotfiles tests
  TEST_REPO=$(temp_dir)
  git init -q -b main "$TEST_REPO"
  git -C "$TEST_REPO" config user.email "test@test.com"
  git -C "$TEST_REPO" config user.name "test"
  printf 'hello\n' > "$TEST_REPO/README.md"
  git -C "$TEST_REPO" add README.md
  git -C "$TEST_REPO" commit -qm "initial commit"
}

teardown() {
  clear_mocks
  rm -rf "$DOTFILES_PATH" "$TEST_REPO" 2>/dev/null || true
}

# ── has_component() ───────────────────────────────────────────────────────

@test "has_component returns 0 when component is in the list" {
  COMPONENTS="dotfiles,packages,symlinks,shell"
  run has_component "dotfiles"
  [ "$status" -eq 0 ]
}

@test "has_component returns 0 for middle component in the list" {
  COMPONENTS="dotfiles,packages,symlinks,shell"
  run has_component "packages"
  [ "$status" -eq 0 ]
}

@test "has_component returns 1 when component is not in the list" {
  COMPONENTS="dotfiles,packages"
  run has_component "shell"
  [ "$status" -ne 0 ]
}

@test "has_component returns 1 for a completely unknown component" {
  COMPONENTS="dotfiles,packages"
  run has_component "nonexistent"
  [ "$status" -ne 0 ]
}

# ── validate_dotfiles() ───────────────────────────────────────────────────

@test "validate_dotfiles returns 0 for a valid git repo" {
  run validate_dotfiles "$TEST_REPO"
  [ "$status" -eq 0 ]
}

@test "validate_dotfiles returns 1 for a non-Git directory" {
  local non_git
  non_git=$(temp_dir)
  run validate_dotfiles "$non_git"
  [ "$status" -ne 0 ]
  rm -rf "$non_git"
}

@test "validate_dotfiles returns 1 for a non-existent directory" {
  run validate_dotfiles "/tmp/does-not-exist-xyz"
  [ "$status" -ne 0 ]
}

@test "validate_dotfiles returns 1 for a git repo with no commits" {
  local no_head_repo
  no_head_repo=$(temp_dir)
  git init -q "$no_head_repo"
  run validate_dotfiles "$no_head_repo"
  [ "$status" -ne 0 ]
  rm -rf "$no_head_repo"
}

# ── create_rollback_point() + rollback() ──────────────────────────────────

@test "create_rollback_point creates a rollback directory with dotfiles copy" {
  # Create a dotfiles dir with some content
  local test_dotfiles
  test_dotfiles=$(temp_dir)
  printf 'hello' > "$test_dotfiles/test_file"
  DOTFILES_PATH="$test_dotfiles"

  create_rollback_point
  [ -d "$ROLLBACK_DIR" ]
  [ -f "$ROLLBACK_DIR/dotfiles/test_file" ]
  rm -rf "$test_dotfiles"
}

@test "create_rollback_point creates symlinks.txt from HOME" {
  local test_dotfiles
  test_dotfiles=$(temp_dir)
  DOTFILES_PATH="$test_dotfiles"

  create_rollback_point
  [ -f "$ROLLBACK_DIR/symlinks.txt" ]
  rm -rf "$test_dotfiles"
}

@test "rollback restores dotfiles from rollback directory" {
  # Create original dotfiles with known content
  local test_dotfiles rollback_dir
  test_dotfiles=$(temp_dir)
  rollback_dir=$(temp_dir)
  mkdir -p "$rollback_dir/dotfiles"
  printf 'original' > "$rollback_dir/dotfiles/config"

  # Simulate modification
  printf 'modified' > "$test_dotfiles/config"

  DOTFILES_PATH="$test_dotfiles"
  rollback "$rollback_dir"

  run cat "$test_dotfiles/config"
  [ "$output" = "original" ]
  rm -rf "$test_dotfiles" "$rollback_dir"
}

@test "rollback returns 1 for a non-existent rollback directory" {
  run rollback "/tmp/nonexistent-rollback-xyz"
  [ "$status" -ne 0 ]
}

# ── backup_dotfiles_dir() ─────────────────────────────────────────────────

@test "backup_dotfiles_dir renames existing dir to timestamped backup" {
  local parent
  parent=$(temp_dir)
  local test_dir="$parent/dotfiles"
  mkdir -p "$test_dir"
  printf 'content' > "$test_dir/file.txt"

  backup_dotfiles_dir "$test_dir"

  # Original dir should be gone (moved)
  [ ! -d "$test_dir" ]
  # Backup should exist with .back suffix — find it scoped to our parent temp
  local found
  found=$(ls -d "${test_dir}".*.back 2>/dev/null | head -1)
  [ -n "$found" ]
  [ -f "$found/file.txt" ]
  rm -rf "$parent" 2>/dev/null || true
}

@test "backup_dotfiles_dir creates parent dir for non-existent path (else branch)" {
  local test_parent
  test_parent=$(temp_dir)
  local new_path="$test_parent/sub/dir"

  [ ! -d "$new_path" ]
  backup_dotfiles_dir "$new_path"
  # Function creates the parent directory, not the target itself
  [ -d "${new_path%/*}" ]
  # Confirm else branch: no backup was created (if-branch would have renamed)
  local found
  found=$(ls -d "${new_path}".*.back 2>/dev/null | head -1 || true)
  [ -z "$found" ]
  rm -rf "$test_parent"
}
