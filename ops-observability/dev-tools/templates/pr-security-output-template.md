# PR Security Output Template

Capture security evidence for a pull request.

## PR Metadata

- PR number:
- Branch:
- Base:
- Commit:

## Required Security Gates

### Pre-commit

```text
command: pre-commit run --all-files --show-diff-on-failure
output:
```

### Gitleaks

```text
command: gitleaks detect --source . --no-git
output:
```

### Semgrep

```text
command: semgrep scan
output:
```

### Trivy

```text
command: trivy fs .
output:
```

### Repository Privacy Scan

```text
command:
output:
```

## SBOM Impact

- [ ] No dependency or package-content changes.
- [ ] Dependency or package contents changed; SBOM regenerated.
- [ ] Not applicable with justification.

## Result

- [ ] Passed
- [ ] Failed
- [ ] Risk accepted with linked risk review

Risk reference:
