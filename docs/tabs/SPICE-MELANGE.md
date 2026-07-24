# Tab Architecture — Spice Melange (Resources)

**Data-tab attribute**: `spice` (labeled "Spice Melange" in the nav; `special-tab` CSS class for the amber/lavender theming)
**HTML**: `web/index.html` (`data-tab="spice"` section)
**Render entry point**: `refreshAll()` → `renderResources(result)` → `renderMapSection()` (`web/addon.js`)
**Bridge action**: `ops.resources.summary` — live, same dual-path availability as Activity.
**Core query**: `duneDb.addonOpsResourcesSummary(db, config)` (`console/api/src/duneDb.js`, `dune-awakening-selfhost-docker`)

---

## 1. Current implementation (as of the Deep Desert / Hagga Basin per-instance rework)

This tab was reworked from a flat map-grouped-totals layout (see `docs/architecture/V0.5-BRIDGE-CONTRACTS.md` for that superseded shape) into a two-section, per-instance layout per the addon's own detailed spec, matching what the Console's real, config-resolved PvP/PvE combat-state resolver (`services/mapCombatState.js`, Core PR #103/#104) can now support.

### 1.1 Real data shape (`ops.resources.summary`)

```json
{
  "deepDesert": {
    "summary": {
      "totalActiveFields": 6,
      "totalRemainingSpice": 30000,
      "pvpInstances": 1,
      "pveInstances": 1,
      "bySize": [{ "size": "Small", "activeFields": 3 }, { "size": "Medium", "activeFields": 2 }, { "size": "Large", "activeFields": 1 }]
    },
    "instances": [
      {
        "partitionId": "8",
        "dimensionIndex": 0,
        "name": "DeepDesert 0",
        "runtimeStatus": "UNASSIGNED",
        "combatState": "PVE",
        "activeFields": 0,
        "remainingSpice": 0,
        "sizes": [{ "size": "Small", "activeFields": 0, "remainingSpice": null }, { "size": "Medium", "activeFields": 0, "remainingSpice": null }, { "size": "Large", "activeFields": 0, "remainingSpice": null }]
      }
    ]
  },
  "haggaBasin": {
    "summary": { "totalActiveFields": 5, "totalRemainingSpice": 25000, "pvpInstances": 1, "pveInstances": 0, "bySize": [{ "size": "Small", "activeFields": 5 }] },
    "instances": [
      {
        "partitionId": "1",
        "dimensionIndex": 0,
        "name": "Sietch Abbir",
        "runtimeStatus": "RUNNING",
        "combatState": "PVP",
        "activeFields": 5,
        "remainingSpice": 25000,
        "sizes": [{ "size": "Small", "activeFields": 5, "remainingSpice": null }]
      }
    ]
  }
}
```

A section with zero currently-provisioned instances (e.g. Deep Desert with nothing spawned) returns its own genuine empty shape (`summary` all-zero, `instances: []`) — a normal, valid, non-error state for this autoscaled map, never conflated with a query/schema failure.

### 1.2 Real, config-resolved PvP/PvE per instance

`combatState` comes directly from `services/mapCombatState.js`'s `resolveMapCombatState()`, the same resolver the Console's own map-combat-state route uses — resolved from the real `UserGame.ini` config, never inferred from `dimension_index`, label, or lifecycle mode. This is why offline/unassigned instances still report a real, meaningful combat state (e.g. Deep Desert dimension 0, unspawned, still correctly resolves to `PVE`).

### 1.3 Real data-model limitation: per-size remaining spice

`dune.resourcefield_state` has real per-field `value_remaining` but no size-tier label. `dune.spicefield_types` has real per-size active-field counts but no remaining-spice column. There is no shared join key between them, and no value-range correlation to infer size (verified: all live fields observed had identical `value_remaining` regardless of size). Given that:

- Per-size `activeFields` is real and reported.
- Per-size `remainingSpice` has no real source and is always `null` — rendered as a dash by the addon, **never estimated or apportioned by ratio** from the instance-level total. That would be exactly the fabrication anti-pattern this whole effort exists to eliminate.
- The instance-level and section-level `remainingSpice` totals ARE real (summed directly from `resourcefield_state`) and are reported at both levels.

### 1.4 Sorting

Deep Desert instances are sorted naturally by `dimensionIndex` (its real numeric identity) — never alphabetically by name. Hagga Basin sietches are sorted alphabetically by name. Both sorts are applied client-side in `web/addon.js` (`sortDeepDesertInstances`/`sortHaggaBasinInstances`), not by the Core query.

### 1.5 Rendering

`renderResources()` checks the top-level `SourceResult.status` first (unavailable → `renderUnavailablePanel()` clears both sections and hides them). On a live result, `renderMapSection()` is called once per section (Deep Desert, Hagga Basin), rendering the section's summary cards, its size-tier table, and either its empty-state note (`#dd-empty-state`/`#hb-empty-state`, zero instances) or its per-instance card list (`renderInstanceCard()`), each card showing the instance's name, runtime status, a PvP/PvE/CONFLICT/MIXED/UNKNOWN combat badge, active-fields/remaining-spice metric cards, and a per-size table.

Numbers are locale-formatted (`toLocaleString()`) via `formatCount()`, which also renders `null`/`undefined` as a dash — never as a fabricated `0` or the literal string `"null"`.

### 1.6 Test coverage

`test/addonOpsResourcesSummary.test.js` (Core repo, `dune-awakening-selfhost-docker`) covers the Core-side query/aggregation logic with 15 tests using a real `mapCombatState.js` resolver sandbox. `test/addon-rendering.test.js` (this repo) covers the addon-side rendering with jsdom-based behavioral tests: unavailable-state clearing, empty-state handling per section, PvP/PvE badge rendering, natural vs. alphabetical sorting, zero-preservation in size rows, dash-not-fabricated remaining-spice per size, locale number formatting, and refresh-transition/no-duplicate-accumulation behavior.

---

## 2. Data flow

Same shape as Activity (see `docs/tabs/ACTIVITY.md` §2), substituting `ops.resources.summary` / `addonOpsResourcesSummary` / `renderResources`. `addonOpsResourcesSummary` now also requires a `config` parameter (for `mapCombatState.js`'s subprocess-based combat-state resolution) — both real call sites (`server.js`'s `addonBridgeRoute` and `opsProvider.js`'s `opsResourcesProvider`) pass it through.

---

## 3. Superseded design

The original flat map-grouped-totals shape (`resourcesByMap`, `spiceFieldsBySize`, no per-instance/PvP-PvE breakdown) is documented for historical reference in `docs/architecture/V0.5-BRIDGE-CONTRACTS.md` and `docs/SPICE-MELANGE-IMPLEMENTATION.md` — both describe the pre-rework implementation and are no longer accurate for the current tab.
