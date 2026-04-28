#!/usr/bin/env bats
#
# Tests for scripts/validate-inputs.sh.

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  REQUIRED=(
    PRISMATIC_URL=https://example.invalid
    PRISM_REFRESH_TOKEN=tok
    INTEGRATION_ID=int_1
    PATH_TO_YML=foo.yml
    PATH_TO_CNI=
  )
}

@test "passes when required inputs and exactly one path are set" {
  run env "${REQUIRED[@]}" "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -eq 0 ]
}

@test "fails when PRISMATIC_URL is empty" {
  run env "${REQUIRED[@]}" PRISMATIC_URL= "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PRISMATIC_URL"* ]]
}

@test "fails when PRISM_REFRESH_TOKEN is empty" {
  run env "${REQUIRED[@]}" PRISM_REFRESH_TOKEN= "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PRISM_REFRESH_TOKEN"* ]]
}

@test "fails when INTEGRATION_ID is empty" {
  run env "${REQUIRED[@]}" INTEGRATION_ID= "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"INTEGRATION_ID"* ]]
}

@test "fails when neither PATH_TO_YML nor PATH_TO_CNI is set" {
  run env "${REQUIRED[@]}" PATH_TO_YML= PATH_TO_CNI= "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Neither PATH_TO_YML nor PATH_TO_CNI"* ]]
}

@test "fails when both PATH_TO_YML and PATH_TO_CNI are set" {
  run env "${REQUIRED[@]}" PATH_TO_YML=foo.yml PATH_TO_CNI=src/cni "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Both PATH_TO_YML and PATH_TO_CNI"* ]]
}

@test "PATH_TO_CNI alone is accepted" {
  run env "${REQUIRED[@]}" PATH_TO_YML= PATH_TO_CNI=src/cni "$PROJECT_ROOT/scripts/validate-inputs.sh"
  [ "$status" -eq 0 ]
}
