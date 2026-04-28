#!/usr/bin/env bash
# status.sh — report deployed state of dotclaude repo
#
# Usage:
#   ./status.sh           # full status report
#   ./status.sh --short   # one-line summary per section (CI-friendly)
#
# Exit codes:
#   0  everything healthy
#   1  one or more warnings or errors detected
set -euo pipefail

# ── resolve paths ─────────────────────────────────────────────────────────────
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_DIR="${REPO_DIR}/src"
CLAUDE_DIR="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"
PLUGINS_DIR="${SRC_DIR}/plugins"
MARKETPLACE_JSON="${PLUGINS_DIR}/.claude-plugin/marketplace.json"
SHORT=false
ISSUES=0

USER_AUTHORED=(
    CLAUDE.md
    settings.json
    skills
    plugins
    agents
    commands
    hooks
)

# ── helpers ───────────────────────────────────────────────────────────────────
header()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()      { printf '\033[0;32m  ✓ %s\033[0m\n' "$*"; }
warn()    { printf '\033[0;33m  ⚠ %s\033[0m\n' "$*"; (( ISSUES++ )) || true; }
info()    { printf '\033[0;34m  · %s\033[0m\n' "$*"; }
absent()  { printf '\033[2m  – %s\033[0m\n' "$*"; }
rule()    { printf '\033[2m%s\033[0m\n' "────────────────────────────────────────"; }

# ── args ──────────────────────────────────────────────────────────────────────
for arg in "$@"; do
    case $arg in
        --short) SHORT=true ;;
        *) printf 'Unknown argument: %s\n' "$arg" >&2; exit 1 ;;
    esac
done

# ══════════════════════════════════════════════════════════════════════════════
# 1. DEPLOYMENT STATE (~/.claude presence + auth)
# ══════════════════════════════════════════════════════════════════════════════
header "1. Deployment"
rule

if [[ -d "${CLAUDE_DIR}" ]]; then
    ok "~/.claude exists"
else
    warn "~/.claude does not exist — run install.sh"
fi

if [[ -f "${CLAUDE_JSON}" ]]; then
    ok "~/.claude.json exists  (auth session present)"
else
    warn "~/.claude.json missing — re-login will be required"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 2. SYMLINK HEALTH
# ══════════════════════════════════════════════════════════════════════════════
header "2. Symlinks"
rule

symlink_ok=0
symlink_warn=0

check_symlink() {
    local src="$1" target="$2" label="$3"
    if [[ -L "${target}" ]]; then
        actual="$(readlink "${target}")"
        if [[ "${actual}" == "${src}" ]]; then
            $SHORT || ok "  ${label}  →  ${actual}"
            (( symlink_ok++ )) || true
        else
            warn "${label}  symlink points elsewhere: ${actual}"
            (( symlink_warn++ )) || true
        fi
    elif [[ -e "${target}" ]]; then
        warn "${label}  real file/dir (not a symlink — run install.sh)"
        (( symlink_warn++ )) || true
    else
        warn "${label}  in repo but not deployed (run install.sh)"
        (( symlink_warn++ )) || true
    fi
}

for item in "${USER_AUTHORED[@]}"; do
    src="${SRC_DIR}/${item}"

    if [[ ! -e "${src}" ]]; then
        absent "${item}  not in repo"
        continue
    fi

    if [[ -d "${src}" ]]; then
        target_dir="${CLAUDE_DIR}/${item}"
        if [[ ! -d "${target_dir}" || -L "${target_dir}" ]]; then
            warn "${item}/  container dir missing or symlinked — run install.sh"
            (( symlink_warn++ )) || true
            continue
        fi
        $SHORT || info "${item}/"
        for child_src in "${src}"/*/; do
            [[ -d "${child_src}" ]] || continue
            child_name="$(basename "${child_src}")"
            check_symlink "${child_src%/}" "${target_dir}/${child_name}" "${item}/${child_name}"
        done
        for child_src in "${src}"/*; do
            [[ -f "${child_src}" ]] || continue
            child_name="$(basename "${child_src}")"
            check_symlink "${child_src}" "${target_dir}/${child_name}" "${item}/${child_name}"
        done
    else
        check_symlink "${src}" "${CLAUDE_DIR}/${item}" "${item}"
    fi
done

if $SHORT; then
    if [[ "${symlink_warn}" -eq 0 ]]; then
        ok "${symlink_ok} symlinks healthy"
    else
        warn "${symlink_ok} healthy, ${symlink_warn} with issues"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# 3. PLUGIN REGISTRATION
# ══════════════════════════════════════════════════════════════════════════════
header "3. Plugins"
rule

if [[ ! -f "${MARKETPLACE_JSON}" ]]; then
    absent "No marketplace.json found at plugins/.claude-plugin/marketplace.json"
elif ! command -v claude &>/dev/null; then
    warn "claude not in PATH — cannot check plugin registration"
else
    marketplace_name="$(jq -r '.name' "${MARKETPLACE_JSON}")"

    # Get registered plugins from claude plugin list (suppress errors if none)
    registered_raw="$(claude plugin list 2>/dev/null || true)"

    # Check marketplace registration
    if echo "${registered_raw}" | grep -q "${marketplace_name}" 2>/dev/null; then
        ok "Marketplace '${marketplace_name}' registered"
    else
        warn "Marketplace '${marketplace_name}' not registered (run install.sh)"
    fi

    echo
    plugin_ok=0
    plugin_warn=0

    while IFS= read -r plugin_name; do
        if echo "${registered_raw}" | grep -q "${plugin_name}" 2>/dev/null; then
            $SHORT || ok "  ${plugin_name}"
            (( plugin_ok++ )) || true
        else
            warn "${plugin_name}  not registered (run install.sh)"
            (( plugin_warn++ )) || true
        fi
    done < <(jq -r '.plugins[].name' "${MARKETPLACE_JSON}")

    if $SHORT; then
        if [[ "${plugin_warn}" -eq 0 ]]; then
            ok "${plugin_ok} plugins registered"
        else
            warn "${plugin_ok} registered, ${plugin_warn} missing"
        fi
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# 4. REPO DRIFT (uncommitted changes)
# ══════════════════════════════════════════════════════════════════════════════
header "4. Repo drift"
rule

if ! command -v git &>/dev/null; then
    absent "git not in PATH — skipping drift check"
else
    git_status="$(git -C "${REPO_DIR}" status --short 2>/dev/null || true)"
    git_branch="$(git -C "${REPO_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    git_sha="$(git -C "${REPO_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")"

    info "Branch: ${git_branch}  (${git_sha})"

    if [[ -z "${git_status}" ]]; then
        ok "Working tree clean — deployed config matches repo"
    else
        warn "Uncommitted changes detected:"
        while IFS= read -r line; do
            printf '    \033[0;33m%s\033[0m\n' "${line}"
        done <<< "${git_status}"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
printf '\n'
rule
if [[ "${ISSUES}" -eq 0 ]]; then
    printf '\033[0;32m✓ All checks passed\033[0m\n\n'
    exit 0
else
    printf '\033[0;33m⚠ %d issue(s) found — run install.sh to resolve\033[0m\n\n' "${ISSUES}"
    exit 1
fi
