# Implementation Prompt — Location tab

**Status (decided 2026-07-24): do not implement.** This tab is permanently out of scope for this addon — see `docs/tabs/LOCATION.md` for the full reasoning.

## If you were sent here to "finish" the Location tab

Stop — there is no implementation task here. The maintainer decided per-player real-time location tracking does not belong in this addon; it already belongs to, and is already handled by, the Console's own map UI. This addon's scope is aggregate operational metrics (AAA-style NOC/SOC KPIs), not per-player tracking, and that applies to both of the options an earlier draft of this prompt presented (aggregate marker counts, or full per-player integration) — neither is being built.

## What "done" looks like for this tab

`renderLocation()` (`web/addon.js`) already correctly renders a permanent "Not available" state via the `SourceResult` contract, because `dune-awakening-selfhost-docker`'s `opsLocationProvider` returns a permanent `{status: "planned"}` placeholder. This is the correct, final, intended state — not a bug, not a gap, not something to fix.

## If you're asked to remove the tab entirely instead

That's a legitimate, separate, small UI cleanup (removing the tab/nav entry and its dead HTML) rather than an implementation task — treat it as its own explicit, small request if asked, not as an extension of this prompt.
