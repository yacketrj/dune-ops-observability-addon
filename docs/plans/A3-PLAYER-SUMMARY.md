# A3 Player Summary Panel

Issue: #4

## Goal

Add a read-only player summary panel using the existing addon data provider boundary.

## Implemented

- Reads player summary data from the active provider.
- Uses `sample` provider for direct browser preview.
- Uses `bridge` provider when loaded inside Dune Docker Console.
- Renders summary totals:
  - total players;
  - online players;
  - offline or non-online players;
  - distinct known factions.
- Renders player table columns:
  - player;
  - level;
  - faction;
  - guild;
  - status;
  - map/location;
  - last seen.
- Handles empty provider responses.
- Handles provider errors without mutating data.
- Keeps diagnostics visible for review and bridge troubleshooting.

## Out of scope

- Player mutation.
- Write permissions.
- Direct localhost/browser API calls.
- New upstream/core routes.
- KPI/database panels.

## Permissions

No permission change.

```json
{
  "players": ["read"]
}
```

## Validation

```bash
node scripts/validate.js
pre-commit run --all-files
bash scripts/package.sh
```
