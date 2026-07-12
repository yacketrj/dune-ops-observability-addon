#!/usr/bin/env bash
# deploy-clean.sh — Deploy a clean upstream stack with ONLY a fix branch applied.
# Web UI only. RBAC (or any other) stack is untouched.
#
# Usage: ./deploy-clean.sh <fix-branch>
# Example: ./deploy-clean.sh fix/clean-deploy

set -euo pipefail

FIX_BRANCH="${1:-}"
[ -z "$FIX_BRANCH" ] && { echo "Usage: $0 <fix-branch>"; exit 1; }

REPO="/home/darkdante/dune-awakening-selfhost-docker"
ADDON="/home/darkdante/dune-docker-addon"
CLEAN="$ADDON/e2e-clean"
UPSTREAM="https://github.com/Red-Blink/dune-awakening-selfhost-docker.git"
UID_HOST=$(id -u)
GID_HOST=$(id -g)

echo "============================================="
echo "  CLEAN DEPLOY: $FIX_BRANCH"
echo "============================================="

# ─── 0. Stop any running clean stack ───
docker rm -f $(docker ps -aq --filter "name=dune") 2>/dev/null || true

# ─── 1. Sync with upstream, cut clean branch ───
echo "=== 1. Sync + cut branch ==="
cd "$REPO"
git fetch upstream main --quiet 2>/dev/null || true
git checkout upstream/main --quiet 2>/dev/null
git branch -D "$FIX_BRANCH" 2>/dev/null || true
git checkout -b "$FIX_BRANCH" upstream/main --quiet 2>/dev/null

# Get the fix from the remote branch
git show "origin/$FIX_BRANCH:console/api/src/server.js" 2>/dev/null > console/api/src/server.js || {
    echo "ERROR: Cannot get server.js from origin/$FIX_BRANCH"
    exit 1
}
echo "  Branch: $FIX_BRANCH"
git diff upstream/main --stat | tail -1

# ─── 2. Fresh clone ───
echo "=== 2. Fresh clone ==="
sudo rm -rf "$CLEAN" 2>/dev/null
git clone "$UPSTREAM" "$CLEAN" --quiet 2>/dev/null
sudo chown -R "$USER:$USER" "$CLEAN"

# Apply the fix
cp "$REPO/console/api/src/server.js" "$CLEAN/console/api/src/server.js"

# Validate: only server.js should differ from upstream
EXTRA=$(cd "$CLEAN" && git diff --name-only HEAD 2>/dev/null | grep -v "server.js" || true)
if [ -n "$EXTRA" ]; then
    echo "  FAIL: Working tree has extra changes:"
    echo "$EXTRA"
    exit 1
fi
echo "  ✓ Clean — only server.js differs"

# ─── 3. Configure .env ───
echo "=== 3. Configure .env ==="
cat > "$CLEAN/.env" << EOF
SERVER_IP=50.123.64.61
SERVER_IP_MODE=public
DOCKER_SOCKET_GID=986
DUNE_HOST_UID=$UID_HOST
DUNE_HOST_GID=$GID_HOST
DUNE_HOST_REPO_ROOT=$CLEAN
EOF
echo "  DUNE_HOST_UID=$UID_HOST  DUNE_HOST_GID=$GID_HOST"

# ─── 4. Fix ownership ───
echo "=== 4. Fix ownership ==="
sudo chown -R "$USER:$USER" "$CLEAN"
rm -rf "$CLEAN/runtime/secrets" "$CLEAN/runtime/generated"
mkdir -p "$CLEAN/runtime/secrets" "$CLEAN/runtime/generated"

# ─── 5. Build web UI ───
echo "=== 5. Build web UI ==="
cd "$CLEAN/console/web"
npm install --silent 2>&1 | tail -1
npm run build 2>&1 | tail -1

# ─── 6. Start web UI only ───
echo "=== 6. Start web UI ==="
cd "$CLEAN"
DUNE_HOST_UID=$UID_HOST DUNE_HOST_GID=$GID_HOST \
    docker compose -f docker-compose.web.yml up -d --force-recreate redblink-dune-docker-console 2>&1 | tail -1
sleep 5
docker cp console/web/dist/. redblink-dune-docker-console:/app/web-dist/ 2>/dev/null || true
docker restart redblink-dune-docker-console >/dev/null 2>&1 || true
sleep 5

# ─── 7. Validate ───
echo "=== 7. Validate ==="

HEALTH=$(curl -s --max-time 5 http://localhost:8088/api/health 2>/dev/null || echo "FAIL")
echo "  Health: $HEALTH"

CUID=$(docker exec redblink-dune-docker-console id -u 2>/dev/null || echo "?")
if [ "$CUID" = "$UID_HOST" ]; then
    echo "  UID match: $CUID = $UID_HOST ✓"
else
    echo "  UID: container=$CUID host=$UID_HOST (may need DUNE_HOST_UID in .env)"
fi

docker exec redblink-dune-docker-console touch /repo/runtime/secrets/.test 2>/dev/null || true
OWNER=$(stat -c '%U:%G' "$CLEAN/runtime/secrets/.test" 2>/dev/null || echo "?")
docker exec redblink-dune-docker-console rm /repo/runtime/secrets/.test 2>/dev/null || true
[ "$OWNER" = "$USER:$USER" ] && echo "  Ownership: $OWNER ✓" || echo "  Ownership: $OWNER ✗"

FIX_LINE=$(docker exec redblink-dune-docker-console grep "itemRequiresDatabaseGrant" /app/src/server.js 2>/dev/null | head -c 80 || echo "FIX NOT FOUND")
echo "  Fix: $FIX_LINE"
echo "  Container: $(docker exec redblink-dune-docker-console id -u -n 2>/dev/null) ($CUID)"

PASS=$(docker exec redblink-dune-docker-console cat runtime/secrets/admin-web-password.txt 2>/dev/null || echo "check console")

echo ""
echo "============================================="
echo "  CLEAN STACK — WEB UI ONLY"
echo "============================================="
echo "  URL:      http://50.123.64.61:8088"
echo "  Password: $PASS"
echo "  Branch:   $FIX_BRANCH"
echo "============================================="
