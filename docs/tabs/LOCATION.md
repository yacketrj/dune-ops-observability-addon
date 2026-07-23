# Tab Architecture — Location

**Data-tab attribute**: `location`
**HTML**: `web/index.html:530-567`
**Render entry point**: `refreshAll()` → `renderLocation(result)` (`web/addon.js:767`)
**Bridge action**: `ops.location.activity` — **not implemented** in `opsProvider.js` (`opsLocationProvider` returns `opsPlaceholder("location")`, no `addonOpsLocationSummary` function exists in `duneDb.js`).

**Second-highest-value finding in this review, but with a real privacy consideration the Inventory finding didn't have** — real, comprehensive, already-used live-map data exists in Core, but most of it is per-entity, real-time-coordinate data, not the aggregate-only shape every other OPS source in this addon has used so far. See §4 before treating this as a drop-in wire-up.

---

## 1. Current implementation (verified) — correctly renders unavailable; no data-fabrication risk

`renderLocation()` (`addon.js:767-786`) correctly follows the `SourceResult` contract. No rendering changes needed regardless of what §2-4 below conclude.

## 2. What the addon currently assumes exists (its own sample fixture, `data-providers.js:223-241`)

```js
const sampleLocation = {
  activeMaps: [{ map, players, online }, ...],
  totalMarkers: 87,
  markersByMap: [{ map, markers }, ...],
  playerDensity: [{ map, players, online }, ...],
  territoryPressure: []  // never rendered by renderLocation() today — read it before assuming it needs a source
};
```

## 3. What real data actually exists in Core (verified directly, this review)

A complete, already-deployed live-map subsystem, used today by the Console's own map UI (`/api/map/*` routes, `server.js:536-544`, session-auth gated):

| Function | `duneDb.js` | Shape | Real map config |
|---|---|---|---|
| `liveMapCapabilities(db)` | :1948 | `{players, vehicles, storage, bases, services, farmState, coordinateTransform}` — booleans, per-install schema detection | — |
| `liveMapConfigPayload(selected)` | :1998 | Static config for two real, named maps: `HaggaBasin` (4096×4096, real world-coordinate bounding box) and `DeepDesert` (same) | Confirms exactly which two maps this game has |
| `liveMapPartitions(db)` | :2007 | Per-map, per-partition marker counts (`{map, partition_id, name, marker_count}`) — this is the closest existing match to the sample fixture's `markersByMap`/`totalMarkers` | Aggregate-only, no player identity |
| `liveMapPlayers(db, map)` | :2025 | **Per-player rows** including `character_name`, `online_status`, `fls_id`/`funcom_id`, `account_id`, and real-time `x/y/z` world coordinates | **Not aggregate — real identity + real-time location** |
| `liveMapVehicles(db, map)` | :2092 | Per-vehicle rows with real-time `x/y/z` | Not player-identifying directly, but real-time position |
| `liveMapStorage(db, map)` | :2119 | Per-container rows (name, item_count, real-time `x/y/z`) | Container name only, not player identity, but real-time position |
| `liveMapBases(db, map)` | :2152 | Per-base rows (owner display name via `permission_actor.actor_name`, real-time `x/y/z`) | Base-owner name + real-time position |
| `liveMapMarkers(db, map)` | :2233 | Combines all four `liveMap{Players,Vehicles,Bases,Storage}` into one `rows[]` array plus `overlays`/`capabilities` | The single richest, already-composed function — but inherits every privacy consideration of its four inputs |

## 4. Privacy consideration — read before wiring anything here

**Every other real OPS data source this addon uses today (`addonOpsActivitySummary`, `addonOpsCombatDeaths`, `addonOpsResourcesSummary`, `addonOpsEconomySummary`) is aggregate-only — `count`/`sum`/`avg`, grouped, with zero per-player identifiers in any returned row.** This was explicitly verified and is called out as the correct pattern in `docs/tabs/ECONOMY.md` §1.2.

