#!/usr/bin/env bash
# install.sh — symlink dotclaude repo items into ~/.claude and register plugins
#
# Usage:
#   ./install.sh              # create/update symlinks + register plugins
#   ./install.sh --uninstall  # remove managed symlinks + uninstall plugins
#   ./install.sh --dry-run    # preview without making changes
#
# Idempotent: already-correct symlinks are skipped without error.
# Existing real files/dirs at target locations are backed up before replacement.
# Plugin registration is persisted in ~/.claude.json (survives default reset).
set -euo pipefail

# ── repo root (always the directory containing this script) ──────────────────
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_DIR="${REPO_DIR}/src"
CLAUDE_DIR="${HOME}/.claude"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
UNINSTALL=false
DRY_RUN=false

# User-authored items managed by this script.
# Add entries here as the repo grows.
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
info()    { printf '\033[0;34m  %s\033[0m\n' "$*"; }
success() { printf '\033[0;32m✓ %s\033[0m\n' "$*"; }
skip()    { printf '\033[2m– %s\033[0m\n' "$*"; }
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
        --uninstall) UNINSTALL=true ;;
        --dry-run)   DRY_RUN=true ;;
        *) error "Unknown argument: $arg"; exit 1 ;;
    esac
done

$DRY_RUN && warn "Dry-run mode — no changes will be made"
echo

# ── link_item: symlink a single src path into a target path ───────────────────
# Handles backup of existing real files and replacement of stale symlinks.
link_item() {
    local src="$1"
    local target="$2"
    local label="$3"

    # Already a correct symlink → skip
    if [[ -L "${target}" && "$(readlink "${target}")" == "${src}" ]]; then
        skip "Already linked: ${label}"
        return
    fi

    # Existing real file/dir → back it up before replacing
    if [[ -e "${target}" && ! -L "${target}" ]]; then
        local backup="${target}.bak_${TIMESTAMP}"
        warn "Backing up existing ${label} → $(basename "${backup}")"
        run "mv '${target}' '${backup}'"
    fi

    # Stale symlink pointing elsewhere → remove it
    if [[ -L "${target}" ]]; then
        run "rm '${target}'"
    fi

    run "ln -s '${src}' '${target}'"
    success "Linked: ${label}"
}

# ── unlink_item: remove a managed symlink ─────────────────────────────────────
unlink_item() {
    local target="$1"
    local label="$2"

    if [[ -L "${target}" ]]; then
        run "rm '${target}'"
        success "Removed: ${label}"
    elif [[ -e "${target}" ]]; then
        skip "Not a symlink, skipping: ${label}"
    else
        skip "Not present: ${label}"
    fi
}

