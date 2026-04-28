#!/usr/bin/env bats
#
# Tests for scripts/import.sh.
#
# Each test runs the script with a stub `prism` that records its argv to a
# file, then asserts on the captured argv. This verifies argument
# construction without contacting a real Prismatic backend.

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORKDIR="$(mktemp -d)"
  ARGV_FILE="$WORKDIR/argv"
  CWD_FILE="$WORKDIR/cwd"
  CANARY="$WORKDIR/pwned"
  export ARGV_FILE CWD_FILE

  cat > "$WORKDIR/prism" <<'STUB'
#!/usr/bin/env bash
pwd > "$CWD_FILE"
{ printf '%s\0' "$@"; } > "$ARGV_FILE"
STUB
  chmod +x "$WORKDIR/prism"
  export PRISM_BIN="$WORKDIR/prism"
}

teardown() {
  rm -rf "$WORKDIR"
}

# Read the captured argv as a newline-joined string for easy matching.
captured_argv() {
  tr '\0' '\n' < "$ARGV_FILE"
}

@test "PATH_TO_YML produces -i and -p flags" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
    "$PROJECT_ROOT/scripts/import.sh"

  run captured_argv
  [ "$status" -eq 0 ]
  [[ "$output" == *"integrations:import"* ]]
  [[ "$output" == *"-i=int_1"* ]]
  [[ "$output" == *"-p=foo.yml"* ]]
  [[ "$output" != *"--test-api-key"* ]]
}

@test "PATH_TO_CNI cds and produces only -i" {
  mkdir -p "$WORKDIR/cni"
  INTEGRATION_ID=int_2 \
  PATH_TO_CNI="$WORKDIR/cni" \
    "$PROJECT_ROOT/scripts/import.sh"

  run captured_argv
  [[ "$output" == *"-i=int_2"* ]]
  [[ "$output" != *"-p="* ]]
  grep -q "/cni\$" "$CWD_FILE"
}

@test "missing path inputs fails with explicit error" {
  run env INTEGRATION_ID=int_3 PATH_TO_YML= PATH_TO_CNI= \
    "$PROJECT_ROOT/scripts/import.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Neither PATH_TO_YML nor PATH_TO_CNI is set"* ]]
}

@test "single test API key emits prism's quoted format" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS='flowA: secretA' \
    "$PROJECT_ROOT/scripts/import.sh"

  run captured_argv
  [[ "$output" == *'--test-api-key="flowA"="secretA"'* ]]
}

@test "multiple test API keys produce multiple flags" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS=$'flowA: secretA\nflowB: secretB\nflowC: secretC' \
    "$PROJECT_ROOT/scripts/import.sh"

  count=$(captured_argv | grep -c '^--test-api-key=')
  [ "$count" -eq 3 ]
  captured_argv | grep -qx -- '--test-api-key="flowA"="secretA"'
  captured_argv | grep -qx -- '--test-api-key="flowB"="secretB"'
  captured_argv | grep -qx -- '--test-api-key="flowC"="secretC"'
}

@test "flow names with spaces are accepted" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS=$'Customer Webhook: secretA\nOrder Sync: secretB' \
    "$PROJECT_ROOT/scripts/import.sh"

  captured_argv | grep -qx -- '--test-api-key="Customer Webhook"="secretA"'
  captured_argv | grep -qx -- '--test-api-key="Order Sync"="secretB"'
}

@test "empty TEST_API_KEYS string adds no flags" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS="" \
    "$PROJECT_ROOT/scripts/import.sh"

  run captured_argv
  [[ "$output" != *"--test-api-key"* ]]
}

@test "whitespace-only TEST_API_KEYS adds no flags" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS=$'   \n\n   ' \
    "$PROJECT_ROOT/scripts/import.sh"

  run captured_argv
  [[ "$output" != *"--test-api-key"* ]]
}

@test "non-mapping YAML (sequence) is rejected" {
  run env INTEGRATION_ID=int_1 PATH_TO_YML=foo.yml \
    PRISM_BIN="$PRISM_BIN" \
    TEST_API_KEYS=$'- flowA\n- flowB' \
    "$PROJECT_ROOT/scripts/import.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"must be a YAML mapping"* ]]
  [ ! -f "$ARGV_FILE" ]
}

@test "non-mapping YAML (scalar) is rejected" {
  run env INTEGRATION_ID=int_1 PATH_TO_YML=foo.yml \
    PRISM_BIN="$PRISM_BIN" \
    TEST_API_KEYS="just a plain string" \
    "$PROJECT_ROOT/scripts/import.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"must be a YAML mapping"* ]]
}

@test "literal double-quote in flow name is rejected" {
  run env INTEGRATION_ID=int_1 PATH_TO_YML=foo.yml \
    PRISM_BIN="$PRISM_BIN" \
    TEST_API_KEYS='"flow\"name": secret' \
    "$PROJECT_ROOT/scripts/import.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *'must not contain a literal'* ]]
}

@test "literal double-quote in API key is rejected" {
  run env INTEGRATION_ID=int_1 PATH_TO_YML=foo.yml \
    PRISM_BIN="$PRISM_BIN" \
    TEST_API_KEYS='flowA: "secret\"value"' \
    "$PROJECT_ROOT/scripts/import.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *'must not contain a literal'* ]]
}

@test "empty API key value is rejected" {
  run env INTEGRATION_ID=int_1 PATH_TO_YML=foo.yml \
    PRISM_BIN="$PRISM_BIN" \
    TEST_API_KEYS='flowA:' \
    "$PROJECT_ROOT/scripts/import.sh"

  [ "$status" -ne 0 ]
  [[ "$output" == *"empty API key"* ]]
}

@test "shell metacharacters in API key value do not execute" {
  # If the script ever interpolated $TEST_API_KEYS into a command line, the
  # `$(touch ...)` substitution would run. With env-var passthrough and an
  # argv array, the value reaches prism inert.
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS="flowA: \$(touch $CANARY)" \
    "$PROJECT_ROOT/scripts/import.sh"

  [ ! -e "$CANARY" ]
  run captured_argv
  [[ "$output" == *"--test-api-key=\"flowA\"=\"\$(touch $CANARY)\""* ]]
}

@test "shell metacharacters in INTEGRATION_ID do not execute" {
  INTEGRATION_ID="int_1\"; touch $CANARY; #" \
  PATH_TO_YML=foo.yml \
    "$PROJECT_ROOT/scripts/import.sh"

  [ ! -e "$CANARY" ]
  run captured_argv
  [[ "$output" == *"-i=int_1\"; touch $CANARY; #"* ]]
}

@test "API key value containing '=' (e.g. base64) is preserved" {
  INTEGRATION_ID=int_1 \
  PATH_TO_YML=foo.yml \
  TEST_API_KEYS='flowA: "YWJjZA=="' \
    "$PROJECT_ROOT/scripts/import.sh"

  captured_argv | grep -qx -- '--test-api-key="flowA"="YWJjZA=="'
}

@test "missing INTEGRATION_ID fails" {
  run env -u INTEGRATION_ID PATH_TO_YML=foo.yml PRISM_BIN="$PRISM_BIN" \
    "$PROJECT_ROOT/scripts/import.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"INTEGRATION_ID"* ]]
}
