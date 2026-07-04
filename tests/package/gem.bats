#!/usr/bin/env bats
# bats file=true

# Test for scripts/package/src/package_managers/gem.sh — Ruby gem package manager wrapper
# Covers the fix for #265: gem::update_apps must check exit code of `gem outdated`

load "../helpers/setup"

# ── gem wrapper functions ───────────────────────────────────────────────

@test "gem::title is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/gem.sh'; declare -f gem::title"
    [ "$status" -eq 0 ]
}

@test "gem::is_available is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/gem.sh'; declare -f gem::is_available"
    [ "$status" -eq 0 ]
}

@test "gem::update_apps is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/gem.sh'; declare -f gem::update_apps"
    [ "$status" -eq 0 ]
}

@test "gem::update_all is defined" {
    run bash -c "source '$SLOTH_PATH/scripts/package/src/package_managers/gem.sh'; declare -f gem::update_all"
    [ "$status" -eq 0 ]
}

# ── #265: exit-code check prevents false positive ────────────────────────

@test "gem::update_apps checks exit code of gem outdated (not just stdout)" {
    # The fix for #265: gem outdated can fail (exit 1) with empty stdout,
    # which previously caused a false "Already up-to-date". The function
    # must now check the exit code and return 1 on failure.
    local gem_script="$SLOTH_PATH/scripts/package/src/package_managers/gem.sh"
    [[ -f "$gem_script" ]]
    # Verify the exit-code check is present
    grep -q 'gem_outdated_exit' "$gem_script"
    grep -q 'gem_outdated_exit.*-ne 0' "$gem_script"
}

@test "gem::update_apps discards stderr to avoid parsing error text as packages" {
    # The fix for #265 review: stderr must NOT be merged into $outdated
    # (2>&1), otherwise error text could be parsed as package names.
    # Use 2>/dev/null to discard stderr while checking exit code separately.
    local gem_script="$SLOTH_PATH/scripts/package/src/package_managers/gem.sh"
    [[ -f "$gem_script" ]]
    grep -q 'gem outdated 2> /dev/null' "$gem_script"
}
