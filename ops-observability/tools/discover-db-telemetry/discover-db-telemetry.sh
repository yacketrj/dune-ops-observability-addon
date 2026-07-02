#!/usr/bin/env bash
set -u

BASE="${HOME}/dune-work"
OPS="${BASE}/ops-observability"
TOOL="${OPS}/tools/discover-db-telemetry"
REL="${OPS}/releases/0.2-telemetry-discovery"
EVD="${OPS}/evidence/releases/0.2-telemetry-discovery"
SAFE_SQL="${TOOL}/sql/safe-query-candidates.sql"
RUN_LOG="${EVD}/tool-run-output.txt"
PRIVACY_LOG="${EVD}/privacy-scan-output.txt"
RESULT_SQL="${EVD}/safe-query-output.txt"
DECISION="${EVD}/release-decision.md"

mkdir -p "$EVD"
: > "$RUN_LOG"
: > "$PRIVACY_LOG"
: > "$RESULT_SQL"

log() {
  printf "%s\n" "$*" | tee -a "$RUN_LOG"
}

fail() {
  log "ERROR: $*"
  exit 1
}

log "== discover-db-telemetry Release 0.2 =="
log "date: $(date -Is)"
log "tool: $TOOL"
log "evidence: $EVD"

command -v psql >/dev/null 2>&1 || fail "psql not found"
[ -f "$SAFE_SQL" ] || fail "missing safe SQL file: $SAFE_SQL"

log "== safe SQL file =="
log "$SAFE_SQL"
wc -l "$SAFE_SQL" | tee -a "$RUN_LOG"

log "== unsafe SQL pattern scan =="
UNSAFE_PATTERN="select[[:space:]]+\\*|insert[[:space:]]|update[[:space:]]|delete[[:space:]]|drop[[:space:]]|truncate[[:space:]]|alter[[:space:]]|create[[:space:]]|grant[[:space:]]|revoke[[:space:]]|copy[[:space:]]|player_id|playerid|account_id|character_name|funcom|fls|actor_id|coord|coordinate|location|position|pos_x|pos_y|pos_z|token|password|secret|session|cookie|auth|credential|payload|blob|serialized"
if grep -RInE "$UNSAFE_PATTERN" "$SAFE_SQL" > "$PRIVACY_LOG"; then
  cat "$PRIVACY_LOG" | tee -a "$RUN_LOG"
  fail "privacy scan failed for safe SQL candidates"
else
  printf "%s\n" "privacy scan passed for safe SQL candidates" | tee -a "$PRIVACY_LOG" "$RUN_LOG"
fi

log "== database connection =="
if [ -z "${DATABASE_URL:-}" ]; then
  log "DATABASE_URL is not set. Set DATABASE_URL or provide psql environment variables before running."
  log "Example variables: PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD"
  exit 3
fi

log "DATABASE_URL is set; value will not be printed."

log "== executing safe aggregate candidates =="
if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$SAFE_SQL" > "$RESULT_SQL" 2>> "$RUN_LOG"; then
  log "safe aggregate query execution passed"
else
  log "safe aggregate query execution failed"
  exit 1
fi

log "== result privacy scan =="
RESULT_PATTERN="player_id|playerid|account_id|character_name|funcom|fls|actor_id|coord|coordinate|location|position|pos_x|pos_y|pos_z|token|password|secret|session|cookie|auth|credential|payload|blob|serialized"
if grep -RInE "$RESULT_PATTERN" "$RESULT_SQL" >> "$PRIVACY_LOG"; then
  cat "$PRIVACY_LOG" | tee -a "$RUN_LOG"
  log "result privacy scan failed"
  exit 2
else
  printf "%s\n" "result privacy scan passed" | tee -a "$PRIVACY_LOG" "$RUN_LOG"
fi

log "== writing release decision stub =="
: > "$DECISION"
printf "%s\n" "# Release 0.2 Decision" >> "$DECISION"
printf "%s\n" "" >> "$DECISION"
printf "%s\n" "Release: 0.2 Telemetry Discovery" >> "$DECISION"
printf "%s\n" "Decision: Pending Review" >> "$DECISION"
printf "%s\n" "Date: $(date -Is)" >> "$DECISION"
printf "%s\n" "Evidence path: $EVD" >> "$DECISION"
printf "%s\n" "" >> "$DECISION"
printf "%s\n" "## Generated Evidence" >> "$DECISION"
printf "%s\n" "" >> "$DECISION"
printf "%s\n" "- tool-run-output.txt" >> "$DECISION"
printf "%s\n" "- privacy-scan-output.txt" >> "$DECISION"
printf "%s\n" "- safe-query-output.txt" >> "$DECISION"
printf "%s\n" "- safe-query-candidates.sql" >> "$DECISION"
printf "%s\n" "- rejected-or-rewrite-required.sql" >> "$DECISION"
printf "%s\n" "- sensitive-review-candidates.sql" >> "$DECISION"

log "Release 0.2 runner completed. Decision remains pending human review."
