# Implementation Prompt — Inventory tab

You are a senior full-stack engineer implementing real backing data for the "Inventory" tab of `yacketrj/dune-ops-observability-addon`, currently fully unavailable. Read `docs/tabs/INVENTORY.md` in full before writing any code — it contains verified evidence and a query sketch; this prompt tells you how to execute and verify it, not what to build from scratch.

## What you're building on (verified, not in dispute)

`opsProvider.js`'s own code comment in `dune-awakening-selfhost-docker` claims "no backing query exists anywhere in this codebase" for inventory — **this claim is wrong, and you should not trust it or propagate it further.** Real, live, already-used aggregate storage data exists: `duneDb.listStorage(db)` (`console/api/src/duneDb.js`, currently around line 2563), used today by the Console's own `/api/storage` route. It returns one row per storage container: `{id, name, class, map, item_count, owner_name}`.

What does **not** exist: a global "items grouped by template" aggregate (only per-player, via `playerInventory(db, id)`), and any real "total items crafted" counter (only per-player recipe-*unlock* tracking exists, which is not the same thing).

## Hard constraints

- **Do not fabricate `totalCrafted`.** No real source exists for this field (verified via an exhaustive keyword search across `console/api/src/duneDb.js` for crafting-count/event tables — none found). It must be returned as `null` and rendered as `"unavailable"`/`"—"` by the addon, never estimated from recipe-unlock counts, item counts, or any other proxy. If you find a real source this review's search missed, that's a legitimate, welcome correction — but verify it directly (confirm the table/column actually exists and actually counts crafted items, not something adjacent) before using it, don't assume a plausible-sounding table name is the right one.
- **Reuse `listStorage(db)` rather than duplicating its query.** `totalInventories` is directly `listStorage(db).rows.length` — call the existing function, don't reimplement its SQL.
- **Follow the exact Phase-1 wiring pattern** already used for the four live `ops.*.summary` actions: new query function in `duneDb.js` following the `tableExists`/schema-discovery convention every other `addonOps*` function uses; `opsInventoryProvider(config, db)` in `opsProvider.js` changed from `(config, db) { return opsPlaceholder("inventory"); }` to `{ const result = await addonOpsInventorySummary(db); return { ok: true, result }; }`; reuse `requireDiscordBotToken` auth (already in place at the `routes.js` dispatch level) — do not add a new permission check.
- **This is cross-repo work.** The query function belongs in `dune-awakening-selfhost-docker`; nothing changes in `yacketrj/dune-ops-observability-addon` itself for this tab, since `renderInventory()` already correctly consumes the `SourceResult` envelope and needs no changes — only the *provider* (in the other repo) goes from placeholder to real.

## Implementation steps

1. In `dune-awakening-selfhost-docker`, sync `main`, create a feature branch.
2. Write `addonOpsInventorySummary(db)` in `duneDb.js`, using `docs/tabs/INVENTORY.md` §3.2's sketch as a starting point — but verify every join condition and column name directly against a real or realistic test database before considering it correct; the sketch is explicitly flagged as illustrative and unverified in that doc. Decide and justify a sane `LIMIT` for the `itemsByTemplate` result set (the sketch uses 50 — confirm this is reasonable, not arbitrary).
3. Consider enriching `itemsByTemplate` with human-readable names via the existing `adminItemMetadata()` lookup (`duneDb.js`, currently around line 2779) — check whether `playerInventory(db, id)` already does this (it does, for per-player results) and follow the same pattern for consistency, but this is a nice-to-have, not required for correctness.
4. Wire `opsInventoryProvider(config, db)` to call your new function, matching the exact `{ ok: true, result }` shape the four already-live providers use.
5. Add tests to `dune-awakening-selfhost-docker`'s own `console/api/test/` suite (`node --test`) covering: the function returns real, correctly-shaped data when the underlying tables have rows; it degrades to an honest empty/zero shape (not a placeholder) when `dune.items`/`dune.placeables` don't exist in a given install's schema (matching every other `addonOps*` function's pattern); `totalCrafted` is always `null`, never a guessed number.
6. Update `console/api/test/discordAdapter.test.js`'s live/planned route classification test (see the precedent already set in Phase 1's PR for the other four actions — the test asserting `ops/inventory` is in `plannedRoutes` needs to move to asserting it's in `liveRoutes`, following exactly how the other four routes were migrated).

## Verification standard

- Verify against a real or realistic database if one is reachable in your environment — do not rely on unit tests with mocked data alone for this, since the entire point is confirming the query is correct against real schema shapes, not just that the code compiles.
- Run this repository's own full test suite before considering the change done.
- Confirm `totalCrafted` is `null` in every test case, including the "happy path" one — if it's ever a number in a test, that's a bug in your own test, not a feature.

## Deliverable

A single draft PR in `dune-awakening-selfhost-docker`, following that repository's existing PR conventions (test output, security-scan output, explicit note that this adds no new auth mechanism or write capability — it's a new read-only query wired to an existing auth path). No changes needed in `yacketrj/dune-ops-observability-addon` itself.
