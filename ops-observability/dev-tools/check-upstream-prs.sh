#!/usr/bin/env bash
# check-upstream-prs.sh — Check status of all upstream PRs across both repos.
# Detects state changes and sends Discord notifications.
#
# Usage: bash check-upstream-prs.sh [--verbose] [--notify]

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
NOTIFY="${HOME}/.local/bin/notify-discord.sh"
CACHE="${HOME}/.cache/acp-pr-states.json"
CHANGED=0

echo "=== Upstream PR Status ==="
echo

# ─── State tracking ───
mkdir -p "$(dirname "$CACHE")"
OLD_STATE="{}"
[ -f "$CACHE" ] && OLD_STATE="$(cat "$CACHE")"
NEW_STATE="{}"

check_pr() {
  local repo="$1" pr="$2" label="$3"
  local state merged title url
  state="$(gh pr view "$pr" --repo "$repo" --json state,mergedAt,title,url --jq '{state, merged: .mergedAt, title, url}' 2>/dev/null || echo '{"state":"NOT_FOUND"}')"
  local state_val merged_val title_val url_val
  state_val="$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('state','UNKNOWN'))" 2>/dev/null)"
  merged_val="$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('merged','') or '')" 2>/dev/null)"
  title_val="$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('title','?'))" 2>/dev/null | head -c 80)"
  url_val="$(echo "$state" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('url',''))" 2>/dev/null)"

  local old_val
  old_val="$(echo "$OLD_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('${repo}_${pr}','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")"

  case "$state_val" in
    MERGED)
      echo -e "  PR #$pr ($label): ${GREEN}MERGED${NC} ($merged_val)"
      if [ "$old_val" = "OPEN" ]; then
        CHANGED=1
        bash "$NOTIFY" upstream-pr-merged \
          "✅ $label PR #$pr Merged!" \
          "**Title:** $title_val
**Repo:** $repo
**Merged:** $merged_val" \
          "$url_val" >/dev/null 2>&1 || true
      fi
      ;;
    OPEN)
      echo -e "  PR #$pr ($label): ${YELLOW}OPEN${NC} — awaiting review"
      if [ "$old_val" = "UNKNOWN" ]; then
        bash "$NOTIFY" upstream-pr-created \
          "📬 $label PR #$pr Created" \
          "**Title:** $title_val
**Repo:** $repo" \
          "$url_val" >/dev/null 2>&1 || true
      fi
      ;;
    CLOSED)
      echo -e "  PR #$pr ($label): ${RED}CLOSED${NC} (not merged)"
      if [ "$old_val" = "OPEN" ]; then
        bash "$NOTIFY" ! \
          "⚠️ $label PR #$pr Closed" \
          "**Title:** $title_val
**Repo:** $repo
**Status:** Closed without merge" \
          "$url_val" >/dev/null 2>&1 || true
      fi
      ;;
    *)
      echo -e "  PR #$pr ($label): ${RED}$state_val${NC}"
      ;;
  esac

  NEW_STATE="$(echo "$NEW_STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); d['${repo}_${pr}']='$state_val'; print(json.dumps(d))" 2>/dev/null)"
}

# ─── Core PRs ───
echo "--- Core (Red-Blink/dune-awakening-selfhost-docker) ---"
check_pr "Red-Blink/dune-awakening-selfhost-docker" "61" "core"
check_pr "Red-Blink/dune-awakening-selfhost-docker" "68" "core"

# ─── Catalog PRs ───
echo
echo "--- Catalog (Red-Blink/dune-docker-addons) ---"
check_pr "Red-Blink/dune-docker-addons" "10" "catalog"

# ─── Save state ───
echo "$NEW_STATE" > "$CACHE"

# ─── Release Detection ───
echo
echo "--- Release Detection ---"
CORE_DIR="${HOME}/dune-awakening-selfhost-docker"
if git -C "$CORE_DIR" tag -l --sort=-creatordate 2>/dev/null | head -1 | grep -q .; then
  echo "  Core tags: $(git -C "$CORE_DIR" tag -l --sort=-creatordate 2>/dev/null | grep -o '^v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -3 | tr '\n' ' ')"
fi

echo
echo "=== Summary ==="
[ "$CHANGED" -eq 1 ] && echo -e "${GREEN}State changes detected — Discord notifications sent.${NC}"
echo "Run 'bash check-upstream-prs.sh' before staging new PRs."
echo "Update README.md compatibility line when a core PR is merged."
