# Tab Architecture — Activity

**Data-tab attribute**: `activity`
**HTML**: `web/index.html:292-363`
**Render entry point**: `refreshAll()` → `renderActivity(result)` (`web/addon.js:529`)
**Bridge action**: `ops.activity.summary` — **live**, reachable via both the Discord adapter (`opsProvider.js:51`, `requireDiscordBotToken` auth) and the addon-bridge (`server.js:617`, `assertInstalledAddonPermission`); the addon itself always uses the addon-bridge path.
**Core query**: `duneDb.addonOpsActivitySummary(db)` (`duneDb.js:4339-4477`)

---

## 1. Current implementation (verified) — no defects found

This is one of the four tabs already fully wired to real, live Core data, and it is correctly implemented end-to-end.

### 1.1 Real query behavior, verified

`addonOpsActivitySummary` is schema-adaptive: it checks `columnsFor(db, "player_state")` for the presence of `last_avatar_activity`, `last_returning_player_event_time`, `transfer_count`, and `last_login_time` columns before building its query, degrading gracefully (returning `null` for a field, not `0`) when a given install's schema doesn't have a needed column — this is Core's own honest-unavailability pattern, already correct, and the addon's `renderActivity()` correctly passes those `null`s through as `"—"` (`addon.js:539-543`: `d.activeLast1h !== null ? d.activeLast1h : "—"`).

Guild/faction/map breakdown sub-queries (`guildActivity`, `factionActivity`, `mapActivity`) are each wrapped in their own `try {} catch {}` and independently degrade to `[]` if the relevant tables/columns are missing (`duneDb.js:4386-4461`) — real per-install schema variance, handled correctly, not fabrication.

### 1.2 Rendering, verified

`renderActivity()` (`addon.js:529-563`) correctly follows the `SourceResult` contract: checks `result.status === "unavailable"` first, calls `renderUnavailablePanel()` with the full metric+table element list on that branch, and only reads `result.data` in the live/preview branch. Table rows (guild/faction/map) use safe `?? 0`/`|| "Unknown"` fallbacks — legitimate here because they operate on `result.data`'s *sub-fields* after the top-level availability check already passed, not a false-zero risk (see `docs/DESIGN-REVIEW-2026-07-23.md` §2.1 for why this distinction matters).

### 1.3 Copy accuracy — minor, low-priority note

Section copy (index.html:303): *"Fine-grained activity windows, guild/faction/map distribution require ops.activity.summary (planned)."* This sentence is now **stale** — `ops.activity.summary` is live, not planned, and has been since PR #109 in `dune-awakening-selfhost-docker` (2026-07-22). Not a rendering defect (nothing here misleads about *data*, only about the *feature's own status* in prose), but worth fixing in the same pass as any other copy cleanup — see `docs/DESIGN-REVIEW-2026-07-23.md` §4's "no shared status convention" note, which this sentence is a direct example of.

---

## 2. Data flow (current, verified)

```
Addon (Console iframe) → window.DuneAddon.request("ops.activity.summary")
  → postMessage → Console's addon-bridge handler (server.js:617)
  → assertInstalledAddonPermission(config, id, "ops:read")
  → duneDb.addonOpsActivitySummary(db)
  → { ok: true, result: {totalPlayers, onlinePlayers, activeLast1h, ..., guildActivity, factionActivity, mapActivity} }
→ data-providers.js's bridge.getActivity(): fetchLiveOrUnavailable("ops.activity.summary")
  → SourceResult { status: "live", data: <above>, reason: null, source: null }
→ addon.js's renderActivity(result)
```

---

## 3. Recommended design changes

1. Fix the stale "planned" copy (§1.3) — trivial, ships with any other doc-accuracy pass.
2. No functional changes needed. This tab is a good reference implementation for any future tab following the same `SourceResult` + schema-adaptive-query pattern.
