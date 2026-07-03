# Branch Protection Requirements

## Purpose

`main` must be protected so pull requests cannot merge until required checks have completed and passed.

## Protected Branch

```text
main
```

## Required Settings

Enable the following protections for `main`:

- require a pull request before merging;
- require status checks to pass before merging;
- require branches to be up to date before merging;
- require conversation resolution before merging;
- do not allow bypassing the configured protections;
- do not allow force pushes;
- do not allow branch deletion.

## Required Checks

Use the exact check names shown in the GitHub PR checks panel.

Current required check set:

```text
Pre-commit / pre-commit (pull_request)
Secret Scan
Filesystem Scan
Validate addon
SAST
```

## Bypass Policy

Bypass should not be used for normal work.

Emergency bypass requires a tracked risk acceptance that includes:

- reason for bypass;
- impacted PR or release;
- failed or unavailable check;
- compensating control;
- follow-up remediation;
- approver.

## Merge Policy

A PR may merge only after:

- required checks are complete and passing;
- the PR body is populated;
- tracked PR documentation exists when required;
- review conversations are resolved;
- risks are documented;
- rollback is documented.
