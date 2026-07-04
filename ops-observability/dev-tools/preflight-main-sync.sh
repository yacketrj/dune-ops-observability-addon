#!/usr/bin/env bash
set -euo pipefail
CANONICAL_REMOTE="${1:-origin}"
CANONICAL_BRANCH="${2:-main}"
git fetch "${CANONICAL_REMOTE}" --prune 2>/dev/null
git switch "${CANONICAL_BRANCH}" 2>/dev/null
git pull --ff-only "${CANONICAL_REMOTE}" "${CANONICAL_BRANCH}" 2>/dev/null
LOCAL=$(git rev-parse "${CANONICAL_BRANCH}" 2>/dev/null)
REMOTE=$(git rev-parse "${CANONICAL_REMOTE}/${CANONICAL_BRANCH}" 2>/dev/null)
if [ "$LOCAL" != "$REMOTE" ]; then
  echo "FAIL: ${CANONICAL_BRANCH} differs from ${CANONICAL_REMOTE}/${CANONICAL_BRANCH}"
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "FAIL: working tree has changes"
  git status --short
  exit 1
fi
echo "PASS: ${CANONICAL_BRANCH} is in lockstep with ${CANONICAL_REMOTE}/${CANONICAL_BRANCH}"
echo "PASS: working tree is clean"
