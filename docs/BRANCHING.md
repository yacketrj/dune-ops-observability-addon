# Branching Policy

> See also: [ROADMAP.md](ROADMAP.md) — unified overview, tagging convention

Addon implementation branches live in this repository.

Core bridge, Console API, runtime, and upstream PR branches live in the core fork repository (`yacketrj/dune-awakening-selfhost-docker`).

## Addon branches

- `feature/addon-foundation`
- `feature/bridge-health-panel`
- `feature/player-summary-panel`
- `feature/kpi-capability-panel`
- `feature/read-only-kpi-panels`
- `feature/player-activity` — v0.4.0: Player Activity & NOC Dashboard
- `feature/noc-dashboard` — merged into v0.4.0 (PR #44)
- `feature/economy-resources` — v0.5.0: Economy & Resources
- `feature/world-assets` — v0.6.0: World & Assets
- `feature/soc-ops-center` — v0.7.0: SOC/OPS Operations Center

## Core branches (fork repository)

These branches live in `yacketrj/dune-awakening-selfhost-docker`:

- `feature/metrics` — R1 Metrics Stack MVP (merged)
- `feature/console-exporter` — R2: Console Exporter + SOC Foundation
- `feature/prometheus-bridge` — R3: Prometheus Bridge API
- `feature/soc-hardening` — R4: SOC Hardening
- `feature/ops-maturity` — R5: Ops Maturity
- `fix/addon-security` — Security fixes (bridge rate limiter, IP allowlisting, CI)

Core feature branches use tags at merge points (e.g. `core-metrics-r2`). Upstream PRs are created from the fork's integration branches.

## Evidence branches

- `evidence/v{major}.{minor}.{patch}` — release evidence archive before tagging
- Example: `evidence/v0.4.0` — stores the 16-file evidence bundle for v0.4.0

## Preserve branches

Use `preserve/*` only for immutable restore points.
- Example: `preserve/pre-db-discovery` — snapshot before database discovery phase for v0.4–v0.6
