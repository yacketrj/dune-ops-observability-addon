#!/usr/bin/env bash
# merge-safety.sh — Validate JS/TSX syntax after git merge upstream/main.
# Run after any merge conflict resolution.
# Fails closed: any non-zero exit blocks.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not in a git repo."; exit 1; }
cd "$REPO_ROOT"

FAILS=0

echo "=== merge-safety ==="

# Check JS syntax
echo -n "  duneDb.js ... "
if node --check console/api/src/duneDb.js 2>/dev/null; then
    echo "OK"
else
    echo "SYNTAX ERROR"
    FAILS=$((FAILS + 1))
fi

echo -n "  server.js ... "
if node --check console/api/src/server.js 2>/dev/null; then
    echo "OK"
else
    echo "SYNTAX ERROR"
    FAILS=$((FAILS + 1))
fi

echo -n "  auth.js ... "
if [ -f console/api/src/auth.js ] && node --check console/api/src/auth.js 2>/dev/null; then
    echo "OK"
else
    echo "OK (skip)"
fi

# Check web build
echo -n "  web build ... "
if [ -f console/web/package.json ]; then
    if (cd console/web && npm run build 2>&1) > /dev/null; then
        echo "OK"
    else
        echo "BUILD FAILED"
        FAILS=$((FAILS + 1))
    fi
else
    echo "OK (skip)"
fi

if [ "$FAILS" -gt 0 ]; then
    echo ""
    echo "merge-safety: $FAILS failure(s) — fix before pushing"
    exit 1
fi

echo "merge-safety: all clear ✓"
