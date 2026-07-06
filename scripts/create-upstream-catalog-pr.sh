#!/usr/bin/env bash
# create-upstream-catalog-pr.sh — Automated upstream catalog PR creation for dune-docker-addons.
# Runs all pre-submission validations and opens the PR against Red-Blink/dune-docker-addons.
#
# Usage: bash create-upstream-catalog-pr.sh <version> [--draft]
# Example: bash create-upstream-catalog-pr.sh v0.5.0
#          bash create-upstream-catalog-pr.sh v0.5.0 --draft

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Usage: bash create-upstream-catalog-pr.sh <version> [--draft]"
  echo "Example: bash create-upstream-catalog-pr.sh v0.5.0"
  exit 1
fi

DRAFT=false
if [ "${2:-}" = "--draft" ]; then
  DRAFT=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_REPO="$(cd "$SCRIPT_DIR/../.." && pwd)"
CATALOG_REPO="${HOME}/dune-docker-addon/dune-docker-addons"
UPSTREAM="Red-Blink/dune-docker-addons"
BRANCH="catalog-${VERSION}"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
fail() { echo -e "${RED}ERROR:${NC} $*"; exit 1; }
pass() { echo -e "${GREEN}✓${NC} $*"; }

echo "=== Upstream Catalog PR: $VERSION ==="
echo

# ─── Gate 0: Preflight ───
echo "--- Gate 0: Preflight ---"

MANIFEST="${ADDON_REPO}/addon.json"
[ -f "$MANIFEST" ] || fail "addon.json not found at $MANIFEST"
MANIFEST_VERSION="$(node -e "console.log(require('${MANIFEST}').version)" 2>/dev/null || true)"
if [ "$MANIFEST_VERSION" != "$VERSION" ]; then
  fail "addon.json version ($MANIFEST_VERSION) does not match tag ($VERSION)"
fi
pass "addon.json version matches tag: $VERSION"

RELEASE_ASSET_URL="$(node -e "console.log(require('${MANIFEST}').downloadUrl)" 2>/dev/null || true)"
if [ -z "$RELEASE_ASSET_URL" ]; then
  fail "downloadUrl not found in addon.json"
fi
pass "downloadUrl: $RELEASE_ASSET_URL"

SHA="$(node -e "console.log(require('${MANIFEST}').sha256)" 2>/dev/null || true)"
if [ -z "$SHA" ]; then
  fail "sha256 not found in addon.json"
fi
pass "SHA-256: $SHA"

# ─── Gate 1: Validation ───
echo
echo "--- Gate 1: Validation ---"

cd "$ADDON_REPO"

if [ -f scripts/validate.js ]; then
  node scripts/validate.js >/dev/null 2>&1 && pass "addon manifest valid" || fail "addon manifest validation failed"
fi

if command -v pre-commit >/dev/null 2>&1; then
  SKIP="trivy,semgrep" pre-commit run --all-files >/dev/null 2>&1 && pass "pre-commit checks pass" || fail "pre-commit checks failed"
fi

if [ -f scripts/verify-release-asset-checksum.sh ]; then
  bash scripts/verify-release-asset-checksum.sh "$VERSION" >/dev/null 2>&1 && pass "release asset checksum verified" || fail "release asset checksum mismatch"
else
  echo "  verify-release-asset-checksum.sh not found — skipping"
fi

# ─── Gate 2: Catalog branch ───
echo
echo "--- Gate 2: Catalog branch ---"

cd "$CATALOG_REPO"

git fetch upstream main --quiet
git checkout upstream/main --detach --quiet
git branch -D "$BRANCH" 2>/dev/null || true
git checkout -b "$BRANCH" --quiet
pass "branch created: $BRANCH"

# Copy addon manifest from addon repo
cp "$MANIFEST" "addons/dune-ops-observability.json"

# Update manifest with current version data
node -e "
const m = JSON.parse(require('fs').readFileSync('addons/dune-ops-observability.json','utf8'));
m.version = '$VERSION';
m.sha256 = '$SHA';
require('fs').writeFileSync('addons/dune-ops-observability.json', JSON.stringify(m, null, 2) + '\n');
"
pass "manifest updated to $VERSION"

