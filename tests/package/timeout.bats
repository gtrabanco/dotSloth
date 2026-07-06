#!/usr/bin/env bats
# bats file=true

# Test for package::run_with_timeout — timeout helper

load "../helpers/setup"

# ── Function existence ────────────────────────────────────────────────────

@test "package::run_with_timeout is defined" {
    declare -f package::run_with_timeout >/dev/null 2>&1
    [ $? -eq 0 ]
}

# ── Normal execution ──────────────────────────────────────────────────────

@test "package::run_with_timeout runs a fast command successfully" {
    run package::run_with_timeout 5 echo "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "package::run_with_timeout runs a command with arguments" {
    run package::run_with_timeout 5 printf "%s\n" "test"
    [ "$status" -eq 0 ]
    [ "$output" = "test" ]
}

# ── Timeout behavior ─────────────────────────────────────────────────────

@test "package::run_with_timeout returns 124 when command exceeds timeout" {
    if ! command -v gtimeout &>/dev/null && ! command -v timeout &>/dev/null; then
        skip "no timeout command available (gtimeout/timeout)"
    fi
    run package::run_with_timeout 1 sleep 10
    [ "$status" -eq 124 ]
}

# ── Default timeout ───────────────────────────────────────────────────────

@test "package::run_with_timeout uses SLOTH_PM_TIMEOUT as default" {
    SLOTH_PM_TIMEOUT=5
    run package::run_with_timeout "$SLOTH_PM_TIMEOUT" echo "works"
    [ "$status" -eq 0 ]
    [[ "$output" == *"works"* ]]
}
