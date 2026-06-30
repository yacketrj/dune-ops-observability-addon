# Release Cadence

## Policy

Use two tracks:

1. Internal feature PRs in this addon repo.
2. External release train PRs to the upstream addon catalog.

Keep using PRs for addon updates. Internal addon work should go through focused PRs with checks.

This preserves an audit trail through PR discussion, diffs, review state, check results, and squash commits.

Do not send an upstream catalog PR for every internal change.

## Cadence

- Internal addon PRs: small, focused, and frequent.
- Public releases: milestone based.
- Normal public release window: no more than once every two weeks.
- Upstream catalog PRs: one PR per released addon version or meaningful feature batch.
- Emergency patch: allowed for broken package, invalid manifest, security issue, or severe runtime failure.

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
- private Dune Docker Console test with the addon copied into a local Console install;
- real bridge smoke test through the Console Addons page;
- release notes;
- pinned release asset;
- checksum for the uploaded release asset.

## Private Console test

Follow the upstream addon template local-development flow before publishing.

For this addon, copy `addon.json` and `web/` into the local Console install under:

```text
runtime/addons/installed/dune-ops-observability/
```

Then enable the addon in `runtime/addons/state.json`, approve the requested read-only permission, refresh Dune Docker Console, open Addons, and test the addon through the real Console iframe bridge.

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