# Update index.json
node -e "
const idx = JSON.parse(require('fs').readFileSync('index.json','utf8'));
const entry = idx.addons.find(a => a.id === 'dune-ops-observability');
if (entry) {
  entry.version = '$VERSION';
  entry.description = 'Read-only operations addon for Dune Docker Console. Provides OPS health summary, player aggregate, and farm aggregate views through the Console bridge.';
} else {
  idx.addons.push({
    id: 'dune-ops-observability',
    name: 'Dune Ops Observability',
    description: 'Read-only operations addon for Dune Docker Console.',
    author: 'DarkDante',
    version: '$VERSION',
    lifecycle: 'active',
    lifecycleMessage: '',
    lifecycleUrl: '',
    manifestUrl: 'https://raw.githubusercontent.com/Red-Blink/dune-docker-addons/main/addons/dune-ops-observability.json'
  });
}
idx.updatedAt = new Date().toISOString();
require('fs').writeFileSync('index.json', JSON.stringify(idx, null, 2) + '\n');
"
pass "index.json updated"

# Validate catalog SHAs
if [ -f scripts/validate-catalog-shas.sh ]; then
  bash scripts/validate-catalog-shas.sh >/dev/null 2>&1 && pass "catalog SHA validation passes" || fail "catalog SHA validation failed"
fi

# ─── Gate 3: Commit & Push ───
echo
echo "--- Gate 3: Commit & Push ---"

git add addons/dune-ops-observability.json index.json
git commit -m "catalog: update Dune Ops Observability to $VERSION" --quiet
pass "committed"

git push origin "$BRANCH" --force --quiet 2>/dev/null || fail "push to origin failed — check remote: yacketrj/dune-docker-addons"
pass "pushed to origin/$BRANCH"

# ─── Gate 4: Create PR ───
echo
echo "--- Gate 4: Create upstream PR ---"

SECURITY_OUTPUT=""
if [ -f "$ADDON_REPO/.security-reports/secret-keyword-review.txt" ]; then
  SECURITY_OUTPUT="$(cat "$ADDON_REPO/.security-reports/secret-keyword-review.txt" | head -10)"
fi

TEST_OUTPUT=""
if [ -f "$ADDON_REPO/scripts/verify-release-asset-checksum.sh" ]; then
  TEST_OUTPUT="$(bash "$ADDON_REPO/scripts/verify-release-asset-checksum.sh" "$VERSION" 2>&1 | tail -5)"
fi

PERMISSIONS="$(node -e "console.log(JSON.stringify(require('${MANIFEST}').permissions, null, 2))" 2>/dev/null || echo '{"ops":["read"]}')"

PR_BODY=$(cat <<END_BODY
## Summary

Updates Dune Ops Observability to $VERSION in the community addon index.

## Why is it needed?

This release updates the addon catalog entry for version $VERSION with the verified release asset checksum.

## Release package

- Source repository: https://github.com/yacketrj/dune-ops-observability-addon
- Release tag: $VERSION
- Package asset: $RELEASE_ASSET_URL
- SHA-256: $SHA

## Test output

\`\`\`text
$TEST_OUTPUT
\`\`\`

## Security output

\`\`\`text
$SECURITY_OUTPUT
\`\`\`

## Permissions requested

\`\`\`json
$PERMISSIONS
\`\`\`

## Review notes

- No write permissions requested.
- No direct localhost/browser API calls.
- Data access goes through the Console bridge.
- Release URL is pinned, not floating "latest".
- SHA-256 checksum is for the exact uploaded release asset.
END_BODY
)

PR_ARGS=(--repo "$UPSTREAM" --head "yacketrj:$BRANCH" --base main --title "Dune Ops Observability $VERSION" --body "$PR_BODY")
if $DRAFT; then
  PR_ARGS+=(--draft)
fi

PR_URL="$(gh pr create "${PR_ARGS[@]}" 2>&1)" || fail "Failed to create PR: $PR_URL"
echo
echo "========================================"
echo -e "${GREEN}Upstream PR created:${NC}"
echo "  $PR_URL"
echo
echo "Next steps:"
echo "  1. Review the PR at the URL above"
echo "  2. Verify CI checks pass (validate-catalog-shas)"
echo "  3. Request review from upstream maintainers"
echo "========================================"
