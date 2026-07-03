# PR: Addon Source Release Prep

Status: Draft
Branch: `release-0-3-source-prep`
Base: `main`
Release: `0.3-expanded-db-bridge`

## Summary

Prepares the addon source repository for the public Release 0.3 train.

## Scope

- Remove stale `players:read` from the addon manifest.
- Keep only `ops:read`, matching the Release 0.3 WebUI provider.
- Align the local Console install helper with the requested permission set.
- Refresh community index PR and release checksum docs for `v0.3.0`.

## Out of Scope

- Upstream Core `ops.health.*` implementation.
- Community addon catalog manifest/index changes.
- GitHub Release publication.

## Validation Required

```text
node scripts/validate.js
pre-commit run --all-files
bash scripts/package.sh
bash ops-observability/dev-tools/pr-gate.sh
```

## Follow-up

After this PR merges:

1. Publish the `v0.3.0` addon release asset.
2. Verify the uploaded release asset checksum.
3. Submit the upstream Core PR.
4. Submit the community addon catalog PR after release URL and checksum are final.