# ── uninstall ─────────────────────────────────────────────────────────────────
if $UNINSTALL; then
    info "Removing managed symlinks from ${CLAUDE_DIR} …"
    echo
    for item in "${USER_AUTHORED[@]}"; do
        src="${SRC_DIR}/${item}"
        target="${CLAUDE_DIR}/${item}"

        if [[ -d "${src}" ]]; then
            # Directory — remove per-child symlinks; rmdir the container if empty
            for child_src in "${src}"/*/; do
                [[ -e "${child_src}" ]] || continue
                child_name="$(basename "${child_src}")"
                unlink_item "${target}/${child_name}" "${item}/${child_name}"
            done
            # Also remove any file-level symlinks directly in the dir (e.g. SKILL.md at root)
            for child_src in "${src}"/*; do
                [[ -f "${child_src}" ]] || continue
                child_name="$(basename "${child_src}")"
                unlink_item "${target}/${child_name}" "${item}/${child_name}"
            done
            # Remove the container dir if now empty and it was created by us (not a symlink)
            if [[ -d "${target}" && ! -L "${target}" ]]; then
                $DRY_RUN || rmdir "${target}" 2>/dev/null && success "Removed empty dir: ${item}/" || true
            fi
        else
            unlink_item "${target}" "${item}"
        fi
    done

    # Unregister plugins
    plugins_dir="${SRC_DIR}/plugins"
    marketplace_json="${plugins_dir}/.claude-plugin/marketplace.json"
    if [[ -f "${marketplace_json}" ]] && command -v claude &>/dev/null; then
        echo
        info "Uninstalling plugins …"
        marketplace_name="$(jq -r '.name' "${marketplace_json}")"
        while IFS= read -r plugin_name; do
            if $DRY_RUN; then
                run "claude plugin uninstall '${plugin_name}'"
            else
                if claude plugin uninstall "${plugin_name}" 2>/dev/null; then
                    success "Uninstalled: ${plugin_name}"
                else
                    skip "Not installed (already clean): ${plugin_name}"
                fi
            fi
        done < <(jq -r '.plugins[].name' "${marketplace_json}")
        run "claude plugin marketplace remove '${marketplace_name}'"
        $DRY_RUN || success "Marketplace removed: ${marketplace_name}"
    fi

    echo
    success "Uninstall complete."
    exit 0
fi

# ── install ───────────────────────────────────────────────────────────────────
info "Installing dotclaude → ${CLAUDE_DIR}"
echo  "  Repo : ${REPO_DIR}"
echo

run "mkdir -p '${CLAUDE_DIR}'"

# ── symlink user-authored items ───────────────────────────────────────────────
# Files    → symlinked directly into ~/.claude/
# Dirs     → ~/.claude/<dir>/ created as a real directory;
#            each child inside is symlinked individually, keeping runtime
#            data written by Claude Code inside ~/.claude/ and out of the repo.
for item in "${USER_AUTHORED[@]}"; do
    src="${SRC_DIR}/${item}"

    if [[ ! -e "${src}" ]]; then
        skip "Not in repo, skipping: ${item}"
        continue
    fi

    if [[ -d "${src}" ]]; then
        # Create the container dir as a real directory
        run "mkdir -p '${CLAUDE_DIR}/${item}'"

        # Symlink each child (subdirs and files) individually
        children=( "${src}"/* )
        if [[ "${#children[@]}" -eq 0 || ( "${#children[@]}" -eq 1 && ! -e "${children[0]}" ) ]]; then
            skip "Empty dir, nothing to link: ${item}/"
            continue
        fi
        for child_src in "${src}"/*/; do
            [[ -d "${child_src}" ]] || continue
            child_name="$(basename "${child_src}")"
            link_item "${child_src%/}" "${CLAUDE_DIR}/${item}/${child_name}" "${item}/${child_name}"
        done
        for child_src in "${src}"/*; do
            [[ -f "${child_src}" ]] || continue
            child_name="$(basename "${child_src}")"
            link_item "${child_src}" "${CLAUDE_DIR}/${item}/${child_name}" "${item}/${child_name}"
        done
    else
        link_item "${src}" "${CLAUDE_DIR}/${item}" "${item}"
    fi
done

# ── register plugins ──────────────────────────────────────────────────────────
# Plugins require a marketplace intermediary — direct path install is not supported.
# The plugins/ dir must contain .claude-plugin/marketplace.json listing all plugins.
plugins_dir="${SRC_DIR}/plugins"
marketplace_json="${plugins_dir}/.claude-plugin/marketplace.json"
if [[ -d "${plugins_dir}" ]]; then
    echo
    info "Registering plugin marketplace …"
    if ! command -v claude &>/dev/null; then
        warn "claude not found in PATH — skipping plugin registration."
        warn "Re-run install.sh after Claude Code is installed."
    elif [[ ! -f "${marketplace_json}" ]]; then
        warn "No marketplace manifest found at plugins/.claude-plugin/marketplace.json"
        warn "Skipping plugin registration."
    else
        # Step 1: register the local directory as a marketplace (idempotent)
        run "claude plugin marketplace add '${plugins_dir}'"
        $DRY_RUN || success "Marketplace registered: ${plugins_dir}"

        # Step 2: read marketplace name and install each listed plugin
        marketplace_name="$(jq -r '.name' "${marketplace_json}")"
        echo
        info "Installing plugins from marketplace '${marketplace_name}' …"
        while IFS= read -r plugin_name; do
            run "claude plugin install '${plugin_name}@${marketplace_name}'"
            $DRY_RUN || success "Installed: ${plugin_name}"
        done < <(jq -r '.plugins[].name' "${marketplace_json}")
    fi
fi

echo
success "Install complete."
