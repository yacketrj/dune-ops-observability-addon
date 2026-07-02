# Dune Ops Observability Metric Classification Standard

## Purpose

This document defines how database, runtime, host, container, network, and log-derived signals are classified before they become telemetry.

No metric may be implemented until it has a classification entry.

## Metric Record Schema

Each metric candidate must include:

| Field                 | Required | Description                                      |
| --------------------- | -------: | ------------------------------------------------ |
| Metric name           |      Yes | Stable name, for example `players.total`         |
| Source                |      Yes | DB, Docker, host, log, HTTP, process, filesystem |
| Collector/query       |      Yes | Query or collector description                   |
| Output type           |      Yes | count, gauge, enum distribution, boolean, status |
| Cardinality           |      Yes | low, medium, high, unbounded                     |
| Privacy class         |      Yes | safe, sensitive, unsafe, unknown                 |
| Permission            |      Yes | usually `ops:read`                               |
| Failure behavior      |      Yes | healthy, degraded, unknown, unsupported          |
| Exposure target       |      Yes | upstream, addon, internal, rejected              |
| E2E coverage          |      Yes | test name or planned test                        |
| Privacy scan coverage |      Yes | forbidden patterns checked                       |
| Notes                 |       No | caveats, assumptions, follow-up                  |

## Privacy Classes

### Safe

May be exposed after review.

Examples:

* total player count
* connected player count
* farm count
* ready/alive farm counts
* database readable count
* low-cardinality enum distributions
* container running status
* restart count
* disk free bytes

### Sensitive

May be useful but requires additional review.

Examples:

* timestamps that could reveal individual activity
* detailed log-derived counts
* table row counts for tables with unclear semantics
* grouped values where cardinality could grow unexpectedly
* host paths
* public URL status

### Unsafe

Must not be exposed.

Examples:

* player identifiers
* account identifiers
* character names
* actor IDs
* Funcom/FLS IDs
* coordinates
* exact positions
* raw rows
* raw logs
* SQL text
* PromQL text
* serialized blobs
* tokens
* passwords
* secrets

### Unknown

Must not be exposed until classified.

Examples:

* unknown database columns
* opaque binary/blob fields
* unclear enum values
* fields with game-specific semantics not yet understood

## Cardinality Rules

| Cardinality | Meaning                                            | Default Action                       |
| ----------- | -------------------------------------------------- | ------------------------------------ |
| Low         | Small fixed set, such as healthy/degraded/critical | Allowed after review                 |
| Medium      | Bounded but variable set                           | Sensitive review                     |
| High        | Many possible values                               | Reject unless aggregated differently |
| Unbounded   | User/player/path/id-derived                        | Reject                               |

## Naming Rules

Metric names must be stable and low-cardinality.

Allowed examples:

```text
server.farms.total
server.farms.ready
server.farms.alive
players.total
players.connected
players.onlineStatus.count
players.lifeState.count
storage.databases.readable
runtime.containers.running
runtime.disk.freeBytes
logs.errors.count
```

Rejected examples:

```text
players.<playerId>.status
characters.<characterName>.state
map.<x>.<y>.players
logs.raw.<line>
sql.query.text
container.env.<name>
```

## DB Query Rules

Allowed query patterns:

```text
COUNT(*)
COUNT WHERE condition
SUM numeric safe column
GROUP BY low-cardinality enum/status field
MIN/MAX only when not tied to identity
EXISTS table/column capability checks
```

Rejected query patterns:

```text
SELECT *
raw row preview
player name selection
identifier selection
coordinate selection
serialized blob selection
free-form log selection
unbounded GROUP BY
query text returned to client
```

## Runtime Metric Rules

Allowed:

* container running state
* restart count
* uptime
* healthcheck state
* expected mount presence
* expected port presence
* disk usage summary
* memory usage summary
* CPU/load summary

Sensitive/review required:

* host paths
* image digests
* public URLs
* network interface details
* process command lines

Rejected by default:

* environment variables
* raw Docker inspect output
* secret mounts
* raw logs
* raw process args containing secrets

## Log Metric Rules

Allowed by default:

* error count
* warning count
* last error timestamp
* last warning timestamp
* known fatal pattern count
* restart pattern count
* auth failure count
* addon bridge failure count

Rejected by default:

* raw log lines
* stack traces
* request headers
* cookies
* tokens
* passwords
* IP-specific detail unless explicitly approved
