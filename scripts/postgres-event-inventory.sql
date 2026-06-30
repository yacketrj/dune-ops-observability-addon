-- PostgreSQL event inventory for Dune Ops Observability.
-- Run with a read-only database user.
-- Do not include sensitive row samples in public issues or pull requests.

\pset pager off

\echo '== Schemas =='
select schema_name
from information_schema.schemata
where schema_name not in ('pg_catalog', 'information_schema')
order by schema_name;

\echo '== Tables and views =='
select table_schema, table_name, table_type
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name;

\echo '== Columns =='
select table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name, ordinal_position;

\echo '== Key relationships =='
select
  tc.table_schema,
  tc.table_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_schema as foreign_table_schema,
  ccu.table_name as foreign_table_name,
  ccu.column_name as foreign_column_name
from information_schema.table_constraints tc
left join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
 and tc.table_schema = kcu.table_schema
left join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name
 and ccu.table_schema = tc.table_schema
where tc.table_schema not in ('pg_catalog', 'information_schema')
order by tc.table_schema, tc.table_name, tc.constraint_type, kcu.column_name;

\echo '== Indexes =='
select schemaname, tablename, indexname, indexdef
from pg_indexes
where schemaname not in ('pg_catalog', 'information_schema')
order by schemaname, tablename, indexname;

\echo '== Candidate event tables by name =='
select table_schema, table_name
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema')
  and lower(table_name) ~ '(event|audit|activity|log|session|player|death|kill|npc|econom|market|trade|wallet|currency|inventory|item|resource|ore|gather|craft|location|zone|map|base|guild|faction)'
order by table_schema, table_name;

\echo '== Candidate event columns by name =='
select table_schema, table_name, column_name, data_type
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
  and lower(column_name) ~ '(event|audit|activity|timestamp|created|updated|player|steam|death|kill|npc|econom|market|trade|wallet|currency|inventory|item|resource|ore|gather|craft|location|zone|map|base|guild|faction|quantity|amount)'
order by table_schema, table_name, ordinal_position;

\echo '== Approximate row counts =='
select
  schemaname,
  relname as table_name,
  n_live_tup as approximate_rows,
  n_dead_tup as approximate_dead_rows,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
from pg_stat_user_tables
order by n_live_tup desc;
