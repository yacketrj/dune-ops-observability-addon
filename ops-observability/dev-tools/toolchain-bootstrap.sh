#!/usr/bin/env bash
set -euo pipefail

ROOT="${ADDON_REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

AUTO_INSTALL="${DUNE_AUTO_INSTALL_TOOLS:-1}"
failures=0

say_pass() { echo "PASS: $*"; }
say_fail() { echo "FAIL: $*"; }
say_info() { echo "INFO: $*"; }

have() {
  command -v "$1" >/dev/null 2>&1
}

record_failure() {
  failures=$((failures + 1))
  say_fail "$*"
}

can_install() {
  if [ "$AUTO_INSTALL" = "0" ]; then
    record_failure "auto-install disabled; missing $1"
    return 1
  fi
  return 0
}

sudo_cmd() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
    return $?
  fi
  if have sudo; then
    sudo "$@"
    return $?
  fi
  return 127
}

apt_install() {
  if ! have apt-get; then
    return 127
  fi
  sudo_cmd apt-get update >/dev/null
  sudo_cmd apt-get install -y "$@" >/dev/null
}

ensure_basic_package() {
  local command_name="$1"
  local package_name="$2"

  if have "$command_name"; then
    say_pass "tool available: $command_name"
    return 0
  fi

  can_install "$command_name" || return 1

  if apt_install "$package_name"; then
    if have "$command_name"; then
      say_pass "installed: $command_name"
      return 0
    fi
  fi

  record_failure "could not install $command_name; install package '$package_name' manually"
  return 1
}

ensure_python3() {
  ensure_basic_package python3 python3
}

ensure_pip() {
  if python3 -m pip --version >/dev/null 2>&1; then
    say_pass "tool available: pip"
    return 0
  fi
  can_install pip || return 1
  if apt_install python3-pip; then
    if python3 -m pip --version >/dev/null 2>&1; then
      say_pass "installed: pip"
      return 0
    fi
  fi
  record_failure "could not install pip; install python3-pip manually"
  return 1
}

ensure_pipx() {
  if have pipx; then
    say_pass "tool available: pipx"
    return 0
  fi

  can_install pipx || return 1

  if apt_install pipx; then
    if have pipx; then
      pipx ensurepath >/dev/null 2>&1 || true
      say_pass "installed: pipx"
      return 0
    fi
  fi

  ensure_python3 || return 1
  ensure_pip || return 1
  if python3 -m pip install --user --upgrade pipx >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
    if have pipx; then
      pipx ensurepath >/dev/null 2>&1 || true
      say_pass "installed: pipx"
      return 0
    fi
  fi

  record_failure "could not install pipx; install pipx manually"
  return 1
}

ensure_pipx_tool() {
  local command_name="$1"
  local package_name="$2"

  if have "$command_name"; then
    say_pass "tool available: $command_name"
    return 0
  fi

  can_install "$command_name" || return 1
  ensure_pipx || return 1

  if pipx install --force "$package_name" >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
    if have "$command_name"; then
      say_pass "installed: $command_name"
      return 0
    fi
  fi

  ensure_pip || true
  if python3 -m pip install --user --upgrade "$package_name" >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
    if have "$command_name"; then
      say_pass "installed: $command_name"
      return 0
    fi
  fi

  record_failure "could not install $command_name; install package '$package_name' manually"
  return 1
}

ensure_go() {
  if have go; then
    say_pass "tool available: go"
    return 0
  fi
  can_install go || return 1
  if apt_install golang-go; then
    if have go; then
      say_pass "installed: go"
      return 0
    fi
  fi
  record_failure "could not install go; install Go manually"
  return 1
}

ensure_gitleaks() {
  if have gitleaks; then
    say_pass "tool available: gitleaks"
    return 0
  fi

  can_install gitleaks || return 1

  if have brew; then
    if brew install gitleaks >/dev/null 2>&1 || brew upgrade gitleaks >/dev/null 2>&1; then
      if have gitleaks; then
        say_pass "installed: gitleaks"
        return 0
      fi
    fi
  fi

  if apt_install gitleaks >/dev/null 2>&1; then
    if have gitleaks; then
      say_pass "installed: gitleaks"
      return 0
    fi
  fi

  ensure_go || return 1
  if GO111MODULE=on go install github.com/gitleaks/gitleaks/v8@latest >/dev/null 2>&1; then
    export PATH="$HOME/go/bin:$PATH"
    if have gitleaks; then
      say_pass "installed: gitleaks"
      return 0
    fi
  fi

  record_failure "could not install gitleaks; install gitleaks manually"
  return 1
}

ensure_trivy() {
  if have trivy; then
    say_pass "tool available: trivy"
    return 0
  fi

  can_install trivy || return 1

  if have brew; then
    if brew install trivy >/dev/null 2>&1 || brew upgrade trivy >/dev/null 2>&1; then
      if have trivy; then
        say_pass "installed: trivy"
        return 0
      fi
    fi
  fi

  if apt_install trivy >/dev/null 2>&1; then
    if have trivy; then
      say_pass "installed: trivy"
      return 0
    fi
  fi

  ensure_basic_package curl curl || return 1
  ensure_basic_package tar tar || true
  mkdir -p "$HOME/.local/bin"
  tmp_script="$(mktemp)"
  if curl -fsSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh -o "$tmp_script" >/dev/null 2>&1; then
    if sh "$tmp_script" -b "$HOME/.local/bin" >/dev/null 2>&1; then
      rm -f "$tmp_script"
      if have trivy; then
        say_pass "installed: trivy"
        return 0
      fi
    fi
  fi
  rm -f "$tmp_script"

  record_failure "could not install trivy; install Trivy manually"
  return 1
}

ensure_zip() {
  ensure_basic_package zip zip
}

ensure_tool() {
  case "$1" in
    git) ensure_basic_package git git || true ;;
    node) ensure_basic_package node nodejs || true ;;
    npm) ensure_basic_package npm npm || true ;;
    python3) ensure_python3 || true ;;
    pip) ensure_pip || true ;;
    pipx) ensure_pipx || true ;;
    pre-commit) ensure_pipx_tool pre-commit pre-commit || true ;;
    semgrep) ensure_pipx_tool semgrep semgrep || true ;;
    gitleaks) ensure_gitleaks || true ;;
    trivy) ensure_trivy || true ;;
    curl) ensure_basic_package curl curl || true ;;
    tar) ensure_basic_package tar tar || true ;;
    zip) ensure_zip || true ;;
    *) record_failure "unknown tool requested: $1" ;;
  esac
}

if [ "$#" -eq 0 ]; then
  set -- git node npm python3 pipx pre-commit gitleaks semgrep trivy zip
fi

for tool in "$@"; do
  ensure_tool "$tool"
done

if [ "$failures" -ne 0 ]; then
  say_fail "toolchain bootstrap ($failures failure(s))"
  exit 1
fi

say_pass "toolchain bootstrap"
