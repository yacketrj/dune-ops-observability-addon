# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.4.x   | :white_check_mark: |
| < 0.4   | :x:                |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

1. Go to the [Security Advisories](https://github.com/yacketrj/dune-ops-observability-addon/security/advisories/new) page and submit a private report.
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Affected version(s)
   - Potential impact
3. You will receive an acknowledgment within 48 hours.
4. We will investigate and respond with a remediation plan within 7 days.

## Secret Exposure Response

If you discover exposed secrets (API keys, tokens, passwords):

1. **Do not share, copy, or use the secret.**
2. Report it via the private advisory process above.
3. The maintainer will rotate the secret and patch the exposure within 24 hours.

## Security Scope

This addon is a **read-only UI component** rendered inside the Dune Docker Console iframe. It:

- Requests only `ops:read` permission
- Communicates via same-origin `postMessage` bridge
- Does not make direct network calls to external services
- Does not access databases, webhooks, or localhost APIs
- Contains no server-side code or container runtime

## Security Gates

All merges require passing:

- **Gitleaks** — secret scanning
- **Semgrep** — SAST (p/default + p/secrets)
- **Trivy** — filesystem scan (vuln, misconfig, secret)
- **npm audit** — dependency vulnerability check (moderate+)
- **Dependency review** — PR-level vulnerability blocking
- **Pre-commit hooks** — local fast feedback

Weekly scheduled security scans run every Monday at 09:17 UTC.

## Related Documentation

- [Pre-release Security Checklist](docs/security/PRE-RELEASE-SECURITY.md)
- [Security Gates](docs/security/SECURITY-GATES.md)
- [Shift-Left Security](docs/security/SHIFT-LEFT-SECURITY.md)
- [API Security Test](docs/security/API-SECURITY-TEST.md)
