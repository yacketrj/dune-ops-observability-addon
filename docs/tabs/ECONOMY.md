# Tab Architecture — Economy

**Data-tab attribute**: `economy`
**HTML**: `web/index.html:436-485`
**Render entry point**: `refreshAll()` → `renderEconomy(result)` (`web/addon.js:702`)
**Bridge action**: `ops.economy.summary` — **live**, same dual-path availability as Activity.
**Core query**: `duneDb.addonOpsEconomySummary(db)` (`duneDb.js:4555+`)

---

## 1. Current implementation (verified) — no defects found

### 1.1 Rendering, verified correct

`renderEconomy()` (`addon.js:702-740`) correctly follows the `SourceResult` contract. No defects.

### 1.2 Real query behavior, verified (re-confirmed from an earlier session, re-checked directly in this review)

`addonOpsEconomySummary` is genuinely aggregate-only: every returned row is a `count`/`sum`/`avg`/`min`/`max` grouped by `currency_id` or `template_id` (`dune.player_virtual_currency_balances`, `dune.dune_exchange_orders`, `dune.dune_exchange_fulfilled_orders`, `dune.tax_invoice`) — **no `player_controller_id`, player name, or any other player-level identifier appears in any returned row**. This is the correct privacy posture for this category of data and should be preserved as the reference pattern for any future economy-adjacent query.

Each of the three data domains (currency, exchange orders, tax) is wrapped in its own `try {} catch {}` (`duneDb.js`, verified in an earlier session), degrading independently to zero/empty on a per-install schema variance.

### 1.3 Copy accuracy

Section copy (index.html:447) is accurate: *"Currency supply, exchange order volume, and fulfilled trade analysis."* No stale-status wording.

---

## 2. Data flow (current, verified)

Same shape as Activity (see `docs/tabs/ACTIVITY.md` §2), substituting `ops.economy.summary` / `addonOpsEconomySummary` / `renderEconomy`.

---

## 3. Recommended design changes

None. This tab is fully backed by real, live, correctly-scoped-for-privacy data today, and its implementation is a good reference for future work — no changes recommended.
