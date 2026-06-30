# Shift-Left Security

This repository uses local hooks and CI gates to catch issues before addon code reaches `main`.

## Local setup

Install `pre-commit` once:

```bash
python3 -m pip install --user pre-commit
```

Or, if you use `pipx`:

```bash
pipx install pre-commit
```

Install the repository hooks:

```bash
pre-commit install
```

Run all hooks manually:

```bash
pre-commit run --all-files
```

## Included hooks

- JSON syntax checks.
- YAML syntax checks.
- merge-conflict marker checks.
- LF line-ending normalization.
- end-of-file normalization.
- trailing whitespace cleanup.
- Gitleaks secret detection.
- addon manifest validation.

## Policy

Local hooks are developer feedback. They reduce bad commits but are not the final security boundary.

Protected branch checks remain the source of truth before merging to `main`.

Secrets should be blocked as early as possible. Dependency and static-analysis findings may exist on feature branches during active work, but they must not merge or release unresolved unless explicitly accepted and documented.
