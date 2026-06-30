# A4 Capability Panel

Issue: #5

## Goal

Show which read-only reporting categories are currently supportable.

## Implemented

- Adds an A4 capability section to the addon UI.
- Shows supported, partial, and unavailable categories.
- Keeps unsupported categories visible rather than implying that data exists.
- Keeps the addon read-only.

## Out of scope

- Write access.
- New bridge actions.
- New upstream routes.
- Actual chart panels.

## Permissions

No permission change.

```json
{
  "players": ["read"]
}
```
