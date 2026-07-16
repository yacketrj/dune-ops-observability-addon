#!/usr/bin/env bash
# deploy-clean-stack.sh — Deploy a clean upstream stack with a fix branch.
# Full stack: orchestrator + game servers + web UI.
# RBAC stack (e2e-integration) is isolated — separate project, separate volumes.
#
# Usage: ./deploy-clean-stack.sh <fix-branch> [--skip-tests] [--clean-secrets]
# Options:
#   --skip-tests      Skip post-deploy test suite
#   --clean-secrets   Create fresh secrets/generated dirs instead of copying from RBAC stack
# To switch back: cd e2e-integration && docker compose up -d

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/deploy-lib.sh"

# Parse arguments
FIX_BRANCH=""
SKIP_TESTS="false"

for arg in "$@"; do
  case "$arg" in
    --skip-tests)
      SKIP_TESTS="true"
      ;;
    --clean-secrets)
      PRESERVE_SECRETS="false"
      ;;
    *)
      if [ -z "$FIX_BRANCH" ]; then
        FIX_BRANCH="$arg"
      fi
      ;;
  esac
done

FIX_BRANCH=$(require_branch "$FIX_BRANCH")
check_repo_exists

echo "=== CLEAN DEPLOY: $FIX_BRANCH ==="
echo "Project: $PROJECT_NAME  |  DB: $DB_VOLUME"

stop_all_dune_containers
stop_clean_stack
fresh_clone
apply_fix_branch_files "$FIX_BRANCH"
configure_env
isolate_db_volume
build_web_ui
fix_permissions
start_full_stack
wait_for_health "http://localhost:8088/api/health" 30

# Validation
log "=== Validation ==="
validate_uid_match || true
validate_ownership || true
validate_mount_source || {
  error "CRITICAL: Container mount source mismatch!"
  error "Container is reading from wrong directory - secrets will not match!"
  error "Aborting deployment."
  exit 1
}
validate_secrets_match || {
  error "CRITICAL: Host and container secrets do not match!"
  error "WebUI login will fail with wrong password."
  error "Aborting deployment."
  exit 1
}

# Run post-deploy tests
run_post_deploy_tests "FULL STACK" "$SKIP_TESTS" || {
  error "Post-deploy tests failed, but stack is running"
  error "Run tests manually: cd $CLEAN && bash tests/dune-cli-test.sh"
}

print_summary "FULL STACK" "$FIX_BRANCH"
