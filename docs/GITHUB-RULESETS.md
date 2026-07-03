# GitHub Rulesets Setup

## Purpose

This document turns the branch protection requirement into an actionable setup guide for this repository.

The goal is to prevent merges to `main` until required pull request checks have completed and passed.

## Protected Target

Protect this branch:

```text
main
```

## Required Merge Policy

All changes must use the PR route.

Direct pushes to `main` should be blocked.

PRs must not merge until required checks complete and pass.

## Recommended Ruleset

Create a repository ruleset named:

```text
main-required-pr-and-checks
```

Target branch pattern:

```text
main
```

Enforcement status:

```text
Active
```

## Required Rules

Enable these rules:

- restrict deletions;
- restrict non-fast-forward updates;
- require a pull request before merging;
- require conversation resolution before merging;
- require status checks to pass;
- require branches to be up to date before merging;
- block force pushes;
- block direct pushes to `main`.

## Required Status Checks

Use the exact check names displayed in the PR checks panel.

Current required checks:

```text
Pre-commit / pre-commit (pull_request)
Secret Scan
Filesystem Scan
Validate addon
SAST
```

## Admin and Bypass Policy

Normal work must not bypass required rules.

If GitHub allows repository admins to bypass rules, disable bypass where possible.

Emergency bypass requires a documented risk acceptance before or immediately after the bypass.

Required bypass evidence:

- PR or commit affected;
- failed or unavailable rule;
- reason for bypass;
- risk severity;
- compensating controls;
- follow-up remediation;
- approving reviewer.

## Setup Steps

1. Open repository settings.
2. Open Rules or Rulesets.
3. Create a new branch ruleset.
4. Name it `main-required-pr-and-checks`.
5. Target branch `main`.
6. Set enforcement to active.
7. Require pull requests before merge.
8. Require required checks to pass.
9. Require the branch to be up to date before merge.
10. Require conversation resolution.
11. Add each required status check exactly as GitHub displays it.
12. Block force pushes and branch deletion.
13. Save the ruleset.
14. Open a test PR with a failing check and verify merge is blocked.
15. Open or update a passing PR and verify merge is allowed only after all checks complete.

## Verification Checklist

- [ ] Direct push to `main` is blocked.
- [ ] PR merge is blocked while checks are pending.
- [ ] PR merge is blocked when any required check fails.
- [ ] PR merge is allowed after all required checks complete and pass.
- [ ] Draft PRs cannot merge.
- [ ] Required conversations must be resolved before merge.
- [ ] Emergency bypass requires tracked risk acceptance.

## Required Evidence Path

Ruleset changes should be documented under:

```text
ops-observability/releases/unreleased/prs/
```

For release-specific changes, use:

```text
ops-observability/releases/<release-id>/prs/
```

## Current Limitation

GitHub rulesets are configured in repository settings, not by this documentation file.

This document records the required configuration. The repository owner must still apply the ruleset in GitHub.
