# Privacy Guard — v0.5.0

## Approved Output Style
Release v0.5.0 output must remain aggregate-only.

Allowed response categories:
- Player state counts
- Aggregate operation metrics

## Response Shape Guard
Responses must use only approved aggregate fields.
All bridge actions return count-based or metric-based aggregate shapes.

## Fallback Guard
When an expected source is unavailable (missing table/column),
responses use zero-count aggregate fallback shapes.

## Review Requirement
Any expansion beyond the v0.5.0 scope requires design review.
