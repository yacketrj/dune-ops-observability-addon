#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
cd "$ROOT"

report_file="$(mktemp)"
err_file="$(mktemp)"
trap 'rm -f "$report_file" "$err_file"' EXIT

set +e
gitleaks detect --source . --no-git --report-format json --report-path "$report_file" >/dev/null 2>"$err_file"
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "PASS: gitleaks scan"
  exit 0
fi

echo "FAIL: gitleaks scan"
if [ -s "$report_file" ]; then
  python3 - "$report_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    print(f"Unable to parse Gitleaks JSON report: {exc}")
    raise SystemExit(0)

if isinstance(data, dict):
    findings = data.get("findings") or data.get("Findings") or []
elif isinstance(data, list):
    findings = data
else:
    findings = []

print(f"findings: {len(findings)}")
for item in findings[:50]:
    file_path = item.get("File") or item.get("file") or "<unknown>"
    line = item.get("StartLine") or item.get("startLine") or item.get("Line") or "?"
    rule = item.get("RuleID") or item.get("ruleID") or item.get("Description") or "<unknown-rule>"
    print(f"- {file_path}:{line} {rule}")
if len(findings) > 50:
    print(f"... {len(findings) - 50} more finding(s)")
PY
fi
if [ -s "$err_file" ]; then
  tail -40 "$err_file"
fi
exit "$status"
