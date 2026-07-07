# Code Review Checklist

Use this checklist for every PR review. All items must be verified before merge.

## Schema & Database

- [ ] All column names probed against live schema (not assumed). Use `columnsFor()` + `firstExistingColumn()` — never hardcode column names.
- [ ] All `tableExists()` checks present before querying any table.
- [ ] Joins use dynamically resolved column names via `quoteIdentifier()`.
- [ ] No raw SQL interpolation of user input. All parameterized via `db.query(text, values)`.
- [ ] `SELECT *` never used. Explicit column lists only.
- [ ] Aggregate queries only — no individual row-level data exposed.

## Error Handling

- [ ] All bridge action queries wrapped in `try/catch` with graceful fallback to empty results.
- [ ] Table/column missing → returns empty/default object, not a thrown error.
- [ ] Transient errors (ECONNREFUSED, ECONNRESET, "does not exist") suppressed per `runBackgroundTick` pattern.
- [ ] Bridge response always returns `{ ok: true, result }` on success, `{ error: "..." }` on failure.
- [ ] Audit log entries are present for every bridge action invocation.

## Security

- [ ] No PII in any response field: no player IDs, account IDs, character names, FLS identifiers, coordinates, tokens, passwords, secrets.
- [ ] No raw SQL returned to client.
- [ ] Permission check via `assertInstalledAddonPermission()` before any data access.
- [ ] Rate limiting inherited via `bridgeRateLimiter` (no bypass).
- [ ] File writes use `{ mode: 0o600 }` followed by `chmodSync` (defense-in-depth).

## Idempotency & Restart Safety

- [ ] Poller/background task has lock boolean to prevent overlapping runs.
- [ ] State snapshots stored in `runtime/generated/` with mode 0600.
- [ ] First-run behavior is safe: no false positives from empty/missing state files.
- [ ] Restart doesn't duplicate work or re-process already-handled events.
- [ ] `setInterval(...).unref?.()` used to avoid blocking process exit.

## Bridge Contract

- [ ] Response schema documented in `docs/architecture/V{X}-BRIDGE-CONTRACTS.md`.
- [ ] Response shape matches what the addon's `render{Name}()` function expects.
- [ ] Empty/default response uses the same structure as populated response (no missing fields).
- [ ] All numeric fields are `Number()` cast before return.

## Testing

- [ ] Unit tests pass: `node --test console/api/test/*.test.js` — 250 tests, 0 failures.
- [ ] Metrics tests pass: `bash tests/metrics-stack-unit.sh` — 16/16.
- [ ] Pre-commit hooks pass: `pre-commit run --all-files` — 10/10.
- [ ] Security checks pass: `BASE_REF=upstream/main bash tests/security-pr-checks.sh`.
- [ ] Bridge smoke test passes: `bash tests/bridge-smoke-test.sh`.
- [ ] Death poller behavior verified: no false positives on empty snapshot.

## Dependencies

- [ ] Code only depends on existing tables/functions already in the upstream schema.
- [ ] New `import` statements reference modules that exist in the upstream codebase.
- [ ] No imports from addon repo or e2e workspace that won't exist upstream.
- [ ] No hardcoded local paths (`/home/darkdante/`, `e2e-integration`, etc.).

## Review Signature

```text
Reviewer: ___________
Date: _______________
Result: [ ] Approved  [ ] Changes Requested  [ ] Blocked
```
