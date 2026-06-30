# Release Testing: v0.2.0

## Required local validation

Run from the addon repository:

```bash
pre-commit run --all-files
node scripts/validate.js
bash scripts/package.sh
```

## Required Console sync

Before private testing, sync the local Dune Docker Console checkout:

```bash
cd /home/darkdante/dune-clean-repro
git fetch upstream --prune
git switch main
git reset --hard upstream/main
```

## Required private Console install

Copy the addon into the local Console install:

```bash
CONSOLE_DIR="/home/darkdante/dune-clean-repro"
ADDON_DIR="/home/darkdante/dune-ops-observability-addon"
ADDON_ID="dune-ops-observability"

rm -rf "$CONSOLE_DIR/runtime/addons/installed/$ADDON_ID"
mkdir -p "$CONSOLE_DIR/runtime/addons/installed/$ADDON_ID"
cp -a "$ADDON_DIR/addon.json" "$ADDON_DIR/web" "$CONSOLE_DIR/runtime/addons/installed/$ADDON_ID/"
```

Enable the addon and approve the requested read-only permission:

```bash
cd /home/darkdante/dune-clean-repro

python3 - <<'PY'
import json
from pathlib import Path

addon_id = "dune-ops-observability"
permissions = ["players:read"]

state_path = Path("runtime/addons/state.json")
state_path.parent.mkdir(parents=True, exist_ok=True)

try:
    state = json.loads(state_path.read_text())
except Exception:
    state = {}

state[addon_id] = {
    "enabled": True,
    "approvedPermissions": permissions
}

state_path.write_text(json.dumps(state, indent=2) + "\n")
print(json.dumps(state[addon_id], indent=2))
PY
```

## Required smoke checks

After refreshing Dune Docker Console, open Addons and verify:

- Dune Ops Observability appears as an installed addon.
- The addon opens in the Console iframe.
- The bridge-backed player summary loads or fails safely.
- A3 Player Summary renders.
- A4 KPI Capability renders.
- A5 read-only KPI panels render.
- No new permission beyond `players:read` is requested.
- No browser direct-localhost API calls are used.
- Empty and degraded data states are readable.

## Release asset verification

After the release workflow uploads the asset, download the release ZIP and verify the SHA-256 against the uploaded asset before opening an upstream catalog PR.
