# PR Body Template

Use this template for every pull request unless a release-specific template is stricter.

## Summary

- What changed:
- Files or areas touched:
- Release or roadmap item:

## Why

- Problem being solved:
- Why this belongs in this repository:
- Why this approach was chosen:

## Documentation Impact

```text
README.md: updated / not affected / needs follow-up
docs/: updated / not affected / needs follow-up
release docs: updated / not affected / needs follow-up
PR tracking docs: updated
```

Documentation drift check:

- [ ] README.md reviewed for drift.
- [ ] Relevant docs reviewed or updated.
- [ ] Release notes and release testing docs reviewed or updated.
- [ ] Roadmap or governance docs reviewed or updated.
- [ ] Tracked PR documentation updated.
- [ ] Deferred documentation, if any, is listed with owner and follow-up PR or issue.

## Unit / Regression / E2E Testing Output

### Unit

```text
command:
output:
```

### Regression

```text
command:
output:
```

### E2E

```text
command:
output:
```

Use `Not applicable` only with a short justification.

## Security Output

```text
gitleaks:
semgrep:
trivy:
privacy scan:
SBOM:
```

Security checklist:

- [ ] No secrets or tokens committed.
- [ ] No raw database dumps committed.
- [ ] No player or account identifiers committed.
- [ ] No coordinates or map/location payloads committed.
- [ ] No inventory, economy, guild, Landsraad, resource, or event-log payloads committed.
- [ ] No raw SQL bridge or unsafe DB access introduced.
- [ ] SBOM impact is stated.
- [ ] SOC2-style control impact is stated.

## Risks

- Known limitations:
- Compatibility impact:
- Rollback plan:
- Follow-up work:

## Review State

- [ ] Branch created from current `main`.
- [ ] Required checks completed and passed.
- [ ] PR documentation is tracked under the relevant release folder.
- [ ] Documentation impact is complete.
- [ ] Conversation threads resolved before merge.
