# Cross-repo security tests

**These tests do not test this repository.**

`owasp-security.test.js` and `blueprints-security.test.js` are OWASP Top 10-style regression tests for a *different* repository's server code: `dune-awakening-selfhost-docker`'s `console/api/src/server.js` (the game server admin console / "Core"). This addon (`dune-ops-observability-addon`) has no server-side `src/` directory of its own — it ships as plain HTML/CSS/JS with no bundler or backend, so these tests have nothing to run against here.

## Why they live in this repository

Historical accident — they were originally written and iterated on here, then generalized into a portable tool via `run-security-tests.sh`, which copies them into a target Core checkout and runs them there. They were never relocated into `dune-awakening-selfhost-docker` itself. Relocating them to `tools/cross-repo-security-tests/` (this directory, previously `pipeline/tests/`) makes that scope explicit at a glance instead of looking like this repository's own (broken) test suite — see [`docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md`](../../docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md) finding C-3 for the full history: running these files directly, in place, previously failed 27/27 with `ENOENT`, because they expect to be copied into a checkout that actually has the directory structure they test.

## Usage

```bash
bash tools/cross-repo-security-tests/run-security-tests.sh /path/to/dune-awakening-selfhost-docker
```

This copies both test files into `<path>/console/api/test/`, runs them via `node --test` from that directory, then deletes the copies. It requires a local checkout of `dune-awakening-selfhost-docker` with `console/api/src/` present; it does not clone anything itself.

## Not run by this repository's CI

No workflow in `.github/workflows/` invokes this script — it is a manual developer tool. If continuous coverage of Core's server code from this angle is wanted, the correct home for that automation is a scheduled workflow in `dune-awakening-selfhost-docker` itself (which can run these tests, or better, permanently move them into its own `console/api/test/` directory), not a cron job here that checks out a second repository.
