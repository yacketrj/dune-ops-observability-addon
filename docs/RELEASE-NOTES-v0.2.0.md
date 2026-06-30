# Release Notes: v0.2.0

## Summary

v0.2.0 is the public player-operations release train.

It bundles the A3, A4, and A5 roadmap work after the addon became publicly listed through the community addon catalog.

## Added

- A3 Player Summary MVP.
- A4 KPI Capability panel.
- A5 read-only KPI panels.
- SOC / OPS metric roadmap.
- Release cadence policy.
- Private Dune Docker Console testing requirement.

## KPI panels

The first read-only panels are derived from player summary data only:

- active rate;
- average level;
- top faction;
- top guild.

## Security and permissions

No permission change.

```json
{
  "players": ["read"]
}
```

## Public release boundary

This release does not add:

- new bridge actions;
- new upstream routes;
- write access;
- database access;
- raw logs;
- exports;
- webhooks;
- persistent history;
- economy data;
- inventory data.

## Testing requirement

Before tagging, validate locally and test privately through Dune Docker Console at:

```text
/home/darkdante/dune-clean-repro
```

The private Console test must use the real Console iframe bridge and does not require the community addon index.
