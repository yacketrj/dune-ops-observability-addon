# Dune Ops Observability

Dune Ops Observability is a production-facing, read-only operations addon for Dune Docker Console.

It gives server owners and operators a lightweight visibility surface for player operations, data-source capability, and derived read-only KPI panels without expanding beyond the approved player-read permission boundary.

## Status

- Public addon: listed through the community addon catalog.
- Current release train: `v0.2.1`.
- Runtime model: static addon UI loaded inside Dune Docker Console as an iframe.
- Production data path: Dune Docker Console addon bridge.
- Direct browser preview path: local sample data only.
- Repository workflow: all changes must use the PR route into `main`.
- Required checks: Validate addon, Pre-commit, Secret Scan, SAST, and Filesystem Scan.

## What the addon provides

### A3 Player Summary

The player summary panel shows read-only player rows when the Console bridge provides player summary data.

It is designed to handle:

- populated player data;
- empty player lists;
- missing optional fields;
- bridge or provider errors;
- local browser preview mode.

### A4 KPI Capability

The KPI capability panel states which reporting categories are currently supportable by the available read-only data.

Unsupported categories are shown explicitly instead of implying that data exists.

### A5 Read-only KPI Panels

The first KPI panels are derived only from the existing player summary payload:

- active rate;
- average level;
- top faction;
- top guild.

No additional permission, upstream route, bridge action, database access, export, webhook, or write capability is introduced by these panels.

## Security and permission boundary

The addon currently requests only:

```json
{
  "players": ["read"]
}
```

The addon does not request or use:

- write permissions;
- `database:read`;
- raw logs;
- admin audit logs;
- exports;
- webhooks;
- persistent history;
- economy data;
- inventory data;
- direct localhost browser API calls.

Future features that require a new permission, new bridge action, new upstream route, retained history, export, alerting, economy data, storage data, inventory data, or admin/security-sensitive data must go through design review before implementation.

See `docs/SOC-OPS-ROADMAP.md` and `docs/REPOSITORY-REQUIREMENTS-AND-DELIVERABLES.md`.

## Architecture

Dune Ops Observability has two runtime modes.

### Console iframe mode

When the addon runs inside Dune Docker Console, it uses the Console addon bridge as the production data path.

Current bridge-backed action:

```text
leadership.players.list
```

### Direct browser preview mode

When the addon is opened directly in a browser, the real Console bridge is not available. In that case, the addon uses sample data so layout and UI work can be tested without a running Console instance.

Direct browser preview mode is not the production data path.

## Repository boundary

Addon work belongs in this repository:

- addon UI;
- addon documentation;
- addon validation;
- release packaging;
- release notes;
- security gates;
- addon branches, issues, and pull requests;
- read-only player summary and KPI views;
- addon-specific governance and developer tooling.

Bridge, API, core Console, Docker, Prometheus, and upstream runtime changes belong in the Dune Docker Console repository, not in this addon repository.

## Branch and PR governance

All changes must use the PR route into `main`.

Before cutting a branch, sync from `origin/main` and confirm the working tree is clean. Do not create a PR from a dirty tree, stale `main`, detached HEAD, wrong repository, wrong branch, or unreviewed staged files.

PRs must include:

- summary;
- why;
- documentation impact;
- unit / regression / E2E testing output;
- security output;
- risks and rollback plan;
- tracked PR documentation under `ops-observability/releases/<release-id>/prs/` or `ops-observability/releases/unreleased/prs/`.

`main` should be protected with GitHub rulesets or branch protection so merges are blocked until required checks complete and pass.

Required checks:

```text
Validate addon
Pre-commit
Secret Scan
SAST
Filesystem Scan
```

See `docs/GITHUB-RULESETS.md` and `docs/BRANCH-PROTECTION.md`.

## Documentation currency

Documentation drift is a merge blocker.

Every PR into `main` must review and update affected documentation before it is marked ready for review or merged.

At minimum, each PR must check:

- `README.md`;
- `docs/`;
- release notes and release testing documents;
- `ops-observability/roadmap/`;
- `ops-observability/releases/`;
- `ops-observability/dev-tools/templates/`;
- tracked PR documentation under `ops-observability/releases/<release-id>/prs/`.

If documentation is intentionally deferred, the PR must state which documentation is deferred, why it is deferred, who owns the follow-up, and the follow-up PR or issue reference.

## Installation

### Community catalog installation

Server owners should normally install published releases through the Dune Docker Console community addon catalog after the release has been reviewed and listed.

Upstream catalog submissions are release-train based. This project does not submit an upstream catalog PR for every internal feature merge.

### Private local testing

Private testing does not require the community addon index.

For release validation, test against a local Dune Docker Console checkout at:

```text
/home/darkdante/dune-clean-repro
```

The standard private test install command is:

```bash
bash /home/darkdante/dune-ops-observability-addon/scripts/validate-and-install-local-console.sh
```

The script validates the addon, builds the package, synchronizes the local Console checkout, copies the addon into the local Console runtime, and enables the approved read-only permission.

After the script completes, refresh Dune Docker Console, open Addons, and verify the addon through the Console iframe bridge.

See `docs/LOCAL-CONSOLE-TEST.md` and the current release testing document.

## Local development

