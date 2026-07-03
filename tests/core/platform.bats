#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/platform.sh — platform detection functions

load "../helpers/setup"

# ── Platform detection ────────────────────────────────────────────────────

@test "platform::is_macos returns 0 on macOS" {
    # On macOS, this should succeed
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::is_macos"
    [ "$status" -eq 0 ]
}

@test "platform::is_linux returns 1 on macOS (Linux not detected)" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::is_linux"
    # On macOS, is_linux returns 1 (false)
    [ "$status" -eq 1 ]
}

@test "platform::command_exists returns 0 for existing command" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::command_exists bash"
    [ "$status" -eq 0 ]
}

@test "platform::command_exists returns 1 for non-existent command" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::command_exists nonexistent_command_xyz"
    [ "$status" -eq 1 ]
}
