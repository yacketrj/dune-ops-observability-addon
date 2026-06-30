# Community Addon Index PR

After an addon release is validated, submit a catalog PR to:

```text
https://github.com/Red-Blink/dune-docker-addons
```

The community index does not host addon source code. It points to reviewed addon release manifests and packages.

## Required catalog changes

A new addon listing must:

1. Add `addons/dune-ops-observability.json`.
2. Add a short entry to `index.json`.
3. Point `downloadUrl` to a pinned GitHub Release asset URL.
4. Include the SHA-256 checksum for that exact release asset.
5. Request only the permissions the addon uses.

Do not use GitHub's automatic source archive as the addon package URL.

## PR body template

````markdown
## Summary

Adds Dune Ops Observability to the community addon index.

## Why is it needed?

This addon provides a read-only operations and observability surface for Dune Docker Console. The initial release exposes a bridge-backed player summary access check with safe preview/sample mode for local layout testing.

## Release package

- Source repository: https://github.com/yacketrj/dune-ops-observability-addon
- Release tag: v0.1.0
- Package asset: <pinned release asset URL>
- SHA-256: <checksum from release asset>

## Test output

```text
<output from local validation and package test>
```

## Security output

```text
<output from pre-commit, Gitleaks, Semgrep, Trivy, and addon validation checks>
```

## Permissions requested

```json
{
  "players": ["read"]
}
```

## Review notes

- No write permissions requested.
- No direct localhost/browser API calls.
- Data access goes through the Console bridge.
- Release URL is pinned, not floating `latest`.
- SHA-256 checksum is for the exact uploaded release asset.
````

## Validation commands before submitting

Run these in the addon repository before opening the community index PR:

```bash
node scripts/validate.js
pre-commit run --all-files
bash scripts/package.sh
sha256sum dist/dune-ops-observability-0.1.0.zip
```

Also confirm GitHub PR checks are green for the addon repository before submitting to the community index.
