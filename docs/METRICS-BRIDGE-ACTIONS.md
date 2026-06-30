# Metrics Bridge Actions

The addon currently has live access only to `leadership.players.list`.

Database-backed panels need read-only aggregate bridge actions before they can show live data.

Proposed action names:

- `ops.health.summary`
- `ops.resources.summary`
- `ops.location.summary`
- `ops.economy.summary`
- `ops.events.summary`

Required behavior:

- return aggregate summaries only;
- return no raw database rows;
- return no database credentials;
- fail safely when a source has no rows;
- fail safely when an action is not implemented;
- keep browser code behind the Console bridge.

Initial implementation target:

- implement `ops.health.summary` first;
- use it for v0.3.0;
- leave economy, location, resources, and events behind separate follow-up work.
