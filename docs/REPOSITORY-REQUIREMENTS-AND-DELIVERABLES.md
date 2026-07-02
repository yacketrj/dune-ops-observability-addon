# Repository Requirements and Deliverables

Status: Draft governance baseline  
Repository: `yacketrj/dune-ops-observability-addon`  
Canonical branch: `main`  
Canonical remote: `origin`  
Scope: Dune Ops Observability addon development, release planning, validation evidence, security gates, and release controls.

## 1. Purpose

This document consolidates the standing requirements for this repository.

It defines:

- repository scope;
- working-tree requirements;
- branch and PR gates;
- PR documentation requirements;
- release deliverables;
- security and privacy guardrails;
- shift-left security requirements;
- SBOM requirements;
- SOC2-style evidence requirements;
- package exclusion requirements;
- reusable template requirements.

This document is additive to the existing project docs. If a conflict is found, stop and reconcile before cutting a branch, PR, or release.

## 2. Existing Documentation Baseline

This repository already establishes the following baseline:

- Addon-specific work lives in this repository.
- Core bridge, Console API, runtime, and upstream PR work lives in the WSL/core repository.
- The addon is production-facing and read-only.
- The production data path is the Dune Docker Console addon bridge.
- Direct browser preview mode uses sample data only.
- The addon does not use raw localhost browser API calls as the default production path.
- Release work must pass validation gates before public release.
- Shift-left security is required through local hooks and CI gates.
- Public releases must include package validation and checksum verification.

Relevant existing docs:

```text
docs/BRANCHING.md
docs/WORKSTREAM-SPLIT.md
docs/RFC-ADDENDUM-ADDON-FIRST-OBSERVABILITY.md
docs/DATA-PROVIDERS.md
docs/SECURITY-GATES.md
docs/SHIFT-LEFT-SECURITY.md
docs/RELEASE-CADENCE.md
docs/PACKAGING.md
docs/COMMUNITY-INDEX-PR.md
```

## 3. Active Repository Scope

The active repository is:

```text
yacketrj/dune-ops-observability-addon
```

The expected local checkout is:

```text
~/dune-work/addon-main
```

The canonical branch is:

```text
main
```

The canonical remote is:

```text
origin
```

The `template` remote may exist as a Red-Blink addon-template reference. It is not the branch base for active development unless explicitly declared for a template-sync task.

## 4. Repository Boundary

This addon repository owns:

- addon UI;
- addon documentation;
- addon validation;
- release packaging;
- release notes;
- security gates;
- addon issues, branches, and pull requests;
- read-only player summary and KPI views;
- observability release planning;
- release evidence and governance documents;
- addon-specific dev tooling.

The WSL/core repository owns:

- bridge action changes;
- bridge permission changes;
- Console API route changes;
- Docker/runtime changes;
- Prometheus or exporter work;
- upstream pull requests into Red-Blink core repositories.

Supporting local worktrees may be referenced by dev scripts, but they are not the active repository for addon governance work by default.

Supporting local paths include:

```text
~/dune-work/core-main
~/dune-work/core-pr-ops-health-expanded-aggregates
~/dune-work/core-pr-addon-ops-health-bridge
~/dune-work/e2e-ops-health
```

## 5. Required Repository Layout

The required observability control layout is:

```text
ops-observability/
├── dev-tools/
├── evidence/
│   └── releases/
├── releases/
├── roadmap/
└── tools/
```

### 5.1 `ops-observability/dev-tools/`

Tracked development scripts, validation gates, patchers, and reusable templates.

Examples:

```text
ops-observability/dev-tools/preflight-main-sync.sh
ops-observability/dev-tools/validate-addon-state.sh
ops-observability/dev-tools/validate-core-ops-health-worktree.sh
ops-observability/dev-tools/run-ops-health-03-validation.sh
ops-observability/dev-tools/templates/pr-body-template.md
```

Dev tools are tracked in Git but must be excluded from runtime release packages unless explicitly required.

### 5.2 `ops-observability/evidence/`

Curated release evidence.

Allowed evidence:

- test output summaries;
- privacy scan output;
- Gitleaks output;
- Semgrep output;
- Trivy output;
- SBOM output;
- release decisions;
- sanitized hash snapshots;
- SOC2-style control evidence;
- documented risk acceptances.

Disallowed evidence:

- raw database dumps;
- raw row payloads;
- player/account identifiers;
- coordinates;
- map or location payloads;
- inventory payloads;
- economy payloads;
- guild payloads;
- Landsraad payloads;
- resource-field payloads;
- event logs;
- secrets;
- tokens;
- passwords.

### 5.3 `ops-observability/releases/`

Release plans, checklists, PR documentation, and release-specific templates.

Expected layout:

