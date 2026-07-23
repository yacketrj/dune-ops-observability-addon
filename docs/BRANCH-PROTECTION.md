# Branch Protection Requirements

## Purpose

`main` must be protected so pull requests cannot merge until required checks have completed and passed.

## A note on team size

This repository has one maintainer. A required-approving-review count is
**not** part of this document's required settings, and should not be added:
with exactly one contributor, "require 1 approval" either blocks the
maintainer from merging their own work, or is satisfied by self-approval,
which is not a real control. Everything below is scoped to what a solo
maintainer can meaningfully configure and comply with — protecting the
maintainer from their own mistakes (an accidental force-push, a
`--no-verify` commit under time pressure, forgetting to open a PR), not
requiring a second person who doesn't exist on this project.

## Protected Branch

```text
main
```

## Required Settings

Enable the following protections for `main`:

- require status checks to pass before merging;
- require branches to be up to date before merging;
- do not allow force pushes;
- do not allow branch deletion.

Deliberately **not** enabled: "require a pull request before merging" (this
would still allow a self-merge with no meaningful review step given a single
contributor, while adding friction for hotfixes) and any required-approving-
review count (see "A note on team size" above). Direct pushes to `main`
remain possible for the maintainer, gated only by required status checks —
this matches how `acp-landing`, `Arrakis-Control-Panel`, and
`dune-awakening-selfhost-docker` are configured for the same owner.

## Required Checks

Use the exact check names shown in the GitHub PR checks panel.

This repository runs two parallel CI setups: `.github/workflows/ci.yml` (a
monolithic workflow with its own working `CI Gate` aggregation job — job
IDs `shellcheck`, `validate-json`, `npm-audit`, `security` all live in the
*same* workflow file, so its `needs:` list resolves correctly) and a set of
split single-purpose workflows (`validate.yml`, `pre-commit.yml`,
`sast.yml`, `secret-scan.yml`, `filesystem-scan.yml`,
`security-gates.yml`) that duplicate much of the same scanning. A prior,
separate `.github/workflows/ci-gate.yml` attempted to aggregate the split
workflows into a second "CI Gate"-named job, but its `needs:` list
referenced job IDs (`validate`, `pre-commit`, `semgrep`, `gitleaks`,
`trivy`) defined in those *other* workflow files — GitHub Actions `needs:`
can only reference jobs within the same workflow file, so that job failed
its own startup validation on every single run and was removed rather than
fixed, since `ci.yml`'s own `CI Gate` already provides a working
aggregation for its four jobs. Required check set, current as of this
writing — verify against the live PR checks panel before applying, since
new checks may be added over time:

```text
CI Gate
validate
pre-commit
semgrep
gitleaks
trivy
```

`CI Gate` (from `ci.yml`) already covers Shell Lint, Validate JSON, NPM
Audit, and Security Scanning (gitleaks + semgrep + trivy) as its own
prerequisite jobs — only the five checks from the split workflows need to
be listed separately, since they have no aggregating gate of their own.

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
