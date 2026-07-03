# PR: Pin GitHub Actions

Status: Draft
Branch: `security/pin-github-actions`
Base: `main`
Release: `unreleased`

## Summary

Pins GitHub Actions workflow `uses:` references to full 40-character commit SHAs.

## Why

Local Semgrep reported blocking supply-chain findings for mutable GitHub Actions tags and branches. Pinning action references prevents silent upstream tag or branch movement from changing workflow behavior.

## Findings Addressed

- `.github/workflows/filesystem-scan.yml`
- `.github/workflows/pre-commit.yml`
- `.github/workflows/release.yml`
- `.github/workflows/sast.yml`
- `.github/workflows/secret-scan.yml`
- `.github/workflows/validate.yml`

## Validation Output

Pending.

## Security Output

Pending.

## Risks

- Pinned actions require intentional maintenance to pick up upstream updates.
- Semgrep action repository is archived; this PR only pins the existing action reference and does not replace it.

## Rollback

Revert this PR.
