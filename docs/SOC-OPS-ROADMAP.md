# SOC / OPS Metric Roadmap

> See also: [ROADMAP.md](ROADMAP.md) — unified overview, dependency graph, tagging convention
> Related: [release-standard.md](../ops-observability/roadmap/release-standard.md) — 5-gate release process
> Related: [metric-classification-standard.md](../ops-observability/roadmap/metric-classification-standard.md) — metric classification rules

## Context

Dune Ops Observability is now publicly listed through the community addon catalog. Public availability changes the roadmap standard.

New metrics must be evaluated by operator value and by public-release risk.

This document covers the SOC/OPS monitoring track. The companion [OBSERVABILITY-ROADMAP.md](OBSERVABILITY-ROADMAP.md) covers game telemetry and the addon release train. Both tracks depend on Core infrastructure releases (R1–R5) defined in [ROADMAP.md](ROADMAP.md).

## Release taxonomy

### Minor feature

A metric is minor when it uses data already available to the addon and does not expand the trust boundary.

Examples:

- derived player summary panels;
- read-only filters and sorting;
- source labels;
- empty states;
- capability labels;
- documentation.

### Major feature

A metric is major when it adds a new class of visibility or expands the trust boundary.

Examples:

- new permission;
- new bridge action;
- new upstream route;
- retained history;
- exports;
- alerting;
- raw logs;
- admin audit views;
- economy, storage, or inventory data.

### Patch

A patch is limited to bug fixes, package fixes, manifest fixes, security fixes, documentation corrections, and safe UI corrections.

## P0 critical metrics

P0 metrics help operators detect service impact, data freshness failure, or runtime degradation.

| Area | Metrics | Release class | Core Dep |
| --- | --- | --- | --- |
| Addon and bridge health | bridge available, bridge errors, last successful read, data age | minor if derived; major if new bridge action | — |
| Player availability | online players, offline players, active rate, sudden drop, last seen staleness | minor if derived from `players:read` | — |
| Console and API reliability | request errors, latency, timeouts | major | R2 (RED metrics) |
| Capacity and saturation | CPU, memory, disk, database size, container health | major | R2 (Grafana dashboards) |
| Service lifecycle | up, down, restart count, degraded state | major | R2 (Alertmanager notifications) |
| Data freshness | stale payload warning, missing fields, source quality | minor if derived; major if new source | — |
| **Grafana availability** | Grafana up/down, dashboard provisioning health, datasource connectivity | major | R2 |
| **Alertmanager pipeline** | alert routing health, notification delivery, silenced alert count | major | R2 |
| **Metrics bridge API** | `metrics.query` availability, Prometheus connectivity, query rejection rate | major | R3 |

**Sources**: `host.yml` (6 CPU/mem/disk/fs alerts), `containers.yml` (4 container alerts), `postgres.yml` (6 DB alerts), `rabbitmq.yml` (6 broker alerts), `ADDON-METRICS-SUPPORT:106-114` (target health)

## P1 security metrics

P1 metrics are security-sensitive and should get explicit design review before implementation.

| Area | Metrics | Release class | Core Dep |
| --- | --- | --- | --- |
| Admin activity | admin commands, privilege changes, config changes | major | — |
| Access failures | failed auth, denied addon requests, permission failures | major | R4 (persistent rate limits) |
| Addon integrity | manifest drift, checksum drift, permission drift | minor for this addon; major for cross-addon scans | — |
| Abuse signals | repeated joins/leaves, suspicious churn, ban/kick trends | major | R4 (proxy-aware IP) |
| Permission posture | requested versus approved permissions | minor for this addon; major for global monitoring | — |
| **Rate limit persistence** | bucket state across restarts, aggregate abuse trends, source IP rotation detection | major | R4 (Redis backend) |
| **Proxy-aware IP detection** | `X-Forwarded-For` support, trusted proxy CIDR, spoofed header detection | major | R4 |
| **Per-addon CSP enforcement** | CSP violations, blocked outbound requests, iframe sandbox events | major | R4 |
| **Authentication pattern analysis** | brute force attempts, session hijacking indicators, anomalous token use | major | R4 (with persistent storage) |

