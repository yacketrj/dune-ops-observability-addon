# Security & Architecture Gap Analysis — Resolution Report (Phase 0 + Phase 1)

**Author perspective**: Principal SDET / Principal Security Engineer
**Date**: 2026-07-23
**Scope**: Resolves the Phase 0 ("Stop the Bleeding") and Phase 1 ("Truth in Advertising") items from [`docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md`](./SECURITY-ARCHITECTURE-GAP-ANALYSIS.md), per that document's §6 prioritized roadmap. Phase 2 (the `SourceResult` envelope refactor fixing F-1/F-2/F-3/F-4/C-4), Phase 3 (supply chain/test cleanup), and Phase 4 (ongoing governance automation) are **not** in scope for this change and remain open — see "What remains" below.

---

## 1. Resolution status by finding

| ID | Severity | Title | Status | Resolution |
|----|----------|-------|--------|------------|
| F-1 | Critical | Unsupported/errored bridge data renders as false zero | **Open — deferred to Phase 2** | Requires the `SourceResult` envelope refactor across every `renderXxx()` in `web/addon.js`. Not attempted here; see gap analysis §6 Phase 2. |
| F-2 | High | Fabricated PvP/PvE sietch/instance data | **Not present in current `main`** | Re-verified: `web/addon.js` on `main` has no `pvpInstances`/`pveInstances`/hardcoded `type: "pvp"` synthesis. The gap analysis flagged this against *uncommitted working-tree changes* from a prior session that were never committed to this repository. No action needed here; if this pattern is reintroduced, treat it as F-1's fabrication anti-pattern and block it before merge. |
| F-3 | Medium | Preview sample data indistinguishable from live data | **Open — deferred to Phase 2** | Unchanged. |
| F-4 | Medium | "All sources online" claimed regardless of per-source success | **Open — deferred to Phase 2** | Unchanged. |
| S-1 | High | README boundary claims contradict shipped bridge-action usage | **Resolved** | §2.1 |
| S-2 | High | No required-status-checks gate on `main`; solo-team review language | **Resolved** | §2.2 |
| S-3 | High | Fabricated/divergent `v0.5.0`–`v1.0.0` release history | **Documented, not executed** | §2.3 — requires explicit maintainer decision on a public artifact. |
| S-4 | Medium | Upstream Core compatibility claim 16 versions stale | **Resolved (partial)** | §2.4 — corrected to an honest, dated, narrower claim; full compatibility regression testing across the 16 intervening versions was not performed. |
| S-5 | Medium | Design docs and README mutually contradict implementation state | **Resolved** | §2.5 |
| C-1 | High | `npm audit`/dependabot audit an empty manifest | **Open — deferred to Phase 3** | Unchanged. |
| C-2 | High | Manifest validator breaks on cache-busting query strings | **Resolved** | §2.6 |
| C-3 | High | "OWASP test suite" 100% fails, wrong-repo code, not wired into CI | **Open — deferred to Phase 3** | Unchanged. |
| C-4 | Medium | Key regression test is a substring check, not behavioral | **Open — deferred to Phase 2** | The real fix requires the Phase 2 envelope refactor to have something meaningful to test against. |
| A-1 | Low | No CSP | **Open — deferred to Phase 3** | Unchanged. |
| A-2 | Low | Static `innerHTML` fails project's own test | **Not present in current `main`** | Re-verified: `web/addon.js` on `main` has zero `innerHTML` occurrences; `test/addon.test.js`'s "does not use innerHTML" assertion currently passes. Same as F-2 — this was an uncommitted working-tree artifact from a prior session, not present in the repository. |

**Summary**: 4 of 16 open findings fully resolved (S-1, S-2, S-4 partial, S-5, C-2); 2 findings (F-2, A-2) turned out to already be non-issues on `main` — the gap analysis correctly identified them in an uncommitted working tree that was never merged; 1 finding (S-3) documented with two concrete options presented, no action taken (public-artifact decision reserved for the maintainer); remaining 9 findings (F-1, F-3, F-4, C-1, C-3, C-4, A-1) are unchanged, tracked for Phase 2/3 per the gap analysis's own roadmap.

Additionally, **one new defect was found during this work**, not in the original gap analysis: `.github/workflows/ci-gate.yml`'s `gate` job used a cross-workflow `needs:` list (referencing job IDs defined in `validate.yml`, `pre-commit.yml`, `sast.yml`, `secret-scan.yml`, `filesystem-scan.yml` — separate workflow files), which is invalid GitHub Actions syntax. This caused the workflow to fail its own startup validation on every single run since it was added (`16aaf4b`, 2026-07-20), including every run on `main` after merge. See §2.7.

---

## 2. Resolution detail

### 2.1 S-1 — `README.md`

