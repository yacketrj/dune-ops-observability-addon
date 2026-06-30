# RFC Addendum: Addon-First Observability and KPI Analytics

Status: accepted for addon repository planning
Date: 2026-06-30

## Summary

User-facing observability and KPI analytics should be implemented addon-first.

The addon repository owns UI, dashboard flow, read-only analytics views, schema capability views, release packaging, and addon-specific issues and pull requests.

The WSL/core repository owns only bridge actions, bridge permissions, Console API changes, Prometheus endpoints, Docker runtime support, and upstream pull requests.

## Initial addon milestones

1. Addon foundation.
2. Bridge health panel.
3. Player summary panel.
4. KPI capability panel.
5. Read-only KPI panels.

## Security position

- Keep the MVP read-only.
- Request narrow permissions only.
- Do not request write permissions for the observability MVP.
- Prefer bridge-mediated access over direct browser access to backend services.
