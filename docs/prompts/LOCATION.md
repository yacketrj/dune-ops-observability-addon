# Implementation Prompt — Location tab

You are a senior full-stack engineer implementing real backing data for the "Location" tab of `yacketrj/dune-ops-observability-addon`, currently fully unavailable. Read `docs/tabs/LOCATION.md` in full before writing any code — it contains verified evidence, a privacy analysis, and a query sketch. **This prompt has a mandatory decision gate you cannot skip.**

## What you're building on (verified, not in dispute)

Real, comprehensive, already-used live-map data exists in `dune-awakening-selfhost-docker`: `duneDb.liveMapCapabilities`, `liveMapPartitions`, `liveMapPlayers`, `liveMapVehicles`, `liveMapBases`, `liveMapStorage`, and the composed `liveMapMarkers` (`console/api/src/duneDb.js`, currently starting around line 1948), all used today by the Console's own `/api/map/*` routes (session-auth gated).

## Mandatory decision gate — read before writing any code

Every other real OPS data source this addon uses today (activity, combat, resources, economy) is **aggregate-only** — counts, sums, averages, with zero per-player identifiers in any returned row. This is the addon's established, documented privacy posture (see its own `README.md` security-boundary section).

`liveMapPlayers` and `liveMapBases` break that pattern: they return **individually identifying data** (character names, Funcom IDs, base-owner names) **plus real-time world coordinates**. `liveMapVehicles`/`liveMapStorage` carry real-time coordinates without direct player identity.

**You must not unilaterally decide to wire the full identity-bearing dataset into an `ops:read`-gated addon.** This is a real privacy/permission-scope decision, not a technical one, and `docs/tabs/LOCATION.md` §4 presents two options explicitly for a reason: this review does not resolve which one is correct, and neither should you, alone, in this prompt's execution. Concretely:

- **If you have the ability to ask the maintainer directly, do so before writing code**, presenting both options from `docs/tabs/LOCATION.md` §4 with your own recommendation.
- **If you do not have that ability in your current execution context** (e.g., you are running unattended), default to **Option A (aggregate-only)** below, and state explicitly in your PR description that you defaulted to the lower-risk option specifically because the identity/privacy question requires human sign-off you didn't have access to — do not proceed to Option B without that sign-off under any circumstance.

## Option A — aggregate-only (default; use this unless explicitly told otherwise)

1. In `dune-awakening-selfhost-docker`, write `addonOpsLocationSummary(db)` using only `liveMapCapabilities(db)` and `liveMapPartitions(db)` — both are genuinely aggregate (marker *counts* per map/partition, no identity, no individual coordinates). Use `docs/tabs/LOCATION.md` §5's sketch as a starting point, verified and refined against a real database before shipping.
2. For a real per-map *online player count* (not full player rows), you may call `liveMapPlayers(db, map)` server-side and immediately reduce its rows to a `COUNT(*) GROUP BY map` — discarding every per-player field (name, Funcom ID, coordinates) before it ever leaves the function. This is the same aggregation-from-identity-bearing-source principle `addonOpsActivitySummary` already uses (it counts `online_players` from `player_state` without ever returning an individual player row) — it is not a violation of the aggregate-only constraint as long as no individual row or field ever appears in the function's return value. Do not return `liveMapPlayers`' raw rows under any circumstance in this option.
3. Follow the exact Phase-1 wiring pattern: `opsLocationProvider(config, db)` in `opsProvider.js` calls your new function; reuse `requireDiscordBotToken`; `{ ok: true, result }` response shape.
4. Add tests following the exact conventions Phase 1 established (real-data-shape assertions, honest degradation to zero/empty when tables are missing, and — specific to this option — a test asserting the returned object never contains a `name`, `characterName`, `fls_id`, `funcom_id`, `x`, `y`, or `z` field anywhere in its structure, since accidentally leaking one of those fields would silently break this option's entire privacy rationale).

## Option B — full live-map integration (only with explicit maintainer sign-off)

If and only if you have received explicit sign-off: wire the complete `liveMapMarkers` output through `opsLocationProvider`. Before doing so, also resolve whether this requires a new, narrower permission scope distinct from the aggregate-only `ops:read` used by every other action — do not silently expand what `ops:read` is understood to mean across the rest of this addon without that being an explicit, documented decision alongside the sign-off itself.

## Hard constraints (apply regardless of option)

- **Do not fabricate any field.** `docs/tabs/LOCATION.md` §5's sketch leaves `activeMaps[].players`/`.online` as `null` in its illustrative form — do not ship that as `null` if you can compute it for real via the aggregation approach in Option A step 2; do not invent a plausible-looking number if you can't.
- **This is cross-repo work** for the Core-side query function; no changes are needed in `yacketrj/dune-ops-observability-addon` itself beyond what's already correct in `renderLocation()`.

## Verification standard

- Verify against a real or realistic database if reachable in your environment.
- Run the full test suite in whichever repository you touch.
- For Option A specifically: the privacy-guarantee test (step 4 above) is not optional — it is the acceptance criterion that proves you actually built the aggregate-only version, not a "trust me" comment.

## Deliverable

A single draft PR in `dune-awakening-selfhost-docker`. State explicitly in the PR description which option you implemented and why (including, if applicable, that you defaulted to Option A due to lacking sign-off access). No changes needed in `yacketrj/dune-ops-observability-addon` itself.
