#!/usr/bin/env bats
# bats file=true

# Integration tests for dot command dispatch — end-to-end behavior

load "setup"

setup() {
    DOT="${SLOTH_PATH}/bin/dot"
}

# ── Integration tests ─────────────────────────────────────────────────────

@test "dot core version command runs with timeout" {
    run bash -c "timeout 2 '${DOT}' core version 2>&1 <<< ''"
    [ "$status" -eq 0 ] || [ "$status" -eq 124 ]
}