```text
ops-observability/releases/<release-id>/
├── release-plan.md
├── checklist.md
├── prs/
└── PR-BODY.md
```

### 5.4 `ops-observability/roadmap/`

Internal standards, classification rules, release policy, and governance documents that are specific to observability planning.

### 5.5 `ops-observability/tools/`

Stable reusable tooling that supports release evidence or telemetry discovery.

One-off patchers belong in `dev-tools/`, not `tools/`, unless they become stable release tooling.

## 6. Branch and PR Base Requirements

Before creating any branch or cutting any PR, `main` must be clean and in lockstep with `origin/main`.

Required preflight:

```bash
cd ~/dune-work/addon-main

git fetch origin --prune
git switch main
git pull --ff-only origin main

git status --short --branch

test "$(git rev-parse main)" = "$(git rev-parse origin/main)" \
  && echo "PASS: main is in lockstep with origin/main" \
  || echo "FAIL: main differs from origin/main"

test -z "$(git status --porcelain)" \
  && echo "PASS: working tree is clean" \
  || echo "FAIL: working tree has changes"
```

Required result:

```text
PASS: main is in lockstep with origin/main
PASS: working tree is clean
```

No branch or PR may be created from:

- stale `main`;
- dirty working tree;
- detached HEAD;
- wrong repository;
- wrong branch;
- unreviewed staged files;
- unpulled `origin/main`;
- unknown local-only state.

## 7. PR Documentation Requirements

Every PR must include a populated PR body with these sections:

```text
Summary
Why
Unit / Regression / E2E Testing Output
Security Output
Risks
```

Each PR must also have tracked PR documentation under the relevant release folder.

Recommended path:

```text
ops-observability/releases/<release-id>/prs/
```

Recommended files:

```text
PR-<number-or-slug>.md
PR-<number-or-slug>-validation-output.md
PR-<number-or-slug>-security-output.md
PR-<number-or-slug>-risk-review.md
```

If a PR is not tied to a numbered release, use:

```text
ops-observability/releases/unreleased/prs/
```

## 8. Required PR Body Template

Every PR body must follow this structure:

```markdown
## Summary

- What changed:
- Files/areas touched:
- Release or roadmap item:

## Why

- Problem being solved:
- Why this belongs in this repository:
- Why this approach was chosen:

## Unit / Regression / E2E Testing Output

### Unit

```text
<paste unit test command and output>
```

### Regression

```text
<paste regression command and output>
```

### E2E

```text
<paste E2E command and output>
```

## Security Output

```text
<paste Gitleaks, Semgrep, Trivy, SBOM, and privacy/security scan output>
```

Security checklist:

- [ ] No secrets or tokens committed.
- [ ] No raw database dumps committed.
- [ ] No player/account identifiers committed.
- [ ] No coordinates or map/location payloads committed.
- [ ] No inventory/economy/guild/Landsraad/resource/event-log payloads committed.
- [ ] No raw SQL bridge or unsafe DB access introduced.
- [ ] SBOM impact is stated.
- [ ] SOC2-style control impact is stated.

## Risks

- Known limitations:
- Compatibility impact:
- Rollback plan:
- Follow-up work:
```

## 9. Security Guardrails

The repository is public. Treat every committed file as public.

Never commit:

- passwords;
- tokens;
- secrets;
- raw database dumps;
- raw SQL result dumps with sensitive rows;
- Steam IDs;
- Funcom IDs;
- account IDs;
- player IDs;
- character IDs;
- coordinates;
- map/location payloads;
- inventory payloads;
- economy payloads;
- wallet or Solari payload values;
- guild data;
- Landsraad data;
- marker/map payloads;
- resource fields;
- event logs;
- raw rows;
- unsafe raw SQL bridge access.

Allowed observability evidence is aggregate-only and sanitized.

## 10. Shift-Left Security Requirements

Shift-left security gates must run before review whenever possible.

Required tools:

```text
Gitleaks
Semgrep
Trivy
```

Required local checks:

- `gitleaks detect` for secret scanning;
- `semgrep scan` for static analysis;
- `trivy fs` for filesystem/dependency vulnerability scanning;
- `git diff --check` for whitespace and conflict-marker validation;
- repository-specific privacy scan for prohibited observability data;
- SBOM impact check.

No PR should proceed with unresolved critical or high findings unless risk acceptance is documented.

## 11. PR Gates

A PR is not ready unless all of the following are true:

- `main` was clean and in lockstep with `origin/main` before branching;
- branch is based on current `main`;
- working tree is clean after commit;
- changed files are reviewed;
- PR body includes all required sections;
- tracked PR documentation exists;
- unit output is included;
- regression output is included;
- E2E output is included or explicitly justified as not applicable;
- security output is included;
- Gitleaks output is included;
- Semgrep output is included;
- Trivy output is included or explicitly justified as not applicable;
- SBOM impact is stated;
- SOC2-style control impact is stated;
- security/privacy scan confirms no prohibited data committed;
- risks and rollback plan are documented.

