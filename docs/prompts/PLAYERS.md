# Implementation Prompt — Players tab

You are a senior full-stack engineer fixing a specific, verified design defect in the "Players" tab of `yacketrj/dune-ops-observability-addon`. Read `docs/tabs/PLAYERS.md` in full before writing any code.

## The defect (verified, not in dispute)

The "KPI Capability" panel (`web/index.html`, around lines 209-255) is entirely static HTML — all 7 rows hardcode `<span class="capability-status capability-supported">supported</span>`, and this markup is never touched by any JavaScript (confirmed: zero references to `capability-grid`/`capability-card`/`capability-status` in `web/addon.js`). Two of the seven claims are currently false: "Inventory & Crafting... via ops.inventory.summary" and "Location & Territory... via ops.location.activity" are both claimed `supported` while both are genuinely `unavailable` today (see `docs/tabs/INVENTORY.md`, `docs/tabs/LOCATION.md`).

Two CSS classes already exist for exactly the states this panel is missing (`capability-partial`, `capability-unavailable` in `web/addon.css` around lines 213-219) but are never applied anywhere — clear evidence this panel was meant to be dynamic and never was.

## Hard constraints

- **Do not fabricate.** The whole point of this fix is to stop the panel from lying about a capability's status. Do not replace one static wrong claim with another static claim that happens to be true today but will drift out of sync again the moment any of the 9 underlying data sources' status changes.
- **Reuse the exact `SourceResult.status` values already flowing through `refreshAll()`** (`web/addon.js`) for the other 9 panels — do not invent a second, parallel "is this supported" concept. The single source of truth for "is `ops.activity.summary` currently live" is the `SourceResult` envelope `refreshAll()` already receives from `provider.getActivity()` on every refresh cycle; this panel must read from that same data, not make its own separate determination.
- **Do not add a new bridge action or network call just to populate this panel.** All the information needed (which of the 9 sources is currently live/preview/unavailable) is already being fetched every refresh cycle for the other 9 panels — this is purely a client-side wiring problem, not a data-availability problem.

## Implementation approach

1. In `web/addon.js`, add DOM element references for each of the 7 (see step 3 below for whether it should be 7 or 9) `<span class="capability-status">` elements — give each a stable `id` in `web/index.html` first (they currently have none).
2. Write a small helper, e.g. `renderCapabilityRow(el, status)`, that sets the element's class to `capability-supported`/`capability-partial`/`capability-unavailable` and its text to a matching label, based on the corresponding `SourceResult.status` (`"live"`/`"preview"` → supported; `"unavailable"` → unavailable; if you want a middle "partial" state, define precisely what would trigger it — e.g., a source that returns real data but with several sub-fields `null` due to per-install schema gaps — do not add a partial state you can't define a real trigger condition for).
3. Call this helper from within `refreshAll()` (`web/addon.js`), once per capability row, using the same 9 `SourceResult` values `refreshAll()` already has in scope (`activity`, `combat`, `resources`, `economy`, `inventory`, `location`, plus — decide explicitly — whether `soc`/`prometheus` should get rows here too, since the panel currently only has 7 rows for 9 real domains; state your decision and reasoning in your PR description either way).
4. Add a jsdom-based behavioral test to `test/addon-rendering.test.js` (following the exact pattern already established there) asserting: when a mocked provider returns `unavailable` for `getInventory`, the Inventory capability row shows `capability-unavailable`, not `capability-supported`; when it returns `live`, the row shows `capability-supported`. This is the regression test that would have caught this defect before it shipped, and must exist before this PR is considered done.

## Verification standard

- `npm test` must pass, including your new test(s).
- `node scripts/validate.js` must pass.
- Manually verify in a browser (or via the jsdom test) that toggling a mocked source between `live` and `unavailable` visibly changes the corresponding capability row on refresh — do not rely on reading the code and assuming it works.
- `pre-commit run --all-files` must pass before opening a PR.

## Deliverable

A single PR in `yacketrj/dune-ops-observability-addon`. No cross-repo work needed — every piece of data this fix needs already exists in this repository's own `refreshAll()` function.
