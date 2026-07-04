# Core PR - v0.5.0

**Status:** Prepared (not submitted)

## Summary
Add bridge actions for version 0.5.0 of the OPS observability roadmap.

## Files Changed
- console/api/src/duneDb.js
- console/api/src/server.js
- console/api/src/addons.js (v0.3.0 only)
- console/api/test/db.test.js (v0.3.0 only)

## Documentation Impact
- README.md: not affected (core repo)
- docs/: not affected
- release docs: not affected
- PR tracking docs: updated

## Security Output
- Gitleaks: no leaks found
- Semgrep: no findings
- Trivy: no vulnerabilities
- Privacy scan: no prohibited data

## Risks
- Schema-dependent: gracefully degrades when tables/columns missing
- Backward compatible: all existing actions unchanged
