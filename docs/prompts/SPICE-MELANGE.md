# Implementation Prompt — Spice Melange (Resources) tab

Read `docs/tabs/SPICE-MELANGE.md` first. **This tab has no functional or data defects.** The only real gap is test coverage for its unusually complex client-side rendering logic.

## The gap

`renderResources()`'s nested `renderSpiceGroups()` function (`web/addon.js`, currently inside the `renderResources` function body) does imperative DOM construction — grouping `spiceFieldsBySize` rows by map, sorting each map's size tiers (Small → Medium → Large), and building summary cards plus a table per map. This is the only panel in the addon built this way (every other panel uses the declarative `appendRow()` helper), and none of the current 26 tests (`test/addon.test.js` + `test/addon-rendering.test.js`) exercise this grouping/sorting logic directly.

## Task

1. Read `renderResources()`/`renderSpiceGroups()` in full in `web/addon.js` to understand the exact current grouping/sorting behavior before writing a test against it — do not guess at the expected output shape.
2. Add a new jsdom-based behavioral test to `test/addon-rendering.test.js`, following the exact pattern already established there (load the real `web/index.html` + scripts into a jsdom window, install a mocked provider, trigger a refresh, assert on rendered DOM), covering:
   - A multi-map, multi-size-tier `SourceResult` (e.g., two maps, each with Small/Medium/Large rows in a deliberately shuffled input order) produces the correct number of map groups and correctly Small→Medium→Large-sorted rows per map.
   - Per-map summary totals (Active/Remaining cards) reflect the correct aggregated values for that map only, not a cross-map total.
   - An `unavailable` `SourceResult` correctly clears any previously-rendered spice groups (verify `#res-spice-groups` is emptied, not just that new data fails to render on top of stale data from a previous successful refresh).
3. Do not change `renderResources()`'s actual logic unless your new test reveals a real bug while writing it — if it does, fix the bug and explain what you found in your PR description; if it doesn't, this should be a test-only PR.

## Hard constraints

- **Do not refactor `renderSpiceGroups()`'s imperative DOM-construction style to match the other panels' declarative style** as part of this task unless explicitly asked — that's a larger, separate refactor with its own risk profile, out of scope for a test-coverage fix.

## Verification standard

- `npm test` must pass, including your new test(s), and the new test(s) must actually fail if you temporarily introduce a deliberate bug (e.g., break the sort comparator) — confirm this before considering the test real coverage, not just a test that happens to pass.
- `pre-commit run --all-files` must pass.

## Deliverable

A single, test-only PR in `yacketrj/dune-ops-observability-addon`.
