#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
cd "$ROOT"

out_file="$(mktemp)"
trap 'rm -f "$out_file"' EXIT

set +e
pre-commit run --all-files --show-diff-on-failure >"$out_file" 2>&1
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "PASS: pre-commit"
  exit 0
fi

echo "FAIL: pre-commit"
if grep -E "^(.*\.\.\.\.*Failed|Failed|hook id:|files were modified by this hook|Check|Fixing|Error|ERROR|FAIL)" "$out_file" | head -80; then
  true
else
  tail -80 "$out_file"
fi
exit "$status"
