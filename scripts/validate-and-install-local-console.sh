#!/usr/bin/env bash
set -euo pipefail

ADDON_REPO="${ADDON_REPO:-/home/darkdante/dune-ops-observability-addon}"
CONSOLE_DIR="${CONSOLE_DIR:-/home/darkdante/dune-clean-repro}"
ADDON_ID="${ADDON_ID:-dune-ops-observability}"

printf 'Addon repository: %s\n' "$ADDON_REPO"
printf 'Console repository: %s\n' "$CONSOLE_DIR"
printf 'Addon id: %s\n' "$ADDON_ID"

if [[ ! -d "$ADDON_REPO" ]]; then
  printf 'Addon repository does not exist: %s\n' "$ADDON_REPO" >&2
  exit 1
fi

if [[ ! -d "$CONSOLE_DIR" ]]; then
  printf 'Console repository does not exist: %s\n' "$CONSOLE_DIR" >&2
  exit 1
fi

printf '\n[1/5] Synchronizing addon repository with origin/main...\n'
cd "$ADDON_REPO"
git fetch origin --prune
git switch main
git pull --ff-only origin main

ADDON_VERSION="$(node -e "process.stdout.write(require('./addon.json').version)")"
EXPECTED_HEADER="Dune Ops Observability r$ADDON_VERSION"

printf '\n[2/5] Running addon validation checks...\n'
pre-commit run --all-files
node scripts/validate.js
bash scripts/package.sh

printf '\n[3/5] Synchronizing local Console repository with upstream/main...\n'
cd "$CONSOLE_DIR"
git fetch upstream --prune
git switch main
git pull --ff-only upstream main

printf '\n[4/5] Copying addon files into local Console runtime...\n'
INSTALL_DIR="$CONSOLE_DIR/runtime/addons/installed/$ADDON_ID"
mkdir -p "$INSTALL_DIR"
cp -a "$ADDON_REPO/addon.json" "$INSTALL_DIR/addon.json"
cp -a "$ADDON_REPO/web" "$INSTALL_DIR/"

printf '\n[5/5] Enabling addon in local Console state...\n'
python3 - "$CONSOLE_DIR/runtime/addons/state.json" "$ADDON_ID" <<'PY'
from pathlib import Path
import json
import sys

state_path = Path(sys.argv[1])
addon_id = sys.argv[2]

state_path.parent.mkdir(parents=True, exist_ok=True)

try:
    state = json.loads(state_path.read_text())
except Exception:
    state = {}

state[addon_id] = {
    "enabled": True,
    "approvedPermissions": ["ops:read"],
}

state_path.write_text(json.dumps(state, indent=2) + "\n")
print(json.dumps(state[addon_id], indent=2))
PY

printf '\nLocal Console install is complete.\n'
printf 'Refresh Dune Docker Console, open Addons, launch Dune Ops Observability, and verify the header displays: %s\n' "$EXPECTED_HEADER"
