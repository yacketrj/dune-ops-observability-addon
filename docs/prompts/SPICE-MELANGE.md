# Implementation Prompt — Spice Melange (Resources) tab

**Status: implemented.** Read `docs/tabs/SPICE-MELANGE.md` for the current, real architecture.

This tab was reworked from a flat map-grouped-totals layout into a two-section (Deep Desert / Hagga Basin) per-instance layout, each instance annotated with its real, config-resolved PvP/PvE combat state (`services/mapCombatState.js`, Core PR #103/#104). The work included:

- Core (`dune-awakening-selfhost-docker`): rewrote `addonOpsResourcesSummary(db, config)` to return the new per-section/per-instance shape; added `test/addonOpsResourcesSummary.test.js` (15 tests, real resolver sandbox); updated `opsProvider.test.js` and `bridgeIntegration.test.js` to the new shape.
- Addon (this repo): rewrote `web/index.html`'s Spice Melange markup for the two-section layout with loading/empty/error states; rewrote `renderResources()`/added `renderMapSection()`/`renderInstanceCard()` in `web/addon.js`; added natural sort (Deep Desert) vs. alphabetical sort (Hagga Basin), locale number formatting, PvP/PvE/CONFLICT/UNKNOWN badges, and zero-preservation for size-tier rows; added 11 new jsdom behavioral tests to `test/addon-rendering.test.js`.

No further action is needed on this tab unless a new gap is found. If one is, follow the same pattern as the other `docs/prompts/*.md` files: read `docs/tabs/SPICE-MELANGE.md` first, do not guess at the real data shape, and verify any change against the real, live-verified per-size remaining-spice data-model limitation documented there (per-size remaining spice has no real source and must stay a dash, never estimated or apportioned).
