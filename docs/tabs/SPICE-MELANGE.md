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

`dune.resourcefield_state` has real per-field `value_remaining` but no size-tier label. `dune.spicefield_types` has real per-size active-field counts but no remaining-spice column. There is no shared join key between them. Given that:

- Per-size `activeFields` is real and reported.
- Per-size `remainingSpice` has no real source and is always `null` in the Core-side data shape — **never estimated or apportioned by ratio** from the instance-level total. That would be exactly the fabrication anti-pattern this whole effort exists to eliminate. The addon does not render a per-size amount column at all (see §1.5) rather than showing a dash for a field that structurally doesn't exist.
- The instance-level and section-level `remainingSpice` totals ARE real (summed directly from `resourcefield_state`) and are reported at both levels, labeled "Potential Spice" in the addon UI (see §1.5) rather than "Remaining" — deliberately not claiming a precision or permanence guarantee a live snapshot can't back up.

**Correction (2026-07-24)**: an earlier version of this doc claimed "all live fields observed had identical `value_remaining` regardless of size" as evidence against a size-value correlation. That claim was based on a degenerate sample (5 live Hagga Basin fields, all Small — there was no Medium/Large field to compare against, so it was never actually a valid test of a size correlation). When a real Deep Desert spawn was later observed with one active field of each size, the three real values were 5,000 (Small), 150,000 (Medium), and 2,500,000 (Large) — a clear, non-identical progression, suggesting a real size-to-value relationship likely *does* exist at the game-engine level. This does not change the addon's behavior: even if a per-size formula exists, this deployment has no config or schema surfacing it precisely enough to compute or verify it (no base-value table exists anywhere in this repo's game config), so per-size `remainingSpice` correctly remains unfabricated. This correction exists so a future reader doesn't cite the original (invalid) claim as settled evidence.

### 1.4 Sorting

Deep Desert instances are sorted naturally by `dimensionIndex` (its real numeric identity) — never alphabetically by name. Hagga Basin sietches are sorted alphabetically by name. Both sorts are applied client-side in `web/addon.js` (`sortDeepDesertInstances`/`sortHaggaBasinInstances`), not by the Core query.

### 1.5 Rendering

`renderResources()` checks the top-level `SourceResult.status` first (unavailable → `renderUnavailablePanel()` clears both sections and hides them). On a live result, `renderMapSection()` is called once per section (Deep Desert, Hagga Basin), rendering the section's summary cards, its size-tier table (Field Size | Active Fields), and either its empty-state note (`#dd-empty-state`/`#hb-empty-state`, zero instances) or its per-instance card list (`renderInstanceCard()`).

**Per-instance/sietch card layout (revised 2026-07-24)**:
- Header: instance/sietch name + runtime status, plus a `res-combat-badge` (PVP/PVE/CONFLICT/MIXED/UNKNOWN, colored per `combatBadgeClass()`).
- The whole card carries an accent class (`res-instance-card--pvp`/`--pve`/`--conflict`/`--mixed`/`--unknown`, via `combatAccentClass()`) that colors the card's border and name text to match its real combat state — red for PvP, green for PvE, amber for CONFLICT/MIXED, neutral gray for UNKNOWN. This is an accent treatment (border + header only), not a full-block background/text recolor — the size-breakdown table underneath intentionally stays neutral/readable rather than colored text-on-color.
- Two metric cards: "Active Fields" (real per-instance count) and **"Potential Spice"** (the real, directly-summed instance-level total — deliberately not labeled "Remaining" or "Available", see §1.3's note on why; carries a `title` tooltip explaining it's a live snapshot, not a fixed/guaranteed amount).
- A size-breakdown table with exactly two columns: Field Size, Active Fields. There is **no third "amount" column** — per-size spice has no real data source (§1.3), and the earlier design's approach of showing a dash for that column was replaced with omitting the column entirely, since the field doesn't meaningfully exist per size at all.

Numbers are locale-formatted (`toLocaleString()`) via `formatCount()`, which also renders `null`/`undefined` as a dash — never as a fabricated `0` or the literal string `"null"`.

### 1.6 Test coverage

`test/addonOpsResourcesSummary.test.js` (Core repo, `dune-awakening-selfhost-docker`) covers the Core-side query/aggregation logic with 15 tests using a real `mapCombatState.js` resolver sandbox. `test/addon-rendering.test.js` (this repo) covers the addon-side rendering with jsdom-based behavioral tests: unavailable-state clearing, empty-state handling per section, PvP/PvE badge rendering, natural vs. alphabetical sorting, zero-preservation in size rows, dash-not-fabricated remaining-spice per size, locale number formatting, and refresh-transition/no-duplicate-accumulation behavior.

---

## 2. Data flow

Same shape as Activity (see `docs/tabs/ACTIVITY.md` §2), substituting `ops.resources.summary` / `addonOpsResourcesSummary` / `renderResources`. `addonOpsResourcesSummary` now also requires a `config` parameter (for `mapCombatState.js`'s subprocess-based combat-state resolution) — both real call sites (`server.js`'s `addonBridgeRoute` and `opsProvider.js`'s `opsResourcesProvider`) pass it through.

---

## 3. Superseded design

The original flat map-grouped-totals shape (`resourcesByMap`, `spiceFieldsBySize`, no per-instance/PvP-PvE breakdown) is documented for historical reference in `docs/architecture/V0.5-BRIDGE-CONTRACTS.md` and `docs/SPICE-MELANGE-IMPLEMENTATION.md` — both describe the pre-rework implementation and are no longer accurate for the current tab.
