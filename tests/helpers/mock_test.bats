#!/usr/bin/env bats
# bats file=true

# Tests for the mock harness (tests/helpers/mock.sh)

load "setup"

setup() {
  clear_mocks
}

teardown() {
  clear_mocks
}

@test "mock_command is defined" {
  declare -f mock_command >/dev/null 2>&1
  [ $? -eq 0 ]
}

@test "unmock_command is defined" {
  declare -f unmock_command >/dev/null 2>&1
  [ $? -eq 0 ]
}

@test "clear_mocks is defined" {
  declare -f clear_mocks >/dev/null 2>&1
  [ $? -eq 0 ]
}

@test "mock_command creates a mock that exits 0 with stdout" {
  mock_command fake_cmd --stdout "hello world"
  run fake_cmd
  [ "$status" -eq 0 ]
  [[ "$output" == *"hello world"* ]]
}

@test "mock_command creates a mock with custom exit code" {
  mock_command fake_cmd --exit-code 42 --stdout "error"
  run fake_cmd
  [ "$status" -eq 42 ]
  [[ "$output" == *"error"* ]]
}

@test "mock_command creates a mock with empty stdout" {
  mock_command fake_cmd --exit-code 1 --stdout ""
  run fake_cmd
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "unmock_command removes a mock" {
  mock_command fake_cmd --stdout "temp"
  run is_mocked fake_cmd
  [ "$status" -eq 0 ]
  unmock_command fake_cmd
  run is_mocked fake_cmd
  [ "$status" -ne 0 ]
}

@test "clear_mocks removes all mocks" {
  mock_command cmd_a --stdout "a"
  mock_command cmd_b --stdout "b"
  clear_mocks
  run is_mocked cmd_a
  [ "$status" -ne 0 ]
  run is_mocked cmd_b
  [ "$status" -ne 0 ]
}

@test "is_mocked returns false for non-existent mock" {
  run is_mocked nonexistent_cmd
  [ "$status" -ne 0 ]
}
