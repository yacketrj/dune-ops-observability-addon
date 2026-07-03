# Release 0.3 Privacy Guard

Status: Gate 1 design artifact
Release: `0.3-expanded-db-bridge`

## Approved Output Style

Release 0.3 output must remain aggregate-only.

Allowed response categories:

- player state counts;
- farm/server state counts;
- combined health summary counts.

## Response Shape Guard

Responses must use only the approved aggregate fields documented in `release-plan.md`.

Any later implementation PR must include tests proving the response shape stays aggregate-only.

## Fallback Guard

When an expected source is unavailable, responses should use zero-count aggregate fallback shapes.

Fallback responses must preserve the same top-level shape as normal responses.

## Review Requirement

Any expansion beyond the Gate 1 response schemas requires a new design review before implementation.
