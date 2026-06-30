# Release Testing v0.1.1

Capture final output before opening the community addon index PR.

## Local validation

```bash
node scripts/validate.js
```

## Shift-left security

```bash
pre-commit run --all-files
```

## Package validation

```bash
bash scripts/package.sh
sha256sum dist/dune-ops-observability-0.1.1.zip
```

## GitHub checks

Confirm the following checks are green before tagging and submitting to the community index:

- Validate addon
- Pre-commit
- Secret Scan / Gitleaks
- SAST / Semgrep
- Filesystem Scan / Trivy
- Release addon

## Community index PR fields

Use the captured output for:

- Summary
- Why is it needed?
- Test output
- Security output
- Permissions requested
- Review notes