**Sources**: `login-rate-limit-defense.md:1-25` (per-client + global aggregate design), `rateLimit.js` (current in-memory implementation), `addon-provenance.md` (provenance tracking)

## P2 operational analytics

P2 metrics are useful but should not displace P0 health and P1 security work.

| Area | Metrics | Release class | Core Dep |
| --- | --- | --- | --- |
| Faction and guild | faction share, guild share, top faction, top guild | minor if derived from player summary | — |
| Progression | level bands, average level, top levels | minor if derived from player summary | — |
| Location concentration | population by map, zone, or server | minor if fields already exist; major if new source | — |
| Economy | spice, solari, market, exchange, tax, trade | major | DB discovery |
| Storage and inventory | containers, items, assets, bases, stockpiles | major | DB discovery |
| **API RED metrics** | request rate, error rate (4xx/5xx), latency p50/p95/p99 per endpoint | major | R2 (Console exporter) |
| **Grafana dashboard usage** | dashboard view count, most queried panels, datasource query rate | minor | R2 |
| **Bridge action analytics** | call rate per action, error rate, avg response time per action | major | R3 (structured logging) |
| **SLO/SLI tracking** | Console API availability (%), bridge latency SLO, data freshness SLO | major | R5 (SLO framework) |

**Sources**: `R1-NOTES:27-37` (operational design), `metric-classification-standard.md` (privacy classes, cardinality rules), `ADDON-METRICS-SUPPORT:168-173` (follow-up bridge work)

## Planned releases

### Core Infrastructure (Core repo: `dune-awakening-selfhost-docker`)

Core releases provide the infrastructure and bridge actions that the addon depends on. See [ROADMAP.md](ROADMAP.md) for the full dependency graph.

#### Core R2: Console Exporter + SOC Foundation

Scope:
- Grafana (localhost:3000, always-on when addon is running)
- Alertmanager (localhost:9093, email + webhook receivers)
- `dune-stack.yml` populated (Console API RED metrics: request rate, errors, latency)
- Console API exporter (new `/metrics` endpoint, Prometheus-scrapable)

Rules:
- No new permissions.
- No new bridge actions.
- No new upstream routes.

Tags: `core-metrics-r2`

#### Core R3: Prometheus Bridge API

Scope:
- `metrics.query` bridge action (safe PromQL subset, requires `ops:read`)
- `/api/server/metrics` endpoint (host-level CPU/mem/disk/uptime)
- Structured logging (JSON Lines with levels, module tags, request IDs)
- 7-day log rotation (configurable)

Rules:
- PromQL must be sanitized (no unbounded cardinality, no raw metric names, no subqueries >1 level).
- Response size limited to `ADMIN_MAX_JSON_BYTES`.

Tags: `core-metrics-r3`

#### Core R4: SOC Hardening

Scope:
- Redis container (internal network, persistent rate limit backend)
- Persistent rate limiting (Redis-backed sliding windows, survives restart)
- Proxy-aware IP detection (`X-Forwarded-For` + `ADMIN_TRUSTED_PROXIES` CIDR)
- Per-addon CSP sandbox (computed from declared addon permissions)
- Alertmanager receivers wired (SMTP + webhook via env vars)

Rules:
- Redis stores rate limit counters only (no secrets, tokens, PII).
- Optional `requirepass` for defense-in-depth.

Tags: `core-soc-r4`

#### Core R5: Ops Maturity

Scope:
- Prometheus retention policy (configurable, automated WAL backup)
- Audit log rotation (compress + rotate `web-admin-audit.jsonl`)
- Health score aggregation (`dune_health_score` 0–100 metric)
- SLO/SLI framework (Console API 99.5% uptime, bridge p95 < 5s, data freshness < 5 min)
- DORA tracking (deploy frequency, lead time, MTTR, change failure rate)

