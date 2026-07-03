# PR: Release 0.3 Gate 3 Live

Status: Complete
Branch: `release-0-3-bridge-probe`
Base: `main`
Release: `0.3-expanded-db-bridge`

## Summary

Added tooling for the Gate 3 local live validation step and completed follow-up WebUI wiring needed for a true browser-facing E2E check.

## Backend Bridge Validation

The local authenticated bridge probe passed against the Dune Docker Console API using:

```text
ops-observability/dev-tools/run-ops-health-03-bridge-probe.sh
```

Validated bridge actions:

```text
ops.health.summary
ops.health.players
ops.health.farms
ops.health.summary.v2
```

## WebUI E2E Validation

Initial backend bridge validation did not prove full release-candidate E2E because the visible addon UI still consumed `leadership.players.list`.

Follow-up Addon PR #41 corrected the WebUI provider and rendering layer so the browser-facing addon now consumes Release 0.3 `ops.health.*` actions and renders OPS aggregate cards/table data.

Local Console iframe E2E passed per operator report after staging Addon PR #41.

Expected visible WebUI surface:

```text
Dune Ops Observability r0.3.0
Refresh OPS health
Players
Online
Offline
Farm Sites
OPS Health Aggregate
Provider: Dune Docker Console OPS health bridge
```

## Result

Gate 3 is complete for local Release 0.3 validation.
