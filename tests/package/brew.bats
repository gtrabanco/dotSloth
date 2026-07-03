#!/usr/bin/env bats
# bats file=true

# Test for scripts/package/src/package_managers/brew.sh — Homebrew package manager wrapper

load "../helpers/setup"

# ── Brew wrapper functions ────────────────────────────────────────────────

@test "brew::title is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::title"
    [ "$status" -eq 0 ]
}

@test "brew::is_available is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::is_available"
    [ "$status" -eq 0 ]
}

@test "brew::install is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::install"
    [ "$status" -eq 0 ]
}

@test "brew::package_exists is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::package_exists"
    [ "$status" -eq 0 ]
}

@test "brew::uninstall is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::uninstall"
    [ "$status" -eq 0 ]
}

@test "brew::update_all is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::update_all"
    [ "$status" -eq 0 ]
}

@test "brew::self_update is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::self_update"
    [ "$status" -eq 0 ]
}

@test "brew::cleanup is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::cleanup"
    [ "$status" -eq 0 ]
}

@test "brew::dump is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::dump"
    [ "$status" -eq 0 ]
}

@test "brew::import is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/brew.sh'; declare -f brew::import"
    [ "$status" -eq 0 ]
}
