# Metric Discovery Findings

This note summarizes the first focused aggregate discovery run against the `dune` database.

## Database state

- Active database: `dune`.
- Active database user: `dune`.
- Current event volume is low.
- `game_events` and `event_log` currently contain zero rows.

## Confirmed enum signals

The database exposes useful enum labels for player and operations metrics:

- `playerconnectionstatus`: `Offline`, `LoggingOut`, `Online`.
- `playerlifestate`: `Alive`, `Dead`, `DeadByCoriolis`, `DeadBySandworm`.
- `characterstate`: `Active`, `Deleted`.
- `specializationtracktype`: `Crafting`, `Gathering`, `Exploration`, `Combat`, `Sabotage`.
- `itemtrackingfunctiontype`: save, update, delete, move, and merge item operations.
- `cheat_type_enum`: includes duplicate-item, negative-Solari, forced-respawn, death, and undermesh signals.
- `logcategorytype`, `logmessagetype`, and `logfunctiontype`: currently focused on Solari balance changes.

## Current data counts

High-value populated tables in the discovery run:

- `items`: 79 rows.
- `player_markers`: 41 rows.
- `markers`: 37 rows.
- `inventories`: 34 rows.
- `resourcefield_state`: 27 rows.
- `actors`: 10 rows.
- `spicefield_types`: 4 rows.
- `encrypted_player_state`: 3 rows.
- `farm_state`: 2 rows.
- `map_areas`: 2 rows.
- `player_state`: 1 row.
- `player_virtual_currency_balances`: 1 row.
- `spicefield_server_availability`: 1 row.

Zero-row tables in the run include:

- `game_events`.
- `event_log`.
- `dune_exchange_orders`.
- `dune_exchange_fulfilled_orders`.
- `dune_exchange_users`.
- `item_operations_staging_table`.
- `landsraad_task_progress`.
- `guilds` and `guild_members`.

## Metrics that can be implemented immediately

### OPS health

Use `farm_state` for:

- farm/server readiness;
- farm/server alive state;
- connected players;
- incoming and outgoing server-to-server connections;
- map coverage by server.

### Player activity

Use `player_state` and `encrypted_player_state` for:

- online/offline status;
- life state;
- character state;
- last avatar activity;
- last login time;
- death-state classification.

### Inventory and resources

Use `items`, `inventories`, and `resourcefield_state` for:

- item count by template;
- total stack size by template;
- visible resource holdings such as SolarisCoin, PlantFiber, ScrapMetal, Stone, Oil, and AzuriteOre;
- resource field count by map and field kind;
- remaining resource-field value.

### Spicefield state

Use `spicefield_types` and `spicefield_server_availability` for:

- spicefield spawn activity;
- configured active and primed limits;
- current active and primed counts;
- field type by map.

### Location and marker state

Use `markers`, `player_markers`, `map_areas`, and `map_names` for:

- marker counts by map and dimension;
- player marker discovery levels;
- player marker discovery methods;
- map area discovery state.

## Metrics blocked by missing current events

These remain roadmap items until populated rows or event mappings exist:

- NPC kills.
- Player kill/death event timelines.
- Most killed NPCs.
- Gathering event timelines.
- Exchange trade volume.
- Fulfilled market orders.
- Dungeon completion trends.
- Landsraad progress trends.
- Event log error/degradation analysis.

## Release recommendation

Implement next in this order:

1. `v0.3.0`: OPS health from `farm_state` plus player-state summary.
2. `v0.4.0`: inventory/resource/spicefield aggregate panels.
3. `v0.5.0`: marker/location aggregate panels.
4. `v0.6.0`: economy panels after exchange tables contain rows.
5. `v0.7.0`: combat/NPC/death panels after `game_events`, `event_log`, or related tables prove event mappings.

## Follow-up discovery

Run the focused discovery script again after a live play session with:

- player login/logout;
- death and respawn;
- NPC kill;
- resource gathering;
- item movement;
- market listing or purchase;
- dungeon or contract activity.

That run should identify which event tables populate during actual gameplay.
