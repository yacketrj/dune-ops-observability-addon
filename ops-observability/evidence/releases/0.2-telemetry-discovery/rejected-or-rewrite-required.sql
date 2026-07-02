-- Rejected or rewrite-required SQL from preserved Release 0.2 discovery scripts.
-- These queries must not be promoted to bridge telemetry as written.

-- Farm state summary: rejected as written because it emits row-level server_id, farm_id, and map.
-- Original pattern:
-- select server_id, farm_id, map, ready, alive, connected_players, incoming_s2s_connections, outgoing_s2s_connections
-- from dune.farm_state
-- order by connected_players desc, server_id;
-- Replacement: see safe-query-candidates.sql farm aggregate rewrite.

-- Event log category counts: rejected as written because message and function_name may be high-cardinality or implementation-sensitive.
-- Original pattern:
-- select category::text as category, message::text as message, function_name::text as function_name, count(*)::bigint as events
-- from dune.event_log
-- group by category::text, message::text, function_name::text
-- order by events desc, category, message, function_name
-- limit 100;
-- Replacement candidate: count by category only after category cardinality review.
