# Tab Architecture — Players

**Status (2026-07-24): §1.2's KPI Capability panel defect is resolved.** See the update note at the top of §1.2 below for what changed.

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

### 1.2 "KPI Capability" panel (index.html) — **resolved 2026-07-24 (Tier 2.1)**

**Original defect** (kept below for history): seven `<article class="capability-card">` rows, entirely static HTML, each hardcoded `<span class="capability-status capability-supported">supported</span>` — confirmed via direct search that zero occurrences of `capability-grid`/`capability-card`/`capability-status` existed anywhere in `web/addon.js`, meaning the panel never reflected real bridge state. One claim (Location & Territory) was permanently false, since Location is closed out-of-scope by owner decision (`docs/tabs/LOCATION.md`) and will never be implemented.

**Fix implemented**:
- Removed the "Location & Territory" row entirely (recommendation #1 below) — Location was a feature this addon will never have, not a capability worth reporting as dynamically supported/unavailable.
- Made the panel dynamic (recommendation #2 below): each `<span class="capability-status">` now carries a `data-capability-sources="..."` attribute (a comma-separated list of the real `SOURCE_NAMES` entries backing it, e.g. `data-capability-sources="opsHealth,activity"` for Population & Activity) read directly from the DOM by a new `renderCapabilities()` function (`web/addon.js`), called at the end of every `refreshAll()` cycle alongside every other `renderXxx()`. A capability's status is computed fresh every refresh from the real `SourceResult.status` of each source it depends on — `"supported"` only if every listed source is `live`/`preview` this refresh, `"unavailable"` only if every listed source is `unavailable`, `"partial"` (previously-dead CSS, now wired up) if some but not all are.
- Added SOC and Metrics/Prometheus rows (recommendation #3 below) — both are real data-source domains that previously had no capability row at all.
- 7 new jsdom behavioral tests added to `test/addon-rendering.test.js` covering: a genuinely-down source shows `unavailable` (never the old static `supported`); a genuinely-live source shows `supported`; the multi-source Population & Activity capability correctly shows `partial` when only some of its sources are live, and correctly requires *all* sources live/down for `supported`/`unavailable`; the Location row no longer exists at all; SOC/Prometheus rows exist and reflect their own independent status; and a source recovering from unavailable to live on a subsequent refresh is reflected, not stuck on a stale value.
- Deliberately broke the multi-source "partial" branch during test-writing to confirm the multi-source test actually catches a regression (it did, with a clear diff), then restored the correct logic and reconfirmed all tests pass — following the same verification discipline used for the Spice Melange sort-order tests.

### 1.3 "Read-only KPI Panels" (index.html:257-288)

Active Rate / Average Level / Top Faction / Top Guild — computed by `renderKpis()` (`addon.js:382-399`) directly from the same OPS-health snapshot as §1.1. Handles missing sub-fields correctly (`kpis.averageLevel === null ? "—" : ...`), though the "not present" wording (e.g., *"Average level is not present in this aggregate payload"*) is worth revisiting once the KPI Capability panel is fixed, for consistent terminology (`docs/DESIGN-REVIEW-2026-07-23.md` §4's "no shared status convention" note applies directly here too — "not present in payload" and "unavailable" describe the same underlying situation with different words in different panels).

---

## 2. Data flow (current, verified)

Identical upstream data source as NOC Overview (`ops.health.summary.v2`/`.players`/`.farms` via the addon-bridge path — see `docs/tabs/NOC-OVERVIEW.md` §2 for the verified server-side routing). This tab and NOC Overview render the *same* underlying snapshot into two different panel layouts; there is no separate provider call for this tab.

---

## 3. Recommended design changes — all implemented 2026-07-24 (Tier 2.1)

1. ~~Remove the "Location & Territory" row entirely.~~ **Done.**
2. ~~Make the remaining KPI Capability panel dynamic, driven by the real `SourceResult.status` of each underlying data source.~~ **Done** — see §1.2 above. Uses a `capability-partial` third state (not just supported/unavailable) for capabilities backed by more than one source, which the original recommendation didn't anticipate but the pre-existing dead CSS already supported.
3. ~~Consider adding rows for SOC and Prometheus/Metrics.~~ **Done** — added, since both are real, live-or-live-but-conditional data-source domains.
4. This panel is now a genuinely useful single-glance "what can I trust right now" summary, recomputed every refresh.

No further action needed on this panel unless a new capability/source is added to the addon in the future — in which case, add a new `<span data-capability-sources="...">` row rather than a static one, to keep this panel from regressing back to the original defect.
