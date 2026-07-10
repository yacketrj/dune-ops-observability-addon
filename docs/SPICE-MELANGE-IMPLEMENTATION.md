# Spice Melange Tab — Implementation Guide

**Branch**: `addon-main/main`  
**Core PR**: [#68](https://github.com/Red-Blink/dune-awakening-selfhost-docker/pull/68) — `ops.resources.summary` bridge action  
**Addon commits**: `3a63e0e` through `a46b45b` (6 commits)  

---

## 1. Architecture Overview

The Spice Melange tab displays spice field data from the Dune game database. Data flows through three layers:

```
PostgreSQL                    Core Bridge                  Addon UI
──────────                    ───────────                  ────────
resourcefield_state    →    ops.resources.summary    →    renderResources()
spicefield_types                (ops:read)                 renderSpiceGroups()
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| Spice-only filter (`field_kind_id = 1`) | Ore types have no subtype column. Only spice field sizes are queryable |
| Per-map summary boxes | Eliminated duplicate map listings (HaggaBasin appeared twice in flat tables) |
| Subselect for spice value | Joining `resourcefield_state` with `spicefield_types` caused duplicate rows on GROUP BY |
| Dynamic rendering in JS | Map groups generated from bridge response rather than hardcoded HTML tables |

---

## 2. Database Schema

Two tables power the spice data:

### resourcefield_state
```sql
\d dune.resourcefield_state

     Column      |       Type       
-----------------+------------------
 field_id        | bigint           -- unique field identifier
 map             | text             -- map name (HaggaBasin, DeepDesert)
 dimension_index | integer          -- dimension index (0 or 1)
 value_remaining | bigint           -- harvestable spice left
 field_kind_id   | smallint         -- 0=Ore, 1=Spice
 spawn_time      | double precision
```

### spicefield_types
```sql
\d dune.spicefield_types

         Column          |  Type    
-------------------------+----------
 spicefield_type_id      | integer  -- auto-generated PK
 field_type              | text     -- Small, Medium, Large
 map_name                | text     -- map name
 dimension_index         | integer
 is_spawning_active      | boolean
 max_globally_active     | integer  -- config cap
 current_globally_active | integer  -- current spawn count
 max_globally_primed     | integer
 current_globally_primed | integer
 global_spawn_weight     | real
```

**Note**: `resourcefield_state` and `spicefield_types` are NOT directly joinable on field type — they use different identifiers (`field_kind_id` vs `field_type`). A direct `JOIN ON map = map_name AND field_kind_id = 1` causes a cartesian product, producing duplicate rows on GROUP BY. The fix uses subselects (see Section 3.2).

---

## 3. Core Bridge Action

### 3.1 Bridge Route

File: `console/api/src/server.js`

```js
if (action === "ops.resources.summary") {
  const addon = assertInstalledAddonPermission(config, id, "ops:read");
  const result = await duneDb.addonOpsResourcesSummary(db);
  audit(config, req, "addons.bridge", { id: addon.id, action, permission: addon.permission, ok: true });
  return json(res, 200, { ok: true, result });
}
```

Pattern matches all existing bridge actions: permission check → query → audit → JSON response.

### 3.2 Query Function

File: `console/api/src/duneDb.js`

```js
export async function addonOpsResourcesSummary(db) {
  // Gate 1: Table must exist
  if (!(await tableExists(db, "resourcefield_state"))) return emptyResourcesSummary();

  // Gateway query: spice-only totals
  const result = await db.query(`
    select count(*)::int as total_fields,
           coalesce(sum(value_remaining), 0)::bigint as total_value
    from dune.resourcefield_state
    where field_kind_id = 1`);

  const r = result.rows?.[0] || {};

  // By-map breakdown (spice only)
  let resourcesByMap = [];
  try {
    const mapResult = await db.query(`
      select map,
             count(*)::int as fields,
             coalesce(sum(value_remaining), 0)::bigint as total_value
      from dune.resourcefield_state
      where field_kind_id = 1
      group by map
      order by fields desc`);
    resourcesByMap = mapResult.rows || [];
  } catch { }

  // Size breakdown: uses subselects to avoid join duplicate rows
  let spiceFieldsBySize = [];
  try {
    const spiceExists = await tableExists(db, "spicefield_types");
    if (spiceExists) {
      const spiceResult = await db.query(`
        select sft.field_type as size,
               sft.map_name as map,
               coalesce(sum(sft.current_globally_active), 0)::int as currently_active,
               coalesce(sum(sft.max_globally_active), 0)::int as max_active,
               (select coalesce(sum(value_remaining), 0)::bigint
                from dune.resourcefield_state rfs
                where rfs.map = sft.map_name and rfs.field_kind_id = 1) as total_value,
               (select count(*)::int
                from dune.resourcefield_state rfs
                where rfs.map = sft.map_name and rfs.field_kind_id = 1) as active_fields
        from dune.spicefield_types sft
        where sft.is_spawning_active = true
        group by sft.field_type, sft.map_name
        order by sft.map_name, sft.field_type`);
      spiceFieldsBySize = spiceResult.rows || [];
    }
  } catch { }

  return {
    totalFields: Number(r.total_fields || 0),
    totalValueRemaining: Number(r.total_value || 0),
    resourcesByMap,
    spiceFieldsBySize
  };
}
```

**Critical fix**: The original query used `LEFT JOIN resourcefield_state ON map = map_name AND field_kind_id = 1`, which caused duplicate rows. HaggaBasin showed 25/25 active instead of 5/5. The fix uses **correlated subselects** — each `field_type` row independently queries `resourcefield_state` via a subquery, eliminating the cartesian product.

### 3.3 Response Schema

```json
{
  "ok": true,
  "result": {
    "totalFields": 5,
    "totalValueRemaining": 25000,
    "resourcesByMap": [
      { "map": "HaggaBasin", "fields": 5, "totalValue": 25000 }
    ],
    "spiceFieldsBySize": [
      {
        "map": "HaggaBasin",
        "size": "Small",
        "active_fields": 5,
        "total_value": 25000,
        "currently_active": 5,
        "max_active": 5
      },
      {
        "map": "DeepDesert",
        "size": "Small",
        "active_fields": 0,
        "total_value": 0,
        "currently_active": 0,
        "max_active": 120
      }
    ]
  }
}
```

---

## 4. Addon Data Provider

File: `web/data-providers.js`

The bridge provider was already wired to call `ops.resources.summary`:

```js
async getResources() {
  return await bridgeRequest("ops.resources.summary");
}
```

Sample data for preview mode:

```js
const sampleResources = {
  totalFields: 5,
  totalValueRemaining: 25000,
  resourcesByMap: [
    { map: "HaggaBasin", fields: 5, totalValue: 25000 }
  ],
  spiceFieldsBySize: [
    { map: "HaggaBasin", size: "Small", active_fields: 5, total_value: 25000, currently_active: 5, max_active: 5 },
    { map: "DeepDesert",  size: "Small", active_fields: 0, total_value: 0, currently_active: 0, max_active: 120 }
  ]
};
```

---

## 5. Addon UI Implementation

### 5.1 Tab Navigation

File: `web/index.html`

The tab button in the nav bar:
```html
<button class="tab" data-tab="spice">Spice Melange</button>
```

The tab content wrapper:
```html
<div class="tab-content" data-tab="spice">
  <!-- spice panels -->
</div>
```

### 5.2 Tab Card Structure

```html
<section class="card">
  <div class="section-heading">
    <p class="eyebrow">v0.5.0</p>
    <h2>Spice Melange</h2>
    <p class="provider-label">ops.resources.summary</p>
  </div>
  <p class="section-copy">Spice field inventory by size and map, with value remaining and spawn capacity.</p>
  
  <!-- Dynamic content rendered by JS -->
  <div id="res-spice-groups"></div>
</section>
```

**Design note**: The per-map summary boxes and size tables are generated dynamically in JavaScript, not hardcoded in HTML. This eliminates the duplicate HaggaBasin listing that appeared when both a "Spice by Map" table and "Spice by Size" table showed the same data.

### 5.3 JavaScript Rendering

File: `web/addon.js`

#### DOM References
```js
const resSpiceGroupsEl = document.querySelector("#res-spice-groups");
```

#### renderSpiceGroups() — Per-map rendering

```js
function renderSpiceGroups(data) {
  if (!resSpiceGroupsEl) return;
  while (resSpiceGroupsEl.firstChild) resSpiceGroupsEl.removeChild(resSpiceGroupsEl.firstChild);

  var byMap = data.resourcesByMap || [];
  var bySize = data.spiceFieldsBySize || [];

  // Index size data by map for grouping
  var sizeByMap = {};
  bySize.forEach(function (f) {
    var mapName = f.map || "Unknown";
    if (!sizeByMap[mapName]) sizeByMap[mapName] = [];
    sizeByMap[mapName].push(f);
  });

  // Iterate maps alphabetically
  Object.keys(mapFields).concat(Object.keys(sizeByMap))
    .filter(function (v, i, a) { return a.indexOf(v) === i; })
    .sort()
    .forEach(function (mapName) {
      
      // 1. Per-map summary grid
      var grid = document.createElement("div");
      grid.className = "summary-grid";
      grid.style.cssText = "margin-bottom:8px";

      // Active Fields box
      var card1 = document.createElement("article");
      card1.className = "metric-card";
      card1.innerHTML = '<span class="metric-label">' + mapName + ' — Active</span><strong>' + fields + '</strong>';

      // Remaining box
      var card2 = document.createElement("article");
      card2.className = "metric-card";
      card2.innerHTML = '<span class="metric-label">' + mapName + ' — Remaining</span><strong>' + value + '</strong>';

      grid.appendChild(card1);
      grid.appendChild(card2);
      resSpiceGroupsEl.appendChild(grid);

      // 2. Size table for this map
      var sizes = sizeByMap[mapName];
      if (!sizes || !sizes.length) return;

      // Sort: Small → Medium → Large
      sizes.sort(function (a, b) {
        var order = { "Small": 1, "Medium": 2, "Large": 3 };
        return (order[a.size] || 99) - (order[b.size] || 99);
      });

      var table = document.createElement("table");
      table.setAttribute("aria-label", "Spice fields for " + mapName);

      // Table header
      var thead = document.createElement("thead");
      var tr = document.createElement("tr");
      ["Size", "Active", "Remaining", "Cap"].forEach(function (h) {
        var th = document.createElement("th");
        th.setAttribute("scope", "col");
        th.textContent = h;
        tr.appendChild(th);
      });
      thead.appendChild(tr);
      table.appendChild(thead);

      // Table body
      var tbody = document.createElement("tbody");
      sizes.forEach(function (s) {
        appendRow(tbody, [
          s.size || "?",
          s.active_fields ?? 0,
          s.total_value ?? 0,
          (s.currently_active ?? 0) + " / " + (s.max_active ?? 0)
        ]);
      });
      table.appendChild(tbody);
      resSpiceGroupsEl.appendChild(table);
    });
}
```

#### renderResources() — Entry point

```js
function renderResources(data) {
  var snapshot = data || {};
  renderSpiceGroups(snapshot);
}
```

Called from `refreshAll()` which fetches all bridge actions in parallel via `Promise.allSettled()`.

---

## 6. Evolution of the Tab

### Phase 1: Original "Resources" tab (v0.4.0)

Showed three tables:
- Summary grid: Total Fields, Value Remaining
- Resources by Type: Ore (26 fields) and Spice (5 fields)
- Resources by Map: HaggaBasin with counts

### Phase 2: Rename to "Spice Melange" (v0.4.1)

- Removed "Ore" category (no useful subtype data)
- Removed Resources by Type table entirely
- Tab renamed: `data-tab="spice"`
- Added Spice Fields by Size table (Small/Medium/Large per map)

### Phase 3: Per-map grouping + subselect fix

- Removed flat "Spice by Map" table (duplicate listing)
- Added per-map summary boxes (Active + Remaining per map)
- Grouped size tables under map headers
- Fixed duplicate row issue: subselects instead of JOIN
- Sorted sizes Small → Medium → Large

---

## 7. Key Commits

| Commit | Message |
|---|---|
| `3a63e0e` | feat: group spice fields under per-map headers instead of flat table |
| `fff7a06` | feat: sort spice fields Small → Medium → Large within each map group |
| `a46b45b` | feat: per-map spice summary boxes, remove duplicate map table |
| `4528c76` | feat: rename Resources tab to Spice Melange, clarify column labels |
| `4abc77a` | fix: spice field query uses subselect to avoid join duplicate rows |
| `dcff28b` | fix: filter resource summary queries to spice only (field_kind_id=1) |

Core PR #68 commits:
| `38bb628` | feat: add ops.activity/resource/combat bridge actions + death poller |
| `b037f7a` | feat: add spice field value by size breakdown via join with resourcefield_state |
| `dcff28b` | fix: filter resource summary queries to spice only (field_kind_id=1) |

---

## 8. How to Recreate

### Step 1: Core Bridge Action

Create `ops.resources.summary` bridge route in `server.js` following the pattern above (Section 3.1). Add `addonOpsResourcesSummary()` to `duneDb.js` (Section 3.2). The subselect approach is critical — do NOT use a direct JOIN.

### Step 2: Addon Data Provider

Wire `getResources()` to call `bridgeRequest("ops.resources.summary")`. Provide sample data in `sampleResources` for preview mode.

### Step 3: Addon HTML

Add the tab button (`data-tab="spice"`) and tab content div. The content area only needs `<div id="res-spice-groups"></div>` — all tables are generated dynamically.

### Step 4: Addon JS

Add `renderSpiceGroups()` function (Section 5.3) and call it from `renderResources()`. The function dynamically builds per-map summary grids and size tables, eliminating duplicate data.

### Step 5: Validate

```bash
# Test the bridge action
curl -X POST http://127.0.0.1:8088/api/addons/installed/dune-ops-observability/bridge \
  -H "Content-Type: application/json" \
  -d '{"action":"ops.resources.summary"}'

# Run bridge smoke test
bash tests/bridge-smoke-test.sh
```

### Confirmation Query

```sql
SELECT sft.field_type as size, sft.map_name as map,
  coalesce(sum(sft.current_globally_active), 0)::int as currently_active,
  coalesce(sum(sft.max_globally_active), 0)::int as max_active,
  (SELECT coalesce(sum(value_remaining), 0)::bigint
   FROM dune.resourcefield_state rfs
   WHERE rfs.map = sft.map_name AND rfs.field_kind_id = 1) as total_value,
  (SELECT count(*)::int
   FROM dune.resourcefield_state rfs
   WHERE rfs.map = sft.map_name AND rfs.field_kind_id = 1) as active_fields
FROM dune.spicefield_types sft
WHERE sft.is_spawning_active = true
GROUP BY sft.field_type, sft.map_name
ORDER BY sft.map_name, sft.field_type;
```

This should return correct counts — not duplicates. HaggaBasin Small should show `active_fields=5`, not 25.
