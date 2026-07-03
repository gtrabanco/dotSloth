#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/log.sh — logging functions

load "../helpers/setup"

# ── Logging functions ─────────────────────────────────────────────────────

@test "log::error is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::error"
    [ "$status" -eq 0 ]
}

@test "log::success is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::success"
    [ "$status" -eq 0 ]
}

@test "log::warning is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::warning"
    [ "$status" -eq 0 ]
}

@test "log::note is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::note"
    [ "$status" -eq 0 ]
}

@test "log::header is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::header"
    [ "$status" -eq 0 ]
}

@test "log::file is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::file"
    [ "$status" -eq 0 ]
}

@test "log::append is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f log::append"
    [ "$status" -eq 0 ]
}

@test "die is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/log.sh'; declare -f die"
    [ "$status" -eq 0 ]
}
