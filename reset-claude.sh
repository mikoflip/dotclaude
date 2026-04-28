#!/usr/bin/env bash
# reset-claude.sh — archive ~/.claude runtime state and reinstall config
#
# Default behaviour:
#   • Archives ~/.claude to a timestamped, Finder-visible backup
#   • Preserves ~/.claude.json  (auth session intact — no re-login required)
#   • Re-runs install.sh to symlink user config back into fresh ~/.claude
#
# Flags:
#   --full      Full factory reset: ~/.claude.json also archived (re-login
#               required; Keychain token stays intact)
#   --dry-run   Print every action without executing
set -euo pipefail

# ── resolve paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"
CLAUDE_DIR="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${HOME}/.claude.bak_${TIMESTAMP}"
BACKUP_JSON="${HOME}/.claude.json.bak_${TIMESTAMP}"
FULL_RESET=false
DRY_RUN=false

# ── helpers ───────────────────────────────────────────────────────────────────
info()    { printf '\033[0;34m  %s\033[0m\n' "$*"; }
success() { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
warn()    { printf '\033[0;33m⚠ %s\033[0m\n' "$*"; }
error()   { printf '\033[0;31m✗ %s\033[0m\n' "$*" >&2; }

run() {
    if $DRY_RUN; then
        printf '\033[2m  [dry-run] %s\033[0m\n' "$*"
    else
        eval "$@"
    fi
}

# ── args ──────────────────────────────────────────────────────────────────────
for arg in "$@"; do
    case $arg in
        --full)    FULL_RESET=true ;;
        --dry-run) DRY_RUN=true ;;
        *) error "Unknown argument: $arg"; exit 1 ;;
    esac
done

# ── guard: install.sh must exist ──────────────────────────────────────────────
if [[ ! -f "${INSTALL_SCRIPT}" ]]; then
    error "install.sh not found at ${INSTALL_SCRIPT}"
    error "Both scripts must live in the same repo directory."
    exit 1
fi

$DRY_RUN && warn "Dry-run mode — no changes will be made"

echo
if $FULL_RESET; then
    info "Claude Code — full factory reset"
    echo  "  ~/.claude        : will be archived"
    echo  "  ~/.claude.json   : will be archived  (re-login required)"
else
    info "Claude Code — runtime reset"
    echo  "  ~/.claude        : will be archived"
    echo  "  ~/.claude.json   : preserved          (no re-login needed)"
fi
echo  "  Backup           : ${BACKUP_DIR}"
echo

# ── guard: nothing to reset ───────────────────────────────────────────────────
if [[ ! -d "${CLAUDE_DIR}" ]]; then
    warn "~/.claude does not exist — skipping archive step."
else
    # ── archive ~/.claude ─────────────────────────────────────────────────────
    info "Archiving ~/.claude …"
    run "mv '${CLAUDE_DIR}' '${BACKUP_DIR}'"
    run "chflags nohidden '${BACKUP_DIR}'"
    success "Archived to: ${BACKUP_DIR}"
fi

# ── handle ~/.claude.json ─────────────────────────────────────────────────────
echo
if $FULL_RESET && [[ -f "${CLAUDE_JSON}" ]]; then
    info "Archiving ~/.claude.json …"
    run "mv '${CLAUDE_JSON}' '${BACKUP_JSON}'"
    run "chflags nohidden '${BACKUP_JSON}'"
    success "Archived to: ${BACKUP_JSON}"
    warn "Re-login required on next launch."
    warn "Keychain token is intact — no password entry needed."
elif [[ -f "${CLAUDE_JSON}" ]]; then
    success "~/.claude.json preserved — auth session intact."
fi

# ── reveal backup in Finder ───────────────────────────────────────────────────
if [[ "${OSTYPE}" == "darwin"* && -d "${BACKUP_DIR}" ]]; then
    echo
    info "Opening backup location in Finder …"
    run "open -R '${BACKUP_DIR}'"
fi

# ── reinstall config via symlinks ─────────────────────────────────────────────
echo
info "Reinstalling config …"
if $DRY_RUN; then
    run "${INSTALL_SCRIPT} --dry-run"
else
    bash "${INSTALL_SCRIPT}"
fi

echo
success "Reset complete. Launch 'claude' to start fresh."
