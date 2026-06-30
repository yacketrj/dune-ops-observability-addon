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

## Data providers

The addon uses `sample` data when opened directly in a browser and the Dune Docker Console `bridge` provider when loaded inside the Console iframe.

The bridge remains the default supported production path. Direct localhost/browser API calls are intentionally not part of the MVP provider set.

See `docs/DATA-PROVIDERS.md`.

## Local validation

```bash
node scripts/validate.js
```

## Shift-left security

Install local hooks before development:

```bash
sudo apt update
sudo apt install -y pipx
pipx ensurepath
pipx install pre-commit
pre-commit install
pre-commit run --all-files
```

See `docs/SHIFT-LEFT-SECURITY.md` for the local hook and CI policy.

## Community addon index

After validated release output exists, submit the listing PR to `Red-Blink/dune-docker-addons` with summary, need, test output, and security output.

See `docs/COMMUNITY-INDEX-PR.md`.
