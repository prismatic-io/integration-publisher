#!/usr/bin/env bash
# Assert the stub prism captured an integrations:import call with the
# expected argv. Used by the action-smoke CI job to validate both the
# block-scalar and nested-object forms of TEST_API_KEYS.

set -euo pipefail
shopt -s nullglob

calls=("$RUNNER_TEMP"/prism-calls/*)
if [[ ${#calls[@]} -eq 0 ]]; then
  echo "::error::stub prism was not invoked"
  exit 1
fi

import_call=""
for f in "${calls[@]}"; do
  argv="$(tr '\0' '\n' < "$f")"
  if grep -qx 'integrations:import' <<<"$argv"; then
    import_call="$f"
    break
  fi
done

if [[ -z "$import_call" ]]; then
  echo "::error::no integrations:import call captured"
  for f in "${calls[@]}"; do
    echo "--- $f"
    tr '\0' '\n' < "$f"
  done
  exit 1
fi

argv="$(tr '\0' '\n' < "$import_call")"
echo "captured import argv:"
echo "$argv"

grep -qx -- '-i=smoke_int' <<<"$argv"
grep -qx -- '-p=tests/fixtures/integration.yml' <<<"$argv"
grep -qx -- '--test-api-key="flowA"="keyA"' <<<"$argv"
grep -qx -- '--test-api-key="flowB"="keyB with spaces"' <<<"$argv"
grep -qx -- '--test-api-key="Customer Webhook"="keyC"' <<<"$argv"
