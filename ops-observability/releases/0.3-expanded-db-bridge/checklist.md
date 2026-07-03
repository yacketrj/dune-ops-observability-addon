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

- [x] `duneDb.addonOpsHealthPlayers` implemented.
- [x] `duneDb.addonOpsHealthFarms` implemented.
- [x] `duneDb.addonOpsHealthSummary` implemented.
- [x] `duneDb.addonOpsHealthSummaryV2` implemented.
- [x] `ops.health.summary` bridge action implemented.
- [x] `ops.health.players` bridge action implemented.
- [x] `ops.health.farms` bridge action implemented.
- [x] `ops.health.summary.v2` bridge action implemented.
- [x] `ops:read` required for every action.

## Tests

- [x] Unit tests cover players aggregate output.
- [x] Unit tests cover farms aggregate output.
- [x] Unit tests cover combined summary output.
- [x] Unit tests cover missing player source.
- [x] Unit tests cover missing farm source.
- [x] Unit tests verify aggregate-only response shape.
- [x] Gate behavior tests pass for implemented bridge functions.

## Evidence

- [x] Core PR implementation captured.
- [x] API test output reported by operator.
- [x] Static validation output captured.
- [x] Security gate output captured.
- [ ] Local bridge E2E output captured.
- [ ] Public-origin bridge E2E output captured if applicable.
- [ ] Evidence snapshot captured.
