#!/usr/bin/env bats
# bats file=true

# Test for bin/dot entry point — CLI interface behavior

load "setup"

setup() {
    DOT="${SLOTH_PATH}/bin/dot"
}

# ── Entry point tests ─────────────────────────────────────────────────────

@test "bin/dot exists and is executable" {
    [[ -x "$DOT" ]]
}

@test "bin/dot sets SLOTH_PATH correctly" {
    local test_sloth_path="$SLOTH_PATH"
    [[ -d "$test_sloth_path" ]]
}
