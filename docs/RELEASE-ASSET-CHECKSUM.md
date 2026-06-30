# Release Asset Checksum Procedure

Community catalog submissions must use the SHA-256 checksum of the uploaded GitHub release asset.

Do not use a checksum from a locally rebuilt package unless it exactly matches the downloaded release asset.

## Required command

After the release asset is uploaded, run:

```bash
bash scripts/verify-release-asset-checksum.sh 0.2.0
```

For a future release, replace `0.2.0` with the release version being submitted.

## Expected output

The script prints:

- the release version;
- the release tag;
- the release asset name;
- the download URL;
- the downloaded byte count;
- the SHA-256 checksum;
- the community manifest fields to copy.

## Catalog rule

The value copied into the community addon manifest must be the `SHA-256` value printed by the verifier script.

The `downloadUrl` in the community manifest and the URL verified by the script must refer to the same release asset.

## Failure condition

If the script is run with an expected checksum and the downloaded asset does not match, the script exits with an error.

Example:

```bash
bash scripts/verify-release-asset-checksum.sh 0.2.0 0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5
```

Do not open or update an upstream catalog PR while this verification fails.
