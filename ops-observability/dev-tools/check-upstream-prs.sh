#!/usr/bin/env bash
# check-upstream-prs.sh — Track all yacketrj upstream PRs across both repos.
# Only notifies Discord on PR merge events. Logs status locally.
#
# Usage: bash check-upstream-prs.sh

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
NOTIFY="${HOME}/.local/bin/notify-discord.sh"
CACHE="${HOME}/.cache/acp-pr-states.json"

echo "=== Upstream PR Status ($(date +%H:%M)) ==="

mkdir -p "$(dirname "$CACHE")"
[ -f "$CACHE" ] && OLD_STATE="$(cat "$CACHE")" || OLD_STATE="{}"

check_repo() {
  local repo="$1" label="$2"
  echo "--- $label ($repo) ---"

  # Open PRs — just list, no notification
  while IFS=$'\t' read -r pr title url; do
    [ -z "$pr" ] && continue
    local key="${repo}_${pr}"
    echo -e "  PR #$pr: ${YELLOW}OPEN${NC}  ${title:0:80}"
    python3 -c "import json,sys; d=json.load(sys.stdin); d['$key']='OPEN'; sys.stdout.write(json.dumps(d))" <<< "$NEW_STATE" > /tmp/acp-new.json 2>/dev/null && NEW_STATE="$(cat /tmp/acp-new.json)"
  done < <(gh pr list --repo "$repo" --author yacketrj --state open --json number,title,url --jq '.[] | "\(.number)\t\(.title)\t\(.url)"' 2>/dev/null)

  # Recently merged — notify Discord on OPEN→MERGED transition
  while IFS=$'\t' read -r pr title url merged; do
    [ -z "$pr" ] && continue
    local key="${repo}_${pr}"
    local old_val
    old_val="$(echo "$OLD_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('$key','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")"
    if [ "$old_val" = "OPEN" ]; then
      echo -e "  PR #$pr: ${GREEN}MERGED${NC} ($merged) ${title:0:60}"
      bash "$NOTIFY" upstream-pr-merged \
        "✅ $label PR #$pr Merged!" \
        "**Title:** $title
**Repo:** $repo
**Merged:** $merged" \
        "$url" >/dev/null 2>&1 || true
    fi
    python3 -c "import json,sys; d=json.load(sys.stdin); d['$key']='MERGED'; sys.stdout.write(json.dumps(d))" <<< "$NEW_STATE" > /tmp/acp-new.json 2>/dev/null && NEW_STATE="$(cat /tmp/acp-new.json)"
  done < <(gh pr list --repo "$repo" --author yacketrj --state merged --limit 5 --json number,title,url,mergedAt --jq '.[] | "\(.number)\t\(.title)\t\(.url)\t\(.mergedAt)"' 2>/dev/null)
}

NEW_STATE="{}"
check_repo "Red-Blink/dune-awakening-selfhost-docker" "Core"
echo
check_repo "Red-Blink/dune-docker-addons" "Catalog"

echo "$NEW_STATE" > "$CACHE"
