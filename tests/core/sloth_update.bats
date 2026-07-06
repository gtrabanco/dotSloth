#!/usr/bin/env bats
# bats file=true

# Test for scripts/core/src/sloth_update.sh — auto-updater functions

load "../helpers/setup"

# ── Function existence ────────────────────────────────────────────────────

@test "sloth_update::sloth_repository_set_ready is defined" {
    declare -f sloth_update::sloth_repository_set_ready >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::get_current_version is defined" {
    declare -f sloth_update::get_current_version >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::get_latest_stable_version is defined" {
    declare -f sloth_update::get_latest_stable_version >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::should_be_updated is defined" {
    declare -f sloth_update::should_be_updated >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::local_sloth_repository_can_be_updated is defined" {
    declare -f sloth_update::local_sloth_repository_can_be_updated >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::exists_migration_script is defined" {
    declare -f sloth_update::exists_migration_script >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::sloth_update is defined" {
    declare -f sloth_update::sloth_update >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::gracefully is defined" {
    declare -f sloth_update::gracefully >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::async is defined" {
    declare -f sloth_update::async >/dev/null 2>&1
    [ $? -eq 0 ]
}

@test "sloth_update::async_success is defined" {
    declare -f sloth_update::async_success >/dev/null 2>&1
    [ $? -eq 0 ]
}

# ── Homebrew path ─────────────────────────────────────────────────────────

@test "sloth_update::sloth_repository_set_ready returns early when HOMEBREW_SLOTH is true" {
    HOMEBREW_SLOTH=true run sloth_update::sloth_repository_set_ready
    [ "$status" -eq 0 ]
}

@test "sloth_update::local_sloth_repository_can_be_updated returns early when HOMEBREW_SLOTH is true" {
    HOMEBREW_SLOTH=true run sloth_update::local_sloth_repository_can_be_updated
    [ "$status" -eq 0 ]
}

# ── Force current version file ────────────────────────────────────────────

@test "sloth_update::local_sloth_repository_can_be_updated returns 1 when force version file exists" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/.sloth_force_current_version"
    SLOTH_FORCE_CURRENT_VERSION_FILE="$tmpdir/.sloth_force_current_version" \
        run sloth_update::local_sloth_repository_can_be_updated
    [ "$status" -eq 1 ]
    rm -rf "$tmpdir"
}

# ── should_be_updated with update available file ─────────────────────────

@test "sloth_update::should_be_updated returns 0 when update available file exists" {
    local tmpdir
    tmpdir=$(mktemp -d)
    touch "$tmpdir/.sloth_update_available"
    SLOTH_UPDATE_AVAILABE_FILE="$tmpdir/.sloth_update_available" \
        run sloth_update::should_be_updated
    [ "$status" -eq 0 ]
    rm -rf "$tmpdir"
}

# ── gracefully: already up to date ────────────────────────────────────────

@test "sloth_update::gracefully returns 0 when already up to date" {
    local tmpdir
    tmpdir=$(mktemp -d)

    # Override functions to simulate "already up to date"
    sloth_update::sloth_repository_set_ready() { return 0; }
    sloth_update::should_be_updated() { return 1; }

    SLOTH_UPDATE_AVAILABE_FILE="$tmpdir/.sloth_update_available" \
        SLOTH_FORCE_CURRENT_VERSION_FILE="$tmpdir/.sloth_force_current_version" \
        SLOTH_ENV=production \
        run sloth_update::gracefully
    [ "$status" -eq 0 ]
    rm -rf "$tmpdir"
}

# ── exists_migration_script ───────────────────────────────────────────────

@test "sloth_update::exists_migration_script returns 0 when migration script exists" {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/migration"
    touch "$tmpdir/migration/v1.0.0"
    chmod +x "$tmpdir/migration/v1.0.0"

    # Override get_current_version to return a version with a migration script
    sloth_update::get_current_version() { echo "v1.0.0"; }

    SLOTH_PATH="$tmpdir" run sloth_update::exists_migration_script
    [ "$status" -eq 0 ]
    rm -rf "$tmpdir"
}

@test "sloth_update::exists_migration_script returns 1 when no migration script" {
    local tmpdir
    tmpdir=$(mktemp -d)

    sloth_update::get_current_version() { echo "v9.9.9"; }

    SLOTH_PATH="$tmpdir" run sloth_update::exists_migration_script
    [ "$status" -eq 1 ]
    rm -rf "$tmpdir"
}
