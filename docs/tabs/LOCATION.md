# Tab Architecture — Location

**Status (decided 2026-07-24)**: **Permanently out of scope.** Per-player real-time location tracking is not this addon's job — that data already belongs to, and is already surfaced by, the Console's own map UI. This addon's scope is aggregate operational/observability metrics (AAA-style NOC/SOC KPIs — population, combat, economy, inventory, platform health), not per-player tracking.

**Data-tab attribute**: `location`
**HTML**: `web/index.html:530-567`
**Render entry point**: `refreshAll()` → `renderLocation(result)` (`web/addon.js:767`)
**Bridge action**: `ops.location.activity` — **not implemented, by design, permanently**. `opsLocationProvider` (in `dune-awakening-selfhost-docker`) returns `opsPlaceholder("location")` unconditionally; no `addonOpsLocationSummary` function exists or is planned.

---

## Why (for context — this is a closed decision, not an open question)

Every other real OPS data source this addon uses (`addonOpsActivitySummary`, `addonOpsCombatDeaths`, `addonOpsResourcesSummary`, `addonOpsEconomySummary`, `addonOpsInventorySummary`, `addonOpsSocSummary`) is aggregate-only — counts, sums, averages, with zero per-player identifiers in any returned row.

Real, comprehensive live-map data does exist in Core (`duneDb.liveMapMarkers`, `liveMapPlayers`, `liveMapBases`, and siblings — already used by the Console's own `/api/map/*` routes, session-auth gated) — but most of it is **individually-identifying, real-time-coordinate data**: character names, Funcom IDs, account IDs, exact X/Y/Z positions. That is a materially different privacy posture than every other source this addon uses, and it already has a proper home: the Console's own admin-only map UI.

This review originally presented two options (an aggregate-only marker-count version, or full per-player integration) and flagged the choice as the maintainer's to make. The maintainer's decision: **neither** — this tab stays a permanent placeholder. An observability/KPI addon showing "how many markers exist per map" isn't a meaningful enough feature on its own to justify building a new Core aggregate just for it, and the per-player option was never on the table for a metrics-focused addon.

## Current implementation (verified, unchanged)

`renderLocation()` (`addon.js:767-786`) correctly follows the `SourceResult` contract and always shows the "Not available" state — this requires no changes and should not be revisited as a "gap."

## What this means going forward

- Do not build `addonOpsLocationSummary` or any Core-side wiring for `ops.location.activity`.
- If this tab is ever removed from the UI entirely (rather than kept as a permanent "not available" placeholder), that's a separate, small addon-side design cleanup — not tracked as required work, since a permanently-unavailable tab is itself an honest, correct state, not a defect.
- Any future per-player location/tracking feature request belongs in the Console app (`dune-awakening-selfhost-docker`'s own web UI), not in this addon, and should be scoped as its own explicit admin-tooling feature — not folded into `ops:read`'s aggregate-metrics permission model.
