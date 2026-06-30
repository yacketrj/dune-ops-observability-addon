# OPS Health Foundation

The OPS Health Foundation panel implements the first v0.3.0 roadmap target without expanding the permission boundary.

## Data boundary

The panel derives its values from the existing player summary read path.

It does not add:

- new permissions;
- new bridge actions;
- new upstream routes;
- retained history;
- exports;
- alerting;
- raw logs;
- database access.

## Panel fields

### Source Health

Reports whether the active provider is the Dune Docker Console bridge, preview sample data, or unavailable because the provider returned an error.

### Freshness

Reports whether the latest successful provider read is fresh or stale within the current browser session.

The current stale threshold is five minutes.

### Player Impact

Reports in-session changes to total player rows and online player rows between successful refreshes.

This value is not persisted.

### Operator Status

Summarizes the current operational state as healthy, stale, preview, or action needed.

## Release classification

This is a minor feature while it remains derived from the existing `players:read` data path.

Any future health metric that requires a new bridge action, new upstream route, retained history, alerting, raw logs, database access, or system health data requires a separate design review before implementation.
