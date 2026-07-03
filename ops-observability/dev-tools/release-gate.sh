#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
RELEASE_ID="${RELEASE_ID:-unreleased}"
EVIDENCE_DIR="${EVIDENCE_DIR:-ops-observability/evidence/releases/$RELEASE_ID}"
cd "$ROOT"

failures=0

check() {
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

require_file_or_dir() {
  local path="$1"
  test -e "$path"
}

check "working tree clean" test -z "$(git status --porcelain)"
check "addon validation" node scripts/validate.js
check "package build" bash scripts/package.sh
check "pre-commit" pre-commit run --all-files --show-diff-on-failure
check "gitleaks scan" gitleaks detect --source . --no-git
check "semgrep scan" semgrep scan
check "trivy filesystem scan" trivy fs .

check "release evidence directory exists" require_file_or_dir "$EVIDENCE_DIR"
check "testing evidence exists" require_file_or_dir "$EVIDENCE_DIR/testing"
check "security evidence exists" require_file_or_dir "$EVIDENCE_DIR/security"
check "SBOM evidence exists" require_file_or_dir "$EVIDENCE_DIR/sbom"
check "control evidence exists" require_file_or_dir "$EVIDENCE_DIR/controls"

if [ "$failures" -ne 0 ]; then
  echo
  echo "FAIL: release gate failed ($failures failure(s))"
  exit 1
fi

echo
echo "PASS: release gate passed"
