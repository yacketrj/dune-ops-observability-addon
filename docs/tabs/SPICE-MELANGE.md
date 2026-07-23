# Tab Architecture — Spice Melange (Resources)

**Data-tab attribute**: `spice` (labeled "Spice Melange" in the nav; `special-tab` CSS class for the amber/lavender theming)
**HTML**: `web/index.html:418-434`
**Render entry point**: `refreshAll()` → `renderResources(result)` (`web/addon.js:593`)
**Bridge action**: `ops.resources.summary` — **live**, same dual-path availability as Activity.
**Core query**: `duneDb.addonOpsResourcesSummary(db)` (`duneDb.js:4489-4545`)

---

## 1. Current implementation (verified) — no defects; one testing gap

### 1.1 Rendering, verified correct but structurally unusual

`renderResources()` (`addon.js:593-699`) correctly follows the `SourceResult` contract at its top level (checks `.status === "unavailable"` first, clears `#res-spice-groups` and shows `.availability-note` on that branch). Once in the live branch, it delegates to a nested `renderSpiceGroups()` function that does **imperative DOM construction** (`document.createElement` for every card, table, row, and cell — roughly 60 lines) rather than the declarative `appendRow()` helper every other panel uses. This is the only panel built this way.

**Why it's structured differently**: the data shape genuinely is more complex than every other panel's flat metric-cards-plus-table layout — it groups `spiceFieldsBySize` rows by map, then renders a per-map pair of summary cards (Active/Remaining) followed by a per-map table of size-tiers (Small/Medium/Large), with inline color-coding (`SPICE_COLOR = "#c4b5fd"`) applied directly via `.style.color`/`.style.cssText` on each created element. This is the specific, real usage the CSP's `style-src 'unsafe-inline'` allowance (added in the A-1 fix) exists to accommodate.

**Not a defect, but a real testing gap**: none of the 26 tests in `test/addon.test.js` + `test/addon-rendering.test.js` exercise `renderSpiceGroups()`'s grouping/sorting logic directly (the 11 behavioral tests added in the F-1 fix cover `renderActivity`, `renderCombat`, `renderInventory`, `renderEconomy`, `renderOpsAggregate`, the preview watermark, and the status banner — not Resources). A regression in the map-grouping or size-tier-sorting logic (`sizes.sort(...)`, `addon.js` inside `renderSpiceGroups`) would not be caught by the current suite.

### 1.2 Real query behavior, verified

`addonOpsResourcesSummary` combines two real tables: `dune.resourcefield_state` (aggregate field counts/values, filtered `field_kind_id = 1`) and `dune.spicefield_types` (per-map, per-size-tier spawn capacity/active counts, filtered `is_spawning_active = true`). Both are wrapped in existence checks (`tableExists`) and independent `try {} catch {}` blocks, degrading to `[]` on a per-install schema variance — consistent with every other `addonOps*` function's pattern. No fabrication; genuinely real, live spice-field data.

---

## 2. Data flow (current, verified)

Same shape as Activity (see `docs/tabs/ACTIVITY.md` §2), substituting `ops.resources.summary` / `addonOpsResourcesSummary` / `renderResources`. The one structural difference is entirely client-side (§1.1's imperative rendering), not in the data-fetch path.

---

## 3. Recommended design changes

1. **Add direct test coverage for `renderSpiceGroups()`'s grouping/sorting behavior** — a jsdom-based test (following the exact pattern already established in `test/addon-rendering.test.js`) asserting that a multi-map, multi-size-tier `SourceResult` produces the correct number of map groups, correctly sorted size rows (Small → Medium → Large), and correct per-map summary totals. This closes the one real gap found in this tab.
2. No functional/data changes needed — this tab is fully backed by real, live data today.
