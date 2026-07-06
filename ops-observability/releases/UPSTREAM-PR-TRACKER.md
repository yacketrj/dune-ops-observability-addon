# Upstream PR Tracker

Status of pull requests submitted to upstream repositories. Checked with:
```bash
bash ops-observability/dev-tools/check-upstream-prs.sh
```

## Core (Red-Blink/dune-awakening-selfhost-docker)

| PR | Title | Status | Merged | Upstream Release |
|---|---|---|---|---|
| [#61](https://github.com/Red-Blink/dune-awakening-selfhost-docker/pull/61) | Bridge rate limiter + IP allowlisting + CI workflow | Merged | 2026-07-05 | v1.3.45 |

## Catalog (Red-Blink/dune-docker-addons)

| PR | Title | Status | Merged | Notes |
|---|---|---|---|---|
| [#7](https://github.com/Red-Blink/dune-docker-addons/pull/7) | Dune Ops Observability v0.3.0 SHA + catalog validation | Open | — | Leadership-board-demo version reverted to 1.0.0 |
| [#5](https://github.com/Red-Blink/dune-docker-addons/pull/5) | Update Dune Ops Observability to v0.3.0 | Closed | — | Replaced by #7 — had wrong SHA + wrong leadership-board-demo version |

## Process

1. After submitting an upstream PR, add it to this tracker with status OPEN.
2. Run `bash ops-observability/dev-tools/check-upstream-prs.sh` before staging new PRs.
3. When a PR merges, update its status to MERGED and record the upstream release tag.
4. If upstream cuts a release that includes our changes:
   - Update the tracker with the release tag
   - Update `README.md` compatibility line: "Upstream Dune Docker Console: compatible with `v1.X.Y`"
   - Sync the core fork (`main` → reset to upstream, rebase feature branches)
5. If a PR is closed without merging, record the reason and close it in this tracker.