Rewrote the "does not request or use" list to remove the false claim that the addon doesn't use economy/inventory data — it does, under the same `ops:read` scope, and both are genuinely aggregate-only (verified directly against `duneDb.addonOpsEconomySummary()`'s SQL: `count`, `sum`, `avg`, grouped by `currency_id`/`template_id`, no `player_controller_id` or player names in any returned row).

Replaced the stale 4-action `leadership.players.list`/`ops.health.*` list (a carryover from the pre-v0.3.0 `players:read` permission model) with an accurate table of all 9 action families the shipped `web/data-providers.js` actually calls, each annotated with its live/not-implemented status in Core — re-verified directly against `console/api/src/server.js`'s route table (`action === "..."` branches) rather than trusting the previous README's claim.

### 2.2 S-2 — `docs/BRANCH-PROTECTION.md`, `docs/GITHUB-RULESETS.md`, `.github/CODEOWNERS`, live branch protection

Rewrote all three governance documents to stop implying a required-approving-review process this one-person team cannot support: removed "require a pull request before merging" and all review-count language, added an explicit "note on team size" section to `docs/BRANCH-PROTECTION.md` explaining why (mirrors the same reasoning already applied to `acp-landing`, `Arrakis-Control-Panel`, and `dune-awakening-selfhost-docker` in this session). `.github/CODEOWNERS` now has a comment clarifying its purpose (ownership/notification routing) is not paired with a review-requirement rule.

