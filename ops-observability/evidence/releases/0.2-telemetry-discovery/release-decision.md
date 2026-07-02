# Release 0.2 Decision

Release: 0.2 Telemetry Discovery
Decision: Approved with limitations
Date: 2026-07-02T15:07:57-07:00
Evidence path: ~/dune-work/ops-observability/evidence/releases/0.2-telemetry-discovery
Postgres container: dune-postgres
Database: dune

## Result

The Release 0.2 container runner executed the approved safe aggregate SQL candidates against the local E2E Postgres container.

The safe SQL pattern scan passed.
The safe aggregate query execution passed.
The result privacy scan passed.

## Validated Safe Candidates

- Player status summary grouped by `online_status`, `life_state`, and `character_state`.
- Farm state aggregate summary using total farms, ready farms, alive farms, connected players, incoming S2S connections, and outgoing S2S connections.

## Observed Output

- Players: `Offline / Alive / Active = 1`.
- Farms: `total = 2`, `ready = 2`, `alive = 2`, `connected_players = 0`, `incoming_s2s_connections = 2`, `outgoing_s2s_connections = 2`.

## Limitations

- This approval applies only to `safe-query-candidates.sql`.
- Preserved SQL discovery scripts remain internal discovery inputs only.
- Economy, inventory, marker, map, event-log, JSON-key, guild, and Landsraad queries remain sensitive or unsafe until individually reviewed.
- This release does not approve additional upstream bridge actions.
- This release does not approve raw row exposure, identifiers, coordinates, secrets, logs, SQL text, or high-cardinality labels.

## Next Release

Release 0.3 may use this evidence to propose expanded aggregate DB bridge actions only after query-level review and E2E coverage are complete.
