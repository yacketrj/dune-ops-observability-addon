# Dune Ops Observability Addon

Operations, observability, and read-only KPI analytics addon for Dune Docker Console.

## Repository boundary

Addon work lives here:

- addon UI;
- addon docs;
- addon validation and release packaging;
- addon security gates;
- addon branches, issues, and pull requests;
- read-only player summary and KPI views.

Bridge/API/core work stays in the WSL-focused Dune Docker Console repository.

## Current addon permissions

```json
{
  "players": ["read"]
}
```

`database:read` will be added when the first read-only KPI panel is implemented.

## Local validation

```bash
node scripts/validate.js
```