Rules:
- No new permissions or bridge actions.
- SLO targets are advisory until validated with production data.

Tags: `core-ops-r5`

### Addon (this repository)

### v0.2.0 public player operations

Scope:

- A3 player summary;
- A4 KPI capability;
- A5 read-only KPI panels.

Rules:

- no new permission;
- no new bridge action;
- no new upstream route.

### v0.3.0 OPS Health Foundation

Scope target:

- bridge freshness panel;
- source health labels;
- stale data warnings;
- player-impact deltas;
- operator status summary.

Default rule: stay within `players:read` unless a separate design PR approves a new bridge action.

### v0.4.0 Game Activity & Combat (merges v0.4 + v0.5)

Scope target:

- active players by interval, sessions, transitions, retention;
- player deaths by location/cause, PvP vs PvE classification;
- NPC kills by type/location, death spike detection.

Default rule: requires database discovery phase before implementation. Enabled by Core R2 (Grafana + Alertmanager for operator visibility).

Tags: `v0.4.0`

### v0.5.0 Economy & Resources (merges v0.6 + v0.7)

Scope target:

- ore/spice/fiber gathering volumes, scarcity indicators;
- currency flow, market volume, inflation signals.

Default rule: requires database discovery phase before implementation. Economy data is classified as sensitive per [metric-classification-standard.md](../ops-observability/roadmap/metric-classification-standard.md).

Tags: `v0.5.0`

### v0.6.0 World & Assets (merges v0.8 + v0.9)

Scope target:

- crafting volumes, inventory movement, storage pressure;
- territory hot spots, activity heat maps, base activity.

Default rule: requires database discovery phase before implementation. Location data must use coarse rollups (map/zone only, no coordinates).

Tags: `v0.6.0`

### v1.0.0 SOC/OPS Operations Center

Scope target:

- platform health summary (API uptime, bridge success/failure, latency);
- Prometheus metrics display (CPU, memory, saturation, DB health) via Core R3 bridge;
- addon integrity (permission drift, manifest drift, configuration drift);
- operator runbook links, incident notes.

Dependencies: requires Core R3 (`metrics.query` bridge) and Core R4 (persistent rate limits + CSP). Cannot ship without these.

Tags: `v1.0.0`

## Hard line

Do not casually add:

- `database:read`;
- admin audit logs;
- raw logs;
- exports;
- webhooks;
- persistent history;
- cross-addon scans;
- economy data;
- inventory data.
- Prometheus scrape target details to unauthenticated endpoints;
- Alertmanager receiver configurations to addon bridge responses;
- Grafana admin credentials or dashboard provisioning paths in logs;
- Redis connection strings or AUTH tokens.

Each item requires its own design PR, security notes, private Console test, and release train decision.

## Document references

- [ROADMAP.md](ROADMAP.md) — unified overview, dependency graph, tagging convention
- [OBSERVABILITY-ROADMAP.md](OBSERVABILITY-ROADMAP.md) — per-release candidate metrics, DB discovery requirements
- [release-standard.md](../ops-observability/roadmap/release-standard.md) — 5-gate release process, evidence bundle
- [metric-classification-standard.md](../ops-observability/roadmap/metric-classification-standard.md) — privacy classes, cardinality, DB/runtime/log rules
- [DATABASE-EVENT-INVENTORY.md](DATABASE-EVENT-INVENTORY.md) — PostgreSQL event inventory procedure
- [METRIC-DISCOVERY-FINDINGS.md](METRIC-DISCOVERY-FINDINGS.md) — first discovery run results
- [METRICS-BRIDGE-ACTIONS.md](METRICS-BRIDGE-ACTIONS.md) — proposed bridge action names and behavior
- [RFC.md](RFC.md) — formal RFC for the comprehensive roadmap
