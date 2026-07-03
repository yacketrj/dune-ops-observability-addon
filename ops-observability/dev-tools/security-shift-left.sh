#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
cd "$ROOT"

failures=0

run_quiet() {
  local name="$1"
  shift
  local out_file
  out_file="$(mktemp)"

  set +e
  "$@" >"$out_file" 2>&1
  local status=$?
  set -e

  if [ "$status" -eq 0 ]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    if [ -s "$out_file" ]; then
      tail -80 "$out_file"
    fi
    failures=$((failures + 1))
  fi

  rm -f "$out_file"
}

require_command() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "PASS: command available: $cmd"
    return 0
  fi
  echo "FAIL: command missing: $cmd"
  failures=$((failures + 1))
  return 1
}

require_command git || true
require_command node || true
require_command pre-commit || true
require_command gitleaks || true
require_command semgrep || true
require_command trivy || true
require_command python3 || true

run_quiet "git diff check" git diff --check
run_quiet "addon manifest validation" node scripts/validate.js
run_quiet "pre-commit" bash ops-observability/dev-tools/precommit-gate.sh
run_quiet "gitleaks scan" bash ops-observability/dev-tools/gitleaks-gate.sh
run_quiet "semgrep scan" bash ops-observability/dev-tools/semgrep-gate.sh
run_quiet "trivy filesystem scan" bash ops-observability/dev-tools/trivy-gate.sh

if [ "$failures" -ne 0 ]; then
  echo "FAIL: shift-left security gate ($failures failure(s))"
  exit 1
fi

echo "PASS: shift-left security gate"
