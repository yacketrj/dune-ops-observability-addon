#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="${1:-$(pwd)}"
API_DIR="$REPO_ROOT/console/api"

if [ ! -d "$API_DIR/src" ]; then
  echo "ERROR: $API_DIR/src not found. Pass the repo root as first argument."
  exit 1
fi

echo "== Running OWASP Top 10 security checks =="
cp pipeline/tests/owasp-security.test.js "$API_DIR/test/owasp-security.test.js"
cp pipeline/tests/blueprints-security.test.js "$API_DIR/test/blueprints-security.test.js"

cd "$API_DIR"
npm ci --silent 2>/dev/null || true
node --test test/owasp-security.test.js test/blueprints-security.test.js

echo "== Cleaning up =="
rm -f test/owasp-security.test.js test/blueprints-security.test.js
echo "Security tests completed."
