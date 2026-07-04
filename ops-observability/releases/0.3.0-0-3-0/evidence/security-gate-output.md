# Shift-Left Security Gate Output — v0.3.0

## Scope
- Branch: release/v0.3.0
- Base: main
- Date: 2026-07-04

## Required Commands

### Diff Check
```
command: git diff --check main
output: No whitespace errors or conflict markers
```

### Addon Validation
```
command: node scripts/validate.js
output: Addon manifest is valid
```

### Static Analysis
```
command: semgrep scan --config=auto --quiet .
output: No findings
```

### Secret Scan
```
command: gitleaks detect --no-git
output: No leaks found
```

### Filesystem Scan
```
command: trivy fs --scanners vuln,secret .
output: No vulnerabilities or secrets
```

## Result
- [x] Passed
- [ ] Failed
- [ ] Risk accepted with linked review
