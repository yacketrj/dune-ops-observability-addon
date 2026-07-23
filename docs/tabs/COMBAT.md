# Tab Architecture — Combat

**Data-tab attribute**: `combat`
**HTML**: `web/index.html:365-416`
**Render entry point**: `refreshAll()` → `renderCombat(result)` (`web/addon.js:565`)
**Bridge action**: `ops.combat.deaths` — **live**, same dual-path availability as Activity (see `docs/tabs/ACTIVITY.md` §1.1).
**Core query**: `duneDb.addonOpsCombatDeaths(db)` (`duneDb.js:4522-4549`)

---

## 1. Current implementation (verified) — no rendering defects; one real Core-side data limitation

### 1.1 Rendering, verified correct

`renderCombat()` (`addon.js:565-591`) follows the same correct `SourceResult` pattern as every other fixed panel: checks `.status === "unavailable"` first, renders "Not available" state via `renderUnavailablePanel()`, only reads `.data` in the live branch. No defects.

### 1.2 Real Core-side data limitation — not an addon defect, but worth documenting here since it affects what this tab can ever show

`addonOpsCombatDeaths`'s SQL (`duneDb.js:4526-4531`) is:

```sql
select count(*)::int as total_deaths,
       count(*) filter (where death_cause = 'Dead')::int as unknown_deaths,
       count(*) filter (where death_cause = 'DeadByCoriolis')::int as coriolis_deaths,
       count(*) filter (where death_cause = 'DeadBySandworm')::int as sandworm_deaths
from dune.player_death_log
```

And the function's return value hardcodes:
```js
return {
  totalDeaths: Number(r.total_deaths || 0),
  pvpDeaths: 0,        // <-- always zero, unconditionally
  pveDeaths: Number(r.total_deaths || 0),   // <-- always equals totalDeaths
  ...
};
```

**This means the Combat tab's "PvP Deaths" card will always show `0` today, for every install, regardless of how many actual player-vs-player kills occurred.** This is real data (not fabricated — `pvpDeaths: 0` genuinely is what the query computes, and the addon correctly renders whatever Core sends), but it's a real limitation worth surfacing: the underlying `dune.player_death_log` table's `death_cause` column doesn't currently distinguish PvP from PvE kills (only `Dead`/`DeadByCoriolis`/`DeadBySandworm` — environmental/creature causes), so there's no query that could produce a non-zero `pvpDeaths` without a different data source.

**A real, better PvP/PvE classification source may exist** — flagged, not confirmed, in this repository's own gap analysis (F-2's resolution note references "Core does have a real, per-partition-configurable PvP/PvE combat-state source (`UserGame.ini` `PvpPveSettings` section, merged via `usersettings.py`)... PR #103/#104"). This review did not re-verify that claim directly (it's about game-mode configuration, not death-log classification specifically, and may not actually help classify individual deaths after the fact) — treat it as a lead to investigate, not a confirmed fix, before promising a real `pvpDeaths` count.

### 1.3 Copy accuracy

Section copy (index.html:376) is accurate as written: *"PvP/PvE death breakdowns: cause, map distribution, and hostile NPC tracking."* No stale-status wording here (unlike Activity's tab), but it doesn't disclose the §1.2 limitation — a reader has no way to know "PvP Deaths: 0" means "not yet classifiable" rather than "genuinely zero PvP activity this period." This is the same category of ambiguity F-1 was designed to eliminate (a real `0` that looks identical to an unmeasurable `0`), just one level deeper than what the `SourceResult` envelope can address — the envelope correctly says "this data is live," and it's telling the truth; the *query* itself just can't currently distinguish two different real-world states that both produce the same number.

---

## 2. Data flow (current, verified)

Same shape as Activity (see `docs/tabs/ACTIVITY.md` §2), substituting `ops.combat.deaths` / `addonOpsCombatDeaths` / `renderCombat`.

---

## 3. Recommended design changes

1. **Investigate whether a real PvP/PvE death classification source exists** (§1.2's flagged lead) before doing anything else here — if one exists, wiring it is real, valuable work; if not, that's an honest, useful thing to confirm and document so nobody re-investigates this later.
2. If no real classification source exists, consider whether `pvpDeaths`/`pveDeaths` should be split into a single "Deaths" card plus a footnote/tooltip stating "PvP/PvE classification not currently available; all deaths are counted together" — this would be more honest than implying a working PvP/PvE split exists when it doesn't. This is a UI-copy decision, not a data-fabrication one (no proposal here suggests inventing a number) — flagging as a design choice for the maintainer, not prescribing one answer.
