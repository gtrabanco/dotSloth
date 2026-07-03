#!/usr/bin/env bats
# bats file=true

# Test for scripts/package/src/package_managers/dnf.sh — DNF package manager wrapper

load "setup"

# ── DNF wrapper functions ─────────────────────────────────────────────────

@test "dnf::title is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::title"
    [ "$status" -eq 0 ]
}

@test "dnf::is_available is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::is_available"
    [ "$status" -eq 0 ]
}

@test "dnf::install is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::install"
    [ "$status" -eq 0 ]
}

@test "dnf::is_installed is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::is_installed"
    [ "$status" -eq 0 ]
}

@test "dnf::cleanup is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::cleanup"
    [ "$status" -eq 0 ]
}

@test "dnf::update_all is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::update_all"
    [ "$status" -eq 0 ]
}

@test "dnf::outdated_app is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::outdated_app"
    [ "$status" -eq 0 ]
}

@test "dnf::dump is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::dump"
    [ "$status" -eq 0 ]
}

@test "dnf::import is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh'; declare -f dnf::import"
    [ "$status" -eq 0 ]
}

@test "dnf::outdated_app captures output in variable (single call fix)" {
    # This verifies the fix for issue #244 — the output should be captured
    # in a variable with || true to handle exit code 100
    local dnf_script="$SLOTH_PATH/scripts/package/src/package_managers/dnf.sh"
    [[ -f "$dnf_script" ]] && grep -q 'outdated="$(dnf check-update.*|| true' "$dnf_script"
}
