# Implementation Prompt — Activity tab

Read `docs/tabs/ACTIVITY.md` first. **This tab has no functional defects** — `renderActivity()` and the underlying `duneDb.addonOpsActivitySummary()` query are both already correct, live, and well-tested. This is a small, low-risk documentation-accuracy fix, not a feature implementation.

## The one real issue

`web/index.html`'s Activity tab section copy (around line 303) reads: *"Fine-grained activity windows, guild/faction/map distribution require ops.activity.summary (planned)."* This is stale — `ops.activity.summary` has been live since `dune-awakening-selfhost-docker` PR #109 (2026-07-22), and this addon's own `renderActivity()` already correctly consumes real guild/faction/map data from it today.

## Task

1. Rewrite that sentence to accurately describe current reality — this feature is live, not planned. Confirm by reading `web/data-providers.js`'s `bridge.getActivity()` and `web/addon.js`'s `renderActivity()` yourself before writing the new copy, so what you write matches what the code actually does today, not what this prompt claims (verify, don't just trust this document).
2. While you're in this file, check whether any other tab's section copy has the same "(planned)" staleness for an action that's actually live — `docs/DESIGN-REVIEW-2026-07-23.md` §4 flags this as a broader pattern (no single source of truth for per-tab status text) worth a systematic pass, not just a one-off fix here. If you find other stale instances, fix them in the same PR; if you don't have time/scope for a full sweep, fix this one and note the broader issue in your PR description for a follow-up.

## Hard constraints

- Do not change any rendering logic, query logic, or add any new feature — this tab does not need one. If you find yourself editing `web/addon.js` or `duneDb.js`, stop; that's out of scope for this prompt.

## Verification standard

- `npm test` must still pass (no test changes expected, since no logic changed).
- `pre-commit run --all-files` must pass.

## Deliverable

A single, small PR in `yacketrj/dune-ops-observability-addon` touching only `web/index.html` (and possibly other tabs' HTML, if you did the broader sweep from step 2).
