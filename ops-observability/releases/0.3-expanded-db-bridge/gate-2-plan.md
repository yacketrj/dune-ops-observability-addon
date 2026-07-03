# Release 0.3 Gate 2 Plan

Status: planning scaffold
Release: `0.3-expanded-db-bridge`

## Goal

Prepare the implementation path for Release 0.3 without changing Core code in this addon-repository PR.

## Scope

Gate 2 implementation is expected to happen in the Core repository. This addon PR only adds planning and validation scaffolding.

## Expected Core Files

```text
console/api/src/duneDb.js
console/api/src/server.js
console/api/test/db.test.js
```

## Expected Core Functions

```text
addonOpsHealthPlayers(db)
addonOpsHealthFarms(db)
addonOpsHealthSummaryV2(db)
```

## Expected Action Names

```text
ops.health.players
ops.health.farms
ops.health.summary.v2
```

## Compatibility Constraint

```text
ops.health.summary remains unchanged.
```

## Local Validation Helpers

The addon repository now provides read-only helpers for future Core work:

```text
ops-observability/dev-tools/validate-core-ops-health-worktree.sh
ops-observability/dev-tools/run-ops-health-03-validation.sh
```

## Gate 2 Entry Conditions

Before Core implementation begins:

- addon `main` is current;
- Core worktree exists;
- Core worktree is on the expected feature branch;
- Core worktree is clean;
- baseline summary action is present;
- baseline OPS permission reference is present.

## Gate 2 Exit Conditions

Gate 2 is complete only after a later Core PR includes:

- selected functions implemented;
- selected actions implemented;
- permission gate enforced;
- tests added;
- changed-file scope reviewed;
- validation runner passes.

## Commands

From the addon repository:

```bash
bash ops-observability/dev-tools/validate-core-ops-health-worktree.sh
bash ops-observability/dev-tools/run-ops-health-03-validation.sh
```

Both scripts are read-only with respect to the Core worktree.
