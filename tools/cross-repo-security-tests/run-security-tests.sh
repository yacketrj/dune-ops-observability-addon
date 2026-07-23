#!/usr/bin/env bash
# Cross-repo security test runner.
#
# These tests do NOT test this repository (dune-ops-observability-addon).
# They test dune-awakening-selfhost-docker's console/api server (Core) —
# specifically its `src/server.js` — for OWASP Top 10-style issues. They
# live here because that's where they were originally written, but they
# have no dependency on anything in this addon and are never run by this
# repository's own CI. See docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md (C-3)
# for why this file was relocated out of pipeline/tests/ into
# tools/cross-repo-security-tests/ — that directory name, not this
# repository's normal test suite, is where "these are Core's tests" should
# be obvious on sight.
#
# Usage: bash tools/cross-repo-security-tests/run-security-tests.sh <path-to-dune-awakening-selfhost-docker-checkout>
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(pwd)}"
API_DIR="$REPO_ROOT/console/api"

if [ ! -d "$API_DIR/src" ]; then
  echo "ERROR: $API_DIR/src not found. Pass a dune-awakening-selfhost-docker repo root as the first argument."
  exit 1
fi

echo "== Running OWASP Top 10 security checks against $API_DIR =="
cp "$SCRIPT_DIR/owasp-security.test.js" "$API_DIR/test/owasp-security.test.js"
cp "$SCRIPT_DIR/blueprints-security.test.js" "$API_DIR/test/blueprints-security.test.js"

cd "$API_DIR"
npm ci --silent 2>/dev/null || true
node --test test/owasp-security.test.js test/blueprints-security.test.js

echo "== Cleaning up =="
rm -f test/owasp-security.test.js test/blueprints-security.test.js
echo "Security tests completed."
