# Permission Design Review — ops:read

## Scope
- Release: v1.0.0
- Change: Add `ops: ["read"]` permission to addon manifest

## Why
The Ops Observability addon needs to communicate with Console API bridge 
actions under the `ops.health.*`, `ops.activity.*`, `ops.combat.*`, 
`ops.resources.*`, `ops.economy.*`, `ops.inventory.*`, `ops.location.*`, 
and `ops.soc.*` namespaces. These are read-only aggregate bridge actions.

## Review

### Permission Category
- Name: ops
- Level: read
- Write capability: No
- Data access: Read-only aggregate counts and metrics

### Data Classification
- Player state counts: Aggregate only
- Bridge health metrics: System-level, no PII
- Activity/combat/economy data: Aggregate rollups, no individual player IDs

### Security Impact
- No write capability introduced
- No raw SQL exposed to addon (bridge-mediated)
- No player identifiers, coordinates, or inventory payloads exposed

### Alternatives Considered
- Reusing `players: ["read"]`: Not semantically correct — OPS bridge 
  actions are not player-data operations
- No-permission fallback: Would not match Console API permission model

## Decision
- [x] Approved — read-only ops permission, bridge-mediated, aggregate only
- [ ] Blocked
- [ ] Requires further review

## Approval
- Reviewer: @yacketrj
- Date: 2026-07-04
- Notes: Design review per REPOSITORY-REQUIREMENTS-AND-DELIVERABLES.md §16
