-- Safe aggregate query candidates for Release 0.2 telemetry discovery.
-- These queries are candidates only; they must still pass E2E and privacy gates before promotion.

-- Player status summary: low-cardinality aggregate state only.
select
  online_status::text as online_status,
  life_state::text as life_state,
  character_state::text as character_state,
  count(*)::bigint as players
from dune.player_state
group by online_status::text, life_state::text, character_state::text
order by players desc, online_status, life_state, character_state;

-- Farm state summary: rewritten from row-level output to aggregate-only output.
select
  count(*)::bigint as farms,
  count(*) filter (where ready)::bigint as ready_farms,
  count(*) filter (where alive)::bigint as alive_farms,
  coalesce(sum(connected_players), 0)::bigint as connected_players,
  coalesce(sum(incoming_s2s_connections), 0)::bigint as incoming_s2s_connections,
  coalesce(sum(outgoing_s2s_connections), 0)::bigint as outgoing_s2s_connections
from dune.farm_state;
