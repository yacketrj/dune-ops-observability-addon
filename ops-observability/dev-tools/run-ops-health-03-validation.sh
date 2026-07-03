#!/usr/bin/env bash
set -euo pipefail

ADDON_ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CORE_ROOT="${CORE_WORKTREE:-$HOME/dune-work/core-pr-ops-health-expanded-aggregates}"

cd "$ADDON_ROOT"
bash ops-observability/dev-tools/toolchain-bootstrap.sh git node python3

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

check_string() {
  local needle="$1"
  grep -R "$needle" -n console/api/src console/api/test >/dev/null 2>&1
}

run_quiet "core worktree validation" bash ops-observability/dev-tools/validate-core-ops-health-worktree.sh

cd "$CORE_ROOT"

run_quiet "players action reference" check_string "ops.health.players"
run_quiet "farms action reference" check_string "ops.health.farms"
run_quiet "summary v2 action reference" check_string "ops.health.summary.v2"
run_quiet "players function reference" check_string "addonOpsHealthPlayers"
run_quiet "farms function reference" check_string "addonOpsHealthFarms"
run_quiet "summary v2 function reference" check_string "addonOpsHealthSummaryV2"
run_quiet "core diff check" git diff --check
run_quiet "core API tests" node --test console/api/test/db.test.js

if [ "$failures" -ne 0 ]; then
  echo "FAIL: Release 0.3 validation runner ($failures failure(s))"
  exit 1
fi

echo "PASS: Release 0.3 validation runner"
