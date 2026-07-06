#!/usr/bin/env bash
# check-upstream-prs.sh — Check status of all upstream PRs across both repos.
# Reports which PRs are open, merged, or need attention.
#
# Usage: bash check-upstream-prs.sh [--verbose]

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "=== Upstream PR Status ==="
echo

# ─── Core PRs ───
echo "--- Core (Red-Blink/dune-awakening-selfhost-docker) ---"

CORE_PRS=("61")
for pr in "${CORE_PRS[@]}"; do
  STATE="$(gh pr view "$pr" --repo Red-Blink/dune-awakening-selfhost-docker --json state,mergedAt --jq '{state, merged: .mergedAt}' 2>/dev/null || echo '{"state":"NOT_FOUND"}')"
  STATE_VAL="$(echo "$STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('state','UNKNOWN'))" 2>/dev/null)"
  MERGED="$(echo "$STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('merged','') or '')" 2>/dev/null)"

  case "$STATE_VAL" in
    MERGED)
      echo -e "  PR #$pr: ${GREEN}MERGED${NC} ($MERGED)"
      ;;
    OPEN)
      echo -e "  PR #$pr: ${YELLOW}OPEN${NC} — awaiting review"
      ;;
    CLOSED)
      echo -e "  PR #$pr: ${RED}CLOSED${NC} (not merged)"
      ;;
    *)
      echo -e "  PR #$pr: ${RED}$STATE_VAL${NC}"
      ;;
  esac
done

# ─── Catalog PRs ───
echo
echo "--- Catalog (Red-Blink/dune-docker-addons) ---"

CATALOG_PRS=("7" "5")
for pr in "${CATALOG_PRS[@]}"; do
  STATE="$(gh pr view "$pr" --repo Red-Blink/dune-docker-addons --json state,mergedAt --jq '{state, merged: .mergedAt}' 2>/dev/null || echo '{"state":"NOT_FOUND"}')"
  STATE_VAL="$(echo "$STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('state','UNKNOWN'))" 2>/dev/null)"
  MERGED="$(echo "$STATE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('merged','') or '')" 2>/dev/null)"

  case "$STATE_VAL" in
    MERGED)
      echo -e "  PR #$pr: ${GREEN}MERGED${NC} ($MERGED)"
      ;;
    OPEN)
      echo -e "  PR #$pr: ${YELLOW}OPEN${NC} — awaiting review"
      ;;
    CLOSED)
      echo -e "  PR #$pr: ${RED}CLOSED${NC} (not merged)"
      ;;
    *)
      echo -e "  PR #$pr: ${RED}$STATE_VAL${NC}"
      ;;
  esac
done

# ─── Detect upstream releases that include our changes ───
echo
echo "--- Release Detection ---"

CORE_DIR="${HOME}/dune-awakening-selfhost-docker"
if git -C "$CORE_DIR" tag -l --sort=-creatordate 2>/dev/null | head -1 | grep -q .; then
  echo "  Core tags (Red-Blink): $(git -C "$CORE_DIR" tag -l --sort=-creatordate 2>/dev/null | grep -o '^v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -5 | tr '\n' ' ')"
fi

ADDON_DIR="${HOME}/dune-docker-addon/addon-main"
if [ -f "$ADDON_DIR/README.md" ]; then
  COMPAT="$(grep 'upstream.*compatible\|v[0-9]\+\.[0-9]\+\.[0-9]\+' "$ADDON_DIR/README.md" | head -2)"
  echo "  README compatibility: $COMPAT"
fi

echo
echo "=== Summary ==="
echo "Run 'bash check-upstream-prs.sh --verbose' for detailed PR info."
echo "Update README.md compatibility line when a core PR is merged into a release."
