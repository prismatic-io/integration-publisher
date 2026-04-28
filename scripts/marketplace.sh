#!/usr/bin/env bash
# Toggle the just-published integration version into Marketplace. Failure
# here is reported in the step summary but does not fail the action — the
# integration was already published, and the marketplace flip is secondary.
#
# PRISM_BIN overrides the prism executable for testing.

set -uo pipefail

: "${VERSION_ID:?VERSION_ID is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

PRISM_BIN="${PRISM_BIN:-prism}"
OVERVIEW="${OVERVIEW:-}"

args=("integrations:marketplace" "$VERSION_ID" "--available")
[[ -n "$OVERVIEW" ]] && args+=("--overview=$OVERVIEW")

"$PRISM_BIN" "${args[@]}"
echo "EXIT_CODE=$?" >> "$GITHUB_OUTPUT"
