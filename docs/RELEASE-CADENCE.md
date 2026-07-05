# Release Cadence

> See also: [ROADMAP.md](ROADMAP.md) — unified overview, dependency graph, full release table
> Related: [release-standard.md](../ops-observability/roadmap/release-standard.md) — 5-gate release process

## Policy

Use three tracks:

1. Internal feature PRs in this addon repo.
2. Core infrastructure PRs in `yacketrj/dune-awakening-selfhost-docker` (fork).
3. External release train PRs to the upstream addon catalog.

Keep using PRs for addon updates. Internal addon work should go through focused PRs with checks.

This preserves an audit trail through PR discussion, diffs, review state, check results, and squash commits.

Do not send an upstream catalog PR for every internal change.

## Cadence

- Internal addon PRs: small, focused, and frequent.
- Core releases: batched by capability block (R1→R5, see [ROADMAP.md](ROADMAP.md)).
- Public releases: milestone based.
- Normal public release window: no more than once every two weeks.
- Upstream catalog PRs: one PR per released addon version or meaningful feature batch.
- Emergency patch: allowed for broken package, invalid manifest, security issue, or severe runtime failure.

## Core Release Alignment

Core releases provide infrastructure and bridge actions the addon depends on. Each Core release is tracked in the fork repo (`yacketrj/dune-awakening-selfhost-docker`) with upstream PRs to `Red-Blink/dune-awakening-selfhost-docker`.

| Core Release | Tag | Addon Impact |
|---|---|---|
| R1 (done) | `v1.3.x` (upstream) | Metrics stack foundation |
| R2 | `core-metrics-r2` | Enables v0.4 via Grafana + Alertmanager |
| R3 | `core-metrics-r3` | Required for v1.0 (`metrics.query` bridge) |
| R4 | `core-soc-r4` | Required for v1.0 (persistent rate limits + CSP) |
| R5 | `core-ops-r5` | Post-v1.0 enhancements (SLO/SLI) |

Upstream Core PRs must be narrow, evidence-backed, and not contain internal roadmap or private workflow content.

## Tagging Convention

| Context | Prefix | Pattern | Examples | Repository |
|---|---|---|---|---|
| Core feature merges | `core-{domain}-r{n}` | Release batch tag | `core-metrics-r2` | Core fork |
| Core feature branches | `feature/{area}` | Dev branch | `feature/console-exporter` | Core fork |
| Addon releases | `v{major}.{minor}.{patch}` | Semver tag | `v0.4.0`, `v1.0.0` | Addon |
| Addon RCs | `v{major}.{minor}.{patch}-rc{n}` | Pre-release tag | `v0.4.0-rc1` | Addon |
| Addon features | `feature/{area}` | Dev branch | `feature/player-activity` | Addon |
| Evidence archive | `evidence/v{major}.{minor}.{patch}` | Evidence tag | `evidence/v0.4.0` | Addon |
| Immutable snapshots | `preserve/{desc}` | Restore point | `preserve/pre-db-discovery` | Addon |

**Tag creation workflow**:
1. All tests + security scans pass on the feature branch
2. Feature branch merged to main
3. Release evidence assembled (16-file bundle per release-standard.md)
4. Tag created: `git tag -a v0.4.0 -m "Dune Ops Observability v0.4.0 — Game Activity & Combat"`
5. Tag pushed: `git push origin --tags`
6. Package built (`scripts/package.sh`) → GitHub Release → SHA-256 verified
7. Catalog manifest updated in `dune-docker-addons` → upstream PR submitted

## Versioning

Use semantic versioning.

- PATCH: bug fix, package fix, documentation fix, or safe UI correction.
- MINOR: new visible panel, read-only feature, or operator workflow improvement.
- MAJOR: permission expansion, breaking manifest change, or incompatible bridge contract.

## Release gates

A public release requires:

- manifest validation;
- pre-commit checks;
- secret scan;
- static analysis;
- filesystem scan;
- package build;
- browser preview smoke test;
- local Console repo synced to upstream `main` at `/home/darkdante/dune-clean-repro`;
- private Dune Docker Console test with the addon copied into that local Console install;
- real bridge smoke test through the Console Addons page;
- release notes;
- pinned release asset;
- checksum for the uploaded release asset.

## Private Console test

Use `/home/darkdante/dune-clean-repro` as the local Dune Docker Console test install.

Before testing, ensure the Console repo is on `main` and synced with upstream:

```bash
cd /home/darkdante/dune-clean-repro
git fetch upstream --prune
git switch main
git reset --hard upstream/main
```

Follow the upstream addon template local-development flow before publishing.

For this addon, copy `addon.json` and `web/` into the local Console install under:

```text
/home/darkdante/dune-clean-repro/runtime/addons/installed/dune-ops-observability/
```

Then enable the addon in `/home/darkdante/dune-clean-repro/runtime/addons/state.json`, approve the requested read-only permission, refresh Dune Docker Console, open Addons, and test the addon through the real Console iframe bridge.

This private Console test does not require the community addon index.

## Upstream rule

Open an upstream catalog PR only after:

- the tag exists;
- the release asset exists;
- the uploaded asset checksum is verified;
- the private Console test has passed;
- the manifest URL, download URL, version, and checksum are final.

## Next train

The next normal release should bundle A3, A4, and A5 as `v0.2.0` after final validation.
