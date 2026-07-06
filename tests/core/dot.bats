#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/dot.sh — dot namespace functions

load "../helpers/setup"

# ── Function existence ────────────────────────────────────────────────────

@test "dot::list_contexts is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; declare -f dot::list_contexts"
    [ "$status" -eq 0 ]
}

@test "dot::list_context_scripts is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; declare -f dot::list_context_scripts"
    [ "$status" -eq 0 ]
}

@test "dot::list_scripts is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; declare -f dot::list_scripts"
    [ "$status" -eq 0 ]
}

# ── list_contexts ─────────────────────────────────────────────────────────

@test "dot::list_contexts returns core contexts" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; dot::list_contexts"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "core"
}

@test "dot::list_contexts excludes underscore-prefixed dirs" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; dot::list_contexts"
    [ "$status" -eq 0 ]
    ! echo "$output" | grep -q "^_"
}

# ── list_context_scripts ──────────────────────────────────────────────────

@test "dot::list_context_scripts returns scripts for core context" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; dot::list_context_scripts core"
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "lint\|install\|update\|version"
}

@test "dot::list_context_scripts returns empty for nonexistent context" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/dot.sh'; dot::list_context_scripts nonexistent_context_xyz"
    [ "$status" -eq 0 ]
}
