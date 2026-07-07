#!/usr/bin/env bats
# bats file=true

# Functional tests for scripts/core/src/str.sh — str::* functions

load "../helpers/setup"

# ── str::split ──────────────────────────────────────────────────────────────

@test "str::split splits on a multi-character delimiter" {
    run str::split "a::b::c" "::"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[0]}" = "a" ]
    [ "${lines[1]}" = "b" ]
    [ "${lines[2]}" = "c" ]
}

@test "str::split splits on a single-character delimiter" {
    run str::split "a,b,c" ","
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[0]}" = "a" ]
    [ "${lines[1]}" = "b" ]
    [ "${lines[2]}" = "c" ]
}

@test "str::split on empty text returns a single empty line" {
    run str::split "" ","
    [ "$status" -eq 0 ]
}

# ── str::contains ───────────────────────────────────────────────────────────

@test "str::contains returns 0 when substring is present" {
    run str::contains "ell" "hello"
    [ "$status" -eq 0 ]
}

@test "str::contains returns 1 when substring is absent" {
    run str::contains "xyz" "hello"
    [ "$status" -eq 1 ]
}

# ── str::to_upper ────────────────────────────────────────────────────────────

@test "str::to_upper uppercases arguments" {
    run str::to_upper "hello"
    [ "$status" -eq 0 ]
    [ "$output" = "HELLO" ]
}

@test "str::to_upper uppercases stdin when no args given" {
    local out rc
    out=$(echo "world" | str::to_upper)
    rc=$?
    [ "$rc" -eq 0 ]
    [ "$out" = "WORLD" ]
}

# ── str::to_lower ────────────────────────────────────────────────────────────

@test "str::to_lower lowercases arguments" {
    run str::to_lower "HELLO"
    [ "$status" -eq 0 ]
    [ "$output" = "hello" ]
}

@test "str::to_lower lowercases stdin when no args given" {
    local out rc
    out=$(echo "WORLD" | str::to_lower)
    rc=$?
    [ "$rc" -eq 0 ]
    [ "$out" = "world" ]
}

# ── str::join ────────────────────────────────────────────────────────────────

@test "str::join joins elements with the glue" {
    run str::join "," "a" "b" "c"
    [ "$status" -eq 0 ]
    [ "$output" = "a,b,c" ]
}

@test "str::join with a single element returns it unchanged" {
    run str::join "," "solo"
    [ "$status" -eq 0 ]
    [ "$output" = "solo" ]
}

@test "str::join with an empty glue concatenates without separator" {
    run str::join "" "a" "b"
    [ "$status" -eq 0 ]
    [ "$output" = "ab" ]
}
