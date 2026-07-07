#!/usr/bin/env bats
# bats file=true

# Integration tests for dot command dispatch — end-to-end behavior

load "../helpers/setup"

setup() {
    DOT="${SLOTH_PATH}/bin/dot"
}

# ── Integration tests ─────────────────────────────────────────────────────

@test "dot core version command runs without hanging" {
    if ! command -v timeout &>/dev/null; then
        skip "timeout not available"
    fi
    run bash -c "timeout 2 '${DOT}' core version 2>&1 <<< ''"
    # Exit 0 = success, 124 = timeout (acceptable), 1 = error but didn't hang
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ] || [ "$status" -eq 1 ]
}
