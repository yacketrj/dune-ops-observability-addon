# Local Console Test Install

Use this procedure to prepare the addon for private Dune Docker Console testing before a release tag or upstream catalog submission.

## Standard command

Run from any directory:

```bash
bash /home/darkdante/dune-ops-observability-addon/scripts/validate-and-install-local-console.sh
```

## What the script does

The script performs the following steps in order:

1. Synchronizes the addon repository with `origin/main`.
2. Runs local validation checks.
3. Builds the release package.
4. Synchronizes the local Dune Docker Console checkout with `upstream/main`.
5. Copies `addon.json` and `web/` into the local Console runtime addon directory.
6. Enables the addon in `runtime/addons/state.json` with the approved read-only permission.

The install step runs only after validation and packaging complete successfully.

## Default paths

```text
Addon repository: /home/darkdante/dune-ops-observability-addon
Console repository: /home/darkdante/dune-clean-repro
Addon id: dune-ops-observability
```

The paths can be overridden by setting environment variables before running the script:

```bash
ADDON_REPO="/path/to/addon" \
CONSOLE_DIR="/path/to/console" \
ADDON_ID="dune-ops-observability" \
bash scripts/validate-and-install-local-console.sh
```

## Required manual verification

After the script completes, refresh Dune Docker Console, open Addons, and launch Dune Ops Observability.

Verify that:

- the addon opens inside the Console iframe;
- the WebUI header displays the release label printed by the install script;
- the OPS Health Foundation panel reports source health, freshness, player impact, and operator status;
- player summary data loads or fails safely;
- A3 Player Summary renders;
- A4 KPI Capability renders;
- A5 read-only KPI panels render;
- no permission beyond `players:read` is requested.

This private Console verification remains a release gate and must be documented before opening an upstream catalog PR.
