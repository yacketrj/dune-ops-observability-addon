# PR: Governance Templates and Gates

Status: Draft
Branch: `docs/governance-templates`
Base: `main`
Release: `unreleased`

## Summary

Adds reusable governance templates, local gate scripts, and branch protection documentation.

## Why

The repository requirements document established standing PR, release, security, SBOM, and SOC2-style evidence requirements. This PR creates the reusable files needed to apply those requirements consistently.

## Deliverables

- PR body template
- PR validation template
- PR security output template
- PR risk review template
- SBOM impact template
- SOC2-style controls template
- Shift-left security gate template
- Release gate template
- Risk acceptance template
- Release decision template
- Shift-left security script
- PR gate script
- Release gate script
- Branch protection requirements document

## Validation Output

Pending.

## Security Output

Pending.

## Risks

- Gate scripts are initial baselines and may need local path/tooling refinements after first execution.
- GitHub contents API records shell scripts without executable bit; run with `bash <script>` unless local chmod is applied in a follow-up commit.

## Rollback

Revert this PR.