`liveMapPlayers` and `liveMapBases` break that pattern: they return **individually identifying** data (character names, Funcom IDs, base-owner names) **plus real-time coordinates** — i.e., exactly the shape needed to answer "where is player X right now," which is a materially different privacy posture than "how many currency holders exist" or "how many deaths occurred by cause." `liveMapVehicles`/`liveMapStorage` are less identity-sensitive (no player name in the row) but still carry real-time coordinates.

This doesn't mean the data is unusable — the Console's own web UI already shows exactly this data to the server owner via session auth, so the *game* already surfaces it to *someone*. The question is specifically whether it's appropriate for the OPS-observability addon (whose permission model, `ops:read`, was designed and documented around aggregate-only access — see the addon's own `README.md` security-boundary section) to re-expose per-player real-time location through a different, less-scrutinized path.

**This is a design decision for the maintainer, not a decision this review makes unilaterally.** Two honest options:

- **(a) Aggregate-only Location tab**: use only `liveMapCapabilities`/`liveMapPartitions` (genuinely aggregate — marker *counts* per map/partition, no identity, no individual coordinates) to power `activeMaps`/`totalMarkers`/`markersByMap`. This matches the addon's existing privacy posture exactly, ships fast, and answers most of what the sample fixture's field names suggest (`playerDensity` can be a per-map *count*, not a per-player location list). Skip `liveMapPlayers`/`liveMapBases`/`liveMapVehicles`/`liveMapStorage` entirely for this tab.
- **(b) Full live-map integration**: wire the complete `liveMapMarkers` output, accepting that this tab now shows individually-identifying, real-time data through the `ops:read` permission — which may need its own explicit permission-scope decision (a new, narrower permission distinct from the aggregate-only `ops:read` used everywhere else), not a silent expansion of what `ops:read` is understood to mean.

Option (a) is the lower-risk, faster-to-ship choice and is what this review recommends by default — but explicitly flags this as the maintainer's call, not a foregone conclusion, since it trades away real, already-built functionality (b) for consistency with the addon's existing privacy stance.

---

## 5. Recommended design (assuming option (a) — aggregate-only)

1. **New Core function** `addonOpsLocationSummary(db)`, calling `liveMapCapabilities(db)` and `liveMapPartitions(db)` only:

```js
export async function addonOpsLocationSummary(db) {
  const capabilities = await liveMapCapabilities(db);
  const partitions = await liveMapPartitions(db); // { rows: [{map, partition_id, name, marker_count}] }
  const byMap = new Map();
  for (const row of partitions.rows) {
    const entry = byMap.get(row.map) || { map: row.map, markers: 0 };
    entry.markers += row.marker_count;
    byMap.set(row.map, entry);
  }
  const markersByMap = [...byMap.values()];
  return {
    activeMaps: markersByMap.map(m => ({ map: m.map, players: null, online: null })), // no aggregate player-per-map count exists yet either — see note below
    totalMarkers: markersByMap.reduce((sum, m) => sum + m.markers, 0),
    markersByMap,
    capabilities
  };
}
```

**Note**: even in the aggregate-only option, a genuine *player count per map* (not per-partition marker count) doesn't exist as a ready-made function — `liveMapPlayers` would need to be called and its rows counted per-map, which reintroduces the per-player-identity data this option is trying to avoid, unless the count is done entirely server-side and only the resulting number is returned (i.e., call `liveMapPlayers`, discard every field except `map`, return `COUNT(*) GROUP BY map`). This is a legitimate, aggregate-safe way to use identity-bearing source data without re-exposing the identities — the same principle Core's own `addonOpsActivitySummary` already uses when it counts `online_players` from `player_state` without returning any individual player row. This sketch's `activeMaps` field should be filled in this way, not left `null`, if a real per-map online count is wanted — flagged here as a refinement for whoever implements this, not left in the sketch above for simplicity.

2. See `docs/prompts/LOCATION.md` for the full implementation prompt, which presents both options (a) and (b) explicitly and requires the implementer to get an explicit maintainer decision before proceeding past option (a)'s scope.
