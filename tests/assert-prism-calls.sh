#!/usr/bin/env bash
# Assert the stub prism captured the expected sequence of calls during the
# action-smoke CI job: integrations:import, integrations:publish, and
# integrations:marketplace.

set -euo pipefail
shopt -s nullglob

calls=("$RUNNER_TEMP"/prism-calls/*)
if [[ ${#calls[@]} -eq 0 ]]; then
  echo "::error::stub prism was not invoked"
  exit 1
fi

find_call() {
  local subcommand="$1"
  for f in "${calls[@]}"; do
    if grep -qx "$subcommand" < <(tr '\0' '\n' < "$f"); then
      echo "$f"
      return 0
    fi
  done
  return 1
}

dump_all() {
  for f in "${calls[@]}"; do
    echo "--- $f"
    tr '\0' '\n' < "$f"
  done
}

import_call=$(find_call 'integrations:import') || {
  echo "::error::no integrations:import call captured"
  dump_all
  exit 1
}
publish_call=$(find_call 'integrations:publish') || {
  echo "::error::no integrations:publish call captured"
  dump_all
  exit 1
}
marketplace_call=$(find_call 'integrations:marketplace') || {
  echo "::error::no integrations:marketplace call captured"
  dump_all
  exit 1
}

echo "captured import argv:"
import_argv=$(tr '\0' '\n' < "$import_call")
echo "$import_argv"
grep -qx -- '-i=smoke_int' <<<"$import_argv"
grep -qx -- '-p=tests/fixtures/integration.yml' <<<"$import_argv"
grep -qx -- '--test-api-key="flowA"="keyA"' <<<"$import_argv"
grep -qx -- '--test-api-key="flowB"="keyB with spaces"' <<<"$import_argv"
grep -qx -- '--test-api-key="Customer Webhook"="keyC"' <<<"$import_argv"

echo "captured publish argv:"
publish_argv=$(tr '\0' '\n' < "$publish_call")
echo "$publish_argv"
grep -qx -- 'smoke_int' <<<"$publish_argv"
grep -q  -- '--commitHash=' <<<"$publish_argv"
grep -q  -- '--commitUrl=' <<<"$publish_argv"
grep -qx -- '--repoUrl=prismatic-io/integration-publisher' <<<"$publish_argv"
grep -qx -- '--customer=cust_smoke' <<<"$publish_argv"
grep -qx -- '--comment=smoke comment' <<<"$publish_argv"

echo "captured marketplace argv:"
marketplace_argv=$(tr '\0' '\n' < "$marketplace_call")
echo "$marketplace_argv"
grep -qx -- 'fakeIntegrationVersionId' <<<"$marketplace_argv"
grep -qx -- '--available' <<<"$marketplace_argv"
grep -qx -- '--overview=Smoke overview' <<<"$marketplace_argv"
