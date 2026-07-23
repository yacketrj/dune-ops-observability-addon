# Tab Architecture — Inventory

**Data-tab attribute**: `inventory`
**HTML**: `web/index.html:487-528`
**Render entry point**: `refreshAll()` → `renderInventory(result)` (`web/addon.js:742`)
**Bridge action**: `ops.inventory.summary` — **not implemented** in `opsProvider.js` (`opsInventoryProvider` returns `opsPlaceholder("inventory")`, `duneDb.js` has no `addonOpsInventorySummary` function).

**This is the highest-value finding in this review**: real, already-used aggregate data exists in Core that is materially close to what this tab needs — it was never connected because nobody looked past the placeholder's comment ("no backing query exists anywhere in this codebase") to check.

---

## 1. Current implementation (verified) — correctly renders unavailable; no data-fabrication risk

`renderInventory()` (`addon.js:742-765`) correctly follows the `SourceResult` contract — with no real backing data, `data-providers.js`'s `bridge.getInventory()` correctly returns `unavailableResult("not_implemented", "ops.inventory.summary")`, and the panel correctly shows the "Not available" note with all three metric cards and both tables cleared. **No changes needed to the rendering layer** — it already does the right thing given no real data. This doc is entirely about *whether real data now exists to wire up*, not about fixing a rendering defect.

## 2. What the addon currently assumes exists (its own sample fixture, `data-providers.js:205-221`)

```js
const sampleInventory = {
  totalItems: 342,
  totalInventories: 18,
  itemsByTemplate: [{ templateId, count, totalStack }, ...],
  totalCrafted: 23,
  storageUsage: [{ inventoryId, itemCount, totalStack }, ...]
};
```

## 3. What real data actually exists in Core (verified directly, this review)

### 3.1 `duneDb.listStorage(db)` — real, live, already used by `/api/storage`

`duneDb.js:2563-2586`. Returns one row per storage container (`dune.placeables` filtered to `building_type in ('SpiceSilo_Placeable','GenericContainer_Placeable','StorageContainer_Placeable','MediumStorageContainer_Placeable')`):

```js
{ id, name, class: building_type, map, item_count, owner_name }
```

This maps closely to the sample fixture's `storageUsage` array shape (`inventoryId` → `id`, `itemCount` → `item_count`, `totalStack` has no direct equivalent — `listStorage` counts distinct items, not summed stack sizes; a `sum(i.stack_size)` addition to the existing query would be a small, real, low-risk change). `totalInventories` (the sample fixture's count of distinct inventories) is directly `listStorage(db).rows.length` — already computable today, from data already being queried, with zero new SQL.

### 3.2 A global "items by template" aggregate does NOT currently exist as a function — but is directly buildable

No existing function groups `dune.items` by `template_id` globally (only per-player, via `playerInventory(db, id)`, `duneDb.js:1689`). A new function, following the exact same schema-discovery pattern every other `addonOps*` function uses, would look like:

```js
export async function addonOpsInventorySummary(db) {
  if (!(await tableExists(db, "items")) || !(await tableExists(db, "placeables"))) {
    return emptyInventorySummary(); // { totalItems: 0, totalInventories: 0, itemsByTemplate: [], totalCrafted: null, storageUsage: [] }
  }
  const totals = await db.query(`
    select count(*)::int as total_items, coalesce(sum(stack_size), 0)::bigint as total_stack
    from dune.items i
    join dune.inventories inv on i.inventory_id = inv.id
    join dune.placeables p on p.id = inv.actor_id
    where p.is_hologram = false and p.owner_entity_id is not null and p.owner_entity_id != 0`);
  const byTemplate = await db.query(`
    select i.template_id::text as template_id, count(*)::int as count, coalesce(sum(i.stack_size), 0)::bigint as total_stack
    from dune.items i
    join dune.inventories inv on i.inventory_id = inv.id
    join dune.placeables p on p.id = inv.actor_id
    where p.is_hologram = false and p.owner_entity_id is not null and p.owner_entity_id != 0
    group by i.template_id
    order by count desc
    limit 50`);
  const storage = await listStorage(db); // reuse existing function directly
  return {
    totalItems: Number(totals.rows[0]?.total_items || 0),
    totalInventories: storage.rows.length,
    itemsByTemplate: byTemplate.rows,
    totalCrafted: null, // see §3.3 — no real source exists for this field
    storageUsage: storage.rows.map(r => ({ inventoryId: r.id, itemCount: r.item_count, totalStack: null }))
  };
}
```

**This query sketch is illustrative, not final** — it needs real verification against a live database before merging (correct join conditions, confirming `dune.items`/`dune.inventories`/`dune.placeables`'s actual column names and relationships exactly as `playerInventory`/`listStorage` already established, and deciding the right `LIMIT` for `itemsByTemplate` to avoid an unbounded result set). The `adminItemMetadata()` lookup (`duneDb.js:2779`) could enrich `itemsByTemplate` with human-readable names, matching the pattern `playerInventory` already uses.

### 3.3 `totalCrafted` — no real source exists

Searched exhaustively for any global "items crafted" counter: only per-player *recipe-unlock* tracking exists (`playerCraftingRecipes`, `duneDb.js:2691` — which recipes a player has access to, not how many items they've crafted). **No real source exists for this field.** It must be reported as permanently `null`/unavailable, not estimated from unlock counts or any other proxy — doing so would reintroduce exactly the fabrication pattern this whole effort has been eliminating elsewhere.

---

## 4. Recommended design

1. **Wire `opsInventoryProvider` to a new `addonOpsInventorySummary(db)` function** (§3.2's sketch, verified and refined against a real database before shipping), following the exact Phase-1 pattern already used for the four live actions: `opsInventoryProvider(config, db) { const result = await addonOpsInventorySummary(db); return { ok: true, result }; }`.
2. **`totalCrafted` stays permanently `null`/unavailable** (§3.3) unless a real crafting-event log is found elsewhere in Core (not found in this review — worth one more targeted search before concluding it's truly absent, since this review's search was keyword-based and could have missed a differently-named table).
3. See `docs/prompts/INVENTORY.md` for the full implementation prompt.
