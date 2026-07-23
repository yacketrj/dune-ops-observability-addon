# Implementation Prompt — SOC tab (SOC Operations Center + Metrics Health / Prometheus)

You are a senior full-stack engineer implementing real backing data for the "SOC" tab of `yacketrj/dune-ops-observability-addon`. Read `docs/tabs/SOC.md` in full before writing any code. **This tab has two genuinely different sub-problems with two different implementation shapes — treat them as two separate, independently-schedulable pieces of work, not one task.**

## Sub-problem 1: `ops.soc.summary` (bridge request/error counts)

**What's real**: every addon-bridge call is already logged to an append-only JSONL audit file (`config.auditLog`, `dune-awakening-selfhost-docker/console/api/src/config.js`, resolving to `runtime/generated/web-admin-audit.jsonl`) via `audit(config, req, "addons.bridge", {id, action, permission, ok: true|false, ...})` calls already present in `server.js`. No aggregate query exists — this requires reading and parsing a log file, not writing SQL.

**Hard constraint — do not ship the naive approach as final**: `docs/tabs/SOC.md` §3's sketch does a full-file line-by-line parse on every request, which will not scale on a busy server with a large audit log. Before shipping, design (and justify your choice in the PR description) one of:
- An in-memory rolling counter, updated at `audit()`-call time whenever `action === "addons.bridge"`, reset/decayed on a rolling window — this avoids re-reading the file at all for the common case.
- A bounded-read approach (e.g., only read the last N KB of the file, or use an OS-level `tail`-equivalent) if you determine the file is expected to grow large and a full in-memory counter isn't feasible for some reason you must state explicitly.

Do not ship the full-file-parse-per-request version as your final implementation — it is explicitly flagged in the source doc as illustrative only.

**Implementation**: add your chosen approach to `dune-awakening-selfhost-docker`, expose it via a new `addonOpsSocSummary(...)` function (signature depends on your chosen approach — it may not need `db` at all, since this is file-based, not database-based; do not force a `db` parameter into the signature if your implementation doesn't need it), wire `opsSocProvider(config, db)` in `opsProvider.js` to call it, following the same `{ok: true, result}` response shape and `requireDiscordBotToken` reuse as every other live provider.

## Sub-problem 2: `ops.health.prometheus` (Prometheus/cAdvisor stack health)

**What's real**: a complete, deployable Prometheus + cAdvisor + node-exporter + postgres-exporter stack already exists (`docker-compose.metrics.yml` in `dune-awakening-selfhost-docker`), bound to `127.0.0.1:9090`, but is **deliberately opt-in** (`dune metrics start`) — it will not be running on every install. `runtime/scripts/metrics-stack.sh` already makes and successfully parses the exact HTTP calls needed (`/-/healthy`, `/api/v1/targets`, `/api/v1/query`).

**Mandatory precondition handling — this is the part most likely to be gotten wrong**: you must check whether Prometheus is actually reachable (a real `fetch`/HTTP call with a short timeout to `/-/healthy`) before attempting anything else, and if it is not reachable, return a **distinct** `unavailable` reason — something like `"metrics_stack_not_running"` — that is different from `"not_implemented"`. These are two different, both-real, both-honest states: "this feature doesn't exist yet" vs. "this feature exists but the operator hasn't turned it on." Conflating them (e.g., always returning `"not_implemented"` regardless of which is actually true) would be a real regression in honesty, not just a missed nicety — an operator who *has* run `dune metrics start` and still sees "not implemented" would be misled about their own system's state.

**Implementation**:
1. Write `addonOpsPrometheusHealth(promBaseUrl = "http://127.0.0.1:9090")` (or equivalent) in `dune-awakening-selfhost-docker`, using `docs/tabs/SOC.md` §4's sketch as a starting point.
2. Write the real PromQL queries for `avgCpuPercent`/`avgMemoryMb`/`totalRestarts`, informed by the exact metric names already defined in `runtime/metrics/rules/containers.yml` (`container_memory_working_set_bytes`, `container_spec_memory_limit_bytes`, `container_last_seen`, etc.) and `runtime/metrics/rules/host.yml` — verify these produce sane numbers against a real, running `dune metrics start`'d stack before considering this done; do not assume a PromQL expression is correct just because it parses.
3. Set a short, explicit timeout on every HTTP call to Prometheus (2-3 seconds, matching `metrics-stack.sh`'s own `--max-time` values) — a slow/unreachable Prometheus must not hang the entire OPS dashboard refresh cycle for every other tab.
4. Wire `opsPrometheusProvider(config, db)` accordingly.

## Hard constraints (both sub-problems)

- **No changes needed in `yacketrj/dune-ops-observability-addon` itself** — `renderSoc()`/`renderPrometheus()` already correctly consume the `SourceResult` envelope. All work here is in `dune-awakening-selfhost-docker`.
- **Do not fabricate any field if a real value can't be determined** — e.g., if `/api/v1/query` returns no data for a metric, that field should be `null`/absent, not a guessed number.
- **These are two independent pieces of work** — do not block one on the other; they can ship as two separate PRs if that's more convenient, or one PR covering both if you prefer, but do not create an artificial dependency between them.

## Verification standard

- For sub-problem 1: verify your chosen counting approach actually produces correct counts against a real or synthetic audit log with a mix of `ok: true`/`ok: false` entries across and outside your chosen time window.
- For sub-problem 2: verify against a real, running `dune metrics start`'d environment if one is reachable in your environment — this cannot be meaningfully verified with mocked data alone, since the entire point is confirming the real HTTP/PromQL integration works. If you cannot reach a live metrics stack, state this limitation explicitly in your PR description and describe exactly what was verified (e.g., "verified against `docker-compose.metrics.yml`'s real metric names and `metrics-stack.sh`'s real API shapes, but not against a live running instance") rather than implying full verification occurred.
- Run `dune-awakening-selfhost-docker`'s own test suite in full.

## Deliverable

One or two draft PRs in `dune-awakening-selfhost-docker` (your choice on splitting). No changes needed in `yacketrj/dune-ops-observability-addon` itself.
