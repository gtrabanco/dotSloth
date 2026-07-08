#!/usr/bin/env bats
# bats file=true

# Functional tests for scripts/core/src/git.sh — git::* functions
# Two tiers (per SPEC):
#   (a) a real temp git repo (created in setup) for state functions;
#   (b) the mock harness from tests/helpers/mock.sh for output-parsing
#       functions that shell out to git. clear_mocks runs in teardown.

load "../helpers/setup"

# Capture the real git binary resolved at load time (setup.bash sources
# _main.sh, which sets GIT_EXECUTABLE). Tests that mock git reassign
# GIT_EXECUTABLE to the mock; setup() resets it before every test so mock
# state never leaks across tests.
_REAL_GIT="$GIT_EXECUTABLE"

setup() {
    GIT_EXECUTABLE="$_REAL_GIT"
    REPO_DIR=$(temp_dir)
    git init -q -b main "$REPO_DIR"
    git -C "$REPO_DIR" config user.email "test@test.com"
    git -C "$REPO_DIR" config user.name "test"
    printf 'hello\n' > "$REPO_DIR/README.md"
    git -C "$REPO_DIR" add README.md
    git -C "$REPO_DIR" commit -qm "initial commit"
}

teardown() {
    clear_mocks
    rm -rf "$REPO_DIR"
}

# ── git::is_in_repo ─────────────────────────────────────────────────────────

@test "git::is_in_repo returns 0 inside a repository" {
    run git::is_in_repo -C "$REPO_DIR"
    [ "$status" -eq 0 ]
}

@test "git::is_in_repo returns 1 outside a repository" {
    local non_repo
    non_repo=$(temp_dir)
    run git::is_in_repo -C "$non_repo"
    [ "$status" -ne 0 ]
    rm -rf "$non_repo"
}

# ── git::current_branch ─────────────────────────────────────────────────────

@test "git::current_branch returns the active branch name" {
    run git::current_branch -C "$REPO_DIR"
    [ "$status" -eq 0 ]
    [ "$output" = "main" ]
}

# ── git::is_clean ───────────────────────────────────────────────────────────

@test "git::is_clean returns 0 when the working tree is clean" {
    run git::is_clean -C "$REPO_DIR"
    [ "$status" -eq 0 ]
}

@test "git::is_clean returns 1 when a tracked file is modified" {
    printf 'changed\n' > "$REPO_DIR/README.md"
    run git::is_clean -C "$REPO_DIR"
    [ "$status" -ne 0 ]
}

# ── git::current_commit_hash ─────────────────────────────────────────────────

@test "git::current_commit_hash returns a non-empty SHA for HEAD" {
    run git::current_commit_hash HEAD -C "$REPO_DIR"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ ^[0-9a-f]+$ ]]
}

@test "git::current_commit_hash with -C option (no explicit branch) defaults to HEAD" {
    run git::current_commit_hash -C "$REPO_DIR"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ ^[0-9a-f]+$ ]]
}

# ── git::local_branch_exists ────────────────────────────────────────────────

@test "git::local_branch_exists returns 0 for an existing branch" {
    run git::local_branch_exists main -C "$REPO_DIR"
    [ "$status" -eq 0 ]
}

@test "git::local_branch_exists returns 1 for a missing branch" {
    run git::local_branch_exists nonexistent_branch -C "$REPO_DIR"
    [ "$status" -ne 0 ]
}

# ── git::is_valid_commit ────────────────────────────────────────────────────

@test "git::is_valid_commit returns 0 for a valid commit" {
    run git::is_valid_commit HEAD -C "$REPO_DIR"
    [ "$status" -eq 0 ]
}

@test "git::is_valid_commit returns 1 for an invalid commit" {
    run git::is_valid_commit nonexistent_sha -C "$REPO_DIR"
    [ "$status" -ne 0 ]
}

# ── git::add_to_gitignore ───────────────────────────────────────────────────
# Tests use distinct files for $1 and $GITIGNORE_PATH to verify the
# function writes to its first argument, not the global $GITIGNORE_PATH.

@test "git::add_to_gitignore appends content to the first argument and returns 0" {
    local gi other
    gi=$(temp_file "")
    other=$(temp_file "")
    GITIGNORE_PATH="$other" run git::add_to_gitignore "$gi" "build/"
    [ "$status" -eq 0 ]
    grep -q "^build/$" "$gi"
    ! grep -q "^build/$" "$other"
    rm -f "$gi" "$other"
}

@test "git::add_to_gitignore does not duplicate already-present content" {
    local gi other
    gi=$(temp_file "build/")
    other=$(temp_file "")
    GITIGNORE_PATH="$other" run git::add_to_gitignore "$gi" "build/"
    [ "$status" -eq 0 ]
    [ "$(grep -c '^build/$' "$gi")" -eq 1 ]
    ! grep -q "^build/$" "$other"
    rm -f "$gi" "$other"
}

