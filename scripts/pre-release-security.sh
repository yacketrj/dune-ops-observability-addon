#!/usr/bin/env bash
# pre-release-security.sh — Full security scan before cutting a release tag.
# Runs gitleaks, trivy, semgrep, npm audit, shellcheck, and API DAST.
# Produces evidence reports under the release evidence directory.
#
# Usage: bash scripts/pre-release-security.sh v0.4.0 [--ci]
#   v0.4.0     Release version tag
#   --ci       Skip API DAST (no running Console in CI)

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Usage: bash scripts/pre-release-security.sh <version> [--ci]"
  echo "Example: bash scripts/pre-release-security.sh v0.4.0"
  exit 1
fi

SKIP_DAST=false
if [ "${2:-}" = "--ci" ]; then
  SKIP_DAST=true
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Not inside a git repository."; exit 1
}
cd "$REPO_ROOT"

EVIDENCE_DIR="ops-observability/evidence/releases/${VERSION}/security"
mkdir -p "$EVIDENCE_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
PASSED=0; FAILED=0; SKIPPED=0

run_gate() {
  local label="$1" cmd="$2" output_file="$3"
  echo -n "  [$label] "
  if [ -n "${4:-}" ] && [ "$4" != "" ] && ! command -v "${4%% *}" >/dev/null 2>&1; then
    echo -e "${YELLOW}SKIP${NC} (${4%% *} not installed)"
    SKIPPED=$((SKIPPED+1))
    return
  fi
  if eval "$cmd" > "$EVIDENCE_DIR/$output_file" 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED+1))
  else
    echo -e "${RED}FAIL${NC} — see $EVIDENCE_DIR/$output_file"
    FAILED=$((FAILED+1))
  fi
}

echo "=== Pre-Release Security Scan: $VERSION ==="
echo "Evidence: $EVIDENCE_DIR"
echo

# ─── GITLEAKS ───
if command -v gitleaks >/dev/null 2>&1; then
  run_gate "gitleaks" \
    "gitleaks detect --redact --report-format json --report-path '$EVIDENCE_DIR/gitleaks-report.json' --log-level error" \
    "gitleaks-report.json" \
    "gitleaks"
else
  SKIPPED=$((SKIPPED+1)); echo -e "  [gitleaks] ${YELLOW}SKIP${NC} (not installed)"
fi

# ─── TRIVY ───
if command -v trivy >/dev/null 2>&1; then
  TRIVY_IGNORE=""
  [ -f .trivyignore ] && TRIVY_IGNORE="--ignorefile .trivyignore"
  run_gate "trivy" \
    "trivy fs --scanners secret,misconfig --severity HIGH,CRITICAL $TRIVY_IGNORE --format json --output '$EVIDENCE_DIR/trivy-report.json' ." \
    "trivy-report.json" \
    "trivy"
else
  SKIPPED=$((SKIPPED+1)); echo -e "  [trivy] ${YELLOW}SKIP${NC} (not installed)"
fi

# ─── SEMGREP ───
if command -v semgrep >/dev/null 2>&1; then
  run_gate "semgrep" \
    "semgrep --config p/default --quiet --json --output '$EVIDENCE_DIR/semgrep-report.json'" \
    "semgrep-report.json" \
    "semgrep"
else
  SKIPPED=$((SKIPPED+1)); echo -e "  [semgrep] ${YELLOW}SKIP${NC} (not installed)"
fi

# ─── NPM AUDIT ───
if [ -f console/api/package-lock.json ]; then
  run_gate "npm-audit" \
    "npm audit --audit-level=high --prefix console/api" \
    "npm-audit-output.txt" \
    "npm"
else
  SKIPPED=$((SKIPPED+1)); echo -e "  [npm-audit] ${YELLOW}SKIP${NC} (no package-lock.json)"
fi

# ─── SHELLCHECK ───
if command -v shellcheck >/dev/null 2>&1; then
  run_gate "shellcheck" \
    "shellcheck runtime/scripts/*.sh runtime/scripts/**/*.sh tests/*.sh 2>/dev/null" \
    "shellcheck-output.txt" \
    "shellcheck"
else
  SKIPPED=$((SKIPPED+1)); echo -e "  [shellcheck] ${YELLOW}SKIP${NC} (not installed)"
fi

# ─── SECURITY PR CHECKS ───
run_gate "sec-checks" \
  "bash tests/security-pr-checks.sh" \
  "security-pr-checks-output.txt" \
  "bash"

# ─── API DAST ───
if [ -f tests/api-security-test.sh ]; then
  if $SKIP_DAST; then
    echo -e "  [api-dast] ${YELLOW}SKIP${NC} (--ci mode, no running Console)"
    SKIPPED=$((SKIPPED+1))
  elif docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'redblink-dune-docker-console'; then
    run_gate "api-dast" \
      "bash tests/api-security-test.sh" \
      "api-security-output.txt" \
      "bash"
  else
    echo -e "  [api-dast] ${YELLOW}SKIP${NC} (Console not running)"
    SKIPPED=$((SKIPPED+1))
  fi
else
  SKIPPED=$((SKIPPED+1)); echo -e "  [api-dast] ${YELLOW}SKIP${NC} (no test script)"
fi

# ─── EVIDENCE MANIFEST ───
cat > "$EVIDENCE_DIR/evidence-manifest.txt" <<EOF
Pre-release security scan for $VERSION
Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Repository: $(git remote get-url origin 2>/dev/null || echo "unknown")
Revision: $(git rev-parse HEAD)
EOF

# ─── SUMMARY ───
echo
echo "========================================"
echo -e "${GREEN}Passed:  $PASSED${NC}"
echo -e "${RED}Failed:  $FAILED${NC}"
if [ "$SKIPPED" -gt 0 ]; then
  echo -e "${YELLOW}Skipped: $SKIPPED${NC}"
fi
echo "========================================"
echo "Evidence stored in: $EVIDENCE_DIR"
echo

if [ "$FAILED" -gt 0 ]; then
  echo "Pre-release security scan: FAILED"
  echo "Review failure details in $EVIDENCE_DIR before releasing."
  exit 1
fi

echo "Pre-release security scan: PASSED"
echo "Proceed with release tag: git tag -a $VERSION -m \"Release $VERSION\""
exit 0
