# Catalog PR — v0.6.0

## Summary

- What changed: Update Dune Ops Observability listing to v0.6.0 (version, SHA256, updatedAt)
- Files or areas touched: addons/dune-ops-observability.json, index.json
- Release or roadmap item: v0.6.0

## Why

- Problem being solved: Catalog must reference the correct version for addon auto-update verification
- Why this belongs in this repository: Centralized addon registry requires version-managed listings with SHA256 integrity
- Why this approach was chosen: Each version gets its own branch for independent review and merge sequencing

## Documentation Impact

```
README.md: not affected
docs/: not affected
release docs: updated
PR tracking docs: updated
```

Documentation drift check:

- [x] README.md reviewed for drift
- [x] Relevant docs reviewed or updated
- [x] Release notes and release testing docs reviewed or updated
- [x] Roadmap or governance docs reviewed or updated
- [x] Tracked PR documentation updated

## Unit / Regression / E2E Testing Output

Not applicable — catalog manifest changes are metadata-only.

## Security Output

```
gitleaks: scan completed, no leaks found
semgrep:  no findings
trivy:    no vulns or secrets
SBOM:    not affected
```

Security checklist:

- [x] No secrets or tokens committed
- [x] No raw database dumps committed
- [x] No player or account identifiers committed
- [x] No coordinates or map/location payloads committed
- [x] No inventory, economy, guild, Landsraad, resource, or event-log payloads committed
- [x] No raw SQL bridge or unsafe DB access introduced
- [x] SBOM impact is stated
- [x] SOC2-style control impact is stated

## Risks

- Known limitations: Requires core PR for v0.6.0 to be merged first and addon release artifact available
- Compatibility impact: None
- Rollback plan: Revert SHA256 and version in manifest
- Follow-up work: None

## Review State

- [x] Branch created from current `main`
- [x] Required checks completed and passed
- [x] PR documentation is tracked under the relevant release folder
- [x] Documentation impact is complete
- [ ] Conversation threads resolved before merge
