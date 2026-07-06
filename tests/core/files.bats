#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/files.sh — files namespace functions

load "../helpers/setup"

# ── Function existence ────────────────────────────────────────────────────

@test "files::check_if_path_is_older is defined" {
    declare -f files::check_if_path_is_older >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "files::backup_move_if_path_exists is defined" {
    declare -f files::backup_move_if_path_exists >/dev/null 2>&1
    [ $? -eq 0 ]
}

# ── check_if_path_is_older ─────────────────────────────────────────────────

@test "files::check_if_path_is_older returns 0 for old file" {
    local tmpfile
    tmpfile=$(mktemp)
    # Set modification time to Jan 1, 2020 (definitely older than 7 days)
    touch -t 202001010000 "$tmpfile"
    run files::check_if_path_is_older "$tmpfile" 7 days
    [ "$status" -eq 0 ]
    rm -f "$tmpfile"
}

@test "files::check_if_path_is_older returns 1 for recent file" {
    local tmpfile
    tmpfile=$(mktemp)
    run files::check_if_path_is_older "$tmpfile" 7 days
    [ "$status" -eq 1 ]
    rm -f "$tmpfile"
}

@test "files::check_if_path_is_older returns 1 for nonexistent path" {
    run files::check_if_path_is_older "/nonexistent/path/xyz" 7 days
    [ "$status" -eq 1 ]
}
