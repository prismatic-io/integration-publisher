#!/usr/bin/env bash
# Validate required inputs before any expensive setup runs (Node install,
# Prism install, etc.). Inputs are read from the environment so values
# containing shell metacharacters cannot break out into command execution.

set -euo pipefail

fail=0

if [[ -z "${PRISMATIC_URL:-}" ]]; then
  echo "::error::PRISMATIC_URL is not set"
  fail=1
fi

if [[ -z "${PRISM_REFRESH_TOKEN:-}" ]]; then
  echo "::error::PRISM_REFRESH_TOKEN is not set"
  fail=1
fi

if [[ -z "${INTEGRATION_ID:-}" ]]; then
  echo "::error::INTEGRATION_ID is not set"
  fail=1
fi

PATH_TO_YML="${PATH_TO_YML:-}"
PATH_TO_CNI="${PATH_TO_CNI:-}"

if [[ -z "$PATH_TO_YML" && -z "$PATH_TO_CNI" ]]; then
  echo "::error::Neither PATH_TO_YML nor PATH_TO_CNI is set"
  fail=1
elif [[ -n "$PATH_TO_YML" && -n "$PATH_TO_CNI" ]]; then
  echo "::error::Both PATH_TO_YML and PATH_TO_CNI provided. Provide only one."
  fail=1
fi

(( fail == 0 ))
