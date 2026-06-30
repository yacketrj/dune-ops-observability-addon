# Packaging

## Local package test

```bash
bash scripts/package.sh
```

The script validates `addon.json`, creates `dist/dune-ops-observability-0.1.0.zip`, and writes a SHA-256 checksum file next to it.

## Release

Create a tag that matches `addon.json.version`.

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow validates the addon, builds the zip, creates the checksum, and uploads both files to the GitHub Release.
