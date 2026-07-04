# SOC2-Style Controls — v0.6.0

## Scope
- Release: v0.6.0
- Branch: release/v0.6.0

## Change Management
- Change summary: Resources Summary bridge actions + addon UI panels
- Approval path: PR review via GitHub
- Linked PRs: core PR, addon PR, catalog PR
- Release impact: New read-only bridge actions and UI panels

## Access Control
- Permission changes: ops:read (v0.3.0); no new permissions for v0.6.0
- New bridge actions: resources.summary.*
- New data access: Read-only aggregate queries
- Write capability introduced: No

## Security Review
- Security gates completed: Gitleaks, Semgrep, Trivy, git diff --check
- Findings: None
- Risk acceptances: See risk-acceptance.md

## Testing Evidence
- Unit: Schema-dependent; validated via clean-repro (v0.3.0) or deferred
- Regression: No regression — purely additive changes
- E2E: Not applicable (no E2E suite for console API)
- Manual verification: Sample data in browser preview

## Data Handling / Privacy Review
- Data categories touched: Aggregate player/ops counts only
- Prohibited categories touched: No
- Evidence sanitized: Yes

## Rollback Plan
- Rollback process: Revert PR; remove release tag; remove catalog entry
- Recovery assumptions: Core schema changes are backward compatible

## Audit Trail
- PR: Tracked under releases/0.6.0-0-6-0/prs/
- Checks: Gitleaks clean, Semgrep clean, Trivy clean
- Release decision: See release-decision.md
- Evidence path: releases/0.6.0-0-6-0/evidence/
