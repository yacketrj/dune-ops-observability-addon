# Dune Ops Observability v0.1.1

Maintenance release for the first community-index-ready addon package.

## Included since v0.1.0

- Preview mode copy clarified so local browser preview is informational, not warning-styled.
- GitHub Actions runtime updated to current Node action/runtime versions.
- Shift-left security hooks added with pre-commit and CI verification.
- Generated `dist/` packages ignored by Git.
- Data provider abstraction added for `sample` and `bridge` providers.
- Direct localhost/browser API calls explicitly excluded from the MVP provider set.
- Community addon index PR guidance added for `Red-Blink/dune-docker-addons` submissions.

## Permissions

```json
{
  "players": ["read"]
}
```

## Security posture

- Read-only player permission only.
- No write permissions.
- No direct host-local browser API access.
- Production data path remains the Dune Docker Console bridge.
