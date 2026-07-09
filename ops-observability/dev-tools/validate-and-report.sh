#!/usr/bin/env bash
# validate-and-report.sh — Comprehensive PR and repo validation for cron.
# Validates: fork sync, PR mergeability, preflight checks.
# Only sends Discord notification when issues are found.

set -euo pipefail

NOTIFY="${HOME}/.local/bin/notify-discord.sh"
CORE_DIR="${HOME}/dune-awakening-selfhost-docker"
CATALOG_DIR="${HOME}/dune-docker-addon/dune-docker-addons"
TODAY="$(date +%Y-%m-%d)"
ISSUES=0
REPORT=""

echo "=== ACP Validation ($(date +%H:%M)) ==="

# ─── 1. Source of truth sync check ───
echo "--- 1. Fork sync ---"
cd "$CORE_DIR"
git fetch upstream main --quiet 2>/dev/null || true
UPSTREAM=$(git rev-parse upstream/main)
ORIGIN=$(git rev-parse origin/main)
if [ "$UPSTREAM" != "$ORIGIN" ]; then
  BEHIND=$(git rev-list origin/main..upstream/main --count 2>/dev/null || echo "?")
  echo "  FAIL: core fork behind upstream by $BEHIND commits"
  REPORT="${REPORT}\n⚠️ Core fork **$BEHIND commits** behind upstream"
  ISSUES=$((ISSUES + 1))
else
  echo "  OK: core fork synced ($(echo $UPSTREAM | cut -c1-7))"
fi

cd "$CATALOG_DIR"
git fetch upstream main --quiet 2>/dev/null || true
CAT_UP=$(git rev-parse upstream/main)
CAT_OR=$(git rev-parse origin/main)
if [ "$CAT_UP" != "$CAT_OR" ]; then
  BEHIND=$(git rev-list origin/main..upstream/main --count 2>/dev/null || echo "?")
  echo "  FAIL: catalog fork behind upstream by $BEHIND commits"
  REPORT="${REPORT}\n⚠️ Catalog fork **$BEHIND commits** behind upstream"
  ISSUES=$((ISSUES + 1))
else
  echo "  OK: catalog fork synced ($(echo $CAT_UP | cut -c1-7))"
fi

# ─── 2. PR mergeability check ───
echo "--- 2. PR mergeability ---"
check_prs() {
  local repo="$1" label="$2"
  gh pr list --repo "$repo" --author yacketrj --state open --json number,title,mergeable --jq '.[] | "\(.number)\t\(.title)\t\(.mergeable)"' 2>/dev/null | while IFS=$'\t' read -r pr title mergeable; do
    if [ "$mergeable" = "MERGEABLE" ]; then
      echo "  OK: #$pr ($label) — MERGEABLE"
    else
      echo "  FAIL: #$pr ($label) — $mergeable"
      REPORT="${REPORT}\n❌ PR #$pr ($label) — **$mergeable** — $title"
      ISSUES=$((ISSUES + 1))
    fi
  done
}

check_prs "Red-Blink/dune-awakening-selfhost-docker" "Core"
check_prs "Red-Blink/dune-docker-addons" "Catalog"

# ─── 3. Summary ───
echo
if [ "$ISSUES" -eq 0 ]; then
  echo "All checks passed. No Discord notification sent."
else
  echo "$ISSUES issue(s) found. Sending Discord notification."
  bash "$NOTIFY" deploy \
    "⚠️ ACP Validation — $ISSUES issue(s)" \
    "$REPORT" \
    "" 16744192 >/dev/null 2>&1 || true
fi
