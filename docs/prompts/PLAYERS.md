# Implementation Prompt — Players tab

You are a senior full-stack engineer fixing a specific, verified design defect in the "Players" tab of `yacketrj/dune-ops-observability-addon`. Read `docs/tabs/PLAYERS.md` in full before writing any code.

## The defect (verified, not in dispute)

The "KPI Capability" panel (`web/index.html`, around lines 209-255) is entirely static HTML — all 7 rows hardcode `<span class="capability-status capability-supported">supported</span>`, and this markup is never touched by any JavaScript (confirmed: zero references to `capability-grid`/`capability-card`/`capability-status` in `web/addon.js`).

**Status update (2026-07-24)**: `ops.inventory.summary` is now real and live (`dune-awakening-selfhost-docker` PRs #111/#114) — that claim is no longer false. **One claim remains permanently false**: "Location & Territory... via ops.location.activity." This is not a temporary data-availability gap — Location is **permanently out of scope** by explicit owner decision (see `docs/tabs/LOCATION.md`): per-player real-time location tracking belongs to the Console's own map UI, not this addon. This row will never become true.

Two CSS classes already exist for exactly the "unavailable" state this panel needs (`capability-partial`, `capability-unavailable` in `web/addon.css` around lines 213-219) but are never applied anywhere — clear evidence this panel was meant to be dynamic and never was.

## Hard constraints

- **Do not fabricate.** The whole point of this fix is to stop the panel from lying about a capability's status. Do not replace one static wrong claim with another static claim that happens to be true today but will drift out of sync again the moment any of the underlying data sources' status changes.
- **Remove the Location & Territory row entirely** — do not make it dynamic. Location is not a capability that will ever become "supported"; keeping a row for it (even a correctly-`unavailable` one) misrepresents it as a pending feature rather than a closed decision. Removing the row is the honest fix here, not marking it unavailable forever.
- **Reuse the exact `SourceResult.status` values already flowing through `refreshAll()`** (`web/addon.js`) for the other panels — do not invent a second, parallel "is this supported" concept. The single source of truth for "is `ops.activity.summary` currently live" is the `SourceResult` envelope `refreshAll()` already receives from `provider.getActivity()` on every refresh cycle; this panel must read from that same data, not make its own separate determination.
- **Do not add a new bridge action or network call just to populate this panel.** All the information needed is already being fetched every refresh cycle for the other panels — this is purely a client-side wiring problem, not a data-availability problem.

## Implementation approach

1. In `web/index.html`, remove the "Location & Territory" `<article class="capability-card">` row entirely.
2. In `web/addon.js`, add DOM element references for each of the remaining 6 `<span class="capability-status">` elements (Population & Activity, Farm Health, Combat & Deaths, Resources, Economy & Trade, Inventory & Crafting) — give each a stable `id` in `web/index.html` first (they currently have none).
3. Write a small helper, e.g. `renderCapabilityRow(el, status)`, that sets the element's class to `capability-supported`/`capability-partial`/`capability-unavailable` and its text to a matching label, based on the corresponding `SourceResult.status` (`"live"`/`"preview"` → supported; `"unavailable"` → unavailable; if you want a middle "partial" state, define precisely what would trigger it — do not add a partial state you can't define a real trigger condition for).
4. Call this helper from within `refreshAll()` (`web/addon.js`), once per remaining capability row, using the same `SourceResult` values `refreshAll()` already has in scope (`activity`, `combat`, `resources`, `economy`, `inventory`). Decide explicitly whether `soc`/`prometheus` should get new rows here too (they currently have none, despite being real domains) — state your decision and reasoning in your PR description either way; adding them is optional polish, not required for this fix.
5. Add a jsdom-based behavioral test to `test/addon-rendering.test.js` (following the exact pattern already established there) asserting: when a mocked provider returns `unavailable` for `getInventory`, the Inventory capability row shows `capability-unavailable`, not `capability-supported`; when it returns `live`, the row shows `capability-supported`. Also assert the Location row no longer exists in the DOM at all. This is the regression test that would have caught the original defect before it shipped, and must exist before this PR is considered done.

## Verification standard

- `npm test` must pass, including your new test(s).
- `node scripts/validate.js` must pass.
- Manually verify in a browser (or via the jsdom test) that toggling a mocked source between `live` and `unavailable` visibly changes the corresponding capability row on refresh — do not rely on reading the code and assuming it works.
- `pre-commit run --all-files` must pass before opening a PR.

## Deliverable

A single PR in `yacketrj/dune-ops-observability-addon`. No cross-repo work needed — every piece of data this fix needs already exists in this repository's own `refreshAll()` function.
