#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT_DIR"
PASS=0; FAIL=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  PASS: ${d}"; PASS=$((PASS+1)); else echo "  FAIL: ${d}"; FAIL=$((FAIL+1)); fi; }
echo "=== Addon State Validation ==="
check "addon.json exists" test -f addon.json
check "addon.json is valid JSON" node -e "require('./addon.json')"
check "web/ directory exists" test -d web
check "addon.js exists" test -f web/addon.js
check "index.html exists" test -f web/index.html
check "data-providers.js exists" test -f web/data-providers.js
check "ops-observability/ exists" test -d ops-observability
check "scripts/validate.js exists" test -f scripts/validate.js
check "scripts/package.sh exists" test -f scripts/package.sh
check "manifest validation passes" node scripts/validate.js
echo "Results: ${PASS} passed, ${FAIL} failed"
exit $FAIL
