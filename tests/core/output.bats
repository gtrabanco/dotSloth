#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/output.sh — output formatting functions

load "setup"

# ── Output functions ──────────────────────────────────────────────────────

@test "output::write is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::write"
    [ "$status" -eq 0 ]
}

@test "output::answer is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::answer"
    [ "$status" -eq 0 ]
}

@test "output::error is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::error"
    [ "$status" -eq 0 ]
}

@test "output::solution is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::solution"
    [ "$status" -eq 0 ]
}

@test "output::question is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::question"
    [ "$status" -eq 0 ]
}

@test "output::answer_is_yes is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::answer_is_yes"
    [ "$status" -eq 0 ]
}

@test "output::question_default is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/output.sh'; declare -f output::question_default"
    [ "$status" -eq 0 ]
}
