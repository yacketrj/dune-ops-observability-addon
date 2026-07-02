# Release 0.3 Checklist — Expanded Aggregate DB Bridge

## Scope

- [ ] Scope limited to player and farm aggregate health.
- [ ] No economy metrics.
- [ ] No inventory metrics.
- [ ] No event-log metrics.
- [ ] No marker/map/location metrics.
- [ ] No guild/Landsraad metrics.
- [ ] No raw identifiers.
- [ ] No coordinates.
- [ ] No raw rows.

## Implementation

- [ ] `duneDb.addonOpsHealthPlayers` implemented.
- [ ] `duneDb.addonOpsHealthFarms` implemented.
- [ ] `ops.health.players` bridge action implemented.
- [ ] `ops.health.farms` bridge action implemented.
- [ ] `ops.health.summary.v2` bridge action implemented or explicitly deferred.
- [ ] `ops:read` required for every action.

## Tests

- [ ] Unit tests cover players aggregate output.
- [ ] Unit tests cover farms aggregate output.
- [ ] Unit tests cover missing `player_state`.
- [ ] Unit tests cover missing `farm_state`.
- [ ] Unit tests verify no raw identifiers.
- [ ] Unit tests verify no row-level farm IDs/maps.
- [ ] Unauthorized bridge tests pass.

## Evidence

- [ ] Core PR gate output captured.
- [ ] API test output captured.
- [ ] E2E output captured.
- [ ] Privacy scan output captured.
- [ ] Evidence snapshot captured.
