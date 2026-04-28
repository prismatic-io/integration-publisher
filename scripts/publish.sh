#!/usr/bin/env bash
# Build and run `prism integrations:publish` from environment variables.
# Inputs are read from env — never interpolated into the shell by the
# caller — so values containing shell metacharacters cannot break out
# into command execution.
#
# PRISM_BIN overrides the prism executable for testing.

set -uo pipefail

: "${INTEGRATION_ID:?INTEGRATION_ID is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

PRISM_BIN="${PRISM_BIN:-prism}"
PATH_TO_CNI="${PATH_TO_CNI:-}"

if [[ -n "$PATH_TO_CNI" ]]; then
  cd "$PATH_TO_CNI" || exit 1
fi

args=("integrations:publish" "$INTEGRATION_ID")

[[ "${SKIP_COMMIT_HASH_PUBLISH:-false}" == "false" && -n "${COMMIT_HASH:-}" ]] && args+=("--commitHash=$COMMIT_HASH")
[[ "${SKIP_COMMIT_URL_PUBLISH:-false}" == "false" && -n "${COMMIT_URL:-}" ]] && args+=("--commitUrl=$COMMIT_URL")
[[ "${SKIP_REPO_URL_PUBLISH:-false}" == "false" && -n "${REPO:-}" ]] && args+=("--repoUrl=$REPO")
[[ "${SKIP_PULL_REQUEST_URL_PUBLISH:-false}" == "false" && -n "${PR_URL:-}" ]] && args+=("--pullRequestUrl=$PR_URL")
[[ -n "${CUSTOMER_ID:-}" ]] && args+=("--customer=$CUSTOMER_ID")
[[ -n "${COMMENT:-}" ]] && args+=("--comment=$COMMENT")

output=$("$PRISM_BIN" "${args[@]}" 2>&1)
status=$?

if (( status != 0 )); then
  echo "::error::prism integrations:publish failed (exit $status)"
  echo "$output"
  exit "$status"
fi

echo "$output"

version_id=$(printf '%s\n' "$output" | awk 'NF{last=$0} END{print last}')
echo "PUBLISHED_INTEGRATION_VERSION_ID=$version_id" >> "$GITHUB_OUTPUT"
