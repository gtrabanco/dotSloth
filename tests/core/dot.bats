#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/dot.sh — dot namespace functions

load "../helpers/setup"

# ── Function existence ────────────────────────────────────────────────────

@test "dot::list_contexts is defined" {
    declare -f dot::list_contexts >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "dot::list_context_scripts is defined" {
    declare -f dot::list_context_scripts >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "dot::list_scripts is defined" {
    declare -f dot::list_scripts >/dev/null 2>&1
    [ $? -eq 0 ]
}

# ── list_contexts ─────────────────────────────────────────────────────────

@test "dot::list_contexts returns successfully" {
    run dot::list_contexts
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "dot::list_contexts excludes underscore-prefixed dirs" {
    run dot::list_contexts
    [ "$status" -eq 0 ]
    [[ "$output" != *$'\n_'* ]]
}

# ── list_context_scripts ──────────────────────────────────────────────────

@test "dot::list_context_scripts returns scripts for core context" {
    run dot::list_context_scripts core
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "dot::list_context_scripts returns empty for nonexistent context" {
    run dot::list_context_scripts nonexistent_context_xyz
    [ "$status" -eq 0 ]
}
