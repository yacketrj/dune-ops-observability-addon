# Dune Ops Observability Addon — Security & Architecture Gap Analysis

**Author perspective**: Principal Security Engineer / Architect / DevSecOps
**Scope**: `yacketrj/dune-ops-observability-addon` (`main`, verified at commit `75dab38` + uncommitted working-tree changes)
**Date**: 2026-07-22
**Companion repo referenced**: `Red-Blink/dune-awakening-selfhost-docker` (Core, verified at `v1.3.61`, branch `main`)

---

## 1. Executive Summary

This addon is architecturally sound at its foundation — the postMessage bridge is origin-checked, permissions are read-only by manifest and by convention, DOM writes are almost entirely `textContent`-based, and the CI pipeline runs a genuinely comprehensive set of static security tools (gitleaks, semgrep, trivy, ShellCheck, dependency-review, SBOM). The team has clearly invested heavily in *process* — five-gate release procedures, PR templates, SOC2-style evidence folders, a security-first checklist, architecture design docs per release.

However, this review finds that **the process artifacts have outpaced the engineering they were meant to govern**, and in several places the actual runtime behavior contradicts both the documentation and the addon's own stated security boundary. The most severe findings are not exotic vulnerabilities — they are:

1. A confirmed **false-zero rendering bug** that will show `0`/empty tables for any bridge action that is unsupported, denied, or erroring, indiscernible from genuine zero-value data. This directly undermines the addon's purpose (operator trust in observability data).
2. A **security boundary contradiction**: the README explicitly states the addon does not use economy or inventory data; the shipped code does, live, today.
3. **No required-status-checks gate on `main`** — a solo-maintainer-achievable control that is currently not configured, despite the README and `docs/GITHUB-RULESETS.md` describing it. (Note: those same docs also describe a required *second-person review*, which is not an achievable control for a one-person team and is treated separately below — see S-2.)
4. A **fabricated release history**: GitHub Releases up to `v1.0.0` exist and are publicly visible, but are not descendants of `main` and do not reflect the actual (far less complete) state of the codebase, which is realistically at `~v0.4.1/v0.5.0-in-progress`.
5. **Dead/non-functional test and validation tooling** that gives false confidence: an empty `npm audit` that always passes, a copy-pasted OWASP test suite that 100% fails when actually executed (and isn't wired into CI at all), and a manifest validator that breaks on the addon's own recently-added cache-busting query strings.
6. A previously-identified (this session, prior conversation) **fabricated PvP/PvE instance/sietch data** pattern in uncommitted `addon.js` changes — synthesizing "1 PvE Sietch" from a single spice-size row with no real source for sietch counts or combat-type classification. This is the same root-cause pattern as finding #1: presenting inferred/fabricated values as measured fact.

None of this requires a rewrite, and none of it requires hiring. The fixes are: (a) build a shared "source truth" data model so the UI can never render `unavailable` as `0`, (b) turn on the subset of branch protection that doesn't require a second person (required status checks, no force-push), (c) delete or properly wire the dead tooling, (d) reconcile documentation with actual bridge-action inventory — including removing documentation that describes a review process this team's size cannot support, (e) stop tagging/releasing versions that don't reflect `main`.

**A note on scope for a one-person team**: this review's original draft flagged "no enforced code review" as a Critical governance gap. That framing was miscalibrated for a solo maintainer, and has been corrected (see S-2). A repository with exactly one contributor cannot meaningfully require a second approving review — there is no second person. The corrected version of this document separates that unachievable expectation from the genuinely solo-achievable half of the same control (required CI checks blocking merge, no direct/force pushes to `main`), and recommends the project's own governance docs be updated to stop promising a review process the team's size cannot deliver.

---

## 2. Scope & Methodology

- Read every file under `web/` (the entire client-side attack surface: `addon.js`, `data-providers.js`, `dune-addon-bridge.js`, `faction-tagger.js`, `index.html`).
- Read `addon.json`, `README.md`, `SECURITY.md`, `CHANGELOG.md`, and all `docs/architecture/*.md` design documents.
- Read the CI/CD configuration: `.github/workflows/*.yml`, `.pre-commit-config.yaml`, `.gitleaks.toml`, `.trivyignore`, `.semgrepignore`, `.github/dependabot.yml`, `.github/CODEOWNERS`.
- Executed `scripts/validate.js`, `node --test test/addon.test.js`, `node --test pipeline/tests/*.test.js`, `npm audit`, live against the working tree.
- Queried the GitHub API for branch protection, rulesets, release history, and recent PR review state.
- Cross-referenced every bridge action name (`ops.*`) the addon calls against the Core repository's actual route table (`console/api/src/server.js`) to determine live vs. stub vs. non-existent.
- Diffed release tags (`v0.4.0` → `v1.0.0`) against `main` to determine whether tagged releases are real, incremental snapshots of the codebase.

All findings below were reproduced directly (command output captured), not inferred from documentation claims.

---

## 3. Findings

Findings are grouped by domain and tagged with severity (**Critical / High / Medium / Low**) using an impact × exploitability heuristic appropriate for a read-only, iframe-sandboxed UI addon (i.e., "Critical" here generally means "operators will be actively misled by false data" or "a real, currently-exploitable process/access-control gap," not "remote code execution," since the addon's blast radius is inherently limited by its `ops:read`-only, no-network, no-database design).

### 3.1 Functional Correctness — Data Truthfulness

#### F-1 (Critical) — Unsupported/errored bridge actions render as zero, not as "unavailable"

**Evidence**: `web/data-providers.js` (bridge provider) explicitly returns a structured envelope for failed/unimplemented actions:

```js
async getInventory() {
  const data = await bridgeRequest("ops.inventory.summary");
  if (!data || data.error || data.status === "planned")
    return { status: "unavailable", reason: ..., source: "ops.inventory.summary" };
  return data;
}
```

But `web/addon.js`'s render functions never check for this envelope:

```js
function renderInventory(data) {
  const d = data || {};
  setText(invItemsEl, d.totalItems ?? 0);   // {status:"unavailable"}.totalItems is undefined -> renders "0"
  ...
}
```

The same pattern repeats in `renderActivity`, `renderCombat`, `renderResources`, `renderEconomy`, `renderLocation`, `renderSoc`, `renderPrometheus`. Additionally, `refreshAll()`'s `Promise.allSettled` maps *any* rejected promise to `{}` before rendering (`r.status === "fulfilled" ? r.value : {}`), which collapses network/bridge errors into the same "empty object → zero" path.

**Confirmed live in Core**: `ops.inventory.summary`, `ops.location.activity`, `ops.soc.summary`, `ops.health.prometheus` are **not implemented** in `console/api/src/server.js` on Core `main` — every call 400s today. This means, right now, in a live deployment, the Inventory, Location, SOC, and Prometheus/Metrics tabs of this addon will render as fully populated, legitimate-looking zero-value tables and metric cards, with no visual distinction from "the server genuinely has zero inventory items."

**Impact**: This is the single most damaging defect in the addon from an *operator trust* perspective — the entire premise of an observability tool is that displayed data is either accurate or explicitly marked as unavailable. Silent false-zero is worse than no data at all, because it actively misleads.

**Also note**: `getOpsHealth()` in the bridge provider has *no* error-envelope handling at all (unlike its siblings) — if any of the three parallel `ops.health.*` calls reject, `Promise.all` rejects the whole function, which is at least caught by the outer `try/catch` in `refreshOpsHealth()`/`refreshAll()` — but this is inconsistent with the pattern used elsewhere and should be unified.

#### F-2 (High) — Fabricated PvP/PvE instance/sietch data from single-row aggregates

**Evidence** (uncommitted working-tree changes to `web/addon.js`, carried over from earlier work this session): logic that synthesizes entire `deepDesert.instances[]` and `haggaBasin.sietches[]` objects — including hardcoded `pvpInstances: 1, pveInstances: 0` and `type: "pvp"/"pve"` labels — from a single row of `spiceFieldsBySize` per map. There is no real sietch/instance count or PvP/PvE classification anywhere in the underlying `ops.resources.summary` payload; the UI presents an inferred value as a measured fact (e.g., "1 PvE Sietch") to the operator.

This is the same class of defect as F-1: rendering non-measured data as if it were live truth, just via fabrication rather than silent-zero.

**Correction path** (already identified and partially scoped in this session, prior conversation turn): Core does have a real, per-partition-configurable PvP/PvE combat-state source (`UserGame.ini` `PvpPveSettings` section, merged via `usersettings.py`), which a fix on the Core side (`dune-awakening-selfhost-docker` PR #103/#104, currently in review) now resolves correctly. The addon-side fabrication must be replaced with either (a) waiting for a real `ops.*.combatState`-shaped bridge action, or (b) explicitly labeling instance/sietch counts as "Not available" until such an action exists — never inferring PvP/PvE from partial spice-size data.

#### F-3 (Medium) — `sampleResources`/`sampleActivity` preview data is visually indistinguishable in shape/precision from live data

**Evidence**: `data-providers.js`'s `sample` provider returns richly detailed fixtures (`averageLevel: 44`, specific guild names, `kdRatio: 0.26`) with the exact same field names and precision as what live bridge data would return. Nothing in the rendered UI (checked `renderActivity`, `renderCombat`, etc.) tags preview-derived values with a distinct visual treatment beyond the top-level status banner text ("Preview mode..."). An operator who scrolls past the status line, or who has the addon iframe reloaded mid-session, cannot tell from any individual metric card whether they're looking at real or fixture data.

**Impact**: Lower than F-1/F-2 because preview mode is explicitly non-production (only reachable when opened outside the Console iframe), but it's a real risk during demos, screenshots used in documentation/marketing, or troubleshooting sessions where someone forgets which mode they're in.

#### F-4 (Medium) — `refreshAll()` unconditionally claims "All observability sources online"

**Evidence**:
```js
const statusMsg = provider.name === "bridge"
  ? "Connected to Dune Docker Console. All observability sources online."
  : "Preview mode. Sample data shown for all panels.";
```
This message is shown whenever the provider is `bridge`, regardless of how many of the 9 parallel `Promise.allSettled` calls actually succeeded. Combined with F-1, an operator could see 4 of 9 tabs silently showing false zeros while the banner claims full connectivity.

### 3.2 Security Boundary & Documentation Integrity

#### S-1 (High) — README security-boundary claims contradict shipped code

**Evidence**: `README.md`, "Security and permission boundary" section, states verbatim:

> "The addon does not request or use: ... economy data; inventory data."

But `web/data-providers.js` (bridge provider, live, currently shipped/uncommitted-but-tracked-as-in-progress) contains `getEconomy()` calling `ops.economy.summary` and `getInventory()` calling `ops.inventory.summary`, both of which are exercised on every `refreshAll()` cycle. `ops.economy.summary` is confirmed **live** in Core.

This is not a stale-doc nitpick — it is the project's own security/permission model documentation making a factually false claim about what data the addon accesses. Any security reviewer, addon-catalog maintainer, or server operator relying on this README to reason about the addon's trust boundary would reach an incorrect conclusion.

**Also incomplete**: the bridge-action inventory listed in README ("Current bridge-backed actions") lists only 4 actions (`leadership.players.list`, `ops.health.summary`, `ops.health.players`, `ops.health.farms`); the shipped code calls **9 distinct action families**, several already live in Core (`ops.activity.summary`, `ops.combat.deaths`, `ops.resources.summary`, `ops.economy.summary`).

#### S-2 (High) — No required-status-checks gate on `main`; second-person review is not an applicable control for a solo maintainer

**Evidence** (live GitHub API queries):
```
GET /repos/yacketrj/dune-ops-observability-addon/branches/main/protection → 404 "Branch not protected"
GET /repos/yacketrj/dune-ops-observability-addon/rulesets → []
```
Last 5 merged PRs (`#49`–`#53`, including one merged same-day as this review) all show `"reviews": []`.

**Correction from initial draft**: this repository is maintained by a single developer acting as the entire dev/sec/ops function. `docs/GITHUB-RULESETS.md`/`docs/BRANCH-PROTECTION.md`/`.github/CODEOWNERS` describe a **required PR-review** control (`* @yacketrj` — i.e., the one and only maintainer reviewing their own PRs). That specific control is not achievable in a one-person team; there is no second reviewer to require, and "self-approve required reviews" is security theater, not a real control. Flagging the absence of second-person review as a fixable gap was a miscalibration in the original draft and has been removed from the finding below. This is a structural fact of team size, not a process failure to correct.

What **is** still a real, solo-achievable gap, and is retained here: **required status checks** (`Validate addon`, `Pre-commit`, `Secret Scan`, `SAST`, `Filesystem Scan`, `CI Gate`) are not configured to block merge on `main`, and direct pushes to `main` are not blocked. Neither of these requires a second person — a solo maintainer can (and, per this project's own documented intent, should) still be prevented from *themselves* fast-pathing a broken or unscanned change into `main` by accident (e.g., a force-push during a rebase, a `git commit --no-verify` under time pressure, or simply forgetting to open a PR before pushing). This is a "protect yourself from your own mistakes" control, not a "require someone else's approval" control, and is fully within a solo maintainer's ability to configure and comply with.

Recommended for a solo-maintainer context specifically: configure the ruleset with **required status checks + block force-push + block direct push**, but explicitly **without** a required-approving-review count (set to 0, or omit the review requirement entirely). This gets the enforceable half of the documented intent without asking for a control that doesn't fit the team's actual size — and the repository's own `docs/GITHUB-RULESETS.md`/`docs/BRANCH-PROTECTION.md`/README/CODEOWNERS text should be updated to stop stating a review requirement that isn't realistic to enforce, rather than leaving that expectation undocumented-but-implied.

#### S-3 (High) — Fabricated / non-representative release history on GitHub

**Evidence**: Git tags and GitHub Releases exist for `v0.5.0` through `v1.0.0`, all created on **2026-07-04**, in a single burst — but `v0.5.0..v1.0.0` are **not ancestors of `main`** (`git merge-base --is-ancestor v0.5.0 main` fails). The actual `main` branch's real, currently-"Latest"-flagged GitHub Release is `v0.4.1` (2026-07-08, four days *after* the v1.0.0 tag timestamp). Diffing `v0.4.0..v0.5.0` shows **14,453 lines deleted** relative to what's on `main` today — i.e., the tagged "v0.5.0" release is not a superset/evolution of the real v0.4.x codebase; it's a divergent, smaller, abandoned line of development.

**Impact**: Anyone visiting the public GitHub Releases page — a prospective addon-catalog reviewer, a server operator deciding whether to install this addon, or a downstream contributor — sees "v1.0.0" and reasonably assumes a mature, complete 1.0 product. The real codebase on `main`, which is where all actual ongoing work happens, has not shipped past `0.4.1`, and the in-progress `0.5.0` work is still mid-flight (uncommitted at time of this review). This is a **misleading public artifact** that actively damages the project's credibility and can mislead security/compliance reviewers who check "what version is deployed."

#### S-4 (Medium) — Upstream Core compatibility claim is 16 patch versions stale

**Evidence**: README states "Upstream Dune Docker Console: compatible with `v1.3.45`". Live Core repository (`dune-awakening-selfhost-docker/VERSION`) is at `v1.3.61`. No compatibility testing evidence exists for the 16 intervening patch releases. Given that this addon depends entirely on Core's bridge-action route table remaining stable, an unverified 16-version gap is a real operational risk, not just a documentation nit — Core could have (and per this session's findings, actually did, via the still-in-review PR #103/#104) changed relevant behavior without the addon's compatibility claim being re-validated.

#### S-5 (Medium) — Design docs describe as "future work" what is already implemented; README describes as "not used" what is already implemented

**Evidence**: `docs/architecture/V0.5-DESIGN.md` and `V0.6-DESIGN.md` (dated 2026-07-07, `Status: Design`) describe `ops.economy.summary`, `ops.inventory.summary`, and `ops.location.activity` as forthcoming work gated on Core PRs. All three are already called live in the shipped `data-providers.js`. Simultaneously (see S-1), the README claims economy/inventory data is *not used at all*. Three different documents in the same repository make three mutually inconsistent claims about the same set of bridge actions. This is a governance failure, not a one-off oversight — the README explicitly states *"Documentation drift is a merge blocker. Every PR into main must review and update affected documentation"* — a rule that has evidently not been followed for several PRs in a row.

### 3.3 CI/CD, Testing, and Supply Chain

#### C-1 (High) — `npm audit` and dependency tooling audit nothing

**Evidence**: No `package.json` exists at the repository root. `package-lock.json` is a stray, untracked, zero-dependency lockfile (`"packages": {}`). `.github/workflows/ci.yml`'s `npm-audit` job runs `npm ci --ignore-scripts || true` then `npm audit --audit-level=moderate`, which trivially reports `found 0 vulnerabilities` because there is nothing to scan. `.github/dependabot.yml` has a full `npm` ecosystem configuration (grouped updates, cooldown, ignore rules) that will never produce a PR because there is no manifest to track.

**Impact**: This CI job and dependabot config give the *appearance* of supply-chain hygiene while providing zero actual coverage. If/when this addon starts using any build tooling, bundler, or client-side library (even a dev dependency), there is currently no working mechanism that would catch a vulnerable version.

#### C-2 (High) — Manifest validator breaks on the addon's own current cache-busting fix

**Evidence**: Live-executed `node scripts/validate.js` against the current working tree (which includes the `?v=0.5.1` cache-busting query strings added earlier this session to work around a Cloudflare caching bug) fails all 4 asset-existence checks:
```
FAIL: referenced script "faction-tagger.js?v=0.5.1" does not exist
FAIL: referenced script "dune-addon-bridge.js?v=0.5.1" does not exist
FAIL: referenced script "data-providers.js?v=0.5.1" does not exist
FAIL: referenced script "addon.js?v=0.5.1" does not exist
```
This is because both `scripts/validate.js` and `test/addon.test.js`'s asset-existence regex (`src="([^"]+)"`) capture the query string as part of the filename and pass it directly to `fs.existsSync()` without stripping it. `.github/workflows/validate.yml` runs this exact script on every PR and push to `main`.

**Impact**: This is a currently-live, reproducible CI-blocking bug. If the cache-busting fix (needed to solve a real production caching problem, per this session's earlier work) is committed and pushed as-is, it will fail the required `Validate addon` check and cannot merge without either fixing the validator or reverting the cache-bust. This also means the manifest validator cannot be trusted for any future asset-versioning strategy without a fix.

#### C-3 (High) — `pipeline/tests/*.test.js` (the "OWASP security test suite") is 100% broken and not wired into CI

**Evidence**: `pipeline/tests/owasp-security.test.js` and `pipeline/tests/blueprints-security.test.js` reference `SRC_DIR = join(__dirname, "..", "src")` — a directory that does not exist in this repository (this addon has no server-side `src/`). Running them directly: `node --test pipeline/tests/owasp-security.test.js` → **27/27 tests fail** with `ENOENT: no such file or directory, open '.../pipeline/src/server.js'`. Neither file is referenced by any `.github/workflows/*.yml`. They are only ever invoked by `pipeline/run-security-tests.sh`, which **copies them into a target Core repository's `test/` directory** and runs them there — i.e., they are a cross-repo tool meant to test Core's `server.js`, mislabeled and stored inside the addon repo's own `pipeline/tests/`, and README lists `run-security-tests.sh` as a manual command a developer must remember to run — it is not automated anywhere.

**Impact**: The presence of a `pipeline/tests/` directory with "security test" names in this repository creates a false impression of test coverage for anyone auditing this repo in isolation (as this review initially did, until execution revealed the truth). At minimum this needs relocation/renaming and a README clarification; ideally it should be wired into an actual CI job that runs it against a checked-out Core repo, or removed from this repository entirely in favor of living in Core.

#### C-4 (Medium) — `test/addon.test.js`'s "no sample fallback" test is a substring check, not a behavioral test

**Evidence**: The test asserting the addon "must return unavailable status for failed actions" only checks that the *string* `"unavailable"` appears anywhere in `data-providers.js` source text:
```js
assert.ok(js.includes('"unavailable"') || ...);
```
It does not instantiate the bridge provider, simulate a failed/denied bridge response, and assert that `renderXxx()` in `addon.js` displays "Unavailable" text in the DOM rather than `0`. This is precisely why F-1 (the most severe finding in this review) exists undetected in a codebase whose CHANGELOG explicitly claims this exact class of bug was "Fixed" (see CHANGELOG `[Unreleased]` → Fixed: *"Bridge provider returns `{status: "unavailable"}` instead of sample data for unimplemented actions"* — the provider layer fix is real, but the *rendering* layer consuming it was never fixed or tested).

#### C-5 (Low) — CI security scanning is otherwise genuinely strong

For balance: `ci.yml`/`ci-gate.yml`/`security-gates.yml`/`pre-commit.yml` collectively run gitleaks, semgrep (`p/default` + `p/secrets`), trivy (vuln/misconfig/secret, CRITICAL/HIGH, fail-on-detect), ShellCheck, JSON validation, dependency-review (PR-level, moderate+ blocking), and a weekly scheduled scan. All GitHub Actions are pinned to immutable SHAs with version comments. This is materially better than most projects of this size and should be preserved as-is — the gap is not in *what* is scanned, it's that the scanned surface (client-side JS/HTML/manifest/shell) doesn't include the parts of the system (rendering logic correctness, actual bridge-action behavior, release/branch governance) where the real defects live.

### 3.4 Client-Side Application Security

#### A-1 (Low) — No Content-Security-Policy

**Evidence**: `web/index.html` has no `<meta http-equiv="Content-Security-Policy">` tag and Core's static file server (per `SECURITY.md`'s own description of the addon's threat model) is not confirmed to set a CSP header for addon content. Given the addon is loaded in a same-origin iframe within the trusted Console, and all current DOM writes use `textContent`/`setAttribute` (verified — no `.innerHTML` with dynamic content, no inline event handlers, no `eval`), the exploitability here is low today. But CSP is cheap defense-in-depth against any future regression (e.g., a contributor adding an `innerHTML` call for a rich-text feature) and should be added rather than relied-upon-by-convention.

#### A-2 (Low) — Static `innerHTML` usage, though not attacker-controlled

**Evidence**: `web/addon.js` lines ~690–736 use `innerHTML = '<p style="...">...</p>'` with hardcoded static strings for "no data available" placeholder messages. `test/addon.test.js` explicitly asserts `addon.js does not use innerHTML` (`assert.ok(!js.includes(".innerHTML"))`) — **this test currently fails** against the working tree (confirmed: these lines exist in the uncommitted `addon.js` changes). While not exploitable (no interpolated/attacker-controlled content), this is (a) a real, currently-failing project-owned test, and (b) inconsistent with the rest of the file's `textContent`-only discipline, and should be converted to `textContent` or DOM node creation for consistency and to keep the test green.

#### A-3 (Low) — postMessage bridge is well-implemented; no findings

For balance: `web/dune-addon-bridge.js` correctly targets `window.location.origin` (not `"*"`) on send, checks `event.origin === window.location.origin` **and** `event.source === window.parent` on receive, validates `message.type`, `message.addonId`, `message.requestId`, and `typeof message.ok === "boolean"` before acting on any inbound message, and has a 30-second request timeout with proper cleanup. This is a correctly-implemented trust boundary and should be the reference pattern for any future bridge-adjacent code.

---

## 4. Findings Summary Table

| ID | Domain | Severity | Title | Status |
|----|--------|----------|-------|--------|
| F-1 | Functional/Trust | **Critical** | Unsupported/errored bridge data renders as false zero | Confirmed live |
| F-2 | Functional/Trust | High | Fabricated PvP/PvE sietch/instance data from partial rows | Confirmed (uncommitted) |
| F-3 | Functional/Trust | Medium | Preview sample data visually indistinguishable from live data | Confirmed |
| F-4 | Functional/Trust | Medium | "All sources online" claimed regardless of per-source success | Confirmed |
| S-1 | Security Boundary | High | README boundary claims contradict shipped bridge-action usage | Confirmed |
| S-2 | Governance | High | No required-status-checks gate on `main`; second-person review not applicable to a solo team (see note) | Confirmed live |
| S-3 | Governance | High | Fabricated/divergent v0.5.0–v1.0.0 release history | Confirmed live |
| S-4 | Governance | Medium | Upstream Core compatibility claim 16 versions stale | Confirmed |
| S-5 | Governance | Medium | Design docs and README mutually contradict implementation state | Confirmed |
| C-1 | Supply Chain | High | `npm audit`/dependabot audit an empty manifest | Confirmed live |
| C-2 | CI/CD | High | Manifest validator breaks on addon's own cache-bust fix | Confirmed live |
| C-3 | Testing | High | "OWASP test suite" 100% fails, not wired into CI, wrong repo's code | Confirmed live |
| C-4 | Testing | Medium | Key regression test is a substring check, not behavioral | Confirmed |
| C-5 | CI/CD | — (positive) | Static security scanning breadth is strong | Confirmed |
| A-1 | AppSec | Low | No CSP | Confirmed |
| A-2 | AppSec | Low | Static innerHTML fails project's own test | Confirmed live |
| A-3 | AppSec | — (positive) | postMessage bridge correctly implemented | Confirmed |

---

## 5. Root Cause Analysis

Nearly every Critical/High finding traces back to one of two root causes:

1. **No behavioral/integration testing of the rendering layer against the full space of provider response states** (success, empty, unavailable/denied, error, timeout). Every functional finding (F-1 through F-4) and the weakest test (C-4) share this root cause. The provider layer was fixed to return honest `{status:"unavailable"}` envelopes; nothing downstream was updated or tested to consume them.
2. **Process artifacts (docs, CI jobs, release tags, branch rules) were created once, sized for a team the project doesn't have, front-loaded, and not kept synchronized with a fast-moving codebase.** This explains S-1, S-3, S-4, S-5, C-1, C-2, and C-3 — each is a case of "the governance scaffolding says X, the code does Y" — and also explains the corrected part of S-2: some of that scaffolding (required second-person review) describes a multi-person team's process, not this project's actual one-person team. The project's own stated rule ("Documentation drift is a merge blocker") is sound; the *solo-achievable* half of its enforcement mechanism (required status checks on `main`) is a real missing piece that would have caught most of these before merge — but the *review-requirement* half of that same documented control cannot be enforced by adding more configuration, because it requires a resource (a second reviewer) the team doesn't have.

This means the roadmap below is not "add more process" — it's "make the rendering layer trustworthy," "turn on the enforcement that a solo maintainer can actually deliver," and "stop the project's own documentation from promising a review process it cannot support."

---

## 6. Prioritized Roadmap

Phases are sequenced by (a) risk reduction per unit effort and (b) dependency order — later phases assume earlier phases are done. Each phase lists concrete deliverables and a rough effort sizing (S = <1 day, M = 1–3 days, L = 3–7 days) assuming one engineer familiar with the codebase.

### Phase 0 — Stop the Bleeding (do before any other addon work merges) — **effort: S**

Goal: prevent the currently-uncommitted work-in-progress from making any of the above worse, and close the most exploitable governance gap immediately.

1. **Enable the solo-achievable subset of branch protection on `main`** (S-2): required status checks (`Validate addon`, `Pre-commit`, `Secret Scan`, `SAST`, `Filesystem Scan`, `CI Gate`) must pass before merge, and block force-push / direct pushes to `main`. **Do not** configure a required-approving-review count — with one maintainer, "require 1 approval" either blocks the maintainer from ever merging their own work, or is satisfied by self-approval, which is not a real control. This is a ~15-minute GitHub Settings/API change with zero code risk and closes the achievable half of S-2 immediately.
2. **Fix `scripts/validate.js` and `test/addon.test.js` to strip query strings before checking asset existence** (C-2). One-line regex fix (`src.split("?")[0]`) in both files. Must land before the cache-busting `?v=` fix is committed, or CI will block it.
3. **Do not tag/publish any new GitHub Release until Phase 2 is complete.** Freeze release-tag creation. Do not delete the existing `v0.5.0`–`v1.0.0` mistaken tags/releases yet (that's a Phase 1 decision requiring maintainer sign-off, since it's a public-facing change) — but stop making the problem worse.

### Phase 1 — Truth in Advertising (governance & documentation reconciliation) — **effort: M**

1. **Decide and execute a remediation for the divergent `v0.5.0`–`v1.0.0` releases** (S-3). Recommended: mark all of them as pre-release/draft with a note explaining the divergence, or delete them if the catalog listing doesn't reference them, and re-tag from `main`'s actual current HEAD once Phase 2/3 land, starting a clean, honest `v0.5.0`. This requires a maintainer decision (it's a public artifact) — document the decision either way.
2. **Rewrite `README.md`'s "Security and permission boundary" and "Current bridge-backed actions" sections** to accurately list all 9 action families actually called by `data-providers.js`, correctly stating which are live in Core today (`ops.health.*`, `ops.activity.summary`, `ops.combat.deaths`, `ops.resources.summary`, `ops.economy.summary`) vs. not yet implemented (`ops.inventory.summary`, `ops.location.activity`, `ops.soc.summary`, `ops.health.prometheus`) — see F-1/S-1.
3. **Reconcile `docs/architecture/V0.5-DESIGN.md` / `V0.6-DESIGN.md` status fields** — mark `ops.economy.summary` as "Implemented" (Core-side confirmed live) and clearly mark `ops.inventory.summary`/`ops.location.activity` as "Addon calls this optimistically; Core does not implement it yet" rather than leaving both docs silent on the mismatch.
4. **Re-validate the upstream Core compatibility claim** (S-4) — either pin-test against Core `v1.3.61` and update the README compatibility line, or establish a lightweight compatibility-check script that diffs the addon's called bridge actions against Core's route table on a schedule (this doubles as an early-warning system for S-1-style drift going forward).
5. **Relocate or clearly re-scope `pipeline/tests/`** (C-3) — either move it into a `tools/cross-repo-security-tests/` directory with a README stating explicitly "these test Core's server.js, run via `run-security-tests.sh <core-repo-path>`, not part of this repo's own CI," or wire an actual CI job that checks out Core and runs it automatically on a schedule. Either way, stop presenting it as this repo's own test suite.
6. **Right-size the review-process language in `docs/GITHUB-RULESETS.md`, `docs/BRANCH-PROTECTION.md`, `README.md`, and `.github/CODEOWNERS`** (S-2). Replace "all changes require owner review" / required-approval language with an accurate description of what a solo maintainer actually does and can enforce (e.g., "required CI checks must pass before merge; there is currently one maintainer, so PR review is self-review assisted by required automated checks — a second reviewer will be required once/if a second maintainer joins"). This is a wording change, not a process change, but it closes the documentation-integrity gap without asking the team to staff up.

### Phase 2 — Source-State Truth Model (the core functional fix) — **effort: L**

This is the highest-value engineering work in this roadmap — it directly fixes F-1, F-2, F-3, F-4, and C-4 as one coherent change, and is a prerequisite for any future observability feature being trustworthy.

1. **Introduce a normalized `SourceResult` envelope** consumed uniformly by every `renderXxx()` function in `addon.js`:
   ```js
   { status: "live" | "unavailable" | "not_approved" | "bridge_error" | "timeout" | "source_empty" | "preview", data: T | null, reason?, source? }
   ```
   Every provider method (`getActivity`, `getCombat`, `getResources`, `getEconomy`, `getInventory`, `getLocation`, `getSoc`, `getPrometheusHealth`, and `getOpsHealth` — currently the odd one out) must return this shape unconditionally, including on success (`status: "live"`).
2. **Rewrite every `renderXxx(data)` function to switch on `data.status` first**, before touching `data.data.*` fields. Define the exact UI treatment per status once (e.g., a shared `renderUnavailablePanel(container, reason)` helper that writes "Not available — <reason>" instead of numeric fields), and reuse it across all 8 panels instead of each panel inventing its own zero-value fallback.
3. **Fix `refreshAll()`'s status banner** (F-4) to compute real aggregate health from the 9 per-source statuses (e.g., "7/9 sources live, 2 unavailable") instead of a hardcoded "All observability sources online" string.
4. **Add a persistent, visually distinct preview-mode treatment** (F-3) — e.g., a diagonal watermark or colored border on every panel, not just the status banner — so preview data can never be mistaken for live data even mid-scroll or in a screenshot.
5. **Remove the fabricated PvP/PvE sietch/instance synthesis** (F-2) from `addon.js` entirely. Replace with an explicit "PvP/PvE designation not available from current data source" state until a real Core-side combat-state bridge action exists (tracked separately in the Core repo's PR #103/#104 follow-up work).
6. **Write real behavioral regression tests** replacing/augmenting C-4's substring check: instantiate the bridge provider with a mocked `window.DuneAddon.request` that returns each of the new `SourceResult` statuses in turn, call each `renderXxx()`, and assert the resulting DOM text is the expected "Unavailable"/"Not approved"/etc. string and *not* `"0"`. This is the single test suite addition that would have caught F-1 before it shipped, and must be added as a required CI check.

### Phase 3 — Supply Chain & Test Infrastructure Cleanup — **effort: M**

1. **Add a real `package.json`** (even if it declares zero runtime dependencies today) so `npm audit`/dependabot's npm ecosystem config actually track something meaningful the moment any dependency is introduced (C-1). If the addon intends to stay dependency-free indefinitely, consider removing the `npm-audit` CI job and the npm dependabot block instead, to stop presenting false coverage — but only after confirming with the maintainer that zero-dependency is a permanent design choice, not an oversight.
2. **Fix the failing `web/addon.js does not use innerHTML` test** (A-2) by converting the four static-string `innerHTML` assignments to `textContent`/DOM-node construction, restoring this test to green rather than leaving it silently broken.
3. **Add a minimal CSP `<meta>` tag** to `web/index.html` (A-1) as defense-in-depth (e.g., `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'`), documented alongside the existing bridge-security section of `SECURITY.md`.

### Phase 4 — Ongoing Governance Hardening — **effort: S, recurring**

1. Add a CI check (or scheduled job) that fails if `README.md`'s listed bridge actions diverge from the actual set of `bridgeRequest(...)` calls in `web/data-providers.js` — a simple grep-and-diff script — to make S-1/S-5-style drift structurally harder to reintroduce.
2. Add the same kind of automated check for `addon.json.version` vs. `web/index.html`'s displayed version vs. the latest real (non-fabricated) GitHub Release tag, closing the loop that C-2/S-3 exposed.
3. Formalize the release-tagging process so that `git tag vX.Y.Z` can only happen from a commit that is an ancestor of `main` (e.g., a release-workflow guard that checks `git merge-base --is-ancestor <sha> main` before allowing `gh release create`), preventing a repeat of S-3.

---

## 7. What Is Already Right (do not regress)

To keep this document balanced and to make clear which patterns should be *preserved* rather than "fixed":

- The postMessage bridge's origin/source/shape validation (`web/dune-addon-bridge.js`) is a correct, minimal, well-scoped trust-boundary implementation.
- DOM rendering discipline is `textContent`-first almost everywhere; no dynamic `innerHTML`, no inline event handlers, no `eval`.
- The manifest (`addon.json`) permission model is genuinely read-only (`ops:read` only), and `test/addon.test.js` has a real enforcement test for this (`permissions are read-only`) that would fail if a write scope were ever added.
- CI security-scanning breadth (gitleaks, semgrep with two rule packs, trivy across vuln/misconfig/secret, ShellCheck, dependency-review, weekly scheduled scans, pinned Action SHAs) is genuinely above-average for a project of this size.
- `console/api`-side (Core) aggregate queries for economy data (confirmed via `addonOpsEconomySummary`) are correctly aggregate-only — counts, sums, averages, grouped by currency/template — with no player-level identifiers surfaced, which is the correct privacy posture for this category of data.
- The release governance *process design* (`ops-observability/releases/<version>/` evidence folders, 5-gate release standard, metric classification standard) is a sound framework — the gap is enforcement and synchronization, not the design of the framework itself.
