# Workstream Split

## Repository rule

Addon-specific work lives in this repository.

Core bridge/API work and upstream pull requests live in the WSL-focused Dune Docker Console repository.

## Addon repository owns

- addon UI shell;
- operations dashboard panels;
- player summary panels;
- read-only KPI analytics panels;
- schema capability views;
- addon docs;
- addon packaging;
- addon security checks;
- addon issues, branches, and pull requests.

## WSL/core repository owns

- bridge action changes;
- new bridge permissions;
- Console API route changes;
- Prometheus scrape endpoints;
- Docker Compose/runtime exporter work;
- upstream PRs into Red-Blink core repositories.

## Initial addon permissions

```json
{
  "players": ["read"]
}
```

`database:read` is expected later for KPI panels, but it should be added when the first read-only query panel is implemented.
