# Release 0.3 — Expanded Aggregate DB Bridge Actions

## Classification

Upstream Core candidate.

This release may become an upstream PR only if the implementation remains narrow, aggregate-only, permission-gated, and fully covered by unit and E2E evidence.

## Objective

Promote the validated Release 0.2 safe aggregate candidates into explicit Core addon bridge actions.

## Proposed Bridge Actions

- `ops.health.players`
- `ops.health.farms`
- `ops.health.summary.v2`

## Approved Input Evidence

Release 0.2 validated the following safe aggregate candidates:

- Player status summary grouped by `online_status`, `life_state`, and `character_state`.
- Farm state aggregate summary using total farms, ready farms, alive farms, connected players, incoming S2S connections, and outgoing S2S connections.

## Explicit Exclusions

This release must not include:

- economy metrics
- inventory metrics
- item template metrics
- event-log metrics
- raw event metadata
- JSON-key discovery output
- marker metrics
- map/dimension metrics
- guild metrics
- Landsraad metrics
- resource-field metrics
- player identifiers
- account identifiers
- character names
- coordinates
- raw rows
- raw logs
- SQL text in API responses

## Permission Model

All actions require:

- addon installed
- addon enabled
- approved permission: `ops:read`
- authenticated console session
- CSRF-valid bridge request

## Response Shape

### `ops.health.players`

Returns aggregate player health only:

```json
{
  "total": 1,
  "onlineStatus": {
    "Offline": 1
  },
  "lifeState": {
    "Alive": 1
  },
  "characterState": {
    "Active": 1
  },
  "combinations": [
    {
      "onlineStatus": "Offline",
      "lifeState": "Alive",
      "characterState": "Active",
      "players": 1
    }
  ]
}
```

### `ops.health.farms`

Returns aggregate farm/server health only:

```json
{
  "total": 2,
  "ready": 2,
  "alive": 2,
  "connectedPlayers": 0,
  "incomingS2SConnections": 2,
  "outgoingS2SConnections": 2
}
```

### `ops.health.summary.v2`

Returns combined aggregate player and farm health.

## Gate 0 — Scope

- [x] Release 0.2 safe aggregate evidence exists.
- [x] Scope excludes sensitive pending-review metrics.
- [x] Target is upstream Core only if implementation remains narrow.

## Gate 1 — Design

- [ ] Core function names selected.
- [ ] Bridge action names finalized.
- [ ] Response schemas finalized.
- [ ] Missing-table/missing-column behavior defined.
- [ ] Unit tests listed.
- [ ] E2E tests listed.

## Gate 2 — Implementation

- [ ] `duneDb` aggregate functions implemented.
- [ ] `server.js` bridge actions implemented.
- [ ] `ops:read` permission enforced.
- [ ] Unit tests added.
- [ ] Changed-file scope reviewed.

## Gate 3 — Verification

- [ ] Core PR gate passed.
- [ ] API unit tests passed.
- [ ] Local bridge E2E passed.
- [ ] Public-origin bridge E2E passed if applicable.
- [ ] WebUI probe passed if applicable.
- [ ] Privacy scan passed.

## Gate 4 — Release

- [ ] Release decision written.
- [ ] Evidence snapshot created.
- [ ] Upstream PR created or release kept internal.
