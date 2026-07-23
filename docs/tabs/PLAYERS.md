# Tab Architecture — Players

**Data-tab attribute**: `players`
**HTML**: `web/index.html:180-290`
**Render entry point**: `refreshOpsHealth()` (`web/addon.js:448`, triggered by the "Refresh OPS health" button, `index.html:31`) and `refreshAll()` (line 880, on every general refresh) both call `renderOpsAggregate()` → `renderKpis()`

---

## 1. Current implementation (verified)

Three panels: "OPS Health Aggregate" (a table), "KPI Capability" (a static grid), "Read-only KPI Panels" (computed cards).

### 1.1 "OPS Health Aggregate" table (index.html:182-207)

One row per refresh, showing the same totals as the NOC Overview's summary cards (Scope/Players/Online/Offline/Farm Sites/Ready-Alive/Last Read), built by `renderOpsAggregate()` (`addon.js:401-445`). The `#empty-state` div correctly distinguishes three states (fixed in the F-1 refactor):
- **Unavailable** (`!snapshot.available`): `emptyStateEl.hidden = false`, text via `unavailableMessage()` — "Not available — [reason]".
- **Available, zero rows**: `emptyStateEl.hidden = snapshot.hasRows` (i.e., shown), text: "OPS health bridge returned zero player rows and zero farm rows. This is live aggregate data, not placeholder content."
- **Available, has rows**: hidden entirely.

No defects found in this panel.

### 1.2 "KPI Capability" panel (index.html:209-255) — **real defect, new finding from this review**

Seven `<article class="capability-card">` rows, **entirely static HTML**, each hardcoded:
```html
<span class="capability-status capability-supported">supported</span>
```

Confirmed via direct search: zero occurrences of `capability-grid`, `capability-card`, or `capability-status` anywhere in `web/addon.js`. This panel is never touched by JavaScript after initial page load — it always shows the same 7 rows regardless of what the actual current bridge state is.

**Two of the seven claims are currently false**:
- *"Inventory & Crafting — supported... via ops.inventory.summary"* — false. `ops.inventory.summary` is not implemented in Core; the addon's own Inventory tab correctly shows an unavailable state for it (see `docs/tabs/INVENTORY.md`).
- *"Location & Territory — supported... via ops.location.activity"* — false, same reasoning (see `docs/tabs/LOCATION.md`).

The other five claims happen to be true today (Population & Activity, Farm Health, Combat & Deaths, Resources, Economy & Trade all genuinely have live backing), but that's incidental — nothing would update this panel if any of them regressed to unavailable, either.

**Dead CSS confirms this was meant to be dynamic**: `web/addon.css:213-219` defines `.capability-partial` and `.capability-unavailable` styles (amber/red, matching the same convention as `.availability-note`) — styles for exactly the two states this panel needs and doesn't have, sitting unused since they were apparently written in anticipation of a dynamic version of this panel that was never built.

**Impact**: An operator navigating from the Inventory tab (correctly showing "Not available") to the Players tab, one click away, will see this panel confidently claim "Inventory & Crafting: supported." This directly undermines the same operator-trust goal that motivated the entire F-1 fix — a static claim that contradicts a dynamic, correct one elsewhere in the same addon.

### 1.3 "Read-only KPI Panels" (index.html:257-288)

Active Rate / Average Level / Top Faction / Top Guild — computed by `renderKpis()` (`addon.js:382-399`) directly from the same OPS-health snapshot as §1.1. Handles missing sub-fields correctly (`kpis.averageLevel === null ? "—" : ...`), though the "not present" wording (e.g., *"Average level is not present in this aggregate payload"*) is worth revisiting once the KPI Capability panel is fixed, for consistent terminology (`docs/DESIGN-REVIEW-2026-07-23.md` §4's "no shared status convention" note applies directly here too — "not present in payload" and "unavailable" describe the same underlying situation with different words in different panels).

---

## 2. Data flow (current, verified)

Identical upstream data source as NOC Overview (`ops.health.summary.v2`/`.players`/`.farms` via the addon-bridge path — see `docs/tabs/NOC-OVERVIEW.md` §2 for the verified server-side routing). This tab and NOC Overview render the *same* underlying snapshot into two different panel layouts; there is no separate provider call for this tab.

---

## 3. Recommended design changes

1. **Make the KPI Capability panel dynamic**, driven by the real `SourceResult.status` of each of the 7 (really, should be 9 — see below) underlying data sources, using the exact same status/reason vocabulary already established by the `.availability-note` convention elsewhere in the addon. Concretely: each capability row's status span should read `capability-supported` / `capability-unavailable` computed from whether that source's most recent `refreshAll()` result was `"live"`/`"preview"` vs `"unavailable"` — not a static claim.
2. **Add the two missing rows**: this panel lists 7 categories but the addon has 9 real data-source domains (activity, combat, resources, economy, inventory, location, soc, prometheus, plus ops-health itself). SOC and Prometheus/Metrics have no row here at all — decide whether that's intentional (they're arguably "meta" rather than "capability" categories) or an oversight, and either add rows or document the exclusion.
3. Once dynamic, this panel becomes a genuinely useful single-glance "what can I trust right now" summary — which is presumably what it was originally designed to be, based on the dead CSS classes' existence.
