#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$ROOT_DIR/Brewfile"
failures=0
warnings=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

check_command() {
    label="$1"
    command_name="$2"
    shift 2

    if ! command -v "$command_name" >/dev/null 2>&1; then
        fail "$label: $command_name not found on PATH"
        return
    fi

    version="$("$command_name" "$@" 2>&1 | head -n 1 || true)"
    if [ -n "$version" ]; then
        pass "$label: $version"
    else
        pass "$label: $command_name available"
    fi
}

printf 'Enterprise AI Workstation doctor\n'
printf '================================\n'

if [ "$(uname -s)" = "Darwin" ]; then
    pass "Operating system: macOS $(sw_vers -productVersion 2>/dev/null || true)"
else
    fail "Operating system: this baseline targets macOS"
fi

check_command "Homebrew" brew --version

if command -v brew >/dev/null 2>&1; then
    if brew bundle check --file="$BREWFILE" >/dev/null 2>&1; then
        pass "Brewfile: declared workstation baseline is installed"
    else
        fail "Brewfile: workstation differs from the declared baseline"
    fi
fi

check_command "Git" git --version
check_command "Python" python3.13 --version
check_command "uv" uv --version
check_command "Node.js" node --version
check_command "npm" npm --version
check_command "tmux" tmux -V
check_command "Docker CLI" docker --version
check_command "Kubernetes CLI" kubectl version --client
check_command "Terraform" terraform version
check_command "AWS CLI" aws --version
check_command "Azure CLI" az version
check_command "Google Cloud CLI" gcloud --version

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        pass "Docker engine: reachable"
    else
        warn "Docker engine: CLI is installed, but the engine is not currently reachable"
    fi
fi

printf '\nSummary: %d failure(s), %d warning(s)\n' "$failures" "$warnings"

if [ "$failures" -ne 0 ]; then
    exit 1
fi
