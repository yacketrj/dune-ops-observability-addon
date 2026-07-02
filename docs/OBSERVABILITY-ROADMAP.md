# Observability Roadmap

This roadmap expands Dune Ops Observability beyond the initial player-operations release train.

It combines three tracks:

1. SOC / OPS monitoring.
2. Game telemetry and LiveOps analytics.
3. PostgreSQL-backed database event discovery.

The roadmap is evidence-driven. Metrics must be tied to an available data source before implementation.

## Principles

- Prefer read-only metrics.
- Prefer derived summaries before raw records.
- Do not expose secrets, tokens, private player data, raw logs, or unrestricted database views.
- Treat new permissions, new bridge actions, new upstream routes, retained history, exports, alerting, raw logs, economy data, inventory data, and database access as design-review items.
- Use PostgreSQL inventory results before implementing database-backed game telemetry.
- Keep public catalog releases batched by release train.

## Industry baseline

Production service monitoring should include latency, traffic, errors, and saturation where the platform exposes those signals.

Game telemetry should track player behavior and game activity through schema-governed events. Typical event families include session lifecycle, player activity, progression, economy, combat, resources, inventory, location, and retention.

## Current public baseline

### v0.2.x Player Operations

Implemented or staged baseline:

- A3 Player Summary.
- A4 KPI Capability.
- A5 Read-only KPI Panels.
- Release asset checksum verification.
- Private Console validation procedure.

Boundary:

- Uses `players:read`.
- No database access.
- No raw logs.
- No write permissions.
- No retained history.

## Near-term roadmap

### v0.3.0 OPS Health Foundation

Purpose: prove that the addon can report operator health from the existing player summary read path.

Metrics:

- source health;
- bridge/source mode;
- last successful read;
- data freshness;
- stale-read warning;
- in-session player-impact delta;
- operator status summary.

Data source:

- existing player summary provider.

Release class:

- minor while derived from `players:read`.

Boundary:

- no new permission;
- no new bridge action;
- no upstream route;
- no retained history.

### v0.4.0 Player Activity Foundation

Purpose: expand read-only player activity analytics if the source data is available.

Candidate metrics:

- active players by interval;
- online/offline transitions;
- session count;
- session duration;
- last seen distribution;
- returning players;
- new players;
- guild activity;
- faction activity;
- location or map activity;
- inactive player aging.

Required database review:

- player tables;
- session tables;
- activity or event tables;
- last seen fields;
- timestamp coverage;
- retention period.

Release class:

- minor if still derived from existing approved player read source;
- major if new database route, new bridge action, retained history, or expanded permission is required.

### v0.5.0 Combat and Death Analytics

Purpose: summarize combat outcomes and dangerous areas if the database stores combat events.

Candidate metrics:

- player deaths by interval;
- player deaths by location;
- player deaths by cause;
- player versus player deaths;
- player versus environment deaths;
- NPC deaths by interval;
- most frequently killed NPC types;
- NPC kill locations;
- kill/death ratio by aggregate cohort;
- death spike detection;
- repeated death loops;
- top hostile NPCs by player impact.

Required database review:

- death or kill event tables;
- NPC identifier fields;
- attacker and victim fields;
- location fields;
- weapon or damage source fields;
- timestamp fields.

Security boundary:

- aggregate first;
- avoid public exposure of individual player targeting unless explicitly approved;
- no raw combat log export in public addon release.

### v0.6.0 Resource and Gathering Analytics

Purpose: summarize gathering and resource flows if the database stores collection events.

Candidate metrics:

- ore gathered by type;
- spice sand gathered;
- flour sand gathered;
- fiber gathered;
- resource quantities by type;
- resource collection by location;
- resource collection by interval;
- top gathered resources;
- gathering spikes;
- resource scarcity indicators;
- player or guild contribution summaries;
- resource source quality warnings.

Required database review:

- resource item tables;
- inventory transaction tables;
- gather event tables;
- item definition tables;
- quantity or amount fields;
- location and timestamp fields.

Security boundary:

- aggregate by resource type before exposing player-level contribution;
- avoid leaking base locations or hidden stockpiles without design approval.

### v0.7.0 Economy and Trade Analytics

Purpose: summarize economy health if the database stores transactions.

Candidate metrics:

- currency flow in and out;
- solari balance movement;
- market transaction count;
- market volume by item;
- average item price;
- top traded items;
- tax or fee totals;
- wealth concentration by aggregate cohort;
- inflation indicators;
- suspicious economy spikes;
- failed or rolled-back transactions.

