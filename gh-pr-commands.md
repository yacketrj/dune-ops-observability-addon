# PR Creation Commands — Ops Observability v0.3.0 → v1.0.0

Execute these in order: **Core first**, then **Addon**, then **Catalog**.
All PRs are currently unsubmitted. Review each branch before creating the PR.

## Security Baseline (all scans passed)

All security scans run against the addon main branch (covers all code):

```
gitleaks: scan completed, no leaks found
semgrep:  no findings
trivy:    no vulns or secrets
```

---

## v0.3.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.3.0 \
  --title "ops: add OPS health bridge and ops:read permission (v0.3.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.3.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.3.0 \
  --title "release v0.3.0 — OPS health dashboard" \
  --label release \
  --label ops \
  --body-file ops-observability/releases/0.3.0-0-3-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.3.0 \
  --title "catalog: add Dune Ops Observability v0.3.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.3.0-0-3-0/prs/catalog-pr.md
```

---
## v0.4.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.4.0 \
  --title "ops: add activity summary bridge action (v0.4.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.4.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.4.0 \
  --title "release v0.4.0 — activity summary panel" \
  --label release \
  --body-file ops-observability/releases/0.4.0-0-4-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.4.0 \
  --title "catalog: update Dune Ops Observability to v0.4.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.4.0-0-4-0/prs/catalog-pr.md
```

---
## v0.5.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.5.0 \
  --title "ops: add combat deaths bridge action (v0.5.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.5.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.5.0 \
  --title "release v0.5.0 — combat deaths panel" \
  --label release \
  --body-file ops-observability/releases/0.5.0-0-5-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.5.0 \
  --title "catalog: update Dune Ops Observability to v0.5.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.5.0-0-5-0/prs/catalog-pr.md
```

---
## v0.6.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.6.0 \
  --title "ops: add resources summary bridge action (v0.6.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.6.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.6.0 \
  --title "release v0.6.0 — resources summary panel" \
  --label release \
  --body-file ops-observability/releases/0.6.0-0-6-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.6.0 \
  --title "catalog: update Dune Ops Observability to v0.6.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.6.0-0-6-0/prs/catalog-pr.md
```

---
## v0.7.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.7.0 \
  --title "ops: add economy summary bridge action (v0.7.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.7.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.7.0 \
  --title "release v0.7.0 — economy summary panel" \
  --label release \
  --body-file ops-observability/releases/0.7.0-0-7-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.7.0 \
  --title "catalog: update Dune Ops Observability to v0.7.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.7.0-0-7-0/prs/catalog-pr.md
```

---
## v0.8.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.8.0 \
  --title "ops: add inventory summary bridge action (v0.8.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.8.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.8.0 \
  --title "release v0.8.0 — inventory summary panel" \
  --label release \
  --body-file ops-observability/releases/0.8.0-0-8-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.8.0 \
  --title "catalog: update Dune Ops Observability to v0.8.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.8.0-0-8-0/prs/catalog-pr.md
```

---
## v0.9.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v0.9.0 \
  --title "ops: add location activity bridge action (v0.9.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --body-file docs/ops-observability/releases/v0.9.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v0.9.0 \
  --title "release v0.9.0 — location activity panel" \
  --label release \
  --body-file ops-observability/releases/0.9.0-0-9-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v0.9.0 \
  --title "catalog: update Dune Ops Observability to v0.9.0" \
  --label enhancement \
  --label addon \
  --body-file ops-observability/releases/0.9.0-0-9-0/prs/catalog-pr.md
```

---
## v1.0.0

### Core
```bash
gh pr create \
  --repo Red-Blink/dune-awakening-selfhost-docker \
  --base main \
  --head yacketrj:release/v1.0.0 \
  --title "ops: add SOC summary bridge action (v1.0.0)" \
  --label enhancement \
  --label ops \
  --label bridge \
  --label major \
  --body-file docs/ops-observability/releases/v1.0.0-pr-body.md
```

### Addon
```bash
gh pr create \
  --repo yacketrj/dune-ops-observability-addon \
  --base main \
  --head release/v1.0.0 \
  --title "release v1.0.0 — SOC summary panel" \
  --label release \
  --label major \
  --body-file ops-observability/releases/1.0.0-1-0-0/prs/addon-pr.md
```

### Catalog
```bash
gh pr create \
  --repo Red-Blink/dune-docker-addons \
  --base main \
  --head yacketrj:release/v1.0.0 \
  --title "catalog: update Dune Ops Observability to v1.0.0" \
  --label enhancement \
  --label addon \
  --label major \
  --body-file ops-observability/releases/1.0.0-1-0-0/prs/catalog-pr.md
```

---

## Order to Execute

1. All 8 core PRs (submit in order v0.3.0 → v1.0.0)
2. All 8 addon PRs (submit in order, after core PRs merge)
3. All 8 catalog PRs (submit in order, after addon releases are published)

## Notes

- Core `--body-file` paths reference `docs/ops-observability/releases/` — these files must be created in the core repo first
- Addon `--body-file` paths are relative to the addon repo root
- Catalog `--body-file` paths are relative to the addon repo root (reference only; body must be copied inline for the catalog PR)
- Replace `--body-file` with `--body "$(cat file.md)"` if `gh pr create` is invoked from a different directory
