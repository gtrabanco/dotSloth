#!/usr/bin/env bats
# bats file=true

# Mock functions for external commands used by dotSloth
# These are placed first in PATH to override real commands during tests

# Mock: curl — always succeeds, returns empty or temp file content
mock_curl() {
    echo "mocked curl response"
    return 0
}

# Mock: brew — always succeeds, returns empty
mock_brew() {
    echo "mocked brew response"
    return 0
}

# Mock: dnf — always succeeds, returns empty
mock_dnf() {
    echo "mocked dnf response"
    return 0
}

# Mock: pip — always succeeds, returns empty
mock_pip() {
    echo "mocked pip response"
    return 0
}

# Mock: apt — always succeeds, returns empty
mock_apt() {
    echo "mocked apt response"
    return 0
}

# Mock: git — always succeeds, returns mocked git output
mock_git() {
    echo "mocked git response"
    return 0
}

# Mock: sudo — always succeeds
mock_sudo() {
    echo "mocked sudo response"
    return 0
}
