# discover-db-telemetry Tool Spec

## Purpose

`discover-db-telemetry` is an internal read-only telemetry discovery tool for Dune Ops Observability.

The tool inventories runtime database structure, classifies telemetry candidates, flags unsafe fields, and proposes safe aggregate query candidates.

This tool does not mutate runtime state and must not emit raw player rows, raw identifiers, raw coordinates, raw logs, tokens, passwords, secrets, or serialized player payloads.

## Release

Release: `0.2-telemetry-discovery`

Target: internal tooling first.

No upstream PR should be created from this tool until generated output has been reviewed and a clear upstream-safe use case exists.

## Runtime Assumptions

The tool runs from the operator environment with access to the local E2E/runtime working tree.

Expected runtime roots:

```text
~/dune-work/e2e-ops-health
~/dune-work/core-pr-addon-ops-health-bridge
~/dune-work/ops-observability
