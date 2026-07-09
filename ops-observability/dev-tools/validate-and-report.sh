#!/usr/bin/env bash
# validate-and-report.sh — Hourly fork sync, PR rebase, mergeability, and CI validation.
# Auto-syncs core fork main with upstream, rebases open PR branches, and reports issues to Discord.
#
# Usage: bash validate-and-report.sh

set -euo pipefail

NOTIFY="${HOME}/.local/bin/notify-discord.sh"
CORE_DIR="${HOME}/dune-awakening-selfhost-docker"
CATALOG_DIR="${HOME}/dune-docker-addon/dune-docker-addons"
TODAY="$(date +%Y-%m-%d)"
ISSUES=0
REPORT=""
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "=== ACP Validation ($(date +%H:%M)) ==="

# ─── 1. Core fork: sync main with upstream ───
echo "--- 1. Core fork sync ---"
cd "$CORE_DIR"

git fetch upstream main --quiet 2>/dev/null || true
git fetch origin --quiet 2>/dev/null || true

UPSTREAM=$(git rev-parse upstream/main)
ORIGIN_MAIN=$(git rev-parse origin/main 2>/dev/null || echo "")

if [ "$UPSTREAM" != "$ORIGIN_MAIN" ]; then
  BEHIND=$(git rev-list origin/main..upstream/main --count 2>/dev/null || echo "?")
  echo "  SYNC: core fork $BEHIND commits behind — syncing main..."

  # Save current branch and working tree
  CURRENT_BRANCH=$(git branch --show-current)
  STASHED=false
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    git stash -u -m "auto-sync-${TODAY}" 2>/dev/null && STASHED=true
  fi

  # Sync main with upstream
  git checkout main 2>/dev/null || git checkout -b main upstream/main
  git reset --hard upstream/main 2>/dev/null
  git push origin main --force-with-lease --no-verify 2>&1 | tail -1

  echo -e "  ${GREEN}OK:${NC} main synced with upstream ($(echo $UPSTREAM | cut -c1-7))"

  # ─── Rebase all open PR branches on updated main ───
  echo "  Rebasing open PR branches..."

  OPEN_PRS=$(gh pr list --repo Red-Blink/dune-awakening-selfhost-docker --author yacketrj --state open --json headRefName --jq '.[].headRefName' 2>/dev/null || echo "")

  for branch in $OPEN_PRS; do
    echo -n "    $branch: "
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      echo "skipped (no remote)"
      continue
    fi

    git checkout "$branch" 2>/dev/null || { echo "failed (checkout)"; continue; }

    if git rebase upstream/main 2>/dev/null; then
      git push origin "$branch" --force-with-lease --no-verify 2>&1 | tail -1
      echo -e "${GREEN}rebased${NC}"
    else
      git rebase --abort 2>/dev/null || true
      echo -e "${RED}CONFLICT${NC}"
      REPORT="${REPORT}\n❌ PR branch \`$branch\` has merge conflicts with upstream/main"
      ISSUES=$((ISSUES + 1))
    fi
  done

  # Restore previous state
  if [ "$STASHED" = true ]; then
    git checkout "$CURRENT_BRANCH" 2>/dev/null || true
    git stash pop 2>/dev/null || true
  elif [ "$CURRENT_BRANCH" != "main" ]; then
    git checkout "$CURRENT_BRANCH" 2>/dev/null || git checkout integration/discord 2>/dev/null || true
  fi
else
  echo -e "  ${GREEN}OK:${NC} core fork synced ($(echo $UPSTREAM | cut -c1-7))"
fi

# ─── 2. Catalog fork sync ───
echo "--- 2. Catalog fork sync ---"
if [ -d "$CATALOG_DIR" ]; then
  cd "$CATALOG_DIR"
  git fetch upstream main --quiet 2>/dev/null || true
  git fetch origin main --quiet 2>/dev/null || true
  CAT_UP=$(git rev-parse upstream/main 2>/dev/null || echo "")
  CAT_OR=$(git rev-parse origin/main 2>/dev/null || echo "")
  if [ -n "$CAT_UP" ] && [ -n "$CAT_OR" ] && [ "$CAT_UP" != "$CAT_OR" ]; then
    BEHIND=$(git rev-list origin/main..upstream/main --count 2>/dev/null || echo "?")
    echo "  SYNC: catalog fork $BEHIND commits behind — syncing..."
    git checkout main 2>/dev/null || true
    git reset --hard upstream/main 2>/dev/null
    git push origin main --force-with-lease --no-verify 2>&1 | tail -1
    echo -e "  ${GREEN}OK:${NC} catalog synced"
  else
    echo -e "  ${GREEN}OK:${NC} catalog fork synced"
  fi
else
  echo "  SKIP: catalog dir not found"
fi

# ─── 3. PR mergeability check ───
echo "--- 3. PR mergeability ---"
check_prs() {
  local repo="$1" label="$2"
  gh pr list --repo "$repo" --author yacketrj --state open --json number,title,mergeable --jq '.[] | "\(.number)\t\(.title)\t\(.mergeable)"' 2>/dev/null | while IFS=$'\t' read -r pr title mergeable; do
    if [ "$mergeable" = "MERGEABLE" ]; then
      echo -e "  ${GREEN}OK:${NC} PR #$pr ($label) — MERGEABLE"
    else
      echo -e "  ${RED}FAIL:${NC} PR #$pr ($label) — $mergeable"
      REPORT="${REPORT}\n❌ PR #$pr ($label) — **$mergeable** — $title"
      ISSUES=$((ISSUES + 1))
    fi
  done
}
check_prs "Red-Blink/dune-awakening-selfhost-docker" "Core"
check_prs "Red-Blink/dune-docker-addons" "Catalog"

# ─── 4. CI failure check ───
echo "--- 4. CI failures ---"
for r in yacketrj/dune-awakening-selfhost-docker yacketrj/dune-ops-observability-addon yacketrj/dune-docker-addons yacketrj/dune-awakening-selfhost-discordbot; do
  FAILS=$(gh run list --repo "$r" --status failure --limit 1 --json databaseId --jq 'length' 2>/dev/null || echo "0")
  REPO_NAME=$(echo "$r" | cut -d'/' -f2)
  if [ "$FAILS" -gt 0 ]; then
    echo -e "  ${RED}FAIL:${NC} $REPO_NAME has $FAILS failed CI runs"
    REPORT="${REPORT}\n⚠️ **$REPO_NAME** — \`$FAILS\` failed CI runs need resolution"
    ISSUES=$((ISSUES + 1))
  else
    echo -e "  ${GREEN}OK:${NC} $REPO_NAME — clean"
  fi
done

# ─── 5. Summary ───
echo
if [ "$ISSUES" -eq 0 ]; then
  echo -e "${GREEN}All checks passed.${NC} No Discord notification sent."
else
  echo -e "${RED}$ISSUES issue(s) found.${NC} Sending Discord notification."
  if [ -x "$NOTIFY" ]; then
    bash "$NOTIFY" deploy \
      "⚠️ ACP Validation — $ISSUES issue(s)" \
      "$REPORT" \
      "" 16744192 >/dev/null 2>&1 || true
  fi
fi