#!/usr/bin/env bash
# deploy-clean.sh — Deploy a clean upstream stack with ONLY a fix branch applied.
# Web UI only. RBAC (or any other) stack is untouched.
#
# Usage: ./deploy-clean.sh <fix-branch> [--skip-tests] [--clean-secrets] [file1 file2 ...]
# Options:
#   --skip-tests      Skip post-deploy test suite
#   --clean-secrets   Create fresh secrets/generated dirs instead of copying from RBAC stack
# Example: ./deploy-clean.sh fix/clean-deploy
# Example: ./deploy-clean.sh fix/clean-deploy --skip-tests console/api/src/server.js

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/deploy-lib.sh"

# Parse arguments
FIX_BRANCH=""
SKIP_TESTS="false"
FILES=()

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
      else
        FILES+=("$arg")
      fi
      ;;
  esac
done

FIX_BRANCH=$(require_branch "$FIX_BRANCH")
check_repo_exists

echo "============================================="
echo "  CLEAN DEPLOY: $FIX_BRANCH (WEB UI ONLY)"
echo "============================================="

stop_all_dune_containers
fresh_clone

# Apply files
if [ ${#FILES[@]} -eq 0 ]; then
  apply_fix_branch_files "$FIX_BRANCH"
else
  for file in "${FILES[@]}"; do
    apply_single_file "$FIX_BRANCH" "$file"
  done
fi

configure_env
fix_permissions
build_web_ui
start_web_console
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
run_post_deploy_tests "WEB UI ONLY" "$SKIP_TESTS" || {
  error "Post-deploy tests failed, but stack is running"
  error "Run tests manually: cd $CLEAN && bash tests/dune-cli-test.sh"
}

print_summary "WEB UI ONLY" "$FIX_BRANCH"
