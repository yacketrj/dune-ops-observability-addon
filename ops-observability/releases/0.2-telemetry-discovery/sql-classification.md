# Release 0.2 SQL Classification

## Purpose

Classify preserved SQL discovery scripts before any query or field is promoted to Core bridge telemetry or addon UI.

## Classification Values

| Value | Meaning | Exposure Rule |
|---|---|---|
| Safe aggregate | Count, sum, status, or low-cardinality grouping with no identity/location | May be promoted after review |
| Sensitive aggregate | Useful but potentially revealing or unclear | Requires manual approval |
| Unsafe raw data | Identifier, coordinate, name, raw row, payload, token, secret | Never expose |
| Unknown | Semantics unclear | Do not expose |
| Not useful | No operational value | Do not expose |

## Initial Query Classification

### postgres-event-inventory.sql

| Section | Classification | Action | Reason |
|---|---|---|---|
| Active database / current user | Sensitive | Internal only | Exposes runtime/database identity metadata |
| Available non-template databases | Sensitive | Internal only | Exposes local DB topology |
| Schemas | Sensitive metadata | Internal only | Useful discovery evidence, not bridge telemetry |
| Tables and views | Sensitive metadata | Internal only | Reveals internal schema |
| Columns | Sensitive metadata | Internal only | Reveals internal schema and candidate sensitive fields |
| Key relationships | Sensitive metadata | Internal only | Reveals implementation model |
| Indexes | Sensitive metadata | Internal only | Reveals implementation detail |
| Candidate event tables by name | Sensitive metadata | Internal only | Discovery-only signal |
| Candidate event columns by name | Sensitive metadata | Internal only | Discovery-only signal |
| Approximate row counts | Sensitive aggregate | Review later | May become storage-health metric after review |

Decision: keep this file as internal discovery evidence only. Do not promote directly to Core bridge telemetry.

### postgres-metric-discovery.sql

| Section | Classification | Action | Reason |
|---|---|---|---|
| Active database / current user | Sensitive | Internal only | Exposes runtime/database identity metadata |
| User-defined enum labels | Sensitive metadata | Internal only | Useful for classification, not bridge telemetry |
| High-value table row counts | Sensitive aggregate | Review later | Broad table list includes player/economy/guild/location tables |
| Player status summary | Safe aggregate | Candidate for bridge | Low-cardinality grouped player state; no player rows |
| Farm state summary | Unsafe as written | Rewrite | Selects row-level `server_id`, `farm_id`, `map` |
| Game event type counts | Sensitive aggregate | Review later | Includes event taxonomy and map |
| Game event custom data keys | Sensitive/unknown | Hold | JSON keys may reveal payload structure |
| Event log category counts | Unsafe as written | Reject/rewrite | Includes message/function grouping; high-cardinality and implementation-specific |
| Event log meta keys | Sensitive/unknown | Hold | JSON keys may reveal internal detail |
| Item template summary | Sensitive aggregate | Hold | Item/economy metadata exposure |
| Item operation function summary | Sensitive aggregate | Hold | Function/template grouping is implementation-specific |
| Exchange order summary | Sensitive aggregate | Hold | Economy price data by template |
| Fulfilled exchange order summary | Sensitive aggregate | Review later | Aggregate completion data, but economy-sensitive |
| Currency balance summary | Sensitive aggregate | Hold | Player-wallet-derived aggregate economy data |
| Resource field summary | Sensitive aggregate | Review later | Map/dimension/resource field data is location-adjacent |
| Spice field type summary | Sensitive aggregate | Review later | World-state/location-adjacent operational data |
| Dungeon completion summary | Sensitive aggregate | Review later | Activity aggregate; likely safe after review |
| Landsraad progress summary | Sensitive aggregate | Hold | Includes faction/guild/player progress fields |
| Marker summary | Sensitive aggregate | Review later | Location-adjacent map/dimension grouping |
| Player marker summary | Sensitive aggregate | Hold | Player-discovery-derived location-adjacent data |

Decision: do not execute this script as a bridge source as-is. Split into approved aggregate candidates, sensitive review candidates, and rejected/rewrite-required queries.
