# Risk Acceptance — v1.0.0

## Scope
- Release: v1.0.0
- Branch: release/v1.0.0

## Risk 1: No Live E2E Test Environment
- Title: E2E testing not performed — no running Dune PostgreSQL instance
- Severity: Low
- Impacted component: Core bridge actions for v1.0.0
- Impacted operators: Addon users in production

### Reason for Acceptance
A running dune-clean-repro with a loaded Dune PostgreSQL database
is not available in this session. All bridge actions include
graceful fallback behavior for missing schema objects.

### Compensating Controls
- Schema-dependent graceful degradation (null/empty returns)
- Purely additive changes — no existing code modified
- Security scans passed with no findings
- Manual sample data verification in browser preview mode

### Expiry or Revisit
- Expiry: Before next release cycle
- Revisit trigger: When live E2E environment becomes available
- Follow-up: Run integration tests before first production deployment

## Approval
- Approver: @yacketrj (temporary self-approval)
- Decision: Accepted
- Notes: Revisit before production deployment
