#!/usr/bin/env bats
#
# Tests for scripts/marketplace.sh.

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORKDIR="$(mktemp -d)"
  ARGV_FILE="$WORKDIR/argv"
  CANARY="$WORKDIR/pwned"
  GITHUB_OUTPUT="$WORKDIR/github_output"
  : > "$GITHUB_OUTPUT"
  export ARGV_FILE GITHUB_OUTPUT

  cat > "$WORKDIR/prism" <<'STUB'
#!/usr/bin/env bash
{ printf '%s\0' "$@"; } > "$ARGV_FILE"
STUB
  chmod +x "$WORKDIR/prism"
  export PRISM_BIN="$WORKDIR/prism"
}

teardown() {
  rm -rf "$WORKDIR"
}

captured_argv() {
  tr '\0' '\n' < "$ARGV_FILE"
}

@test "marketplace emits integrations:marketplace VERSION_ID --available" {
  VERSION_ID=ver_1 \
    "$PROJECT_ROOT/scripts/marketplace.sh"

  run captured_argv
  [ "$status" -eq 0 ]
  [[ "$output" == *"integrations:marketplace"* ]]
  [[ "$output" == *"ver_1"* ]]
  [[ "$output" == *"--available"* ]]
}

@test "OVERVIEW adds --overview flag" {
  VERSION_ID=ver_1 \
  OVERVIEW="A useful integration" \
    "$PROJECT_ROOT/scripts/marketplace.sh"

  run captured_argv
  [[ "$output" == *"--overview=A useful integration"* ]]
}

@test "empty OVERVIEW omits --overview flag" {
  VERSION_ID=ver_1 \
  OVERVIEW="" \
    "$PROJECT_ROOT/scripts/marketplace.sh"

  run captured_argv
  [[ "$output" != *"--overview="* ]]
}

@test "EXIT_CODE=0 is written when prism succeeds" {
  VERSION_ID=ver_1 \
    "$PROJECT_ROOT/scripts/marketplace.sh"

  grep -qx 'EXIT_CODE=0' "$GITHUB_OUTPUT"
}

@test "EXIT_CODE captures non-zero prism exit and the script does not fail" {
  cat > "$WORKDIR/prism" <<'STUB'
#!/usr/bin/env bash
exit 9
STUB
  chmod +x "$WORKDIR/prism"

  run env VERSION_ID=ver_1 PRISM_BIN="$WORKDIR/prism" GITHUB_OUTPUT="$GITHUB_OUTPUT" \
    "$PROJECT_ROOT/scripts/marketplace.sh"

  [ "$status" -eq 0 ]
  grep -qx 'EXIT_CODE=9' "$GITHUB_OUTPUT"
}

@test "shell metacharacters in OVERVIEW do not execute" {
  VERSION_ID=ver_1 \
  OVERVIEW="\$(touch $CANARY)" \
    "$PROJECT_ROOT/scripts/marketplace.sh"

  [ ! -e "$CANARY" ]
  run captured_argv
  [[ "$output" == *"--overview=\$(touch $CANARY)"* ]]
}

@test "missing VERSION_ID fails" {
  run env -u VERSION_ID PRISM_BIN="$PRISM_BIN" GITHUB_OUTPUT="$GITHUB_OUTPUT" \
    "$PROJECT_ROOT/scripts/marketplace.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"VERSION_ID"* ]]
}
