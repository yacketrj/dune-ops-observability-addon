# Release 0.3 — Expanded Aggregate DB Bridge Actions

## Classification

Upstream Core candidate.

This release may become an upstream PR only if the implementation remains narrow, aggregate-only, permission-gated, and fully covered by unit and E2E evidence.

## Objective

Promote the validated Release 0.2 safe aggregate candidates into explicit Core addon bridge actions.

## Proposed Bridge Actions

- `ops.health.summary`
- `ops.health.players`
- `ops.health.farms`
- `ops.health.summary.v2`

## Approved Input Evidence

Release 0.2 validated the following safe aggregate candidates:

- Player status summary grouped by `online_status`, `life_state`, and `character_state`.
- Farm state aggregate summary using total farms, ready farms, alive farms, connected players, incoming S2S connections, and outgoing S2S connections.

## Explicit Exclusions

This release remains limited to aggregate player and farm health. It must not add other telemetry classes or row-level payloads.

## Permission Model

All actions require:

- addon installed
- addon enabled
- approved permission: `ops:read`
- authenticated console session
- CSRF-valid bridge request

## Response Shape

### `ops.health.summary`

Returns combined aggregate player and farm health. This is the compatibility action for the initial metrics bridge contract.

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

- [x] Core function names selected.
- [x] Bridge action names finalized.
- [x] Response schemas finalized.
- [x] Missing-table/missing-column behavior defined.
- [x] Unit tests listed.
- [x] E2E tests listed.

Gate 1 design artifact:

```text
ops-observability/releases/0.3-expanded-db-bridge/gate-1-design.md
```

## Gate 2 — Implementation

- [x] Gate 2 plan added.
- [x] Core worktree validator added.
- [x] Release 0.3 validation runner added.
- [x] `duneDb` aggregate functions implemented.
- [x] `server.js` bridge actions implemented.
- [x] `ops:read` permission enforced.
- [x] Unit tests added.
- [x] Changed-file scope reviewed.

Gate 2 preparation artifacts:

```text
ops-observability/releases/0.3-expanded-db-bridge/gate-2-plan.md
ops-observability/dev-tools/validate-core-ops-health-worktree.sh
ops-observability/dev-tools/run-ops-health-03-validation.sh
```

Core implementation PR:

```text
Core PR: yacketrj/dune-awakening-selfhost-docker-WSL#87
Merge commit: 97faa59d4048477f7d89c7998807baaeb86a593e
```

## Gate 3 — Verification

- [ ] Core PR gate passed or explicitly not configured.
- [x] API unit tests passed per operator report.
- [ ] Local bridge E2E passed.
- [ ] Public-origin bridge E2E passed if applicable.
- [ ] WebUI probe passed if applicable.
- [ ] Privacy scan passed.

## Gate 4 — Release

- [ ] Release decision written.
- [ ] Evidence snapshot created.
- [ ] Upstream PR created or release kept internal.