# ── git::check_branch_is_behind ─────────────────────────────────────────────

@test "git::check_branch_is_behind returns 1 when no upstream is configured" {
    run git::check_branch_is_behind main -C "$REPO_DIR"
    [ "$status" -ne 0 ]
}

# Distinguishing regression test: a remote ahead of local main is set up and
# branch.main.merge is wired to the remote-tracking ref, so the fixed code
# resolves branch=main, finds the upstream, and returns 0 (behind). Under the
# bug, $1 (-C) is consumed as the branch name, branch.-C.merge is unset, and
# the function returns 1 (no upstream) — so a 0 here proves -C was preserved.
@test "git::check_branch_is_behind with -C option does not consume -C" {
    local remote_dir
    remote_dir=$(temp_dir)
    git init -q -b main "$remote_dir"
    git -C "$remote_dir" config user.email "test@test.com"
    git -C "$remote_dir" config user.name "test"
    git -C "$remote_dir" commit -qm "remote root" --allow-empty
    git -C "$remote_dir" commit -qm "remote ahead" --allow-empty

    git -C "$REPO_DIR" remote add origin "$remote_dir"
    git -C "$REPO_DIR" fetch -q origin
    git -C "$REPO_DIR" config branch.main.merge "refs/remotes/origin/main"

    run git::check_branch_is_behind -C "$REPO_DIR"
    [ "$status" -eq 0 ]

    rm -rf "$remote_dir"
}

# ── git::check_branch_is_ahead ──────────────────────────────────────────────

# Distinguishing regression test: a remote is set up, local main is reset to
# origin/main and given one extra commit (strictly ahead, shared history), and
# branch.main.merge is wired to the remote-tracking ref, so the fixed code
# resolves branch=main, finds the upstream, and returns 0 (ahead). Under the
# bug, $1 (-C) is consumed as the branch name, branch.-C.merge is unset, and
# the function returns 1 (no upstream) — so a 0 here proves -C was preserved.
@test "git::check_branch_is_ahead with -C option does not consume -C" {
    local remote_dir
    remote_dir=$(temp_dir)
    git init -q -b main "$remote_dir"
    git -C "$remote_dir" config user.email "test@test.com"
    git -C "$remote_dir" config user.name "test"
    git -C "$remote_dir" commit -qm "remote root" --allow-empty

    git -C "$REPO_DIR" remote add origin "$remote_dir"
    git -C "$REPO_DIR" fetch -q origin
    git -C "$REPO_DIR" reset -q --hard origin/main
    git -C "$REPO_DIR" commit -qm "local ahead" --allow-empty
    git -C "$REPO_DIR" config branch.main.merge "refs/remotes/origin/main"

    run git::check_branch_is_ahead -C "$REPO_DIR"
    [ "$status" -eq 0 ]

    rm -rf "$remote_dir"
}

# ── git::remote_latest_tag_version (mock tier) ─────────────────────────────

@test "git::remote_latest_tag_version parses the latest tag from mocked git output" {
    mock_command git --stdout "abc123 refs/tags/v3.1.4"
    GIT_EXECUTABLE="$MOCK_DIR/git"
    run git::remote_latest_tag_version "https://example.com/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "3.1.4" ]
}

# ── git::check_remote_exists (mock tier) ────────────────────────────────────

@test "git::check_remote_exists returns 0 when the remote exists" {
    mock_command git --exit-code 0 --stdout "https://example.com/repo.git"
    GIT_EXECUTABLE="$MOCK_DIR/git"
    run git::check_remote_exists origin
    [ "$status" -eq 0 ]
}

@test "git::check_remote_exists returns non-zero when the remote is absent" {
    mock_command git --exit-code 1
    GIT_EXECUTABLE="$MOCK_DIR/git"
    run git::check_remote_exists origin
    [ "$status" -ne 0 ]
}

# ── git::remote_branch_exists (mock tier) ───────────────────────────────────

@test "git::remote_branch_exists returns 0 when the remote branch is listed" {
    mock_command git --stdout "origin/main"
    GIT_EXECUTABLE="$MOCK_DIR/git"
    run git::remote_branch_exists origin main
    [ "$status" -eq 0 ]
}

@test "git::remote_branch_exists returns 1 when the remote is unreachable" {
    mock_command git --exit-code 1
    GIT_EXECUTABLE="$MOCK_DIR/git"
    run git::remote_branch_exists origin main
    [ "$status" -ne 0 ]
}

# ── git::local_latest_tag_version (mock tier) ───────────────────────────────

@test "git::local_latest_tag_version returns the latest local tag" {
    mock_command git --stdout "v2.0.0"
    GIT_EXECUTABLE="$MOCK_DIR/git"
    run git::local_latest_tag_version "https://example.com/repo.git"
    [ "$status" -eq 0 ]
    [ "$output" = "2.0.0" ]
}
