# Release 0.2 — Internal Telemetry Discovery

## Release Classification

Internal tooling.

This release is not intended for upstream unless the resulting tooling proves generally useful and safe.

## Objective

Build a read-only telemetry discovery tool that inventories the Dune runtime database schema, classifies metric candidates, flags unsafe fields, and produces safe aggregate query candidates.

## Target Location

```text
~/dune-work/ops-observability/tools/discover-db-telemetry/
```

## Evidence Location

```text
~/dune-work/ops-observability/evidence/releases/0.2-telemetry-discovery/
```

## Deliverables

```text
db-schema-inventory.json
db-telemetry-catalog.md
safe-query-candidates.sql
forbidden-field-report.txt
release-decision.md
```

## Scope

In scope:

* discover database schemas
* list tables
* list columns
* list column types
* capture row counts
* detect low-cardinality candidates without exposing raw values where unsafe
* flag sensitive-looking fields
* propose aggregate query candidates
* emit JSON and Markdown artifacts
* run against the E2E runtime

Out of scope:

* adding new upstream bridge actions
* changing Core source
* changing addon UI
* exposing raw rows
* exposing player identifiers
* exposing coordinates
* storing raw logs
* committing evidence upstream

## Gate 0 — Scope Gate

Status: Ready.

Acceptance criteria:

* release is classified as internal tooling
* no upstream PR planned yet
* DB access is read-only
* output artifacts are evidence-only
* no raw rows emitted

## Gate 1 — Design Gate

Required decisions:

* database connection method
* schema discovery query set
* forbidden field pattern list
* safe aggregate candidate rules
* output format
* evidence folder layout

Forbidden field patterns:

```text
player
player_id
playerid
controller
account
account_id
character
character_name
funcom
fls
actor
actor_id
x
y
z
coord
coordinate
location
position
token
password
secret
session
cookie
auth
key
blob
payload
serialized
```

Note: some terms such as `player_state` may be safe at the table level but unsafe at the row/field level. Classification must distinguish source table from exposed field.

## Gate 2 — Implementation Gate

Required checks:

* script runs without mutating DB
* script handles missing DB/table/column
* script produces all required artifacts
* script does not emit raw rows
* script does not emit raw high-cardinality values
* script exits non-zero on unexpected collection failure
* script exits zero with degraded report when optional tables are missing

## Gate 3 — Verification Gate

Required evidence:

```text
git-state.txt
tool-run-output.txt
db-schema-inventory.json
db-telemetry-catalog.md
safe-query-candidates.sql
forbidden-field-report.txt
privacy-scan-output.txt
release-decision.md
```

Required validation:

* inventory includes all visible tables
* catalog includes all visible columns
* every column is classified or marked unknown
* safe query candidates use aggregate-only patterns
* forbidden field report lists unsafe/sensitive candidates
* privacy scan confirms no raw rows, names, identifiers, coordinates, secrets, SQL result rows, or tokens are emitted

## Gate 4 — Release Gate

Release may be approved when:

* discovery output is reviewed
* safe candidates are identified
* unsafe candidates are rejected
* unknown candidates are deferred
* Release 0.3 backlog is generated

## Release Decision Template

```text
Release: 0.2 Telemetry Discovery
Decision: Approved / Approved with limitations / Blocked / Abandoned
Date:
Reviewer:
Evidence path:
Known limitations:
Safe candidates approved:
Sensitive candidates requiring review:
Unsafe candidates rejected:
Unknown candidates deferred:
Next release:
```

## Expected Follow-Up

Release 0.3 should only implement metrics that Release 0.2 classifies as safe aggregate metrics.
