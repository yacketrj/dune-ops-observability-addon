# Implementation Prompt — Economy tab

Read `docs/tabs/ECONOMY.md` first. **This tab has no defects and requires no changes.**

## Why this prompt exists anyway

Per this review's scope, every tab gets a companion prompt — for Economy, the correct action is explicit confirmation, not a fabricated task. `renderEconomy()`, `web/data-providers.js`'s `bridge.getEconomy()`, and `dune-awakening-selfhost-docker`'s `duneDb.addonOpsEconomySummary(db)` are all already correct: real, live, aggregate-only (no player-level identifiers in any returned row — verified directly against the SQL), and correctly wired through the `SourceResult` envelope.

## Task

If you're asked to "implement" this tab, your first action should be to **re-verify this claim yourself** before doing anything else — read `web/addon.js`'s `renderEconomy()`, `web/data-providers.js`'s `getEconomy()`, and `dune-awakening-selfhost-docker`'s `duneDb.addonOpsEconomySummary(db)` directly, and confirm:

1. The `SourceResult` contract is followed correctly (status checked before data is read).
2. No player-level identifier appears in any field the query returns.
3. The rendered UI matches what the section copy claims.

If your own re-verification confirms this doc's claim (no defects), **do not make any code changes** — report your confirmation and stop. Making a speculative "improvement" to a tab that has no identified problem, just to have produced a diff, risks introducing a regression into the one part of this codebase that's already a reference implementation for everything else.

If your own re-verification finds something this review missed, document exactly what you found (with file:line citations) and treat it as a new, real finding — fix it following the same `SourceResult` conventions used everywhere else in this addon, and add a regression test to `test/addon-rendering.test.js` covering it.

## Verification standard

- If you make any change: `npm test` must pass including a new/updated test, and `pre-commit run --all-files` must pass.
- If you make no change: state clearly in your final report what you checked and that it confirmed no defect, so this doesn't get re-investigated from scratch next time.

## Deliverable

Either: (a) a short confirmation report, no code changes, or (b) a small PR fixing a genuinely new finding, with the same rigor as every other prompt in this set.