## 12. Release Gates

A release is not ready unless it includes:

- release plan;
- release checklist;
- PR documentation;
- unit evidence;
- regression evidence;
- E2E evidence;
- Gitleaks evidence;
- Semgrep evidence;
- Trivy evidence;
- SBOM output or no-change statement;
- SOC2-style control evidence;
- risk review;
- rollback plan;
- release decision;
- known limitations;
- package build output;
- release asset checksum.

Recommended release evidence layout:

```text
ops-observability/evidence/releases/<release-id>/
├── testing/
│   ├── unit-output.txt
│   ├── regression-output.txt
│   └── e2e-output.txt
├── security/
│   ├── gitleaks-output.txt
│   ├── semgrep-output.txt
│   ├── trivy-output.txt
│   └── privacy-scan-output.txt
├── sbom/
│   ├── sbom.cyclonedx.json
│   ├── sbom.spdx.json
│   └── sbom-generation-output.txt
└── controls/
    ├── change-management.md
    ├── access-control.md
    ├── data-handling-review.md
    ├── risk-review.md
    ├── rollback-plan.md
    └── audit-trail.md
```

## 13. SBOM Requirements

Every release package must include or generate an SBOM unless explicitly marked not applicable with justification.

Preferred formats:

```text
CycloneDX JSON
SPDX JSON
```

Recommended path:

```text
ops-observability/evidence/releases/<release-id>/sbom/
```

Required PR statement:

```text
SBOM impact: No dependency or package-content changes.
```

or:

```text
SBOM impact: Dependency or package contents changed. SBOM regenerated and validation output included.
```

SBOM output must not include credentials, private registry tokens, local secrets, or sensitive runtime data.

## 14. SOC2-Style Evidence Requirements

Use SOC2-style evidence language only. Do not claim SOC2 certification or SOC2 compliance unless formally audited.

Correct language:

```text
SOC2-style evidence
control-oriented evidence
audit-ready release documentation
```

Required control categories:

- change management;
- access control;
- testing evidence;
- security review;
- risk review;
- data handling / privacy review;
- rollback plan;
- audit trail.

Recommended path:

```text
ops-observability/evidence/releases/<release-id>/controls/
```

## 15. Addon Runtime and Data-Provider Requirements

Production runtime:

```text
Dune Docker Console iframe addon bridge
```

Direct browser preview:

```text
sample data only
```

The addon must not use direct browser calls to raw host-local API ports as its default production data path.

Bridge-mediated access remains the default supported provider.

Any future same-origin local API provider must be optional, reviewed, read-only by default, and explicitly documented.

## 16. Permission and Capability Requirements

Current addon permission boundary:

```json
{
  "players": ["read"]
}
```

The addon must not request write permissions for observability MVP work.

Future work that requires any of the following needs design review before implementation:

- new permission;
- new bridge action;
- new upstream route;
- retained history;
- export;
- alerting;
- economy data;
- storage data;
- inventory data;
- admin/security-sensitive data.

## 17. OPS Bridge Requirements

Existing baseline bridge-backed addon action:

```text
leadership.players.list
```

Future Core bridge work may define additional actions, but bridge action changes belong in the WSL/core repository, not this addon repository.

When Release 0.3 planning references Core-side bridge actions, the known target actions are:

```text
ops.health.players
ops.health.farms
ops.health.summary.v2
```

Compatibility requirement:

```text
ops.health.summary remains unchanged unless explicitly modified by a future compatibility release.
```

Blocked for Release 0.3 planning unless separately approved:

- `database.query`;
- `database:read` expansion;
- `database:write` expansion;
- raw SQL bridge;
- raw rows;
- IDs;
- coordinates;
- inventory;
- economy;
- guild;
- Landsraad;
- markers;
- maps;
- locations;
- resource fields;
- event logs;
- exports;
- webhooks;
- retained history.

## 18. Package and Release Asset Requirements

Local package validation must run before release.

Required commands should include:

```bash
node scripts/validate.js
bash scripts/package.sh
```

Release assets must include:

- versioned addon package zip;
- SHA-256 checksum;
- release notes;
- pinned release asset URL.

The community addon index must point to a pinned GitHub Release asset URL, not GitHub's automatic source archive.

The package checksum must match the exact uploaded release asset.

## 19. Package Exclusion Requirements

The following paths are tracked for governance and development but should be excluded from runtime release packages unless explicitly needed:

```text
ops-observability/dev-tools/
ops-observability/evidence/
ops-observability/releases/
ops-observability/roadmap/
docs/
```

