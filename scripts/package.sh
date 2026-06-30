#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT_DIR"

command -v node >/dev/null 2>&1 || { echo "node is required" >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required" >&2; exit 1; }

node scripts/validate.js

ADDON_ID="$(node -e "process.stdout.write(require('./addon.json').id)")"
ADDON_VERSION="$(node -e "process.stdout.write(require('./addon.json').version)")"
PACKAGE_NAME="${ADDON_ID}-${ADDON_VERSION}.zip"

rm -rf dist
mkdir -p dist

zip -r "dist/${PACKAGE_NAME}" addon.json web -x "*.DS_Store" >/dev/null

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "dist/${PACKAGE_NAME}" | tee "dist/${PACKAGE_NAME}.sha256"
else
  shasum -a 256 "dist/${PACKAGE_NAME}" | tee "dist/${PACKAGE_NAME}.sha256"
fi

echo "Created dist/${PACKAGE_NAME}"
