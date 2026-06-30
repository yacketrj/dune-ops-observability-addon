# Shift-Left Security

This repository uses local hooks and CI gates to catch issues before addon code reaches `main`.

## Local setup

Install `pre-commit` once with `pipx`:

```bash
sudo apt update
sudo apt install -y pipx
pipx ensurepath
pipx install pre-commit
```

If `pre-commit` is not found after installation, open a new shell or run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Install the repository hooks:

```bash
pre-commit install
```

Run all hooks manually:

```bash
pre-commit run --all-files
```

## Why not `pip install --user` on WSL?

Some Linux distributions mark the system Python as externally managed. In that case, direct `pip install --user ...` may fail with `externally-managed-environment`.

Use `pipx` for standalone Python command-line tools such as `pre-commit`.

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
