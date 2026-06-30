# Database Event Inventory Procedure

This procedure defines the required PostgreSQL review before adding advanced game telemetry metrics.

The goal is to identify every table, view, column, and timestamped record that can support read-only player, economy, combat, resource, NPC, location, progression, and operational metrics.

## Scope

Inventory the running PostgreSQL database before implementing metrics that depend on stored game events or operational records.

Do not infer coverage from UI assumptions. Use database evidence.

## Required inventory output

The database review must produce:

1. List of schemas.
2. List of base tables and views.
3. List of columns with data types.
4. Primary keys, foreign keys, and indexed columns.
5. Timestamp columns and retention windows.
6. Tables that appear to contain event, audit, activity, kill, death, economy, inventory, resource, gathering, crafting, NPC, location, or session data.
7. Estimated row counts for candidate event tables.
8. Sample-safe column summaries that do not expose secrets or private player data.
9. Candidate metrics mapped to source tables and columns.
10. Fields that are not available and require upstream support.

## Read-only SQL inventory

Run these queries with a read-only database user.

### Schemas

```sql
select schema_name
from information_schema.schemata
where schema_name not in ('pg_catalog', 'information_schema')
order by schema_name;
```

### Tables and views

```sql
select table_schema, table_name, table_type
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name;
```

### Columns

```sql
select table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
order by table_schema, table_name, ordinal_position;
```

### Key relationships

```sql
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
```

### Indexes

```sql
select schemaname, tablename, indexname, indexdef
from pg_indexes
where schemaname not in ('pg_catalog', 'information_schema')
order by schemaname, tablename, indexname;
```

### Candidate event tables by name

```sql
select table_schema, table_name
from information_schema.tables
where table_schema not in ('pg_catalog', 'information_schema')
  and lower(table_name) ~ '(event|audit|activity|log|session|player|death|kill|npc|econom|market|trade|wallet|currency|inventory|item|resource|ore|gather|craft|location|zone|map|base|guild|faction)'
order by table_schema, table_name;
```

### Candidate event columns by name

```sql
select table_schema, table_name, column_name, data_type
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
  and lower(column_name) ~ '(event|audit|activity|timestamp|created|updated|player|steam|death|kill|npc|econom|market|trade|wallet|currency|inventory|item|resource|ore|gather|craft|location|zone|map|base|guild|faction|quantity|amount)'
order by table_schema, table_name, ordinal_position;
```

### Approximate row counts

```sql
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
```

## Metric-source mapping

For each proposed metric, document:

- metric name;
- metric category;
- source schema and table;
- required columns;
- aggregation window;
- cardinality risk;
- privacy risk;
- permission or bridge impact;
- release class.

## Implementation rule

No economy, combat, death, NPC, resource, crafting, inventory, market, or location metric should be implemented until its source table and required columns are confirmed through this inventory.