The local gate scripts detect required tools before they run. When a tool is missing, they attempt to install it automatically by default.

Auto-install can use available local package managers and language installers such as apt, pipx/pip, Go, Homebrew, or the upstream Trivy installer. If a tool cannot be installed safely in the current environment, the gate fails closed with the missing tool and remediation target.

Disable auto-install when you only want detection:

```bash
DUNE_AUTO_INSTALL_TOOLS=0 bash ops-observability/dev-tools/pr-gate.sh
```

Bootstrap the full local toolchain explicitly:

```bash
bash ops-observability/dev-tools/toolchain-bootstrap.sh
```

Run local validation from the addon repository:

```bash
node scripts/validate.js
bash scripts/package.sh
bash ops-observability/dev-tools/precommit-gate.sh
bash ops-observability/dev-tools/security-shift-left.sh
bash ops-observability/dev-tools/pr-gate.sh
```

The gate scripts intentionally print concise `PASS:` / `FAIL:` lines. When a gate fails, it prints compact failure details. For full scanner diagnostics, run the underlying tool directly.

Individual quiet gates:

```bash
bash ops-observability/dev-tools/precommit-gate.sh
bash ops-observability/dev-tools/gitleaks-gate.sh
bash ops-observability/dev-tools/semgrep-gate.sh
bash ops-observability/dev-tools/trivy-gate.sh
```

GitHub's contents API does not preserve executable mode. Use `bash <script>` unless the local file has been made executable.

For quick UI work, open `web/index.html` directly in a browser. The addon will use sample data in direct browser preview mode.

For bridge validation, install the addon into the local Dune Docker Console checkout and open it through the Console Addons page.

## Release process

Public releases follow a release-train model.

Internal addon work continues through focused pull requests for auditability. Upstream community catalog updates are batched by released addon version or meaningful feature batch.

A public release requires:

- addon manifest validation;
- pre-commit checks;
- secret scan;
- static analysis;
- filesystem scan;
- package build;
- browser preview smoke test;
- private Dune Docker Console test;
- real bridge smoke test through the Console Addons page;
- release notes;
- pinned GitHub release asset;
- SHA-256 checksum verified from the uploaded release asset.

See:

- `docs/LOCAL-CONSOLE-TEST.md`;
- `docs/RELEASE-CADENCE.md`;
- current release notes;
- current release testing checklist.

## Roadmap

The current public roadmap is organized by SOC / OPS impact and release risk.

Near-term direction:

- `v0.2.0`: public player-operations release train with A3, A4, and A5;
- `v0.3.0`: OPS Health Foundation focused on source health, data freshness, stale-data warnings, and operator status summary;
- future major track: server and Console health metrics that may require upstream bridge or core support.

Sensitive areas such as database access, raw logs, admin audit data, economy data, storage data, inventory data, exports, webhooks, and persistent history require explicit design review before implementation.

See `docs/SOC-OPS-ROADMAP.md`.

## Contributing

Contributions, testing notes, issue reports, and operator feedback are welcome.

Good contributions include:

- bug reports with clear reproduction steps;
- screenshots or notes from private Console testing;
- accessibility improvements;
- documentation corrections;
- safer empty-state handling;
- read-only UI improvements;
- proposals for SOC / OPS metrics with permission and security impact clearly stated.

Before opening a pull request:

1. Keep the change focused.
2. Branch from current `main`.
3. Avoid expanding permissions unless a design discussion has already approved it.
4. Run local validation and quiet gates.
5. Review README and affected docs for drift.
6. Document testing performed.
7. Call out any security, permission, bridge, documentation, or upstream impact.

For metric proposals, classify the proposal as minor, major, or patch using `docs/SOC-OPS-ROADMAP.md`.

## Feedback and support

Use GitHub issues and pull requests for feedback, bug reports, roadmap discussion, and contribution review.

When reporting an issue, include:

- addon version;
- Dune Docker Console version or commit when known;
- whether the addon was installed through the catalog or privately copied into Console;
- browser and operating system;
- screenshots or logs when safe to share;
- expected behavior;
- actual behavior.

Do not include secrets, tokens, private server data, player personal data, or sensitive logs in public issues.

## Documentation index

- `docs/BRANCH-PROTECTION.md` — branch protection intent and required checks.
- `docs/GITHUB-RULESETS.md` — actionable GitHub ruleset setup for `main`.
- `docs/REPOSITORY-REQUIREMENTS-AND-DELIVERABLES.md` — repository governance baseline, gates, deliverables, and documentation currency requirement.
- `docs/DATA-PROVIDERS.md` — sample provider and Console bridge provider boundary.
- `docs/LOCAL-CONSOLE-TEST.md` — local Console validation and install procedure.
- `docs/RELEASE-CADENCE.md` — release train and upstream catalog policy.
- `docs/SECURITY-GATES.md` — required validation and security gates.
- `docs/SHIFT-LEFT-SECURITY.md` — local hook and CI security policy.
- `docs/SOC-OPS-ROADMAP.md` — SOC / OPS metric taxonomy and roadmap.
- `docs/COMMUNITY-INDEX-PR.md` — upstream catalog submission guidance.

## License

No license file is currently included. Add a license before accepting broad external code contributions.
