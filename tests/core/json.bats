#!/usr/bin/env bats
# bats file=true

# Functional tests for scripts/core/src/json.sh — json::* functions
# json::is_valid depends on jq; json::to_yaml depends on python-yq (kislyuk/yq),
# whose `--yaml-output` flag is NOT supported by the Go yq (mikefarah/yq) that is
# preinstalled on CI. Each test skips when its own dependency is missing:
# json::is_valid tests skip when jq is absent; json::to_yaml tests skip when
# python-yq (kislyuk) is absent — detected via `yq --help | grep kislyuk`, like
# the python-yq recipe. The file-form branches are guarded by `[[ -t 0 ]]`,
# which is never true under bats (stdin is not a tty), so they are exercised
# through a small pty helper that skips when python3 is absent.

load "../helpers/setup"

# Run a bash -c command with stdin attached to a pseudo-terminal so that
# `[[ -t 0 ]]` is true inside the child. Sets PTY_STATUS (exit code) and
# PTY_OUTPUT (child stdout with carriage returns stripped). Skips the calling
# test when python3 (with the pty module) is unavailable.
_pty_bash() {
    local cmd="$1"
    command -v python3 >/dev/null 2>&1 || skip "python3 not installed"
    PTY_OUTPUT=$(python3 - "$cmd" <<'PYEOF'
import os, pty, sys
pid, fd = pty.fork()
if pid == 0:
    os.execvp("bash", ["bash", "-c", sys.argv[1]])
buf = b""
while True:
    try:
        chunk = os.read(fd, 4096)
    except OSError:
        break
    if not chunk:
        break
    buf += chunk
_, status = os.waitpid(pid, 0)
rc = os.waitstatus_to_exitcode(status) if hasattr(os, "waitstatus_to_exitcode") else (status >> 8)
sys.stdout.buffer.write(buf.replace(b"\r", b""))
sys.exit(rc)
PYEOF
)
    PTY_STATUS=$?
}

# json::to_yaml uses `yq --yaml-output`, a python-yq (kislyuk/yq) flag that the
# Go yq (mikefarah/yq) does not understand. Detect python-yq specifically, the
# same way the python-yq recipe does, so the to_yaml tests skip (rather than
# fail) when only the Go yq is installed — as is the case in CI.
_have_python_yq() {
    command -v yq >/dev/null 2>&1 && yq --help 2>&1 | grep -q "https://github.com/kislyuk/yq"
}

# ── json::is_valid ───────────────────────────────────────────────────────────

@test "json::is_valid returns 0 for valid JSON via stdin" {
    command -v jq >/dev/null 2>&1 || skip "jq not installed"
    local out rc
    out=$(echo "{\"a\":1}" | json::is_valid)
    rc=$?
    [ "$rc" -eq 0 ]
}

@test "json::is_valid returns non-zero for invalid JSON via stdin" {
    command -v jq >/dev/null 2>&1 || skip "jq not installed"
    ! echo "{not json}" | json::is_valid
}

@test "json::is_valid returns 0 for a valid JSON file" {
    command -v jq >/dev/null 2>&1 || skip "jq not installed"
    local f
    f=$(temp_file '{"a":1}')
    _pty_bash ". '${SLOTH_PATH}/scripts/core/src/_main.sh'; json::is_valid '$f'"
    [ "$PTY_STATUS" -eq 0 ]
    rm -f "$f"
}

@test "json::is_valid returns non-zero for an invalid JSON file" {
    command -v jq >/dev/null 2>&1 || skip "jq not installed"
    local f
    f=$(temp_file '{not json}')
    ! _pty_bash ". '${SLOTH_PATH}/scripts/core/src/_main.sh'; json::is_valid '$f'"
    [ "$PTY_STATUS" -ne 0 ]
    rm -f "$f"
}

# ── json::to_yaml ───────────────────────────────────────────────────────────

@test "json::to_yaml converts valid JSON to YAML via stdin" {
    _have_python_yq || skip "python-yq (kislyuk) not installed"
    local out rc
    out=$(echo "{\"a\":1,\"b\":\"two\"}" | json::to_yaml)
    rc=$?
    [ "$rc" -eq 0 ]
    [[ "$out" == *"a: 1"* ]]
    [[ "$out" == *"b: two"* ]]
}

@test "json::to_yaml converts valid JSON from a file" {
    _have_python_yq || skip "python-yq (kislyuk) not installed"
    local f
    f=$(temp_file '{"a":1,"b":"two"}')
    _pty_bash ". '${SLOTH_PATH}/scripts/core/src/_main.sh'; json::to_yaml '$f'"
    [ "$PTY_STATUS" -eq 0 ]
    [[ "$PTY_OUTPUT" == *"a: 1"* ]]
    [[ "$PTY_OUTPUT" == *"b: two"* ]]
    rm -f "$f"
}
