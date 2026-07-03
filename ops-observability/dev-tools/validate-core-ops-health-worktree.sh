#!/usr/bin/env bash
set -euo pipefail

ROOT="${CORE_WORKTREE:-$HOME/dune-work/core-pr-ops-health-expanded-aggregates}"
EXPECTED_BRANCH="${EXPECTED_CORE_BRANCH:-ops-health-expanded-aggregates}"
EXPECTED_REMOTE_SLUG="${EXPECTED_CORE_REMOTE_SLUG:-yacketrj/dune-awakening-selfhost-docker-WSL}"

failures=0

pass() { echo "PASS: $*"; }
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

if [ ! -d "$ROOT/.git" ] && ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  fail "core worktree not found: $ROOT"
else
  pass "core worktree found"
fi

if [ "$failures" -eq 0 ]; then
  cd "$ROOT"

  current_branch="$(git branch --show-current || true)"
  if [ "$current_branch" = "$EXPECTED_BRANCH" ]; then
    pass "branch is $EXPECTED_BRANCH"
  else
    fail "branch is '$current_branch', expected '$EXPECTED_BRANCH'"
  fi

  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  case "$remote_url" in
    *"$EXPECTED_REMOTE_SLUG"*) pass "origin matches expected core repository" ;;
    *) fail "origin does not match expected core repository" ;;
  esac

  if [ -z "$(git status --porcelain)" ]; then
    pass "core worktree is clean"
  else
    fail "core worktree has local changes"
    git status --short
  fi

  for path in console/api/src/duneDb.js console/api/src/server.js console/api/test/db.test.js; do
    if [ -f "$path" ]; then
      pass "required file exists: $path"
    else
      fail "required file missing: $path"
    fi
  done

  if grep -R "ops.health.summary" -n console/api/src console/api/test >/dev/null 2>&1; then
    pass "baseline summary action reference found"
  else
    fail "baseline summary action reference missing"
  fi

  if grep -R "ops:read" -n console/api/src console/api/test >/dev/null 2>&1; then
    pass "baseline ops permission reference found"
  else
    fail "baseline ops permission reference missing"
  fi
fi

if [ "$failures" -ne 0 ]; then
  echo "FAIL: core OPS health worktree validation ($failures failure(s))"
  exit 1
fi

echo "PASS: core OPS health worktree validation"
