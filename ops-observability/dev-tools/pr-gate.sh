#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
BASE_REF="${BASE_REF:-origin/main}"
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

check "fetch origin" git fetch origin --prune
check "working tree clean" test -z "$(git status --porcelain)"
check "branch has commits over base" test -n "$(git rev-list --count "$BASE_REF"..HEAD)"
check "changed files" git diff --name-only "$BASE_REF"..HEAD
check "diff check" git diff --check "$BASE_REF"..HEAD
check "addon validation" node scripts/validate.js
check "pre-commit" pre-commit run --all-files --show-diff-on-failure

if [ -x ops-observability/dev-tools/security-shift-left.sh ]; then
  check "shift-left security" ops-observability/dev-tools/security-shift-left.sh
else
  check "shift-left security" bash ops-observability/dev-tools/security-shift-left.sh
fi

if [ "$failures" -ne 0 ]; then
  echo
  echo "FAIL: PR gate failed ($failures failure(s))"
  exit 1
fi

echo
echo "PASS: PR gate passed"
