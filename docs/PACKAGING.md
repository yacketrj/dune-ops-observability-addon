# Packaging

## Local package test

```bash
bash scripts/package.sh
```

The script validates the manifest and all JS syntax, creates `dist/<id>-<version>.zip`, and writes a SHA-256 checksum file next to it.

## Pre-release SHA verification (required before catalog submission)

After the release workflow uploads the asset, verify the SHA-256 on the uploaded release asset matches the local build:

```bash
bash scripts/verify-release-asset-checksum.sh 0.3.0
```

To also check against an expected SHA:

```bash
bash scripts/verify-release-asset-checksum.sh 0.3.0 <expected-sha256-from-catalog>
```

**Do not submit or update a community catalog manifest while this verification fails.** The `sha256` value in the catalog must match the GitHub release asset, not a locally-rebuilt zip.

## Release

Create a tag that matches `addon.json.version`.

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow validates the addon, builds the zip, creates the checksum, and uploads both files to the GitHub Release.

## Catalog submission checklist

Before opening a catalog PR in `Red-Blink/dune-docker-addons`:

1. Run `bash scripts/package.sh` and confirm it passes.
2. Push the tag and wait for the release workflow to upload the asset.
3. Run `bash scripts/verify-release-asset-checksum.sh <version>` against the uploaded release asset.
4. Copy the printed SHA-256 and manifest fields into the catalog entry.
5. Run `bash scripts/validate-catalog-shas.sh` from the catalog repo to confirm the entry is valid.
