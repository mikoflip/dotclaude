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
    knowledge
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

# ── normalize_marketplace_path: undo absolute-path write-through ──────────────
# The `claude` CLI resolves the marketplace directory to an absolute path and
# writes it into settings.json. Since settings.json is symlinked to
# src/settings.json, that absolute path (specific to this machine) would land
# in git-tracked source. Rewrite it back to the relative "plugins" path,
# which is what the repo always commits.
normalize_marketplace_path() {
    local name="$1"
    local settings_file="${SRC_DIR}/settings.json"

    [[ -f "${settings_file}" ]] || return 0

    local current_path
    current_path="$(jq -r --arg name "${name}" '.extraKnownMarketplaces[$name].source.path // ""' "${settings_file}")"

    if [[ "${current_path}" == /* ]]; then
        local tmp
        tmp="$(mktemp)"
        jq --arg name "${name}" '.extraKnownMarketplaces[$name].source.path = "plugins"' \
            "${settings_file}" > "${tmp}" && mv "${tmp}" "${settings_file}"
        warn "Normalized leaked absolute path in settings.json → relative \"plugins\""
    fi
}

# ── resolve_mcp_json: substitute ${VAR} placeholders from src/mcp.env ─────────
# src/mcp.json is tracked and machine-agnostic; machine-specific values (e.g.
# absolute paths) live in src/mcp.env (gitignored, one KEY=VALUE per line) and
# are substituted in here via plain bash string replacement — no envsubst
# dependency, keeping jq as the repo's one hard dependency.
resolve_mcp_json() {
    local mcp_json="${SRC_DIR}/mcp.json"
    local mcp_env="${SRC_DIR}/mcp.env"
    local content
    content="$(cat "${mcp_json}")"

    if [[ -f "${mcp_env}" ]]; then
        local key value
        while IFS='=' read -r key value; do
            [[ -z "${key}" || "${key}" == \#* ]] && continue
            content="${content//\$\{${key}\}/${value}}"
        done < "${mcp_env}"
    fi

    printf '%s' "${content}"
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

    # Unregister MCP servers
    mcp_json="${SRC_DIR}/mcp.json"
    if [[ -f "${mcp_json}" ]] && command -v claude &>/dev/null; then
        echo
        info "Unregistering MCP servers …"
        while IFS= read -r server_name; do
            if $DRY_RUN; then
                run "claude mcp remove '${server_name}' -s user"
            else
                if claude mcp remove "${server_name}" -s user 2>/dev/null; then
                    success "Unregistered: ${server_name}"
                else
                    skip "Not registered (already clean): ${server_name}"
                fi
            fi
        done < <(jq -r 'keys[]' "${mcp_json}")
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
        marketplace_name="$(jq -r '.name' "${marketplace_json}")"

        # Step 1: register the local directory as a marketplace (idempotent)
        run "claude plugin marketplace add '${plugins_dir}'"
        $DRY_RUN || success "Marketplace registered: ${plugins_dir}"

        # `claude plugin marketplace add` writes the absolute ${plugins_dir}
        # path into settings.json's extraKnownMarketplaces.<name>.source.path.
        # settings.json is a symlink back into this repo (src/settings.json),
        # so that write-through would otherwise leak this machine's absolute
        # path into git-tracked source. Normalize it back to the relative
        # "plugins" path immediately so the leak never reaches a commit.
        $DRY_RUN || normalize_marketplace_path "${marketplace_name}"

        # Step 2: install each listed plugin
        echo
        info "Installing plugins from marketplace '${marketplace_name}' …"
        while IFS= read -r plugin_name; do
            run "claude plugin install '${plugin_name}@${marketplace_name}'"
            $DRY_RUN || success "Installed: ${plugin_name}"
        done < <(jq -r '.plugins[].name' "${marketplace_json}")
    fi
fi

# ── register MCP servers ──────────────────────────────────────────────────────
# src/mcp.json declares user-scoped MCP servers by name. Machine-specific
# placeholders (e.g. ${PLAYWRIGHT_MCP_DIR}) are resolved from src/mcp.env.
mcp_json="${SRC_DIR}/mcp.json"
if [[ -f "${mcp_json}" ]]; then
    echo
    info "Registering MCP servers …"
    if ! command -v claude &>/dev/null; then
        warn "claude not found in PATH — skipping MCP server registration."
        warn "Re-run install.sh after Claude Code is installed."
    elif ! command -v jq &>/dev/null; then
        warn "jq not found in PATH — skipping MCP server registration."
    else
        if [[ ! -f "${SRC_DIR}/mcp.env" ]]; then
            warn "No src/mcp.env found — copy src/mcp.env.example and fill in your paths."
            warn "Unresolved \${VAR} placeholders will be registered literally."
        fi

        resolved_mcp_json="$(resolve_mcp_json)"

        # `claude mcp add-json` errors on a name that already exists (not
        # idempotent like `claude plugin install`), so check first via `get`.
        while IFS= read -r server_name; do
            server_config="$(printf '%s' "${resolved_mcp_json}" | jq -c --arg name "${server_name}" '.[$name]')"
            if claude mcp get "${server_name}" &>/dev/null; then
                skip "Already registered: ${server_name}"
            else
                run "claude mcp add-json '${server_name}' '${server_config}' -s user"
                $DRY_RUN || success "Registered MCP server: ${server_name}"
            fi
        done < <(printf '%s' "${resolved_mcp_json}" | jq -r 'keys[]')
    fi
fi

echo
success "Install complete."
