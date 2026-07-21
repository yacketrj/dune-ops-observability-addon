# Packaging

## Local package test

```bash
bash scripts/package.sh
```

The script validates `addon.json`, creates `dist/dune-ops-observability-<version>.zip`, and writes a SHA-256 checksum file next to it.

## Release

Create a tag that matches `addon.json.version`.

```bash
git tag v0.4.1
git push origin v0.4.1
```

The release workflow validates the addon, builds the zip, creates the checksum, generates a CycloneDX SBOM, and uploads all artifacts to the GitHub Release.

## Release artifacts

- `dune-ops-observability-<version>.zip` — addon package
- `dune-ops-observability-<version>.zip.sha256` — SHA-256 checksum
- `sbom.json` — CycloneDX software bill of materials (when available)
