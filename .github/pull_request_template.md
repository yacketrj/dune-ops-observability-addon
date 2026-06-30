## Summary

- 

## Workstream

- [ ] Addon UI
- [ ] Bridge usage
- [ ] Read-only analytics
- [ ] Documentation
- [ ] Security / validation
- [ ] Release packaging

## Repository boundary

- [ ] This PR contains addon-repository work only.
- [ ] Any required bridge/API/core changes are tracked separately in the WSL/core repository.

## Validation

- [ ] `node scripts/validate.js`
- [ ] GitHub validation workflow passes
- [ ] Secret scan passes
- [ ] SAST passes
- [ ] Filesystem scan passes

## Security review

- [ ] No write permissions added without explicit justification.
- [ ] No credentials or tokens committed.
- [ ] No raw SQL, raw command text, or sensitive identifiers exposed in UI.
