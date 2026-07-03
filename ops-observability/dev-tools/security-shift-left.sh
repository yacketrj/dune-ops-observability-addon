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

run_quiet "toolchain bootstrap" bash ops-observability/dev-tools/toolchain-bootstrap.sh git node python3 pre-commit gitleaks semgrep trivy
export DUNE_TOOLCHAIN_BOOTSTRAP_DONE=1

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
