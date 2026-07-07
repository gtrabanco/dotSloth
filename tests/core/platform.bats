#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/platform.sh — platform detection functions

load "../helpers/setup"

# ── Platform detection ────────────────────────────────────────────────────

@test "platform::is_macos returns 0 on macOS" {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "not running on macOS"
    fi
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::is_macos"
    [ "$status" -eq 0 ]
}

@test "platform::is_linux returns 1 on macOS (Linux not detected)" {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "not running on macOS"
    fi
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::is_linux"
    # On macOS, is_linux returns 1 (false)
    [ "$status" -eq 1 ]
}

@test "platform::is_linux returns 0 on Linux" {
    if [[ "$(uname -s)" != "Linux" ]]; then
        skip "not running on Linux"
    fi
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::is_linux"
    [ "$status" -eq 0 ]
}

@test "platform::is_macos returns 1 on Linux (macOS not detected)" {
    if [[ "$(uname -s)" != "Linux" ]]; then
        skip "not running on Linux"
    fi
    run bash -c "source '$SLOTH_PATH/scripts/core/src/platform.sh'; platform::is_macos"
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
