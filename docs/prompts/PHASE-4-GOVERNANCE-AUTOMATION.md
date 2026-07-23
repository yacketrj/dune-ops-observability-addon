# Implementation Prompt — Phase 4: Ongoing Governance Hardening

You are a senior DevSecOps engineer implementing Phase 4 ("Ongoing Governance Hardening") from `docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md` §6, for `yacketrj/dune-ops-observability-addon`. Phases 0 through 3 are complete and merged (PRs #63, #64, #65, #66) — see `docs/GAP-ANALYSIS-RESOLUTION-2026-07-23.md` for that full history. Phase 4 is the last phase in the roadmap and is explicitly scoped as **recurring, low-effort automation** — three specific, concrete mechanisms, not a broad rewrite.

Read this entire prompt before writing any code. It contains verified, current-as-of-2026-07-23 evidence for exactly where things stand today, including two corrections to the original gap analysis's Phase 4 description that you need to know about before starting (§0 below) — the original text is slightly stale against work completed in Phases 2 and 3, and following it literally would produce an incomplete fix.

---

## 0. Corrections to the original Phase 4 description — read first

The gap analysis's original Phase 4 item 1 says: *"Add a CI check... that fails if README.md's listed bridge actions diverge from the actual set of `bridgeRequest(...)` calls in web/data-providers.js — a simple grep-and-diff script."*

**This is now incomplete.** Since the Phase 2 `SourceResult` refactor (PR #64), `web/data-providers.js`'s `bridge` provider object calls bridge actions two different ways:
- 3 actions (`ops.health.summary.v2`, `ops.health.players`, `ops.health.farms`) are called via direct `bridgeRequest("...")` calls (verified: `data-providers.js` lines ~365-367).
- 6 actions (`ops.activity.summary`, `ops.combat.deaths`, `ops.resources.summary`, `ops.economy.summary`, `ops.inventory.summary`, `ops.location.activity`, `ops.soc.summary`, `ops.health.prometheus` — 8 actions, not 6, correcting this draft's own count while writing it) are called via a shared `fetchLiveOrUnavailable("...")` wrapper (verified: lines ~375-396), which itself calls `bridgeRequest(action)` once, internally.

A grep for literal `bridgeRequest("` calls will only ever find the 3 `ops.health.*` actions (called directly inside `getOpsHealth()`) — it will miss the other 8 call sites entirely (`getActivity`, `getCombat`, `getResources`, `getEconomy`, `getInventory`, `getLocation`, `getSoc`, `getPrometheusHealth`, one `fetchLiveOrUnavailable("...")` call each), since their action-name strings appear as arguments to `fetchLiveOrUnavailable(...)`, not `bridgeRequest(...)` directly (verified via `grep -c`: exactly 3 direct `bridgeRequest("` calls, exactly 8 `fetchLiveOrUnavailable("` calls, 9 total distinct action strings — `ops.health.summary.v2`/`.players`/`.farms` count as 3 of the distinct actions from the direct-call group, the other 6 real actions plus `ops.soc.summary` and `ops.health.prometheus` make up the 8 from the wrapper group). **Your drift-check script must account for both calling patterns**, or it will silently miss any drift in the 8 actions called via the wrapper — which would defeat the entire purpose of this task.

Additionally, `README.md`'s current "Current bridge-backed actions" table (verified, current content) lists exactly 9 actions with Live/Not-implemented status per action — this table itself was rewritten as part of the Phase 0/1 fix (S-1) and is currently accurate. Your job is to make sure it *stays* that way automatically, not to fix it again right now.

---

## 1. Item 1 — README bridge-action drift check

### Goal
A CI check (or local script run by CI) that fails if `README.md`'s "Current bridge-backed actions" table's list of action strings ever diverges from the actual, complete set of action strings the addon calls, across both calling patterns identified in §0.

### Implementation approach
1. Write a new script, e.g. `scripts/check-bridge-action-drift.js` (plain Node, no new dependency — this repository ships zero runtime dependencies by design, and this is a dev-time check, not shipped code).
2. Extract the real, complete action-string set from `web/data-providers.js` using two regexes: one for `bridgeRequest("([^"]+)")` and one for `fetchLiveOrUnavailable("([^"]+)")` (or, more robustly, parse for both patterns' string-literal arguments generally — your choice, but verify it actually finds exactly 9 distinct action strings against the current file before considering it correct, not just that it runs without error).
3. Extract the action-string set from `README.md`'s "Current bridge-backed actions" table (the markdown table rows, each starting with `| \`ops...`).
4. Diff the two sets. Fail (non-zero exit, clear error message naming exactly which actions are missing from which side) if they don't match exactly.
5. Wire this script into `.github/workflows/ci.yml`'s existing `unit-tests` job (added in Phase 2 — the natural home for this, since it already runs `node scripts/validate.js && npm test`; add your new script as a third step) — do not create a whole new workflow file for a single script.
6. Add a corresponding local test to `test/addon.test.js` (or a new small test file) that would fail if someone added a 10th action to `data-providers.js` without updating `README.md`, and vice versa — i.e., test the *checker itself*, not just run it once and trust it forever.

### Verification standard
- Deliberately add a fake 10th bridge action to a scratch copy of `data-providers.js` (in a temp branch or local-only change, never committed) and confirm your script correctly flags it as undocumented in README, then revert.
- Deliberately remove one row from a scratch copy of `README.md`'s table and confirm your script flags the resulting mismatch, then revert.
- Confirm the script passes cleanly against the actual current, correct state of both files before merging.

---

## 2. Item 2 — version-consistency check across three sources

### Goal
The gap analysis's original wording only mentions `addon.json.version` vs. `index.html`'s displayed version vs. "the latest real (non-fabricated) GitHub Release tag." Verified current state, and one correction:

- `addon.json` and `web/index.html`'s displayed version are **already checked against each other** — `scripts/validate.js` (lines ~94-96) and a `test/addon.test.js` test both do this today, and both currently pass (both read `0.4.1`).
- **`package.json`'s version field is a third source this check should also cover**, which the original gap analysis didn't mention (it predates Phase 2 adding a real `package.json` with a version field via the `jsdom` devDependency addition). Verified current state: `package.json` and `addon.json` both currently say `0.4.1` — in sync today, but nothing enforces that going forward, and this is a real, present drift surface the original Phase 4 text missed.
- **The GitHub Release tag comparison is the genuinely new piece.** Verified current state: `gh release list` shows the latest tag as `v0.4.1` (dated 2026-07-08) — but also shows `v0.5.0` through `v1.0.0` (dated 2026-07-04, i.e., *before* `v0.4.1` despite the higher version numbers), which are the fabricated/divergent releases S-3 already identified (confirmed directly in this session: `git merge-base --is-ancestor origin/release/v0.5.0 origin/main` returns false — that release's source branch is not reachable from `main`). **Do not build a "latest release tag" check that naively takes the highest-numbered or most-recent-by-date tag** — it must specifically determine "the latest release tag whose commit is an ancestor of `main`," which is a different, correct question that happens to require exactly the item-3 ancestor-check logic below as a building block. Build item 3 first, or build the ancestor-check logic as a shared function both items 2 and 3 can call.

### Implementation approach
1. Extend (or write, if it doesn't already exist as a standalone function) an ancestor-aware "find the latest real release" check: list all release tags via `gh release list` or the GitHub API, filter to only those whose tag commit is an ancestor of `main` (see item 3's `git merge-base --is-ancestor` approach), then take the highest-version one among *those*.
2. Compare that result against `addon.json.version`, `package.json.version`, and `web/index.html`'s displayed version — all three must agree with each other, and the release-tag check is informational/advisory (failing this specific comparison on every commit between releases would be expected and correct, not a bug — you're not expected to cut a new release on every commit). Decide explicitly whether this three-way check should be a hard CI failure (probably only for the `addon.json`/`package.json`/`index.html` mutual consistency, which should never legitimately disagree) versus an informational report (for the "is this newer than the latest real release" comparison, which is expected to differ constantly during normal development) — do not make routine, correct commits fail CI over an expected, healthy state of "unreleased version is ahead of latest tag."
3. This is naturally an extension of item 1's script or a sibling script in the same file/job — your choice, but don't duplicate the ancestor-check logic between items 2 and 3; write it once, use it twice.

### Verification standard
- Confirm your ancestor-aware "latest real release" logic correctly identifies `v0.4.1` (not `v1.0.0`) as the latest real release, given the actual current tag/branch state of this repository — this is a real, live test case already sitting in this repository's own history; use it.
- Confirm the three-way version check currently passes (since all three sources agree at `0.4.1` today) and would fail if you temporarily, locally desynced one of the three files.

---

## 3. Item 3 — release-tagging ancestor guard

### Goal
Prevent a repeat of S-3: `git tag vX.Y.Z && git push --tags` (or an equivalent `gh release create`) should be blocked, or at minimum loudly flagged, if the tagged commit is not an ancestor of `main`.

### Verified current state — the gap is real and specific
`.github/workflows/release.yml` triggers on `push: tags: "v*"` with **no ancestor check anywhere** and **no `fetch-depth: 0`** on its checkout step (verified: `actions/checkout@...` with no `with: fetch-depth` override, meaning it defaults to a shallow, depth-1 checkout — insufficient for `git merge-base` to work correctly without an additional fetch step).

### Implementation approach
1. In `.github/workflows/release.yml`, change the checkout step to `fetch-depth: 0` (full history) — required for any ancestor check to function at all.
2. Add a new step, immediately after checkout and before any packaging/release work, that runs:
   ```bash
   git fetch origin main --depth=1  # or rely on fetch-depth: 0 having already pulled main's ref
   if ! git merge-base --is-ancestor "$GITHUB_SHA" origin/main; then
     echo "Refusing to release: tagged commit $GITHUB_SHA is not an ancestor of main."
     echo "This is exactly the defect that produced the fabricated v0.5.0-v1.0.0 releases — see S-3 in docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md."
     exit 1
   fi
   ```
   Verify the exact ref-fetching mechanics work correctly in GitHub Actions' tag-triggered checkout context (the checked-out ref on a tag push is the tag's commit, not a branch — confirm `$GITHUB_SHA` is the right variable to check, and that `origin/main` is actually fetchable and correctly up-to-date at the time this runs, not a stale cached ref) before considering this done. This is exactly the kind of detail that's easy to get subtly wrong and must be tested against a real tag push, not just read and assumed correct.
3. Consider also (not required, but directly requested by the gap analysis's own phrasing "e.g., a release-workflow guard that checks...") whether this same check should exist as a local pre-push or pre-tag git hook, so a developer gets the same feedback *before* pushing a bad tag, not only after CI runs and fails. This repository already has a `pipeline/pre-push-gates` script — check whether adding a tag-specific check there makes sense, but do not make this a blocking requirement if it adds meaningfully more scope; the CI-side guard (step 2) is the actual requirement from the gap analysis.

### Verification standard
- **Test this against a real tag push in a disposable/test scenario** — e.g., create a throwaway branch not merged into `main`, tag a commit on it, push that tag to a fork or a scratch remote (never to the real `yacketrj/dune-ops-observability-addon` repository) and confirm the workflow correctly refuses to release. Do not merge this change having only reasoned about it — the exact failure mode this is meant to prevent (S-3) happened because a similar-looking but subtly different mechanism was apparently never actually exercised end-to-end.
- Confirm a real, legitimate tag pushed from a commit that *is* on `main` still releases successfully — this guard must not block correct releases.

---

## 4. Hard constraints (apply to all three items)

- **Do not touch or attempt to "fix" the existing fabricated `v0.5.0`–`v1.0.0` releases as part of this work.** That is S-3's own, separate, still-open resolution (documented with two options in `docs/GAP-ANALYSIS-RESOLUTION-2026-07-23.md` §2.3), reserved for the maintainer's decision on a public-facing artifact. This prompt is entirely about *preventing a repeat going forward* — it does not require, and must not attempt, cleaning up the past.
- **Do not add a new runtime dependency.** All three items are implementable in plain Node/bash, consistent with this repository's zero-runtime-dependency design (`package.json`'s own description).
- **Do not weaken any existing check to make these new ones pass.** If implementing the version-consistency check reveals a real, current drift (it shouldn't, per the verification above, but confirm), fix the drift — do not loosen the new check's tolerance to accommodate it.
- **These are three related but independently shippable pieces of work.** You do not need to land all three in one PR — but item 2 depends on item 3's ancestor-check logic existing first (or being built as shared code alongside it), so sequence your work accordingly if splitting into multiple PRs.

## 5. Verification standard (overall)

- `npm test` and `node scripts/validate.js` must pass throughout.
- Every new check must be demonstrated to actually catch the failure mode it's designed for — via a deliberate, reverted test case, not just code review of the logic. This is the same standard every fix in Phases 0-3 of this project was held to (see `docs/GAP-ANALYSIS-RESOLUTION-2026-07-23.md`'s verification sections for the pattern to follow).
- `pre-commit run --all-files` must pass before opening any PR.

## 6. Deliverable

One or more draft PRs in `yacketrj/dune-ops-observability-addon` (your choice on splitting per item, given the item-2/item-3 dependency noted above). Each PR description must state which item(s) it covers and include the deliberate-failure verification evidence described above — a screenshot or pasted terminal output showing the check actually firing on a bad input, not just passing on the current, already-correct state.
