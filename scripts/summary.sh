#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_STEP_SUMMARY:?GITHUB_STEP_SUMMARY is required}"
: "${INTEGRATION_ID:?INTEGRATION_ID is required}"
: "${PRISMATIC_URL:?PRISMATIC_URL is required}"

skip_row() {
  local label="$1" skip="$2"
  if [[ "$skip" == "false" ]]; then
    echo "| $label | ✅ |"
  else
    echo "| $label | ❌ |"
  fi
}

source_label="${PATH_TO_CNI:-${PATH_TO_YML:-$INTEGRATION_ID}}"

{
  echo "### Integration Published :rocket:"
  echo "#### \`$source_label\`"
  echo "|![Prismatic Logo](https://app.prismatic.io/logo_fullcolor_white.svg)| Publish Info |"
  echo "| --------------------- | --------------- |"
  echo "| Integration ID        | $INTEGRATION_ID |"
  if [[ -n "${PATH_TO_CNI:-}" ]]; then
    echo "| Source Directory      | $PATH_TO_CNI |"
  elif [[ -n "${PATH_TO_YML:-}" ]]; then
    echo "| Source File           | $PATH_TO_YML |"
  fi
  echo "| Published Integration Version ID | ${VERSION_ID:-} |"
  echo "| Target Stack          | $PRISMATIC_URL |"
  echo "| Designer Link         | $PRISMATIC_URL/designer/$INTEGRATION_ID |"
  echo "| Commit Link           | ${COMMIT_URL:-} |"

  if [[ -n "${PRISMATIC_TENANT_ID:-}" ]]; then
    echo "| Tenant ID             | $PRISMATIC_TENANT_ID |"
  fi

  if [[ -n "${PR_URL:-}" ]]; then
    echo "| PR Link               | $PR_URL |"
  fi

  if [[ "${MAKE_AVAILABLE_IN_MARKETPLACE:-false}" == "true" ]]; then
    if [[ "${MARKETPLACE_EXIT_CODE:-}" == "0" ]]; then
      echo "| Made available in marketplace | ✅ |"
    else
      echo "| Made available in marketplace | ❌ |"
    fi
  fi

  skip_row "Commit Hash Published" "${SKIP_COMMIT_HASH_PUBLISH:-false}"
  skip_row "Commit Link Published" "${SKIP_COMMIT_URL_PUBLISH:-false}"
  skip_row "Repository Link Published" "${SKIP_REPO_URL_PUBLISH:-false}"
  skip_row "PR Link Published" "${SKIP_PULL_REQUEST_URL_PUBLISH:-false}"
} >> "$GITHUB_STEP_SUMMARY"
