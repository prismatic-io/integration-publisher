#!/usr/bin/env bats
#
# Tests for scripts/summary.sh.
#
# Each test runs the script with a temp GITHUB_STEP_SUMMARY file and the
# minimum required env, then asserts on the captured markdown content.

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORKDIR="$(mktemp -d)"
  GITHUB_STEP_SUMMARY="$WORKDIR/summary.md"
  : > "$GITHUB_STEP_SUMMARY"
  export GITHUB_STEP_SUMMARY
  export INTEGRATION_ID="int_123"
  export PRISMATIC_URL="https://example.invalid"
}

teardown() {
  rm -rf "$WORKDIR"
}

@test "summary heading includes PATH_TO_CNI when set" {
  PATH_TO_CNI="integrations/orders" \
    "$PROJECT_ROOT/scripts/summary.sh"

  run cat "$GITHUB_STEP_SUMMARY"
  [ "$status" -eq 0 ]
  [[ "$output" == *"#### \`integrations/orders\`"* ]]
  [[ "$output" == *"| Source Directory      | integrations/orders |"* ]]
}

@test "summary heading includes PATH_TO_YML when CNI is unset" {
  PATH_TO_YML="integrations/orders.yml" \
    "$PROJECT_ROOT/scripts/summary.sh"

  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"#### \`integrations/orders.yml\`"* ]]
  [[ "$output" == *"| Source File           | integrations/orders.yml |"* ]]
}

@test "summary falls back to INTEGRATION_ID when neither path is set" {
  "$PROJECT_ROOT/scripts/summary.sh"

  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"#### \`int_123\`"* ]]
}

@test "PATH_TO_CNI takes precedence over PATH_TO_YML" {
  PATH_TO_CNI="integrations/orders" \
  PATH_TO_YML="integrations/orders.yml" \
    "$PROJECT_ROOT/scripts/summary.sh"

  run cat "$GITHUB_STEP_SUMMARY"
  [[ "$output" == *"#### \`integrations/orders\`"* ]]
  [[ "$output" == *"| Source Directory      | integrations/orders |"* ]]
  [[ "$output" != *"| Source File"* ]]
}
