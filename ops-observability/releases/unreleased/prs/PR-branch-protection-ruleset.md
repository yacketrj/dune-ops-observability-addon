# PR: GitHub Rulesets and Branch Protection

Status: Draft
Branch: `docs/github-rulesets`
Base: `main`
Release: `unreleased`

## Summary

Adds an actionable GitHub ruleset setup guide and branch protection risk acceptance template.

## Why

The repository now requires the PR route and passing checks before merge. This PR documents the exact ruleset configuration needed to enforce that requirement at the repository level.

## Deliverables

- `docs/GITHUB-RULESETS.md`
- `ops-observability/dev-tools/templates/branch-protection-risk-acceptance-template.md`
- `ops-observability/releases/unreleased/prs/PR-branch-protection-ruleset.md`

## Validation Output

Pending.

## Security Output

Pending.

## Risks

- This PR documents ruleset setup but does not apply GitHub repository settings automatically.
- Repository owner must configure the ruleset in GitHub settings.

## Rollback

Revert this PR.
