#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${DUNE_CONSOLE_BASE_URL:-http://localhost:8080}"
ADDON_ID="${ADDON_ID:-dune-ops-observability}"
COOKIE_FILE="${DUNE_CONSOLE_COOKIE_FILE:-}"
CSRF_TOKEN="${DUNE_CONSOLE_CSRF_TOKEN:-}"

failures=0

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

pass() { echo "PASS: $*"; }
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

need_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "tool available: $1"
  else
    fail "tool missing: $1"
  fi
}

need_tool curl
need_tool python3

if [ "$failures" -ne 0 ]; then
  echo "FAIL: bridge probe prerequisites ($failures failure(s))"
  exit 1
fi

curl_args=(--silent --show-error --location --max-time 30)

if [ -n "$COOKIE_FILE" ]; then
  if [ -f "$COOKIE_FILE" ]; then
    curl_args+=(--cookie "$COOKIE_FILE")
  else
    fail "cookie file not found"
  fi
fi

if [ -n "$CSRF_TOKEN" ]; then
  curl_args+=(-H "X-CSRF-Token: $CSRF_TOKEN")
fi

curl_args+=(-H "Content-Type: application/json" -H "X-Requested-With: XMLHttpRequest")

probe_action() {
  local action="$1"
  local response_file="$tmp_dir/${action//./_}.json"
  local status_file="$tmp_dir/${action//./_}.status"
  local url="$BASE_URL/api/addons/installed/$ADDON_ID/bridge"

  set +e
  curl "${curl_args[@]}" \
    --request POST \
    --data "{\"action\":\"$action\"}" \
    --output "$response_file" \
    --write-out '%{http_code}' \
    "$url" >"$status_file" 2>"$tmp_dir/${action//./_}.err"
  local curl_status=$?
  set -e

  if [ "$curl_status" -ne 0 ]; then
    fail "$action curl request"
    sed 's/[[:cntrl:]]//g' "$tmp_dir/${action//./_}.err" | tail -20
    return
  fi

  local http_status
  http_status="$(cat "$status_file")"
  if [ "$http_status" != "200" ]; then
    fail "$action HTTP $http_status"
    python3 - "$response_file" <<'PY' || true
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
except Exception:
    print("response was not valid JSON")
    raise SystemExit(0)

if isinstance(data, dict):
    safe = {k: data.get(k) for k in ("error", "message", "ok") if k in data}
    print(json.dumps(safe, sort_keys=True))
else:
    print("response JSON was not an object")
PY
    return
  fi

  if python3 - "$action" "$response_file" <<'PY'
import json
import sys
from pathlib import Path

action = sys.argv[1]
path = Path(sys.argv[2])
data = json.loads(path.read_text())

if not isinstance(data, dict):
    raise SystemExit("response is not an object")
if data.get("ok") is not True:
    raise SystemExit("response ok flag is not true")
result = data.get("result")
if not isinstance(result, dict):
    raise SystemExit("result is not an object")

blocked_keys = {
    "rows",
    "rawrows",
    "raw",
    "sql",
    "query",
    "password",
    "secret",
    "token",
    "steamid",
    "steam_id",
    "accountid",
    "account_id",
    "playerid",
    "player_id",
    "characterid",
    "character_id",
    "charactername",
    "character_name",
    "coordinates",
    "location",
    "position",
    "x",
    "y",
    "z",
}

found = []

def walk(value, path="result"):
    if isinstance(value, dict):
        for key, child in value.items():
            normalized = str(key).replace("-", "_").lower()
            if normalized in blocked_keys:
                found.append(f"{path}.{key}")
            walk(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk(child, f"{path}[{index}]")

walk(result)
if found:
    raise SystemExit("blocked key(s) present: " + ", ".join(found[:10]))

if action in {"ops.health.summary", "ops.health.summary.v2"}:
    if not isinstance(result.get("players"), dict):
        raise SystemExit("summary players object missing")
    if not isinstance(result.get("farms"), dict):
        raise SystemExit("summary farms object missing")
elif action == "ops.health.players":
    if "total" not in result or not isinstance(result.get("onlineStatus"), dict):
        raise SystemExit("players aggregate shape missing")
elif action == "ops.health.farms":
    if "total" not in result or "ready" not in result or "alive" not in result:
        raise SystemExit("farms aggregate shape missing")
else:
    raise SystemExit("unexpected action")

print("PASS")
PY
  then
    pass "$action bridge response"
  else
    fail "$action bridge response"
  fi
}

if [ "$failures" -eq 0 ]; then
  probe_action "ops.health.summary"
  probe_action "ops.health.players"
  probe_action "ops.health.farms"
  probe_action "ops.health.summary.v2"
fi

if [ "$failures" -ne 0 ]; then
  echo "FAIL: Release 0.3 bridge probe ($failures failure(s))"
  exit 1
fi

echo "PASS: Release 0.3 bridge probe"
