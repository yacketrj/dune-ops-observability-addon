# Shift-Left Security

This repository uses local hooks, quiet gate wrappers, and CI gates to catch issues before addon code reaches `main`.

## Local setup

The preferred setup path is the repository bootstrap script:

```bash
bash ops-observability/dev-tools/toolchain-bootstrap.sh
```

The bootstrap script detects required tools and installs missing supported tools where the local environment allows it.

By default, the gates attempt to install missing tools before running. Disable auto-install for detection-only mode:

```bash
DUNE_AUTO_INSTALL_TOOLS=0 bash ops-observability/dev-tools/pr-gate.sh
```

The bootstrap currently covers the local gate toolchain used by this repository, including Git, Node, Python, Pre-commit, Gitleaks, Semgrep, Trivy, and package-building support.

If a tool cannot be installed in the current environment, the gate fails closed and prints the missing tool and remediation target.

## Manual Pre-commit setup

Pre-commit can still be installed manually with `pipx`:

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

## Quiet gates

Routine local validation should use the quiet gate wrappers:

```bash
bash ops-observability/dev-tools/precommit-gate.sh
bash ops-observability/dev-tools/gitleaks-gate.sh
bash ops-observability/dev-tools/semgrep-gate.sh
bash ops-observability/dev-tools/trivy-gate.sh
bash ops-observability/dev-tools/security-shift-left.sh
bash ops-observability/dev-tools/pr-gate.sh
```

Passing gates print concise `PASS:` lines. Failed gates print `FAIL:` plus compact failure details.

For full verbose diagnostics, run the underlying tool directly.

## Why prefer `pipx` for Python tools?

Some Linux distributions mark the system Python as externally managed. In that case, direct `pip install --user ...` may fail with `externally-managed-environment`.

Use `pipx` for standalone Python command-line tools such as Pre-commit and Semgrep when possible.

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
