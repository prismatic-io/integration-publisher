#!/usr/bin/env bats
#
# Tests for scripts/publish.sh.
#
# Each test runs the script with a stub `prism` that records its argv to a
# file and emits a fake version ID, then asserts on the captured argv and
# step output.

setup() {
  PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  WORKDIR="$(mktemp -d)"
  ARGV_FILE="$WORKDIR/argv"
  CWD_FILE="$WORKDIR/cwd"
  CANARY="$WORKDIR/pwned"
  GITHUB_OUTPUT="$WORKDIR/github_output"
  : > "$GITHUB_OUTPUT"
  export ARGV_FILE CWD_FILE GITHUB_OUTPUT

  cat > "$WORKDIR/prism" <<'STUB'
#!/usr/bin/env bash
pwd > "$CWD_FILE"
{ printf '%s\0' "$@"; } > "$ARGV_FILE"
echo "fakeIntegrationVersionId"
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

@test "publish emits integrations:publish with INTEGRATION_ID" {
  INTEGRATION_ID=int_1 \
    "$PROJECT_ROOT/scripts/publish.sh"

  run captured_argv
  [ "$status" -eq 0 ]
  [[ "$output" == *"integrations:publish"* ]]
  [[ "$output" == *"int_1"* ]]
}

@test "publish writes the last non-empty stdout line as PUBLISHED_INTEGRATION_VERSION_ID" {
  INTEGRATION_ID=int_1 \
    "$PROJECT_ROOT/scripts/publish.sh"

  grep -q "^PUBLISHED_INTEGRATION_VERSION_ID=fakeIntegrationVersionId$" "$GITHUB_OUTPUT"
}

@test "metadata flags are appended when SKIP_* are false" {
  INTEGRATION_ID=int_1 \
  COMMIT_HASH=abc1234 \
  COMMIT_URL=https://example.invalid/c/abc1234 \
  REPO=owner/repo \
  PR_URL=https://example.invalid/pull/9 \
  SKIP_COMMIT_HASH_PUBLISH=false \
  SKIP_COMMIT_URL_PUBLISH=false \
  SKIP_REPO_URL_PUBLISH=false \
  SKIP_PULL_REQUEST_URL_PUBLISH=false \
    "$PROJECT_ROOT/scripts/publish.sh"

  run captured_argv
  [[ "$output" == *"--commitHash=abc1234"* ]]
  [[ "$output" == *"--commitUrl=https://example.invalid/c/abc1234"* ]]
  [[ "$output" == *"--repoUrl=owner/repo"* ]]
  [[ "$output" == *"--pullRequestUrl=https://example.invalid/pull/9"* ]]
}

@test "metadata flags are omitted when SKIP_* are true" {
  INTEGRATION_ID=int_1 \
  COMMIT_HASH=abc1234 \
  COMMIT_URL=https://example.invalid/c/abc1234 \
  REPO=owner/repo \
  PR_URL=https://example.invalid/pull/9 \
  SKIP_COMMIT_HASH_PUBLISH=true \
  SKIP_COMMIT_URL_PUBLISH=true \
  SKIP_REPO_URL_PUBLISH=true \
  SKIP_PULL_REQUEST_URL_PUBLISH=true \
    "$PROJECT_ROOT/scripts/publish.sh"

  run captured_argv
  [[ "$output" != *"--commitHash="* ]]
  [[ "$output" != *"--commitUrl="* ]]
  [[ "$output" != *"--repoUrl="* ]]
  [[ "$output" != *"--pullRequestUrl="* ]]
}

@test "metadata flags are omitted when their values are empty" {
  INTEGRATION_ID=int_1 \
  COMMIT_HASH= \
  COMMIT_URL= \
  REPO= \
  PR_URL= \
    "$PROJECT_ROOT/scripts/publish.sh"

  run captured_argv
  [[ "$output" != *"--commitHash="* ]]
  [[ "$output" != *"--commitUrl="* ]]
  [[ "$output" != *"--repoUrl="* ]]
  [[ "$output" != *"--pullRequestUrl="* ]]
}

@test "CUSTOMER_ID adds --customer flag" {
  INTEGRATION_ID=int_1 \
  CUSTOMER_ID=cust_42 \
    "$PROJECT_ROOT/scripts/publish.sh"

  run captured_argv
  [[ "$output" == *"--customer=cust_42"* ]]
}

@test "COMMENT adds --comment flag" {
  INTEGRATION_ID=int_1 \
  COMMENT="release notes" \
    "$PROJECT_ROOT/scripts/publish.sh"

  run captured_argv
  [[ "$output" == *"--comment=release notes"* ]]
}

@test "PATH_TO_CNI cds before invoking prism" {
  mkdir -p "$WORKDIR/cni"
  INTEGRATION_ID=int_2 \
  PATH_TO_CNI="$WORKDIR/cni" \
    "$PROJECT_ROOT/scripts/publish.sh"

  grep -q "/cni\$" "$CWD_FILE"
}

@test "shell metacharacters in COMMENT do not execute" {
  INTEGRATION_ID=int_1 \
  COMMENT="\$(touch $CANARY)" \
    "$PROJECT_ROOT/scripts/publish.sh"

  [ ! -e "$CANARY" ]
  run captured_argv
  [[ "$output" == *"--comment=\$(touch $CANARY)"* ]]
}

@test "non-zero prism exit fails the script and surfaces output" {
  cat > "$WORKDIR/prism" <<'STUB'
#!/usr/bin/env bash
echo "boom"
exit 7
STUB
  chmod +x "$WORKDIR/prism"

  run env INTEGRATION_ID=int_1 PRISM_BIN="$WORKDIR/prism" GITHUB_OUTPUT="$GITHUB_OUTPUT" \
    "$PROJECT_ROOT/scripts/publish.sh"

  [ "$status" -eq 7 ]
  [[ "$output" == *"prism integrations:publish failed"* ]]
  [[ "$output" == *"boom"* ]]
  ! grep -q PUBLISHED_INTEGRATION_VERSION_ID "$GITHUB_OUTPUT"
}

@test "missing INTEGRATION_ID fails" {
  run env -u INTEGRATION_ID PRISM_BIN="$PRISM_BIN" GITHUB_OUTPUT="$GITHUB_OUTPUT" \
    "$PROJECT_ROOT/scripts/publish.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"INTEGRATION_ID"* ]]
}
