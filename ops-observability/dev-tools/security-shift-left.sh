#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
cd "$ROOT"

failures=0

run_required() {
  local name="$1"
  shift
  echo
  echo "============================================================"
  echo "$name"
  echo "============================================================"
  if "$@"; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    failures=$((failures + 1))
  fi
}

require_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  echo "FAIL: required command not found: $cmd"
  failures=$((failures + 1))
  return 1
}

require_command git || true
require_command node || true
require_command pre-commit || true
require_command gitleaks || true
require_command semgrep || true
require_command trivy || true

run_required "git diff check" git diff --check
run_required "addon manifest validation" node scripts/validate.js
run_required "pre-commit hooks" pre-commit run --all-files --show-diff-on-failure
run_required "gitleaks scan" gitleaks detect --source . --no-git
run_required "semgrep scan" semgrep scan
run_required "trivy filesystem scan" trivy fs .

if [ "$failures" -ne 0 ]; then
  echo
  echo "FAIL: shift-left security gate failed ($failures failure(s))"
  exit 1
fi

echo
echo "PASS: shift-left security gate passed"
