#!/usr/bin/env bash
# artifact-guard.sh — Block commits containing generated artifacts.
# Called by pre-push-gates and pre-pr-check.sh.
# Fails closed: any non-zero exit blocks.

set -euo pipefail

FORBIDDEN='coverage/|dist/|\.tmp/|\.tgz|lcov-report|\.cdx\.json|\.cdx\.json\.sha256'

# Check staged changes
STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
if echo "$STAGED" | grep -Eq "$FORBIDDEN"; then
    echo "BLOCKED: Generated artifacts in staged changes:"
    echo "$STAGED" | grep -E "$FORBIDDEN" | head -10
    echo ""
    echo "Remove these files or add them to .gitignore."
    exit 1
fi

# Check diff vs upstream/main
if git rev-parse upstream/main >/dev/null 2>&1; then
    DIFF=$(git diff --name-only upstream/main...HEAD 2>/dev/null || echo "")
    if echo "$DIFF" | grep -Eq "$FORBIDDEN"; then
        echo "BLOCKED: Generated artifacts in PR diff vs upstream/main:"
        echo "$DIFF" | grep -E "$FORBIDDEN" | head -10
        echo ""
        echo "Remove these files before pushing."
        exit 1
    fi
fi

echo "artifact-guard: clean ✓"
exit 0
