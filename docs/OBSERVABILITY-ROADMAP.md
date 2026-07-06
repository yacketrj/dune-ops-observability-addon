# Observability Roadmap

> See also: [ROADMAP.md](ROADMAP.md) — unified overview, dependency graph, tagging convention, full release table
> Related: [SOC-OPS-ROADMAP.md](SOC-OPS-ROADMAP.md) — P0/P1/P2 metric taxonomy, Core R2–R5 releases
> Related: [release-standard.md](../ops-observability/roadmap/release-standard.md) — 5-gate release process

This roadmap expands Dune Ops Observability beyond the initial player-operations release train.

It combines three tracks:

1. SOC / OPS monitoring.
2. Game telemetry and LiveOps analytics.
3. PostgreSQL-backed database event discovery.

The roadmap is evidence-driven. Metrics must be tied to an available data source before implementation.

**Note**: This roadmap groups the originally planned v0.4–v0.9 releases into three combined releases (see [Decision Log](ROADMAP.md#9-decision-log)). v0.4.0 merges the former v0.4 Player Activity + v0.5 Combat into "Game Activity & Combat". v0.5.0 merges v0.6 Resources + v0.7 Economy into "Economy & Resources". v0.6.0 merges v0.8 Inventory/Crafting + v0.9 Location/Territory into "World & Assets".

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

### v0.4.0 Game Activity & Combat

> Merges: former v0.4.0 Player Activity Foundation + v0.5.0 Combat and Death Analytics

Purpose: deliver read-only player activity analytics and combat summaries in one release, enabled by Core R2 (Grafana + Alertmanager for operator visibility).

**Core dependency**: Core R2 (Console Exporter + SOC Foundation) — enables Grafana-based operator dashboards and Alertmanager notification pipeline while v0.4 panels are being used. v0.4 does NOT require the Prometheus bridge (R3) or Redis (R4).

**Player activity** — Candidate metrics:

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

**Combat** — Candidate metrics:

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

Release class:

- minor if still derived from existing approved player read source;
- major if new database route, new bridge action, retained history, or expanded permission is required.

Security boundary:

- aggregate first;
- avoid public exposure of individual player targeting unless explicitly approved;
- no raw combat log export in public addon release.

### v0.5.0 NOC Dashboard (Phase 1)

> New release — AAA game infrastructure NOC wallboard

Purpose: deliver a production-quality NOC (Network Operations Center) dashboard using existing data sources. Phase 1 uses only R1 infrastructure and existing bridge actions. Phase 2 enrichment (live Prometheus metrics, Grafana, Alertmanager) is deferred to v1.0.0 after Core R2+R3.

**Core dependency**: None. Works with existing R1 infrastructure. Core R2 (Grafana + Alertmanager) enriches the panel in v1.0.0 Phase 2.

Metrics derived from the [AAA NOC Dashboard standard](ROADMAP.md#3-industry-standards-mapping) (AWS GameLift reference):

**Service health map** — Candidate metrics:

- Postgres up/down (from `dune ready` container checks);
- RabbitMQ admin + game up/down (from `dune ready` container checks);
- Director up/down + heartbeat status (from `dune ready` container checks);
- Gateway up/down + monitoring DB status (from `dune ready` container checks);
- Survival_1 up/down + ready state (from `dune ready` game server checks);
- Overmap up/down + ready state (from `dune ready` game server checks);
- TextRouter up/down (from `dune ready` container checks);
- Container restart counts (from Docker container inspection);
- Service dependency chain status (Docker → Postgres → RabbitMQ → Director → Game Servers).

Data source: `dune ready` CLI output via Console API, Docker container inspection.

**Player CCU** — Candidate metrics:

- Concurrent users from `leadership.players.list` bridge action;
- Online/offline player split;
- Player count trend (current vs last refresh).

Data source: existing `leadership.players.list` bridge action (`players:read`).

**Resource snapshot** — Candidate metrics:

- CPU % (from `/api/server/performance`);
- Memory used/total/% (from `/api/server/performance`);
- Disk used/total/% (from `/api/server/performance`);
- Host uptime (from `/proc/uptime` via `/api/server/performance`).

Data source: existing `/api/server/performance` endpoint (reads `/proc` directly).

**OPS health** — Candidate metrics:

- Bridge freshness (last successful read timestamp);
- Data staleness warning (> 5 min since last read);
- Source health (bridge/sample/unavailable mode);
- Operator status summary (healthy/stale/preview).

Data source: existing `ops.health.summary` bridge action (`ops:read`) — from v0.3.0.

**Deployment health** — Candidate metrics:

- Container uptime (from Docker container inspection);
- Orchestrator status (from `dune status`);
- World partition count (from database);
- DB health (connections, size — from `ops.health.farms`/`ops.health.players`).

Data source: Docker CLI + existing bridge actions.

**Alert reference** — Candidate metrics:

- 16 Prometheus alert rules listed as text reference (no live state until Core R2);
- Alerts grouped by category: Host (6), Containers (4), Postgres (6), RabbitMQ (6);
- Placeholder for Core R2 Alertmanager integration.

Data source: Read-only alert rule definitions from `runtime/metrics/rules/`.

Release class:
- minor (uses existing permissions and bridge actions — no new Core infrastructure).

Boundary:
- no new permission;
- no new bridge action;
- no upstream route;
- no retained history;
- no Core R2/R3/R4 dependency;
- Phase 2 enrichment deferred to v1.0.0.

### v0.6.0 Economy & Resources

> Merges: former v0.6.0 Resource and Gathering Analytics + v0.7.0 Economy and Trade Analytics

Purpose: provide read-only resource flow and economy health analytics. Economy data is classified as **sensitive** per the metric classification standard and requires explicit design review.

**Resources** — Candidate metrics:

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

**Economy** — Candidate metrics:

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
- individual player financial records should not be exposed without approval;
- aggregate by resource type before exposing player-level contribution;
- avoid leaking base locations or hidden stockpiles without design approval.

Release class: major (economy data, new database routes).

### v0.7.0 World & Assets

> Merges: former v0.8.0 Inventory, Crafting, and Storage Analytics + v0.9.0 Location, Territory, and Base Activity

Purpose: summarize item creation, storage pressure, world activity, and operational hot spots. Storage and location data are classified as **sensitive**; coarse rollups only (map/zone, no coordinates).

**Inventory, Crafting & Storage** — Candidate metrics:

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

**Location, Territory & Base Activity** — Candidate metrics:

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

- storage and inventory data are sensitive; aggregate first;
- avoid exposing exact stockpiles, base contents, or ownership records without design approval;
- avoid exposing exact player positions, hidden bases, or operationally sensitive locations;
- prefer coarse map or zone rollups.

Release class: major (location data, storage data, new database routes).

### v1.0.0 SOC / OPS Operations Center

Purpose: graduate from addon panel to operator command surface with platform health, bridge monitoring, and operator tooling.

**Core dependencies**: Requires Core R3 (Prometheus Bridge API) for `metrics.query` bridge action and Core R4 (SOC Hardening) for persistent rate limits + per-addon CSP. Cannot ship before R3+R4 are deployed.

Candidate metrics:

- platform health summary (Console API uptime via Prometheus);
- bridge request success and failure rate;
- API latency p50/p95/p99 (from Core R3 `/api/server/metrics`);
- database size and growth (from Core R3 bridge);
- database connection health (from Core R3 bridge);
- Prometheus metrics display: CPU, memory, disk saturation (from Core R3 `metrics.query`);
- addon permission drift (versus declared permissions);
- manifest checksum drift (versus catalog);
- configuration drift (versus baseline);
- Alertmanager events (if exposed via Core R4 receiver);
- persistent rate limit statistics (from Core R4 Redis backend);
- degraded data sources;
- stale metrics warnings;
- operator runbook links;
- incident notes or external references.

Required upstream support:

- Core R3: `metrics.query` bridge action, `/api/server/metrics` endpoint, structured logging;
- Core R4: Redis-backed persistent rate limits, per-addon CSP sandbox, proxy-aware IP detection;
- design review required before implementation.

## Database discovery phase

Before versions v0.4.0 through v0.6.0, run the PostgreSQL event inventory procedure.

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
   - **Current answer**: Use `database.query` for discovery; promote to dedicated bridge actions only for production dashboard paths.
2. Whether database-backed metrics should be exposed through upstream Console bridge actions instead.
   - **Current answer**: Bridge-mediated access remains the default. New bridge actions require Core PR + design review.
3. Which metrics are safe for public catalog users versus private/self-hosted operators only.
   - **Current answer**: All addon public releases use aggregate-only data. No player-level economy/death/resource records in public dashboards.
4. Whether player-level economy, death, and resource records should ever be displayed, or only aggregates.
   - **Current answer**: Aggregate-only for public releases. Player-level display requires explicit design approval.
5. Retention policy for any derived history.
   - **Current answer**: No retained history without design PR (hard line per SOC-OPS-ROADMAP.md).
6. Release grouping for game telemetry (v0.4–v0.6).
   - **Resolved (2026-07-04)**: Combined into 3 releases: v0.4 = Activity+Combat, v0.5 = Economy+Resources, v0.6 = World+Assets.
7. Grafana and Alertmanager deployment model.
   - **Resolved (2026-07-04)**: Grafana always-on when addon is running. Alertmanager supports email + webhook.
8. Persistent rate limiting backend.
   - **Resolved (2026-07-04)**: Redis (container dependency, internal network only).
9. v1.0.0 timing relative to Core releases.
   - **Resolved (2026-07-04)**: v1.0.0 must wait for Core R3+R4 to deploy.

## Document references

- [ROADMAP.md](ROADMAP.md) — unified overview, dependency graph, tagging convention
- [SOC-OPS-ROADMAP.md](SOC-OPS-ROADMAP.md) — P0/P1/P2 metric taxonomy, Core R2–R5 releases
- [RFC.md](RFC.md) — formal RFC for the comprehensive roadmap
- [DATABASE-EVENT-INVENTORY.md](DATABASE-EVENT-INVENTORY.md) — PostgreSQL event inventory procedure
- [METRIC-DISCOVERY-FINDINGS.md](METRIC-DISCOVERY-FINDINGS.md) — results from first aggregate discovery run
- [METRICS-BRIDGE-ACTIONS.md](METRICS-BRIDGE-ACTIONS.md) — proposed bridge action names and behavior
- [release-standard.md](../ops-observability/roadmap/release-standard.md) — 5-gate release process
- [metric-classification-standard.md](../ops-observability/roadmap/metric-classification-standard.md) — metric classification rules
