# Release 0.2 Source Artifacts

## Preserved SQL Inputs

The following preserved addon SQL scripts were identified and copied into the internal telemetry discovery workspace:

- `tools/discover-db-telemetry/sql/postgres-event-inventory.sql`
- `tools/discover-db-telemetry/sql/postgres-metric-discovery.sql`

## Original Source Paths

- `~/dune-work/e2e-ops-health.preserved-source-20260630-225833/runtime/addons/installed/dune-ops-observability/scripts/postgres-event-inventory.sql`
- `~/dune-work/e2e-ops-health.preserved-source-20260630-225833/runtime/addons/installed/dune-ops-observability/scripts/postgres-metric-discovery.sql`

## Review Requirement

These scripts are discovery inputs only.

Before any metric from these scripts is implemented in Core or addon UI, each query and output field must be classified as:

- safe aggregate
- sensitive aggregate
- unsafe raw data
- unknown
- not useful

## Security Rule

No query from these files may be promoted to bridge telemetry if it exposes raw rows, player identifiers, account identifiers, character names, actor IDs, coordinates, raw payloads, SQL text, tokens, passwords, secrets, or high-cardinality labels.
