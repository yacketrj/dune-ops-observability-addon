# Security Config Templates

Reference for all security scanning configuration files used across the project. Each repo maintains its own copies with repo-specific allowlists.

## Files per repository

| File | Purpose | Core | Addon | Catalog |
|---|---|---|---|---|
| `.pre-commit-config.yaml` | Pre-commit hook definitions | Yes | Yes | Yes |
| `.gitleaks.toml` | Gitleaks allowlist | Yes (built-in token) | Yes | Yes |
| `.trivyignore` | Trivy scan exclusions | Yes (TLS certs) | Yes | Yes |
| `.semgrepignore` | Semgrep scan exclusions | Yes (upstream code) | Yes | Yes |
| `tests/api-security-test.sh` | API DAST script | Yes | No | No |
| `scripts/pre-release-security.sh` | Pre-release scan | Yes | Yes | No |

## .pre-commit-config.yaml

Defines hooks that run on `git commit`:
- Standard hooks: check-json, check-yaml, check-merge-conflict, mixed-line-ending, end-of-file-fixer, trailing-whitespace
- gitleaks: secret scanning
- trivy: filesystem secret scanning (HIGH/CRITICAL)
- semgrep: static analysis (p/default ruleset)
- Repo-specific hooks: validate-addon-manifest (addon), validate-catalog-shas (catalog), security-checks (core)

**Installation**: `pre-commit install`

## .gitleaks.toml

TOML configuration for Gitleaks secret detection. The `[allowlist]` section accepts known tokens that must not trigger a finding.

Core repo example (command-auth fallback):
```toml
[allowlist]
  description = "Known command-auth fallback shared by game server"
  regexes = ["Nu6VmPWUMvdPMeB7qErr"]
```

Addon/catalog repos: the allowlist is empty — all secret findings must be reviewed.

## .trivyignore

Plain text file, one path or glob pattern per line. Trivy skips these paths during filesystem scanning.

Core repo example:
```
runtime/rabbitmq-game/certs/
```

## .semgrepignore

Plain text file with glob patterns. Semgrep skips matching files.

Core repo example:
```
# Pre-existing upstream code
orchestrator/
console/web/

# Generated artifacts
.security-reports/

# Test fixtures with synthetic tokens
console/api/test/runner.test.js
```

Addon repo example:
```
# Generated artifacts
dist/
node_modules/

# Documentation examples
docs/diagrams/
```

## Shared hooks

The pre-push hook (`~/.local/bin/pre-push-gates`) is symlinked into each repo's `.git/hooks/pre-push`. It runs the same four checks (gitleaks, trivy, semgrep, API DAST) regardless of which repo is being pushed.

See [PRE-PUSH-GATES.md](PRE-PUSH-GATES.md) for the hook specification.

## Adding new allowlist entries

When a tool flags a known non-secret:
1. Verify the finding is truly safe (not a real secret)
2. Add the pattern/path to the repo's allowlist file
3. Commit the allowlist update
4. Document the reason in the commit message

Never add secrets to allowlists as a shortcut — every allowlist entry must be justified.
