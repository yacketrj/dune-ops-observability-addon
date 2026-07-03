# PR: Pin GitHub Actions

Status: Draft
Branch: `security/pin-github-actions`
Base: `main`
Release: `unreleased`

## Summary

Pins GitHub Actions workflow `uses:` references to full 40-character commit SHAs and quiets local gate output.

## Why

Local Semgrep reported blocking supply-chain findings for mutable GitHub Actions tags and branches. Pinning action references prevents silent upstream tag or branch movement from changing workflow behavior.

The local gate wrappers also reduce noisy scanner output. Passing checks print a single `PASS:` line. Failed checks print `FAIL:` plus compact details about what failed.

## Findings Addressed

- `.github/workflows/filesystem-scan.yml`
- `.github/workflows/pre-commit.yml`
- `.github/workflows/release.yml`
- `.github/workflows/sast.yml`
- `.github/workflows/secret-scan.yml`
- `.github/workflows/validate.yml`

## Quiet Gate Updates

- `ops-observability/dev-tools/precommit-gate.sh`
- `ops-observability/dev-tools/gitleaks-gate.sh`
- `ops-observability/dev-tools/semgrep-gate.sh`
- `ops-observability/dev-tools/trivy-gate.sh`
- `ops-observability/dev-tools/security-shift-left.sh`
- `ops-observability/dev-tools/pr-gate.sh`
- `ops-observability/dev-tools/release-gate.sh`

## Validation Output

Pending.

## Security Output

Pending.

## Risks

- Pinned actions require intentional maintenance to pick up upstream updates.
- Semgrep action repository is archived; this PR only pins the existing action reference and does not replace it.
- Quiet gates intentionally suppress successful command output; rerun the underlying command directly for full verbose diagnostics.

## Rollback

Revert this PR.
