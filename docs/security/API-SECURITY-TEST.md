# API Security Test (DAST)

Dynamic Application Security Testing for the Dune Docker Console API. Tests security enforcement against a running Console instance.

## Usage

```bash
CONSOLE_PORT=8088 bash tests/api-security-test.sh
```

Environment variables:
- `CONSOLE_PORT` — Console bind port (default: `8088`)
- `BASE_URL` — Override full base URL (default: `http://127.0.0.1:$CONSOLE_PORT`)
- `ADMIN_PASSWORD` — Admin password for auth tests (default: read from `runtime/secrets/admin-web-password.txt`)

## Test categories

| # | Category | What it validates | Severity |
|---|---|---|---|
| 1 | Health | Console is reachable | Critical |
| 2 | Security Headers | X-Content-Type-Options, X-Frame-Options, Referrer-Policy | High |
| 3 | Authentication | 401/403 for unauthenticated access; login works | Critical |
| 4 | CSRF | POST rejected without CSRF token; GET allowed | Critical |
| 5 | Input Validation | Path traversal, SQL injection, XSS probes rejected | Critical |
| 6 | Size Limits | Oversized payloads rejected (20KB JSON) | Medium |
| 7 | Addon Bridge | Invalid IDs, unsupported actions, traversal protection | High |
| 8 | Rate Limiting | Login rate limit triggers after repeated failures | High |
| 9 | Info Leakage | No stack traces, no Server header, no internal paths | High |

## Pass/Skip/Fail semantics

- **PASS**: Check succeeded as expected
- **FAIL**: Security violation found — blocks the push/release
- **SKIP**: Check could not run (auth disabled, missing password, Console offline) — does not block

A SKIP on auth-dependent checks (CSRF, authenticated endpoints) is expected when auth is disabled or the password doesn't match. A PASS is expected on all non-auth-dependent checks (headers, input validation, bridge security, info leakage).

## Expected findings

Current known behaviors (not vulnerabilities):
1. **Login rate limiter may not trigger** when CSRF enforcement blocks the request before the rate limit counter increments. This is defense-in-depth — the CSRF gate prevents blind brute-force attacks. The rate limiter activates when CSRF tokens are present.
2. **Auth-dependent checks SKIP** when the running Console has auth disabled or the password file doesn't match. Use `ADMIN_AUTH_DISABLED=true` in `.env` for testing in dev environments.

## Location

The test script lives in the core repository:
- `dune-awakening-selfhost-docker/tests/api-security-test.sh`

It is referenced by the pre-push hook (`~/.local/bin/pre-push-gates`) and the pre-release scan (`scripts/pre-release-security.sh`).
