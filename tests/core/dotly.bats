#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/dotly.sh — dotly file listing functions
# Completes feature 05 acceptance criterion #5 (10th test file)

load "../helpers/setup"

# ── dotly::list_bash_files ──────────────────────────────────────────────

@test "dotly::list_bash_files is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dotly.sh'; declare -f dotly::list_bash_files"
    [ "$status" -eq 0 ]
}

@test "dotly::list_bash_files returns files from bin/" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dotly.sh'; dotly::list_bash_files | grep -c 'bin/'"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test "dotly::list_bash_files excludes scripts/self/" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dotly.sh'; dotly::list_bash_files | grep -c '/scripts/self/'"
    [ "$status" -ne 0 ]
}

@test "dotly::list_bash_files finds .sh files" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dotly.sh'; dotly::list_bash_files | grep -c '\.sh$'"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

# ── dotly::list_dotfiles_bash_files ─────────────────────────────────────

@test "dotly::list_dotfiles_bash_files is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dotly.sh'; declare -f dotly::list_dotfiles_bash_files"
    [ "$status" -eq 0 ]
}

@test "dotly::list_dotfiles_bash_files runs without error with empty DOTFILES_PATH" {
    local tmpdir
    tmpdir=$(mktemp -d)
    run bash -c "DOTFILES_PATH='$tmpdir' source '$SLOTH_PATH/scripts/core/src/dotly.sh'; dotly::list_dotfiles_bash_files" 2>/dev/null
    [ "$status" -eq 0 ]
    rm -rf "$tmpdir"
}
