#!/usr/bin/env bash
# Build and run `prism integrations:import` from action inputs.
#
# Inputs are read from environment variables — never interpolated into the
# shell by the caller — so values containing shell metacharacters cannot
# break out into command execution.
#
# Required env: INTEGRATION_ID, plus one of PATH_TO_YML or PATH_TO_CNI.
# Optional env: TEST_API_KEYS — a YAML mapping of flowName -> API_KEY. The
#               script wraps each pair in prism's required "name"="key"
#               format before passing it to --test-api-key.
# PRISM_BIN overrides the prism executable for testing.

set -euo pipefail

: "${INTEGRATION_ID:?INTEGRATION_ID is required}"

PRISM_BIN="${PRISM_BIN:-prism}"
PATH_TO_YML="${PATH_TO_YML:-}"
PATH_TO_CNI="${PATH_TO_CNI:-}"
TEST_API_KEYS="${TEST_API_KEYS:-}"

args=()

if [[ -n "$PATH_TO_YML" ]]; then
  args+=("-i=$INTEGRATION_ID" "-p=$PATH_TO_YML")
elif [[ -n "$PATH_TO_CNI" ]]; then
  cd "$PATH_TO_CNI"
  args+=("-i=$INTEGRATION_ID")
else
  echo "Neither PATH_TO_YML nor PATH_TO_CNI is set" >&2
  exit 1
fi

if [[ -n "${TEST_API_KEYS//[[:space:]]/}" ]]; then
  for tool in yq jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      echo "TEST_API_KEYS requires '$tool' on PATH (preinstalled on GitHub-hosted runners)." >&2
      exit 1
    fi
  done

  if ! TEST_API_KEYS_JSON=$(yq -o=json '.' <<<"$TEST_API_KEYS" 2>/dev/null); then
    echo "TEST_API_KEYS is not valid YAML." >&2
    exit 1
  fi

  kind=$(jq -r 'type' <<<"$TEST_API_KEYS_JSON")
  if [[ "$kind" != "object" ]]; then
    echo "TEST_API_KEYS must be a YAML mapping (flowName: apiKey), got $kind." >&2
    exit 1
  fi

  while IFS= read -r entry; do
    flow_name=$(jq -r '.key   | if . == null then "" else tostring end' <<<"$entry")
    api_key=$(jq   -r '.value | if . == null then "" else tostring end' <<<"$entry")

    if [[ -z "$flow_name" ]]; then
      echo "TEST_API_KEYS contains an entry with an empty flow name." >&2
      exit 1
    fi
    if [[ -z "$api_key" ]]; then
      echo "TEST_API_KEYS: empty API key for flow '$flow_name'." >&2
      exit 1
    fi
    # prism's --test-api-key parser uses [^"] for both flow name and value,
    # so neither side can contain a literal double-quote.
    if [[ "$flow_name" == *\"* || "$api_key" == *\"* ]]; then
      echo "TEST_API_KEYS: flow name and API key must not contain a literal '\"' (flow: '$flow_name')." >&2
      exit 1
    fi

    args+=("--test-api-key=\"${flow_name}\"=\"${api_key}\"")
  done < <(jq -c 'to_entries[]' <<<"$TEST_API_KEYS_JSON")
fi

exec "$PRISM_BIN" integrations:import "${args[@]}"
