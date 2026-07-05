# Security Gates

Security is enforced at three layers: pre-commit, pre-push, and pre-release. Each layer catches different classes of issues. Gates fail closed — any non-zero exit blocks the operation.

## Layer 1: Pre-commit

Runs on every `git commit`. Fast, file-level checks.

| Tool | What it catches | Config | Applies to |
|---|---|---|---|
| `check-json` | Malformed JSON | `.pre-commit-config.yaml` | All repos |
| `check-yaml` | Malformed YAML | `.pre-commit-config.yaml` | All repos |
| `check-merge-conflict` | Unresolved `<<<<<<<` markers | `.pre-commit-config.yaml` | All repos |
| `mixed-line-ending` | Inconsistent CRLF/LF | `.pre-commit-config.yaml` (fixes LF) | All repos |
| `end-of-file-fixer` | Missing final newline | `.pre-commit-config.yaml` | All repos |
| `trailing-whitespace` | Trailing spaces/tabs | `.pre-commit-config.yaml` | All repos |
| `gitleaks` | Hardcoded secrets in staged files | `.gitleaks.toml` (allowlist) | All repos |
| `trivy` | HIGH/CRITICAL secrets in repo | `.trivyignore` (exclusions) | All repos |
| `semgrep` | Code-level vulnerabilities | `.semgrepignore` (exclusions) | All repos |
| `validate-addon-manifest` | Invalid `addon.json` | `scripts/validate.js` | Addon repo |
| `validate-catalog-shas` | SHA-256 mismatch in catalog | `scripts/validate-catalog-shas.sh` | Catalog repo |
| `security-checks` | ShellCheck, keyword review, git diff | `tests/security-pr-checks.sh` | Core repo |

**Installation**:
```bash
pre-commit install
```

**Manual run**:
```bash
pre-commit run --all-files
```

**Bypass** (emergency only):
```bash
git commit --no-verify
```

## Layer 2: Pre-push

Runs on every `git push`. Full-repo scans plus runtime API security testing.

| Tool | What it catches | Scope |
|---|---|---|
| `gitleaks` | Hardcoded secrets across entire repo | All files |
| `trivy` | HIGH/CRITICAL secrets and misconfigurations | All files (respects `.trivyignore`) |
| `semgrep` | Code vulnerabilities (p/default ruleset) | All files (respects `.semgrepignore`) |
| `api-security-test.sh` | Runtime API vulnerabilities (DAST) | Running Console API (skipped if not running) |

**Installation** (shared hook across all repos):
```bash
ln -sf ~/.local/bin/pre-push-gates .git/hooks/pre-push
```

**API security DAST test** (`tests/api-security-test.sh`):
- Validates security headers (X-Content-Type-Options, X-Frame-Options, Referrer-Policy)
- Tests authentication enforcement (401/403 for unauthenticated requests)
- Tests CSRF enforcement (403 for POST without CSRF token)
- Input validation probes (path traversal, SQL injection, XSS, oversized payloads)
- Addon bridge security (invalid IDs, unsupported actions, traversal protection)
- Rate limit enforcement (429 after repeated failed logins)
- Information leakage detection (stack traces, internal paths, Server header)

Run API DAST locally:
```bash
CONSOLE_PORT=8088 bash tests/api-security-test.sh
```

**Bypass** (emergency only):
```bash
git push --no-verify
```

## Layer 3: Pre-release

Runs before cutting a release tag. Produces a signed evidence report.

| Tool | What it checks | Evidence output |
|---|---|---|
| `gitleaks` | Full-history secret scan | `gitleaks-report.json` |
| `trivy` | Filesystem vulnerability + secret scan | `trivy-report.json` |
| `semgrep` | Full static analysis (p/default) | `semgrep-report.json` |
| `npm audit` | Dependency vulnerabilities (HIGH+) | `npm-audit-output.txt` |
| `shellcheck` | Bash script security lints | `shellcheck-output.txt` |
| `api-security-test.sh` | Runtime API security (DAST) | `api-security-output.txt` |
| `security-pr-checks.sh` | Keyword review, git diff check | `security-pr-checks-output.txt` |

**Run pre-release scan**:
```bash
bash scripts/pre-release-security.sh v0.4.0
```

Output goes to `ops-observability/evidence/releases/<release-id>/security/`.

**Exit criteria**:
- Zero unresolved HIGH/CRITICAL findings from all tools
- All SAST findings either fixed or accepted with documented risk
- API DAST test passes (all applicable checks)
- npm audit returns zero HIGH/CRITICAL vulnerabilities
- Security evidence files committed to release evidence bundle

## Tool Allowlists

Each repo maintains exclusion files for known accepted findings:

| File | Purpose |
|---|---|
| `.gitleaks.toml` | Allowlist known hardcoded tokens (e.g., upstream command-auth fallback) |
| `.trivyignore` | Exclude dev TLS certs, test fixtures, upstream assets |
| `.semgrepignore` | Exclude upstream code, generated artifacts, test fixtures with synthetic tokens |

## CI Integration

Pre-commit checks enforced via branch protection on `main`. The `ci.yml` workflow runs:

- `api-tests` — Node.js unit tests (`node --test`)
- `metrics-unit` — Prometheus stack unit tests (bash TAP)
- `security-checks` — gitleaks + trivy against changed files, ShellCheck, keyword review
- `api-dependency-audit` — `npm audit --audit-level=high`

CI gates must pass before merge. Pre-push and API DAST are local-only (require running Console).
