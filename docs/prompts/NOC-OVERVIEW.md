# Implementation Prompt — NOC Overview tab

You are a senior full-stack engineer fixing a specific, verified design defect in the "NOC Overview" tab of `yacketrj/dune-ops-observability-addon`. Read `docs/tabs/NOC-OVERVIEW.md` in full before writing any code — it contains exact file:line citations and verified evidence for everything below; this prompt tells you how to execute the fix, not what the problem is.

## The defect (verified, not in dispute)

`web/index.html`'s "Service Health Map" panel (around line 102-117) has section copy promising named per-service rows: *"Service dependency status: Postgres, RabbitMQ, Director, Gateway, Survival_1, Overmap, TextRouter."* The actual rendering function, `renderNocService()` (`web/addon.js`, currently around line 788), renders five unrelated addon-bookkeeping rows ("OPS Health Bridge," "Player Aggregate," "Farm Aggregate," "Data Freshness," "Provider Mode") that have nothing to do with those seven named services.

## Hard constraints

- **Do not fabricate or synthesize data.** If you choose Option B below and cannot get real per-service status for all seven named services, do not invent placeholder rows dressed up as real — report exactly what you can determine and mark the rest `unavailable`, following the exact `SourceResult` envelope pattern already used by every other panel in this addon (`{status: "live"|"preview"|"unavailable", data, reason, source}` — see any of `renderActivity`/`renderCombat`/`renderEconomy` in `web/addon.js` for the reference pattern, and `renderUnavailablePanel()`'s helper).
- **Do not silently leave the mismatch unresolved.** Pick Option A or Option B below explicitly and execute it fully — do not ship a change that touches this panel without fixing the actual copy/behavior mismatch.
- **This addon has no runtime dependencies by design** (see `package.json`'s description) except `jsdom`, which is test-only. Do not add a new runtime dependency to fetch container status — use `docker ps` via the exact `runningContainerNames()` pattern already established in `dune-awakening-selfhost-docker/console/api/src/services/publicDirectory.js:401` if you pursue Option B, which requires new work in that other repository, not this one.
- **This addon's own repository has no server-side code.** If Option B requires new backend work, that work happens in `dune-awakening-selfhost-docker` (Core), following the exact Phase-1 pattern already used for the four live `ops.*.summary` actions (`opsProvider.js`, `requireDiscordBotToken` auth, `{ok: true, result}` response shape) — do not invent a new auth mechanism or bridge-action-naming convention.

## Choose one, with an explicit reason recorded in your PR description

### Option A — Fix the copy (fast, ships today, zero new Core work)

Rewrite the section copy at `web/index.html`'s "Service Health Map" panel to accurately describe what `renderNocService()` actually shows (addon-internal read health bookkeeping — bridge connection state, player/farm aggregate population state, data freshness, provider mode), not named infrastructure services. Do not touch `renderNocService()`'s logic. Do not rename the panel's heading ("Service Health Map") if you can write copy that's accurate under that heading; rename it too if you can't.

### Option B — Build the real thing the copy promises (real, buildable, larger scope)

1. In `dune-awakening-selfhost-docker`, verify the actual current Docker Compose service names for all 7 named services (Postgres, RabbitMQ, Director, Gateway, Survival_1, Overmap, TextRouter) against the real `docker-compose.yml` — do not assume the 4-name list already hardcoded in `publicDirectory.js`'s `BATTLEGROUP_CORE_CONTAINERS` is complete or correctly named; it currently only names `dune-director`, `dune-server-gateway`, `dune-server-survival-1`, `dune-server-overmap` (4 of the 7).
2. Expose real per-container up/down status (via `docker ps` or `docker inspect`, following `runningContainerNames()`'s pattern) as a new bridge action, e.g. `ops.service.health`, following the exact same wiring pattern Phase 1 used: a new `opsServiceHealthProvider(config, db)` in `opsProvider.js`, added to `OPS_BRIDGE_ACTIONS`, a new `DISCORD_ADAPTER_ROUTES` entry in `adapter.js`, added to `DISCORD_LIVE_ADAPTER_ROUTES`, wired into `routes.js`'s dispatch — reuse `requireDiscordBotToken`, do not add a new auth mechanism.
3. Back in this addon repository, add `getServiceHealth()` to `data-providers.js` (following the exact `fetchLiveOrUnavailable()` pattern already used by every live action), and rewrite `renderNocService()` to render real per-service status rows instead of the current 5 bookkeeping rows.
4. If Docker isn't reachable, or a named container isn't found running, that service's row must show `unavailable`/a clear "not running" status — never assume a container is up because you didn't get an error, and never omit a named service from the table just because its status is unknown.

## Verification standard

- Run this repository's full test suite (`npm test`) and the manifest validator (`node scripts/validate.js`) before considering any change done.
- If you touch `web/addon.js`, add or update a behavioral test in `test/addon-rendering.test.js` (jsdom-based, following the exact pattern already established there) asserting the panel renders correctly for both a fully-healthy and a partially-unavailable case.
- If you pursue Option B, you cannot fully verify this from the addon repository alone — you need a running Core instance with the new bridge action to confirm the end-to-end flow. Document what you verified vs. what requires a live environment in your PR description.
- Run `pre-commit run --all-files` before opening a PR — do not bypass with `--no-verify`.

## Deliverable

A single PR in `yacketrj/dune-ops-observability-addon` (plus, if Option B, a companion PR in `yacketrj/dune-awakening-selfhost-docker`, opened as its own independently-reviewable draft PR — do not create a merge-order dependency that would leave one repository broken waiting on the other; the addon-side change should degrade gracefully to showing `unavailable` if the Core-side PR hasn't merged yet). State in your PR description which option you chose and why.
