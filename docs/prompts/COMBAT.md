# Implementation Prompt — Combat tab

Read `docs/tabs/COMBAT.md` first. **The addon-side rendering is already correct.** The issue here is a real, upstream Core-side data limitation, plus a decision about how honestly to present it — not an addon bug to fix by yourself.

## The situation (verified, not in dispute)

`dune-awakening-selfhost-docker`'s `duneDb.addonOpsCombatDeaths(db)` (`console/api/src/duneDb.js`, currently around line 4522) hardcodes `pvpDeaths: 0` unconditionally and folds every death into `pveDeaths`, because the underlying `dune.player_death_log.death_cause` column only distinguishes environmental/creature causes (`Dead`, `DeadByCoriolis`, `DeadBySandworm`), not PvP vs. PvE. This means the Combat tab's "PvP Deaths" card will show `0` for every install today, and this addon is correctly, honestly rendering that real (if unhelpfully-shaped) `0` — this is not a false-zero rendering bug; it's a real number that happens to always be zero because the source data can't currently say otherwise.

`docs/tabs/COMBAT.md` §1.2 flags an unverified lead: an earlier session's notes (in this addon's own gap-analysis history) mention a "real, per-partition-configurable PvP/PvE combat-state source (`UserGame.ini` `PvpPveSettings` section, merged via `usersettings.py`)" that may or may not actually help classify individual deaths after the fact — this was never confirmed to be usable for this specific purpose (`PvpPveSettings` sounds like it configures game *mode* per partition, not a per-death classification field).

## Task — investigate first, then decide, do not guess

1. **In `dune-awakening-selfhost-docker`**, investigate directly whether any real, per-death or per-partition-at-time-of-death data exists that could classify `dune.player_death_log` rows as PvP vs. PvE after the fact. Check the actual `player_death_log` schema columns (not just `death_cause`), check whether `usersettings.py`'s `PvpPveSettings` merge writes anything queryable per-partition that could be joined against a death's `map`/`partition_id` at the time it occurred, and check for any other table this review's keyword-based search may have missed (search for `pvp`, `pve`, `combat_state`, `partition_mode` — case-insensitively, across `console/api/src/`).
2. **If a real source is found**: wire it into `addonOpsCombatDeaths`'s query, following the exact schema-adaptive pattern (`tableExists`/`columnsFor` checks) every other `addonOps*` function already uses. Do not guess at column names — verify them directly against a real database if one is reachable in your environment, the same verification standard every other Phase-1-style fix in this project has required.
3. **If no real source is found** (a legitimate, real possible outcome — this is not a foregone conclusion that one exists): do not invent a heuristic (e.g., guessing PvP based on map name, or player proximity at time of death, or any other inferred signal) to produce a non-zero `pvpDeaths` value. That would be exactly the fabrication anti-pattern this whole project has been eliminating elsewhere. Instead, in this addon repository, consider changing the Combat tab's presentation to be honest about the limitation — e.g., a single "Deaths" card instead of split PvP/PvE cards, with a footnote explaining classification isn't currently available — but treat this as a UI/copy decision requiring your own judgment about what's clearest for an operator, not a prescribed fix; presenting several options to the maintainer rather than unilaterally redesigning the panel is also acceptable if you're unsure.

## Hard constraints

- **This is a two-repository task with an investigation gate.** Do not skip step 1 and jump straight to a UI change — confirming whether real data exists changes what the right fix is entirely.
- **Do not weaken or remove `renderCombat()`'s already-correct `SourceResult` handling** while making any change here.

## Verification standard

- If you change Core's query, verify against a real or realistic test database, following the same standard already established for Phase 1 (`dune-awakening-selfhost-docker`'s own `console/api/test/` suite, `node --test`).
- If you change this addon's UI, run `npm test` and add/update a behavioral test in `test/addon-rendering.test.js` reflecting the new presentation.
- `pre-commit run --all-files` must pass in whichever repository(ies) you touch.

## Deliverable

Start with a short investigation report (can be the first few paragraphs of your PR description, or a standalone note) stating clearly whether a real classification source was found. Only proceed to code changes once that's established. If both a Core-side fix and an addon-side UI change are warranted, open them as two separate, independently-reviewable PRs in their respective repositories.
