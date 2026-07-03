#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/package.sh — package management functions

load "../helpers/setup"

# ── Package functions ─────────────────────────────────────────────────────

@test "package::manager_exists is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/package.sh'; declare -f package::manager_exists"
    [ "$status" -eq 0 ]
}

@test "package::load_manager is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/package.sh'; declare -f package::load_manager"
    [ "$status" -eq 0 ]
}

@test "package::get_all_package_managers is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/package.sh'; declare -f package::get_all_package_managers"
    [ "$status" -eq 0 ]
}

@test "package::get_available_package_managers is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/core/src/package.sh'; declare -f package::get_available_package_managers"
    [ "$status" -eq 0 ]
}
