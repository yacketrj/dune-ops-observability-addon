-- Focused aggregate metric discovery for the Dune database.
-- Run with a read-only database user.
-- This script reports aggregate counts and metadata only.

\pset pager off

\echo '== Active database =='
select current_database() as database_name, current_user as user_name;

\echo '== User-defined enum labels =='
select
  n.nspname as schema_name,
  t.typname as type_name,
  e.enumlabel as enum_label,
  e.enumsortorder as enum_sort_order
from pg_type t
join pg_enum e on e.enumtypid = t.oid
join pg_namespace n on n.oid = t.typnamespace
where n.nspname not in ('pg_catalog', 'information_schema')
order by n.nspname, t.typname, e.enumsortorder;

\echo '== High-value table row counts =='
select table_name, count_estimate
from (
  select 'dune.player_state' as table_name, count(*)::bigint as count_estimate from dune.player_state
  union all select 'dune.encrypted_player_state', count(*)::bigint from dune.encrypted_player_state
  union all select 'dune.actors', count(*)::bigint from dune.actors
  union all select 'dune.farm_state', count(*)::bigint from dune.farm_state
  union all select 'dune.game_events', count(*)::bigint from dune.game_events
  union all select 'dune.event_log', count(*)::bigint from dune.event_log
  union all select 'dune.items', count(*)::bigint from dune.items
  union all select 'dune.inventories', count(*)::bigint from dune.inventories
  union all select 'dune.item_operations_staging_table', count(*)::bigint from dune.item_operations_staging_table
  union all select 'dune.dune_exchange_orders', count(*)::bigint from dune.dune_exchange_orders
  union all select 'dune.dune_exchange_fulfilled_orders', count(*)::bigint from dune.dune_exchange_fulfilled_orders
  union all select 'dune.dune_exchange_users', count(*)::bigint from dune.dune_exchange_users
  union all select 'dune.player_virtual_currency_balances', count(*)::bigint from dune.player_virtual_currency_balances
  union all select 'dune.resourcefield_state', count(*)::bigint from dune.resourcefield_state
  union all select 'dune.spicefield_types', count(*)::bigint from dune.spicefield_types
  union all select 'dune.spicefield_server_availability', count(*)::bigint from dune.spicefield_server_availability
  union all select 'dune.guilds', count(*)::bigint from dune.guilds
  union all select 'dune.guild_members', count(*)::bigint from dune.guild_members
  union all select 'dune.landsraad_task_progress', count(*)::bigint from dune.landsraad_task_progress
  union all select 'dune.player_markers', count(*)::bigint from dune.player_markers
  union all select 'dune.markers', count(*)::bigint from dune.markers
  union all select 'dune.map_areas', count(*)::bigint from dune.map_areas
) s
order by count_estimate desc, table_name;

\echo '== Player status summary =='
select
  online_status::text as online_status,
  life_state::text as life_state,
  character_state::text as character_state,
  count(*)::bigint as players
from dune.player_state
group by online_status::text, life_state::text, character_state::text
order by players desc, online_status, life_state, character_state;

\echo '== Farm state summary =='
select server_id, farm_id, map, ready, alive, connected_players, incoming_s2s_connections, outgoing_s2s_connections
from dune.farm_state
order by connected_players desc, server_id;

\echo '== Game event type counts =='
select event_type, player_facing_event, map, count(*)::bigint as events
from dune.game_events
group by event_type, player_facing_event, map
order by events desc, event_type, map
limit 100;

\echo '== Game event custom data keys =='
select key, count(*)::bigint as rows_with_key
from dune.game_events, lateral jsonb_object_keys(custom_data) as key
where custom_data is not null
group by key
order by rows_with_key desc, key
limit 100;

\echo '== Event log category counts =='
select category::text as category, message::text as message, function_name::text as function_name, count(*)::bigint as events
from dune.event_log
group by category::text, message::text, function_name::text
order by events desc, category, message, function_name
limit 100;

\echo '== Event log meta keys =='
select key, count(*)::bigint as rows_with_key
from dune.event_log, lateral jsonb_object_keys(meta) as key
where meta is not null
group by key
order by rows_with_key desc, key
limit 100;

\echo '== Item template summary =='
select template_id, count(*)::bigint as item_rows, sum(stack_size)::bigint as total_stack_size
from dune.items
group by template_id
order by total_stack_size desc nulls last, item_rows desc, template_id
limit 100;

\echo '== Item operation function summary =='
select function_name::text as function_name, template_id, count(*)::bigint as operations
from dune.item_operations_staging_table
group by function_name::text, template_id
order by operations desc, function_name, template_id
limit 100;

\echo '== Exchange order summary =='
select template_id, is_npc_order, count(*)::bigint as orders, min(item_price) as min_price, max(item_price) as max_price, avg(item_price)::bigint as avg_price
from dune.dune_exchange_orders
group by template_id, is_npc_order
order by orders desc, template_id
limit 100;

\echo '== Fulfilled exchange order summary =='
select completion_type, count(*)::bigint as orders, sum(stack_size)::bigint as total_stack_size
from dune.dune_exchange_fulfilled_orders
group by completion_type
order by orders desc, completion_type;

\echo '== Currency balance summary =='
select currency_id, count(*)::bigint as holders, min(balance) as min_balance, max(balance) as max_balance, avg(balance)::bigint as avg_balance, sum(balance)::bigint as total_balance
from dune.player_virtual_currency_balances
group by currency_id
order by total_balance desc nulls last, currency_id;

\echo '== Resource field summary =='
select map, dimension_index, field_kind_id, count(*)::bigint as fields, sum(value_remaining)::bigint as total_value_remaining
from dune.resourcefield_state
group by map, dimension_index, field_kind_id
order by fields desc, total_value_remaining desc nulls last, map, dimension_index, field_kind_id;

\echo '== Spice field type summary =='
select map_name, dimension_index, field_type, is_spawning_active, max_globally_active, current_globally_active, max_globally_primed, current_globally_primed
from dune.spicefield_types
order by map_name, dimension_index, field_type;

\echo '== Dungeon completion summary =='
select dungeon_id, difficulty, count(*)::bigint as completions, avg(duration_ms)::bigint as avg_duration_ms, max(players_num) as max_players_num
from dune.dungeon_completion
group by dungeon_id, difficulty
order by completions desc, dungeon_id, difficulty
limit 100;

\echo '== Landsraad progress summary =='
select faction_id, task_id, count(*)::bigint as progress_rows, max(timestamp) as last_progress_time, max(faction_progress) as max_faction_progress, max(guild_progress) as max_guild_progress, max(player_progress) as max_player_progress
from dune.landsraad_task_progress
group by faction_id, task_id
order by last_progress_time desc nulls last, progress_rows desc
limit 100;

\echo '== Marker summary =='
select map_name_id, dimension_index, count(*)::bigint as markers
from dune.markers
group by map_name_id, dimension_index
order by markers desc, map_name_id, dimension_index;

\echo '== Player marker summary =='
select map_name_id, dimension_index, discovery_level, discovery_method, count(*)::bigint as player_markers
from dune.player_markers
group by map_name_id, dimension_index, discovery_level, discovery_method
order by player_markers desc, map_name_id, dimension_index;
