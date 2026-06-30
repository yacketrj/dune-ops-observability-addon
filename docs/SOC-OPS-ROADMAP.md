# SOC / OPS Metric Roadmap

## Context

Dune Ops Observability is now publicly listed through the community addon catalog. Public availability changes the roadmap standard.

New metrics must be evaluated by operator value and by public-release risk.

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

| Area | Metrics | Release class |
| --- | --- | --- |
| Addon and bridge health | bridge available, bridge errors, last successful read, data age | minor if derived; major if new bridge action |
| Player availability | online players, offline players, active rate, sudden drop, last seen staleness | minor if derived from `players:read` |
| Console and API reliability | request errors, latency, timeouts | major |
| Capacity and saturation | CPU, memory, disk, database size, container health | major |
| Service lifecycle | up, down, restart count, degraded state | major |
| Data freshness | stale payload warning, missing fields, source quality | minor if derived; major if new source |

## P1 security metrics

P1 metrics are security-sensitive and should get explicit design review before implementation.

| Area | Metrics | Release class |
| --- | --- | --- |
| Admin activity | admin commands, privilege changes, config changes | major |
| Access failures | failed auth, denied addon requests, permission failures | major |
| Addon integrity | manifest drift, checksum drift, permission drift | minor for this addon; major for cross-addon scans |
| Abuse signals | repeated joins/leaves, suspicious churn, ban/kick trends | major |
| Permission posture | requested versus approved permissions | minor for this addon; major for global monitoring |

## P2 operational analytics

P2 metrics are useful but should not displace P0 health and P1 security work.

| Area | Metrics | Release class |
| --- | --- | --- |
| Faction and guild | faction share, guild share, top faction, top guild | minor if derived from player summary |
| Progression | level bands, average level, top levels | minor if derived from player summary |
| Location concentration | population by map, zone, or server | minor if fields already exist; major if new source |
| Economy | spice, solari, market, exchange, tax, trade | major |
| Storage and inventory | containers, items, assets, bases, stockpiles | major |

## Planned releases

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

### Future major: server and Console health

Likely major scope:

- API request errors;
- bridge request latency;
- timeout count;
- service up/down;
- container health;
- disk and database fullness;
- data freshness source contracts.

This requires design review because it likely needs upstream bridge or core support.

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

Each item requires its own design PR, security notes, private Console test, and release train decision.