Required database review:

- wallet tables;
- market tables;
- exchange tables;
- trade transaction tables;
- currency fields;
- price and quantity fields;
- timestamp fields;
- account or player references.

Security boundary:

- economy metrics require explicit design review;
- public dashboards should use aggregate values by default;
- individual player financial records should not be exposed without approval.

### v0.8.0 Inventory, Crafting, and Storage Analytics

Purpose: summarize item creation, movement, and storage if available.

Candidate metrics:

- crafted item count by type;
- crafting failures;
- item sink and source rates;
- inventory movement count;
- storage usage by category;
- container count;
- high-value item movement aggregates;
- base storage pressure;
- abandoned assets;
- resource-to-crafted-item conversion.

Required database review:

- inventory tables;
- storage tables;
- item definition tables;
- crafting tables;
- base or container tables;
- owner reference fields;
- timestamp fields.

Security boundary:

- storage and inventory data are sensitive;
- aggregate first;
- avoid exposing exact stockpiles, base contents, or ownership records without design approval.

### v0.9.0 Location, Territory, and Base Activity

Purpose: summarize world activity and operational hot spots if location fields are available.

Candidate metrics:

- active players by map, zone, or server;
- death hot spots;
- gathering hot spots;
- NPC kill hot spots;
- base activity counts;
- territory pressure;
- travel activity;
- underused areas;
- contested areas;
- activity heat map summaries.

Required database review:

- map or zone fields;
- world position fields;
- base tables;
- territory tables;
- activity events with coordinates or named locations.

Security boundary:

- avoid exposing exact player positions, hidden bases, or operationally sensitive locations;
- prefer coarse map or zone rollups.

### v1.0.0 SOC / OPS Operations Center

Purpose: graduate from addon panel to operator command surface.

Candidate metrics:

- platform health summary;
- bridge request success and failure rate;
- API latency if exposed by upstream;
- database size and growth if approved;
- database connection health if approved;
- addon permission drift;
- manifest checksum drift;
- configuration drift;
- degraded data sources;
- stale metrics;
- operator runbook links;
- incident notes or external references.

Required upstream support:

- likely requires new bridge actions or API routes;
- likely requires design review before implementation.

## Database discovery phase

Before versions `0.4.0` through `0.9.0`, run the PostgreSQL event inventory procedure.

Required output:

- available tables and views;
- candidate event tables;
- candidate event columns;
- timestamp coverage;
- row counts;
- retention windows;
- safe aggregation strategy;
- unavailable metrics requiring upstream support.

Reference:

- `docs/DATABASE-EVENT-INVENTORY.md`

## Metric categories to inventory

### Player

- player identity key;
- display name fields;
- account identifiers;
- guild and faction fields;
- level and progression fields;
- online status;
- last seen;
- session start and end;
- login and logout events.

### Combat

- player deaths;
- NPC deaths;
- attacker and victim references;
- damage source;
- weapon or ability;
- location;
- timestamp;
- PvP or PvE classification.

### NPC

- NPC type;
- NPC faction;
- spawn area;
- killed count;
- kill timestamp;
- most killed NPCs;
- NPCs causing most player deaths.

### Resources

- resource type;
- quantity;
- gathering source;
- gatherer reference;
- location;
- timestamp;
- ore type;
- spice sand;
- flour sand;
- fiber;
- other collectible resources discovered in the database.

### Economy

- currency amount;
- transaction type;
- buyer and seller references;
- item type;
- quantity;
- price;
- tax or fee;
- market identifier;
- timestamp.

### Inventory and crafting

- item type;
- item count;
- crafted item;
- consumed resources;
- storage location;
- container reference;
- owner reference;
- movement timestamp.

### Location and territory

- map;
- zone;
- coordinates if available;
- base reference;
- territory reference;
- activity type;
- timestamp.

## Release rules

- A metric may enter a release only after its data source is documented.
- Metrics using only existing approved read-only data may be minor releases.
- Metrics requiring new bridge actions, new upstream routes, retained history, economy data, inventory data, raw logs, or database access require design review.
- Public releases must pass private Console testing.
- Upstream catalog PRs must use verified release asset checksums.

## Open decisions

1. Whether the addon should ever read PostgreSQL directly.
2. Whether database-backed metrics should be exposed through upstream Console bridge actions instead.
3. Which metrics are safe for public catalog users versus private/self-hosted operators only.
4. Whether player-level economy, death, and resource records should ever be displayed, or only aggregates.
5. Retention policy for any derived history.
