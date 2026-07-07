#!/usr/bin/env bash
# check-upstream-prs.sh — Check status of all yacketrj upstream PRs across both repos.
# Detects state changes and sends Discord notifications.
# Runs hourly via cron. Also runnable manually.
#
# Usage: bash check-upstream-prs.sh [--verbose]

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
NOTIFY="${HOME}/.local/bin/notify-discord.sh"
CACHE="${HOME}/.cache/acp-pr-states.json"
CHANGED=0
TOTAL=0; MERGED_C=0; OPEN_C=0; CLOSED_C=0

echo "=== Upstream PR Status ($(date +%H:%M)) ==="
echo

mkdir -p "$(dirname "$CACHE")"
OLD_STATE="{}"
[ -f "$CACHE" ] && OLD_STATE="$(cat "$CACHE")"
NEW_STATE="{}"

check_repo() {
  local repo="$1" label="$2"
  echo "--- $label ($repo) ---"

  gh pr list --repo "$repo" --author yacketrj --state open --json number,title,url --jq '.[] | "\(.number)\t\(.title)\t\(.url)"' 2>/dev/null | while IFS=$'\t' read -r pr title url; do
    check_pr "$repo" "$pr" "$label" "$title" "$url" "OPEN"
  done

  # Also check recently merged/closed (last 10)
  gh pr list --repo "$repo" --author yacketrj --state merged --limit 5 --json number,title,url,mergedAt --jq '.[] | "\(.number)\t\(.title)\t\(.url)\t\(.mergedAt)"' 2>/dev/null | while IFS=$'\t' read -r pr title url merged; do
    check_pr "$repo" "$pr" "$label" "$title" "$url" "MERGED" "$merged"
  done

  gh pr list --repo "$repo" --author yacketrj --state closed --limit 3 --json number,title,url --jq '.[] | select(.title != null) | "\(.number)\t\(.title)\t\(.url)"' 2>/dev/null | while IFS=$'\t' read -r pr title url; do
    local key="${repo}_${pr}"
    if echo "$NEW_STATE" | grep -q "\"${key}\":" ; then continue; fi
    check_pr "$repo" "$pr" "$label" "$title" "$url" "CLOSED"
  done
}

check_pr() {
  local repo="$1" pr="$2" label="$3" title="$4" url="$5" state_val="$6"
  local merged_val="${7:-}"

  local key="${repo}_${pr}"
  local old_val
  old_val="$(echo "$OLD_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")"

  case "$state_val" in
    MERGED)
      echo -e "  PR #$pr: ${GREEN}MERGED${NC} $([ -n "$merged_val" ] && echo "($merged_val)")  ${title:0:70}"
      if [ "$old_val" = "OPEN" ]; then
        CHANGED=1
        bash "$NOTIFY" upstream-pr-merged \
          "✅ $label PR #$pr Merged!" \
          "**Title:** $title
**Repo:** $repo
**Merged:** ${merged_val:-unknown}" \
          "$url" >/dev/null 2>&1 || true
      fi
      ;;
    OPEN)
      echo -e "  PR #$pr: ${YELLOW}OPEN${NC}  ${title:0:70}"
      if [ "$old_val" = "UNKNOWN" ]; then
        bash "$NOTIFY" upstream-pr-created \
          "📬 $label PR #$pr Opened" \
          "**Title:** $title
**Repo:** $repo" \
          "$url" >/dev/null 2>&1 || true
      fi
      ;;
    CLOSED)
      echo -e "  PR #$pr: ${RED}CLOSED${NC}  ${title:0:70}"
      if [ "$old_val" = "OPEN" ]; then
        bash "$NOTIFY" upstream-pr-created \
          "⚠️ $label PR #$pr Closed" \
          "**Title:** $title
**Repo:** $repo
**Status:** Closed without merge" \
          "$url" >/dev/null 2>&1 || true
      fi
      ;;
  esac

  NEW_STATE="$(echo "$NEW_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); d['$key']='$state_val'; print(json.dumps(d))" 2>/dev/null)"
}

check_repo "Red-Blink/dune-awakening-selfhost-docker" "Core"
echo
check_repo "Red-Blink/dune-docker-addons" "Catalog"

echo "$NEW_STATE" > "$CACHE"

echo
echo "========================================"
[ "$CHANGED" -eq 1 ] && echo -e "${GREEN}State changes detected — Discord notifications sent.${NC}"
echo "Run manually: bash ops-observability/dev-tools/check-upstream-prs.sh"
echo "Cron: runs hourly at :00"
echo "========================================"