Corrected the documented required-check list in both files from the previous (already-partially-stale) `Pre-commit / pre-commit (pull_request)`, `Secret Scan`, `Filesystem Scan`, `Validate addon`, `SAST` to the actually-correct set: `CI Gate` (covering `ci.yml`'s Shell Lint/Validate JSON/NPM Audit/Security Scanning) plus `validate`, `pre-commit`, `semgrep`, `gitleaks`, `trivy` from the split workflows — verified against live GitHub Actions API output (`gh api repos/.../actions/workflows`) rather than guessed.

**Live branch protection configured** on `main` (verified via `gh api -X PUT repos/yacketrj/dune-ops-observability-addon/branches/main/protection`):
- Required status checks: `CI Gate`, `validate`, `pre-commit`, `semgrep`, `gitleaks`, `trivy` (strict — branch must be up to date).
- No required-approving-review count.
- Force pushes and branch deletion blocked.
- `enforce_admins: false` (matches the pattern applied to the other three repos this session — the maintainer can still bypass in a genuine emergency, consistent with the bypass-policy documented in both governance docs).

### 2.3 S-3 — release history (documented, not executed)

Per the gap analysis's own instruction ("this requires a maintainer decision... document the decision either way") and this session's standing rule against unilaterally touching public-facing governance artifacts, no releases were deleted, edited, or re-tagged. Two options, as originally framed by the gap analysis, are presented here for the maintainer's decision:

1. **Mark `v0.5.0`–`v1.0.0` as draft/pre-release** with a note explaining the divergence (they are not ancestors of `main`), leaving them visible but clearly flagged as not representing the real `main` history.
2. **Delete `v0.5.0`–`v1.0.0`** entirely (git tags and GitHub Releases), then re-tag a clean `v0.5.0` from `main`'s actual current HEAD once Phase 2/3 land — only viable if nothing external (the addon catalog listing, a downstream consumer) references these specific tags today.

No recommendation is asserted as final here beyond what the gap analysis already stated; this is the maintainer's call on a public artifact, not a code-correctness question.

### 2.4 S-4 — Core compatibility claim

Re-verified directly: the fork's `VERSION` file and upstream `Red-Blink/dune-awakening-selfhost-docker`'s `VERSION` file both read `v1.3.61` (confirmed via `gh api repos/Red-Blink/dune-awakening-selfhost-docker/contents/VERSION`), not `v1.3.45` as the README claimed. Re-confirmed that all 9 bridge action families the addon depends on are still present (for the 5 live ones) or still absent (for the 4 not-yet-implemented ones) in `v1.3.61`'s route table — i.e., the specific integration surface this addon relies on has not regressed across the 16-version gap, even though a full behavioral regression test was not performed.

Updated the README's compatibility claim to state precisely what was verified (a targeted route-table check, dated) rather than either leaving the stale `v1.3.45` claim or asserting broader compatibility than was actually tested. The gap analysis's suggested "lightweight compatibility-check script" (§6 Phase 1 item 4) was not built as part of this change — that's a small but real piece of new tooling, appropriately scoped to Phase 4's "ongoing governance hardening" rather than a doc-accuracy fix.

### 2.5 S-5 — `docs/architecture/V0.5-DESIGN.md`, `V0.6-DESIGN.md`

Updated both `Status:` fields to reflect verified reality: `V0.5-DESIGN.md`'s `ops.economy.summary` is marked `Implemented`, since it's confirmed live in Core and called by the addon. `V0.6-DESIGN.md`'s `ops.inventory.summary`/`ops.location.activity` remain marked `Design`, with an explicit note that the addon calls them optimistically today and the bridge provider correctly returns `{status: "unavailable"}` for both — resolving the three-way documentation contradiction the gap analysis identified (README said "not used," design docs said "future work," code said "already calling this live").

### 2.6 C-2 — `scripts/validate.js`, `test/addon.test.js`

Fixed both asset-existence checks to strip query strings (`src.split("?")[0]`) before calling `fs.existsSync()`/`existsSync()`. Verified directly: temporarily added `?v=0.5.1-test` to `web/index.html`'s `addon.js` script tag, confirmed both `node scripts/validate.js` and `node --test test/addon.test.js` (all 14 tests) pass with the query string present, then reverted the test-only change (confirmed zero diff on `web/index.html` afterward).

### 2.7 New finding — `.github/workflows/ci-gate.yml` broken since creation

**Evidence**: `gh run list --workflow=ci-gate.yml` shows `conclusion: failure` on every run since the workflow was added (`16aaf4b`, "chore: add CI Gate workflow required by branch protection"). Root cause: its single job (`gate`) declares `needs: [validate, pre-commit, semgrep, gitleaks, trivy]`, but those five job IDs are defined in five separate workflow files (`validate.yml`, `pre-commit.yml`, `sast.yml`, `secret-scan.yml`, `filesystem-scan.yml`). GitHub Actions `needs:` can only reference jobs within the same workflow file — this is invalid configuration that fails GitHub's own workflow-file validation before any job runs, confirmed via `gh run view <id>` reporting "This run likely failed because of a workflow file issue" on every invocation.

This is precisely why S-2's branch protection was never actually turned on despite the commit message's stated intent ("required by branch protection") — the check this workflow was meant to provide could never pass, so requiring it would have permanently blocked every merge.

**Resolution**: deleted `.github/workflows/ci-gate.yml`. It was fully redundant with `.github/workflows/ci.yml`'s own `ci-gate` job (job id `ci-gate`, display name `CI Gate` — an exact name collision with the broken standalone file), which correctly aggregates its four same-workflow jobs (`shellcheck`, `validate-json`, `npm-audit`, `security`) and has passed on every run. The five jobs the broken file was trying to aggregate (`validate`, `pre-commit`, `semgrep`, `gitleaks`, `trivy`) are now required as individual status checks instead (see §2.2) — this achieves the same enforcement goal without a second, non-functional "CI Gate"-named job competing with the working one.

---

## 3. What remains (not in scope for this change)

Per the gap analysis's own phased roadmap:

- **Phase 2 (effort: L)** — the `SourceResult` envelope refactor. This is the highest-value remaining work: it fixes F-1 (the Critical finding), F-3, F-4, and C-4 as one coherent change. Not started.
- **Phase 3 (effort: M)** — add a real `package.json` (or remove the `npm-audit` job/dependabot npm block if zero-dependency is a permanent, confirmed design choice), fix the failing... — actually A-2's test was found to already be passing (see §1), but C-1 (empty-manifest audit) and C-3 (mislabeled cross-repo test suite) remain open. A-1 (no CSP) also remains open.
- **Phase 4 (effort: S, recurring)** — automated drift detection between README's bridge-action list and actual code, version-consistency checks, a release-tagging guard requiring the tagged commit be an ancestor of `main` (would have prevented S-3).
- **S-3's actual resolution** — requires the maintainer to pick one of the two options in §2.3 above.

---

## 4. Verification summary

```
$ node scripts/validate.js
Addon manifest is valid: dune-ops-observability v0.4.1

$ node --test test/addon.test.js
# tests 14
# pass 14
# fail 0

$ pre-commit run --files scripts/validate.js test/addon.test.js README.md \
    docs/architecture/V0.5-DESIGN.md docs/architecture/V0.6-DESIGN.md \
    docs/GITHUB-RULESETS.md docs/BRANCH-PROTECTION.md .github/CODEOWNERS
check for merge conflicts: Passed
mixed line ending: Passed
fix end of files: Passed
trim trailing whitespace: Passed
Detect hardcoded secrets: Passed
trivy: Passed
semgrep: Passed
Validate addon manifest: Passed

$ gh api repos/yacketrj/dune-ops-observability-addon/branches/main/protection \
    --jq '{checks: .required_status_checks.contexts, reviews: .required_pull_request_reviews, force_push: .allow_force_pushes.enabled}'
{
  "checks": ["CI Gate", "validate", "pre-commit", "semgrep", "gitleaks", "trivy"],
  "reviews": null,
  "force_push": false
}
```

Manual regression test confirming the C-2 fix (query-string cache-busting):
```
$ sed -i 's/src="addon\.js"/src="addon.js?v=0.5.1-test"/' web/index.html
$ node scripts/validate.js
Addon manifest is valid: dune-ops-observability v0.4.1   # previously: 4 FAIL lines
$ node --test test/addon.test.js   # 14/14 pass with query string present
$ git checkout web/index.html   # reverted test-only change, confirmed zero diff
```
