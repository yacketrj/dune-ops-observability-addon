# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- Pin all GitHub Actions to immutable SHAs with version comments
- Add dependabot cooldown (7 days) for both github-actions and npm ecosystems
- Add npm audit to main CI workflow
- Add dependency-review action for PRs (moderate severity blocking)
- Add weekly scheduled security scans (Monday 09:17 UTC)
- Add SBOM (CycloneDX) generation to release workflow
- Remove SKIP from pre-commit CI workflow (trivy, semgrep, ggshield now run)
- Fix filesystem-scan.yml: add scanners (vuln,misconfig,secret) and severity (CRITICAL,HIGH)
- Add gitleaks regex allowlist for known false positives
- Add SECURITY.md with vulnerability reporting process
- Add CODEOWNERS requiring owner review
- Add issue templates (bug report, feature request)

### Fixed
- Bridge provider returns `{status: "unavailable"}` instead of sample data for unimplemented actions
- Harden postMessage bridge: add event.source === window.parent check
- Expand validate.js to check entry.path, permissions, file existence, version consistency, JS parsing

### Added
- 14 addon tests covering manifest validation, asset existence, security checks, bridge behavior
- security-gates.yml workflow with dependency-audit, dependency-review, semgrep-sast, secret-scan, trivy-filesystem

## [0.4.1] - 2026-07-15

### Fixed
- Correct version to 0.4.1 to match release cadence

### Added
- Deployment scripts for clean testing environments
- gitleaks configuration to ignore scraper cache false positives
- Remove cached HTML files and update .gitignore

## [0.4.0] - 2026-07-10

### Added
- NOC Dashboard with service health map
- Server resources monitoring
- Deployment health metrics
- Player activity tracking
- KPI capability panel

## [0.3.0] - 2026-07-03

### Added
- Expanded database bridge
- OPS health foundation (ops.health.summary.v2, ops.health.players, ops.health.farms)
- Player activity summary (ops.activity.summary)

## [0.2.1] - 2026-06-28

### Fixed
- Bridge health panel rendering
- Provider abstraction layer

## [0.2.0] - 2026-06-25

### Added
- Telemetry discovery findings
- Privacy-safe query candidates
- Release evidence framework

## [0.1.1] - 2026-06-20

### Added
- Initial release packaging
- SHA-256 checksum verification
- Release notes and testing documentation

## [0.1.0] - 2026-06-15

### Added
- Initial addon foundation
- Basic NOC dashboard structure
- postMessage bridge implementation
- Sample data providers
