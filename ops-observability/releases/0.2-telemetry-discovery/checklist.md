# Release 0.2 Checklist — Telemetry Discovery

## Gate 0 — Scope

- [ ] Release classified as internal tooling.
- [ ] No upstream PR planned.
- [ ] Output artifacts are evidence-only.
- [ ] DB access is read-only.
- [ ] No raw rows are emitted.
- [ ] No player identifiers are emitted.
- [ ] No coordinates are emitted.
- [ ] No secrets/tokens/passwords are emitted.

## Gate 1 — Design

- [ ] Tool spec created.
- [ ] Data source documented.
- [ ] Output schema documented.
- [ ] Classification rules documented.
- [ ] Forbidden-field patterns documented.
- [ ] Safe aggregate rules documented.
- [ ] Exit codes documented.
- [ ] Evidence path documented.

## Gate 2 — Implementation

- [ ] Tool runs locally.
- [ ] Tool discovers tables.
- [ ] Tool discovers columns.
- [ ] Tool captures row counts.
- [ ] Tool estimates cardinality using aggregate-only queries.
- [ ] Tool classifies fields.
- [ ] Tool writes JSON inventory.
- [ ] Tool writes Markdown catalog.
- [ ] Tool writes safe query candidates.
- [ ] Tool writes forbidden-field report.
- [ ] Tool handles missing DB safely.
- [ ] Tool handles empty tables safely.

## Gate 3 — Verification

- [ ] `db-schema-inventory.json` generated.
- [ ] `db-telemetry-catalog.md` generated.
- [ ] `safe-query-candidates.sql` generated.
- [ ] `forbidden-field-report.txt` generated.
- [ ] `tool-run-output.txt` generated.
- [ ] `privacy-scan-output.txt` generated.
- [ ] Privacy scan passed.
- [ ] No unsafe query candidates generated.
- [ ] Every discovered field classified or marked unknown.
- [ ] Evidence reviewed.

## Gate 4 — Release

- [ ] Release decision written.
- [ ] Safe candidates approved.
- [ ] Sensitive candidates marked for review.
- [ ] Unsafe candidates rejected.
- [ ] Unknown candidates deferred.
- [ ] Release 0.3 backlog created.

## Current Release 0.2 Progress

- [x] Preserved SQL scripts copied into internal tooling.
- [x] Initial SQL source review generated.
- [x] Safe aggregate candidate SQL created.
- [x] Rejected/rewrite-required SQL list created.
- [x] Sensitive-review SQL list created.
- [ ] Discovery runner implemented.
- [ ] Discovery runner executed against E2E database.
- [ ] JSON schema inventory generated.
- [ ] Markdown telemetry catalog generated.
- [ ] Privacy scan executed.
- [ ] Release decision written.

## Runner Validation — 2026-07-02

- [x] Container-aware discovery runner implemented.
- [x] Runner executed against `dune-postgres`.
- [x] Safe SQL pattern scan passed.
- [x] Safe aggregate query execution passed.
- [x] Result privacy scan passed.
- [x] Release decision written.
