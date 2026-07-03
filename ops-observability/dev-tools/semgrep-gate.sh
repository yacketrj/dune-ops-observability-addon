#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
cd "$ROOT"

json_file="$(mktemp)"
err_file="$(mktemp)"
trap 'rm -f "$json_file" "$err_file"' EXIT

set +e
semgrep scan --error --json-output "$json_file" >/dev/null 2>"$err_file"
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "PASS: semgrep scan"
  exit 0
fi

if [ "$status" -eq 1 ]; then
  echo "FAIL: semgrep scan found blocking findings"
  python3 - "$json_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    print(f"Unable to parse Semgrep JSON output: {exc}")
    raise SystemExit(1)

results = data.get("results", [])
print(f"findings: {len(results)}")
for item in results:
    file_path = item.get("path", "<unknown>")
    start = item.get("start", {}) or {}
    line = start.get("line", "?")
    rule = item.get("check_id", "<unknown-rule>")
    extra = item.get("extra", {}) or {}
    severity = extra.get("severity", "UNKNOWN")
    message = str(extra.get("message", "")).splitlines()[0]
    print(f"- {file_path}:{line} [{severity}] {rule}: {message}")
PY
  exit 1
fi

echo "FAIL: semgrep scan failed with exit code $status"
if [ -s "$err_file" ]; then
  echo "stderr:"
  tail -40 "$err_file"
fi
exit "$status"
