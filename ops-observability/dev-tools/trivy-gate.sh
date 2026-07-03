#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null)}"
cd "$ROOT"

json_file="$(mktemp)"
err_file="$(mktemp)"
trap 'rm -f "$json_file" "$err_file"' EXIT

set +e
trivy fs --exit-code 1 --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL --format json --output "$json_file" . >/dev/null 2>"$err_file"
status=$?
set -e

if [ "$status" -eq 0 ]; then
  echo "PASS: trivy filesystem scan"
  exit 0
fi

echo "FAIL: trivy filesystem scan"
if [ -s "$json_file" ]; then
  python3 - "$json_file" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
except Exception as exc:
    print(f"Unable to parse Trivy JSON output: {exc}")
    raise SystemExit(0)

vulns = []
secrets = []
misconfigs = []
for result in data.get("Results", []) or []:
    target = result.get("Target", "<unknown>")
    for vuln in result.get("Vulnerabilities", []) or []:
        vulns.append((target, vuln))
    for secret in result.get("Secrets", []) or []:
        secrets.append((target, secret))
    for misconfig in result.get("Misconfigurations", []) or []:
        misconfigs.append((target, misconfig))

print(f"vulnerabilities: {len(vulns)}")
for target, vuln in vulns[:50]:
    vid = vuln.get("VulnerabilityID", "<unknown>")
    pkg = vuln.get("PkgName", "<unknown-package>")
    severity = vuln.get("Severity", "UNKNOWN")
    installed = vuln.get("InstalledVersion", "?")
    fixed = vuln.get("FixedVersion", "")
    suffix = f" fixed={fixed}" if fixed else ""
    print(f"- {target} [{severity}] {vid} {pkg}@{installed}{suffix}")
if len(vulns) > 50:
    print(f"... {len(vulns) - 50} more vulnerability finding(s)")

print(f"secrets: {len(secrets)}")
for target, secret in secrets[:50]:
    title = secret.get("Title") or secret.get("RuleID") or "secret finding"
    start_line = secret.get("StartLine", "?")
    print(f"- {target}:{start_line} {title}")
if len(secrets) > 50:
    print(f"... {len(secrets) - 50} more secret finding(s)")

print(f"misconfigurations: {len(misconfigs)}")
for target, misconfig in misconfigs[:50]:
    mid = misconfig.get("ID", "<unknown>")
    severity = misconfig.get("Severity", "UNKNOWN")
    title = misconfig.get("Title", "misconfiguration")
    print(f"- {target} [{severity}] {mid}: {title}")
if len(misconfigs) > 50:
    print(f"... {len(misconfigs) - 50} more misconfiguration finding(s)")
PY
fi
if [ -s "$err_file" ]; then
  tail -40 "$err_file"
fi
exit "$status"
