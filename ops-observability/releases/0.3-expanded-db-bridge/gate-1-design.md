# Release 0.3 Gate 1 Design Summary

Status: complete
Release: `0.3-expanded-db-bridge`

## Goal

Finalize the design for the next OPS health aggregate surface before any Core implementation work starts.

## Selected Core Function Names

```text
addonOpsHealthPlayers(db)
addonOpsHealthFarms(db)
addonOpsHealthSummaryV2(db)
```

## Selected Action Names

```text
ops.health.players
ops.health.farms
ops.health.summary.v2
```

## Compatibility Rule

```text
ops.health.summary remains unchanged.
```

## Required Permission

```text
ops:read
```

## Response Groups

The schemas remain in `release-plan.md`.

Release 0.3 includes three response groups:

- player aggregate health;
- farm aggregate health;
- combined summary health.

## Empty Aggregate Behavior

When a required source is unavailable, implementation should return a zero-count aggregate response with the same shape as the normal response.

## Required Test Groups

- player aggregate tests;
- farm aggregate tests;
- combined summary tests;
- compatibility tests for the existing summary action;
- zero-count fallback tests;
- approved-field response tests.

## Implementation Boundary

Gate 1 is design-only. Core implementation belongs in a later Core PR.