Example zip exclusion:

```bash
zip -r dune-ops-observability-addon.zip . \
  -x "ops-observability/dev-tools/*" \
  -x "ops-observability/evidence/*" \
  -x "ops-observability/releases/*" \
  -x "ops-observability/roadmap/*" \
  -x "docs/*" \
  -x ".git/*"
```

The actual exclusion mechanism must match `scripts/package.sh`.

## 20. Community Index PR Requirements

Open an upstream catalog PR only after:

- the tag exists;
- the release asset exists;
- the uploaded asset checksum is verified;
- private Console test has passed;
- the manifest URL is final;
- the download URL is final;
- the version is final;
- the checksum is final;
- addon repository checks are green.

The community index PR must include:

- summary;
- why;
- release package information;
- test output;
- security output;
- permissions requested;
- review notes.

## 21. Release 0.2 Deliverables

Release name:

```text
Internal Telemetry Discovery
```

Required deliverables:

- release plan;
- SQL classification;
- SQL review checklist;
- source artifacts document;
- checklist;
- safe SQL candidate file;
- rejected/rewrite-required SQL file;
- sensitive-review SQL file;
- tool run output;
- privacy scan output;
- safe query output;
- release decision.

Approved safe aggregate candidates:

- player status summary grouped by online status, life state, and character state;
- farm aggregate summary including total, ready, alive, connected players, incoming S2S, and outgoing S2S.

Held or rejected categories:

- economy;
- inventory;
- markers;
- maps;
- locations;
- event logs;
- JSON keys;
- guild;
- Landsraad;
- resource fields.

## 22. Release 0.3 Deliverables

Release name:

```text
Expanded Aggregate DB Bridge Actions
```

Required deliverables:

- release plan;
- checklist;
- PR body;
- PR documentation;
- patch plan;
- validation checklist;
- privacy guard;
- security output;
- unit/regression/E2E evidence;
- SBOM impact evidence;
- SOC2-style control evidence;
- risk review;
- rollback plan;
- release decision.

Required planned bridge actions:

```text
ops.health.players
ops.health.farms
ops.health.summary.v2
```

Compatibility requirement:

```text
ops.health.summary remains unchanged unless explicitly modified by a future compatibility release.
```

## 23. Required Templates

Reusable templates should live under:

```text
ops-observability/dev-tools/templates/
```

Required templates:

```text
pr-body-template.md
pr-validation-template.md
pr-security-output-template.md
pr-risk-review-template.md
sbom-impact-template.md
soc2-style-controls-template.md
shift-left-security-gate-template.md
release-gate-template.md
risk-acceptance-template.md
release-decision-template.md
```

Release-specific templates may live under:

```text
ops-observability/releases/<release-id>/
```

## 24. Required Dev Tools

Recommended tracked scripts:

```text
ops-observability/dev-tools/preflight-main-sync.sh
ops-observability/dev-tools/validate-addon-state.sh
ops-observability/dev-tools/validate-core-ops-health-worktree.sh
ops-observability/dev-tools/security-shift-left.sh
ops-observability/dev-tools/pr-gate.sh
ops-observability/dev-tools/release-gate.sh
ops-observability/dev-tools/run-ops-health-03-validation.sh
```

Dev tools should:

- fail closed;
- print exact command output;
- avoid modifying files unless explicitly named as patchers;
- refuse wrong repositories;
- refuse dirty worktrees unless explicitly designed to inspect them;
- write evidence to release-specific evidence directories;
- avoid committing secrets or raw sensitive data.

## 25. Risk Acceptance Requirements

Risk acceptance is required when:

- a high or critical tool finding cannot be remediated before PR;
- E2E testing is not performed;
- SBOM generation is skipped;
- Trivy, Semgrep, or Gitleaks cannot run;
- prohibited telemetry categories are touched;
- release evidence is incomplete;
- a compatibility risk is known.

Risk acceptance must include:

- risk description;
- impacted component;
- severity;
- reason for acceptance;
- compensating controls;
- expiry or revisit condition;
- approving reviewer.

## 26. Definition of Done

A repository change is done when:

- branch was created from synced `main`;
- changes are scoped to expected paths;
- unit, regression, and E2E evidence is captured or justified;
- security scans are captured;
- SBOM impact is documented;
- SOC2-style controls are documented;
- risks and rollback plan are documented;
- PR body is complete;
- tracked PR documentation exists;
- no prohibited data is committed;
- release evidence is updated where applicable.

A release is done when:

- all PRs are merged or explicitly deferred;
- release checklist is complete;
- release decision is written;
- evidence is complete and sanitized;
- known limitations are documented;
- rollback plan is documented;
- release package excludes governance/dev-only content unless explicitly required.
