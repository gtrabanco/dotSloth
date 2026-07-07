#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/script.sh — script utility functions

load "../helpers/setup"

# ── Script functions ──────────────────────────────────────────────────────

@test "script::function_exists is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/script.sh'; declare -f script::function_exists"
    [ "$status" -eq 0 ]
}

@test "script::list_functions is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/script.sh'; declare -f script::list_functions"
    [ "$status" -eq 0 ]
}
