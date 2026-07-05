# PR: Gate Toolchain Bootstrap

Status: Draft
Branch: `dev-tools/auto-install-gates`
Base: `main`
Release: `unreleased`

## Summary

Adds a shared local toolchain bootstrap script and wires gate scripts to check for required local tools before running.

## Why

The repo uses external command-line scanners and validators that are not vendored in the source tree. Gate scripts should detect missing tools, bootstrap supported tools where the local environment allows it, and fail closed with clear remediation when bootstrap is not possible.

## Deliverables

- `ops-observability/dev-tools/toolchain-bootstrap.sh`
- Updated quiet gates:
  - `precommit-gate.sh`
  - `gitleaks-gate.sh`
  - `semgrep-gate.sh`
  - `trivy-gate.sh`
  - `security-shift-left.sh`
  - `pr-gate.sh`
  - `release-gate.sh`
- Documentation updates:
  - `README.md`
  - `docs/REPOSITORY-REQUIREMENTS-AND-DELIVERABLES.md`
  - `docs/security/SHIFT-LEFT-SECURITY.md`

## Documentation Impact

```text
README.md: updated
docs/: updated
release docs: not affected
PR tracking docs: updated
```

Documentation drift check:

- [x] README.md reviewed for drift.
- [x] Relevant docs reviewed or updated.
- [x] Release/testing docs reviewed or updated.
- [x] Roadmap or governance docs reviewed or updated.
- [x] Tracked PR documentation updated.
- [x] Deferred documentation: none.

## Validation Output

Pending.

## Security Output

Pending.

## Risks

- Bootstrap behavior depends on the local environment and available package managers.
- `DUNE_AUTO_INSTALL_TOOLS=0` disables bootstrap attempts for detection-only mode.
- Gates fail closed if required tooling cannot be prepared.
- No runtime addon behavior changes.

## Rollback

Revert this PR.
