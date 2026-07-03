#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
RELEASE_ID="${RELEASE_ID:-unreleased}"
EVIDENCE_DIR="${EVIDENCE_DIR:-ops-observability/evidence/releases/$RELEASE_ID}"
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

require_file_or_dir() {
  local path="$1"
  if [ -e "$path" ]; then
    return 0
  fi
  echo "missing: $path"
  return 1
}

check_clean_tree() {
  test -z "$(git status --porcelain)"
}

run_quiet "working tree clean" check_clean_tree
run_quiet "addon validation" node scripts/validate.js
run_quiet "package build" bash scripts/package.sh
run_quiet "pre-commit" bash ops-observability/dev-tools/precommit-gate.sh
run_quiet "gitleaks scan" bash ops-observability/dev-tools/gitleaks-gate.sh
run_quiet "semgrep scan" bash ops-observability/dev-tools/semgrep-gate.sh
run_quiet "trivy filesystem scan" bash ops-observability/dev-tools/trivy-gate.sh

run_quiet "release evidence directory exists" require_file_or_dir "$EVIDENCE_DIR"
run_quiet "testing evidence exists" require_file_or_dir "$EVIDENCE_DIR/testing"
run_quiet "security evidence exists" require_file_or_dir "$EVIDENCE_DIR/security"
run_quiet "SBOM evidence exists" require_file_or_dir "$EVIDENCE_DIR/sbom"
run_quiet "control evidence exists" require_file_or_dir "$EVIDENCE_DIR/controls"

if [ "$failures" -ne 0 ]; then
  echo "FAIL: release gate ($failures failure(s))"
  exit 1
fi

echo "PASS: release gate"
