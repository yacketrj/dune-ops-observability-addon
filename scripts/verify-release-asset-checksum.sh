#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
EXPECTED_SHA="${2:-}"
REPO="${REPO:-yacketrj/dune-ops-observability-addon}"
ADDON_ID="${ADDON_ID:-dune-ops-observability}"

if [[ -z "$VERSION" ]]; then
  printf 'Usage: %s <version> [expected-sha256]\n' "$0" >&2
  printf 'Example: %s 0.2.0 0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5\n' "$0" >&2
  exit 2
fi

TAG="v$VERSION"
ASSET="$ADDON_ID-$VERSION.zip"
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

printf 'Release version: %s\n' "$VERSION"
printf 'Release tag: %s\n' "$TAG"
printf 'Asset: %s\n' "$ASSET"
printf 'Download URL: %s\n' "$DOWNLOAD_URL"

curl --fail --location --silent --show-error --output "$WORK_DIR/$ASSET" "$DOWNLOAD_URL"

ACTUAL_SHA="$(sha256sum "$WORK_DIR/$ASSET" | awk '{print $1}')"
SIZE_BYTES="$(wc -c < "$WORK_DIR/$ASSET" | tr -d ' ')"

printf 'Downloaded bytes: %s\n' "$SIZE_BYTES"
printf 'SHA-256: %s\n' "$ACTUAL_SHA"

if [[ -n "$EXPECTED_SHA" ]]; then
  if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    printf 'Checksum mismatch.\n' >&2
    printf 'Expected: %s\n' "$EXPECTED_SHA" >&2
    printf 'Actual:   %s\n' "$ACTUAL_SHA" >&2
    exit 1
  fi

  printf 'Checksum verified.\n'
fi

printf '\nCommunity manifest fields:\n'
printf '  "version": "%s",\n' "$VERSION"
printf '  "downloadUrl": "%s",\n' "$DOWNLOAD_URL"
printf '  "sha256": "%s"\n' "$ACTUAL_SHA"
