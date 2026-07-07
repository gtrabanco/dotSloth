#!/usr/bin/env bats
# bats file=true

# Functional tests for scripts/core/src/array.sh — array::* functions

load "../helpers/setup"

# ── array::union ────────────────────────────────────────────────────────────

@test "array::union deduplicates and sorts elements" {
    run array::union 3 1 2 1 3 4
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 4 ]
    [ "${lines[0]}" = "1" ]
    [ "${lines[1]}" = "2" ]
    [ "${lines[2]}" = "3" ]
    [ "${lines[3]}" = "4" ]
}

@test "array::union with no args returns empty output" {
    run array::union
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ── array::disjunction ──────────────────────────────────────────────────────

@test "array::disjunction keeps only unique elements" {
    run array::disjunction 1 2 1 3 2
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 1 ]
    [ "${lines[0]}" = "3" ]
}

@test "array::disjunction with all duplicates returns empty" {
    run array::disjunction a a a
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ── array::difference ───────────────────────────────────────────────────────

@test "array::difference keeps only duplicated elements" {
    run array::difference 1 2 1 3 2
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "1" ]
    [ "${lines[1]}" = "2" ]
}

@test "array::difference with all unique returns empty" {
    run array::difference 1 2 3
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# ── array::exists_value ─────────────────────────────────────────────────────

@test "array::exists_value returns 0 when value is present" {
    run array::exists_value 2 1 2 3
    [ "$status" -eq 0 ]
}

@test "array::exists_value returns 1 when value is absent" {
    run array::exists_value 9 1 2 3
    [ "$status" -eq 1 ]
}

@test "array::exists_value returns 1 with fewer than two args" {
    run array::exists_value only_one
    [ "$status" -eq 1 ]
}

# ── array::substract ────────────────────────────────────────────────────────

@test "array::substract removes matching values" {
    run array::substract 2 1 2 3 4
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 3 ]
    [ "${lines[0]}" = "1" ]
    [ "${lines[1]}" = "3" ]
    [ "${lines[2]}" = "4" ]
}

@test "array::substract keeps all values when value not found" {
    run array::substract 9 1 2 3
    [ "$status" -eq 0 ]
    [ "$output" = "1 2 3" ]
}

# ── array::uniq_unordered ────────────────────────────────────────────────────
# Called directly (not via run) and eval its declare -p output, then inspect
# the resulting uniq_values array (per SPEC resolution).

@test "array::uniq_unordered preserves first-occurrence order without duplicates" {
    local out
    out=$(array::uniq_unordered a b a c b d)
    local -a uniq_values=()
    eval "$out"
    [ "${#uniq_values[@]}" -eq 4 ]
    [ "${uniq_values[0]}" = "a" ]
    [ "${uniq_values[1]}" = "b" ]
    [ "${uniq_values[2]}" = "c" ]
    [ "${uniq_values[3]}" = "d" ]
}

@test "array::uniq_unordered with no args declares an empty array" {
    local out
    out=$(array::uniq_unordered)
    local -a uniq_values=()
    eval "$out"
    [ "${#uniq_values[@]}" -eq 0 ]
}
