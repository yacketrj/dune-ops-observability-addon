#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
BASE_REF="${BASE_REF:-origin/main}"
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

check_clean_tree() {
  test -z "$(git status --porcelain)"
}

check_branch_has_commits() {
  local count
  count="$(git rev-list --count "$BASE_REF"..HEAD)"
  test "$count" -gt 0
}

check_changed_files() {
  test -n "$(git diff --name-only "$BASE_REF"..HEAD)"
}

run_quiet "toolchain bootstrap" bash ops-observability/dev-tools/toolchain-bootstrap.sh git node python3 pre-commit gitleaks semgrep trivy
export DUNE_TOOLCHAIN_BOOTSTRAP_DONE=1

run_quiet "fetch origin" git fetch origin --prune
run_quiet "working tree clean" check_clean_tree
run_quiet "branch has commits over base" check_branch_has_commits
run_quiet "changed files exist" check_changed_files
run_quiet "diff check" git diff --check "$BASE_REF"..HEAD
run_quiet "addon validation" node scripts/validate.js
run_quiet "pre-commit" bash ops-observability/dev-tools/precommit-gate.sh
run_quiet "shift-left security" bash ops-observability/dev-tools/security-shift-left.sh

if [ "$failures" -ne 0 ]; then
  echo "FAIL: PR gate ($failures failure(s))"
  exit 1
fi

echo "PASS: PR gate"
