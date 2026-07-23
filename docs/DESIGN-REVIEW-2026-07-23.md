# Design Review — Dune Ops Observability Addon (all 10 tabs)

**Author perspective**: Principal Architect / Principal Security Engineer
**Date**: 2026-07-23
**Scope**: A complete design review of every tab in `web/index.html`, cross-referenced directly against the current live implementation (`web/addon.js`, `web/data-providers.js`, verified post-merge of PRs #63/#64/#65) and against `dune-awakening-selfhost-docker`'s actual current Core capabilities (`console/api/src/duneDb.js`, `server.js`, `docker-compose.metrics.yml`, `runtime/scripts/metrics-stack.sh`, verified at `main` commit `ed76f64`).

This is a fresh review, not a restatement of the existing aspirational roadmap docs (`docs/ROADMAP.md`, `docs/RFC.md`). Those documents describe a multi-release *vision* (Grafana, Alertmanager, Redis-backed rate limiting, per-addon CSP enforcement, a `metrics.query` PromQL bridge action, a computed `dune_health_score`) — **none of which exist in Core today**, confirmed by direct code search. Every claim below is grounded in code that was actually read and executed, or an explicit "not found" after a real search.

---

## 1. Executive summary

The addon is in a materially better state than it was one day ago (2026-07-22): the Critical false-zero rendering defect (F-1) is fixed, along with F-3/F-4/C-4, and the supply-chain/governance findings (S-1 through S-5, C-1 through C-3, A-1) are resolved. See `docs/GAP-ANALYSIS-RESOLUTION-2026-07-23.md` for that history.

This review found **two new, previously-undocumented false-positive rendering defects**, both in HTML that is never touched by any JavaScript render function — the same class of problem as F-1, but in different tabs than the ones the `SourceResult` refactor covered:

1. **Players tab, "KPI Capability" panel**: all 7 capability rows are hardcoded `capability-supported` in static HTML. Two of them ("Inventory & Crafting," "Location & Territory") are false today — neither `ops.inventory.summary` nor `ops.location.activity` exists in Core. This is a static, never-updated claim of support that doesn't exist, sitting one tab away from the reader who just saw evidence to the contrary on the Inventory/Location tabs themselves.
2. **NOC Overview, "Service Health Map" panel**: the section copy promises named per-service rows ("Postgres, RabbitMQ, Director, Gateway, Survival_1, Overmap, TextRouter") but `renderNocService()` actually renders five generic addon-bookkeeping rows ("OPS Health Bridge," "Player Aggregate," "Farm Aggregate," "Data Freshness," "Provider Mode") that have nothing to do with those named services. Not a fabricated number, but a broken promise about what the table shows — an operator scanning for "is Postgres up" will not find that answer here, without any indication that the promise was never fulfilled.

The second major finding is architectural rather than a defect: **real, previously-unknown backing data exists in Core for two of the three "fully unavailable" tabs** (Location, and a real aggregate half of Inventory), and a real, currently-unused, opt-in Prometheus stack exists that could answer most of the SOC/Prometheus tab's questions — none of this was found or considered when those tabs' placeholders were designed. This materially changes the roadmap: "Inventory," "Location," and part of "SOC/Prometheus" are not stuck waiting for new Core development the way `opsProvider.js`'s own code comments claim ("no backing query exists anywhere in this codebase... do not implement these from Core") — that comment is now half-wrong, and should not be trusted as-is by a future implementer. See §3 per-tab findings and the companion per-tab prompts for exactly what's real.

A third, minor finding: `faction-tagger.js` runs a full-DOM `querySelectorAll` text scan on *every* mutation across all 10 tabs (throttled 100ms), including every one of `refreshAll()`'s per-refresh DOM updates. Not a correctness bug, but worth knowing before adding more tabs/rows — see §4.

---

## 2. Cross-tab architectural patterns (apply once, referenced by every per-tab doc)

### 2.1 The three states every tab must render correctly

Since the Phase 2 refactor (PR #64), every data-bearing tab receives a `SourceResult` envelope: `{status: "live"|"preview"|"unavailable", data, reason, source}`. Any new tab or panel must follow this exact contract — do not read a field off a raw payload without checking `.status` first. See `web/addon.js`'s `renderUnavailablePanel()` and the `*_METRIC_ELS`/`*_TABLE_ELS` array convention already used by every existing panel.

### 2.2 The "supported" vs. "not yet implemented" line, verified as of this review

| Bridge action | Core status | Verified via |
|---|---|---|
| `ops.health.summary` / `.v2` / `.players` / `.farms` | **Live** | `server.js:607`, `duneDb.addonOpsHealth{Summary,SummaryV2,Players,Farms}` |
| `ops.activity.summary` | **Live** | `opsProvider.js:51`, `duneDb.addonOpsActivitySummary` |
| `ops.combat.deaths` | **Live** | `opsProvider.js:56`, `duneDb.addonOpsCombatDeaths` |
| `ops.resources.summary` | **Live** | `opsProvider.js:61`, `duneDb.addonOpsResourcesSummary` |
| `ops.economy.summary` | **Live** | `opsProvider.js:66`, `duneDb.addonOpsEconomySummary` |
| `ops.inventory.summary` | **Not implemented in the Discord adapter path — but real, reusable aggregate storage data exists** (`duneDb.listStorage`, used by `/api/storage`) | See §3.7 |
| `ops.location.activity` | **Not implemented in the Discord adapter path — but real, comprehensive live-map data exists** (`duneDb.liveMapMarkers` + friends, used by `/api/map/*`) | See §3.8 |
| `ops.soc.summary` | **Not implemented anywhere — no real bridge-request counter exists as a query; a real per-request JSONL audit log exists but isn't aggregated** | See §3.9 |
| `ops.health.prometheus` | **Not implemented anywhere in Core's Node.js code — but a real, deployable, currently-unused Prometheus+cAdvisor+node-exporter stack exists** (`docker-compose.metrics.yml`, opt-in via `dune metrics start`) | See §3.9 |

This table supersedes `opsProvider.js`'s own code comment ("no backing query exists anywhere in this codebase" for the five remaining domains) for two of those five — that comment was accurate about `ops.soc.summary`/`ops.health.prometheus`/`ops.aggregated.dashboard`, but is now stale/wrong about `ops.inventory.summary`/`ops.location.activity`. Do not propagate that comment's blanket claim into new work without re-checking against this table.

### 2.3 Auth boundary (unchanged, still correct)

The four already-live routes are gated by `requireDiscordBotToken` (`routes.js:103`) — a shared bearer token, not `ops:read`/`assertInstalledAddonPermission` (the addon-bridge's own system, used by `server.js`'s `action === "..."` handlers for installed third-party addons calling `POST /api/addons/bridge`, a different consumer). Any new Discord-adapter route added for Inventory/Location must follow the same `requireDiscordBotToken` pattern the existing four use — do not add a redundant/wrong permission check, and do not conflate the two systems.

The `/api/map/*` and `/api/storage` routes I found with real backing data (§3.7, §3.8) currently require **session auth** (`auth.requireAuth`, cookie-based, owner-only) — a *third*, different auth mechanism from both of the above. Wiring `duneDb.liveMapMarkers`/`duneDb.listStorage` into `opsLocationProvider`/`opsInventoryProvider` means calling the same underlying query functions through the Discord adapter's existing bearer-token path, not adding a new route or exposing the session-authed routes to the bot — the query functions themselves have no auth logic; only the HTTP route wrapper does.

---

## 3. Per-tab findings

### 3.1 NOC Overview

**Real defect found**: "Service Health Map" panel (index.html:102-117) — section copy names 7 specific services; `renderNocService()` (addon.js:788) renders 5 unrelated addon-bookkeeping rows instead. See §1 above. Full detail and fix options in `docs/tabs/NOC-OVERVIEW.md`.

**Correctly honest**: "Server Resources" panel's CPU/Memory/Disk/Uptime cards are hardcoded to `"—"` in `renderNocResources()` (addon.js:800), matching the section copy's own disclaimer ("requires Prometheus bridge"). No fabrication here.

### 3.2 Players

**Real defect found**: "KPI Capability" panel (index.html:218-254) — all 7 rows hardcoded `capability-supported`, two of which are false. See §1 above.

**Design note**: this tab's "OPS Health Aggregate" table and "Read-only KPI Panels" section both derive from `ops.health.*` only (via `normalizeOpsHealth()`), which is a narrower, older data source than the four newer `ops.*.summary` actions. This tab predates those and was never revisited once they landed — worth deciding whether "Players" should absorb some of what "Activity" now covers, or stay as the original OPS-health-only view.

### 3.3 Activity

No defects found. `renderActivity()` correctly consumes the real, live `addonOpsActivitySummary()` shape end-to-end, with real per-field fallback logic already matching what Core can and cannot compute per-deployment (e.g., `guildActivity`/`factionActivity`/`mapActivity` degrade gracefully to `[]` if the relevant tables/columns don't exist in a given install — this is Core's own schema-discovery behavior, already correctly handled).

### 3.4 Combat

No defects found. `renderCombat()` correctly consumes `addonOpsCombatDeaths()`. One accuracy note: Core's query (`duneDb.js:4522`) currently classifies **all** deaths as `pveDeaths` (`pvpDeaths: 0` is hardcoded server-side, pending real PvP/PvE classification — see the addon's own gap analysis F-2 finding, already resolved as "not present," but the underlying Core-side `pvpDeaths: 0` limitation is real and unrelated to F-2's fabrication issue). The addon renders this correctly (it's real data, just currently always zero for PvP) — flagging for awareness, not as a defect.

### 3.5 Spice Melange (Resources)

No defects found. `renderResources()`'s imperative DOM-building (`renderSpiceGroups()`) is more complex than every other panel's declarative table-row approach, but functions correctly and is covered by the existing test suite indirectly (not directly unit-tested at the DOM level — see `docs/tabs/SPICE-MELANGE.md` for a suggested test addition).

### 3.6 Economy

No defects found. `renderEconomy()` correctly consumes the real, aggregate-only `addonOpsEconomySummary()` (verified in an earlier session: no player-level identifiers in any returned row).

### 3.7 Inventory — real data exists, currently unused

**Finding**: `duneDb.listStorage(db)` (duneDb.js:2563) is a real, live, already-used (by `/api/storage`, the console's own storage browser) aggregate query returning one row per storage container: `{id, name, class, map, item_count, owner_name}`. This is a materially different (and arguably more directly useful) shape than the addon's current `getInventory()` sample fixture assumes (`totalItems`, `totalInventories`, `itemsByTemplate`, `totalCrafted`, `storageUsage`) — `listStorage` gives per-container totals, not per-item-template totals.

A true "items by template" aggregate (matching the sample fixture's `itemsByTemplate` field) does **not** exist as a function today — it would need a new query (`SELECT template_id, COUNT(*), SUM(stack_size) FROM dune.items GROUP BY template_id ORDER BY count DESC LIMIT N`, following the exact schema-discovery pattern every other `addonOps*` function already uses). This is new, real, buildable work — not fabrication, but not "already done" either.

Full detail, exact field mapping, and a concrete query sketch in `docs/tabs/INVENTORY.md`.

### 3.8 Location — real data exists, currently unused

**Finding**: `duneDb.liveMapMarkers(db, map)` (duneDb.js:2233) and its four sibling functions (`liveMapPlayers`, `liveMapVehicles`, `liveMapBases`, `liveMapStorage`, plus `liveMapCapabilities`/`liveMapPartitions`) are a real, comprehensive, already-used (by `/api/map/*`, the console's own live map UI) live-map data system with actual per-map coordinate configs (`HaggaBasin`, `DeepDesert`) and partition/marker aggregation. This is a *better*, more detailed data source than the addon's current `getLocation()` sample fixture (`activeMaps`, `totalMarkers`, `markersByMap`, `playerDensity`) — real per-partition marker counts, real per-map player/vehicle/base/storage overlays all exist today.

Full detail and exact field mapping in `docs/tabs/LOCATION.md`.

### 3.9 SOC (including the Metrics Health / Prometheus panel)

**Two sub-findings, different resolutions:**

1. **`ops.soc.summary`'s `bridgeRequests`/`bridgeErrors`/`bridgeSuccessRate`**: no aggregate query exists, but a real, append-only, per-request audit log exists (`config.auditLog`, written by `audit(config, req, "addons.bridge", {...ok: true/false})` on every bridge call — `server.js:606` et al.). Computing a rolling-window request/error count means tailing and parsing this JSONL file, not a SQL query — a genuinely different implementation shape than everything else in this addon, and worth flagging explicitly to whoever implements it so they don't go looking for a `duneDb.js` function that doesn't exist.

2. **`ops.health.prometheus`**: no Prometheus integration exists in Core's Node.js code, but a **real, complete, currently-unused Prometheus + cAdvisor + node-exporter + postgres-exporter stack already exists** (`docker-compose.metrics.yml`), deliberately opt-in (`dune metrics start`), bound to `127.0.0.1:9090`. `runtime/scripts/metrics-stack.sh` already makes and parses the exact HTTP calls needed (`curl http://127.0.0.1:9090/api/v1/targets`, `/-/healthy`, `/api/v1/query`) — as a bash script, not from the Node.js API server, but the pattern is real and directly portable. This is conditionally-real data: it only exists if the operator has opted into the metrics stack. A correct implementation must detect and honestly report that precondition (e.g., a new `unavailable` reason like `"metrics_stack_not_running"`), not assume it's always there.

Full detail in `docs/tabs/SOC.md`.

### 3.10 Diag

Per your direction, this tab is being reconsidered (removed, or restricted to admin/owner access) rather than documented as a stable feature. No architecture doc or implementation prompt produced for it. Noting here only what exists today for completeness: `<pre id="output">` is a raw `JSON.stringify()` dump of `refreshAll()`'s internal state (provider name, per-source status/reason breakdown, ops-health totals), populated by `writeOutput()` — genuinely useful for debugging, not fabricated, but also not designed as an end-user-facing feature (no formatting, no access control, always visible to anyone who can open the addon).

---

## 4. Cross-cutting technical notes (not tied to one tab)

- **`faction-tagger.js`'s `MutationObserver`** (web/faction-tagger.js:58-63) re-scans the *entire* addon DOM (`querySelectorAll("tr, .metric-card, .summary-grid, .card, article")` plus a second pass over `td, th, span, .section-heading, h2, h3, .panel-title`) on every batch of DOM mutations, throttled 100ms via `setTimeout`. `refreshAll()` mutates dozens of nodes across up to 9 panels every refresh cycle, so this fires at least once (likely a few times, depending on mutation batching) per refresh. Not currently a measured performance problem (the addon's DOM is small), but it will not scale gracefully if more tabs/rows are added without revisiting this — a future implementer adding significant new DOM (e.g., a large Location marker table) should measure this, or scope the observer to a narrower root/selector.
- **Dead CSS classes**: `.capability-unavailable`, `.capability-partial` (addon.css:213-219) are defined but never applied by any HTML or JS — either wire them up as part of fixing the KPI Capability panel (§3.2), or remove them.
- **No shared "tab implemented via real Core data" indicator convention** exists — each tab's section-copy prose independently describes its own status in freehand English (e.g., "Fine-grained activity windows... require ops.activity.summary (planned)" — a sentence that is now stale on the Activity tab, since that action is live). A consistent, single-source-of-truth status badge (driven by the same `SourceResult.status` already available) would prevent this kind of prose drift going forward — see the Phase 4 automation idea in `docs/GAP-ANALYSIS-RESOLUTION-2026-07-23.md` §3 for the closely-related "README bridge-action list drift" check; the same mechanism could drive per-tab status text too.

---

## 5. Deliverables produced alongside this review

- `docs/tabs/*.md` — one architecture document per tab (9 of 10; Diag excluded per explicit direction), each containing: current implementation (verified file:line citations), current data-flow diagram (text form), findings specific to that tab, and a recommended design for anything not yet real.
- `docs/prompts/*.md` — one Sonnet-5-consumable implementation prompt per tab, scoped to exactly what's real/buildable per this review (no prompt asks for a field that has no real source — where no real source exists, the prompt says so explicitly and asks for an honest `unavailable` state instead).
