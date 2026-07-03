# Release 0.3 Checklist — Expanded Aggregate DB Bridge

## Scope

- [x] Scope limited to player and farm aggregate health.
- [x] No additional telemetry categories in Gate 1.
- [x] No row-level response payloads in Gate 1.
- [x] Existing `ops.health.summary` compatibility preserved.

## Design

- [x] Core function names selected.
- [x] Bridge action names finalized.
- [x] Response schemas finalized in `release-plan.md`.
- [x] Missing-source fallback behavior defined.
- [x] Unit test groups listed.
- [x] E2E test groups listed.
- [x] Gate 1 design summary added.

## Gate 2 Preparation

- [x] Gate 2 plan added.
- [x] Core worktree validator added.
- [x] Release 0.3 validation runner added.
- [x] Core implementation boundary documented.
- [x] Core validation commands documented.

## Implementation

- [ ] `duneDb.addonOpsHealthPlayers` implemented.
- [ ] `duneDb.addonOpsHealthFarms` implemented.
- [ ] `duneDb.addonOpsHealthSummaryV2` implemented.
- [ ] `ops.health.players` bridge action implemented.
- [ ] `ops.health.farms` bridge action implemented.
- [ ] `ops.health.summary.v2` bridge action implemented or explicitly deferred.
- [ ] `ops:read` required for every action.

## Tests

- [ ] Unit tests cover players aggregate output.
- [ ] Unit tests cover farms aggregate output.
- [ ] Unit tests cover combined summary output.
- [ ] Unit tests cover missing player source.
- [ ] Unit tests cover missing farm source.
- [ ] Unit tests verify aggregate-only response shape.
- [ ] Gate behavior tests pass.

## Evidence

- [ ] Core PR gate output captured.
- [ ] API test output captured.
- [ ] E2E output captured.
- [ ] Privacy scan output captured.
- [ ] Evidence snapshot captured.
