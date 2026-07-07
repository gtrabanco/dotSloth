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
# NOTE: git::add_to_gitignore appends to $GITIGNORE_PATH (not to its first
# argument $gitignore_file_path), so the test points GITIGNORE_PATH at the
# same file to exercise the intended behavior. See the final report for the
# noted bug.

@test "git::add_to_gitignore appends content and returns 0" {
    local gi
    gi=$(temp_file "")
    GITIGNORE_PATH="$gi" run git::add_to_gitignore "$gi" "build/"
    [ "$status" -eq 0 ]
    grep -q "^build/$" "$gi"
    rm -f "$gi"
}

@test "git::add_to_gitignore does not duplicate already-present content" {
    local gi
    gi=$(temp_file "build/")
    GITIGNORE_PATH="$gi" run git::add_to_gitignore "$gi" "build/"
    [ "$status" -eq 0 ]
    [ "$(grep -c '^build/$' "$gi")" -eq 1 ]
    rm -f "$gi"
}

# ── git::check_branch_is_behind ─────────────────────────────────────────────

@test "git::check_branch_is_behind returns 1 when no upstream is configured" {
    run git::check_branch_is_behind main -C "$REPO_DIR"
    [ "$status" -ne 0 ]
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
